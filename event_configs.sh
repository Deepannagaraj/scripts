#!/bin/bash

## Listing only the configs from the Spark event logs:

if [ $# -eq 0 ]
then
   echo -e "\n\t>>> Incorrect Usage: <<<\n\n \t\t===> Usage: $0 <SPARK_EVENT_LOG_FILE> <===\n"
   exit 1
fi

### head -3 $1 | tail -1 | jq 

if [ -f "$1" ]; then
   echo ""
else
   echo -e "\n\tFile does not exist: $FILE_NAME. Provide a valid File path\n"
	exit 3
fi

grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq 