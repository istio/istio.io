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

set -e
set -u
set -o pipefail

source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/ingress/secure-ingress/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

# export the INGRESS_ environment variables
_set_ingress_environment_variables

snip_generate_client_and_server_certificates_and_keys_1

snip_generate_client_and_server_certificates_and_keys_2

# creating httpbin gateway secrets
snip_configure_a_tls_ingress_gateway_for_a_single_host_1

# deploying httpbin gateway
snip_configure_a_tls_ingress_gateway_for_a_single_host_2

# deploying httpbin virtual service
snip_configure_a_tls_ingress_gateway_for_a_single_host_3

# waiting for httpbin deployment to start
_wait_for_deployment default httpbin

# verifying httpbin deployment
_run_and_verify_lines snip_configure_a_tls_ingress_gateway_for_a_single_host_4 "
+ HTTP/2 418
+ -=[ teapot ]=-
"

# deleting httpbin secret and re-creating
snip_configure_a_tls_ingress_gateway_for_a_single_host_5
snip_configure_a_tls_ingress_gateway_for_a_single_host_6

# wait for the change to propagate
sleep 5s

# verifying new httpbin credentials
_run_and_verify_lines snip_configure_a_tls_ingress_gateway_for_a_single_host_7 "
+ HTTP/2 418
+ -=[ teapot ]=-
"

# verifying old httpbin credentials no longer work
_run_and_verify_failure snip_configure_a_tls_ingress_gateway_for_a_single_host_8

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_1

# start helloworld-v1 sample
snip_configure_a_tls_ingress_gateway_for_multiple_hosts_2

# waiting for helloworldv1 deployment to start
_wait_for_deployment default helloworld-v1

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_3

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_4

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_5

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_6

# waiting for configuration to propagate
sleep 5s # TODO: call proper wait utility (e.g., istioctl wait)

_run_and_verify_contains snip_configure_a_tls_ingress_gateway_for_multiple_hosts_7 "$snip_configure_a_tls_ingress_gateway_for_multiple_hosts_7_out"

_run_and_verify_lines snip_configure_a_tls_ingress_gateway_for_multiple_hosts_8 "
+ HTTP/2 418
+ -=[ teapot ]=-
"

snip_configure_a_mutual_tls_ingress_gateway_1

snip_configure_a_mutual_tls_ingress_gateway_2

# wait for the change to propagate
sleep 5s

_run_and_verify_failure snip_configure_a_mutual_tls_ingress_gateway_3

snip_configure_a_mutual_tls_ingress_gateway_4

_run_and_verify_lines snip_configure_a_mutual_tls_ingress_gateway_5 "
+ HTTP/2 418
+ -=[ teapot ]=-
"
