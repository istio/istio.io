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

# create external ns
snip_deploy_an_https_proxy_1

# create proxy ns
snip_deploy_an_https_proxy_2
snip_deploy_an_https_proxy_3

# create squid deployment
snip_deploy_an_https_proxy_4
_wait_for_deployment external squid

# create sleep
snip_deploy_an_https_proxy_5
_wait_for_deployment external sleep
snip_deploy_an_https_proxy_6
snip_deploy_an_https_proxy_7

_verify_contains snip_deploy_an_https_proxy_8 "<title>Wikipedia, the free encyclopedia</title>"
_verify_contains snip_deploy_an_https_proxy_9 "CONNECT en.wikipedia.org:443"

# create service entry
snip_configure_traffic_to_external_https_proxy_1

_verify_contains snip_configure_traffic_to_external_https_proxy_2 "<title>Wikipedia, the free encyclopedia</title>"
_verify_contains snip_configure_traffic_to_external_https_proxy_3 "outbound|3128||my-company-proxy.com"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_1
snip_cleanup_2
snip_cleanup_3
snip_cleanup_4
snip_cleanup_5
