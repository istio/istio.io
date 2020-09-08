#!/bin/bash

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

# shellcheck source=prow/lib.sh
source "${ROOT}/prow/lib.sh"

# Cluster names for multicluster configurations.
export CLUSTER1_NAME=${CLUSTER1_NAME:-"cluster1"}
export CLUSTER2_NAME=${CLUSTER2_NAME:-"cluster2"}
export CLUSTER3_NAME=${CLUSTER3_NAME:-"cluster3"}

export CLUSTER_NAMES=("${CLUSTER1_NAME}" "${CLUSTER2_NAME}" "${CLUSTER3_NAME}")
export CLUSTER_POD_SUBNETS=(10.10.0.0/16 10.20.0.0/16 10.30.0.0/16)
export CLUSTER_SVC_SUBNETS=(10.255.10.0/24 10.255.20.0/24 10.255.30.0/24)

export ARTIFACTS="${ARTIFACTS:-$(mktemp -d)}"

# Cleans up the clusters created by setup_kind_clusters
function cleanup_kind_clusters() {
  for c in "${CLUSTER_NAMES[@]}"; do
     cleanup_kind_cluster "${c}"
  done
}

function setup_kind_clusters() {
  TOPOLOGY="${1}"
  IMAGE="${2:-kindest/node:v1.18.2}"

  KUBECONFIG_DIR="$(mktemp -d)"

  # The kind tool will error when trying to create clusters in parallel unless we create the network first
  # TODO remove this when kind support creating multiple clusters in parallel - this will break ipv6
  docker network inspect kind > /dev/null 2>&1 || docker network create -d=bridge -o com.docker.network.bridge.enable_ip_masquerade=true kind

  # Trap replaces any previous trap's, so we need to explicitly cleanup both clusters here
  trap cleanup_kind_clusters EXIT

  function deploy_kind() {
    IDX="${1}"
    CLUSTER_NAME="${CLUSTER_NAMES[$IDX]}"
    CLUSTER_POD_SUBNET="${CLUSTER_POD_SUBNETS[$IDX]}"
    CLUSTER_SVC_SUBNET="${CLUSTER_SVC_SUBNETS[$IDX]}"
    CLUSTER_YAML="${ARTIFACTS}/config-${CLUSTER_NAME}.yaml"
    if [ ! -f "${CLUSTER_YAML}" ]; then
      cp ./prow/config/trustworthy-jwt.yaml "${CLUSTER_YAML}"
      cat <<EOF >> "${CLUSTER_YAML}"
networking:
  podSubnet: ${CLUSTER_POD_SUBNET}
  serviceSubnet: ${CLUSTER_SVC_SUBNET}
EOF
    fi

    CLUSTER_KUBECONFIG="${KUBECONFIG_DIR}/${CLUSTER_NAME}"

    # Create the clusters.
    # TODO: add IPv6
    KUBECONFIG="${CLUSTER_KUBECONFIG}" setup_kind_cluster "${IMAGE}" "${CLUSTER_NAME}" "${CLUSTER_YAML}"

    # Kind currently supports getting a kubeconfig for internal or external usage. To simplify our tests,
    # its much simpler if we have a single kubeconfig that can be used internally and externally.
    # To do this, we can replace the server with the IP address of the docker container
    # https://github.com/kubernetes-sigs/kind/issues/1558 tracks this upstream
    CONTAINER_IP=$(docker inspect "${CLUSTER_NAME}-control-plane" --format "{{ .NetworkSettings.Networks.kind.IPAddress }}")
    kind get kubeconfig --name "${CLUSTER_NAME}" --internal | \
      sed "s/${CLUSTER_NAME}-control-plane/${CONTAINER_IP}/g" > "${CLUSTER_KUBECONFIG}"
  }

  # Deploy Kind cluster and note down the PID for each of the jobs
  # If any of them fails, then cleanup clusters already provisioned
  declare -a DEPLOY_KIND_JOBS
  for i in "${!CLUSTER_NAMES[@]}"; do
    deploy_kind "${i}" & DEPLOY_KIND_JOBS+=("${!}")
  done
  for pid in "${DEPLOY_KIND_JOBS[@]}"; do
    wait "${pid}" || exit 1
  done

  # Install MetalLB for LoadBalancer support. Must be done synchronously since METALLB_IPS is shared.
  for CLUSTER_NAME in "${CLUSTER_NAMES[@]}"; do
    install_metallb "${KUBECONFIG_DIR}/${CLUSTER_NAME}"
  done

  # Export variables for the kube configs for the clusters.
  export CLUSTER1_KUBECONFIG="${KUBECONFIG_DIR}/${CLUSTER1_NAME}"
  export CLUSTER2_KUBECONFIG="${KUBECONFIG_DIR}/${CLUSTER2_NAME}"
  export CLUSTER3_KUBECONFIG="${KUBECONFIG_DIR}/${CLUSTER3_NAME}"

  if [[ "${TOPOLOGY}" != "SINGLE_CLUSTER" ]]; then
    # Clusters 1 and 2 are on the same network
    connect_kind_clusters "${CLUSTER1_NAME}" "${CLUSTER1_KUBECONFIG}" "${CLUSTER2_NAME}" "${CLUSTER2_KUBECONFIG}" 1
    # Cluster 3 is on a different network but we still need to set up routing for MetalLB addresses
    connect_kind_clusters "${CLUSTER1_NAME}" "${CLUSTER1_KUBECONFIG}" "${CLUSTER3_NAME}" "${CLUSTER3_KUBECONFIG}" 0
    connect_kind_clusters "${CLUSTER2_NAME}" "${CLUSTER2_KUBECONFIG}" "${CLUSTER3_NAME}" "${CLUSTER3_KUBECONFIG}" 0
  fi
}

function connect_kind_clusters() {
  C1="${1}"
  C1_KUBECONFIG="${2}"
  C2="${3}"
  C2_KUBECONFIG="${4}"
  POD_TO_POD_AND_SERVICE_CONNECTIVITY="${5}"

  C1_NODE="${C1}-control-plane"
  C2_NODE="${C2}-control-plane"
  C1_DOCKER_IP=$(docker inspect -f "{{ .NetworkSettings.Networks.kind.IPAddress }}" "${C1_NODE}")
  C2_DOCKER_IP=$(docker inspect -f "{{ .NetworkSettings.Networks.kind.IPAddress }}" "${C2_NODE}")
  if [ "${POD_TO_POD_AND_SERVICE_CONNECTIVITY}" -eq 1 ]; then
    # Set up routing rules for inter-cluster direct pod to pod & service communication
    C1_POD_CIDR=$(KUBECONFIG="${C1_KUBECONFIG}" kubectl get node -ojsonpath='{.items[0].spec.podCIDR}')
    C2_POD_CIDR=$(KUBECONFIG="${C2_KUBECONFIG}" kubectl get node -ojsonpath='{.items[0].spec.podCIDR}')
    C1_SVC_CIDR=$(KUBECONFIG="${C1_KUBECONFIG}" kubectl cluster-info dump | sed -n 's/^.*--service-cluster-ip-range=\([^"]*\).*$/\1/p' | head -n 1)
    C2_SVC_CIDR=$(KUBECONFIG="${C2_KUBECONFIG}" kubectl cluster-info dump | sed -n 's/^.*--service-cluster-ip-range=\([^"]*\).*$/\1/p' | head -n 1)
    docker exec "${C1_NODE}" ip route add "${C2_POD_CIDR}" via "${C2_DOCKER_IP}"
    docker exec "${C1_NODE}" ip route add "${C2_SVC_CIDR}" via "${C2_DOCKER_IP}"
    docker exec "${C2_NODE}" ip route add "${C1_POD_CIDR}" via "${C1_DOCKER_IP}"
    docker exec "${C2_NODE}" ip route add "${C1_SVC_CIDR}" via "${C1_DOCKER_IP}"
  fi

  # Set up routing rules for inter-cluster pod to MetalLB LoadBalancer communication
  connect_metallb "$C1_NODE" "$C2_KUBECONFIG" "$C2_DOCKER_IP"
  connect_metallb "$C2_NODE" "$C1_KUBECONFIG" "$C1_DOCKER_IP"
}

function install_metallb() {
  KUBECONFIG="${1}"
  kubectl apply --kubeconfig="$KUBECONFIG" -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
  kubectl apply --kubeconfig="$KUBECONFIG" -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
  kubectl create --kubeconfig="$KUBECONFIG" secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

  if [ -z "${METALLB_IPS[*]}" ]; then
    # Take IPs from the end of the docker kind network subnet to use for MetalLB IPs
    DOCKER_KIND_SUBNET="$(docker inspect kind | jq .[0].IPAM.Config[0].Subnet -r)"
    METALLB_IPS=()
    while read -r ip; do
      METALLB_IPS+=("$ip")
    done < <(cidr_to_ips "$DOCKER_KIND_SUBNET" | tail -n 100)
  fi

  # Give this cluster of those IPs
  RANGE="${METALLB_IPS[0]}-${METALLB_IPS[9]}"
  METALLB_IPS=("${METALLB_IPS[@]:10}")

  echo 'apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - '"$RANGE" | kubectl apply --kubeconfig="$KUBECONFIG" -f -
}

function connect_metallb() {
  REMOTE_NODE=$1
  METALLB_KUBECONFIG=$2
  METALLB_DOCKER_IP=$3

  IP_REGEX='(([0-9]{1,3}\.?){4})'
  LB_CONFIG="$(kubectl --kubeconfig="${METALLB_KUBECONFIG}" -n metallb-system get cm config -o jsonpath="{.data.config}")"
  if [[ "$LB_CONFIG" =~ $IP_REGEX-$IP_REGEX ]]; then
    while read -r lb_cidr; do
      docker exec "${REMOTE_NODE}" ip route add "${lb_cidr}" via "${METALLB_DOCKER_IP}"
    done < <(ips_to_cidrs "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}")
  fi
}

function cidr_to_ips() {
    CIDR="$1"
    python3 - <<EOF
from ipaddress import IPv4Network; [print(str(ip)) for ip in IPv4Network('$CIDR').hosts()]
EOF
}

function ips_to_cidrs() {
  IP_RANGE_START="$1"
  IP_RANGE_END="$2"
  python3 - <<EOF
from ipaddress import summarize_address_range, IPv4Address
[ print(n.compressed) for n in summarize_address_range(IPv4Address(u'$IP_RANGE_START'), IPv4Address(u'$IP_RANGE_END')) ]
EOF
}
