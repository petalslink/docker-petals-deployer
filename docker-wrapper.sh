#!/bin/sh

# Variables setting
cli_host=`hostname -i`

petals_host="localhost"
petals_port="7700"
petals_user="petals"
petals_pass="petals"

[ ! -z "$CLI_PETALS_HOST" ] && petals_host="$CLI_PETALS_HOST"
[ ! -z "$CLI_PETALS_PORT" ] && petals_port="$CLI_PETALS_PORT"
[ ! -z "$CLI_PETALS_USER" ] && petals_user="$CLI_PETALS_USER"
[ ! -z "$CLI_PETALS_PASS" ] && petals_pass="$CLI_PETALS_PASS"

petalscli="/opt/petals-deployer/bin/petals-cli.sh -h $petals_host -n $petals_port -u $petals_user -p $petals_pass -y -c "

# Informational dump
echo "############################ PETALS DEPLOYER ############################"
echo "###     Starting deploy script with following parameters:" 
echo " - Petals host: $petals_host" && echo " - Petals port: $petals_port" && echo " - Petals user: $petals_user" && echo " - Petals pass: $petals_pass"
echo " - Deploy file: $DEPLOY_FILE"
echo " - URLS to deploy: $DEPLOY_URLS"
echo " - CLI host: $cli_host"
echo " - CLI version :"
/opt/petals-deployer/bin/petals-cli.sh --version

# CLI environment file setting
echo
echo "###     Setting configuration..." 
echo "#docker-petals-deployer artifacts server configuration" >> /opt/petals-deployer/conf/petals-cli.default 
echo "embedded.http.port=80" >> /opt/petals-deployer/conf/petals-cli.default 
echo "embedded.http.host=$cli_host" >> /opt/petals-deployer/conf/petals-cli.default
echo >> /opt/petals-deployer/conf/petals-cli.default 

# Pre deploy Petals ESB informations & status
echo
echo "###     Target Petals ESB container status:"
echo
$petalscli version
$petalscli topology-list
echo "Artifacts :"
$petalscli list
echo
$petalscli endpoint-list

echo
echo "###     Starting deploy ..."

# Deploy artifacts from urls
if [ ! -z ${DEPLOY_URLS+x} ] && [ "$DEPLOY_URLS" != "" ] 
then
  echo
  echo "# URLs found, deploying:"
  IFSBACKUP="$IFS"
  IFS=';'
  set $DEPLOY_URLS
  IFS="$IFSBACKUP"
  for item in $*
  do
    echo "Deploying $item..."
    $petalscli deploy -- -u $item
  done
  echo "# URLs deploy over."
fi

# Deploy artifacts from file
if [ ! -z ${DEPLOY_FILE+x} ] && [ "$DEPLOY_FILE" != "" ] 
then
  echo
  echo "# File found, deploying:"
  while IFS='' read -r line || [[ -n "$line" ]]; do
    if [ ! -z ${line+x} ] && [ "$line" != "" ] 
    then
      echo "Deploying $line..."
      $petalscli deploy -- -u $line
    fi
  done < "$DEPLOY_FILE"
  echo "# Files deploy over."
fi

# Post deploy Petals ESB status
echo
echo "###     Status after deploy:"
echo
echo "Artifacts :"
$petalscli list
echo
$petalscli endpoint-list
echo
echo "###     Deploy script over."
echo "#########################################################################"
