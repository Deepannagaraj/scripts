#!/bin/bash

## Check for the inputs.
if [ "$#" -ne 1 ]; then
	echo -e "\n\t>>> Incorrect Usage: <<<\n\t===> Usage: $0 CONTAINER_LOG_FILE <===\n"
	exit 2
fi

### Script to find the time taken to complete the job from the AM / Driver container!!!
FILE_NAME=$1

if [ -f "$FILE_NAME" ]; then
    echo ""
else
    echo -e "\n\tFile does not exist: $FILE_NAME. Provide a valid File path\n"
	exit 3
fi

### Start time date calculation:
START_DATETIME_1=`grep ^[0-9] $FILE_NAME | head -n1 | awk -F' ' {'print $1,$2'} | awk -F',' {'print $1'}`
SDT=`echo $START_DATETIME_1 | grep [0-9]$`

if [ -z "$SDT" ]; then
	START_DATETIME=$(sed 's/.\{4\}$//' <<<"$START_DATETIME_1")
else
	START_DATETIME=$START_DATETIME_1
fi

echo -e "\t-> Start Timestamp:\t$START_DATETIME"

### End time date calculation:
END_DATETIME_1=`grep ^[0-9] $FILE_NAME | tail -n1 | awk -F' ' {'print $1,$2'} | awk -F',' {'print $1'}`
EDT=`echo $END_DATETIME_1 | grep [0-9]$`

if [ -z "$SDT" ]; then
	END_DATETIME=$(sed 's/.\{4\}$//' <<<"$END_DATETIME_1")
else
	END_DATETIME=$END_DATETIME_1
fi

echo -e "\n\t-> End Timestamp:\t$END_DATETIME"

if [[ $START_DATETIME == *-* ]]; then
    DELIMITER='-'
elif [[ $START_DATETIME == */* ]]; then
	DELIMITER='/'
else
	echo -e "Invalid date format"
	exit 4
fi

OPTS="-j -f"

case $DELIMITER in

	"-")
		START_EPOCH=`date $OPTS "%Y-%m-%d %H:%M:%S" "$START_DATETIME" +%s`
		END_EPOCH=`date $OPTS "%Y-%m-%d %H:%M:%S" "$END_DATETIME" +%s`
		;;

	"/")
		START_EPOCH=`date $OPTS "%y/%m/%d %H:%M:%S" "$START_DATETIME" "+%s"`
		END_EPOCH=`date $OPTS "%y/%m/%d %H:%M:%S" "$END_DATETIME" "+%s"`
		;;

	*)
		echo -e "Invalid Format"
		;;
		
esac

# Calculate the difference in seconds
difference=$((END_EPOCH - START_EPOCH))

# Calculate days, hours, minutes, and seconds
days=$((difference / 86400))
difference=$((difference % 86400))
hours=$((difference / 3600))
difference=$((difference % 3600))
minutes=$((difference / 60))
seconds=$((difference % 60))

echo -e "\n\t==> Total time taken:\t$days days $hours hours $minutes minutes $seconds seconds\n"