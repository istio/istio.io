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

snip_install_spire_crds() {
helm upgrade --install -n spire-server spire-crds spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ --create-namespace
}

snip_install_spire_istio_overrides() {
helm upgrade --install -n spire-server spire spire --repo https://spiffe.github.io/helm-charts-hardened/ --wait --set global.spire.trustDomain="example.org"
}

snip_spire_csid_istio_gateway() {
kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-ingressgateway-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  workloadSelectorTemplates:
    - "k8s:ns:istio-system"
    - "k8s:sa:istio-ingressgateway-service-account"
EOF
}

snip_spire_csid_istio_sidecar() {
kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-sidecar-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  podSelector:
    matchLabels:
      spiffe.io/spire-managed-identity: "true"
  workloadSelectorTemplates:
    - "k8s:ns:default"
EOF
}

snip_set_spire_server_pod_name_var() {
SPIRE_SERVER_POD=$(kubectl get pod -l statefulset.kubernetes.io/pod-name=spire-server-0 -n spire-server -o jsonpath="{.items[0].metadata.name}")
}

snip_option_2_manual_registration_2() {
kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
/opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:sa:istio-ingressgateway-service-account \
    -selector k8s:ns:istio-system \
    -socketPath /run/spire/sockets/server.sock
}

! IFS=$'\n' read -r -d '' snip_option_2_manual_registration_2_out <<\ENDSNIP

Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
Revision         : 0
TTL              : default
Selector         : k8s:ns:istio-system
Selector         : k8s:sa:istio-ingressgateway-service-account
ENDSNIP

snip_option_2_manual_registration_3() {
kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
/opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/default/sa/sleep \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
    -selector k8s:pod-label:spiffe.io/spire-managed-identity:true \
    -socketPath /run/spire/sockets/server.sock
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
    # This is used to customize the sidecar template.
    # It adds both the label to indicate that SPIRE should manage the
    # identity of this pod, as well as the CSI driver mounts.
    sidecarInjectorWebhook:
      templates:
        spire: |
          labels:
            spiffe.io/spire-managed-identity: "true"
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
            # This is used to customize the ingress gateway template.
            # It adds the CSI driver mounts, as well as an init container
            # to stall gateway startup until the CSI driver mounts the socket.
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
                      image: busybox:1.36
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

snip_apply_sleep() {
istioctl kube-inject --filename samples/security/spire/sleep-spire.yaml | kubectl apply -f -
}

snip_set_sleep_pod_var() {
SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
}

snip_get_sleep_svid() {
istioctl proxy-config secret "$SLEEP_POD" -o json | jq -r \
'.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
}

snip_get_svid_subject() {
openssl x509 -in chain.pem -text | grep SPIRE
}

! IFS=$'\n' read -r -d '' snip_get_svid_subject_out <<\ENDSNIP
    Subject: C = US, O = SPIRE, CN = sleep-5f4d47c948-njvpk
ENDSNIP

snip_uninstall_spire() {
helm delete -n spire-server spire
}

snip_uninstall_spire_crds() {
helm delete -n spire-server spire-crds
}
