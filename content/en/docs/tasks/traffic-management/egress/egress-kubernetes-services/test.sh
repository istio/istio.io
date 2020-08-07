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

# @setup profile=demo

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"

# Deploy sleep sample and set up variable pointing to it
# Start the sleep sample
startup_sleep_sample
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')

# create namespace without istio
snip__1

# deploy sleep in without-istio namespace
snip__2
_wait_for_deployment without-istio sleep
snip__3

# Create secret
snip_kubernetes_externalname_service_to_access_an_external_service_1

_verify_contains snip_kubernetes_externalname_service_to_access_an_external_service_3 "\"Host\": \"my-httpbin.default.svc.cluster.local"

# apply dr
snip_kubernetes_externalname_service_to_access_an_external_service_4
_wait_for_istio destinationrule default my-httpbin

_verify_contains snip_kubernetes_externalname_service_to_access_an_external_service_5 "\"X-Envoy-Decorator-Operation\": \"my-httpbin.default.svc.cluster.local:80/*\""

# service wikipedia
snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_1
snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_2

_verify_contains snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_4 "<title>Wikipedia, the free encyclopedia</title>"

# apply dr
snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_5
_wait_for_istio destinationrule default my-wikipedia

_verify_contains snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_6 "<title>Wikipedia, the free encyclopedia</title>"

_verify_contains snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_7 "Connected to en.wikipedia.org"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_of_kubernetes_externalname_service_1
snip_cleanup_of_kubernetes_service_with_endpoints_1
snip_cleanup_1
snip_cleanup_2
snip_cleanup_3
snip_cleanup_4
