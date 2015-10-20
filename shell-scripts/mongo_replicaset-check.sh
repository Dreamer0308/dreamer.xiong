#!/bin/bash
### Error Code ###
# -0.9903 --- the first argument of this sub script is empty
# -0.9904 --- the first argument of this sub script is not found
# -0.9905 --- the folder permission is not correct
# -0.9906 --- can not get replica status
# -0.9907 --- wrong js file

MONGO=/usr/bin/mongo
serverstatus="/home/zabbix/tmp/mongodb-replica.status"
serverstatusjs="/home/zabbix/bin/mongo_Replica.js"
tmp_folder="/home/zabbix/tmp"
monogstat_bin="/usr/bin/mongostat"
mongo_user=""
mongo_pwd=""
mongo_port=27017
ORIGINAL_STAT=2
NODE_IP=$2

### Function ###
check_return(){
if [ $? -ne 0 ]
    then
        echo "$1"
        exit 1
fi
}


# Check the folder
[ -d "$tmp_folder" -a -r "$tmp_folder" -a -w  "$tmp_folder" -a -x "$tmp_folder" ]
check_return "-0.9905"

#if js file doesn't exist, then add the content to the file
if [ ! -s $serverstatusjs ]; then
    cat > "$serverstatusjs" << EOF
printjson(rs.printReplicationInfo())
printjson(rs.status())
EOF

fi
check_return "-0.9907"

# if no user is provided, don't use authentication
if [ -z "$mongo_user" ]; then
    $MONGO admin --port $mongo_port $serverstatusjs > $serverstatus 2> /dev/null
    check_return "-0.9906"
else
    $MONGO -u $mongo_user -p$mongo_pwd admin --port 10100 $serverstatusjs > $serverstatus 2> /dev/null
    check_return "-0.9906"
fi
                                                           
check(){
    keyword=`echo $1 |  sed 's/^ *//;s/ *$//'`
    #check the argument is empty or not
    if [ -z "$keyword" ]; then
        echo "-0.9903"
        exit 1
    else
        #check the argument is exist or not preretval=$(grep -i $1' ' "$mysql_extended_file")
        if [ -z "$preretval" ]; then
            echo "-0.9904"
            exit 1
        else
            #check the argument's value is empty or not. if it is empty, give it "0"
            retval=$(echo "$preretval"|  awk '{ print $4 }' | sed 's/^ *//;s/ *$//')
            if [ -z "$retval" ]; then
                echo 0
                exit 0
            else
                echo $retval
                exit 0
            fi
        fi
    fi
}

#Check replication delay time
repl_delay() {
    CURRENT_STAT=$(cat $serverstatus|grep \"myState\" |awk '{print $3}'|awk -F ',' '{print $1}'|sed 's/ *$//g'|sed 's/^ *//g')
    if [ $? -ne 0 ]
    then
        echo "-0.9906"
        exit 1
    fi

    #Make sure the server is not master, if its master, then return normal code "0"
    #  delay_time = master_timestamp - node_timestamp
    if [ $CURRENT_STAT -ne 1 ]; then
        MY_IP=$(/sbin/ifconfig eth0|grep inet |awk '{print $2}'| awk -F'addr:' '{print $2}'|sed 's/ *$//g'|sed 's/^ *//g')
        MY_Timestamp=$(cat $serverstatus|grep -A5 $MY_IP|grep Timestamp|awk -F "[(|,]" '{print $2}')
        Master_Timestamp=$(cat $serverstatus|grep -A2 PRIMARY|grep Timestamp|awk -F "[(|,]" '{print $2}')
        node_delay=$(($Master_Timestamp-$MY_Timestamp))
        if [ $? -ne 0 ]
        then
            echo "-0.9906"
            exit 1
        fi
    echo $node_delay
    else
        echo "0"
        exit
    fi
}


# Check if current server is the primary of the mongo replica set or not
master_change() {
    #Check current server state,
    #  if it was 2(slave) and now is 1(master), 
    #    then return bad code 1, trigger the alert,
    #      "mongo master is down, now $hostname is master"
    CURRENT_STAT=$(cat $serverstatus|grep \"myState\" |awk '{print $3}'|awk -F ',' '{print $1}'|sed 's/ *$//g'|sed 's/^ *//g')
    if [ $? -ne 0 ]
    then
        echo "-0.9906"
        exit 1
    fi

    if [ $ORIGINAL_STAT -ne 1 -a $CURRENT_STAT -eq 1 ]; then
        echo "1"
    else
        echo "0"
    fi
}

# Check all nodes status from Master 
nodes_status() {
    if [ -z $NODE_IP ]; then
        echo "Wrong args, usage -- bash script.sh nodes_status \$ip"
        exit
    fi
    #As we always check the node status on the primary, 
    #  so before we check each node status,
    #    we need to ensure current server is the primary,
    #      if not, then return normal code "0" directly 
    CURRENT_STAT=$(cat $serverstatus|grep \"myState\" |awk '{print $3}'|awk -F ',' '{print $1}'|sed 's/ *$//g'|sed 's/^ *//g')
    if [ $? -ne 0 ]
    then
        echo "-0.9906"
        exit 1
    fi

    if [ $CURRENT_STAT -eq 1 ]; then
        NODE_STATUS=$(grep -A2 $NODE_IP $serverstatus|grep health|awk '{print $3}'|awk -F ',' '{print $1}'|sed 's/ *$//g'|sed 's/^ *//g')
        if [ $? -ne 0 ]
        then
            echo "-0.9906"
            exit 1
        fi

        if [ $NODE_STATUS -ne 1 ]; then
            echo "1"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}



case $1 in
    oplog_first     ) grep first  "$serverstatus" | awk -F 'time:' '{ print $2 }'|sed 's/ *$//g'|sed 's/^ *//g';;
    oplog_last      ) grep last   "$serverstatus" | awk -F 'time:' '{ print $2 }'|sed 's/ *$//g'|sed 's/^ *//g';;
    oplog_size      ) grep size   "$serverstatus" | awk -F':' '{print $2}'|sed 's/ *$//g'|sed 's/^ *//g';;
    oplog_length    ) grep length "$serverstatus" | awk -F':' '{print $2}'|awk -F'secs' '{print $1}'| sed 's/ *$//g' | sed 's/^ *//g';;
    repl_delay      ) repl_delay;;
    master_change   ) master_change;;
    nodes_status    ) nodes_status;;
    *               ) check "$1";;
esac

