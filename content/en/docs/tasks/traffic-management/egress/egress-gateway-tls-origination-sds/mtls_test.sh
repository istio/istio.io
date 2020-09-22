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

# Enable access logging
# istioctl install --set profile=demo --set meshConfig.accessLogFile="/dev/stdout"
# _wait_for_deployment istio-system istiod
# TODO: above command is not needed, since access logging seems to be enabled by default.
# TODO: Also, running "istioctl install" causes the test to fail?????

# Make sure automatic sidecar injection is enabled
kubectl label namespace default istio-injection=enabled || true

# Deploy sleep sample
snip_before_you_begin_1
_wait_for_deployment default sleep

# Generate certificates
snip_generate_client_and_server_certificates_and_keys_1
snip_generate_client_and_server_certificates_and_keys_2
snip_generate_client_and_server_certificates_and_keys_3

# Create mesh-external namespace
snip_deploy_a_mutual_tls_server_1

# Generate secrets
snip_deploy_a_mutual_tls_server_2

# Create nginx conf and deploy server
snip_deploy_a_mutual_tls_server_3
snip_deploy_a_mutual_tls_server_4
snip_deploy_a_mutual_tls_server_5

_wait_for_deployment mesh-external my-nginx

# Create secret in istio-system
snip_configure_mutual_tls_origination_for_egress_traffic_using_sds_1

# Open Gateway Listener
snip_configure_mutual_tls_origination_for_egress_traffic_using_sds_2
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-nginx
# Configure route
snip_configure_mutual_tls_origination_for_egress_traffic_using_sds_3
_wait_for_istio virtualservice default direct-nginx-through-egress-gateway
# Originate TLS
snip_configure_mutual_tls_origination_for_egress_traffic_using_sds_4
_wait_for_istio destinationrule istio-system originate-mtls-for-nginx

# Verify GET request works
_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_using_sds_5 "Welcome to nginx!"

_verify_contains snip_configure_mutual_tls_origination_for_egress_traffic_using_sds_6 "GET / HTTP/1.1"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_the_mutual_tls_origination_example_1
snip_cleanup_the_mutual_tls_origination_example_2
snip_cleanup_the_mutual_tls_origination_example_3
snip_cleanup_1
