#!/bin/bash

CreateNetwork() {
  echo neutron net-create $maas_nw_name
  neutron net-create $maas_nw_name
  echo neutron subnet-create $maas_nw_name \
      --name $maas_subnw_name \
      --allocation-pool start=${maas_nw_allocation_start},end=${maas_nw_allocation_end} \
      --disable-dhcp \
      $maas_nw_cidr
  neutron subnet-create $maas_nw_name \
      --name $maas_subnw_name \
      --allocation-pool start=${maas_nw_allocation_start},end=${maas_nw_allocation_end} \
      --disable-dhcp \
      $maas_nw_cidr
  echo neutron router-create $maas_rt_name
  neutron router-create $maas_rt_name
  echo neutron router-interface-add $maas_rt_name $maas_subnw_name
  neutron router-interface-add $maas_rt_name $maas_subnw_name
  echo neutron router-gateway-set $maas_rt_name $ext_net_id
  neutron router-gateway-set $maas_rt_name $ext_net_id
}

CreatePXEbootImage() {
  echo dd if=/dev/zero of=$pxeboot_img_name bs=1M count=4
  dd if=/dev/zero of=$pxeboot_img_name bs=1M count=4
  echo mkdosfs $pxeboot_img_name
  mkdosfs $pxeboot_img_name
  echo sudo losetup /dev/loop0 $pxeboot_img_name
  sudo losetup /dev/loop0 $pxeboot_img_name
  echo sudo mount /dev/loop0 /mnt
  sudo mount /dev/loop0 /mnt
  echo sudo syslinux --install /dev/loop0
  sudo syslinux --install /dev/loop0
  #wget http://boot.ipxe.org/ipxe.iso
  echo wget http://10.230.19.126:80/swift/v1/public-dir/ipxe.iso
  wget http://10.230.19.126:80/swift/v1/public-dir/ipxe.iso
  echo sudo mount -o loop ipxe.iso /media
  sudo mount -o loop ipxe.iso /media
  echo sudo cp /media/ipxe.krn /mnt
  sudo cp /media/ipxe.krn /mnt
  cat << EOF | sudo tee "/mnt/syslinux.cfg"
DEFAULT ipxe
LABEL ipxe
 KERNEL ipxe.krn
EOF

  echo sudo umount /media/
  sudo umount /media/
  echo sudo umount /mnt
  sudo umount /mnt
  echo sudo losetup -d /dev/loop0
  sudo losetup -d /dev/loop0
}

UploadImage(){
  # upload pxe-boot image to glance
  echo "glance image-create --name $1 --is-public false --disk-format raw --container-format bare < $2"
  glance image-create --name $1 --is-public false --disk-format raw --container-format bare < $2
}

CreateInstance(){
  maas_net_id=`neutron net-list | grep maas-network| cut -d\| -f2| tr -d ' '`
  echo "maas_net_id="$maas_net_id
  echo ssh-keygen -b 2048 -t rsa -f maas-key -q -N ""
  ssh-keygen -b 2048 -t rsa -f maas-key -q -N ""
  echo nova keypair-add --pub-key maas-key.pub maas-keypair
  nova keypair-add --pub-key maas-key.pub maas-keypair
  echo nova boot --flavor $flavor --image $boot_img --key-name maas-keypair --nic net-id=$admin_net_id --nic net-id=$maas_net_id --poll --user-data cloudconfig.yaml $1
  nova boot --flavor $flavor --image $boot_img --key-name maas-keypair --nic net-id=$admin_net_id --nic net-id=$maas_net_id --poll --user-data cloudconfig.yaml $1
  echo "Waiting for the instance to finish"
  ret=0
  while [ $ret -eq 0 ]; do
    ret=`nova console-log maas-server|egrep -c "Cloud-init v.* finished at" | cat`
    if [ $ret -ne 0 ]; then
	echo -en "."
    fi
    sleep 5
  done
}

CopyFiles() {
  echo "Copy files to the instance"
  ip=`nova show $maas_instance | grep "$admin_nw_name" | cut -d\| -f3 |tr -d ' '`
  echo "ip is "$ip
  echo "scp -i maas-key ~/novarc maas-key* nova_driver/* setvars $ip:"
  scp -i maas-key ~/novarc maas-key* nova_driver/* setvars $ip:
}

### main ###
source setvars
CreateNetwork
CreatePXEbootImage
UploadImage $glance_img_name $pxeboot_img_name
CreateInstance $maas_instance
CopyFiles
# Configure MAAS
echo "running configure_maas.sh on "$ip"..."
ssh -i maas-key $ip 'bash -s' < configure_maas.sh
echo "Finished environment preparation."
