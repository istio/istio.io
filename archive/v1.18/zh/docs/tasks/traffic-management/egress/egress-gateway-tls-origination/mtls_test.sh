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

# Make sure automatic sidecar injection is enabled
kubectl label namespace default istio-injection=enabled || true

# Deploy sleep sample
snip_before_you_begin_1
_wait_for_deployment default sleep

# Generate Certificates for service outside the mesh to use for mTLS
set +e # suppress harmless "No such file or directory:../crypto/bio/bss_file.c:72:fopen('1_root/index.txt.attr','r')" error
snip_generate_client_and_server_certificates_and_keys_1
snip_generate_client_and_server_certificates_and_keys_2
snip_generate_client_and_server_certificates_and_keys_3
set -e

# Create mesh-external namespace
snip_deploy_a_mutual_tls_server_1

# Setup sever with certs and config
snip_deploy_a_mutual_tls_server_2
snip_deploy_a_mutual_tls_server_3
snip_deploy_a_mutual_tls_server_4
snip_deploy_a_mutual_tls_server_5

# Wait for nginx
_wait_for_deployment mesh-external my-nginx

# Open Gateway Listener
snip_configure_mutual_tls_origination_for_egress_traffic_1
snip_configure_mutual_tls_origination_for_egress_traffic_2
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-nginx

# Configure routing from sleep to egress gateway to nginx
snip_configure_mutual_tls_origination_for_egress_traffic_3
_wait_for_istio virtualservice default direct-nginx-through-egress-gateway

# Originate TLS with destination rule
snip_configure_mutual_tls_origination_for_egress_traffic_4

_wait_for_istio destinationrule istio-system originate-mtls-for-nginx

_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_5 "kubernetes://client-credential            Cert Chain     ACTIVE"

# Verify that mTLS connection is set up properly
_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_6 "Welcome to nginx!"

# Verify request is routed through Gateway
_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_7 "GET / HTTP/1.1"

# @cleanup
kubectl label namespace default istio-injection-
snip_cleanup_the_mutual_tls_origination_example_1
snip_cleanup_the_mutual_tls_origination_example_2
snip_cleanup_the_mutual_tls_origination_example_3
snip_cleanup_1
