#!/bin/bash

# Adapted from https://github.com/docker-library/mongo/issues/339#issuecomment-557606066

# Set oplog size to the minimum
# and specify replSet name
set -- "$@" --oplogSize 990 --replSet myrepl

# call default entrypoint
/usr/local/bin/docker-entrypoint.sh "$@" &

# check if mongod is already running and the tmp init setup is done
PS_COMMAND="ps aux | grep '[m]ongod' | grep -v 'docker-entrypoint.sh'"
IS_MONGO_RUNNING=$( bash -c "${PS_COMMAND}" )
while [ -z "${IS_MONGO_RUNNING}" ]
do
  echo "[INFO] Waiting for the MongoDB setup to finish ..."
  sleep 1
  IS_MONGO_RUNNING=$( bash -c "${PS_COMMAND}" )
done
# wait for mongod to be ready for connections
sleep 3

COUNTER=0
until mongo --quiet --eval "db.serverStatus()" > /dev/null 2>&1 ; do
  sleep 1
  COUNTER=$((COUNTER+1))
  if [[ ${COUNTER} -eq 30 ]]; then
    echo "MongoDB did not initialize within 30 seconds, exiting"
    exit 2
  fi
  echo "Waiting for MongoDB to initialize... ${COUNTER}/30"
done
echo "Done waiting for MongoDB to initialize!"

# check if replica set is already initiated
RS_STATUS=$( mongo --quiet --eval "rs.status().ok" )
if [[ "$RS_STATUS" != "1" ]]
then
  echo "[INFO] Replication set config invalid. Reconfiguring now."
  RS_CONFIG_STATUS=$( mongo --quiet --eval "rs.status().codeName" )
  if [[ $RS_CONFIG_STATUS == 'InvalidReplicaSetConfig' ]]
  then
    mongo --quiet > /dev/null <<EOF
config = rs.config()
config.members[0].host = hostname()
rs.reconfig(config, {force: true})
EOF
  else
    echo "[INFO] MongoDB setup finished. Initiating replicata set."
    mongo --quiet --eval "rs.initiate()" > /dev/null
  fi
else
  echo "[INFO] Replication set already initiated."
fi

echo "[INFO] Compacting oplog."
mongo --quiet > /dev/null <<EOF
use local
db.runCommand({ "compact" : "oplog.rs", "force" : true } )
EOF
echo "[INFO] Done."

wait
