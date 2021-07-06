#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
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

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/setup/install/virtual-machine/index.md
####################################################################################################

snip_prepare_the_guide_environment_1() {
VM_APP="<the name of the application this VM will run>"
VM_NAMESPACE="<the name of your service namespace>"
WORK_DIR="<a certificate working directory>"
SERVICE_ACCOUNT="<name of the Kubernetes service account you want to use for your VM>"
CLUSTER_NETWORK=""
VM_NETWORK=""
CLUSTER="Kubernetes"
}

snip_prepare_the_guide_environment_2() {
VM_APP="<the name of the application this VM will run>"
VM_NAMESPACE="<the name of your service namespace>"
WORK_DIR="<a certificate working directory>"
SERVICE_ACCOUNT="<name of the Kubernetes service account you want to use for your VM>"
# Customize values for multi-cluster/multi-network as needed
CLUSTER_NETWORK="kube-network"
VM_NETWORK="vm-network"
CLUSTER="cluster1"
}

snip_setup_wd() {
mkdir -p "${WORK_DIR}"
}

snip_setup_iop() {
cat <<EOF > ./vm-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: "${CLUSTER}"
      network: "${CLUSTER_NETWORK}"
EOF
}

snip_install_the_istio_control_plane_2() {
istioctl install -f vm-cluster.yaml
}

snip_install_istio() {
istioctl install -f vm-cluster.yaml --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_HEALTHCHECKS=true
}

snip_install_eastwest() {
samples/multicluster/gen-eastwest-gateway.sh --single-cluster | istioctl install -y -f -
}

snip_install_the_istio_control_plane_5() {
samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster "${CLUSTER}" --network "${CLUSTER_NETWORK}" | \
    istioctl install -y -f -
}

snip_expose_istio() {
kubectl apply -f samples/multicluster/expose-istiod.yaml
}

snip_install_the_istio_control_plane_7() {
kubectl apply -f samples/multicluster/expose-istiod.yaml
}

snip_install_the_istio_control_plane_8() {
kubectl apply -n istio-system -f samples/multicluster/expose-services.yaml
}

snip_install_namespace() {
kubectl create namespace "${VM_NAMESPACE}"
}

snip_install_sa() {
kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"
}

snip_create_files_to_transfer_to_the_virtual_machine_1() {
cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF
}

snip_create_wg() {
cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF
}

snip_apply_wg() {
kubectl --namespace "${VM_NAMESPACE}" apply -f workloadgroup.yaml
}

snip_create_files_to_transfer_to_the_virtual_machine_4() {
cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${NETWORK}"
  probe:
    periodSeconds: 5
    initialDelaySeconds: 1
    httpGet:
      port: 8080
      path: /ready
EOF
}

snip_create_files_to_transfer_to_the_virtual_machine_5() {
istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}"
}

snip_configure_wg() {
istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}" --autoregister
}

snip_configure_the_virtual_machine_1() {
sudo mkdir -p /etc/certs
sudo cp "${HOME}"/root-cert.pem /etc/certs/root-cert.pem
}

snip_configure_the_virtual_machine_2() {
sudo  mkdir -p /var/run/secrets/tokens
sudo cp "${HOME}"/istio-token /var/run/secrets/tokens/istio-token
}

snip_configure_the_virtual_machine_5() {
sudo cp "${HOME}"/cluster.env /var/lib/istio/envoy/cluster.env
}

snip_configure_the_virtual_machine_6() {
sudo cp "${HOME}"/mesh.yaml /etc/istio/config/mesh
}

snip_configure_the_virtual_machine_7() {
sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts >> /etc/hosts'
}

snip_configure_the_virtual_machine_8() {
sudo mkdir -p /etc/istio/proxy
sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem
}

snip_start_istio_within_the_virtual_machine_1() {
sudo systemctl start istio
}

snip_verify_istio_works_successfully_1() {
2020-08-21T01:32:17.748413Z info sds resource:default pushed key/cert pair to proxy
2020-08-21T01:32:20.270073Z info sds resource:ROOTCA new connection
2020-08-21T01:32:20.270142Z info sds Skipping waiting for gateway secret
2020-08-21T01:32:20.270279Z info cache adding watcher for file ./etc/certs/root-cert.pem
2020-08-21T01:32:20.270347Z info cache GenerateSecret from file ROOTCA
2020-08-21T01:32:20.270494Z info sds resource:ROOTCA pushed root cert to proxy
2020-08-21T01:32:20.270734Z info sds resource:default new connection
2020-08-21T01:32:20.270763Z info sds Skipping waiting for gateway secret
2020-08-21T01:32:20.695478Z info cache GenerateSecret default
2020-08-21T01:32:20.695595Z info sds resource:default pushed key/cert pair to proxy
}

snip_verify_istio_works_successfully_2() {
kubectl create namespace sample
kubectl label namespace sample istio-injection=enabled
}

snip_verify_istio_works_successfully_3() {
kubectl apply -n sample -f samples/helloworld/helloworld.yaml
}

snip_verify_istio_works_successfully_4() {
curl helloworld.sample.svc:5000/hello
}

! read -r -d '' snip_verify_istio_works_successfully_4_out <<\ENDSNIP
Hello version: v1, instance: helloworld-v1-578dd69f69-fxwwk
ENDSNIP

snip_uninstall_1() {
sudo systemctl stop istio
}

snip_uninstall_2() {
sudo dpkg -r istio-sidecar
dpkg -s istio-sidecar
}

snip_uninstall_3() {
sudo rpm -e istio-sidecar
}

snip_uninstall_4() {
kubectl delete -f samples/multicluster/expose-istiod.yaml
istioctl manifest generate | kubectl delete -f -
}

snip_uninstall_5() {
kubectl delete namespace istio-system
}
