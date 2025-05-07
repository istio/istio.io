#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

# Copyright Istio Authors
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

# @setup profile=none

set -e
set -u
set -o pipefail

# install cert-manager
snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_1
snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_2

_verify_like snip_verify_secrets_are_created_for_each_cluster_issuer_1 "$snip_verify_secrets_are_created_for_each_cluster_issuer_1_out"

snip_export_root_certificates_for_each_cluster_issuer_1

snip_deploy_istio_with_default_certsigner_info_1
snip_deploy_istio_with_default_certsigner_info_2
snip_deploy_istio_with_default_certsigner_info_3
snip_deploy_istio_with_default_certsigner_info_4

# deploy test application
snip_deploy_istio_with_default_certsigner_info_5
_wait_for_deployment foo sleep
_wait_for_deployment foo httpbin
_wait_for_deployment bar httpbin


snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_1
_verify_contains snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_2 "Herman Melville - Moby-Dick"
_verify_contains snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_3 "upstream connect error"

# @cleanup

snip_cleanup_1

