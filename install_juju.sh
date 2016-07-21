#!/bin/bash

set -u
set -e

SetVars(){
  source setvars
  maas_url="http:\/\/${maas_server_ip}\/MAAS\/"
  maas_key=`sudo maas-region-admin apikey --username $maas_user_name`
}

InstallJuju(){
  echo sudo apt-get install -y juju-core juju-deployer
  sudo apt-get install -y juju-core juju-deployer
}

ConfigureJuju(){
  echo juju init -f
  juju init -f
  sed -i -e "s/maas-server:.*/maas-server: \'$maas_url\'/g" "$HOME/.juju/environments.yaml"
  sed -i -e "s/maas-oauth:.*/maas-oauth: \'$maas_key\'/g" "$HOME/.juju/environments.yaml"
  echo juju switch maas
  juju switch maas
}

DeployBootstrap(){
  echo juju bootstrap --debug --constraints tags=bootstrap
  juju bootstrap --debug --constraints tags=bootstrap
}

SetVars
InstallJuju
ConfigureJuju
#DeployBootstrap
