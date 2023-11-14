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
#          docs/tasks/security/authorization/authz-custom/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl create ns foo
kubectl label ns foo istio-injection=enabled
kubectl apply -f samples/httpbin/httpbin.yaml -n foo
kubectl apply -f samples/sleep/sleep.yaml -n foo
}

snip_before_you_begin_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_2_out <<\ENDSNIP
200
ENDSNIP

snip_deploy_the_external_authorizer_1() {
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.19/samples/extauthz/ext-authz.yaml
}

! read -r -d '' snip_deploy_the_external_authorizer_1_out <<\ENDSNIP
service/ext-authz created
deployment.apps/ext-authz created
ENDSNIP

snip_deploy_the_external_authorizer_2() {
kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
}

! read -r -d '' snip_deploy_the_external_authorizer_2_out <<\ENDSNIP
2021/01/07 22:55:47 Starting HTTP server at [::]:8000
2021/01/07 22:55:47 Starting gRPC server at [::]:9000
ENDSNIP

! read -r -d '' snip_deploy_the_external_authorizer_3 <<\ENDSNIP
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-authz-grpc-local
spec:
  hosts:
  - "external-authz-grpc.local" # The service name to be used in the extension provider in the mesh config.
  endpoints:
  - address: "127.0.0.1"
  ports:
  - name: grpc
    number: 9191 # The port number to be used in the extension provider in the mesh config.
    protocol: GRPC
  resolution: STATIC
ENDSNIP

snip_define_the_external_authorizer_1() {
kubectl edit configmap istio -n istio-system
}

! read -r -d '' snip_define_the_external_authorizer_2 <<\ENDSNIP
data:
  mesh: |-
    # Add the following content to define the external authorizers.
    extensionProviders:
    - name: "sample-ext-authz-grpc"
      envoyExtAuthzGrpc:
        service: "ext-authz.foo.svc.cluster.local"
        port: "9000"
    - name: "sample-ext-authz-http"
      envoyExtAuthzHttp:
        service: "ext-authz.foo.svc.cluster.local"
        port: "8000"
        includeRequestHeadersInCheck: ["x-ext-authz"]
ENDSNIP

! read -r -d '' snip_define_the_external_authorizer_3 <<\ENDSNIP
data:
  mesh: |-
    extensionProviders:
    - name: "oauth2-proxy"
      envoyExtAuthzHttp:
        service: "oauth2-proxy.foo.svc.cluster.local"
        port: "4180" # The default port used by oauth2-proxy.
        includeRequestHeadersInCheck: ["authorization", "cookie"] # headers sent to the oauth2-proxy in the check request.
        headersToUpstreamOnAllow: ["authorization", "path", "x-auth-request-user", "x-auth-request-email", "x-auth-request-access-token"] # headers sent to backend application when request is allowed.
        headersToDownstreamOnAllow: ["content-type", "set-cookie"] # headers sent back to the client when request is allowed.
        headersToDownstreamOnDeny: ["content-type", "set-cookie"] # headers sent back to the client when request is denied.
ENDSNIP

snip_enable_with_external_authorization_1() {
kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ext-authz
spec:
  selector:
    matchLabels:
      app: httpbin
  action: CUSTOM
  provider:
    # The provider name must match the extension provider defined in the mesh config.
    # You can also replace this with sample-ext-authz-http to test the other external authorizer definition.
    name: sample-ext-authz-grpc
  rules:
  # The rules specify when to trigger the external authorizer.
  - to:
    - operation:
        paths: ["/headers"]
EOF
}

snip_enable_with_external_authorization_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: deny" -s
}

! read -r -d '' snip_enable_with_external_authorization_2_out <<\ENDSNIP
denied by ext_authz for not found header `x-ext-authz: allow` in the request
ENDSNIP

snip_enable_with_external_authorization_3() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: allow" -s
}

! read -r -d '' snip_enable_with_external_authorization_3_out <<\ENDSNIP
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin:8000",
    "User-Agent": "curl/7.76.0-DEV",
    "X-B3-Parentspanid": "430f770aeb7ef215",
    "X-B3-Sampled": "0",
    "X-B3-Spanid": "60ff95c5acdf5288",
    "X-B3-Traceid": "fba72bb5765daf5a430f770aeb7ef215",
    "X-Envoy-Attempt-Count": "1",
    "X-Ext-Authz": "allow",
    "X-Ext-Authz-Check-Result": "allowed",
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=e5178ee79066bfbafb1d98044fcd0cf80db76be8714c7a4b630c7922df520bf2;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"
  }
}
ENDSNIP

snip_enable_with_external_authorization_4() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_enable_with_external_authorization_4_out <<\ENDSNIP
200
ENDSNIP

snip_enable_with_external_authorization_5() {
kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
}

! read -r -d '' snip_enable_with_external_authorization_5_out <<\ENDSNIP
2021/01/07 22:55:47 Starting HTTP server at [::]:8000
2021/01/07 22:55:47 Starting gRPC server at [::]:9000
2021/01/08 03:25:00 [gRPCv3][denied]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52088}}  principal:"spiffe://cluster.local/ns/foo/sa/sleep"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076306  nanos:473835000}  http:{id:"13869142855783664817"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"377ba0cdc2334270"}  headers:{key:"x-b3-traceid"  value:"635187cb20d92f62377ba0cdc2334270"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"deny"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"9609691a-4e9b-9545-ac71-3889bc2dffb0"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
2021/01/08 03:25:06 [gRPCv3][allowed]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52184}}  principal:"spiffe://cluster.local/ns/foo/sa/sleep"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076300  nanos:925912000}  http:{id:"17995949296433813435"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"a66b5470e922fa80"}  headers:{key:"x-b3-traceid"  value:"300c2f2b90a618c8a66b5470e922fa80"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"allow"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"2b62daf1-00b9-97d9-91b8-ba6194ef58a4"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
ENDSNIP

snip_clean_up_1() {
kubectl delete namespace foo
}
