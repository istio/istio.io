#!/bin/bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http:/www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Get the gateway-api version/sha

set -e

MOD_STRING=$(grep gateway-api go.mod | awk '{ print $2 }')
# Does MOD_STRING contain a -? Yes, parse out short sha and get the full sha. If not, then this is the version needed.
if [[ "$MOD_STRING" == *"-"* ]]; then
  IFS='-' read -ra SPLITS <<< "$MOD_STRING"
  MOD_STRING=${SPLITS[0]}
fi
echo "${MOD_STRING}"
