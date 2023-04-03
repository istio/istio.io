#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2034

# Copyright 2023 Istio Authors
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

# @setup profile=none
GATEWAY_API="true"

source "content/en/docs/ops/ambient/getting-started/test.sh"

# @cleanup
GATEWAY_API="true"

snip_uninstall_1
snip_uninstall_2
snip_uninstall_3
samples/bookinfo/platform/kube/cleanup.sh
snip_uninstall_4
