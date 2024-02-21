#!/bin/bash

## Script to collect JSTACKs at regular intervals.

if [ "$#" -ne 5 ]; then
	echo -e "\n\t>>> Incorrect Usage: <<<\n\t===> Usage: $0 APPLICATION_ID USER OUTPUT_PATH NUM_ITERATIONS SLEEP_SECS <===\n"
	exit 1
fi

## JAVA_HOME / JAVA_PATH in case if needed:
JAVA_PATH=/usr/java/jdk1.8.0_232-cloudera/bin

## Validating the inputs.
APP_ID=$1
USER=$2
JSTACK_PATH=$3
NUM_ITERATIONS=$4
SLEEP_TIME=$5

## Check if the application is running.. Else fail.
APP_STATUS=$(yarn app -status "$APP_ID" 2> /dev/null | grep 'State' | grep -v 'Final' | awk -F' ' {'print $NF'})

if [[ "$APP_STATUS" == "FINISHED" ]]; then
	echo "This application is already completed. Exiting from the script !!!"
	exit 3
fi

if [[ "$APP_STATUS" != "RUNNING" ]]; then
	echo "This application status is unknown. Exiting from the script !!!"
	exit 6
fi

## Finding the PID of the containers.
CONTAINERS_LIST=$(ps -ef | grep "$APP_ID" | grep -v -e bash -e container-executor -e grep -e jstack | awk '{print $2}')

## Capturing the JSTACKs.
ITERATIONS=$(seq 1 "$NUM_ITERATIONS")

for i in $ITERATIONS
	do
		echo "Iteration : $i"
		date
		for CONT_PID in $CONTAINERS_LIST
		do 
			CONT_ID=$(ps -ef | grep "$CONT_PID" | tr ' ' '\n' | grep 'container.log.dir' | awk -F'/' {'print $NF'})	
			echo -e "Collecting JSTACK for Container $CONT_ID -- Process $CONT_PID ..."
			sudo -u ${USER} ${JAVA_PATH}/jstack -l ${CONT_PID} >> /${JSTACK_PATH}/jstacks_${CONT_ID}.txt
	done
	date
	echo -e "Sleeping for $SLEEP_TIME seconds to start next iteration !!!\n"
	sleep ${SLEEP_TIME}
done
echo -e "======\nCaptured JSTACKs for $NUM_ITERATIONS times at a interval of $SLEEP_TIME secs\n======"

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