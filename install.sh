#!/bin/bash

set -euo pipefail
source ./setting.env
source ./functions.sh

parse_args $@


function prompt_continue {
    printf 'Continue next step (y/n)? '
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then 
        echo Yes
    else
        echo No
        exit 1
    fi

}

mkdir -p ${MANIFEST_DIR}/

# if no worker i.e SNO, compact cluster, use master mcp
if [ ! -z "$WORKERS"  ]; then
    export MCP=master   
    echo Use mcp $MCP 
fi

export OCP_CHANNEL=$(get_ocp_channel)

function install_sriov_operator {
    # Debug: oc get csv -n openshift-sriov-network-operator -o custom-columns=Name:.metadata.name,Phase:.status.phase
    #        oc get network.operator -o yaml | grep routing
    #        ( look for =>  routingViaHost: false )

# install SRIOV operator
# skip if sriov operator subscription already exists 
if ! oc get Subscription sriov-network-operator-subsription -n openshift-sriov-network-operator 2>/dev/null; then 
    #// Installing SR-IOV Network Operator done
    echo "Installing SRIOV Operator ..."
    export OCP_CHANNEL=$(get_ocp_channel)
    envsubst < templates/sub-sriov.yaml.template > ${MANIFEST_DIR}/sub-sriov.yaml
    oc create -f ${MANIFEST_DIR}/sub-sriov.yaml
    echo "install SRIOV Operator: done"
else
    echo "Skip installing SRIOV Operator: done"

fi

wait_pod_in_namespace openshift-sriov-network-operator
# give it a little delay. W/o delay we could encounter error on the next command.
sleep 10
}

install_sriov_operator
prompt_continue

function configure_mcp {
### Configure MCP

# step 1 - Create mcp-offloading mcp
    # create template
 if ! oc get mcp mcp-offloading  2>/dev/null; then
    echo "create mcp for mcp-offloading  ..."
    mkdir -p ${MANIFEST_DIR}
    envsubst < templates/mcp-offloading.yaml.template > ${MANIFEST_DIR}/mcp-offloading.yaml
    oc create -f ${MANIFEST_DIR}/mcp-offloading.yaml
    echo "create mcp for mcp-offloading: done"
 fi
}

# Create a new MCP, but if cluster is SNO or compact we only have masters, and hence use master MCP.
if [ ! -z "${WORKER_LIST}" ]; then
    configure_mcp
else
    echo "Cluster has no workers. Will use master mcp"
fi

function add_label {
 # step 2 - label nodes
 if [ ! -z ${WORKER_LIST} ]; then
    for NODE in $WORKER_LIST; do
        echo label $NODE with $MCP
        echo oc label --overwrite node ${NODE} node-role.kubernetes.io/${MCP}=""
    done
 else
    echo "Cluster has no workers. No need to label master nodes"
 fi
}

add_label

prompt_continue

# step 3 - (optional ) oc get node 

function add_SriovNetworkPoolConfig {
 # step 4 - add mcp to SriovNetworkPoolConfig custom resource.
 #if ! oc get SriovNetworkPoolConfig -n openshift-sriov-network-operator  2>/dev/null; then
 # This command does not return exit 1 when SriovNetworkPoolConfig not exists
 if [ ! -f ${MANIFEST_DIR}/sriov-pool-config.yaml ]; then
    echo "create SriovNetworkPoolConfig  ..."
    # create sriov-pool-config.yaml from template
    envsubst < templates/sriov-pool-config.yaml.template > ${MANIFEST_DIR}/sriov-pool-config.yaml
    # apply
    oc create -f ${MANIFEST_DIR}/sriov-pool-config.yaml
    echo "create SriovNetworkPoolConfig: done"
    wait_mcp
 else
    echo ${MANIFEST_DIR}/sriov-pool-config.yam exists. No need to create SriovNetworkPoolConfig
 fi
}
add_SriovNetworkPoolConfig
prompt_continue

function config_SriovNetworkNodePolicy {
##### Configuring the SR-IOV network node policy
echo "Acquiring SRIOV interface PCI info from worker node ${BAREMETAL_WORKER} ..."
export HWOL_INTERFACE_PCI=$(exec_over_ssh ${BAREMETAL_WORKER} "ethtool -i ${HWOL_INTERFACE}" | awk '/bus-info:/{print $NF;}')
echo "Acquiring SRIOV interface PCI info from worker node ${BAREMETAL_WORKER}: done"

# step 1 - create sriov-node-policy.yaml from template
    # 
echo "generating ${MANIFEST_DIR}/sriov-node-policy.yaml ..."
envsubst < templates/sriov-node-policy.yaml.template > ${MANIFEST_DIR}/sriov-node-policy.yaml
echo "generating ${MANIFEST_DIR}/sriov-node-policy.yaml: done"

# step 2 - apply

if ! oc get SriovNetworkNodePolicy sriov-node-policy -n openshift-sriov-network-operator 2>/dev/null; then
    echo "create SriovNetworkNodePolicy ..."
    echo oc create -f ${MANIFEST_DIR}/sriov-node-policy.yaml
    echo "create SriovNetworkNodePolicy: done"
fi

}

prompt_continue
hn_exit


function create_networl_attachment {

#### Creating a network attachment definitio

# step 1 - 
    # create net-attach-def.yaml from template
envsubst < templates//net-attach-def.yaml.template > ${MANIFEST_DIR}/net-attach-def.yaml
echo "generating ${MANIFEST_DIR}/net-attach-def.yaml: done"
    # apply
if ! oc get SriovNetwork net-attach-def -n openshift-sriov-network-operator 2>/dev/null; then
    echo "create SriovNetwork ..."
    echo oc create -f ${MANIFEST_DIR}/net-attach-def.yaml
    echo "create SriovNetwork: done"
fi

}


#
#  to annotate pod
# ....
# metadata:
#   annotations:
#    v1.multus-cni.io/default-network: net-attach-def/net-attach-def 
