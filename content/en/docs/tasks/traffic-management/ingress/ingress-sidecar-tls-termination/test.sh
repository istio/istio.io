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

# @setup profile=demo

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"

# set feature flag and create test namespace
snip_before_you_begin_1
snip_before_you_begin_2

# setup peer authentication
snip_enable_global_mtls_1
snip_disable_peerauthentication_for_external_mtls_port_1

# generate client and server certs/keys
snip_generate_ca_cert_server_certkey_and_client_certkey_1
snip_generate_k8s_secret_for_the_certificates_and_keys_1

# deploy httpbin service with sidecar configuration
snip_create_httpbin_deployment_and_services_2
snip_create_sidecar_configuration_for_httpbin_to_enable_external_mtls_on_ingress_1

_wait_for_deployment test httpbin

# deploy test applications
snip_verification_1
_wait_for_deployment test sleep
_wait_for_deployment default sleep

# verification
_verify_contains snip_verify_internal_mesh_connectivity_on_port_8080_1 "200 OK"

snip_verify_external_to_internal_mesh_connectivity_on_port_8443_1
_verify_contains snip_verify_external_to_internal_mesh_connectivity_on_port_8443_2 "HTTP/2 200"

_verify_contains snip_verify_external_to_internal_mesh_connectivity_on_port_8443_3 "Connection reset by peer"

# cleanup the resources
snip_cleanup_the_mutual_tls_termination_example_1
snip_cleanup_the_mutual_tls_termination_example_2