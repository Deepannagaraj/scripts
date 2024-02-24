#!/bin/bash

## Script to collect JSTACKs at regular intervals.

if [ "$#" -ne 5 ]; then
	echo -e "\n\t>>> Incorrect Usage: <<<\n\t===> Usage: $0 APPLICATION_ID USER OUTPUT_PATH NUM_ITERATIONS SLEEP_SECS <===\n"
	exit 2
fi

## JAVA_HOME / JAVA_PATH in case if needed:
# JAVA_PATH=/usr/java/jdk1.8.0_232-cloudera/bin

# Check for the valid JSTACK command.
JS_COM=$(which jstack &> /dev/null ; echo $?)
JS_PATH=$JAVA_PATH/jstack

if [ "$JS_COM" -ne 0 ] ; then
	if [ ! -e "$JS_PATH" ]; then
		echo -e "\n\tNo valid JSTACK command found.\n\tProvide the valid path by uncommenting the JAVA_PATH variable.\n\tExiting from the script !!!\n"
		exit 3
	fi
fi

## Checking for the Kerberos ticket...
KRB_ENABLED=1

if [ "$KRB_ENABLED" -eq 0 ]; then
	echo -e "\n\tKerberos not enabled continuing to run the script without Kerberos !!!\n"
else
	KRB_CHECK=$(klist &> /dev/null ; echo $?)
	if [ "$KRB_CHECK" -eq 1 ]; then
		echo -e "\n\tNo valid Kerberos ticket found. Get the Kerberos ticket and then run the command.\n\tIf the cluster is not Kerberised then set the 'KRB_ENABLED' to '0' at line number #25 and rerun the script.\n\tExiting from the script !!!\n"
		exit 4
	fi
fi

## Validating the inputs.
APP_ID=$1
USER=$2
JSTACK_PATH=$3
NUM_ITERATIONS=$4
SLEEP_TIME=$5

if [ ! -d "$JSTACK_PATH" ]; then
    echo -e "Output directory doesn't exist. Creating a new one...\n"
	mkdir $JSTACK_PATH
fi

## Check if the application is running.. Else fail.
APP_STATUS=$(yarn app -status "$APP_ID" 2> /dev/null | grep 'State' | grep -v 'Final' | awk -F' ' {'print $NF'})

if [[ "$APP_STATUS" == "FINISHED" ]] || [[ "$APP_STATUS" == "KILLED" ]]; then
	echo -e "\n\tThis application is already completed / killed. Exiting from the script !!!\n"
	exit 5
elif [[ "$APP_STATUS" != "RUNNING" ]]; then
	echo -e "\n\tThis application status is unknown. Exiting from the script !!!\n"
	exit 6
else
	echo -e "\n\tApplication is in running status. Continuing with JSTACK collection !!!\n"
fi

## Getting the PID of the containers.
CONTAINERS_LIST=$(ps -ef | grep "$APP_ID" | grep -v -e bash -e container-executor -e grep -e jstack | awk '{print $2}')

## Check for running containers.
NUM_CONT=$(ps -ef | grep "$APP_ID" | grep -v -e bash -e container-executor -e grep -e jstack | awk '{print $2}' | wc -l)

if [ "$NUM_CONT" -eq 0 ]; then
	echo -e "\n\tThere are no containers running for this application in this NodeManager node. Exiting the from the script !!!\n"
	exit 7
fi

## Capturing the JSTACKs.
ITERATIONS=1

while [ "$ITERATIONS" -le "$NUM_ITERATIONS" ]; do
	echo "Iteration : $ITERATIONS"
	date
	for CONT_PID in $CONTAINERS_LIST
		do 
			CONT_ID=$(ps -ef | grep "$CONT_PID" | tr ' ' '\n' | grep 'container.log.dir' | awk -F'/' {'print $NF'})	
			echo -e "Collecting JSTACK for Container $CONT_ID -- Process $CONT_PID ..."
			sudo -u ${USER} ${JAVA_PATH}/jstack -l ${CONT_PID} >> ${JSTACK_PATH}/jstacks_${CONT_ID}.txt
	done
	date
	if [ "$ITERATIONS" -lt "$NUM_ITERATIONS" ]; then
		echo -e "Next iteration will start in $SLEEP_TIME seconds...\n"
		sleep ${SLEEP_TIME}
	fi
    # Increment the counter
    ((ITERATIONS++))
done
echo -e "\n\t======\n\tCaptured JSTACKs $NUM_ITERATIONS times at a interval of $SLEEP_TIME secs\n\t======"

## Clean the JSTACK after every hour.
CURRENT_TIME=$(date +%s)
CLEAN_FILE=$JSTACK_PATH/__last_clean_time

## Create the file if doesn't exist
if [ ! -e "$CLEAN_FILE" ]; then
	echo $CURRENT_TIME > "$CLEAN_FILE"
fi

## Find the difference in time and clean up the files
LAST_JSTACK_CLEAN_TIME=$(cat "$CLEAN_FILE")
TIME_DIFF=$((CURRENT_TIME - LAST_JSTACK_CLEAN_TIME))
HOUR_DIFF=$(date -u -d @"$TIME_DIFF" +'%H')

if [ "$HOUR_DIFF" -ne 0 ]; then
	find ${JSTACK_PATH}/*.txt -type f -exec bash -c 'timestamp=$(date +%Y-%m-%dT%H:%M:%S); mv "$1" "${1%.*}_${timestamp}.${1##*.}"' _ {} \;
	echo $CURRENT_TIME > "$CLEAN_FILE"
fi

# Find and delete files created before one day
find ${JSTACK_PATH}/*.txt -type f -not -newermt "$(date -d '1 day ago' '+%Y-%m-%d %H:%M:%S')" -exec rm {} \;

## Crontab format to schedule the jobs.
## */6 * * * * sh /root/jstack_test.sh APPID USER PATH INTERATIONS SLEEPTIME > /$PATH/command_output.txt
