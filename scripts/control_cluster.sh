#!/bin/bash 

# Start or stop the cluster, to keep your free tier a while! :)

start_cluster() {
    echo "Starting instances..."
    gcloud compute instances start --async $(gcloud compute instances list --filter TERMINATED | grep -v "NAME" | awk '{ print $1}')
}

stop_cluster() {
    echo "Stopping instances..."
    gcloud compute instances stop --async $(gcloud compute instances list --filter RUNNING | grep -v "NAME" | awk '{ print $1}')
}

if [[ $1 == "start" ]]
then
    start_cluster
elif [[ $1 == "stop" ]]
then
    stop_cluster
else
    echo "Not an option..."
fi

