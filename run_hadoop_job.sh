#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <job_name> <output_folder>"
    exit 1
fi

# Assign arguments to variables
JOB_NAME=$1
OUTPUT_FOLDER=$2

# Paths to your Hadoop job JAR and input folder in HDFS
JOB_JAR="/tmp/jobs/$JOB_NAME.jar"
INPUT_FOLDER="data/data"

# Check if the output folder already exists in HDFS and remove it if it does
hdfs dfs -test -e $OUTPUT_FOLDER
if [ $? -eq 0 ]; then
    echo "Output folder already exists. Removing it..."
    hdfs dfs -rm -r $OUTPUT_FOLDER
fi

# Execute the Hadoop job
echo "Executing Hadoop job: $JOB_NAME"
hadoop jar $JOB_JAR $INPUT_FOLDER $OUTPUT_FOLDER

# Check if the job was successful
if [ $? -eq 0 ]; then
    echo "Hadoop job executed successfully. Output is in $OUTPUT_FOLDER"
else
    echo "Hadoop job failed. Please check the logs for more details."
    exit 1
fi
