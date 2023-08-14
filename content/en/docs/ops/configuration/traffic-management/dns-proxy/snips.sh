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

snip_dns_capture_in_action_2() {
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f samples/sleep/sleep.yaml
}

snip_dns_capture_in_action_3() {
kubectl exec deploy/sleep -- curl -sS -v address.internal
}

! read -r -d '' snip_dns_capture_in_action_3_out <<\ENDSNIP
* processing: address.internal
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
  resolution: DNS
EOF
}

snip_address_auto_allocation_2() {
kubectl exec deploy/sleep -- curl -sS -v auto.internal
}

! read -r -d '' snip_address_auto_allocation_2_out <<\ENDSNIP
*   Trying 240.240.0.1:80...
ENDSNIP

snip_external_tcp_services_without_vips_1() {
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
    # discoverySelectors configuration below is just used for simulating the external service TCP scenario,
    # so that we do not have to use an external site for testing.
    discoverySelectors:
    - matchLabels:
        istio-injection: enabled
EOF
}

snip_external_tcp_services_without_vips_2() {
kubectl create ns external-1
kubectl -n external-1 apply -f samples/tcp-echo/tcp-echo.yaml
}

snip_external_tcp_services_without_vips_3() {
kubectl create ns external-2
kubectl -n external-2 apply -f samples/tcp-echo/tcp-echo.yaml
}

snip_external_tcp_services_without_vips_4() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-svc-1
spec:
  hosts:
  - tcp-echo.external-1.svc.cluster.local
  ports:
  - name: external-svc-1
    number: 9000
    protocol: TCP
  resolution: DNS
---
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-svc-2
spec:
  hosts:
  - tcp-echo.external-2.svc.cluster.local
  ports:
  - name: external-svc-2
    number: 9000
    protocol: TCP
  resolution: DNS
EOF
}

snip_external_tcp_services_without_vips_5() {
istioctl pc listener deploy/sleep | grep tcp-echo | awk '{printf "ADDRESS=%s, DESTINATION=%s %s\n", $1, $4, $5}'
}

! read -r -d '' snip_external_tcp_services_without_vips_5_out <<\ENDSNIP
ADDRESS=240.240.105.94, DESTINATION=Cluster: outbound|9000||tcp-echo.external-2.svc.cluster.local
ADDRESS=240.240.69.138, DESTINATION=Cluster: outbound|9000||tcp-echo.external-1.svc.cluster.local
ENDSNIP

snip_cleanup_1() {
kubectl -n external-1 delete -f samples/tcp-echo/tcp-echo.yaml
kubectl -n external-2 delete -f samples/tcp-echo/tcp-echo.yaml
kubectl delete -f samples/sleep/sleep.yaml
istioctl uninstall --purge -y
kubectl delete ns istio-system external-1 external-2
}
