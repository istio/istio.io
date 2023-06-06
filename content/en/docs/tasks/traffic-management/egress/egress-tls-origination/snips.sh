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
#          docs/tasks/traffic-management/egress/egress-tls-origination/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_before_you_begin_2() {
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
}

snip_before_you_begin_3() {
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
}

snip_apply_simple() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  - number: 443
    name: https-port
    protocol: HTTPS
  resolution: DNS
EOF
}

snip_curl_simple() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
}

! read -r -d '' snip_curl_simple_out <<\ENDSNIP
HTTP/1.1 301 Moved Permanently
...
location: https://edition.cnn.com/politics
...

HTTP/2 200
...
ENDSNIP

snip_apply_origination() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: edition-cnn-com
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
    targetPort: 443
  - number: 443
    name: https-port
    protocol: HTTPS
  resolution: DNS
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: edition-cnn-com
spec:
  host: edition.cnn.com
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 80
      tls:
        mode: SIMPLE # initiates HTTPS when accessing edition.cnn.com
EOF
}

snip_curl_origination_http() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
}

! read -r -d '' snip_curl_origination_http_out <<\ENDSNIP
HTTP/1.1 200 OK
...
ENDSNIP

snip_curl_origination_https() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
}

! read -r -d '' snip_curl_origination_https_out <<\ENDSNIP
HTTP/2 200
...
ENDSNIP

snip_cleanup_the_tls_origination_configuration_1() {
kubectl delete serviceentry edition-cnn-com
kubectl delete destinationrule edition-cnn-com
}

snip_configure_the_client_sleep_pod_1() {
kubectl create secret generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
}

snip_configure_the_client_sleep_pod_2() {
kubectl create role client-credential-role --resource=secret --verb=list
kubectl create rolebinding client-credential-role-binding --role=client-credential-role --serviceaccount=default:sleep
}

snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: originate-mtls-for-nginx
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
    targetPort: 443
  - number: 443
    name: https-port
    protocol: HTTPS
  resolution: DNS
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  workloadSelector:
    matchLabels:
      app: sleep
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 80
      tls:
        mode: MUTUAL
        credentialName: client-credential # this must match the secret created earlier to hold client certs, and works only when DR has a workloadSelector
        sni: my-nginx.mesh-external.svc.cluster.local # this is optional
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_2() {
istioctl proxy-config secret deploy/sleep | grep client-credential
}

! read -r -d '' snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_2_out <<\ENDSNIP
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:15:20Z     2023-06-05T12:15:20Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           10792363984292733914                       2024-06-04T12:15:19Z     2023-06-05T12:15:19Z
ENDSNIP

snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_3() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
}

! read -r -d '' snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_3_out <<\ENDSNIP
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
ENDSNIP

snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_4() {
kubectl logs -l app=sleep -c istio-proxy | grep 'my-nginx.mesh-external.svc.cluster.local'
}

snip_cleanup_the_mutual_tls_origination_configuration_1() {
kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
kubectl delete secret client-credential
kubectl delete rolebinding client-credential-role-binding
kubectl delete role client-credential-role
kubectl delete configmap nginx-configmap -n mesh-external
kubectl delete service my-nginx -n mesh-external
kubectl delete deployment my-nginx -n mesh-external
kubectl delete namespace mesh-external
kubectl delete serviceentry originate-mtls-for-nginx
kubectl delete destinationrule originate-mtls-for-nginx
}

snip_cleanup_the_mutual_tls_origination_configuration_2() {
rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
}

snip_cleanup_the_mutual_tls_origination_configuration_3() {
rm ./nginx.conf
}

snip_cleanup_common_configuration_1() {
kubectl delete service sleep
kubectl delete deployment sleep
}
