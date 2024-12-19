#!/usr/bin/env bash
# shellcheck disable=SC2154

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

snip_configure_helm
_rewrite_helm_repo snip_install_ambient_aio

_verify_like snip_show_components "$snip_show_components_out"
_verify_like snip_check_pods "$snip_check_pods_out"

# @cleanup
snip_delete_ambient_aio
snip_delete_crds
snip_delete_system_namespace
