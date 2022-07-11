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

# @setup profile=none

snip_plug_in_certificates_and_key_into_the_cluster_1
snip_plug_in_certificates_and_key_into_the_cluster_2
snip_plug_in_certificates_and_key_into_the_cluster_3
snip_plug_in_certificates_and_key_into_the_cluster_4
snip_plug_in_certificates_and_key_into_the_cluster_5

echo y | snip_deploy_istio_1
_wait_for_deployment istio-system istiod

# create_ns_foo_with_httpbin_sleep
snip_deploying_example_services_1
snip_deploying_example_services_2

_wait_for_deployment foo httpbin
_wait_for_deployment foo sleep

# Disable errors, since the next command is expected to return an error.
set +e
set +o pipefail

# Retrieve the certificate chain
snip_verifying_the_certificates_1

# Restore error handling
set -e
set -o pipefail

# Split the certificate chain to cert files
snip_verifying_the_certificates_2

_verify_same snip_verifying_the_certificates_3 "$snip_verifying_the_certificates_3_out"

_verify_same snip_verifying_the_certificates_4 "$snip_verifying_the_certificates_4_out"

_verify_same snip_verifying_the_certificates_5 "$snip_verifying_the_certificates_5_out"

# @cleanup
snip_cleanup_1
snip_cleanup_2
#TODO fix cleanup instructions in doc and then remove the following 2 lines
kubectl get validatingwebhookconfigurations -o custom-columns=NAME:.metadata.name --no-headers | xargs kubectl delete validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations -o custom-columns=NAME:.metadata.name --no-headers | xargs kubectl delete mutatingwebhookconfigurations
