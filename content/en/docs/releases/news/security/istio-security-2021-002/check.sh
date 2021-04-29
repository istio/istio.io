#!/usr/bin/env bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eEuo pipefail

RED='\033[0;31m'
NC='\033[0m'

INGRESS_LABEL="istio=ingressgateway"
INGRESS_NAMESPACE="istio-system"

INGRESS_LABEL_KEY=$(echo $INGRESS_LABEL | cut -d '=' -f 1)
INGRESS_LABEL_VAL=$(echo $INGRESS_LABEL | cut -d '=' -f 2)

ingress_pod=$(kubectl -n $INGRESS_NAMESPACE get pod \
  -l $INGRESS_LABEL \
  -o jsonpath='{.items[0].metadata.name}' || true)

if [ -z "$ingress_pod" ]; then
  echo "No ingress pod found in \"${INGRESS_NAMESPACE}\" with label selectors \"${INGRESS_LABEL}\""
  exit 1
fi

echo "Inspecting Istio ingress gateway pod \"${ingress_pod}\" in \"${INGRESS_NAMESPACE}\" namespace"

ingress_ports=$(istioctl proxy-config listeners \
  "${ingress_pod}.${INGRESS_NAMESPACE}" \
  | awk 'NR > 1 {print $2}')

function check_port {
  local policy_name=$1
  local port=$2

  local found=false
  local ip
  for ip in $ingress_ports; do
    if [ "$ip" == "$port" ]; then
      found=true
      break
    fi
  done
  if ! $found; then
    echo -e "${RED} Authorization Policy \"${policy_name}\" has port \"${port}\" that needs to be migrated. ${NC}"
  fi
}

authz_policies=$(kubectl -n $INGRESS_NAMESPACE get authorizationpolicies | awk 'NR > 1 {print $1}')
echo -e "Checking Authorization Policies attached to \"$ingress_pod\"\n"

for p in $authz_policies; do
  policy=$(kubectl -n "${INGRESS_NAMESPACE}" get authorizationpolicy "${p}" -o json)
  label_selector=$(echo "${policy}" |\
    jq -r --arg KEY "$INGRESS_LABEL_KEY" '.spec.selector.matchLabels[$KEY]')
  if [ "${label_selector}" != "${INGRESS_LABEL_VAL}" ]; then
    continue
  fi
  policy_ports=$(echo "${policy}" | jq -r '.spec.rules[]|select(.to)|.to[]|.operation|select(.ports)|.ports[]')
  policy_notports=$(echo "${policy}" | jq -r '.spec.rules[]|select(.to)|.to[]|.operation|select(.notPorts)|.notPorts[]')
  for pp in $policy_ports; do
    check_port "${p}" "${pp}"
  done
  for pp in $policy_notports; do
    check_port "${p}" "${pp}"
  done
done
