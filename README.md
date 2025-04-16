## NOTE: Some scripts are taken from some other GitHub repositories.

# Scripts

We have some handy scripts which will help us in reducing the manual work for few operations.

==================================================================================

Links to How-To section for the scripts:

- [capture_jstack.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#capture_jstacksh)
- [copy_keytabs.sh](https://github.com/Deepannagaraj/scripts/tree/main?tab=readme-ov-file#copy_keytabssh)
- [event_configs.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#event_configssh)
- [hiveRandomDataGen.py](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#hiveRandomDataGenpy)
- [hiveSampleTable.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#hiveSampleTablesh)
- [sparkdiff.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#sparkdiffsh)
- [split_log_yarn.py](https://github.com/Deepannagaraj/scripts/blob/main/README.md#split_log_yarnpy)
- [timedifference.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#timedifferencesh)

==================================================================================

## capture_jstack.sh

This script is used to capture the JSTACKs for containers running on a NodeManager (YARN).

Copy the content of the script to the NodeManager node:
```bash
curl -so /var/tmp/capture_jstack.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/capture_jstack.sh
```

Once the YARN application is in RUNNING state, we can run the script like below:
```bash
sh /var/tmp/capture_jstack.sh APP_ID/APP_NAME USER PATH INTERATIONS SLEEPTIME
```

For long running applications, we can add the below statement to the crontab file to capture the JSTACKs regularly.
```bash
*/6 * * * * sh /var/tmp/capture_jstack.sh APP_ID/APP_NAME USER PATH INTERATIONS SLEEPTIME >> /PATH_TO/command_output.txt
```

## copy_keytabs.sh

This script copies all recent Service Keytabs to the specified path.

Download the scripts to the local node.
```bash
curl -so /var/tmp/copy_keytabs.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/refs/heads/main/copy_keytabs.sh
```

Run the script to copy the Keytabs.
```bash
sh /var/tmp/copy_keytabs.sh
```

## capture_lsof_ofd.sh

This script is used to capture the lsof output for containers running on a NodeManager (YARN).

Copy the content of the script to the NodeManager node:
```bash
curl -so /var/tmp/capture_lsof_ofd.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/refs/heads/main/capture_lsof_ofd.sh
```

Once the YARN application is in RUNNING state, we can run the script like below:
```bash
sh /var/tmp/capture_lsof_ofd.sh APP_ID/APP_NAME PATH INTERATIONS SLEEPTIME
```

For long running applications, we can add the below statement to the crontab file to capture the JSTACKs regularly.
```bash
*/6 * * * * sh /var/tmp/capture_lsof_ofd.sh APP_ID/APP_NAME PATH INTERATIONS SLEEPTIME >> /PATH_TO/command_output.txt
```

## event_configs.sh

Using this script we can find the value of a configuration parameter from Spark event log file.

Download the scripts to the local node.
```bash
curl -so /var/tmp/event_configs.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/event_configs.sh
```

Run the command like below.
```bash
sh /var/tmp/event_configs.sh SPARK_EVENT_LOG | grep CONFIG_TO_FIND
```

SAMPLE OUTPUT:
```bash
$ sh /var/tmp/event_configs.sh EVENT_LOG | grep 'deployMode'
    "spark.submit.deployMode": "client",
```

**NOTE:**
- Make sure we have the jq command available to run this script.

## hiveRandomDataGen.py

Using this Python code, we can generate random data for the given table schema.

Download the scripts to the local node.
```bash
curl -so /var/tmp/hiveRandomDataGen.py https://raw.githubusercontent.com/Deepannagaraj/scripts/main/hiveRandomDataGen.py
```

Generate the table_schema.out file.
```bash
beeline -e "SHOW CREATE TABLE database.table" > table_schema.out
```

Run the command like below.
```bash
python /var/tmp/hiveRandomDataGen.py -s table_schema.out -n 300 **OPTIONAL** -p 1 -d database
```

SAMPLE OUTPUT:
```bash
$ python /var/tmp/hiveRandomDataGen.py -s schema.out -n 300 -p 1


Parsing input schema

Checking main columns
     3 columns found.

Checking partitions
     1 partitions found.

Generating 300 rows for 3
 columns and 1 partitions in table orc_table.

All done. Please execute: 
         $ beeline -f HiveRandom.hql

Time: 2 s.

$ beeline -f HiveRandom.hql
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/opt/cloudera/parcels/CDH-7.2.18-1.cdh7.2.18.p0.51297892/jars/log4j-slf4j-impl-2.18.0.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/opt/cloudera/parcels/CDH-7.2.18-1.cdh7.2.18.p0.51297892/jars/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]

>>> SNIPPED <<<

----------------------------------------------------------------------------------------------
VERTICES: 03/03  [==========================>>] 100%  ELAPSED TIME: 18.13 s    
----------------------------------------------------------------------------------------------
301 rows affected (24.182 seconds)
```

## hiveSampleTable.sh

This script will create four tables under database *taxi_info* for testings.

Download the scripts to the local node.
```bash
curl -so /var/tmp/hiveSampleTable.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/hiveSampleTable.sh
```

Run the command like below.
```bash
sh /var/tmp/hiveSampleTable.sh
```

SAMPLE OUTPUT:
```bash
$ sh /var/tmp/hiveSampleTable.sh 

        -> Downloading data files ...

        -> Uploading data files to HDFS ...

        -> Generating SQL queries ...

        -> Running the SQL queries ...

        -> Deleting all files ...

         >>> Data loaded to the tables under Database taxi_info <<<
```

## sparkdiff.sh

Using this script we can find the configuration differences between two Spark applications.

Download the scripts to the local node.
```bash
curl -so /var/tmp/sparkdiff.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/sparkdiff.sh
```

Run the command like below.
```bash
sh /var/tmp/sparkdiff.sh EVENT_LOG_1 EVENT_LOG_2
```

SAMPLE OUTPUT:
```bash
$ sh /var/tmp/sparkdiff.sh EVENT_LOG_1 EVENT_LOG_2
10,11c10,11
< "spark.driver.maxResultSize":"4g"
< "spark.driver.memory":"20G"
---
> "spark.driver.maxResultSize":"3g"
> "spark.driver.memory":"60G"
16c16
< "spark.executor.cores":"4"
---
> "spark.executor.cores":"3"
91,93c91,93
< "BytesRead.integer":"1175839872364"
< "BytesRead.iec":"1.1Ti"
< "RecordsRead.integer":"96324947297"
---
> "BytesRead.integer":"1333777864594"
> "BytesRead.iec":"1.3Ti"
> "RecordsRead.integer":"90636862794"
```

## split_log_yarn.py

This python code can be used to split the YARN application logs to separate container logs.

Download the scripts to the local node.
```bash
curl -so /var/tmp/split_log_yarn.py https://raw.githubusercontent.com/Deepannagaraj/scripts/main/split_log_yarn.py
```

Split the YARN Application logs.
```bash
python /var/tmp/split_log_yarn.py <APPLICATION_LOG> <OUTPUT_DIR>
```

Continue to troubleshoot the issue with the split logs.

## timedifference.sh

We can use this script to find the time taken for a container to run / finish.

Download the scripts to the local node.
```bash
curl -so /var/tmp/timedifference.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/timedifference.sh
curl -so /var/tmp/split_log_yarn.py https://raw.githubusercontent.com/Deepannagaraj/scripts/main/split_log_yarn.py
```

Split the YARN Application logs.
```bash
python /var/tmp/split_log_yarn.py <APPLICATION_LOG> <OUTPUT_DIR>
```

Once the logs are split, pick any container log and run the below command.
```bash
sh /var/tmp/timedifference.sh CONTAINER_LOG
```

SAMPLE OUTPUT:
```bash
$ python /var/tmp/split_log_yarn.py APPLICATIONLOG APPLICATIONLOG-split

$ sh /var/tmp/timedifference.sh APPLICATIONLOG-split/containers/CONTAINERID/stderr

        -> Start Timestamp:     2024-03-28 14:14:32

        -> End Timestamp:       2024-03-29 08:25:41

        ==> Total time taken:   0 days 18 hours 11 minutes 9 seconds
```

**NOTE:**
- This script might not work properly for YARN Applications which are using custom log4j.properties.