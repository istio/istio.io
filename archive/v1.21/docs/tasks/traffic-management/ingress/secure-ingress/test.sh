#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155

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

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"

GATEWAY_API="${GATEWAY_API:-false}"

# @setup profile=default

kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

snip_generate_client_and_server_certificates_and_keys_1
snip_generate_client_and_server_certificates_and_keys_2
snip_generate_client_and_server_certificates_and_keys_3
snip_generate_client_and_server_certificates_and_keys_4
snip_generate_client_and_server_certificates_and_keys_5

# creating httpbin gateway secrets
snip_configure_a_tls_ingress_gateway_for_a_single_host_1

if [ "$GATEWAY_API" == "true" ]; then
    snip_configure_a_tls_ingress_gateway_for_a_single_host_4
    snip_configure_a_tls_ingress_gateway_for_a_single_host_5
    _wait_for_gateway istio-system mygateway
    snip_configure_a_tls_ingress_gateway_for_a_single_host_6
else
    # deploying httpbin gateway
    snip_configure_a_tls_ingress_gateway_for_a_single_host_2

    # deploying httpbin virtual service
    snip_configure_a_tls_ingress_gateway_for_a_single_host_3

    # wait for config to propagate
    _wait_for_istio gateway default mygateway
    _wait_for_istio virtualservice default httpbin

    # export the INGRESS_ environment variables
    _set_ingress_environment_variables
fi

# verifying httpbin deployment
_verify_elided snip_configure_a_tls_ingress_gateway_for_a_single_host_7 "$snip_configure_a_tls_ingress_gateway_for_a_single_host_7_out"

# deleting httpbin secret and re-creating
snip_configure_a_tls_ingress_gateway_for_a_single_host_8

# TODO: wait for the secret change to propagate

# verifying new httpbin credentials
_verify_elided snip_configure_a_tls_ingress_gateway_for_a_single_host_9 "$snip_configure_a_tls_ingress_gateway_for_a_single_host_9_out"

# verifying old httpbin credentials no longer work
_verify_failure snip_configure_a_tls_ingress_gateway_for_a_single_host_10

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_1

# start helloworld-v1 sample
snip_configure_a_tls_ingress_gateway_for_multiple_hosts_2

# waiting for helloworldv1 deployment to start
_wait_for_deployment default helloworld-v1

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_3

if [ "$GATEWAY_API" == "true" ]; then
    snip_configure_a_tls_ingress_gateway_for_multiple_hosts_6
    snip_configure_a_tls_ingress_gateway_for_multiple_hosts_7
else
    snip_configure_a_tls_ingress_gateway_for_multiple_hosts_4
    snip_configure_a_tls_ingress_gateway_for_multiple_hosts_5

    # waiting for configuration to propagate
    _wait_for_istio gateway default mygateway
    _wait_for_istio virtualservice default helloworld-v1
fi

_verify_elided snip_configure_a_tls_ingress_gateway_for_multiple_hosts_8 "$snip_configure_a_tls_ingress_gateway_for_multiple_hosts_8_out"

_verify_elided snip_configure_a_tls_ingress_gateway_for_multiple_hosts_9 "$snip_configure_a_tls_ingress_gateway_for_multiple_hosts_9_out"

snip_configure_a_mutual_tls_ingress_gateway_1

if [ "$GATEWAY_API" == "true" ]; then
    snip_configure_a_mutual_tls_ingress_gateway_3
else
    snip_configure_a_mutual_tls_ingress_gateway_2

    # wait for the change to propagate
    _wait_for_istio gateway default mygateway
fi

_verify_failure snip_configure_a_mutual_tls_ingress_gateway_4

_verify_elided snip_configure_a_mutual_tls_ingress_gateway_5 "$snip_configure_a_mutual_tls_ingress_gateway_5_out"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleanup_1
    snip_cleanup_3
    snip_cleanup_4
fi
