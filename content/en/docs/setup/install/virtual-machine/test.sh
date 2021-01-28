#!/usr/bin/env bash
# shellcheck disable=SC2034

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

source "tests/util/samples.sh"

VM_APP="vm-app"
VM_NAMESPACE="vm-namespace"
WORK_DIR="$(mktemp -d)"
SERVICE_ACCOUNT="default"
CLUSTER_NETWORK=""
VM_NETWORK=""
CLUSTER="Kubernetes"

# @setup profile=none

snip_setup_wd

snip_setup_iop

echo y | snip_install_istio

snip_install_eastwest

snip_expose_istio

snip_install_namespace || true

snip_install_sa || true

snip_create_wg

snip_apply_wg

snip_configure_wg

# Rather than spinning up a real VM, we will use a docker container
# We do the implicit "Securely transfer the files from "${WORK_DIR}" to the virtual machine." step by
# a volume mount
docker run --rm -it --init -d --network=kind --name vm \
  -v "${WORK_DIR}:/root" -v "${PWD}/content/en/docs/setup/install/virtual-machine:/test" -w "/root" \
  gcr.io/istio-release/base:1.9-dev.2

POD_CIDR=$(kubectl get node -ojsonpath='{.items[0].spec.podCIDR}')
DOCKER_IP=$(docker inspect -f "{{ .NetworkSettings.Networks.kind.IPAddress }}" istio-testing-control-plane)
# Here, we run the snippets *inside* the docker VM. This mirrors the docs telling to run the commands
# on the VM
docker exec --privileged vm bash -c "
  # Setup connectivity
  ip route add ${POD_CIDR} via ${DOCKER_IP}
  source /test/snips.sh
  snip_configure_the_virtual_machine_1
  snip_configure_the_virtual_machine_2
  # TODO: we should probably have a better way to get the debian package
  curl -LO https://storage.googleapis.com/istio-build/dev/1.10-alpha.e0558027c9915da4d966bad51a649abfa1bc17b6/deb/istio-sidecar.deb
  sudo dpkg -i istio-sidecar.deb
  snip_configure_the_virtual_machine_5
  snip_configure_the_virtual_machine_6
  snip_configure_the_virtual_machine_7
  snip_configure_the_virtual_machine_8
"
# We cannot use systemd inside docker (since its a pain). Just run it directly.
docker exec --privileged -w / -d vm /usr/local/bin/istio-start.sh

snip_verify_istio_works_successfully_2 || true
snip_verify_istio_works_successfully_3
_wait_for_deployment sample helloworld-v1
_wait_for_deployment sample helloworld-v2

check_call() {
  docker exec vm bash -c "source /test/snips.sh; snip_verify_istio_works_successfully_4"
}

_verify_contains check_call "Hello version:"

# @cleanup
docker stop vm
snip_uninstall_4
kubectl delete namespace istio-system vm-namespace sample
