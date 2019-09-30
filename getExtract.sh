#! /bin/sh
#
# getExtract.sh
# Copyright (C) Crown Copyright
#
# Distributed under terms of the MIT license.
#
# This script spins up a PostgreSQL pod and exports the event stream to a
# password protected CSV file.
set -euxo pipefail # defensive bash programming

DEPLOYMENT_NAME="hocs-postgres"
NAMESPACE_NAME=$(kubectl config view --minify --output 'jsonpath={..namespace}')

echo 'Checking this will work:'
kubectl auth can-i deploy deployment
kubectl auth can-i deploy pod
kubectl auth can-i exec pod

if [ "$NAMESPACE_NAME" == "alf-prod" ] ; then
  echo "--- This is production!"
  if [ "$1" != "--prod" ] ; then
    echo "Refusing to continue: pass --prod to do this for real"
    exit 1
  fi
fi

echo '--- Spinning up a pod for PostgreSQL'
# --current-replicas=0 ensures we are scaled down so we don't stomp on someone
#kubectl scale deployment --current-replicas=0 --replicas=1 $DEPLOYMENT_NAME
kubectl scale deployment --replicas=1 $DEPLOYMENT_NAME
if [ "$?" -eq "1" ] ; then
  echo 'Problem scaling deployment.'
  echo "Is $DEPLOYMENT_NAME already scaled up?"
  exit 1
fi
kubectl rollout status deployment/$DEPLOYMENT_NAME
PODNAME=$(kubectl get pods --field-selector=status.phase=Running -l name=$DEPLOYMENT_NAME --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
if [ -z "$PODNAME" ] ; then
  echo 'No postgres pod deployed'
  exit 1
fi
echo "$PODNAME"

FILENAME=OFFICIAL-SENSITIVE-$NAMESPACE_NAME-$(date +%Y-%m-%d).csv
ZIPNAME=OFFICIAL-$NAMESPACE_NAME-$(date +%Y-%m-%d).zip

echo "--- Exporting data to $FILENAME"
# variables in single quotes don't get interpolated
kubectl exec -it $PODNAME -- bash -c 'export PGPASSWORD=${HOCS_PASSWORD};psql -h${HOCS_DB_HOSTNAME} -U${HOCS_USERNAME} -d${HOCS_DB_NAME} -c "copy (select * from hocs_reporting_001.properties) to stdout with csv header;"' > $FILENAME

echo "--- Scaling pod back"
kubectl scale deployment --current-replicas=1 --replicas=0 $DEPLOYMENT_NAME
echo "--- Done"

PASSWORD=$(curl -s https://www.dinopass.com/password/simple)

zip -P "$PASSWORD" "$ZIPNAME" "$FILENAME"

rm -v "$FILENAME"


echo "Complete: $ZIPNAME encrypted with $PASSWORD"
