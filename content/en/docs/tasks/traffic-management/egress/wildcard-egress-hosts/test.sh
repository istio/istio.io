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

source "tests/util/samples.sh"

cat > ./egressgateway.yaml <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: default
  meshConfig:
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
EOF
istioctl install -f ./egressgateway.yaml

kubectl label namespace default istio-injection=enabled --overwrite

startup_sleep_sample
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')

confirm_blocking() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -I https://www.google.com | grep  "HTTP/"; kubectl exec $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com | grep "HTTP/"
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

snip_setup_egress_gateway_with_sni_proxy_5

_verify_same snip_setup_egress_gateway_with_sni_proxy_6 "$snip_setup_egress_gateway_with_sni_proxy_6_out"

_verify_like snip_setup_egress_gateway_with_sni_proxy_7 "$snip_setup_egress_gateway_with_sni_proxy_7_out"
_wait_for_deployment istio-system istio-egressgateway-with-sni-proxy

snip_setup_egress_gateway_with_sni_proxy_8
_wait_for_istio serviceentry default sni-proxy
_wait_for_istio destinationrule default disable-mtls-for-sni-proxy

snip_configure_traffic_through_egress_gateway_with_sni_proxy_1
_wait_for_istio serviceentry default wikipedia

snip_configure_traffic_through_egress_gateway_with_sni_proxy_2
_wait_for_istio gateway default istio-egressgateway-with-sni-proxy
_wait_for_istio destinationrule default egressgateway-for-wikipedia
_wait_for_istio virtualservice default direct-wikipedia-through-egress-gateway
_wait_for_istio virtualservice default envoyfilter forward-downstream-sni
_wait_for_istio virtualservice default envoyfilter forward-downstream-sni

_verify_same snip_configure_traffic_through_egress_gateway_with_sni_proxy_3 "$snip_configure_traffic_through_egress_gateway_with_sni_proxy_3_out"

_verify_lines snip_configure_traffic_through_egress_gateway_with_sni_proxy_4 "
+ outbound|8443||sni-proxy.local
+ en.wikipedia.org
+ de.wikipedia.org
"

_verify_lines snip_configure_traffic_through_egress_gateway_with_sni_proxy_6 "
+ TCP [en.wikipedia.org]200
+ TCP [de.wikipedia.org]200
"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_direct_traffic_to_a_wildcard_host_1

snip_cleanup_wildcard_configuration_for_a_single_hosting_server_1

snip_cleanup_wildcard_configuration_for_arbitrary_domains_1
snip_cleanup_wildcard_configuration_for_arbitrary_domains_2
snip_cleanup_wildcard_configuration_for_arbitrary_domains_3

snip_cleanup_1

rm ./egressgateway.yaml
kubectl delete ns istio-system
kubectl label namespace default istio-injection- 
