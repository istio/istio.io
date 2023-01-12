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
#          docs/tasks/traffic-management/ingress/ingress-sni-passthrough/index.md
####################################################################################################

snip_generate_client_and_server_certificates_and_keys_1() {
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
}

snip_generate_client_and_server_certificates_and_keys_2() {
openssl req -out nginx.example.com.csr -newkey rsa:2048 -nodes -keyout nginx.example.com.key -subj "/CN=nginx.example.com/O=some organization"
openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in nginx.example.com.csr -out nginx.example.com.crt
}

snip_deploy_an_nginx_server_1() {
kubectl create secret tls nginx-server-certs --key nginx.example.com.key --cert nginx.example.com.crt
}

snip_deploy_an_nginx_server_2() {
cat <<\EOF > ./nginx.conf
events {
}

http {
  log_format main '$remote_addr - $remote_user [$time_local]  $status '
  '"$request" $body_bytes_sent "$http_referer" '
  '"$http_user_agent" "$http_x_forwarded_for"';
  access_log /var/log/nginx/access.log main;
  error_log  /var/log/nginx/error.log;

  server {
    listen 443 ssl;

    root /usr/share/nginx/html;
    index index.html;

    server_name nginx.example.com;
    ssl_certificate /etc/nginx-server-certs/tls.crt;
    ssl_certificate_key /etc/nginx-server-certs/tls.key;
  }
}
EOF
}

snip_deploy_an_nginx_server_3() {
kubectl create configmap nginx-configmap --from-file=nginx.conf=./nginx.conf
}

snip_deploy_an_nginx_server_4() {
cat <<EOF | istioctl kube-inject -f - | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 443
    protocol: TCP
  selector:
    run: my-nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 1
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 443
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx
          readOnly: true
        - name: nginx-server-certs
          mountPath: /etc/nginx-server-certs
          readOnly: true
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-configmap
      - name: nginx-server-certs
        secret:
          secretName: nginx-server-certs
EOF
}

snip_deploy_an_nginx_server_5() {
kubectl exec "$(kubectl get pod  -l run=my-nginx -o jsonpath={.items..metadata.name})" -c istio-proxy -- curl -sS -v -k --resolve nginx.example.com:443:127.0.0.1 https://nginx.example.com
}

! read -r -d '' snip_deploy_an_nginx_server_5_out <<\ENDSNIP
...
SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
ALPN, server accepted to use http/1.1
Server certificate:
  subject: CN=nginx.example.com; O=some organization
  start date: May 27 14:18:47 2020 GMT
  expire date: May 27 14:18:47 2021 GMT
  issuer: O=example Inc.; CN=example.com
  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.

> GET / HTTP/1.1
> User-Agent: curl/7.58.0
> Host: nginx.example.com
...
< HTTP/1.1 200 OK

< Server: nginx/1.17.10
...
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
ENDSNIP

snip_configure_an_ingress_gateway_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
    hosts:
    - nginx.example.com
EOF
}

snip_configure_an_ingress_gateway_2() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx
spec:
  hosts:
  - nginx.example.com
  gateways:
  - mygateway
  tls:
  - match:
    - port: 443
      sniHosts:
      - nginx.example.com
    route:
    - destination:
        host: my-nginx
        port:
          number: 443
EOF
}

snip_configure_an_ingress_gateway_3() {
curl -v --resolve "nginx.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" --cacert example.com.crt "https://nginx.example.com:$SECURE_INGRESS_PORT"
}

! read -r -d '' snip_configure_an_ingress_gateway_3_out <<\ENDSNIP
Server certificate:
  subject: CN=nginx.example.com; O=some organization
  start date: Wed, 15 Aug 2018 07:29:07 GMT
  expire date: Sun, 25 Aug 2019 07:29:07 GMT
  issuer: O=example Inc.; CN=example.com
  SSL certificate verify ok.

  < HTTP/1.1 200 OK
  < Server: nginx/1.15.2
  ...
  <html>
  <head>
  <title>Welcome to nginx!</title>
ENDSNIP

snip_cleanup_1() {
kubectl delete secret nginx-server-certs
kubectl delete configmap nginx-configmap
kubectl delete service my-nginx
kubectl delete deployment my-nginx
kubectl delete gateway mygateway
kubectl delete virtualservice nginx
}

snip_cleanup_2() {
rm example.com.crt example.com.key nginx.example.com.crt nginx.example.com.key nginx.example.com.csr
}

snip_cleanup_3() {
rm ./nginx.conf
}
