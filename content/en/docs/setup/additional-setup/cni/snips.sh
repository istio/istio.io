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
#          docs/setup/additional-setup/cni/index.md
####################################################################################################

snip_cni_agent_operator_install() {
cat <<EOF > istio-cni.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      namespace: istio-system
      enabled: true
EOF
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -f istio-cni.yaml -y
}

snip_cni_agent_helm_install() {
helm install istio-cni istio/cni -n istio-system --wait
}

snip_cni_agent_helm_istiod_install() {
helm install istiod istio/istiod -n istio-system --set pilot.cni.enabled=true --wait
}

! IFS=$'\n' read -r -d '' snip_handling_init_container_injection_for_revisions_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  revision: REVISION_NAME
  ...
  values:
    pilot:
      cni:
        enabled: true
  ...
ENDSNIP

! IFS=$'\n' read -r -d '' snip_upgrading_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty # Do not include other components
  components:
    cni:
      enabled: true
  values:
    cni:
      excludeNamespaces:
        - istio-system
ENDSNIP

snip_cni_agent_helm_upgrade() {
helm upgrade istio-cni istio/cni -n istio-system --wait
}
