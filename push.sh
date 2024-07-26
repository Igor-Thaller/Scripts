#!/bin/bash
# Color text output
RESET='\033[0m'
GREEN='\033[0;32m'

green_color() {
  echo -e "${GREEN}$1${RESET}"
}

rollback() {
  local host=$1
  local vmid1=$2
  local snapshot1=$3
  local vmid2=$4
  local snapshot2=$5
  local vmid3=$6
  local snapshot3=$7

  echo "Rolling back 'Kubernetes' on $host"

  ssh root@$host "qm rollback $vmid1 $snapshot1" &
  ssh root@$host "qm rollback $vmid2 $snapshot2" &
  ssh root@$host "qm rollback $vmid3 $snapshot3" &

  wait
}

copy_script() {
  local source=$1
  local destination=$2

  echo "Copying script to $destination"
  scp $source $destination &
}

rollback 192.168.100.2 116 test-rollback 115 test-rollback 117 test-rollback

copy_script debian-kubernetes-autoinstaller.sh igor@192.168.100.22:/home/igor/Scripts
copy_script debian-kubernetes-autoinstaller.sh igor@192.168.100.23:/home/igor/Scripts
copy_script debian-kubernetes-autoinstaller.sh igor@192.168.100.24:/home/igor/Scripts

wait

green_color "Complete Reset and send over the new files"
