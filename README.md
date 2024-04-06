
# Scritps

We have some handy scripts which will help us in reducing the manual work for few operations.

==================================================================================

How-To Links:

- [capture_jstack.sh](https://github.com/Deepannagaraj/scripts?tab=readme-ov-file#capture_jstacksh)

==================================================================================

## capture_jstack.sh

This script is used to capture the JSTACKs running on a NodeManager (YARN).

Copy the content of the script to the NodeManager node:
```bash
  curl -o /var/tmp/capture_jstack.sh https://raw.githubusercontent.com/Deepannagaraj/scripts/main/capture_jstack.sh
```

Once the YARN application is in RUNNING state, we can run the script like below:
```bash
  sh /var/tmp/capture_jstack.sh APPID USER PATH INTERATIONS SLEEPTIME
```

For long running applications, we can add the below statement to the crontab file to capture the JSTACKs regularly.
```bash
  */6 * * * * sh /root/capture_jstack.sh APPID USER PATH INTERATIONS SLEEPTIME >> /PATH_TO/command_output.txt
```
