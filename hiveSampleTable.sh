#!/bin/bash

TEMP_LOCATION=/var/tmp/hiveLoadData
mkdir $TEMP_LOCATION

DATABASE=taxi_info

## Download the data.
echo -e "\n\t-> Downloading data files ..."
curl -so $TEMP_LOCATION/fhvhv_tripdata_2023-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/fhvhv_tripdata_2023-01.parquet
curl -so $TEMP_LOCATION/fhv_tripdata_2023-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/fhv_tripdata_2023-01.parquet
curl -so $TEMP_LOCATION/green_tripdata_2023-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2023-01.parquet
curl -so $TEMP_LOCATION/yellow_tripdata_2023-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet

## Upload the data to HDFS.
echo -e "\n\t-> Uploading data files to HDFS ..."
hdfs dfs -put $TEMP_LOCATION/fhv_tripdata_2023-01.parquet $TEMP_LOCATION/fhvhv_tripdata_2023-01.parquet $TEMP_LOCATION/green_tripdata_2023-01.parquet $TEMP_LOCATION/yellow_tripdata_2023-01.parquet /tmp/

## Creating the HQL files.
echo -e "\n\t-> Generating SQL queries ..."
echo -e "CREATE DATABASE IF NOT EXISTS ${DATABASE};\nUSE ${DATABASE};\n\nCREATE TABLE IF NOT EXISTS for_hire_vechicle (dispatching_base_num string, pickup_datetime timestamp, dropOff_datetime timestamp, PUlocationID double, DOlocationID double, SR_Flag int, Affiliated_base_number string) STORED AS parquet;\nCREATE EXTERNAL TABLE IF NOT EXISTS fhv_high_volume (hvfhs_license_num string, dispatching_base_num string, originating_base_num string, request_datetime timestamp, on_scene_datetime timestamp, pickup_datetime timestamp, dropoff_datetime timestamp, PULocationID bigint, DOLocationID bigint, trip_miles double, trip_time bigint, base_passenger_fare double, tolls double, bcf double, sales_tax double, congestion_surcharge double, airport_fee double, tips double, driver_pay double, shared_request_flag string, shared_match_flag string, access_a_ride_flag string, wav_request_flag string, wav_match_flag string) STORED AS parquet;\nCREATE TABLE IF NOT EXISTS green_tripdata (VendorID bigint, lpep_pickup_datetime timestamp, lpep_dropoff_datetime timestamp, store_and_fwd_flag string, RatecodeID double, PULocationID bigint, DOLocationID bigint, passenger_count double, trip_distance double, fare_amount double, extra double, mta_tax double, tip_amount double, tolls_amount double, ehail_fee int, improvement_surcharge double, total_amount double, payment_type double, trip_type double, congestion_surcharge double) STORED AS parquet;\nCREATE EXTERNAL TABLE IF NOT EXISTS yellow_tripdata (VendorID bigint, tpep_pickup_datetime timestamp, tpep_dropoff_datetime timestamp, passenger_count double, trip_distance double, RatecodeID double, store_and_fwd_flag string, PULocationID bigint, DOLocationID bigint, payment_type bigint, fare_amount double, extra double, mta_tax double, tip_amount double, tolls_amount double, improvement_surcharge double, total_amount double, congestion_surcharge double, airport_fee double) STORED AS parquet;" > $TEMP_LOCATION/create_database_table.hql

echo -e "USE ${DATABASE};\n\nLOAD DATA INPATH '/tmp/fhv_tripdata_2023-01.parquet' INTO TABLE for_hire_vechicle;\nLOAD DATA INPATH '/tmp/fhvhv_tripdata_2023-01.parquet' INTO TABLE fhv_high_volume;\nLOAD DATA INPATH '/tmp/green_tripdata_2023-01.parquet' INTO TABLE green_tripdata;\nLOAD DATA INPATH '/tmp/yellow_tripdata_2023-01.parquet' INTO TABLE yellow_tripdata;" > $TEMP_LOCATION/load_data.hql

## Running the SQL files.
echo -e "\n\t-> Running the SQL queries ..."

KRB_ENABLED=1

if [ "$KRB_ENABLED" -eq 0 ]; then
    beeline -n hive -p hive -f $TEMP_LOCATION/create_database_table.hql 2&> /dev/null
    beeline -n hive -p hive -f $TEMP_LOCATION/load_data.hql 2&> /dev/null
else
	beeline -f $TEMP_LOCATION/create_database_table.hql 2&> /dev/null
    beeline -f $TEMP_LOCATION/load_data.hql 2&> /dev/null
fi

## Deleting the files.
echo -e "\n\t-> Deleting all files ..."
hdfs dfs -rm -f -skipTrash $TEMP_LOCATION/fhv_tripdata_2023-01.parquet $TEMP_LOCATION/fhvhv_tripdata_2023-01.parquet $TEMP_LOCATION/green_tripdata_2023-01.parquet $TEMP_LOCATION/yellow_tripdata_2023-01.parquet 2&> /dev/null
rm -rf $TEMP_LOCATION 

echo -e "\n\t >>> Data loaded to the tables under Database ${DATABASE} <<<\n"