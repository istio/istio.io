#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

# Copyright 2022 Istio Authors
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

source "content/en/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/snips.sh"
source "tests/util/samples.sh"

# Make sure automatic sidecar injection is enabled
kubectl label namespace default istio-injection=enabled || true

# Deploy sleep sample
# Deploy sample and set up variable pointing to it
startup_sleep_sample
snip_before_you_begin_3

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

# Configure sleep pod
snip_configure_the_client_sleep_pod_1
snip_configure_the_client_sleep_pod_2

# Configure mTLS for egress traffic from sidecar to external service
snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_1

_wait_for_istio destinationrule default originate-mtls-for-nginx

_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_2 "kubernetes://client-credential            Cert Chain     ACTIVE"

# Verify that mTLS connection is set up properly
_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_3 "Welcome to nginx!"

# Verify request is hitting the sidecar
_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_at_sidecar_4 "GET / HTTP/1.1"

# @cleanup
kubectl label namespace default istio-injection-
snip_cleanup_the_mutual_tls_origination_configuration_1
snip_cleanup_the_mutual_tls_origination_configuration_2
snip_cleanup_the_mutual_tls_origination_configuration_3
cleanup_sleep_sample
