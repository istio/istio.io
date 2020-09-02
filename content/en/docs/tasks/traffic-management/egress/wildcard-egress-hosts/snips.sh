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

snip_before_you_begin_1() {
istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
}

snip_before_you_begin_2() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_before_you_begin_3() {
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
}

snip_before_you_begin_4() {
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

snip_wildcard_configuration_for_a_single_hosting_server_1() {
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

snip_wildcard_configuration_for_a_single_hosting_server_2() {
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

snip_wildcard_configuration_for_a_single_hosting_server_3() {
kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
}

! read -r -d '' snip_wildcard_configuration_for_a_single_hosting_server_3_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
ENDSNIP

snip_wildcard_configuration_for_a_single_hosting_server_4() {
kubectl exec "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -n istio-system -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
}

! read -r -d '' snip_wildcard_configuration_for_a_single_hosting_server_4_out <<\ENDSNIP
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
ENDSNIP

snip_cleanup_wildcard_configuration_for_a_single_hosting_server_1() {
kubectl delete serviceentry www-wikipedia
kubectl delete gateway istio-egressgateway
kubectl delete virtualservice direct-wikipedia-through-egress-gateway
kubectl delete destinationrule egressgateway-for-wikipedia
}

snip_setup_egress_gateway_with_sni_proxy_1() {
cat <<EOF > ./sni-proxy.conf
user www-data;

events {
}

stream {
  log_format log_stream '\$remote_addr [\$time_local] \$protocol [\$ssl_preread_server_name]'
  '\$status \$bytes_sent \$bytes_received \$session_time';

  access_log /var/log/nginx/access.log log_stream;
  error_log  /var/log/nginx/error.log;

  # tcp forward proxy by SNI
  server {
    resolver 8.8.8.8 ipv6=off;
    listen       127.0.0.1:8443;
    proxy_pass   \$ssl_preread_server_name:443;
    ssl_preread  on;
  }
}
EOF
}

snip_setup_egress_gateway_with_sni_proxy_2() {
kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
}

snip_setup_egress_gateway_with_sni_proxy_3() {
cat > ./egressgateway-with-sni-proxy.yaml <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  meshConfig:
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
  components:
    egressGateways:
    - name: istio-egressgateway-with-sni-proxy
      enabled: true
      label:
        app: istio-egressgateway-with-sni-proxy
        istio: egressgateway-with-sni-proxy
      k8s:
        service:
          ports:
          - port: 443
            name: https
EOF
}

snip_setup_egress_gateway_with_sni_proxy_4() {
istioctl install -f ./egressgateway-with-sni-proxy.yaml --set values.gateways.istio-egressgateway.runAsRoot=true
}

snip_setup_egress_gateway_with_sni_proxy_5() {
cat <<EOF > ./egressgateway-with-sni-proxy-patch.yaml
spec:
  template:
    spec:
      volumes:
      - name: sni-proxy-config
        configMap:
          name: egress-sni-proxy-configmap
          defaultMode: 292 # 0444
      containers:
      - name: sni-proxy
        image: nginx
        volumeMounts:
        - name: sni-proxy-config
          mountPath: /etc/nginx
          readOnly: true
        securityContext:
          runAsNonRoot: false
          runAsUser: 0
EOF
}

snip_setup_egress_gateway_with_sni_proxy_6() {
kubectl patch deployment istio-egressgateway-with-sni-proxy -n istio-system --patch "$(cat ./egressgateway-with-sni-proxy-patch.yaml)"
}

! read -r -d '' snip_setup_egress_gateway_with_sni_proxy_6_out <<\ENDSNIP
deployment.apps/istio-egressgateway-with-sni-proxy patched
ENDSNIP

snip_setup_egress_gateway_with_sni_proxy_7() {
kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
}

! read -r -d '' snip_setup_egress_gateway_with_sni_proxy_7_out <<\ENDSNIP
NAME                                                  READY     STATUS    RESTARTS   AGE
istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
ENDSNIP

snip_setup_egress_gateway_with_sni_proxy_8() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: sni-proxy
spec:
  hosts:
  - sni-proxy.local
  location: MESH_EXTERNAL
  ports:
  - number: 8443
    name: tcp
    protocol: TCP
  resolution: STATIC
  endpoints:
  - address: 127.0.0.1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: disable-mtls-for-sni-proxy
spec:
  host: sni-proxy.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
}

snip_configure_traffic_through_egress_gateway_with_sni_proxy_1() {
cat <<EOF | kubectl create -f -
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: wikipedia
spec:
  hosts:
  - "*.wikipedia.org"
  ports:
  - number: 443
    name: tls
    protocol: TLS
EOF
}

snip_configure_traffic_through_egress_gateway_with_sni_proxy_2() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway-with-sni-proxy
spec:
  selector:
    istio: egressgateway-with-sni-proxy
  servers:
  - port:
      number: 443
      name: tls-egress
      protocol: TLS
    hosts:
    - "*.wikipedia.org"
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-wikipedia
spec:
  host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
  subsets:
    - name: wikipedia
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: ISTIO_MUTUAL
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
  - istio-egressgateway-with-sni-proxy
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - "*.wikipedia.org"
    route:
    - destination:
        host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
        subset: wikipedia
        port:
          number: 443
      weight: 100
  tcp:
  - match:
    - gateways:
      - istio-egressgateway-with-sni-proxy
      port: 443
    route:
    - destination:
        host: sni-proxy.local
        port:
          number: 8443
      weight: 100
---
# The following filter is used to forward the original SNI (sent by the application) as the SNI of the
# mutual TLS connection.
# The forwarded SNI will be will be used to enforce policies based on the original SNI value.
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: forward-downstream-sni
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        portNumber: 443
        filterChain:
          filter:
            name: istio.stats
    patch:
      operation: INSERT_BEFORE
      value:
         name: forward_downstream_sni
         config: {}
EOF
}

snip_configure_traffic_through_egress_gateway_with_sni_proxy_3() {
kubectl apply -n istio-system -f - <<EOF
# The following filter verifies that the SNI of the mutual TLS connection is
# identical to the original SNI issued by the client (the SNI used for routing by the SNI proxy).
# The filter prevents the gateway from being deceived by a malicious client: routing to one SNI while
# reporting some other value of SNI. If the original SNI does not match the SNI of the mutual TLS connection,
# the filter will block the connection to the external service.
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: egress-gateway-sni-verifier
spec:
  workloadSelector:
    labels:
      app: istio-egressgateway-with-sni-proxy
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: GATEWAY
      listener:
        portNumber: 443
        filterChain:
          filter:
            name: istio.stats
    patch:
      operation: INSERT_BEFORE
      value:
         name: sni_verifier
         config: {}
EOF
}

snip_configure_traffic_through_egress_gateway_with_sni_proxy_4() {
kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
}

! read -r -d '' snip_configure_traffic_through_egress_gateway_with_sni_proxy_4_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
<title>Wikipedia – Die freie Enzyklopädie</title>
ENDSNIP

snip_configure_traffic_through_egress_gateway_with_sni_proxy_5() {
kubectl logs -l istio=egressgateway-with-sni-proxy -c istio-proxy -n istio-system
}

! read -r -d '' snip_configure_traffic_through_egress_gateway_with_sni_proxy_6 <<\ENDSNIP
[2019-01-02T16:34:23.312Z] "- - -" 0 - 578 79141 624 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55018 172.30.109.84:443 172.30.109.112:45346 en.wikipedia.org
[2019-01-02T16:34:24.079Z] "- - -" 0 - 586 65770 638 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55034 172.30.109.84:443 172.30.109.112:45362 de.wikipedia.org
ENDSNIP

snip_configure_traffic_through_egress_gateway_with_sni_proxy_7() {
kubectl logs -l istio=egressgateway-with-sni-proxy -n istio-system -c sni-proxy
}

! read -r -d '' snip_configure_traffic_through_egress_gateway_with_sni_proxy_7_out <<\ENDSNIP
127.0.0.1 [01/Aug/2018:15:32:02 +0000] TCP [en.wikipedia.org]200 81513 280 0.600
127.0.0.1 [01/Aug/2018:15:32:03 +0000] TCP [de.wikipedia.org]200 67745 291 0.659
ENDSNIP

snip_cleanup_wildcard_configuration_for_arbitrary_domains_1() {
kubectl delete serviceentry wikipedia
kubectl delete gateway istio-egressgateway-with-sni-proxy
kubectl delete virtualservice direct-wikipedia-through-egress-gateway
kubectl delete destinationrule egressgateway-for-wikipedia
kubectl delete --ignore-not-found=true envoyfilter forward-downstream-sni
kubectl delete --ignore-not-found=true envoyfilter -n istio-system egress-gateway-sni-verifier
}

snip_cleanup_wildcard_configuration_for_arbitrary_domains_2() {
kubectl delete serviceentry sni-proxy
kubectl delete destinationrule disable-mtls-for-sni-proxy
kubectl delete configmap egress-sni-proxy-configmap -n istio-system
}

snip_cleanup_wildcard_configuration_for_arbitrary_domains_3() {
rm ./sni-proxy.conf ./egressgateway-with-sni-proxy.yaml ./egressgateway-with-sni-proxy-patch.yaml
}

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
istioctl x uninstall
}
