#! /bin/bash
# 
# This script automates some common tasks related to terracotta cluster management

VERSION="0.0.1"
LINUX_USER=

echo "Configs:"
echo $TERRACOTTA_HOME
echo $TERRACOTTA_CONFIG_XML

help()
{
    echo ""
    echo "USAGE: $0 <options> <start|stop>"
    echo "  -s list of TC servers separated by commas (TC server must be formatted as <IP or FDQN>/<TC Node Name>)"
    echo "  -u specify unix user to connect and run as"
    echo "  -h list this help message"
    echo ""
    echo "Commands can be one of: "
    echo "  start       # Start the terracotta process on the specified node(s)"
    echo "  stop        # Stop the terracotta process on the specified node(s)"
    echo ""
}

error()
{
    exit 1
}

listtcservers(){
        for i in "${NODE[@]}"; do 
            echo "$i"
        done
}

runcommand(){
    SSHCONNECT=
    SERVERADDRESS=
    TCSERVERNAME=
    
    echo "About to execute command '$CMD' against the following TC servers:"
    echo "$NODES"
    
    IFS=',' read -ra NODE <<< "$NODES"
    for i in "${NODE[@]}"; do 
    	echo "=========================================================================================="
    	#parsing the node definition
        IFS='/'; TOKENS=( $i );
        #check if formatted right (there should be 2 tokens)
    	if [ ! ${#TOKENS[@]} -eq 2 ]; then
    		echo "Server node is not formatted right. Should be <server name/address>/<tc server name>"
    	else
    	    SERVERADDRESS=${TOKENS[0]}
            TCSERVERNAME=${TOKENS[1]}
    	
    		if [ $SERVERADDRESS == "localhost" ] || [ $SERVERADDRESS == "127.0.0.1" ] ; then
    			export JAVA_HOME="$REMOTE_JAVA_HOME"
            	export JAVA_OPTS="$REMOTE_JAVA_OPTS"
            	if [ $CMD == "start" ]; then
            		exec "$TERRACOTTA_HOME/bin/start-tc-server.sh" -f "$TERRACOTTA_CONFIG_XML" -n "$TCSERVERNAME" &
        		elif [ $CMD == "stop" ]; then
        		    exec "$TERRACOTTA_HOME/bin/stop-tc-server.sh" -f "$TERRACOTTA_CONFIG_XML" -n "$TCSERVERNAME" &
        		else
        			echo "Didn't understand command...do nothing";
            	fi
    		else
    			if [ -n "$LINUX_USER" ]; then
	        	    SSHCONNECT="$LINUX_USER@$SERVERADDRESS"
	           	 	echo "SSH connect with '$SSHCONNECT' and running command '$CMD' for tc node '$TCSERVERNAME'..."
            	else
            	    SSHCONNECT="$SERVERADDRESS"
            	    echo "SSH connect with '<CurrentUser>@$SSHCONNECT' and running command '$CMD' for tc node '$TCSERVERNAME'..."
            	fi
    	
            	
            	if [ $CMD == "start" ]; then
            		ssh -f "$SSHCONNECT" "export JAVA_HOME=$REMOTE_JAVA_HOME; export JAVA_OPTS='$REMOTE_JAVA_OPTS'; $TERRACOTTA_HOME/bin/start-tc-server.sh -f $TERRACOTTA_CONFIG_XML -n $TCSERVERNAME"
        		elif [ $CMD == "stop" ]; then
        		    ssh -f "$SSHCONNECT" "export JAVA_HOME=$REMOTE_JAVA_HOME; export JAVA_OPTS='$REMOTE_JAVA_OPTS'; $TERRACOTTA_HOME/bin/stop-tc-server.sh -f $TERRACOTTA_CONFIG_XML -n $TCSERVERNAME"
        		else
        			echo "Didn't understand command...do nothing";
            	fi
    		fi
    		
            #wait between each server operation
	        echo "Short wait between commands..."
     	    sleep 1
     	fi
    done
}

# Parse Params
while getopts aqhvds:u: flag
do
    case "$flag" in
    (h) help; exit 0;;
    (s) NODES="$OPTARG";;
    (u) LINUX_USER="$OPTARG";;
    (*) help; exit 0;;
    esac
done
shift $(expr $OPTIND - 1)

if [ -n "$NODES" ]; then
     case "$1" in
        ("start") CMD="start";runcommand;;
        ("stop") CMD="stop";runcommand;;
        (*) echo "Didn't understand command"; help; error;;
     esac
else
    help;
    exit 1;
fi