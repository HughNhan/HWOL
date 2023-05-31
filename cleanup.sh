#!/bin/bash

#set -euo pipefail
source ./setting.env
source ./functions.sh

parse_args $@

if [ -z "${WORKER_LIST}" ]; then
    export MCP=master   
fi

MSG=$(oc get networkattachmentdefinition.k8s.cni.cncf.io 2>&1 | grep "No")
if [ -z "${MSG}" ] ; then
    echo "remove SriovNetwork ..."
    oc delete -f ${MANIFEST_DIR}/net-attach-def.yaml
    echo "remove SriovNetwork: done"
else
    echo "No SriovNetwork to remove"

fi
prompt_continue


# step 2 - apply
#set -uo pipefail

oc get SriovNetworkNodePolicy sriov-node-policy -n openshift-sriov-network-operator  2>/dev/null
if [ $? -eq 0 ]; then
    echo "remove SriovNetworkNodePolicy ..."
    oc delete -f ${MANIFEST_DIR}/sriov-node-policy.yaml
    echo "remove SriovNetworkNodePolicy: done"
else
    echo "No SriovNetworkNodePolicy to remove"
fi

prompt_continue

# step 3 - delete
function rm_SriovNetworkPoolConfig {

MSG=$(oc get SriovNetworkPoolConfig -n openshift-sriov-network-operator 2>&1 | grep "No")
if [ -z "${MSG}" ] ; then
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

exit


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


