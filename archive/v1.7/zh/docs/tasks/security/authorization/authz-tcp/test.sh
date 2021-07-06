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

snip_before_you_begin_1

_wait_for_deployment foo tcp-echo
_wait_for_deployment foo sleep

# shellcheck disable=SC2155
export TCP_ECHO_IP=$(kubectl get pod "$(kubectl get pod -l app=tcp-echo -n foo -o jsonpath={.items..metadata.name})" -n foo -o "jsonpath={.status.podIP}")

# When strict-mode mTLS is enabled, only ports defined as a service are
# protected by mTLS.  As part of this test, we connect to port 9002, which was
# not configured as a service, so the connection fails and breaks the test.
#
# To make this test reliable, we remove any peer authentication that may have
# stuck around from a previous test.
#kubectl delete peerauthentication --all-namespaces --all

_verify_same snip_before_you_begin_2 "$snip_before_you_begin_2_out"

_verify_same snip_before_you_begin_3 "$snip_before_you_begin_3_out"

_verify_same snip_before_you_begin_4 "$snip_before_you_begin_4_out"

snip_configure_access_control_for_a_tcp_workload_1
_wait_for_istio authorizationpolicy foo tcp-policy

_verify_same snip_configure_access_control_for_a_tcp_workload_2 "$snip_configure_access_control_for_a_tcp_workload_2_out"

_verify_same snip_configure_access_control_for_a_tcp_workload_3 "$snip_configure_access_control_for_a_tcp_workload_3_out"

_verify_same snip_configure_access_control_for_a_tcp_workload_4 "$snip_configure_access_control_for_a_tcp_workload_4_out"

snip_configure_access_control_for_a_tcp_workload_5
_wait_for_istio authorizationpolicy foo tcp-policy

_verify_same snip_configure_access_control_for_a_tcp_workload_6 "$snip_configure_access_control_for_a_tcp_workload_6_out"

_verify_same snip_configure_access_control_for_a_tcp_workload_7 "$snip_configure_access_control_for_a_tcp_workload_7_out"

snip_configure_access_control_for_a_tcp_workload_8
_wait_for_istio authorizationpolicy foo tcp-policy

_verify_same snip_configure_access_control_for_a_tcp_workload_9 "$snip_configure_access_control_for_a_tcp_workload_9_out"

_verify_same snip_configure_access_control_for_a_tcp_workload_10 "$snip_configure_access_control_for_a_tcp_workload_10_out"

# @cleanup
set +e # ignore cleanup errors
snip_clean_up_1
