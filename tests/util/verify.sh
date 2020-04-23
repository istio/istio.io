#!/bin/bash

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

_err_exit() {
    echo "VERIFY FAILED $1: $2";
    exit 1
}

# Verify that $out is the same as $expected.
_verify_same() {
    local out=$1
    local expected=$2
    local msg=$3

    if [ "$out" != "$expected" ]; then
        _err_exit "$msg" "$out"
    fi
}

# Verify that $out contains the substring $expected.
_verify_contains() {
    local out=$1
    local expected=$2
    local msg=$3

    if [[ "$out" != *"$expected"* ]]; then
        _err_exit "$msg" "$out"
    fi
}

# Verify that $out does not contains the substring $expected.
_verify_not_contains() {
    local out=$1
    local expected=$2
    local msg=$3

    if [[ "$out" == *"$expected"* ]]; then
        _err_exit "$msg" "$out"
    fi
}

# Verify that $out is "like" $expected. Like implies:
#   1. Same number of lines
#   2. Same number of whitespace-seperated tokens per line
#   3. Tokens can only differ in the following ways:
#        - different elapsed time values
#        - different ip values
#        - prefix match ending with a dash character
_verify_like() {
    local out=$1
    local expected=$2
    local msg=$3

    if [[ "$out" != "$expected" ]]; then
        local olines=()
        while read -r line; do
            olines+=("$line")
        done <<< "$out"

        local elines=()
        while read -r line; do
            elines+=("$line")
        done <<< "$expected"

        if [[ ${#olines[@]} -ne ${#elines[@]} ]]; then
            _err_exit "$msg" "$out"
        fi

        for i in "${!olines[@]}"; do
            local oline=${olines[i]}
            local eline=${elines[i]}

            if [[ "$oline" == "$eline" ]]; then
                continue
            fi

            read -r -a otokens <<< "$oline"
            read -r -a etokens <<< "$eline"

            if [[ ${#otokens[@]} -ne ${#etokens[@]} ]]; then
                _err_exit "$msg" "$out"
            fi

            for j in "${!otokens[@]}"; do
                local otok=${otokens[j]}
                local etok=${etokens[j]}

                if [[ "$otok" == "$etok" ]]; then
                    continue
                fi

                if [[ "$otok" =~ ^([0-9]+[smhd])+$ && "$etok" =~ ^([0-9]+[smhd])+$ ]]; then
                    continue
                fi

                if [[ "$otok" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && "$etok" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    continue
                fi

                local comm=""
                for ((k=0; k < ${#otok}; k++)) do
                    if [ "${otok:$k:1}" = "${etok:$k:1}" ]; then
                        comm=${comm}${otok:$k:1}
                    else
                        if [[ "$comm" =~ ^([a-zA-Z0-9_]+-)+ ]]; then
                            break
                        fi
                        _err_exit "$msg" "$out"
                    fi
                done
            done
        done
    fi
}
