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

# @setup profile=default

# Set retries to a higher value because config update is slow.
export VERIFY_TIMEOUT=300

export CLIENT_IP

snip_before_you_begin_1

_wait_for_deployment foo httpbin

if [ "$GATEWAY_API" == "true" ]; then
    snip_before_you_begin_4
    _verify_contains snip_before_you_begin_5 "rbac: debug"
    snip_before_you_begin_6
else
    snip_before_you_begin_2
    _verify_contains snip_before_you_begin_3 "rbac: debug"

    # Export the INGRESS_ environment variables
    _set_ingress_environment_variables
fi

_verify_same snip_before_you_begin_7 "$snip_before_you_begin_7_out"

if [ "$GATEWAY_API" == "true" ]; then
    snip_network_load_balancer_2
else
    snip_network_load_balancer_1
fi

# Test denied by default

if [ "$GATEWAY_API" == "true" ]; then
    snip_ipbased_allow_list_and_deny_list_3
    _wait_for_istio authorizationpolicy foo ingress-policy
else
    snip_ipbased_allow_list_and_deny_list_1
    _wait_for_istio authorizationpolicy istio-system ingress-policy
fi
_verify_same snip_ipbased_allow_list_and_deny_list_5 "$snip_ipbased_allow_list_and_deny_list_5_out"

if [ "$GATEWAY_API" == "true" ]; then
    snip_ipbased_allow_list_and_deny_list_4
    _wait_for_istio authorizationpolicy foo ingress-policy
else
    snip_ipbased_allow_list_and_deny_list_2
    _wait_for_istio authorizationpolicy istio-system ingress-policy
fi
_verify_same snip_ipbased_allow_list_and_deny_list_5 "$snip_ipbased_allow_list_and_deny_list_5_out"

# Test client IP allowed

if [ "$GATEWAY_API" == "true" ]; then
    _verify_like snip_ipbased_allow_list_and_deny_list_8 "$snip_ipbased_allow_list_and_deny_list_8_out"
    CLIENT_IP=$(kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_12
    _wait_for_istio authorizationpolicy foo ingress-policy
else
    _verify_like snip_ipbased_allow_list_and_deny_list_6 "$snip_ipbased_allow_list_and_deny_list_6_out"
    CLIENT_IP=$(kubectl get pods -n istio-system | grep ingress | awk '{print $1}' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_10
    _wait_for_istio authorizationpolicy istio-system ingress-policy
fi
_verify_same snip_ipbased_allow_list_and_deny_list_14 "$snip_ipbased_allow_list_and_deny_list_14_out"

if [ "$GATEWAY_API" == "true" ]; then
    _verify_like snip_ipbased_allow_list_and_deny_list_9 "$snip_ipbased_allow_list_and_deny_list_9_out"
    CLIENT_IP=$(kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_13
    _wait_for_istio authorizationpolicy foo ingress-policy
else
    _verify_like snip_ipbased_allow_list_and_deny_list_7 "$snip_ipbased_allow_list_and_deny_list_7_out"
    CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_11
    _wait_for_istio authorizationpolicy istio-system ingress-policy
fi
_verify_same snip_ipbased_allow_list_and_deny_list_14 "$snip_ipbased_allow_list_and_deny_list_14_out"

# Test client IP denied

if [ "$GATEWAY_API" == "true" ]; then
    CLIENT_IP=$(kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_17
    _wait_for_istio authorizationpolicy foo ingress-policy
else
    CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_15
    _wait_for_istio authorizationpolicy istio-system ingress-policy
fi
_verify_same snip_ipbased_allow_list_and_deny_list_19 "$snip_ipbased_allow_list_and_deny_list_19_out"

if [ "$GATEWAY_API" == "true" ]; then
    CLIENT_IP=$(kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_18
    _wait_for_istio authorizationpolicy foo ingress-policy
else
    CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
    snip_ipbased_allow_list_and_deny_list_16
    _wait_for_istio authorizationpolicy istio-system ingress-policy
fi
_verify_same snip_ipbased_allow_list_and_deny_list_19 "$snip_ipbased_allow_list_and_deny_list_19_out"

if [ "$GATEWAY_API" == "true" ]; then
    _verify_contains snip_ipbased_allow_list_and_deny_list_21 "remoteIP"
else
    _verify_contains snip_ipbased_allow_list_and_deny_list_20 "remoteIP"
fi

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_clean_up_1
    snip_clean_up_3
fi
