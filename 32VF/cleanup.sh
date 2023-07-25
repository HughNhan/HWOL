#!/bin/bash

#set -euo pipefail
source ./setting.env
source ./functions.sh

parse_args $@

if [ -z "${WORKER_LIST}" ]; then
    export MCP=master   
fi

function rm_networkattachmentdefinition {
 if oc get networkattachmentdefinition.k8s.cni.cncf.io/$NET_ATTACH_NS &>/dev/null; then
    echo "remove NetworkAttachmentDefinition ..."
    oc delete -f ${MANIFEST_DIR}/net-attach-def.yaml
    echo "remove NetworkAttachmentDefinition: done"
 else
    echo "No NetworkAttachmentDefinition to remove"

 fi
 prompt_continue
}
# VF32 does not remove


# step 2 - apply
#set -uo pipefail

if oc get SriovNetworkNodePolicy/sriov-node-policy-32vf -n openshift-sriov-network-operator  &>/dev/null; then
    echo "remove SriovNetworkNodePolicy-32vf ..."
    oc delete -f ${MANIFEST_DIR}/sriov-node-policy-32vf.yaml
    echo "remove SriovNetworkNodePolicy-32vf: done"
    wait_mcp
    # !!!! reboot !!!!

else
    echo "No SriovNetworkNodePolicy-32vf to remove"
fi

echo "Will remove SriovNetworkPoolConfig-32vf, and reboot if continue"
prompt_continue

# step 3 - delete
function rm_SriovNetworkPoolConfig {

if oc get SriovNetworkPoolConfig/sriovnetworkpoolconfig-offload-32vf -n openshift-sriov-network-operator &>/dev/null; then
    echo "remove SriovNetworkPoolConfig-32vf  ..."
    oc delete -f ${MANIFEST_DIR}/sriov-pool-config-32vf.yaml
    wait_mcp
    # !!!! reboot !!!!
    rm ${MANIFEST_DIR}/sriov-pool-config.yaml 
    echo "remove SriovNetworkPoolConfig-32vf : done"
else
    echo "No SriovNetworkPoolConfig to remove"
fi

}

rm_SriovNetworkPoolConfig
#!!!! reboot !!!!

echo "Continue if you want to also remove the mcp-offload-32vf mcp  ..."
prompt_continue

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

if oc get mcp mcp-offloading-32vf  -n openshift-sriov-network-operator &>/dev/null; then
    echo "remove mcp for mcp-offloading-32vf   ..."
    oc delete -f ${MANIFEST_DIR}/mcp-offloading-32vf.yaml
    rm  -f ${MANIFEST_DIR}/mcp-offloading-32vf .yaml
    echo "delete mcp for mcp-offloading-32vf: done"
else
    echo "No mcp mcp-offloading-32vf  to remove."
fi


function rm_srioc_operator {
    echo "Continue if you want to also remove the SRIOV Operator ..."
    prompt_continue
    if oc get Subscription sriov-network-operator-subsription -n openshift-sriov-network-operator &>/dev/null; then
        echo "Remove  SRIOV Operator ..."
        oc delete -f ${MANIFEST_DIR}/sub-sriov.yaml
        rm ${MANIFEST_DIR}/sub-sriov.yaml
    fi
}
# 322VF does nottouch SRIOV operator


