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

snip_liveness_and_readiness_probes_using_the_command_approach_1

snip_liveness_and_readiness_probes_using_the_command_approach_2

_wait_for_istio peerauthentication istio-io-health default

snip_liveness_and_readiness_probes_using_the_command_approach_3

_wait_for_deployment istio-io-health liveness

_verify_like snip_liveness_and_readiness_probes_using_the_command_approach_4 "$snip_liveness_and_readiness_probes_using_the_command_approach_4_out"

kubectl -n istio-io-health delete -f samples/health-check/liveness-command.yaml

snip_disable_the_probe_rewrite_globally_1

# TODO test annotation approach and verify both disable approaches work.

# @cleanup
snip_cleanup_1
