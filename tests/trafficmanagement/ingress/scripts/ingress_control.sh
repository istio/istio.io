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

source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/ingress/ingress-control/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

# check for external load balancer
out=$(snip_determining_the_ingress_ip_and_ports_1 2>&1)
_verify_like "$out" "$snip_determining_the_ingress_ip_and_ports_1_out" "snip_determining_the_ingress_ip_and_ports_1"

# set INGRESS_HOST, INGRESS_PORT, and SECURE_INGRESS_PORT environment variables
if [[ "$out" != *"<none>"* && "$out" != *"<pending>"* ]]; then
    # external load balancer
    snip_determining_the_ingress_ip_and_ports_2
else
    # node port
    snip_determining_the_ingress_ip_and_ports_4
    snip_determining_the_ingress_ip_and_ports_9
fi

# create the gateway and routes
snip_configuring_ingress_using_an_istio_gateway_1
snip_configuring_ingress_using_an_istio_gateway_2

# wait for rules to propagate
sleep 5s # TODO: call proper wait utility (e.g., istioctl wait)

# access the httpbin service
out=$(snip_configuring_ingress_using_an_istio_gateway_3 2>&1)
#_verify_first_line "$out" "$snip_configuring_ingress_using_an_istio_gateway_3_out" "snip_configuring_ingress_using_an_istio_gateway_3"
_verify_contains "$out" "HTTP/1.1 200 OK" "snip_configuring_ingress_using_an_istio_gateway_3"

# access the httpbin service
out=$(snip_configuring_ingress_using_an_istio_gateway_4 2>&1)
#_verify_first_line "$out" "$snip_configuring_ingress_using_an_istio_gateway_4_out" "snip_configuring_ingress_using_an_istio_gateway_4"
_verify_contains "$out" "HTTP/1.1 404 Not Found" "snip_configuring_ingress_using_an_istio_gateway_3"

# configure for web browser
snip_accessing_ingress_services_using_a_browser_1

# wait for rules to propagate
sleep 5s # TODO: call proper wait utility (e.g., istioctl wait)

# access httpbin without host header
out=$(curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" 2>&1)
_verify_contains "$out" "HTTP/1.1 200 OK" "request_httpbin_without_host_header"
