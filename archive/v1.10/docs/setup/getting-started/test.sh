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

# Download Istio
# Skipping this as we use the istioctl built from istio/istio reference

# Install Istio
# @setup profile=none
snip_install_istio_install_1
_wait_for_deployment istio-system istiod

# Label the namespace
# remove the injection label to prevent the following command from failing
kubectl label namespace default istio-injection-
snip_install_istio_install_2

# TODO: how to make sure previous tests cleaned up everything?
# Cleanup sleep
cleanup_sleep_sample

# Deploy the sample Application
snip_deploy_the_sample_application_bookinfo_1

# Check the services
_verify_like snip_deploy_the_sample_application_bookinfo_2 "$snip_deploy_the_sample_application_bookinfo_2_out"

# Wait for pods to be ready
for deploy in "productpage-v1" "details-v1" "ratings-v1" "reviews-v1" "reviews-v2" "reviews-v3"; do
    _wait_for_deployment default "$deploy"
done

# Check the pods
_verify_like snip_deploy_the_sample_application_bookinfo_3 "$snip_deploy_the_sample_application_bookinfo_3_out"

# Verify connectivity
_verify_like snip_deploy_the_sample_application_bookinfo_4 "$snip_deploy_the_sample_application_bookinfo_4_out"

# Open to outside traffic
_verify_contains snip_open_the_application_to_outside_traffic_ip_1 "$snip_open_the_application_to_outside_traffic_ip_1_out"
_wait_for_istio gateway default bookinfo-gateway

# Ensure no issues with configuration - istioctl analyze
_verify_contains snip_open_the_application_to_outside_traffic_ip_2 "$snip_open_the_application_to_outside_traffic_ip_2_out"

# Get GATEWAY_URL
# export the INGRESS_ environment variables
# TODO make this work more generally. Currently using snips for Kind.
snip_determining_the_ingress_ip_and_ports_10
snip_determining_the_ingress_ip_and_ports_15
snip_determining_the_ingress_ip_and_ports_16

# Verify external access
get_bookinfo_productpage() {
    curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
}
_verify_contains get_bookinfo_productpage "<title>Simple Bookstore App</title>"

# verify Kiali deployment
_verify_contains snip_view_the_dashboard_dashboard_1 'deployment "kiali" successfully rolled out'

# Verify Kiala dashboard
# TODO Verify the browser output

# @cleanup
cleanup_bookinfo_sample
snip_uninstall_1
kubectl delete ns istio-system --ignore-not-found=true
