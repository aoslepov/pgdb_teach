#!/bin/bash
get_role=${1-master}
read_from_master=1
node_ip={{ ansible_default_ipv4.address }}
lag_limit=100 # lag limit MB

state_node=$(curl -s http://$node_ip:8008/patroni  | jq .state | sed 's/"//g')
role_node=$(curl -s http://$node_ip:8008/patroni  | jq .role | sed 's/"//g')
let "lag_node= $(curl -s http://$node_ip:8008/cluster | jq .members |jq '.[] | select(.name=="{{ansible_hostname}}")| .lag') / 1024/1024"

#echo $state_node" "$role_node " "$lag_node

#check node status
if [[ $state_node != "running" ]]; then echo  "node not stared"; exit 3; fi
#check status role
if [[ ($role_node != "master") && ($role_node != "replica")  ]]; then echo  "node failed"; exit 3; fi



check_master() {

#check master
if [[  $role_node == $get_role ]]; then 
	echo  "node status is master" 
	exit 0
else
	echo  "node status is NOT master"; exit 3;
fi

}

check_replica() {

if [[  ($role_node == $get_role) && ($lag_node -lt $lag_limit) ]]; then
#if [[  ($role_node == $get_role) ]]; then

	echo  "node status is replica "; exit 0;
	else
	if [[ ($read_from_master == 1) && ($role_node = "master")  ]]; then
	    echo  "node status is replica READ"; exit 0;
	else
	    echo  "node status is NOT replica"; exit 3;
	fi

fi

}


if [[ $get_role = "master" ]]; then check_master; fi

if [[ $get_role = "replica" ]]; then check_replica; fi


