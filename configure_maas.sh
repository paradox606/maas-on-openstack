#!/bin/bash

set -u
#set -e

ConfigureMAAS(){
  # Create admin user and login
    echo sudo maas-region-admin createadmin --username $maas_user_name --password $maas_passwd --email root@example.com
    sudo maas-region-admin createadmin --username $maas_user_name --password $maas_passwd --email root@example.com
    echo maas login $maas_user_name http://localhost/MAAS/api/1.0 "`sudo maas-region-admin apikey --username $maas_user_name`"
    maas login $maas_user_name http://localhost/MAAS/api/1.0 "`sudo maas-region-admin apikey --username $maas_user_name`"

  # Set interface
    uuid=$(maas $maas_user_name node-groups list | grep uuid | cut -d\" -f4)
    echo maas admin node-group-interface update -d $uuid eth1 \
	ip_range_high=$ip_range_high \
	ip_range_low=$ip_range_low \
	management=2                    \
	broadcast_ip=$broadcast_ip \
	router_ip=$router_ip \
	static_ip_range_low=$static_ip_range_low \
	static_ip_range_high=$static_ip_range_high
    maas admin node-group-interface update -d $uuid eth1 \
	ip_range_high=$ip_range_high \
	ip_range_low=$ip_range_low \
	management=2                    \
	broadcast_ip=$broadcast_ip \
	router_ip=$router_ip \
	static_ip_range_low=$static_ip_range_low \
	static_ip_range_high=$static_ip_range_high

  # Set dns forwarder
    echo maas admin maas set-config name=upstream_dns value=$dns_forwarder_ip
    maas admin maas set-config name=upstream_dns value=$dns_forwarder_ip
    
  # set ssh key
    echo maas $maas_user_name sshkeys new key="`cat ~/maas-key.pub`"
    maas $maas_user_name sshkeys new key="`cat ~/maas-key.pub`"
    
  # Import default images
    echo maas $maas_user_name boot-resources import
    maas $maas_user_name boot-resources import
    ret=null
    while [ ${ret} = null ]
      do
      sleep 5
      echo maas $maas_user_name boot-images read $uuid
      ret=`maas $maas_user_name boot-images read $uuid | jq .[0]`
    done
}

PatchNovaDriver(){
    echo sudo cp nova.py /usr/lib/python2.7/dist-packages/provisioningserver/drivers/power/nova.py
    sudo cp nova.py /usr/lib/python2.7/dist-packages/provisioningserver/drivers/power/nova.py
    echo sudo patch -p1 -d /usr/lib/python2.7/dist-packages/provisioningserver/ < ~/patchfile.diff
    sudo patch -p1 -d /usr/lib/python2.7/dist-packages/provisioningserver/ < ~/patchfile.diff
    echo sudo rm /usr/lib/python2.7/dist-packages/provisioningserver/drivers/power/__init__.pyc
    sudo rm /usr/lib/python2.7/dist-packages/provisioningserver/drivers/power/__init__.pyc
    echo sudo rm /usr/lib/python2.7/dist-packages/provisioningserver/power/__init__.pyc
    sudo rm /usr/lib/python2.7/dist-packages/provisioningserver/power/__init__.pyc
    echo sudo rm /usr/lib/python2.7/dist-packages/provisioningserver/power/schema.pyc
    sudo rm /usr/lib/python2.7/dist-packages/provisioningserver/power/schema.pyc
    echo sudo restart maas-clusterd
    sudo restart maas-clusterd
    echo sudo restart maas-regiond
    sudo restart maas-regiond
}

### main
source setvars
ConfigureMAAS
PatchNovaDriver
