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
#          docs/setup/install/istioctl/index.md
####################################################################################################

snip_install_istio_using_the_default_profile_1() {
istioctl install
}

snip_install_istio_using_the_default_profile_2() {
istioctl install --set meshConfig.accessLogFile=/dev/stdout
}

! read -r -d '' snip_install_istio_using_the_default_profile_3 <<\ENDSNIP
# my-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
ENDSNIP

snip_install_istio_using_the_default_profile_4() {
istioctl install -f my-config.yaml
}

snip_install_from_external_charts_1() {
istioctl install --manifests=manifests/
}

snip_install_a_different_profile_1() {
istioctl install --set profile=demo
}

snip_check_whats_installed_1() {
kubectl -n istio-system get deploy
}

! read -r -d '' snip_check_whats_installed_1_out <<\ENDSNIP
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
istio-ingressgateway   1/1     1            1           49m
istiod                 1/1     1            1           49m
ENDSNIP

snip_check_whats_installed_2() {
kubectl -n istio-system get IstioOperator installed-state -o yaml > installed-state.yaml
}

snip_display_the_list_of_available_profiles_1() {
istioctl profile list
}

! read -r -d '' snip_display_the_list_of_available_profiles_1_out <<\ENDSNIP
Istio configuration profiles:
    default
    demo
    empty
    minimal
    openshift
    preview
    remote
ENDSNIP

snip_display_the_configuration_of_a_profile_1() {
istioctl profile dump demo
}

! read -r -d '' snip_display_the_configuration_of_a_profile_1_out <<\ENDSNIP
components:
  egressGateways:
  - enabled: true
    k8s:
      resources:
        requests:
          cpu: 10m
          memory: 40Mi
    name: istio-egressgateway

...
ENDSNIP

snip_display_the_configuration_of_a_profile_2() {
istioctl profile dump --config-path components.pilot demo
}

! read -r -d '' snip_display_the_configuration_of_a_profile_2_out <<\ENDSNIP
enabled: true
k8s:
  env:
  - name: PILOT_TRACE_SAMPLING
    value: "100"
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 1
    periodSeconds: 3
    timeoutSeconds: 5
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
  strategy:
    rollingUpdate:
      maxSurge: 100%
      maxUnavailable: 25%
ENDSNIP

snip_show_differences_in_profiles_1() {
istioctl profile diff default demo
}

! read -r -d '' snip_show_differences_in_profiles_1_out <<\ENDSNIP
 gateways:
   egressGateways:
-  - enabled: false
+  - enabled: true
...
     k8s:
        requests:
-          cpu: 100m
-          memory: 128Mi
+          cpu: 10m
+          memory: 40Mi
       strategy:
...
ENDSNIP

snip_generate_a_manifest_before_installation_1() {
istioctl manifest generate > $HOME/generated-manifest.yaml
}

snip_show_differences_in_manifests_1() {
istioctl manifest generate > 1.yaml
istioctl manifest generate -f operator/samples/pilot-k8s.yaml > 2.yaml
istioctl manifest diff 1.yaml 2.yaml
}

! read -r -d '' snip_show_differences_in_manifests_1_out <<\ENDSNIP
Differences of manifests are:

Object Deployment:istio-system:istio-pilot has diffs:

spec:
  template:
    spec:
      containers:
        '[0]':
          resources:
            requests:
              cpu: 500m -> 1000m
              memory: 2048Mi -> 4096Mi
      nodeSelector: -> map[master:true]
      tolerations: -> [map[effect:NoSchedule key:dedicated operator:Exists] map[key:CriticalAddonsOnly
        operator:Exists]]


Object HorizontalPodAutoscaler:istio-system:istio-pilot has diffs:

spec:
  maxReplicas: 5 -> 10
  minReplicas: 1 -> 2
ENDSNIP

snip_verify_a_successful_installation_1() {
istioctl manifest generate <your original installation options> > $HOME/generated-manifest.yaml
}

snip_verify_a_successful_installation_2() {
istioctl verify-install -f $HOME/generated-manifest.yaml
}

snip_customizing_the_configuration_1() {
istioctl install --set values.global.logging.level=debug
}

snip_customizing_the_configuration_2() {
istioctl install -f operator/samples/pilot-k8s.yaml
}

snip_customizing_the_configuration_3() {
istioctl install --set values.pilot.traceSampling=0.1
}

! read -r -d '' snip_identify_an_istio_component_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      enabled: false
ENDSNIP

! read -r -d '' snip_customize_kubernetes_settings_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      k8s:
        resources:
          requests:
            cpu: 1000m # override from default 500m
            memory: 4096Mi # ... default 2048Mi
        hpaSpec:
          maxReplicas: 10 # ... default 5
          minReplicas: 2  # ... default 1
        nodeSelector:
          master: "true"
        tolerations:
        - key: dedicated
          operator: Exists
          effect: NoSchedule
        - key: CriticalAddonsOnly
          operator: Exists
ENDSNIP

snip_customize_kubernetes_settings_2() {
istioctl install -f samples/operator/pilot-k8s.yaml
}

! read -r -d '' snip_customize_istio_settings_using_the_helm_api_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      traceSampling: 0.1 # override from 1.0
    global:
      monitoringPort: 15050
ENDSNIP

snip_configure_gateways_1() {
istioctl profile dump --config-path components.ingressGateways
istioctl profile dump --config-path values.gateways.istio-ingressgateway
}

! read -r -d '' snip_configure_gateways_2 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
      - namespace: user-ingressgateway-ns
        name: ilb-gateway
        enabled: true
        k8s:
          resources:
            requests:
              cpu: 200m
          serviceAnnotations:
            cloud.google.com/load-balancer-type: "internal"
          service:
            ports:
            - port: 8060
              targetPort: 8060
              name: tcp-citadel-grpc-tls
            - port: 5353
              name: tcp-dns
ENDSNIP

! read -r -d '' snip_configure_gateways_3 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  components:
    ingressGateways:
      - name: ilb-gateway
        namespace: user-ingressgateway-ns
        enabled: true
        # Copy settings from istio-ingressgateway as needed.
  values:
    gateways:
      istio-ingressgateway:
        debug: error
ENDSNIP

snip_customizing_external_charts_and_profiles_1() {
istioctl manifest generate --manifests mycharts/ --set profile=custom1 -f path-to-user-overlay.yaml
}

snip_customizing_external_charts_and_profiles_2() {
istioctl manifest generate --manifests mycharts/ -f manifests/profiles/custom1.yaml -f path-to-user-overlay.yaml
}

! read -r -d '' snip_patching_the_output_manifest_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  hub: docker.io/istio
  tag: 1.1.6
  components:
    pilot:
      enabled: true
      namespace: istio-control
      k8s:
        overlays:
          - kind: Deployment
            name: istiod
            patches:
              # Select list item by value
              - path: spec.template.spec.containers.[name:discovery].args.[30m]
                value: "60m" # overridden from 30m
              # Select list item by key:value
              - path: spec.template.spec.containers.[name:discovery].ports.[containerPort:8080].containerPort
                value: 1234
              # Override with object (note | on value: first line)
              - path: spec.template.spec.containers.[name:discovery].env.[name:POD_NAMESPACE].valueFrom
                value: |
                  fieldRef:
                    apiVersion: v2
                    fieldPath: metadata.myPath
              # Deletion of list item
              - path: spec.template.spec.containers.[name:discovery].env.[name:REVISION]
              # Deletion of map item
              - path: spec.template.spec.containers.[name:discovery].securityContext
          - kind: Service
            name: istiod
            patches:
              - path: spec.ports.[name:https-dns].port
                value: 11111 # OVERRIDDEN
ENDSNIP

! read -r -d '' snip_patching_the_output_manifest_2 <<\ENDSNIP
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
spec:
  template:
    spec:
      containers:
      - args:
        - 60m
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v2
              fieldPath: metadata.myPath
        name: discovery
        ports:
        - containerPort: 1234
---
apiVersion: v1
kind: Service
metadata:
  name: istiod
spec:
  ports:
  - name: https-dns
    port: 11111
---
ENDSNIP

snip_uninstall_istio_1() {
istioctl x uninstall --purge
}

snip_uninstall_istio_2() {
istioctl x uninstall <your original installation options>
}

snip_uninstall_istio_3() {
istioctl manifest generate <your original installation options> | kubectl delete -f -
}

snip_uninstall_istio_4() {
kubectl delete namespace istio-system
}
