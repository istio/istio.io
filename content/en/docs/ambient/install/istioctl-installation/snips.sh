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
#          docs/ambient/install/istioctl-installation/index.md
####################################################################################################

snip_prerequisites_1() {
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
}

snip_install_1() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=ambient --skip-confirmation
}

snip_verify_the_components_status_1() {
kubectl get pods -n istio-system
}

! IFS=$'\n' read -r -d '' snip_verify_the_components_status_1_out <<\ENDSNIP
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-d9rdt      1/1     Running   0          2m15s
istiod-56d848857c-pwsd6   1/1     Running   0          2m23s
ztunnel-wp7hk             1/1     Running   0          2m9s
ENDSNIP

snip_verify_the_components_status_2() {
kubectl get daemonset -n istio-system
}

! IFS=$'\n' read -r -d '' snip_verify_the_components_status_2_out <<\ENDSNIP
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m16s
ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
ENDSNIP

snip_uninstall_1() {
kubectl label namespace default istio.io/dataplane-mode-
}

snip_uninstall_2() {
kubectl logs ds/ztunnel -n istio-system  | grep inpod
}

! IFS=$'\n' read -r -d '' snip_uninstall_2_out <<\ENDSNIP
Found 3 pods, using pod/ztunnel-jrxln
inpod_enabled: true
inpod_uds: /var/run/ztunnel/ztunnel.sock
inpod_port_reuse: true
inpod_mark: 1337
2024-03-26T00:02:06.161802Z  INFO ztunnel::inpod::workloadmanager: handling new stream
2024-03-26T00:02:06.162099Z  INFO ztunnel::inpod::statemanager: pod received snapshot sent
2024-03-26T00:41:05.518194Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("7ef61e18-725a-4726-84fa-05fc2a440879") received netns, starting proxy
2024-03-26T00:50:14.856284Z  INFO ztunnel::inpod::statemanager: pod delete request, draining proxy
ENDSNIP

snip_uninstall_3() {
istioctl x waypoint delete --all
istioctl uninstall -y --purge
kubectl delete namespace istio-system
}

snip_uninstall_4() {
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl delete -f -
}
