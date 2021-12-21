#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2155,SC2154

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

export VM_APP="mysqldb"
export VM_NAMESPACE="vm"
export WORK_DIR="$(mktemp -d)"
export SERVICE_ACCOUNT="default"
export CLUSTER_NETWORK=""
export VM_NETWORK=""
export CLUSTER="Kubernetes"

source "tests/util/samples.sh"
source "content/en/docs/setup/install/virtual-machine/snips.sh"
source "content/en/docs/setup/install/virtual-machine/common.sh"

function run_in_vm() {
  script="${1:?script}"
  docker exec --privileged vm bash -c "set -x; source /examples/snips.sh;
  ${script}
"
}

function run_in_vm_interactive() {
  script="${1:?script}"
  docker exec -t --privileged vm bash -c "set -x ;source /examples/snips.sh;
  ${script}
"
}

# @setup profile=none

setup_cluster_for_vms
EXTRA_VM_ARGS="-v ${PWD}/content/en/docs/examples/virtual-machines:/examples" setup_vm
start_vm
echo "VM STARTED"
run_in_vm "while ! curl localhost:15021/healthz/ready -s; do sleep 1; done"
run_in_vm "while ! curl archive.ubuntu.com -s; do sleep 1; done"

run_in_vm "
 snip_running_mysql_on_the_vm_1
 mkdir -p /var/lib/mysql /var/run/mysqld
 chown -R mysql:mysql /var/lib/mysql /var/run/mysqld;
 chmod 777 /var/run/mysqld
"

# We do not have systemd, need to start mysql manually
docker exec --privileged -d vm mysqld --skip-grant-tables
# Wait for mysql to be ready
run_in_vm "while ! sudo mysql 2> /dev/null; do echo retrying mysql...; sleep 5; done"

run_in_vm snip_running_mysql_on_the_vm_3

check_table4() { run_in_vm_interactive snip_running_mysql_on_the_vm_4; }
_verify_contains check_table4 "${snip_running_mysql_on_the_vm_4_out}"

check_table5() { run_in_vm_interactive snip_running_mysql_on_the_vm_5; }
_verify_contains check_table5 "${snip_running_mysql_on_the_vm_5_out}"

snip_expose_the_mysql_service_to_the_mesh_1

# Setup test applications. Doc assumes these are present
kubectl create namespace bookinfo || true
kubectl label namespace bookinfo istio-injection=enabled --overwrite
kubectl apply -n bookinfo -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -n bookinfo -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl apply -n bookinfo -f samples/bookinfo/networking/destination-rule-all.yaml
startup_sleep_sample
for deploy in "productpage-v1" "details-v1" "ratings-v1" "reviews-v1" "reviews-v2" "reviews-v3"; do
    _wait_for_deployment bookinfo "$deploy"
done

# Switch bookinfo to point to mysql
snip_using_the_mysql_service_1
snip_using_the_mysql_service_2

# Send traffic, ensure we get ratings
get_bookinfo_productpage() {
    sample_http_request "/productpage"
}
_verify_contains get_bookinfo_productpage "glyphicon glyphicon-star"

run_curl() { run_in_vm_interactive snip_reaching_kubernetes_services_from_the_virtual_machine_1; }
_verify_elided run_curl "${snip_reaching_kubernetes_services_from_the_virtual_machine_1_out}"

# @cleanup
docker stop vm
kubectl delete -f samples/multicluster/expose-istiod.yaml -n istio-system --ignore-not-found=true
istioctl manifest generate | kubectl delete -f - --ignore-not-found=true
cleanup_sleep_sample
kubectl delete namespace istio-system vm bookinfo  --ignore-not-found=true
