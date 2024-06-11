#!/bin/bash

# Array of job names
job_names=(
    "AverageOrderValue"
    "MonthlySalesPerProduct"
    "MonthlyTrends"
    "ProductPerformanceBySeason"
    "TopSellingProducts"
)

# Local paths
local_job_dir="./jobs"
local_script_path="./run_hadoop_job.sh"
local_output_base_path="./job_outputs"

# HDFS output folder base path
hdfs_output_base_path="/output"

# Docker container paths
container_job_dir="/tmp/jobs"
container_script_path="/tmp/run_hadoop_job.sh"

# Ensure the jobs directory and the script exist
if [ ! -d "$local_job_dir" ] || [ ! -f "$local_script_path" ]; then
    echo "Job directory or run_hadoop_job.sh script not found!"
    exit 1
fi

# Remove existing local output base path if it exists and create a new one
rm -rf $local_output_base_path
mkdir -p $local_output_base_path

# Copy job JARs and the script to the NameNode container
echo "Copying job JARs and run_hadoop_job.sh script to the NameNode container..."
docker exec -it namenode /bin/bash -c "rm -rf $container_job_dir && mkdir -p $container_job_dir"
docker exec -it namenode /bin/bash -c "rm -f $container_script_path"
docker cp "$local_job_dir/." namenode:$container_job_dir
docker cp "$local_script_path" namenode:$container_script_path

# Iterate over each job and execute it inside the NameNode container
counter=0
total_jobs=${#job_names[@]}
for job in "${job_names[@]}"; do
    hdfs_output_folder="${hdfs_output_base_path}/${job}"
    local_output_folder="${local_output_base_path}/${job}"
    
    echo "Running job: $job with HDFS output folder: $hdfs_output_folder"

    # Execute the Hadoop job
    docker exec -it namenode /bin/bash -c "/tmp/run_hadoop_job.sh $job $hdfs_output_folder"
    
    # Check the exit status of the last command
    if [ $? -eq 0 ]; then
        echo "Job $job executed successfully."
        
        # Create local output folder for this job
        mkdir -p $local_output_folder
        
        # Copy the output from HDFS to a temporary location in the NameNode container
        docker exec -it namenode /bin/bash -c "hdfs dfs -get $hdfs_output_folder /tmp/hdfs_output"
        
        # Copy the output from the container to the local file system
        docker cp namenode:/tmp/hdfs_output/. $local_output_folder
        
        # Clean up the temporary location in the container
        docker exec -it namenode /bin/bash -c "rm -rf /tmp/hdfs_output"
        
        echo "Output for job $job copied to local folder: $local_output_folder"
        counter=$((counter+1))
    else
        echo "Job $job failed."
    fi
done

echo "Finished running $counter jobs out of $total_jobs."

