#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155

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

# @setup profile=demo

kubectl label namespace default istio-injection=enabled --overwrite

snip_global_rate_limit_1
snip_global_rate_limit_2

kubectl wait --for condition=available --timeout=90s deploy redis
kubectl wait --for condition=available --timeout=90s deploy ratelimit

# Install Bookinfo sample
startup_bookinfo_sample  # from tests/util/samples.sh

# export the INGRESS_ environment variables
_set_ingress_environment_variables
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo "*** GATEWAY_URL = $GATEWAY_URL ***"

# apply global ratelimit envoyfilter
snip_global_rate_limit_3
snip_global_rate_limit_4

# name route
snip_global_rate_limit_advanced_case_1
# apply global ratelimit advanced case envoyfilter
snip_global_rate_limit_advanced_case_2

# verify global ratelimit
_verify_same snip_verify_global_rate_limit_1 "$snip_verify_global_rate_limit_1_out"

# verify global ratelimit advanced case
_verify_same snip_verify_global_rate_limit_2 "$snip_verify_global_rate_limit_2_out"

# apply local ratelimit envoyfilter
snip_local_rate_limit_2

# verify local ratelimit
_verify_same snip_verify_local_rate_limit_1 "$snip_verify_local_rate_limit_1_out"

# @cleanup
snip_cleanup_1
cleanup_bookinfo_sample