## NOTE: Some scripts are taken from some other GitHub repositories.

# Scritps

We have some handy scripts which will help us in reducing the manual work for few operations.

==================================================================================

Links to How-To section for the scripts:

- [capture_jstack.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#capture_jstacksh)
- [timedifference.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#timedifferencesh)
- [sparkdiff.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#sparkdiffsh)
- [event_configs.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#event_configssh)

==================================================================================

## capture_jstack.sh

This script is used to capture the JSTACKs running on a NodeManager (YARN).

Copy the content of the script to the NodeManager node:
```bash
$ curl -o /var/tmp/capture_jstack.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/capture_jstack.sh
```

Once the YARN application is in RUNNING state, we can run the script like below:
```bash
$ sh /var/tmp/capture_jstack.sh APPID USER PATH INTERATIONS SLEEPTIME
```

For long running applications, we can add the below statement to the crontab file to capture the JSTACKs regularly.
```bash
*/6 * * * * sh /root/capture_jstack.sh APPID USER PATH INTERATIONS SLEEPTIME >> /PATH_TO/command_output.txt
```


## timedifference.sh

We can use this script to find the time taken for a container to run / finish.

Download the scripts to the local node.
```bash
$ curl -o /var/tmp/timedifference.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/timedifference.sh
$ curl -o /var/tmp/split_log_yarn.py https://raw.githubusercontent.com/Deepannagaraj/scripts/main/split_log_yarn.py
```

Split the YARN Application logs.
```bash
$ python /var/tmp/split_log_yarn.py <APPLICATION_LOG> <OUTPUT_DIR>
```

Once the logs are split, pick any container log and run the below command.
```bash
$ sh /var/tmp/timedifference.sh CONTAINER_LOG
```

SAMPLE OUTPUT:
```bash
$ python /var/tmp/split_log_yarn.py application_1707198725210_656778.log application_1707198725210_656778-split

$ sh /var/tmp/timedifference.sh application_1707198725210_656778-split/containers/container_e34_1707198725210_656778_01_000001/stderr 
        ==> Start Timstamp
24/04/03 19:34:12

        ==> Ending Timstamp
24/04/03 19:48:18

Total time taken
0 years 0 months 0 days 00 hours 14 minutes 06 seconds
```

**NOTE:**
- This script might not work properly for Spark Application which are using custom log4j.properties.
- This script might also not work properly for the other than Spark Applications.

## sparkdiff.sh

Using this script we can find the configuration differences between two Spark applications.

Download the scripts to the local node.
```bash
$ curl -o /var/tmp/sparkdiff.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/sparkdiff.sh
```

Run the command like below.
```bash
$ sh /var/tmp/sparkdiff.sh EVENT_LOG_1 EVENT_LOG_2
```

SAMPLE OUTPUT:
```bash
$ sh /var/tmp/sparkdiff.sh application_1710074961896_286303 application_1710074961896_286368
6,7c6,7
< "spark.app.id":"application_1711234513896_286303"
< "spark.app.name":"agg_customers"
---
> "spark.app.id":"application_1711234513896_286368"}
> "spark.app.name":"'agg_usage'"
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

**NOTE:**
- Make sure we have the python3 command available to run this script.

## event_configs.sh

Using this script we can find the value of a configuration parameter from Spark event log file.

Download the scripts to the local node.
```bash
$ curl -o /var/tmp/event_configs.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/event_configs.sh
```

Run the command like below.
```bash
$ sh /var/tmp/event_configs.sh SPARK_EVENT_LOG | grep CONFIG_TO_FIND
```

SAMPLE OUTPUT:
```bash
$ sh /var/tmp/event_configs.sh application_1710074961896_286303 | grep 'deployMode'
    "spark.submit.deployMode": "client",
```

**NOTE:**
- Make sure we have the jq command available to run this script.