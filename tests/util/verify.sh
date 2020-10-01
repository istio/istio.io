#!/bin/bash
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
    printf "VERIFY FAILED %s: received: \"%s\", expected: \"%s\"\n" "$msg" "$out" "$expected"
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
#        - different elapsed time values
#        - different ip values
#        - prefix match ending with a dash character
#        - expected ... is a wildcard token, matches anything
# Otherwise, returns 1.
__cmp_like() {
    local out="${1//$'\r'}"
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

# Verify the output of $func is the same as $expected.  If they are not the same,
# exponentially back off and try again, 7 times (~2m total) by default. The number
# of retries can be changed by setting the VERIFY_RETRIES environment variable.
__verify_with_retry() {
    local cmp_func=$1
    local func=$2
    local expected=$3
    local failonerr=${4:-}

    local max_attempts=${VERIFY_RETRIES:-7}
    local attempt=1

    # Most tests include "set -e", which causes the script to exit if a
    # statement returns a non-true return value.  In some cases, $func may
    # exit with a non-true return value, but we want to retry the command
    # later.  We want to temporarily disable that "errexit" behavior.
    local errexit_state
    errexit_state="$(shopt -po errexit || true)"
    set +e

    while true; do
        # Run the command.
        out=$($func 2>&1)
        local funcret="$?"

        # shellcheck disable=SC2001
        out=$(sed 's/[[:space:]]*$//g' <<< "$out")

        $cmp_func "$out" "$expected"
        local cmpret="$?"

        if [[ "$cmpret" -eq 0 ]]; then
            if [[ -z "$failonerr" || "$funcret" -eq 0 ]]; then
                # Restore the "errexit" state.
                eval "$errexit_state"
                return
            fi
        fi

        if (( attempt >= max_attempts )); then
            # Restore the "errexit" state.
            eval "$errexit_state"
            __err_exit "$func" "$out" "$expected"
        fi

        sleep $(( 2 ** attempt ))
        attempt=$(( attempt + 1 ))
    done
}

# Get the resource state of the cluster. Used by the test framework to compare the
# cluster state before and after running each test:
#
# __cluster_snapshot
#
# ... test commands
# ... cleanup commands
#
# __cluster_cleanup_check
#
__cluster_state() {
    # kubectl get ns -o name
    # kubectl get all --ignore-not-found -n default -n istio-system
    # kubectl get istiooperators --ignore-not-found -n default -n istio-system
    # TODO: ^^^ fails because istio-system ns is sometimes incorrectly in snapshot, still cleaning up from previous test.

    # TEMP WORKAROUND, don't check istio-system
    kubectl get ns -o name | sed '/istio-system/d'
    kubectl get all --ignore-not-found -n default
    kubectl get istiooperators --ignore-not-found -n default 2>&1
    kubectl get destinationrules --ignore-not-found -n default -n istio-system 2>&1
    kubectl get envoyfilters --ignore-not-found -n default -n istio-system 2>&1
    kubectl get gateways --ignore-not-found -n default -n istio-system  2>&1
    kubectl get serviceentries --ignore-not-found -n default -n istio-system 2>&1
    kubectl get sidecars --ignore-not-found -n default -n istio-system 2>&1
    kubectl get virtualservices --ignore-not-found -n default -n istio-system 2>&1
    kubectl get workloadentries --ignore-not-found -n default -n istio-system 2>&1
    kubectl get authorizationpolicies --ignore-not-found -n default -n istio-system 2>&1
    kubectl get peerauthentications --ignore-not-found -n default -n istio-system 2>&1
    kubectl get requestauthentications --ignore-not-found -n default -n istio-system 2>&1
}

__create_cluster_snapshots() {
    # Get the list of KUBECONFIG files as an array.
    IFS=':' read -r -a KFILES <<< "${KUBECONFIG}"
    for KFILE in "${KFILES[@]}"; do
        # Get the contexts in this KUBECONFIG file as an array.
        mapfile -t CTXS <<< "$(export KUBECONFIG=${KFILE}; kubectl config get-contexts -o name)"
        if [[ "${#CTXS[*]}" != "1" ]]; then
          echo "${KFILE} contains ${#CTXS[*]} contexts. Expected 1."
          exit 1
        fi

        # Dump the state of this cluster to a snapshot file.
        CTX="${CTXS[0]}"
        SNAPSHOT_FILE="__cluster_snapshot_${CTX}.txt"
        echo "Creating snapshot ${SNAPSHOT_FILE}"
        (KUBECONFIG="${KFILE}"; __cluster_state > "${SNAPSHOT_FILE}" 2>&1)
    done
}

__cluster_cleanup_check() {
    # Get the list of KUBECONFIG files as an array.
    IFS=':' read -r -a KFILES <<< "${KUBECONFIG}"
    for KFILE in "${KFILES[@]}"; do
        # Get the contexts in this KUBECONFIG file as an array.
        mapfile -t CTXS <<< "$(export KUBECONFIG=${KFILE}; kubectl config get-contexts -o name)"
        if [[ "${#CTXS[*]}" != "1" ]]; then
          echo "${KFILE} contains ${#CTXS[*]} contexts. Expected 1."
          exit 1
        fi

        # Read the snapshot file for this cluster.
        CTX="${CTXS[0]}"
        SNAPSHOT_FILE="__cluster_snapshot_${CTX}.txt"
        echo "Performing cleanup check against snapshot ${SNAPSHOT_FILE}"
        SNAPSHOT=$(<"${SNAPSHOT_FILE}")
        rm "${SNAPSHOT_FILE}"

        # Verify that we've restored the original cluster state.
        VERIFY_RETRIES=9
        (KUBECONFIG="${KFILE}"; _verify_like __cluster_state "${SNAPSHOT}")
        echo "Finished cleanup check against snapshot ${SNAPSHOT_FILE}"
    done
}


# Public Functions


# Runs $func and compares the output with $expected.  If they are not the same,
# exponentially back off and try again, 7 times by default. The number of retries
# can be changed by setting the VERIFY_RETRIES environment variable.
_verify_same() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_same "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output does not
# contain the substring $expected,
# exponentially back off and try again, 7 times by default. The number of retries
# can be changed by setting the VERIFY_RETRIES environment variable.
_verify_contains() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_contains "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output contains the
# substring $expected,
# exponentially back off and try again, 7 times by default. The number of retries
# can be changed by setting the VERIFY_RETRIES environment variable.
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
# exponentially back off and try again, 7 times by default. The number of retries
# can be changed by setting the VERIFY_RETRIES environment variable.
_verify_elided() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_elided "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the first line of
# output does not match the first line in $expected,
# exponentially back off and try again, 7 times by default. The number of retries
# can be changed by setting the VERIFY_RETRIES environment variable.
_verify_first_line() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_first_line "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output is not
# "like" $expected,
# exponentially back off and try again, 7 times by default. The number of retries
# can be changed by setting the VERIFY_RETRIES environment variable.
# Like implies:
#   1. Same number of lines
#   2. Same number of whitespace-seperated tokens per line
#   3. Tokens can only differ in the following ways:
#        - different elapsed time values
#        - different ip values
#        - prefix match ending with a dash character
#        - expected ... is a wildcard token, matches anything
_verify_like() {
    local func=$1
    local expected=$2
    __verify_with_retry __cmp_like "$func" "$expected"
}

# Runs $func and compares the output with $expected.  If the output does not
# "conform to" the specification in $expected,
# exponentially back off and try again, 7 times by default. The number of retries
# can be changed by setting the VERIFY_RETRIES environment variable.
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
    local errexit_state

    errexit_state="$(shopt -po errexit || true)"
    set +e

    # Run the command.
    out=$($func 2>&1)
    local funcret="$?"

    # Restore the "errexit" state.
    eval "$errexit_state"

    if [[ "$funcret" -eq 0 ]]; then
        __err_exit "$func" "$out" "NON-ZERO COMMAND EXIT STATUS"
    fi
}