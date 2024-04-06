
# Scritps

We have some handy scripts which will help us in reducing the manual work for few operations.

==================================================================================

Links to How-To section for the scripts:

- [capture_jstack.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#capture_jstacksh)

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
$ curl -o /var/tmp/timedifference.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/capture_jstack.sh
$ curl -o /var/tmp/split_log_yarn.py https://raw.githubusercontent.com/Deepannagaraj/scripts/main/capture_jstack.sh
```

Split the YARN Application logs.
```bash
$ python /Users/dnagarathinam/Documents/commands/split_log_yarn <application_log> <output_dir>
```

Once the logs are split, pick any container log and run the below command.
```bash
$ /var/tmp/timedifference.sh CONTAINER_LOG
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