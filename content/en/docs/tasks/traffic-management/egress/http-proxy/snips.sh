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
#          docs/tasks/traffic-management/egress/http-proxy/index.md
####################################################################################################
source "content/en/boilerplates/snips/before-you-begin-egress.sh"

snip_deploy_an_https_proxy_1() {
kubectl create namespace external
}

snip_deploy_an_https_proxy_2() {
cat <<EOF > ./proxy.conf
http_port 3128

acl SSL_ports port 443
acl CONNECT method CONNECT

http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow all

coredump_dir /var/spool/squid
EOF
}

snip_deploy_an_https_proxy_3() {
kubectl create configmap proxy-configmap -n external --from-file=squid.conf=./proxy.conf
}

snip_deploy_an_https_proxy_4() {
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: squid
  namespace: external
spec:
  replicas: 1
  selector:
    matchLabels:
      app: squid
  template:
    metadata:
      labels:
        app: squid
    spec:
      volumes:
      - name: proxy-config
        configMap:
          name: proxy-configmap
      containers:
      - name: squid
        image: sameersbn/squid:3.5.27
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: proxy-config
          mountPath: /etc/squid
          readOnly: true
EOF
}

snip_deploy_an_https_proxy_5() {
kubectl apply -n external -f samples/sleep/sleep.yaml
}

snip_deploy_an_https_proxy_6() {
export PROXY_IP="$(kubectl get pod -n external -l app=squid -o jsonpath={.items..podIP})"
}

snip_deploy_an_https_proxy_7() {
export PROXY_PORT=3128
}

snip_deploy_an_https_proxy_8() {
kubectl exec "$(kubectl get pod -n external -l app=sleep -o jsonpath={.items..metadata.name})" -n external -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
}

! read -r -d '' snip_deploy_an_https_proxy_8_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
ENDSNIP

snip_deploy_an_https_proxy_9() {
kubectl exec "$(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name})" -n external -- tail /var/log/squid/access.log
}

! read -r -d '' snip_deploy_an_https_proxy_9_out <<\ENDSNIP
1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
ENDSNIP

snip_configure_traffic_to_external_https_proxy_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: proxy
spec:
  hosts:
  - my-company-proxy.com # ignored
  addresses:
  - $PROXY_IP/32
  ports:
  - number: $PROXY_PORT
    name: tcp
    protocol: TCP
  location: MESH_EXTERNAL
EOF
}

snip_configure_traffic_to_external_https_proxy_2() {
kubectl exec "$SOURCE_POD" -c sleep -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
}

! read -r -d '' snip_configure_traffic_to_external_https_proxy_2_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
ENDSNIP

snip_configure_traffic_to_external_https_proxy_3() {
kubectl logs "$SOURCE_POD" -c istio-proxy
}

! read -r -d '' snip_configure_traffic_to_external_https_proxy_3_out <<\ENDSNIP
[2018-12-07T10:38:02.841Z] "- - -" 0 - 702 87599 92 - "-" "-" "-" "-" "172.30.109.95:3128" outbound|3128||my-company-proxy.com 172.30.230.52:44478 172.30.109.95:3128 172.30.230.52:44476 -
ENDSNIP

snip_configure_traffic_to_external_https_proxy_4() {
kubectl exec "$(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name})" -n external -- tail /var/log/squid/access.log
}

! read -r -d '' snip_configure_traffic_to_external_https_proxy_4_out <<\ENDSNIP
1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
}

snip_cleanup_2() {
kubectl delete -f samples/sleep/sleep.yaml -n external
}

snip_cleanup_3() {
kubectl delete -n external deployment squid
kubectl delete -n external configmap proxy-configmap
rm ./proxy.conf
}

snip_cleanup_4() {
kubectl delete namespace external
}

snip_cleanup_5() {
kubectl delete serviceentry proxy
}
