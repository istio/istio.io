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
#          docs/tasks/traffic-management/egress/wildcard-egress-hosts/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-gamma-support.sh"

snip_before_you_begin_1() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
}

snip_before_you_begin_2() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=minimal -y \
    --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true \
    --set meshConfig.accessLogFile=/dev/stdout \
    --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
}

snip_before_you_begin_3() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_before_you_begin_4() {
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
}

snip_before_you_begin_5() {
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
}

snip_configure_direct_traffic_to_a_wildcard_host_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: wikipedia
spec:
  hosts:
  - "*.wikipedia.org"
  ports:
  - number: 443
    name: https
    protocol: HTTPS
EOF
}

snip_configure_direct_traffic_to_a_wildcard_host_2() {
kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
}

! read -r -d '' snip_configure_direct_traffic_to_a_wildcard_host_2_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
ENDSNIP

snip_cleanup_direct_traffic_to_a_wildcard_host_1() {
kubectl delete serviceentry wikipedia
}

snip_configure_egress_gateway_traffic_to_a_wildcard_host_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*.wikipedia.org"
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-wikipedia
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
    - name: wikipedia
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-wikipedia-through-egress-gateway
spec:
  hosts:
  - "*.wikipedia.org"
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - "*.wikipedia.org"
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: wikipedia
        port:
          number: 443
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sniHosts:
      - "*.wikipedia.org"
    route:
    - destination:
        host: www.wikipedia.org
        port:
          number: 443
      weight: 100
EOF
}

snip_configure_egress_gateway_traffic_to_a_wildcard_host_2() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: wikipedia-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: "*.wikipedia.org"
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-wikipedia-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: wikipedia
  rules:
  - backendRefs:
    - name: wikipedia-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-wikipedia-from-egress-gateway
spec:
  parentRefs:
  - name: wikipedia-egress-gateway
  hostnames:
  - "*.wikipedia.org"
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: www.wikipedia.org
      port: 443
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: wikipedia
spec:
  hosts:
  - "*.wikipedia.org"
  ports:
  - number: 443
    name: https
    protocol: HTTPS
EOF
}

snip_configure_egress_gateway_traffic_to_a_wildcard_host_3() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: www-wikipedia
spec:
  hosts:
  - www.wikipedia.org
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
EOF
}

snip_configure_egress_gateway_traffic_to_a_wildcard_host_4() {
kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
}

! read -r -d '' snip_configure_egress_gateway_traffic_to_a_wildcard_host_4_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
ENDSNIP

snip_configure_egress_gateway_traffic_to_a_wildcard_host_5() {
kubectl exec "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -n istio-system -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
}

! read -r -d '' snip_configure_egress_gateway_traffic_to_a_wildcard_host_5_out <<\ENDSNIP
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
ENDSNIP

snip_configure_egress_gateway_traffic_to_a_wildcard_host_6() {
kubectl exec "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=wikipedia-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
}

! read -r -d '' snip_configure_egress_gateway_traffic_to_a_wildcard_host_6_out <<\ENDSNIP
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
ENDSNIP

snip_cleanup_egress_gateway_traffic_to_a_wildcard_host_1() {
kubectl delete serviceentry www-wikipedia
kubectl delete gateway istio-egressgateway
kubectl delete virtualservice direct-wikipedia-through-egress-gateway
kubectl delete destinationrule egressgateway-for-wikipedia
}

snip_cleanup_egress_gateway_traffic_to_a_wildcard_host_2() {
kubectl delete se wikipedia
kubectl delete se www-wikipedia
kubectl delete gtw wikipedia-egress-gateway
kubectl delete tlsroute direct-wikipedia-to-egress-gateway
kubectl delete tlsroute forward-wikipedia-from-egress-gateway
}

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
}

snip_cleanup_2() {
istioctl uninstall --purge -y
}
