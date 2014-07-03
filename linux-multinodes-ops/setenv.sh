#! /bin/bash
# 
# This script starts the full cluster in the right order (make sure the right nodes are active and passive, determined by the start order)
#

export RUN_AS_USER="@some_system_user@"
export TERRACOTTA_HOME="@terracotta_home_path@"
export TERRACOTTA_CONFIG_XML="@terracotta_config_home_path@/tc-config.xml"
export REMOTE_JAVA_HOME="@path_to_java_on_remote@"

REMOTE_JAVA_OPTS="-server -Xms1G -Xmx1G -XX:+UseParallelOldGC -XX:+UseCompressedOops"
#REMOTE_JAVA_OPTS="${REMOTE_JAVA_OPTS} -verbose:gc -Xloggc:run.gc.log -XX:+PrintGCDetails -XX:+PrintTenuringDistribution -XX:+PrintGCTimeStamps"
#REMOTE_JAVA_OPTS="${REMOTE_JAVA_OPTS} -Dcom.sun.management.jmxremote.port=7070 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

export REMOTE_JAVA_OPTS="${REMOTE_JAVA_OPTS}"