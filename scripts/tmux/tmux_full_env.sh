#!/bin/bash

tmux set -g pane-border-status top

tmux new-window -n "CKA k8s cluster"
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 2
tmux split-window -v

tmux select-pane -t 0
tmux send-keys 'gcloud compute ssh etcd-0' Enter
tmux select-pane -T "etcd-0"
tmux select-pane -t 1
tmux send-keys 'gcloud compute ssh master-0' Enter
tmux select-pane -T "master-0"
tmux select-pane -t 2
tmux send-keys 'gcloud compute ssh worker-0' Enter
tmux select-pane -T "worker-0"
tmux select-pane -t 3
tmux send-keys 'gcloud compute ssh worker-1' Enter
tmux select-pane -T "worker-1"

