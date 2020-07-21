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

# Deploy sleep sample and set up variable pointing to it
set +e
kubectl delete pods -l app=sleep --force
set -e
snip_before_you_begin_1
_wait_for_deployment default sleep

# Generate certificates
snip_generate_ca_and_server_certificates_and_keys_1
snip_generate_ca_and_server_certificates_and_keys_2

# Create mesh-external namespace
snip_create_secrets_for_the_client_and_server_1

# Generate secrets
snip_create_secrets_for_the_client_and_server_2
snip_create_secrets_for_the_client_and_server_3

# Create nginx conf and deploy server
snip_deploy_a_simple_tls_server_1
snip_deploy_a_simple_tls_server_2
snip_deploy_a_simple_tls_server_3

_wait_for_deployment mesh-external my-nginx

# Create secret in istio-system
snip_deploy_a_simple_tls_server_6

# Open Gateway Listener
snip_configure_simple_tls_origination_for_egress_traffic_1
# Configure route
snip_configure_simple_tls_origination_for_egress_traffic_2
# Originate TLS
snip_configure_simple_tls_origination_for_egress_traffic_3

# Verify GET request works
_verify_contains snip_configure_simple_tls_origination_for_egress_traffic_4 "Welcome to nginx!"

_verify_contains snip_configure_simple_tls_origination_for_egress_traffic_5 "GET / HTTP/1.1"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_the_tls_origination_example_1
snip_cleanup_the_tls_origination_example_2
snip_cleanup_the_tls_origination_example_3
