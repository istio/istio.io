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

source "tests/util/verify.sh"

# Label istio-system ns and install Istio
# @setup profile=none
snip_install_istio_with_psa_1
snip_install_istio_with_psa_2
_wait_for_deployment istio-system istiod

# Label the sample application namespace
_verify_same snip_deploy_the_sample_application_1 "$snip_deploy_the_sample_application_1_out"

# Deploy the sample application
_verify_same snip_deploy_the_sample_application_2 "$snip_deploy_the_sample_application_2_out"

# Wait for pods to be ready
for deploy in "productpage-v1" "details-v1" "ratings-v1" "reviews-v1" "reviews-v2" "reviews-v3"; do
    _wait_for_deployment default "$deploy"
done

# Verify connectivity
_verify_like snip_deploy_the_sample_application_3 "$snip_deploy_the_sample_application_3_out"

# @cleanup
snip_uninstall_1
snip_uninstall_2
snip_uninstall_3
snip_uninstall_4
