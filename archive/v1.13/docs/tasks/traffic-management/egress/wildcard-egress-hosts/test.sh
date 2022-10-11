#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155

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

echo y | snip_before_you_begin_1
_wait_for_deployment istio-system istiod

kubectl label namespace default istio-injection=enabled --overwrite

snip_before_you_begin_2
_wait_for_deployment default sleep
snip_before_you_begin_4

confirm_blocking() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -I https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -I https://edition.cnn.com | grep "HTTP/"
}
_verify_contains confirm_blocking "command terminated with exit code 35"

snip_configure_direct_traffic_to_a_wildcard_host_1
_wait_for_istio serviceentry default wikipedia

_verify_same snip_configure_direct_traffic_to_a_wildcard_host_2 "$snip_configure_direct_traffic_to_a_wildcard_host_2_out"

snip_cleanup_direct_traffic_to_a_wildcard_host_1

snip_wildcard_configuration_for_a_single_hosting_server_1
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-wikipedia
_wait_for_istio virtualservice default direct-wikipedia-through-egress-gateway

snip_wildcard_configuration_for_a_single_hosting_server_2
_wait_for_istio serviceentry default www-wikipedia

_verify_same snip_wildcard_configuration_for_a_single_hosting_server_3 "$snip_wildcard_configuration_for_a_single_hosting_server_3_out"

_verify_contains snip_wildcard_configuration_for_a_single_hosting_server_4 "outbound|443||www.wikipedia.org"

snip_cleanup_wildcard_configuration_for_a_single_hosting_server_1

snip_setup_egress_gateway_with_sni_proxy_1

snip_setup_egress_gateway_with_sni_proxy_2

snip_setup_egress_gateway_with_sni_proxy_3

snip_setup_egress_gateway_with_sni_proxy_4
_wait_for_deployment istio-system istio-egressgateway-with-sni-proxy

_verify_like snip_setup_egress_gateway_with_sni_proxy_5 "$snip_setup_egress_gateway_with_sni_proxy_5_out"

snip_setup_egress_gateway_with_sni_proxy_6
_wait_for_istio serviceentry default sni-proxy
_wait_for_istio destinationrule default disable-mtls-for-sni-proxy

snip_configure_traffic_through_egress_gateway_with_sni_proxy_1
_wait_for_istio serviceentry default wikipedia

snip_configure_traffic_through_egress_gateway_with_sni_proxy_2
_wait_for_istio gateway default istio-egressgateway-with-sni-proxy
_wait_for_istio destinationrule default egressgateway-for-wikipedia
_wait_for_istio virtualservice default direct-wikipedia-through-egress-gateway
_wait_for_istio envoyfilter default forward-downstream-sni

snip_configure_traffic_through_egress_gateway_with_sni_proxy_3
_wait_for_istio envoyfilter istio-system egress-gateway-sni-verifier

_verify_same snip_configure_traffic_through_egress_gateway_with_sni_proxy_4 "$snip_configure_traffic_through_egress_gateway_with_sni_proxy_4_out"

_verify_lines snip_configure_traffic_through_egress_gateway_with_sni_proxy_5 "
+ outbound|18443||sni-proxy.local
+ en.wikipedia.org
+ de.wikipedia.org
"

_verify_lines snip_configure_traffic_through_egress_gateway_with_sni_proxy_7 "
+ TCP [en.wikipedia.org]200
+ TCP [de.wikipedia.org]200
"

# @cleanup
snip_cleanup_direct_traffic_to_a_wildcard_host_1

snip_cleanup_wildcard_configuration_for_a_single_hosting_server_1

snip_cleanup_wildcard_configuration_for_arbitrary_domains_1
snip_cleanup_wildcard_configuration_for_arbitrary_domains_2
snip_cleanup_wildcard_configuration_for_arbitrary_domains_3

snip_cleanup_1
echo y | snip_cleanup_2

kubectl delete ns istio-system
kubectl label namespace default istio-injection-
