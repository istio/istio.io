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

# @setup profile=default

set -e
set -u
set -o pipefail

# Deploy Prometheus with mTLS scraping pre-configured
snip_configure_prometheus_for_mtls_scraping_1
_wait_for_deployment istio-system prometheus

# Verify Prometheus has sidecar injected (3/3 ready)
_verify_like snip_configure_prometheus_for_mtls_scraping_2 "$snip_configure_prometheus_for_mtls_scraping_2_out"

# Deploy httpbin
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f samples/httpbin/httpbin.yaml
_wait_for_deployment default httpbin

# Patch httpbin to enable the mTLS metrics listeners
snip_enable_on_a_sidecar_workload_2
_wait_for_deployment default httpbin

# Set env vars used by subsequent snips
export HTTPBIN_POD=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].metadata.name}')
export HTTPBIN_IP=$(kubectl get pod -n default -l app=httpbin -o jsonpath='{.items[0].status.podIP}')
export PROM_POD=$(kubectl get pod -n istio-system -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')

# Verify the mTLS listeners (15091, 15092) are active on the httpbin sidecar
_verify_like snip_enable_on_a_sidecar_workload_3 "$snip_enable_on_a_sidecar_workload_3_out"

# Verify mTLS scraping succeeds: Prometheus pod's sidecar curls httpbin with workload certs → HTTP 200
_verify_same snip_verify_secure_metrics_scraping_with_prometheus_1 "$snip_verify_secure_metrics_scraping_with_prometheus_1_out"

# Verify mTLS is enforced: plain HTTP to the secure port must be rejected
_verify_contains snip_verify_secure_metrics_scraping_with_prometheus_2 "connection termination"

# @cleanup
snip_cleanup_1
