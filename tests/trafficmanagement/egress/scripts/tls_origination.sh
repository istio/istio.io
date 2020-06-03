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

source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/egress/egress-tls-origination/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

# Deploy sample and set up variable pointing to it
startup_sleep_sample
snip_before_you_begin_3

# Confirm we can access plain HTTP
snip_apply_simple
_verify_elided snip_curl_simple "$snip_curl_simple_out"

# Apply TLS origination config, check http and https content is correct
snip_apply_origination
_verify_elided snip_curl_origination_http "$snip_curl_origination_http_out"
_verify_elided snip_curl_origination_https "$snip_curl_origination_https_out"
