#!/bin/bash

KEYTAB_DIR=/var/tmp/keytabs/

mkdir -p $KEYTAB_DIR

for i in `find /var/run/cloudera-scm-agent/process -name *.keytab | cut -d'/' -f7 | sort | uniq`
    do echo -e "\n--> Finding latest Keytab file for:\t${i}"
    for j in `find /var/run/cloudera-scm-agent/process -name $i -type f -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1`
        do echo -e "--> Copying from file:\t${j}"
        echo -e "--> Copying to file:\t$KEYTAB_DIR${i}"
        cp -f -n ${j} $KEYTAB_DIR
    done
done
