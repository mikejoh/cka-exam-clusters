#!/bin/bash

tmux set -g pane-border-status top

tmux new-window -n "CKA k8s cluster workers"
tmux split-window -v
tmux select-pane -t 0
tmux send-keys 'gcloud compute ssh worker-0' Enter
tmux select-pane -T "worker-0"

tmux select-pane -t 1
tmux send-keys 'gcloud compute ssh worker-1' Enter
tmux select-pane -T "worker-1"

tmux set synchronize-panes on
