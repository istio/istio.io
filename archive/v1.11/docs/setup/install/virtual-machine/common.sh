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

set -e
set -u
set -o pipefail
set -x

function setup_cluster_for_vms() {
  snip_setup_wd

  snip_setup_iop

  echo y | snip_install_istio

  snip_install_eastwest

  snip_expose_istio
}

function setup_vm() {
  snip_install_namespace || true
  snip_install_sa || true

  snip_create_wg
  snip_apply_wg
  snip_configure_wg

  # Rather than spinning up a real VM, we will use a docker container
  # We do the implicit "Securely transfer the files from "${WORK_DIR}" to the virtual machine." step by
  # a volume mount
  # shellcheck disable=SC2086
  docker run --rm -it --init -d --network=kind --name vm \
    -v "${WORK_DIR}:/root" -v "${PWD}/content/en/docs/setup/install/virtual-machine:/test" \
    ${EXTRA_VM_ARGS:-} \
    -w "/root" \
    gcr.io/istio-release/base:1.9-dev.2

  POD_CIDR=$(kubectl get node -ojsonpath='{.items[0].spec.podCIDR}')
  DOCKER_IP=$(docker inspect -f "{{ .NetworkSettings.Networks.kind.IPAddress }}" istio-testing-control-plane)
  # Here, we run the snippets *inside* the docker VM. This mirrors the docs telling to run the commands
  # on the VM
  docker exec --privileged vm bash -c "
    # Setup connectivity
    ip route add ${POD_CIDR} via ${DOCKER_IP}
    # Docker sets up a bunch of rules for DNS which messes with things. Just remove all of them
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT ACCEPT
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    sudo iptables -F
    sudo iptables -X
    echo nameserver 8.8.8.8 | sudo tee /etc/resolv.conf
    source /test/snips.sh
    snip_configure_the_virtual_machine_1
    snip_configure_the_virtual_machine_2
    # TODO: we should probably have a better way to get the debian package
    curl -LO https://storage.googleapis.com/istio-build/dev/1.9-alpha.cdae086ca8cae8be174c8feee509841f89792e43/deb/istio-sidecar.deb
    sudo dpkg -i istio-sidecar.deb
    snip_configure_the_virtual_machine_5
    snip_configure_the_virtual_machine_6
    snip_configure_the_virtual_machine_7
    snip_configure_the_virtual_machine_8
  "
}

function start_vm() {
  # We cannot use systemd inside docker (since its a pain). Just run it directly.
  docker exec --privileged -w / -e ISTIO_AGENT_FLAGS="--log_output_level=dns:debug" -d vm /usr/local/bin/istio-start.sh
}
