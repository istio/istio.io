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

# @setup profile=default

_set_ingress_environment_variables

startup_bookinfo_sample

snip_apply_parity

_verify_same snip_verify_parity_even "$snip_verify_parity_even_out"

_verify_same snip_verify_parity_odd "$snip_verify_parity_odd_out"

# @cleanup
snip_clean_up
cleanup_bookinfo_sample
