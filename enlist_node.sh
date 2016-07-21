#!/bin/bash

set -u
#set -e

display_usage() {
  echo "enlist_node.sh <NODE_NAME> <FLAVOR> <TAG>"
  echo "ex.) enlist_node.sh node1 m1.small bootstrap" 
}


CreateInstance(){
  # create an instance with two nics
  echo nova boot --flavor $2 --image $glance_img_name --nic net-id=$maas_net_id --poll $1
  nova boot --flavor $2 --image $glance_img_name --nic net-id=$maas_net_id --poll $1
  echo nova interface-attach --net-id $maas_net_id $1
  nova interface-attach --net-id $maas_net_id $1
}

EnlistNodes(){
  maas_net_id=`neutron net-list | grep $maas_nw_name| cut -d\| -f2| tr -d ' '`
  echo "maas_net_id: "$maas_net_id
  echo "Start to enlist $1"
  CreateInstance $1 $2
  echo "retrieving mac for $1"
  ip=`nova show $1|grep "maas-network network"|cut -d\| -f3`
  if [[ $ip == *","* ]];then
    ip=`cut -d"," -f1 <<< "$ip"`
  fi
  echo "ip is "$ip
  mac=`neutron port-list|grep $ip|cut -d\| -f4`
  echo "mac is "$mac
  echo "Waiting if $1 is ready for commissioning. this will take a while..."
  sys_id=null
  while [ ${sys_id} = null ]
  do
    sleep 5
    sys_id=`maas $maas_user_name nodes list mac_address="$mac" | jq .[0].system_id | sed -e's/^"//'  -e 's/"$//'`
    echo -en "."
  done
  nova_id=`nova list | grep $1| cut -d'|' -f2 | tr -d ' '`
  echo maas $maas_user_name node update $sys_id power_type=nova
  maas $maas_user_name node update $sys_id power_type=nova
  echo maas $maas_user_name node update $sys_id power_parameters_nova_id=$nova_id \
  power_parameters_os_tenantname=$OS_TENANT_NAME \
  power_parameters_os_tenantname=$OS_TENANT_NAME \
  power_parameters_os_username=$OS_USERNAME \
  power_parameters_os_password=$OS_PASSWORD \
  power_parameters_os_authurl=$OS_AUTH_URL
  maas $maas_user_name node update $sys_id power_parameters_nova_id=$nova_id \
  power_parameters_os_tenantname=$OS_TENANT_NAME \
  power_parameters_os_tenantname=$OS_TENANT_NAME \
  power_parameters_os_username=$OS_USERNAME \
  power_parameters_os_password=$OS_PASSWORD \
  power_parameters_os_authurl=$OS_AUTH_URL
#  echo "Ready for commissioning"
#  echo maas $maas_user_name node update $sys_id hostname=$1
  maas $maas_user_name node update $sys_id hostname=$1
#  echo "Start commissioning $1"
  echo "sleep 20"
  sleep 20
  #maas $maas_user_name node commission $sys_id
}

TagNode(){
  tag=$2
  maas $maas_user_name tags list | grep "\"name\":" | grep $tag
  if [ $? -ne 0 ];then
    maas $maas_user_name tags new name=$tag
  fi
  sys_id=`maas $maas_user_name nodes list hostname=$1 | jq .[0].system_id | sed -e 's/^"//'  -e 's/"$//'`
  maas $maas_user_name tag update-nodes $tag add=$sys_id
}

### main ###

if [  $# -le 2 ];then
  display_usage
  exit 1
fi

source setvars
EnlistNodes $1 $2
TagNode $1 $3
