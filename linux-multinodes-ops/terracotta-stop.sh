#! /bin/bash
# 
# This script stops the full cluster in the right order (standby first)
#

. "setenv.sh"
exec "manage-tc-cluster.sh" -s remotehost1/node1,remotehost2/node2 stop