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
#          docs/examples/microservices-istio/bookinfo-kubernetes/index.md
####################################################################################################

snip_deploy_the_application_and_a_testing_pod_1() {
export MYHOST=$(kubectl config view -o jsonpath={.contexts..namespace}).bookinfo.com
}

snip_deploy_the_application_and_a_testing_pod_2() {
kubectl apply -n "$NAMESPACE" -l version!=v2,version!=v3 -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml
}

! read -r -d '' snip_deploy_the_application_and_a_testing_pod_2_out <<\ENDSNIP
service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created
ENDSNIP

snip_deploy_the_application_and_a_testing_pod_3() {
kubectl get pods -n "$NAMESPACE"
}

! read -r -d '' snip_deploy_the_application_and_a_testing_pod_3_out <<\ENDSNIP
NAME                            READY   STATUS    RESTARTS   AGE
details-v1-6d86fd9949-q8rrf     1/1     Running   0          10s
productpage-v1-c9965499-tjdjx   1/1     Running   0          8s
ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          9s
reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          9s
ENDSNIP

snip_deploy_the_application_and_a_testing_pod_4() {
kubectl scale deployments --all --replicas 3 -n "$NAMESPACE"
}

! read -r -d '' snip_deploy_the_application_and_a_testing_pod_4_out <<\ENDSNIP
deployment.apps/details-v1 scaled
deployment.apps/productpage-v1 scaled
deployment.apps/ratings-v1 scaled
deployment.apps/reviews-v1 scaled
ENDSNIP

snip_deploy_the_application_and_a_testing_pod_5() {
kubectl get pods -n "$NAMESPACE"
}

! read -r -d '' snip_deploy_the_application_and_a_testing_pod_5_out <<\ENDSNIP
NAME                            READY   STATUS    RESTARTS   AGE
details-v1-6d86fd9949-fr59p     1/1     Running   0          50s
details-v1-6d86fd9949-mksv7     1/1     Running   0          50s
details-v1-6d86fd9949-q8rrf     1/1     Running   0          1m
productpage-v1-c9965499-hwhcn   1/1     Running   0          50s
productpage-v1-c9965499-nccwq   1/1     Running   0          50s
productpage-v1-c9965499-tjdjx   1/1     Running   0          1m
ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          50s
ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          50s
ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          1m
reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          49s
reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          1m
reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          49s
ENDSNIP

snip_deploy_the_application_and_a_testing_pod_6() {
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/sleep/sleep.yaml -n "$NAMESPACE"
}

snip_deploy_the_application_and_a_testing_pod_7() {
kubectl exec -n "$NAMESPACE" "$(kubectl get pod -n "$NAMESPACE" -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -c sleep -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip_deploy_the_application_and_a_testing_pod_7_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_enable_external_access_to_the_application_1() {
kubectl patch svc productpage -p '{"spec": {"type": "LoadBalancer"}}' -n "$NAMESPACE"
}

! read -r -d '' snip_enable_external_access_to_the_application_1_out <<\ENDSNIP
service/productpage patched
ENDSNIP

snip_configure_the_kubernetes_ingress_resource_and_access_your_applications_webpage_1() {
kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: bookinfo
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - host: $MYHOST
    http:
      paths:
      - path: /productpage
        backend:
          serviceName: productpage
          servicePort: 9080
      - path: /login
        backend:
          serviceName: productpage
          servicePort: 9080
      - path: /logout
        backend:
          serviceName: productpage
          servicePort: 9080
      - path: /static
        pathType: Prefix
        backend:
          serviceName: productpage
          servicePort: 9080
EOF
}

snip_update_your_etchosts_configuration_file_1() {
kubectl get ingress bookinfo -n "$NAMESPACE"
}

snip_update_your_etchosts_configuration_file_2() {
echo "$(kubectl get ingress istio-system -n istio-system -o jsonpath='{..ip} {..host}')" "$(kubectl get ingress -n "$NAMESPACE" bookinfo -o jsonpath='{..host}')"
}

snip_access_your_application_1() {
curl -s "$MYHOST"/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip_access_your_application_1_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_access_your_application_2() {
echo http://"$MYHOST"/productpage
}

! read -r -d '' snip_access_your_application_3 <<\ENDSNIP
private final static String ratings_service = "http://ratings:9080/ratings";
ENDSNIP

snip_access_your_application_4() {
while :; do curl -s "$MYHOST"/productpage | grep -o "<title>.*</title>"; sleep 1; done
}

! read -r -d '' snip_access_your_application_4_out <<\ENDSNIP
<title>Simple Bookstore App</title>
<title>Simple Bookstore App</title>
<title>Simple Bookstore App</title>
<title>Simple Bookstore App</title>
...
ENDSNIP
