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

GATEWAY_API="${GATEWAY_API:-false}"

# ingressgateway is necessary, but we need to do a custom install
# @setup profile=none

echo '*** install Istio with numTrustedProxies set to 2 ***'
echo y | snip_install_num_trusted_proxies_two

_wait_for_deployment istio-system istiod
_wait_for_deployment istio-system istio-ingressgateway

echo '*** apply httpbin ***'
snip_create_httpbin_namespace
snip_label_httpbin_namespace
snip_apply_httpbin
_wait_for_deployment httpbin httpbin

echo '*** apply httpbin gateway ***'
if [ "$GATEWAY_API" == "true" ]; then
    snip_deploy_httpbin_k8s_gateway
    snip_export_k8s_gateway_url
else
    snip_deploy_httpbin_gateway

    # wait for for the rules to propagate
    _wait_for_istio gateway httpbin httpbin-gateway
    _wait_for_istio virtualservice httpbin httpbin

    snip_export_gateway_url
fi
echo "*** GATEWAY_URL = $GATEWAY_URL ***"

_verify_like snip_curl_xff_headers "$snip_curl_xff_headers_out"

# @cleanup
kubectl delete -f samples/httpbin/httpbin-gateway.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
kubectl delete ns httpbin

# Delete the Istio this test installed
echo y | istioctl uninstall --revision "default"
kubectl delete ns istio-system
