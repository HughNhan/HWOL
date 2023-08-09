#!/bin/sh

set -euo pipefail

source ./setting.env
source ./functions.sh

parse_args $@

echo "Removing performance profile ..."
if oc get performance-profile hwol-qos &>/dev/null; then
  oc delete -f ${MANIFEST_DIR}/performance_profile.yaml 
  echo "deleted performance-profile: done"
  sleep 10
  if [[ "${WAIT_MCP}" == "true" ]]; then
    wait_mcp
  fi
fi
echo "Removing performance profile: done"

##### Remove performance profile ######
if oc get mcp $MCP 2>/dev/null; then
    oc delete -f ${MANIFEST_DIR}/mcp-${MCP}.yaml
    echo "deleted mcp for ${MCP}: done"
fi

#unlabel

# remove label from  workers
echo "deleting label for $WORKER_LIST ..."
for worker in $WORKER_LIST; do
   oc label --overwrite node ${worker} node-role.kubernetes.io/${MCP}-
done

# EOF
