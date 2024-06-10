systemctl start docker
sudo docker-compose up
sudo docker cp data namenode:/tmp/data
sudo docker cp jobs namenode:/tmp/jobs
sudo docker exec -it namenode bash
hdfs dfs -put /tmp/data data/
hdfs dfs -ls data/data
