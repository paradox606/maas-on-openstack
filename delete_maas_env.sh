#!/bin/bash

#set -e
set -u

DeleteInstances(){
  echo nova delete $maas_instance
  nova delete $maas_instance
  echo ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R $maas_instance
  ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R $maas_instance
  echo nova keypair-delete maas-keypair
  nova keypair-delete maas-keypair
  echo rm maas-key
  rm maas-key
  echo rm maas-key.pub
  rm maas-key.pub
}

DeleteNetwork() {
  echo neutron router-interface-delete $maas_rt_name $maas_subnw_name
  neutron router-interface-delete $maas_rt_name $maas_subnw_name
  echo neutron router-gateway-clear $maas_rt_name
  neutron router-gateway-clear $maas_rt_name
  echo neutron router-delete $maas_rt_name
  neutron router-delete $maas_rt_name
  echo sleep 2
  sleep 2
  echo neutron net-delete $maas_nw_name
  neutron net-delete $maas_nw_name
}

DeleteImage(){
  echo glance image-delete $glance_img_name
  glance image-delete $glance_img_name
}

### main ###
source setvars
DeleteInstances
DeleteNetwork
DeleteImage
