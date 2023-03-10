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
#          docs/ops/configuration/traffic-management/dns-proxy/index.md
####################################################################################################

snip_getting_started_1() {
cat <<EOF | istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
        # Enable automatic address allocation, optional
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
EOF
}

snip_dns_capture_in_action_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-address
spec:
  addresses:
  - 198.51.100.1
  hosts:
  - address.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
EOF
}

snip_dns_capture_in_action_3() {
kubectl exec deploy/sleep -- curl -sS -v address.internal
}

! read -r -d '' snip_dns_capture_in_action_3_out <<\ENDSNIP
*   Trying 198.51.100.1:80...
ENDSNIP

snip_address_auto_allocation_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-auto
spec:
  hosts:
  - auto.internal
  ports:
  - name: http
    number: 80
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: 198.51.100.2
EOF
}

snip_address_auto_allocation_2() {
kubectl exec deploy/sleep -- curl -sS -v auto.internal
}

! read -r -d '' snip_address_auto_allocation_2_out <<\ENDSNIP
*   Trying 240.240.0.1:80...
ENDSNIP

snip_cleanup_1() {
istioctl uninstall --purge -y
kubectl delete ns istio-system
}
