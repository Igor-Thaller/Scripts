#!/bin/bash
ssh root@192.168.100.2 'qm rollback 116 test-rollback'
scp debian-kubernetes-autoinstaller.sh igor@192.168.100.22:/home/igor/Scripts
