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

source "tests/util/gateway-api.sh"
install_gateway_api_crds

set -e
set -u
set -o pipefail

# Download Istio
# Skipping this as we use the istioctl built from istio/istio reference

# Install Istio
# @setup profile=none
snip_install_istio_1
_wait_for_deployment istio-system istiod

# Label the namespace
# remove the injection label to prevent the following command from failing
kubectl label namespace default istio-injection-
_verify_same snip_install_istio_2 "$snip_install_istio_2_out"

# Deploy the sample Application
snip_deploy_the_sample_application_1

# Check the services
_verify_like snip_deploy_the_sample_application_2 "$snip_deploy_the_sample_application_2_out"

# Wait for pods to be ready
for deploy in "productpage-v1" "details-v1" "ratings-v1" "reviews-v1" "reviews-v2" "reviews-v3"; do
    _wait_for_deployment default "$deploy"
done

# Check the pods
_verify_like snip_deploy_the_sample_application_3 "$snip_deploy_the_sample_application_3_out"

# Verify connectivity
_verify_like snip_deploy_the_sample_application_4 "$snip_deploy_the_sample_application_4_out"

# Open to outside traffic
_verify_contains snip_deploy_bookinfo_gateway "$snip_deploy_bookinfo_gateway_out"
_wait_for_gateway default bookinfo-gateway
snip_annotate_bookinfo_gateway

# Ensure no issues with configuration
_verify_like snip_open_the_application_to_outside_traffic_3 "$snip_open_the_application_to_outside_traffic_3_out"

# verify Kiali deployment
_verify_contains snip_view_the_dashboard_1 'deployment "kiali" successfully rolled out'

# Verify Kiali dashboard
# TODO Verify the browser output

# @cleanup
samples/bookinfo/platform/kube/cleanup.sh
snip_uninstall_1
snip_uninstall_2
snip_uninstall_3

remove_gateway_api_crds
