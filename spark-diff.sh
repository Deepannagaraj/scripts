#!/bin/bash

## Checking the input files
if [ $# -ne 2 ]
then
   echo -e "\n\t>>> Incorrect Usage: <<<\n\n \t\t===> Usage: $0 <EVENT_LOG_1> <EVENT_LOG_2> <===\n"
   exit 1
fi

## Setting the filename and output directories.
if ! [ -f "$1" ]; then
   echo -e "\n\tFirst file does not exist: $1\n\tProvide a valid File path\n"
   exit 3
else
   EVENT_LOG_1=`echo $1 | awk -F'/' {'print $NF'}`
fi

if ! [ -f "$2" ]; then
   echo -e "\n\tSecond file does not exist: $2\n\tProvide a valid File path\n"
   exit 3
else
   EVENT_LOG_2=`echo $2 | awk -F'/' {'print $NF'}`
fi

TEMP_FILE=~/.spark_diff

if ! [ -f "$TEMP_FILE" ]; then
   mkdir -p $TEMP_FILE
fi

###########################################################################################################################################################################################

### Listing configurations:
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."JVM Information"' > ${TEMP_FILE}/${EVENT_LOG_1}_jvm_info.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."Spark Properties"' > ${TEMP_FILE}/${EVENT_LOG_1}_spark_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."Hadoop Properties"' > ${TEMP_FILE}/${EVENT_LOG_1}_hadoop_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."System Properties"' > ${TEMP_FILE}/${EVENT_LOG_1}_system_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."Classpath Entries"' > ${TEMP_FILE}/${EVENT_LOG_1}_classpath_entry.json

grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."JVM Information"' > ${TEMP_FILE}/${EVENT_LOG_2}_jvm_info.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."Spark Properties"' > ${TEMP_FILE}/${EVENT_LOG_2}_spark_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."Hadoop Properties"' > ${TEMP_FILE}/${EVENT_LOG_2}_hadoop_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."System Properties"' > ${TEMP_FILE}/${EVENT_LOG_2}_system_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."Classpath Entries"' > ${TEMP_FILE}/${EVENT_LOG_2}_classpath_entry.json

###########################################################################################################################################################################################

### Separating Data metrics:
jq 'select(.Event=="SparkListenerStageCompleted")' $1 | grep -i -A1 -E 'internal.metrics.input.bytesRead|internal.metrics.input.recordsRead|internal.metrics.output.bytesWritten|internal.metrics.output.recordsWritten|internal.metrics.shuffle.read.remoteBytesRead|internal.metrics.shuffle.read.localBytesRead|internal.metrics.shuffle.read.recordsRead|internal.metrics.shuffle.write.bytesWritten|internal.metrics.shuffle.write.recordsWritten' > ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json

jq 'select(.Event=="SparkListenerStageCompleted")' $2 | grep -i -A1 -E 'internal.metrics.input.bytesRead|internal.metrics.input.recordsRead|internal.metrics.output.bytesWritten|internal.metrics.output.recordsWritten|internal.metrics.shuffle.read.remoteBytesRead|internal.metrics.shuffle.read.localBytesRead|internal.metrics.shuffle.read.recordsRead|internal.metrics.shuffle.write.bytesWritten|internal.metrics.shuffle.write.recordsWritten' > ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json

###########################################################################################################################################################################################

## Creating some necessary files:

touch ${TEMP_FILE}/${EVENT_LOG_1}_input_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_input_bytes.out ${TEMP_FILE}/${EVENT_LOG_1}_input_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_input_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_1}_input_records.out ${TEMP_FILE}/${EVENT_LOG_2}_input_records.out ${TEMP_FILE}/${EVENT_LOG_1}_output_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_output_bytes.out ${TEMP_FILE}/${EVENT_LOG_1}_output_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_output_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_1}_output_records.out ${TEMP_FILE}/${EVENT_LOG_2}_output_records.out ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_bytes.out ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_records.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_records.out ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_bytes.out ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_records.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_records.out 

######  Input data calculation:
Input_Data_Records=$(grep -A1 'internal.metrics.input' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Input.RecordsRead.Integer: ${Input_Data_Records}" > ${TEMP_FILE}/${EVENT_LOG_1}_input_records.out


Input_Data_Size=$(grep -A1 'internal.metrics.input' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Input.BytesRead.Integer: ${Input_Data_Size}" > ${TEMP_FILE}/${EVENT_LOG_1}_input_bytes.out

if [ -n "$Input_Data_Size" ]; then
   echo "Input.BytesRead.Readable: `numfmt --to=iec-i $Input_Data_Size`" > ${TEMP_FILE}/${EVENT_LOG_1}_input_bytes_iec.out
fi

### Second Event log:
Input_Data_Records=$(grep -A1 'internal.metrics.input' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Input.RecordsRead.Integer: ${Input_Data_Records}" > ${TEMP_FILE}/${EVENT_LOG_2}_input_records.out


Input_Data_Size=$(grep -A1 'internal.metrics.input' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Input.BytesRead.Integer: ${Input_Data_Size}" > ${TEMP_FILE}/${EVENT_LOG_2}_input_bytes.out

if [ -n "$Input_Data_Size" ]; then
   echo "Input.BytesRead.Readable: `numfmt --to=iec-i $Input_Data_Size`" > ${TEMP_FILE}/${EVENT_LOG_2}_input_bytes_iec.out
fi

###########################################################################################################################################################################################

######  Output data calculation:
Output_Data_Records=$(grep -A1 'internal.metrics.output' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Output.RecordsRead.Integer: ${Output_Data_Records}" > ${TEMP_FILE}/${EVENT_LOG_1}_output_records.out


Output_Data_Size=$(grep -A1 'internal.metrics.output' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Output.BytesRead.Integer: ${Output_Data_Size}" > ${TEMP_FILE}/${EVENT_LOG_1}_output_bytes.out

if [ -n "$Output_Data_Size" ]; then
   echo "Output.BytesRead.Readable: `numfmt --to=iec-i $Output_Data_Size`" > ${TEMP_FILE}/${EVENT_LOG_1}_output_bytes_iec.out
fi

### Second Event log:
Output_Data_Records=$(grep -A1 'internal.metrics.output' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Output.RecordsRead.Integer: ${Output_Data_Records}" > ${TEMP_FILE}/${EVENT_LOG_2}_output_records.out


Output_Data_Size=$(grep -A1 'internal.metrics.output' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Output.BytesRead.Integer: ${Output_Data_Size}" > ${TEMP_FILE}/${EVENT_LOG_2}_output_bytes.out

if [ -n "$Output_Data_Size" ]; then
   echo "Output.BytesRead.Readable: `numfmt --to=iec-i $Output_Data_Size`" > ${TEMP_FILE}/${EVENT_LOG_2}_output_bytes_iec.out
fi

###########################################################################################################################################################################################

######  Shuffle Read calculation:
Shuffle_Read_Records=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'read' | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.RecordsRead.Integer: ${Shuffle_Read_Records}" > ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_records.out


Shuffle_Read_Size=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'read' | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.BytesRead.Integer: ${Shuffle_Read_Size}" > ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_bytes.out

if [ -n "$Shuffle_Read_Size" ]; then
   echo "Shuffle.BytesRead.Readable: `numfmt --to=iec-i $Shuffle_Read_Size`" > ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_bytes_iec.out
fi

### Second Event log:
Shuffle_Read_Records=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'read' | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.RecordsRead.Integer: ${Shuffle_Read_Records}" > ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_records.out


Shuffle_Read_Size=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'read' | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.BytesRead.Integer: ${Shuffle_Read_Size}" > ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_bytes.out

if [ -n "$Shuffle_Read_Size" ]; then
   echo "Shuffle.BytesRead.Readable: `numfmt --to=iec-i $Shuffle_Read_Size`" > ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_bytes_iec.out
fi

###########################################################################################################################################################################################

######  Shuffle Write calculation:
Shuffle_Write_Records=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'write' | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.RecordsWrite.Integer: ${Shuffle_Write_Records}" > ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_records.out


Shuffle_Read_Size=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_1}_data_metrics.json | grep -A1 -i 'write' | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.BytesWrite.Integer: ${Shuffle_Read_Size}" > ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_bytes.out

if [ -n "$Shuffle_Read_Size" ]; then
   echo "Shuffle.BytesWrite.Readable: `numfmt --to=iec-i $Shuffle_Read_Size`" > ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_bytes_iec.out
fi

### Second Event log:
Shuffle_Write_Records=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'write' | grep -A1 -i 'records' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.RecordsWrite.Integer: ${Shuffle_Write_Records}" > ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_records.out


Shuffle_Read_Size=$(grep -A1 'internal.metrics.shuffle' \
    ${TEMP_FILE}/${EVENT_LOG_2}_data_metrics.json | grep -A1 -i 'write' | grep -A1 -i 'bytes' | grep -i value | cut -d':' -f2 | cut -d',' -f1 | awk '{sum+=$1} END{print sum}')

echo "Shuffle.BytesWrite.Integer: ${Shuffle_Read_Size}" > ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_bytes.out

if [ -n "$Shuffle_Read_Size" ]; then
   echo "Shuffle.BytesWrite.Readable: `numfmt --to=iec-i $Shuffle_Read_Size`" > ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_bytes_iec.out
fi

###########################################################################################################################################################################################

### Listing configuration differences:
echo -e "\t====================\n\tJVM Information Diff\n\t===================="
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_jvm_info.json ${TEMP_FILE}/${EVENT_LOG_2}_jvm_info.json 

echo -e "\n\t=====================\n\tSpark Properties Diff\n\t=====================" 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_spark_prop.json ${TEMP_FILE}/${EVENT_LOG_2}_spark_prop.json 

echo -e "\n\t======================\n\tHadoop Properties Diff\n\t======================"
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_hadoop_prop.json ${TEMP_FILE}/${EVENT_LOG_2}_hadoop_prop.json 

echo -e "\n\t======================\n\tSystem Properties Diff\n\t======================"
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_system_prop.json ${TEMP_FILE}/${EVENT_LOG_2}_system_prop.json 

echo -e "\n\t======================\n\tClasspath Entries Diff\n\t======================"
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_classpath_entry.json ${TEMP_FILE}/${EVENT_LOG_2}_classpath_entry.json 

### Listing Data differences:
echo -e "\n\t====================\n\tInput Data Diff\n\t===================="
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_input_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_input_bytes.out
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_input_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_input_bytes_iec.out 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_input_records.out ${TEMP_FILE}/${EVENT_LOG_2}_input_records.out 

echo -e "\n\t=====================\n\tOutput Data Diff\n\t====================="
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_output_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_output_bytes.out 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_output_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_output_bytes_iec.out 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_output_records.out ${TEMP_FILE}/${EVENT_LOG_2}_output_records.out 

echo -e "\n\t======================\n\tShuffle Read Data Diff\n\t======================"
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_bytes.out 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_bytes_iec.out 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_read_records.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_read_records.out 

echo -e "\n\t======================\n\tShuffle Write Data Diff\n\t======================"
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_bytes.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_bytes.out 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_bytes_iec.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_bytes_iec.out 
sdiff -s ${TEMP_FILE}/${EVENT_LOG_1}_shuffle_write_records.out ${TEMP_FILE}/${EVENT_LOG_2}_shuffle_write_records.out 

###########################################################################################################################################################################################

### Clearing the temporary files:
rm -rf $TEMP_FILE/${EVENT_LOG_1}* $TEMP_FILE/${EVENT_LOG_2}*

#diff -u $TEMP_FILE/$1_classpath_entry.json $TEMP_FILE/$2_classpath_entry.json | grep --color -e ^- -e ^+ | awk '/^[[:space:]]*\+/{ print; print ""; next } { print }' | grep --color -e ^- -e ^+ -e ^$
