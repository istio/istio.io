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
#          docs/ops/integrations/spire/index.md
####################################################################################################

snip_install_spire_with_controller_manager() {
kubectl apply -f samples/security/spire/spire-quickstart.yaml
}

! read -r -d '' snip_spire_ca_integration_prerequisites_1 <<\ENDSNIP
socket_path = "/run/secrets/workload-spiffe-uds/socket"
ENDSNIP

snip_create_clusterspiffeid() {
kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: example
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  podSelector:
    matchLabels:
      spiffe.io/spire-managed-identity: "true"
EOF
}

snip_define_istio_operator_for_auto_registration() {
cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  profile: default
  meshConfig:
    trustDomain: example.org
  values:
    global:
    # This is used to customize the sidecar template
    sidecarInjectorWebhook:
      templates:
        spire: |
          spec:
            containers:
            - name: istio-proxy
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            volumes:
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        label:
          istio: ingressgateway
          spiffe.io/spire-managed-identity: "true"
        k8s:
          overlays:
            - apiVersion: apps/v1
              kind: Deployment
              name: istio-ingressgateway
              patches:
                - path: spec.template.spec.volumes.[name:workload-socket]
                  value:
                    name: workload-socket
                    csi:
                      driver: "csi.spiffe.io"
                      readOnly: true
                - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                  value:
                    name: workload-socket
                    mountPath: "/run/secrets/workload-spiffe-uds"
                    readOnly: true
                - path: spec.template.spec.initContainers
                  value:
                    - name: wait-for-spire-socket
                      image: busybox:1.28
                      volumeMounts:
                        - name: workload-socket
                          mountPath: /run/secrets/workload-spiffe-uds
                          readOnly: true
                      env:
                        - name: CHECK_FILE
                          value: /run/secrets/workload-spiffe-uds/socket
                      command:
                        - sh
                        - "-c"
                        - |-
                          echo "$(date -Iseconds)" Waiting for: ${CHECK_FILE}
                          while [[ ! -e ${CHECK_FILE} ]] ; do
                            echo "$(date -Iseconds)" File does not exist: ${CHECK_FILE}
                            sleep 15
                          done
                          ls -l ${CHECK_FILE}
EOF
}

snip_apply_istio_operator_configuration() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --skip-confirmation -f ./istio.yaml
}

snip_define_istio_operator_for_manual_registration() {
cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  profile: default
  meshConfig:
    trustDomain: example.org
  values:
    global:
    # This is used to customize the sidecar template
    sidecarInjectorWebhook:
      templates:
        spire: |
          spec:
            containers:
            - name: istio-proxy
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            volumes:
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        label:
          istio: ingressgateway
        k8s:
          overlays:
            - apiVersion: apps/v1
              kind: Deployment
              name: istio-ingressgateway
              patches:
                - path: spec.template.spec.volumes.[name:workload-socket]
                  value:
                    name: workload-socket
                    csi:
                      driver: "csi.spiffe.io"
                      readOnly: true
                - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                  value:
                    name: workload-socket
                    mountPath: "/run/secrets/workload-spiffe-uds"
                    readOnly: true
                - path: spec.template.spec.initContainers
                  value:
                    - name: wait-for-spire-socket
                      image: busybox:1.28
                      volumeMounts:
                        - name: workload-socket
                          mountPath: /run/secrets/workload-spiffe-uds
                          readOnly: true
                      env:
                        - name: CHECK_FILE
                          value: /run/secrets/workload-spiffe-uds/socket
                      command:
                        - sh
                        - "-c"
                        - |-
                          echo "$(date -Iseconds)" Waiting for: ${CHECK_FILE}
                          while [[ ! -e ${CHECK_FILE} ]] ; do
                            echo "$(date -Iseconds)" File does not exist: ${CHECK_FILE}
                            sleep 15
                          done
                          ls -l ${CHECK_FILE}
EOF
}

snip_apply_sleep() {
istioctl kube-inject --filename samples/security/spire/sleep-spire.yaml | kubectl apply -f -
}

snip_option_2_manual_registration_1() {
INGRESS_POD=$(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
INGRESS_POD_UID=$(kubectl get pods -n istio-system "$INGRESS_POD" -o jsonpath='{.metadata.uid}')
}

snip_set_spire_server_pod_name_var() {
SPIRE_SERVER_POD=$(kubectl get pod -l app=spire-server -n spire -o jsonpath="{.items[0].metadata.name}")
}

snip_option_2_manual_registration_3() {
kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
/opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s_psat:cluster:demo-cluster \
    -selector k8s_psat:agent_ns:spire \
    -selector k8s_psat:agent_sa:spire-agent \
    -node -socketPath /run/spire/sockets/server.sock
}

! read -r -d '' snip_option_2_manual_registration_3_out <<\ENDSNIP

Entry ID         : d38c88d0-7d7a-4957-933c-361a0a3b039c
SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
Parent ID        : spiffe://example.org/spire/server
Revision         : 0
TTL              : default
Selector         : k8s_psat:agent_ns:spire
Selector         : k8s_psat:agent_sa:spire-agent
Selector         : k8s_psat:cluster:demo-cluster
ENDSNIP

snip_option_2_manual_registration_4() {
kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
/opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:sa:istio-ingressgateway-service-account \
    -selector k8s:ns:istio-system \
    -selector k8s:pod-uid:"$INGRESS_POD_UID" \
    -dns "$INGRESS_POD" \
    -dns istio-ingressgateway.istio-system.svc \
    -socketPath /run/spire/sockets/server.sock
}

! read -r -d '' snip_option_2_manual_registration_4_out <<\ENDSNIP

Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:istio-system
Selector         : k8s:pod-uid:63c2bbf5-a8b1-4b1f-ad64-f62ad2a69807
Selector         : k8s:sa:istio-ingressgateway-service-account
DNS name         : istio-ingressgateway.istio-system.svc
DNS name         : istio-ingressgateway-5b45864fd4-lgrxs
ENDSNIP

snip_option_2_manual_registration_5() {
istioctl kube-inject --filename samples/security/spire/sleep-spire.yaml | kubectl apply -f -
}

snip_set_sleep_pod_vars() {
SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
SLEEP_POD_UID=$(kubectl get pods "$SLEEP_POD" -o jsonpath='{.metadata.uid}')
}

snip_option_2_manual_registration_8() {
kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
/opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/default/sa/sleep \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
    -selector k8s:pod-uid:"$SLEEP_POD_UID" \
    -dns "$SLEEP_POD" \
    -socketPath /run/spire/sockets/server.sock
}

snip_verifying_that_identities_were_created_for_workloads_1() {
kubectl exec -t "$SPIRE_SERVER_POD" -n spire -c spire-server -- ./bin/spire-server entry show
}

! read -r -d '' snip_verifying_that_identities_were_created_for_workloads_1_out <<\ENDSNIP
Found 2 entries
Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d

Entry ID         : af7b53dc-4cc9-40d3-aaeb-08abbddd8e54
SPIFFE ID        : spiffe://example.org/ns/default/sa/sleep
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:ee490447-e502-46bd-8532-5a746b0871d6
ENDSNIP

snip_get_sleep_svid() {
istioctl proxy-config secret "$SLEEP_POD" -o json | jq -r \
'.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
}

snip_get_svid_subject() {
openssl x509 -in chain.pem -text | grep SPIRE
}

! read -r -d '' snip_get_svid_subject_out <<\ENDSNIP
    Subject: C = US, O = SPIRE, CN = sleep-5f4d47c948-njvpk
ENDSNIP

snip_cleanup_spire_1() {
kubectl delete CustomResourceDefinition clusterspiffeids.spire.spiffe.io
kubectl delete CustomResourceDefinition clusterfederatedtrustdomains.spire.spiffe.io
kubectl delete -n spire configmap spire-bundle
kubectl delete -n spire serviceaccount spire-agent
kubectl delete -n spire configmap spire-agent
kubectl delete -n spire daemonset spire-agent
kubectl delete csidriver csi.spiffe.io
kubectl delete ValidatingWebhookConfiguration spire-controller-manager-webhook
kubectl delete -n spire configmap spire-controller-manager-config
kubectl delete -n spire configmap spire-server
kubectl delete -n spire service spire-controller-manager-webhook-service
kubectl delete -n spire service spire-server-bundle-endpoint
kubectl delete -n spire service spire-server
kubectl delete -n spire serviceaccount spire-server
kubectl delete -n spire deployment spire-server
kubectl delete clusterrole spire-server-cluster-role spire-agent-cluster-role manager-role
kubectl delete clusterrolebinding spire-server-cluster-role-binding spire-agent-cluster-role-binding manager-role-binding
kubectl delete -n spire role spire-server-role leader-election-role
kubectl delete -n spire rolebinding spire-server-role-binding leader-election-role-binding
kubectl delete namespace spire
rm istio.yaml chain.pem
}
