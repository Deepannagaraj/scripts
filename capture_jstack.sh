#!/bin/bash

## Script to collect JSTACKs at regular intervals.

if [ "$#" -ne 5 ]; then
	echo -e "\n\t>>> Incorrect Usage: <<<\n\t===> Usage: $0 APPLICATION_ID USER OUTPUT_PATH NUM_ITERATIONS SLEEP_SECS <===\n"
	exit 2
fi

## JAVA_HOME / JAVA_PATH in case if needed:
# JAVA_PATH=/usr/java/jdk1.8.0_232-cloudera/bin

# Check for the valid JSTACK command.
JS_COM=$(which jstack 2> /dev/null ; echo $?)
JS_JP_COM==$(which "$JAVA_PATH"/jstack 2> /dev/null ; echo $?)

if [ "$JS_COM" -eq 0 ] && [ "$JS_JP_COM" -eq 0 ]; then
	echo -e "\n\tNo valid JSTACK command found.\n\tProvide the valid path by uncommenting the JAVA_PATH variable.\n\tExiting from the script !!!\n"
	exit 3
fi

## Validating the inputs.
APP_ID=$1
USER=$2
JSTACK_PATH=$3
NUM_ITERATIONS=$4
SLEEP_TIME=$5

## Checking for the Kerberos ticket...
KRB_ENABLED=1

if [ "$KRB_ENABLED" -eq 0 ]; then
	echo -e "\n\tKerberos not enabled continuing to run the script without Kerberos !!!\n"
else
	KRB_CHECK=$(klist > /dev/null ; echo $?)
	if [ "$KRB_CHECK" -eq 1 ]; then
		echo -e "\n\tNo valid Kerberos ticket found. Get the Kerberos ticket and then run the command.\n\tExiting from the script !!!\n"
		exit 4
	fi
fi


## Check if the application is running.. Else fail.
APP_STATUS=$(yarn app -status "$APP_ID" 2> /dev/null | grep 'State' | grep -v 'Final' | awk -F' ' {'print $NF'})

if [[ "$APP_STATUS" == "FINISHED" ]] || [[ "$APP_STATUS" == "KILLED" ]]; then
	echo -e "\n\tThis application is already completed / killed. Exiting from the script !!!\n"
	exit 5
fi

if [[ "$APP_STATUS" != "RUNNING" ]]; then
	echo -e "\n\tThis application status is unknown. Exiting from the script !!!\n"
	exit 6
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
echo -e "\t======\nCaptured JSTACKs for $NUM_ITERATIONS times at a interval of $SLEEP_TIME secs\n======"

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
