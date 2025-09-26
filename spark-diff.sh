#!/bin/bash

## Listing only the configs from the Spark event logs:

if [ $# -ne 2 ]
then
   echo -e "\n\t>>> Incorrect Usage: <<<\n\n \t\t===> Usage: $0 <EVENT_LOG_1> <EVENT_LOG_2> <===\n"
   exit 1
fi

if ! [ -f "$1" ]; then
   echo -e "\n\tFirst file does not exist: $1\n\tProvide a valid File path\n"
   exit 3
fi

if ! [ -f "$2" ]; then
   echo -e "\n\tSecond file does not exist: $2\n\tProvide a valid File path\n"
   exit 3
fi

TEMP_FILE=~/.spark_diff

if ! [ -f "$TEMP_FILE" ]; then
   mkdir -p $TEMP_FILE
fi

grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."JVM Information"' > $TEMP_FILE/$1_jvm_info.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."Spark Properties"' > $TEMP_FILE/$1_spark_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."Hadoop Properties"' > $TEMP_FILE/$1_hadoop_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."System Properties"' > $TEMP_FILE/$1_system_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $1 | jq '."Classpath Entries"' > $TEMP_FILE/$1_classpath_entry.json

grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."JVM Information"' > $TEMP_FILE/$2_jvm_info.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."Spark Properties"' > $TEMP_FILE/$2_spark_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."Hadoop Properties"' > $TEMP_FILE/$2_hadoop_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."System Properties"' > $TEMP_FILE/$2_system_prop.json
grep '"Event":"SparkListenerEnvironmentUpdate"' $2 | jq '."Classpath Entries"' > $TEMP_FILE/$2_classpath_entry.json

echo -e "\t====================\n\tJVM Information Diff\n\t===================="
sdiff -s $TEMP_FILE/$1_jvm_info.json $TEMP_FILE/$2_jvm_info.json

echo -e "\n\t=====================\n\tSpark Properties Diff\n\t====================="
sdiff -s $TEMP_FILE/$1_spark_prop.json $TEMP_FILE/$2_spark_prop.json

echo -e "\n\t======================\n\tHadoop Properties Diff\n\t======================"
sdiff -s $TEMP_FILE/$1_hadoop_prop.json $TEMP_FILE/$2_hadoop_prop.json

echo -e "\n\t======================\n\tSystem Properties Diff\n\t======================"
sdiff -s $TEMP_FILE/$1_system_prop.json $TEMP_FILE/$2_system_prop.json

echo -e "\n\t======================\n\tClasspath Entries Diff\n\t======================"
sdiff -s $TEMP_FILE/$1_classpath_entry.json $TEMP_FILE/$2_classpath_entry.json

#diff -u $TEMP_FILE/$1_classpath_entry.json $TEMP_FILE/$2_classpath_entry.json | grep --color -e ^- -e ^+ | awk '/^[[:space:]]*\+/{ print; print ""; next } { print }' | grep --color -e ^- -e ^+ -e ^$

rm -rf $TEMP_FILE/$1* $TEMP_FILE/$2*