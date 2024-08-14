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
source "content/en/boilerplates/snips/gateway-api-support.sh"

snip_before_you_begin_1() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_before_you_begin_2() {
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
}

snip_before_you_begin_3() {
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
}

snip_before_you_begin_4() {
openssl version -a | grep OpenSSL
}

! IFS=$'\n' read -r -d '' snip_before_you_begin_4_out <<\ENDSNIP
OpenSSL 1.1.1g  21 Apr 2020
ENDSNIP

! IFS=$'\n' read -r -d '' snip_before_you_begin_5 <<\ENDSNIP
$ istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
ENDSNIP

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
kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
}

! IFS=$'\n' read -r -d '' snip_perform_tls_origination_with_an_egress_gateway_2_out <<\ENDSNIP
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
      name: https-port-for-tls-origination
      protocol: HTTPS
    hosts:
    - edition.cnn.com
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 80
        tls:
          mode: ISTIO_MUTUAL
          sni: edition.cnn.com
EOF
}

snip_perform_tls_origination_with_an_egress_gateway_4() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: https-listener-for-tls-origination
    hostname: edition.cnn.com
    port: 80
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: cnn-egress-gateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 80
      tls:
        mode: ISTIO_MUTUAL
        sni: edition.cnn.com
EOF
}

snip_perform_tls_origination_with_an_egress_gateway_5() {
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
EOF
}

snip_perform_tls_origination_with_an_egress_gateway_6() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
}

snip_perform_tls_origination_with_an_egress_gateway_7() {
kubectl apply -f - <<EOF
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

snip_perform_tls_origination_with_an_egress_gateway_8() {
kubectl exec "${SOURCE_POD}" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
}

! IFS=$'\n' read -r -d '' snip_perform_tls_origination_with_an_egress_gateway_8_out <<\ENDSNIP
HTTP/1.1 200 OK
...
ENDSNIP

snip_perform_tls_origination_with_an_egress_gateway_9() {
kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
}

snip_perform_tls_origination_with_an_egress_gateway_10() {
kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
}

! IFS=$'\n' read -r -d '' snip_perform_tls_origination_with_an_egress_gateway_11 <<\ENDSNIP
[2024-03-14T18:37:01.451Z] "GET /politics HTTP/1.1" 200 - via_upstream - "-" 0 2484998 59 37 "172.30.239.26" "curl/7.87.0-DEV" "b80c8732-8b10-4916-9a73-c3e1c848ed1e" "edition.cnn.com" "151.101.131.5:443" outbound|443||edition.cnn.com 172.30.239.33:51270 172.30.239.33:80 172.30.239.26:35192 edition.cnn.com default.forward-cnn-from-egress-gateway.0
ENDSNIP

snip_cleanup_the_tls_origination_example_1() {
kubectl delete gw istio-egressgateway
kubectl delete serviceentry cnn
kubectl delete virtualservice direct-cnn-through-egress-gateway
kubectl delete destinationrule originate-tls-for-edition-cnn-com
kubectl delete destinationrule egressgateway-for-cnn
}

snip_cleanup_the_tls_origination_example_2() {
kubectl delete serviceentry cnn
kubectl delete gtw cnn-egress-gateway
kubectl delete httproute direct-cnn-to-egress-gateway
kubectl delete httproute forward-cnn-from-egress-gateway
kubectl delete destinationrule egressgateway-for-cnn
kubectl delete destinationrule originate-tls-for-edition-cnn-com
}

snip_generate_client_and_server_certificates_and_keys_1() {
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
}

snip_generate_client_and_server_certificates_and_keys_2() {
openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
}

snip_generate_client_and_server_certificates_and_keys_4() {
openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
}

snip_deploy_a_mutual_tls_server_1() {
kubectl create namespace mesh-external
}

snip_deploy_a_mutual_tls_server_2() {
kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
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

    server_name my-nginx.mesh-external.svc.cluster.local;
    ssl_certificate /etc/nginx-server-certs/tls.crt;
    ssl_certificate_key /etc/nginx-server-certs/tls.key;
    ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
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

snip_configure_mutual_tls_origination_for_egress_traffic_1() {
kubectl create secret -n istio-system generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
}

snip_configure_mutual_tls_origination_for_egress_traffic_2() {
kubectl create secret -n default generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
}

snip_configure_mutual_tls_origination_for_egress_traffic_3() {
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
    - my-nginx.mesh-external.svc.cluster.local
    tls:
      mode: ISTIO_MUTUAL
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
          sni: my-nginx.mesh-external.svc.cluster.local
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_4() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-egressgateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: my-nginx.mesh-external.svc.cluster.local
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: nginx-egressgateway-istio-sds
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - watch
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: nginx-egressgateway-istio-sds
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-egressgateway-istio-sds
subjects:
- kind: ServiceAccount
  name: nginx-egressgateway-istio
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: nginx-egressgateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: ISTIO_MUTUAL
        sni: my-nginx.mesh-external.svc.cluster.local
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_5() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-nginx-through-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
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
        host: my-nginx.mesh-external.svc.cluster.local
        port:
          number: 443
      weight: 100
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_6() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-nginx-to-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
  gateways:
  - mesh
  http:
  - match:
    - port: 80
    route:
    - destination:
        host: nginx-egressgateway-istio.default.svc.cluster.local
        port:
          number: 443
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-nginx-from-egress-gateway
spec:
  parentRefs:
  - name: nginx-egressgateway
  hostnames:
  - my-nginx.mesh-external.svc.cluster.local
  rules:
  - backendRefs:
    - name: my-nginx
      namespace: mesh-external
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: my-nginx-reference-grant
  namespace: mesh-external
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: default
  to:
    - group: ""
      kind: Service
      name: my-nginx
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_7() {
kubectl apply -n istio-system -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # this must match the secret created earlier to hold client certs
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # can be enabled if the certificate was generated with SAN as specified in previous section
        # - my-nginx.mesh-external.svc.cluster.local
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_8() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # this must match the secret created earlier to hold client certs
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # can be enabled if the certificate was generated with SAN as specified in previous section
        # - my-nginx.mesh-external.svc.cluster.local
EOF
}

snip_configure_mutual_tls_origination_for_egress_traffic_9() {
istioctl -n istio-system proxy-config secret deploy/istio-egressgateway | grep client-credential
}

! IFS=$'\n' read -r -d '' snip_configure_mutual_tls_origination_for_egress_traffic_9_out <<\ENDSNIP
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
ENDSNIP

snip_configure_mutual_tls_origination_for_egress_traffic_10() {
istioctl proxy-config secret deploy/nginx-egressgateway-istio | grep client-credential
}

! IFS=$'\n' read -r -d '' snip_configure_mutual_tls_origination_for_egress_traffic_10_out <<\ENDSNIP
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
ENDSNIP

snip_configure_mutual_tls_origination_for_egress_traffic_11() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
}

! IFS=$'\n' read -r -d '' snip_configure_mutual_tls_origination_for_egress_traffic_11_out <<\ENDSNIP
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
ENDSNIP

snip_configure_mutual_tls_origination_for_egress_traffic_12() {
kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
}

snip_configure_mutual_tls_origination_for_egress_traffic_13() {
kubectl logs -l gateway.networking.k8s.io/gateway-name=nginx-egressgateway | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
}

! IFS=$'\n' read -r -d '' snip_configure_mutual_tls_origination_for_egress_traffic_14 <<\ENDSNIP
[2024-04-08T20:08:18.451Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 5 5 "172.30.239.41" "curl/7.87.0-DEV" "86e54df0-6dc3-46b3-a8b8-139474c32a4d" "my-nginx.mesh-external.svc.cluster.local" "172.30.239.57:443" outbound|443||my-nginx.mesh-external.svc.cluster.local 172.30.239.53:48530 172.30.239.53:443 172.30.239.41:53694 my-nginx.mesh-external.svc.cluster.local default.forward-nginx-from-egress-gateway.0
ENDSNIP

snip_cleanup_the_mutual_tls_origination_example_1() {
kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
kubectl delete configmap nginx-configmap -n mesh-external
kubectl delete service my-nginx -n mesh-external
kubectl delete deployment my-nginx -n mesh-external
kubectl delete namespace mesh-external
}

snip_cleanup_the_mutual_tls_origination_example_2() {
kubectl delete secret client-credential -n istio-system
kubectl delete gw istio-egressgateway
kubectl delete virtualservice direct-nginx-through-egress-gateway
kubectl delete destinationrule -n istio-system originate-mtls-for-nginx
kubectl delete destinationrule egressgateway-for-nginx
}

snip_cleanup_the_mutual_tls_origination_example_3() {
kubectl delete secret client-credential
kubectl delete gtw nginx-egressgateway
kubectl delete role nginx-egressgateway-istio-sds
kubectl delete rolebinding nginx-egressgateway-istio-sds
kubectl delete virtualservice direct-nginx-to-egress-gateway
kubectl delete httproute forward-nginx-from-egress-gateway
kubectl delete destinationrule originate-mtls-for-nginx
kubectl delete destinationrule egressgateway-for-nginx
kubectl delete referencegrant my-nginx-reference-grant -n mesh-external
}

snip_cleanup_the_mutual_tls_origination_example_4() {
rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
}

snip_cleanup_the_mutual_tls_origination_example_5() {
rm ./nginx.conf
}

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
}
