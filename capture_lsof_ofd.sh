#!/bin/bash

## Script to collect JSTACKs at regular intervals.
if [ "$#" -ne 4 ]; then
	echo -e "\n\t>>> Incorrect Usage: <<<\n\t===> Usage: $0 APPLICATION_ID OUTPUT_PATH NUM_ITERATIONS SLEEP_SECS <===\n"
	exit 2
fi

# Check for the valid lsof command.
LSOF_COM=$(which lsof &> /dev/null ; echo $?)

if [ "$LSOF_COM" -eq 0 ] ; then
	LSOF_COM=$(which lsof)
else
	echo -e "\n\tNo valid lsof command found.\n\tPlease install the lsof YUM package and retry.\n\tExiting from the script !!!\n"
	exit 3
fi

## Validating the inputs.
APP_INFO=$1
LSOF_OUT_PATH=$3
NUM_ITERATIONS=$4
SLEEP_TIME=$5

list_contids() {
	## Getting the PID of the containers.
	CONTAINERS_LIST=$(ps -ef | grep "$APP_ID" | grep -v -e bash -e container-executor -e grep -e jstack | awk '{print $2}')

	## Check for running containers.
	NUM_CONT=$(ps -ef | grep "$APP_ID" | grep -v -e bash -e container-executor -e grep -e jstack | awk '{print $2}' | wc -l)

	if [ "$NUM_CONT" -eq 0 ]; then
		echo -e "\n\tThere are no containers running for application $APP_ID in this NodeManager node. Exiting the from the script !!!\n"
		exit 5
	fi
}

collect_lsof() {
	## Capturing the JSTACKs.
	ITERATIONS=1

	while [ "$ITERATIONS" -le "$NUM_ITERATIONS" ]; do
		echo "Iteration : $ITERATIONS"
		#date
		for CONT_PID in $CONTAINERS_LIST
			do 
				CONT_ID=$(ps -ef | grep "$CONT_PID" | tr ' ' '\n' | grep 'container.log.dir' | awk -F'/' {'print $NF'})	
				echo -e "Collecting Open Files for Container $CONT_ID -- Process $CONT_PID ..."
				sudo -u ${USER} ${LSOF_COM} -p ${CONT_PID} >> ${LSOF_OUT_PATH}/jstacks_${CONT_ID}.txt
		done
		#date
		if [ "$ITERATIONS" -lt "$NUM_ITERATIONS" ]; then
			echo -e "Next iteration will start in $SLEEP_TIME seconds...\n"
			sleep ${SLEEP_TIME}
		fi
		# Increment the counter
		((ITERATIONS++))
	done
	echo -e "\n\t======\n\tCaptured Open Files for $APP_ID : $NUM_ITERATIONS times at $SLEEP_TIME secs interval\n\t======"
}

perform_cleanup() {
	## Creating the output directory.
	if [ ! -d "$LSOF_OUT_PATH" ]; then
		echo -e "Output directory doesn't exist. Creating a new one...\n"
		mkdir $LSOF_OUT_PATH
	fi

	## Clean the JSTACK after every hour.
	CURRENT_TIME=$(date +%s)
	CLEAN_FILE=$LSOF_OUT_PATH/__last_clean_time

	## Create the file if doesn't exist
	if [ ! -e "$CLEAN_FILE" ]; then
		echo $CURRENT_TIME > "$CLEAN_FILE"
	fi

	## Find the difference in time and clean up the files
	LAST_JSTACK_CLEAN_TIME=$(cat "$CLEAN_FILE")
	TIME_DIFF=$((CURRENT_TIME - LAST_JSTACK_CLEAN_TIME))
	HOUR_DIFF=$(date -u -d @"$TIME_DIFF" +'%H')

	if [ "$HOUR_DIFF" -ne 0 ]; then
		find ${LSOF_OUT_PATH}/*.txt -type f -exec bash -c 'timestamp=$(date +%Y-%m-%dT%H:%M:%S); mv "$1" "${1%.*}_${timestamp}.out"' _ {} \;
		echo $CURRENT_TIME > "$CLEAN_FILE"
	fi

	# Find and delete files created before one day
	find ${LSOF_OUT_PATH}/*.txt -type f -not -newermt "$(date -d '1 day ago' '+%Y-%m-%d %H:%M:%S')" -exec rm {} \;
}

collection_process() {
	list_contids
	collect_lsof
	perform_cleanup
}

## Check if the given is a APPID then check the status and collect the JSTACKs .. Else fail.
if [[ $APP_INFO =~ ^application_[0-9]+_[0-9]+$ ]]; then

	APP_ID=$APP_INFO
	APP_STATUS=$(yarn app -status "$APP_ID" 2> /dev/null | grep 'State' | grep -v 'Final' | awk -F' ' {'print $NF'})

	if [[ "$APP_STATUS" == "FINISHED" ]] || [[ "$APP_STATUS" == "KILLED" ]]; then
		echo -e "\n\tApplication $APP_ID is already completed / killed. Exiting from the script !!!\n"
		exit 4
	elif [[ "$APP_STATUS" != "RUNNING" ]]; then
		echo -e "\n\tApplication $APP_ID status is unknown. Exiting from the script !!!\n"
		exit 4
	else
		echo -e "\n\tApplication $APP_ID is in running status. Continuing with JSTACK collection !!!\n"
		collection_process
		exit 0
	fi
fi

## Getting the Application status if the provided is Application Name and collect the JSTACKs.
APPLICATION_LIST=$(yarn application -list -appStates RUNNING 2> /dev/null | grep $APP_INFO | grep ^application_ | awk -F' '  {'print $1'})

if [ -z "$APPLICATION_LIST" ] ; then 
	echo -e "\n\tThere is no application running with name $APP_INFO"
	exit 4
fi

for APP_ID in $APPLICATION_LIST
	do
		collection_process
done

## Crontab format to schedule the jobs.
## */6 * * * * sh /root/capture_lsof_ofd.sh APPID/NAME PATH INTERATIONS SLEEPTIME >> /$PATH/command_output.txt