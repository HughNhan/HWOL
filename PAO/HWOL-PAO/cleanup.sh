#!/bin/sh
#

set -euo pipefail

source ./setting.env
source ./functions.sh

parse_args $@


##### Remove performance-profile ######
echo "Removing performance profile ..."
if oc get PerformanceProfile ${MCP} &>/dev/null; then
  oc delete -f ${MANIFEST_DIR}/performance_profile.yaml 
  echo "deleted performance-profile: done"
  if [[ "${WAIT_MCP}" == "true" ]]; then
        wait_mcp ${MCP}
  fi
fi

# remove pao label. This label is for visual identification, and no functional at all.
for worker in $WORKER_LIST; do
   oc label --overwrite node ${worker} node-role.kubernetes.io/pao-
done

# we are using MCP mcp-offloading. Leave it in-place since HWOL is still using.

# EOF
