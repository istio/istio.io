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
#          docs/tasks/traffic-management/egress/egress-gateway-tls-origination/index.md
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

snip_perform_tls_origination_with_an_egress_gateway_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: cnn
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
EOF
}

snip_perform_tls_origination_with_an_egress_gateway_2() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
}

! read -r -d '' snip_perform_tls_origination_with_an_egress_gateway_2_out <<\ENDSNIP
HTTP/1.1 301 Moved Permanently
...
location: https://edition.cnn.com/politics
...
ENDSNIP

snip_perform_tls_origination_with_an_egress_gateway_3() {
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
      number: 80
      name: http-port-for-tls-origination
      protocol: HTTP
    hosts:
    - edition.cnn.com
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
}

snip_perform_tls_origination_with_an_egress_gateway_4() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: originate-tls-for-edition-cnn-com
spec:
  host: edition.cnn.com
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
EOF
}

snip_perform_tls_origination_with_an_egress_gateway_5() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
}

! read -r -d '' snip_perform_tls_origination_with_an_egress_gateway_5_out <<\ENDSNIP
HTTP/1.1 200 OK
...
ENDSNIP

snip_perform_tls_origination_with_an_egress_gateway_6() {
kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
}

snip_cleanup_the_tls_origination_example_1() {
kubectl delete gateway istio-egressgateway
kubectl delete serviceentry cnn
kubectl delete virtualservice direct-cnn-through-egress-gateway
kubectl delete destinationrule originate-tls-for-edition-cnn-com
kubectl delete destinationrule egressgateway-for-cnn
}

snip_cleanup_the_tls_origination_example_2() {
kubectl delete -f samples/sleep/sleep.yaml
}

snip_generate_client_and_server_certificates_and_keys_1() {
git clone https://github.com/nicholasjackson/mtls-go-example
}

snip_generate_client_and_server_certificates_and_keys_2() {
cd mtls-go-example
}

snip_generate_client_and_server_certificates_and_keys_3() {
./generate.sh nginx.example.com password
}

snip_generate_client_and_server_certificates_and_keys_4() {
mkdir ../nginx.example.com && mv 1_root 2_intermediate 3_application 4_client ../nginx.example.com
}

snip_generate_client_and_server_certificates_and_keys_5() {
cd ..
}

snip_deploy_a_mutual_tls_server_1() {
kubectl create namespace mesh-external
}

snip_deploy_a_mutual_tls_server_2() {
kubectl create -n mesh-external secret tls nginx-server-certs --key nginx.example.com/3_application/private/nginx.example.com.key.pem --cert nginx.example.com/3_application/certs/nginx.example.com.cert.pem
kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
}

snip_deploy_a_mutual_tls_server_3() {
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
    ssl_client_certificate /etc/nginx-ca-certs/ca-chain.cert.pem;
    ssl_verify_client on;
  }
}
EOF
}

snip_deploy_a_mutual_tls_server_4() {
kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
}

snip_deploy_a_mutual_tls_server_5() {
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  namespace: mesh-external
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
  namespace: mesh-external
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
        - name: nginx-ca-certs
          mountPath: /etc/nginx-ca-certs
          readOnly: true
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-configmap
      - name: nginx-server-certs
        secret:
          secretName: nginx-server-certs
      - name: nginx-ca-certs
        secret:
          secretName: nginx-ca-certs
EOF
}

snip_deploy_a_mutual_tls_server_6() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: nginx
spec:
  hosts:
  - nginx.example.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  endpoints:
  - address: my-nginx.mesh-external.svc.cluster.local
    ports:
      https: 443
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx
spec:
  hosts:
  - nginx.example.com
  tls:
  - match:
    - port: 443
      sniHosts:
      - nginx.example.com
    route:
    - destination:
        host: nginx.example.com
        port:
          number: 443
      weight: 100
EOF
}

snip_deploy_a_container_to_test_the_nginx_deployment_1() {
kubectl create secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
kubectl create secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
}

snip_deploy_a_container_to_test_the_nginx_deployment_2() {
kubectl apply -f - <<EOF
# Copyright 2017 Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

##################################################################################################
# Sleep service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: sleep
  labels:
    app: sleep
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: sleep
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: nginx-client-certs
          mountPath: /etc/nginx-client-certs
          readOnly: true
        - name: nginx-ca-certs
          mountPath: /etc/nginx-ca-certs
          readOnly: true
      volumes:
      - name: nginx-client-certs
        secret:
          secretName: nginx-client-certs
      - name: nginx-ca-certs
        secret:
          secretName: nginx-ca-certs
EOF
}

snip_deploy_a_container_to_test_the_nginx_deployment_3() {
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
}

snip_deploy_a_container_to_test_the_nginx_deployment_4() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -v --resolve nginx.example.com:443:1.1.1.1 --cacert /etc/nginx-ca-certs/ca-chain.cert.pem --cert /etc/nginx-client-certs/tls.crt --key /etc/nginx-client-certs/tls.key https://nginx.example.com
}

! read -r -d '' snip_deploy_a_container_to_test_the_nginx_deployment_4_out <<\ENDSNIP
...
< HTTP/1.1 200 OK
...
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
ENDSNIP

snip_deploy_a_container_to_test_the_nginx_deployment_5() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -k --resolve nginx.example.com:443:1.1.1.1 https://nginx.example.com
}

! read -r -d '' snip_deploy_a_container_to_test_the_nginx_deployment_5_out <<\ENDSNIP
...
<html>
<head><title>400 No required SSL certificate was sent</title></head>
<body>
<center><h1>400 Bad Request</h1></center>
<center>No required SSL certificate was sent</center>
...
</body>
</html>
ENDSNIP

snip_redeploy_the_egress_gateway_with_the_client_certificates_1() {
kubectl create -n istio-system secret tls nginx-client-certs --key nginx.example.com/4_client/private/nginx.example.com.key.pem --cert nginx.example.com/4_client/certs/nginx.example.com.cert.pem
kubectl create -n istio-system secret generic nginx-ca-certs --from-file=nginx.example.com/2_intermediate/certs/ca-chain.cert.pem
}

snip_redeploy_the_egress_gateway_with_the_client_certificates_2() {
cat > gateway-patch.json <<EOF
[{
  "op": "add",
  "path": "/spec/template/spec/containers/0/volumeMounts/0",
  "value": {
    "mountPath": "/etc/istio/nginx-client-certs",
    "name": "nginx-client-certs",
    "readOnly": true
  }
},
{
  "op": "add",
  "path": "/spec/template/spec/volumes/0",
  "value": {
  "name": "nginx-client-certs",
    "secret": {
      "secretName": "nginx-client-certs",
      "optional": true
    }
  }
},
{
  "op": "add",
  "path": "/spec/template/spec/containers/0/volumeMounts/1",
  "value": {
    "mountPath": "/etc/istio/nginx-ca-certs",
    "name": "nginx-ca-certs",
    "readOnly": true
  }
},
{
  "op": "add",
  "path": "/spec/template/spec/volumes/1",
  "value": {
  "name": "nginx-ca-certs",
    "secret": {
      "secretName": "nginx-ca-certs",
      "optional": true
    }
  }
}]
EOF
}

snip_redeploy_the_egress_gateway_with_the_client_certificates_3() {
kubectl -n istio-system patch --type=json deploy istio-egressgateway -p "$(cat gateway-patch.json)"
}

snip_redeploy_the_egress_gateway_with_the_client_certificates_4() {
kubectl exec -it -n istio-system "$(kubectl -n istio-system get pods -l istio=egressgateway -o jsonpath='{.items[0].metadata.name}')" -- ls -al /etc/istio/nginx-client-certs /etc/istio/nginx-ca-certs
}

snip_configure_mutual_tls_origination_for_egress_traffic_1() {
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
    - nginx.example.com
    tls:
      mode: MUTUAL
      serverCertificate: /etc/certs/cert-chain.pem
      privateKey: /etc/certs/key.pem
      caCertificates: /etc/certs/root-cert.pem
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: nginx
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 443
        tls:
          mode: ISTIO_MUTUAL
          sni: nginx.example.com
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_2() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-nginx-through-egress-gateway
spec:
  hosts:
  - nginx.example.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: nginx
        port:
          number: 443
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
    route:
    - destination:
        host: nginx.example.com
        port:
          number: 443
      weight: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: nginx.example.com
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        clientCertificate: /etc/istio/nginx-client-certs/tls.crt
        privateKey: /etc/istio/nginx-client-certs/tls.key
        caCertificates: /etc/istio/nginx-ca-certs/ca-chain.cert.pem
        sni: nginx.example.com
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_3() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -s --resolve nginx.example.com:80:1.1.1.1 http://nginx.example.com
}

! read -r -d '' snip_configure_mutual_tls_origination_for_egress_traffic_3_out <<\ENDSNIP
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
ENDSNIP

snip_configure_mutual_tls_origination_for_egress_traffic_4() {
kubectl logs -l istio=egressgateway -n istio-system | grep 'nginx.example.com' | grep HTTP
}

snip_mutual_tls_cleanup_1() {
kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
kubectl delete secret nginx-client-certs nginx-ca-certs
kubectl delete secret nginx-client-certs nginx-ca-certs -n istio-system
kubectl delete configmap nginx-configmap -n mesh-external
kubectl delete service my-nginx -n mesh-external
kubectl delete deployment my-nginx -n mesh-external
kubectl delete namespace mesh-external
kubectl delete gateway istio-egressgateway
kubectl delete serviceentry nginx
kubectl delete virtualservice nginx
kubectl delete virtualservice direct-nginx-through-egress-gateway
kubectl delete destinationrule originate-mtls-for-nginx
kubectl delete destinationrule egressgateway-for-nginx
}

snip_mutual_tls_cleanup_2() {
rm -rf nginx.example.com mtls-go-example
}

snip_mutual_tls_cleanup_3() {
rm -f ./nginx.conf ./istio-egressgateway.yaml
}

snip_cleanup_1() {
kubectl delete service sleep
kubectl delete deployment sleep
}
