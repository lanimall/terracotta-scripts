#! /bin/bash
# 
# This script starts the full cluster in the right order (make sure the right nodes are active and passive, determined by the start order)
#

. "setenv.sh"
exec "manage-tc-cluster.sh" -s remotehost1/node1,remotehost2/node2 start