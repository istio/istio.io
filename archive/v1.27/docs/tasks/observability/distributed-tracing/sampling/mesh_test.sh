#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155,SC2034,SC2016

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
source "tests/util/addons.sh"

# @setup profile=none
snip_install_default_sampling

# Deploy the OTel collector
bpsnip_start_otel_collector_service__1
bpsnip_start_otel_collector_service__2
_wait_for_deployment observability opentelemetry-collector

# Enable OTel Tracing extension via Telememetry API
snip_enable_telemetry_no_sampling

# Install Bookinfo application
startup_bookinfo_sample

_set_ingress_environment_variables
GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
bpsnip_trace_generation__1

# @cleanup
cleanup_bookinfo_sample
snip_cleanup_telemetry
snip_cleanup_collector

# clean up istio to restore state of profile=none
istioctl uninstall --purge -y
kubectl delete ns istio-system
kubectl label namespace default istio-injection-
