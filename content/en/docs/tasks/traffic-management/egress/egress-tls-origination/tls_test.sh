#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

set -e
set -u
set -o pipefail

GATEWAY_API="${GATEWAY_API:-false}"

source "tests/util/samples.sh"

# @setup profile=default

# Make sure default namespace is injected
kubectl label namespace default istio-injection=enabled || true

# Deploy sample and set up variable pointing to it
startup_curl_sample
snip_before_you_begin_3

# Confirm we can access plain HTTP
snip_apply_simple

_wait_for_resource serviceentry default edition-cnn-com

_verify_elided snip_curl_simple "$snip_curl_simple_out"

# Apply TLS origination config, check http and https content is correct
snip_apply_origination_serviceentry
_wait_for_resource serviceentry default edition-cnn-com

if [ "$GATEWAY_API" == "true" ]; then
    snip_apply_origination_backendtlspolicy
    _wait_for_resource backendtlspolicy default edition-cnn-com
else
    snip_apply_origination_destinationrule
    _wait_for_resource destinationrule default edition-cnn-com
fi

_verify_elided snip_curl_origination_http "$snip_curl_origination_http_out"
_verify_elided snip_curl_origination_https "$snip_curl_origination_https_out"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleanup_the_tls_origination_configuration_1
else
    snip_cleanup_the_tls_origination_configuration_2
fi

cleanup_curl_sample
kubectl label namespace default istio-injection-
