#!/bin/bash

## Check for the inputs.
if [ "$#" -ne 1 ]; then
	echo -e "\n\t>>> Incorrect Usage: <<<\n\t===> Usage: $0 CONTAINER_LOG_FILE <===\n"
	exit 2
fi

### Script to find the time taken to complete the job from the AM / Driver container!!!
FILE_NAME=$1

### Start time date calculation:
START_DATETIME_1=`grep ^[0-9] $FILE_NAME | head -n1 | awk -F' ' {'print $1,$2'} | awk -F',' {'print $1'}`

SDT=`echo $START_DATETIME_1 | grep [1-9]$`

if [ -z "$SDT" ]; then
	START_DATETIME=$(sed 's/.\{4\}$//' <<<"$START_DATETIME_1")
else
	START_DATETIME=$START_DATETIME_1
fi

echo -e "\t==> Start Timstamp"
echo $START_DATETIME

START_YEAR=`echo $START_DATETIME | awk -F'/' {'print $1'}`
START_MONTH=`echo $START_DATETIME | awk -F'/' {'print $2'}`
START_DATE=`echo $START_DATETIME | awk -F'/' {'print $3'} | awk -F' ' {'print $1'}`
START_TIME=`echo $START_DATETIME | awk -F' ' {'print $2'}`

### Convert the time to seconds:
START_SECS=`gdate --date "$START_TIME" +%s`

### End time date calculation:
END_DATETIME_1=`grep ^[0-9] $FILE_NAME | tail -n1 | awk -F' ' {'print $1,$2'} | awk -F',' {'print $1'}`

EDT=`echo $END_DATETIME_1 | grep [1-9]$`

if [ -z "$SDT" ]; then
	END_DATETIME=$(sed 's/.\{4\}$//' <<<"$END_DATETIME_1")
else
	END_DATETIME=$END_DATETIME_1
fi

echo -e "\n\t==> Ending Timstamp"
echo $END_DATETIME

END_YEAR=`echo $END_DATETIME | awk -F'/' {'print $1'}`
END_MONTH=`echo $END_DATETIME | awk -F'/' {'print $2'}`
END_DATE=`echo $END_DATETIME | awk -F'/' {'print $3'} | awk -F' ' {'print $1'}`
END_TIME=`echo $END_DATETIME | awk -F' ' {'print $2'}`

### Convert the time to seconds:
END_SECS=`gdate --date "$END_TIME" +%s`

### Diffence Calculations:

TIMETAKEN=`echo "$(($END_SECS - $START_SECS))"`
ACT_DIFF=`gdate --date "@$TIMETAKEN" -u +%H:%M:%S`

HOUR=`echo $ACT_DIFF | awk -F'\:' {'print $1'}`
MINS=`echo $ACT_DIFF | awk -F'\:' {'print $2'}`
SECS=`echo $ACT_DIFF | awk -F'\:' {'print $3'}`

YEARTAKEN=`echo "$(($END_YEAR - $START_YEAR))"`
MONTHTAKEN=`echo "$(($END_MONTH - $START_MONTH))"`
DAYSTAKEN=`echo "$(($END_DATE - $START_DATE))"`

echo -e "\nTotal time taken"

echo "$YEARTAKEN years $MONTHTAKEN months $DAYSTAKEN days $HOUR hours $MINS minutes $SECS seconds"