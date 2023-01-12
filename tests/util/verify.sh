#!/usr/bin/env bash
# shellcheck disable=SC2030,SC2031

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
    local msg=$1
    local out=$2
    local expected=$3
    printf "VERIFY FAILED %s:\nreceived:\n\"%s\"\nexpected:\n\"%s\"\n" "$msg" "$out" "$expected"
    exit 1
}

# Returns 0 if $out and $expected are the same.  Otherwise, returns 1.
__cmp_same() {
    local out="${1//$'\r'}"
    local expected=$2

    if [[ "$out" != "$expected" ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if $out contains the substring $expected.  Otherwise, returns 1.
__cmp_contains() {
    local out="${1//$'\r'}"
    local expected=$2

    if [[ "$out" != *"$expected"* ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if $out does not contain the substring $expected.  Otherwise,
# returns 1.
__cmp_not_contains() {
    local out="${1//$'\r'}"
    local expected=$2

    if [[ "$out" == *"$expected"* ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if $out contains the lines in $expected where "..." on a line
# matches one or more lines containing any text.  Otherwise, returns 1.
__cmp_elided() {
    local out="${1//$'\r'}"
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

# Returns 0 if $out matches the regex string $expected.  Otherwise, returns 1.
__cmp_regex() {
    local out="${1//$'\r'}"
    local expected=$2

    if [[ "$out" =~ $expected ]]; then
        return 0
    fi

    return 1
}

# Returns 0 if the first line of $out matches the first line in $expected.
# Otherwise, returns 1.
__cmp_first_line() {
    local out=$1
    local expected=$2

    IFS=$'\n\r' read -r out_first_line <<< "$out"
    IFS=$'\n' read -r expected_first_line <<< "$expected"

    if [[ "$out_first_line" != "$expected_first_line" ]]; then
        return 1
    fi

    return 0
}

# Returns 0 if $out is "like" $expected. Like implies:
#   1. Same number of lines
#   2. Same number of whitespace-seperated tokens per line
#   3. Tokens can only differ in the following ways:
#        - different elapsed time values (e.g. 25s, 2m30s).
#        - different ip values. Disallows <none> and <pending> by
#          default. This can be customized by setting the
#          CMP_MATCH_IP_NONE and CMP_MATCH_IP_PENDING environment
#          variables, respectively.
#        - prefix match ending with a dash character
#        - expected ... is a wildcard token, matches anything
# Otherwise, returns 1.
__cmp_like() {
    local out="${1//$'\r'}"
    local expected=$2
    local ipregex="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
    local timeregex="^([0-9]+[smhd])+$"

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
            # Get the next line from expected and output.
            local oline=${olines[i]}
            local eline=${elines[i]}

            # Optimization: if the lines match exactly, it's a match.
            if [[ "$oline" == "$eline" ]]; then
                continue
            fi

            # Split the expected and output lines into tokens.
            read -r -a otokens <<< "$oline"
            read -r -a etokens <<< "$eline"

            # Make sure the number of tokens match.
            if [[ ${#otokens[@]} -ne ${#etokens[@]} ]]; then
                return 1
            fi

            # Iterate and compare tokens.
            for j in "${!otokens[@]}"; do
                local etok=${etokens[j]}

                # If using wildcard, skip the match for this token.
                if [[ "$etok" == "..." ]]; then
                    continue
                fi

                # Get the token from the actual output.
                local otok=${otokens[j]}

                # Check for an exact token match.
                if [[ "$otok" == "$etok" ]]; then
                    continue
                fi

                # Check for elapsed time tokens.
                if [[ "$otok" =~ $timeregex && "$etok" =~ $timeregex ]]; then
                    continue
                fi

                # Check for IP addresses.
                if [[ "$etok" =~ $ipregex ]]; then
                    if [[ "$otok" =~ $ipregex ]]; then
                      # We got an IP address. It's a match.
                      continue
                    fi

                    if [[ "$otok" == "<pending>" && "${CMP_MATCH_IP_PENDING:-false}" == "true" ]]; then
                      # We're configured to allow <pending>. Consider this a match.
                      continue
                    fi

                    if [[ "$otok" == "<none>" && "${CMP_MATCH_IP_NONE:-false}" == "true" ]]; then
                      # We're configured to allow <none>. Consider this a match.
                      continue
                    fi
                fi

                local comm=""
                for ((k=0; k < ${#otok}; k++)) do
                    if [ "${otok:$k:1}" != "${etok:$k:1}" ]; then
                        break
                    fi
                    comm="${comm}${otok:$k:1}"
                done
                if ! [[ "$comm" =~ ^([a-zA-Z0-9_]+-)+ ]]; then
                    return 1
                fi
            done
        done
    fi

    return 0
}

# Returns 0 if $out "conforms to" $expected. Conformance implies:
#   1. For each line in $expected with the prefix "+ " there must be at least one
#      line in $output containing the following string.
#   2. For each line in $expected with the prefix "- " there must be no line in
#      $output containing the following string.
# Otherwise, returns 1.
__cmp_lines() {
    local out=$1
    local expected=$2

    while IFS=$'\n' read -r line; do
        if [[ "${line:0:2}" == "+ " ]]; then
            __cmp_contains "$out" "${line:2}"
        elif [[ "${line:0:2}" == "- " ]]; then
            __cmp_not_contains "$out" "${line:2}"
        else
            continue
        fi
        # shellcheck disable=SC2181
        if [[ "$?" -ne 0 ]]; then
            return 1
        fi
    done <<< "$expected"

    return 0
}

# Returns 0 if the command failed to execute.  Otherwise, returns 1.
__cmp_failure() {
    local funcret=$3

    if [[ "$funcret" -eq 0 ]]; then
        return 1
    fi

    return 0
}

# Verify the output of $func is the same as $expected.  If they are not the same,
# retry every second, up to 2 minutes by default. The delay between retries as
# well as the timeout can be configured by setting the VERIFY_DELAY and
# VERIFY_TIMEOUT environment variables, respectively. You can also specify
# the expected number of consecutive successes by setting the VERIFY_CONSECUTIVE
# environment variable.
#
# Arguments:
# $1: output comparison function (required).
# $2: function to be executed periodically (required).
# $3: expected output (required).
# $4: fail on error. If a non-empty string, will restore the failure status upon error.
__verify_with_retry() {
    local cmp_func=$1
    local func=$2
    local expected=$3
    local failonerr=${4:-}

    local max_time=${VERIFY_TIMEOUT:-120} # Default=2m
    local delay=${VERIFY_DELAY:-1} # Default=1s
    local expected_consecutive=${VERIFY_CONSECUTIVE:-1} # Default=1 success

    local start_time
    start_time=$(date +%s)
    local end_time
    end_time=$((start_time + max_time))
    local current_time=$start_time

    # Most tests include "set -e", which causes the script to exit if a
    # statement returns a non-true return value.  In some cases, $func may
    # exit with a non-true return value, but we want to retry the command
    # later.  We want to temporarily disable that "errexit" behavior.
    local errexit_state
    errexit_state="$(shopt -po errexit || true)"
    set +e

    local consecutive=0
    while true; do
        # Run the command.
        out=$($func 2>&1)
        local funcret="$?"

        # shellcheck disable=SC2001
        out=$(sed 's/[[:space:]]*$//g' <<< "$out")

        $cmp_func "$out" "$expected" "$funcret"
        local cmpret="$?"

        if [[ "$cmpret" -eq 0 ]]; then
            # Comparison succeeded.
            consecutive=$(( consecutive + 1 ))
            if (( consecutive >= expected_consecutive )); then
              if [[ -z "$failonerr" || "$funcret" -eq 0 ]]; then
                  # Restore the "errexit" state.
                  eval "$errexit_state"
                  return
              fi
            fi
        else
            # The comparison failed.
            consecutive=0
        fi

        current_time=$(date +%s)
        if (( current_time > end_time )); then
            # Restore the "errexit" state.
            eval "$errexit_state"
            __err_exit "$func (timeout after ${max_time}s)" "$out" "$expected"
        fi

        sleep "${delay}"
    done
}

# Public Functions


# Runs $func and compares the output with $expected.  If they are not the same,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
_verify_same() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_same "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output does not
# contain the substring $expected,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
_verify_contains() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_contains "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output contains the
# substring $expected,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
_verify_not_contains() {
    local func=$1
    local expected=$2
    # __cmp_not_contains will return true even if func fails. Pass failonerr arg
    # to tell __verify_with_retry to fail in this case instead.
    __verify_with_retry __cmp_not_contains "$func" "$expected" "true"
}

# Runs $func and compares the output with $expected.  If the output does not
# contain the lines in $expected where "..." on a line matches one or more lines
# containing any text,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
_verify_elided() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_elided "$func" "$expected"
}

# Runs $func and compares the output with regex string $expected.  If the output does not
# match the regex string $expected,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
_verify_regex() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_regex "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the first line of
# output does not match the first line in $expected,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
_verify_first_line() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_first_line "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output is not
# "like" $expected,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
#
# Like implies:
#   1. Same number of lines
#   2. Same number of whitespace-seperated tokens per line
#   3. Tokens can only differ in the following ways:
#        - different elapsed time values
#        - different ip values. Disallows <none> and <pending> by
#          default. This can be customized by setting the
#          CMP_MATCH_IP_NONE and CMP_MATCH_IP_PENDING environment
#          variables, respectively.
#        - prefix match ending with a dash character
#        - expected ... is a wildcard token, matches anything
_verify_like() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_like "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output does not
# "conform to" the specification in $expected,
# wait a second and try again, up to two minutes by default. The retry behavior
# can be changed by setting the `VERIFY_TIMEOUT` and `VERIFY_DELAY` environment
# variables. You can also specify the expected number of consecutive successes
# by setting the VERIFY_CONSECUTIVE environment variable.
#
# Conformance implies:
#   1. For each line in $expected with the prefix "+ " there must be at least one
#      line in the output containing the following string.
#   2. For each line in $expected with the prefix "- " there must be no line in
#      the output containing the following string.
_verify_lines() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_lines "$func" "$expected"
}

# Runs $func and confirm that it fails (i.e., non-zero return code). This function is useful
# for testing commands that demonstrate configurations that are expected to fail.
_verify_failure() {
    local func=$1
    __verify_with_retry __cmp_failure "$func" "NON-ZERO COMMAND EXIT STATUS"
}
