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

__err_exit() {
    echo "VERIFY FAILED $1: $2";
    exit 1
}

# Returns 0 if $out and $expected are the same.  Otherwise, returns 1.
__cmp_same() {
    local out=$1
    local expected=$2

    if [[ "$out" != "$expected" ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if $out contains the substring $expected.  Otherwise, returns 1.
__cmp_contains() {
    local out=$1
    local expected=$2

    if [[ "$out" != *"$expected"* ]]; then
        echo "false"
        return 1
    fi

    return 0
}

# Returns 0 if $out does not contain the substring $expected.  Otherwise,
# returns 1.
__cmp_not_contains() {
    local out=$1
    local expected=$2

    if [[ "$out" == *"$expected"* ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if $out contains the lines in $expected where "..." on a line
# matches one or more lines containing any text.  Otherwise, returns 1.
__cmp_elided() {
    local out=$1
    local expected=$2

    local contains=""
    while IFS=$'\n' read -r line; do
        if [[ "$line" =~ ^[[:space:]]*\.\.\.[[:space:]]*$ ]]; then
            if [[ "$contains" != "" && "$out" != *"$contains"* ]]; then
                return 1
            fi
            contains=""
        else
            if [[ "$contains" != "" ]]; then
                contains+=$'\n'
            fi
            contains+="$line"
        fi
    done <<< "$expected"
    if [[ "$contains" != "" && "$out" != *"$contains"* ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if the first line of $out matches the first line in $expected.
# Otherwise, returns 1.
# TODO ???? flaky behavior, doesn't seem to work as expected
__cmp_first_line() {
    local out=$1
    local expected=$2

    # TODO ???? the following seem to leave a trailing \n in some cases and then the following check fails
    IFS=$'\n' read -r out_first_line <<< "$out"
    IFS=$'\n' read -r expected_first_line <<< "$expected"
    echo "out first line: \"$out_first_line\""
    echo "expected first line: \"$expected_first_line\""

    # TODO ???? following fails because one or the other might have a \n at the end of the string, when the other does not
    if [[ "$out_first_line" != "$expected_first_line" ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if $out is "like" $expected. Like implies:
#   1. Same number of lines
#   2. Same number of whitespace-seperated tokens per line
#   3. Tokens can only differ in the following ways:
#        - different elapsed time values
#        - different ip values
#        - prefix match ending with a dash character
#        - expected ... is a wildcard token, matches anything
# Otherwise, returns 1.
__cmp_like() {
    local out=$1
    local expected=$2

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
            return 1
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
                return 1
            fi

            for j in "${!otokens[@]}"; do
                local etok=${etokens[j]}

                if [[ "$etok" == "..." ]]; then
                    continue
                fi

                local otok=${otokens[j]}

                if [[ "$otok" == "$etok" ]]; then
                    continue
                fi

                if [[ "$otok" =~ ^([0-9]+[smhd])+$ && "$etok" =~ ^([0-9]+[smhd])+$ ]]; then
                    continue
                fi

                if [[ ("$otok" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$otok" == "<none>" || "$otok" == "<pending>") && "$etok" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
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
                        return 1
                    fi
                done
            done
        done
    fi

    return 0
}


# Verify that $out is the same as $expected.  If they are not the same,
# exponentially back off and try again.
__verify_with_retry() {
    local cmp_func=$1
    local cmd=$2
    local expected=$3
    local max_attempts=$4
    local attempt=1

    while true; do
      out=$($cmd 2>&1)

      if $cmp_func "$out" "$expected"; then
          return
      fi

      if (( attempt >= max_attempts )); then
          __err_exit "$cmd" "$out"
      fi

      sleep $(( 2 ** attempt ))
      attempt=$(( attempt + 1 ))
    done
}

# Public Functions

# Runs $func and compares the output with $expected.  If they are not the same,
# will retry $max_attempts times with an exponential backoff.  If $max_attempts
# is not set, it will retry 5 times by default.
_run_and_verify_same() {
    local func=$1
    local expected=$2
    local max_attempts=${3:-5}
    __verify_with_retry __cmp_same "$func" "$expected" "$max_attempts"
}

# Runs $func and compares the output with $expected.  If the output does not
# contain the substring $expected, will retry $max_attempts times with an
# exponential backoff.  If $max_attempts is not set, it will retry 5 times by
# default.
_run_and_verify_contains() {
    local func=$1
    local expected=$2
    local max_attempts=${3:-5}
    __verify_with_retry __cmp_contains "$func" "$expected" "$max_attempts"
}

# Runs $func and compares the output with $expected.  If the output contains the
# substring $expected, will retry $max_attempts times with an exponential
# backoff.  If $max_attempts is not set, it will retry 5 times by default.
#
# This function is not useful since __cmp_not_contains will return true
# even if the function fails. The _verify_not_contains function, itself,
# is also often not very useful for the same reason.
# TODO Replace it with some kind of _verify_worked_and_not_contains function.
_run_and_verify_not_contains() {
    local func=$1
    local expected=$2
    local max_attempts=${3:-5}
    __verify_with_retry __cmp_not_contains "$func" "$expected" "$max_attempts"
}

# Runs $func and compares the output with $expected.  If the output does not
# contain the lines in $expected where "..." on a line matches one or more lines
# containing any text, will retry $max_attempts times with an exponential
# backoff.  If $max_attempts is not set, it will retry 5 times by default.
_run_and_verify_elided() {
    local func=$1
    local expected=$2
    local max_attempts=${3:-5}
    __verify_with_retry __cmp_elided "$func" "$expected" "$max_attempts"
}

# Runs $func and compares the output with $expected.  If the first line of
# output does not match the first line in $expected, will retry $max_attempts
# times with an exponential backoff.  If $max_attempts is not set, it will
# retry 5 times by default.
_run_and_verify_first_line() {
    local func=$1
    local expected=$2
    local max_attempts=${3:-5}
    __verify_with_retry __cmp_first_line "$func" "$expected" "$max_attempts"
}

# Runs $func and compares the output with $expected.  If the output is not
# "like" $ecpted, will retry $max_attempts times with an exponential backoff.
# Like implies:
#   1. Same number of lines
#   2. Same number of whitespace-seperated tokens per line
#   3. Tokens can only differ in the following ways:
#        - different elapsed time values
#        - different ip values
#        - prefix match ending with a dash character
#        - expected ... is a wildcard token, matches anything
# If $max_attempts is not set, it will retry 5 times by default.
_run_and_verify_like() {
    local func=$1
    local expected=$2
    local max_attempts=${3:-5}
    __verify_with_retry __cmp_like "$func" "$expected" "$max_attempts"
}

# Verify that $out is the same as $expected.
_verify_same() {
    local out=$1
    local expected=$2
    local msg=$3

    if ! __cmp_same "$out" "$expected"; then
        __err_exit "$msg" "$out"
    fi
}

# Verify that $out contains the substring $expected.
_verify_contains() {
    local out=$1
    local expected=$2
    local msg=$3

    if ! __cmp_contains "$out" "$expected"; then
        __err_exit "$msg" "$out"
    fi
}

# Verify that $out does not contain the substring $expected.
_verify_not_contains() {
    local out=$1
    local expected=$2
    local msg=$3

    if ! __cmp_not_contains "$out" "$expected"; then
        __err_exit "$msg" "$out"
    fi
}

# Verify that $out contains the lines in $expected where "..." on a line
# matches one or more lines containing any text.
_verify_elided() {
    local out=$1
    local expected=$2
    local msg=$3

    if ! __cmp_elided "$out" "$expected"; then
        __err_exit "$msg" "$out"
    fi
}

# Verify that the first line of $out matches the first line in $expected.
_verify_first_line() {
    local out=$1
    local expected=$2
    local msg=$3

    if ! __cmp_first_line "$out" "$expected"; then
        __err_exit "$msg" "$out"
    fi
}

# Verify that $out is "like" $expected. Like implies:
#   1. Same number of lines
#   2. Same number of whitespace-seperated tokens per line
#   3. Tokens can only differ in the following ways:
#        - different elapsed time values
#        - different ip values
#        - prefix match ending with a dash character
#        - expected ... is a wildcard token, matches anything
_verify_like() {
    local out=$1
    local expected=$2
    local msg=$3

    if ! __cmp_like "$out" "$expected"; then
        __err_exit "$msg" "$out"
    fi
}
