#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

# Copyright 2020 Istio Authors
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

source "tests/util/samples.sh"

# set feature flag and create test namespace
echo y | snip_before_you_begin_1
_wait_for_deployment istio-system istiod
snip_before_you_begin_2

# setup peer authentication
snip_enable_global_mtls_1
snip_disable_peerauthentication_for_the_externally_exposed_httpbin_port_1

# generate client and server certs/keys
snip_generate_ca_cert_server_certkey_and_client_certkey_1
snip_create_k8s_secrets_for_the_certificates_and_keys_1

# deploy httpbin service with sidecar configuration
snip_deploy_the_httpbin_test_service_2
snip_configure_httpbin_to_enable_external_mtls_1

_wait_for_deployment test httpbin

# deploy test applications
snip_verification_1
_wait_for_deployment test sleep
_wait_for_deployment default sleep

# verification
_verify_first_line snip_verify_internal_mesh_connectivity_on_port_8080_1 "HTTP/1.1 200 OK"
snip_verify_external_to_internal_mesh_connectivity_on_port_8443_1
_verify_first_line snip_verify_external_to_internal_mesh_connectivity_on_port_8443_2 "HTTP/2 200"

# @cleanup
snip_cleanup_the_mutual_tls_termination_example_1
snip_cleanup_the_mutual_tls_termination_example_2
echo y | snip_cleanup_the_mutual_tls_termination_example_3
kubectl delete ns istio-system
