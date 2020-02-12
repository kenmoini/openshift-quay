#!/bin/bash

OC_ARG_OPTS=""

oc $OC_ARG_OPTS create -f quay-enterprise-namespace.yaml
oc $OC_ARG_OPTS project quay-enterprise

oc $OC_ARG_OPTS create -f quay-enterprise-config-secret.yaml
oc $OC_ARG_OPTS create secret generic quay-enterprise-secret
oc $OC_ARG_OPTS create -f quay-enterprise-redhat-quay-3-pull-secret.yaml

oc $OC_ARG_OPTS create -f quay-storageclass.yaml
oc $OC_ARG_OPTS create -f db-pvc.yaml
oc $OC_ARG_OPTS create -f postgres-deployment.yaml
oc $OC_ARG_OPTS create -f postgres-service.yaml

echo "Sleeping 30s while PostgreSQL deploys..."
sleep 30

POSTGRES_POD_NAME=$(oc get pods -o name | sed -e 's;pod/;;g')

oc $OC_ARG_OPTS exec -it $POSTGRES_POD_NAME -n quay-enterprise -- /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | /opt/rh/rh-postgresql10/root/usr/bin/psql -d quay'

oc $OC_ARG_OPTS create serviceaccount postgres -n quay-enterprise
oc $OC_ARG_OPTS adm policy add-scc-to-user anyuid -z system:serviceaccount:quay-enterprise:postgres

oc $OC_ARG_OPTS create -f quay-servicetoken-role-k8s1-6.yaml -n quay-enterprise
oc $OC_ARG_OPTS create -f quay-servicetoken-role-binding-k8s1-6.yaml -n quay-enterprise

oc $OC_ARG_OPTS adm policy add-scc-to-user anyuid system:serviceaccount:quay-enterprise:default

oc $OC_ARG_OPTS create -f quay-enterprise-redis.yaml

echo "Sleeping 30s while Redis deploys..."
sleep 30

oc $OC_ARG_OPTS create -f quay-enterprise-config.yaml
oc $OC_ARG_OPTS create -f quay-enterprise-config-service-clusterip.yaml
oc $OC_ARG_OPTS create -f quay-enterprise-config-route.yaml

oc $OC_ARG_OPTS create -f quay-enterprise-service-clusterip.yaml
oc $OC_ARG_OPTS create -f quay-enterprise-app-route.yaml
oc $OC_ARG_OPTS create -f quay-enterprise-app-rc.yaml