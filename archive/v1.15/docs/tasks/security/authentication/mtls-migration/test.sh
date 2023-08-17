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

# @setup profile=default

# create_ns_foo_bar_legacy
snip_set_up_the_cluster_1
snip_set_up_the_cluster_2

_wait_for_deployment foo httpbin
_wait_for_deployment foo sleep
_wait_for_deployment bar httpbin
_wait_for_deployment bar sleep
_wait_for_deployment legacy sleep

# curl_foo_bar_legacy
_verify_same snip_set_up_the_cluster_3 "$snip_set_up_the_cluster_3_out"

# verify_initial_peerauthentications
_verify_same snip_set_up_the_cluster_4 "$snip_set_up_the_cluster_4_out"

# TODO: Revisit this check. It may be that the DR from the test comes from the framework
#       Maybe we can move to profile none and simply set up a simple istioctl
# verify_initial_destinationrules
#_verify_like snip_set_up_the_cluster_5 "$snip_set_up_the_cluster_5_out"

# configure_mtls_foo_peerauthentication
snip_lock_down_to_mutual_tls_by_namespace_1
_wait_for_istio peerauthentication foo default

# Disable errors, since the next command is expected to return an error.
set +e
set +o pipefail

# curl_foo_bar_legacy_post_pa
_verify_same snip_lock_down_to_mutual_tls_by_namespace_2 "$snip_lock_down_to_mutual_tls_by_namespace_2_out"

# Restore error handling
set -e
set -o pipefail

# configure_mtls_entire_mesh
snip_lock_down_mutual_tls_for_the_entire_mesh_1
_wait_for_istio peerauthentication istio-system default

# Disable errors, since the next command is expected to return an error.
set +e
set +o pipefail

# curl_foo_bar_legacy_httpbin_foo_mtls
expected="sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56"
_verify_same snip_lock_down_mutual_tls_for_the_entire_mesh_2 "$expected"

# Restore error handling
set -e
set -o pipefail

# @cleanup
snip_clean_up_the_example_1
snip_clean_up_the_example_2
