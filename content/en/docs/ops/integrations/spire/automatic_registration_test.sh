#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2154,SC2155,SC2164

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

set -e
set -u
set -o pipefail

# @setup profile=none

# Install SPIRE configured with k8s Controller Manager
snip_install_spire_crds
snip_install_spire_istio_overrides
_wait_for_daemonset spire-server spire-agent
_wait_for_statefulset spire-server spire-server

# Create ClusterSPIFFEID
snip_spire_csid_istio_gateway
snip_spire_csid_istio_sidecar

# Install Istio
set +u # Do not exit when value is unset. CHECK_FILE in the IstioOperator might be unset
snip_define_istio_operator_for_auto_registration
snip_apply_istio_operator_configuration
set -u # Exit on unset value
_wait_for_deployment istio-system istiod
_wait_for_deployment istio-system istio-ingressgateway

# Deploy sleep application with registration label
snip_apply_sleep
_wait_for_deployment default sleep

# Set spire-server pod variable
snip_set_spire_server_pod_name_var

# Set sleep pod and pod uid variables
snip_set_sleep_pod_var

# Verify sleep workload identity was issued by SPIRE
snip_get_sleep_svid
_verify_contains snip_get_svid_subject "O = SPIRE"

# @cleanup
#
kubectl delete -f samples/security/spire/sleep-spire.yaml
istioctl uninstall --purge --skip-confirmation
kubectl delete ns istio-system
snip_uninstall_spire
snip_uninstall_spire_crds
kubectl delete ns spire-server
