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

source "tests/util/samples.sh"

# @setup profile=none

# install Service API CRDs
snip_setup_1

# install Istio with PILOT_ENABLED_SERVICE_APIS flag enabled
istioctl install --set profile=minimal -y
_wait_for_deployment istio-system istiod

startup_httpbin_sample

# setup the Gateway and GatewayClass
snip_configuring_a_gateway_2

# setup the Ingress IP
snip_configuring_a_gateway_3

# send CURL traffic to http://$INGRESS_HOST/get (expected 200)
_verify_elided snip_configuring_a_gateway_4 "$snip_configuring_a_gateway_4_out"

# send CURL traffic to http://$INGRESS_HOST/get (expected 404)
_verify_elided snip_configuring_a_gateway_5 "$snip_configuring_a_gateway_5_out"


# @cleanup
cleanup_httpbin_sample
kubectl kustomize "github.com/kubernetes-sigs/service-apis/config/crd?ref=v0.4.0" | kubectl delete -f -
kubectl delete ns istio-system
kubectl delete ns istio-ingress
