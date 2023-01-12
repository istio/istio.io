#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2155

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
source "content/en/docs/setup/install/virtual-machine/common.sh"

export VM_APP="vm-app"
export VM_NAMESPACE="vm-namespace"
export WORK_DIR="$(mktemp -d)"
export SERVICE_ACCOUNT="default"
export CLUSTER_NETWORK=""
export VM_NETWORK=""
export CLUSTER="Kubernetes"

# @setup profile=none

setup_cluster_for_vms
setup_vm
start_vm

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
kubectl delete validatingwebhookconfiguration istiod-default-validator #TODO fix snip and then remove
kubectl delete mutatingwebhookconfiguration istio-revision-tag-default #TODO fix snip and then remove
kubectl delete namespace istio-system vm-namespace sample
