#!/bin/bash

set -euo pipefail
source ./setting.env
source ./functions.sh

parse_args $@

if [ -z "${WORKER_LIST}" ]; then
    export MCP=master   
fi

if oc get SriovNetwork net-attach-def -n openshift-sriov-network-operator 2>/dev/null; then
    echo "remove SriovNetwork ..."
    oc delete -f ${MANIFEST_DIR}/net-attach-def.yaml
    echo "remove SriovNetwork: done"
else
    echo "No SriovNetwork to remove"

fi


# step 2 - apply
set -uo pipefail

if oc get SriovNetworkNodePolicy sriov-node-policy -n openshift-sriov-network-operator 2>/dev/null; then
    echo "remove SriovNetworkNodePolicy ..."
    oc delete -f ${MANIFEST_DIR}/sriov-node-policy.yaml
    echo "remove SriovNetworkNodePolicy: done"
else
    echo "No SriovNetworkNodePolicy to remove"
fi

# step 3 - delete

function rm_SriovNetworkPoolConfig {
#if oc get SriovNetworkPoolConfig -n openshift-sriov-network-operator  2>/dev/null; then
# This command does not return exit 1 when SriovNetworkPoolConfig not exists
if [ -f ${MANIFEST_DIR}/sriov-pool-config.yaml ]; then
    echo "remove SriovNetworkPoolConfig ..."
    oc delete -f ${MANIFEST_DIR}/sriov-pool-config.yaml
    wait_mcp
    rm ${MANIFEST_DIR}/sriov-pool-config.yaml 
    echo "remove SriovNetworkPoolConfig: done"
else
    echo "No SriovNetworkPoolConfig to remove"
fi

}

rm_SriovNetworkPoolConfig

# step 2 - remove label from nodes
if [ ! -z "${WORKER_LIST}" ]; then
    echo "removing worker node labels"
    for NODE in $WORKER_LIST; do
        oc label --overwrite node ${NODE} node-role.kubernetes.io/${MCP}-
    done
else
    echo "removing master node labels"
    for NODE in $MASTER_LIST; do
        oc label --overwrite node ${NODE} node-role.kubernetes.io/${MCP}-
    done
fi

if oc get mcp mcp-offloading -n openshift-sriov-network-operator  2>/dev/null; then
    echo "remove mcp for mcp-offloading  ..."
    oc delete -f ${MANIFEST_DIR}/mcp-offloading.yaml
    echo "delete mcp for mcp-offloading: done"
fi


