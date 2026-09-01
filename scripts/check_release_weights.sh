#!/usr/bin/env bash
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

# Checks (and optionally fixes) the `weight` front matter of the release
# announcement section pages under content/*/news/releases/<major>.<minor>.x/.
#
# Hugo sorts these pages by ascending weight, and treats a weight of 0 as
# "unweighted", which sorts last. To keep the newest release at the top forever
# without renumbering every directory on each release, the weight is derived
# from the version itself:
#
#     weight = BASE - (major * 100 + minor)
#
# So 1.31.x is 869, 1.32.x is 868, 2.0.x is 800, and 0.x is 1000. Adding a new
# minor release only ever adds one file; no existing weight has to change.
#
# Usage:
#   scripts/check_release_weights.sh          # verify, exit 1 on mismatch
#   scripts/check_release_weights.sh --fix    # rewrite the wrong weights

set -euo pipefail

BASE=1000

FIX=0
if [[ "${1:-}" == "--fix" ]]; then
    FIX=1
elif [[ -n "${1:-}" ]]; then
    echo "usage: $0 [--fix]" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

expected_weight() {
    local dir_name="$1" major minor
    if [[ "${dir_name}" =~ ^([0-9]+)\.([0-9]+)\.x$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
    elif [[ "${dir_name}" =~ ^([0-9]+)\.x$ ]]; then
        # Pre-1.0 releases were only ever grouped by major version.
        major="${BASH_REMATCH[1]}"
        minor=0
    else
        return 1
    fi
    if (( minor > 99 )); then
        echo "internal error: minor ${minor} in '${dir_name}' overflows the weight formula" >&2
        exit 1
    fi
    echo "$(( BASE - (major * 100 + minor) ))"
}

failed=0
fixed=0
checked=0

while IFS= read -r index; do
    dir_name="$(basename "$(dirname "${index}")")"

    if ! want="$(expected_weight "${dir_name}")"; then
        echo "SKIP  ${index}: directory name '${dir_name}' is not <major>.<minor>.x"
        continue
    fi

    checked=$(( checked + 1 ))
    got="$(sed -n 's/^weight:[[:space:]]*\([0-9-]\+\)[[:space:]]*$/\1/p' "${index}" | head -1)"

    if [[ "${got}" == "${want}" ]]; then
        continue
    fi

    if [[ -z "${got}" ]]; then
        echo "FAIL  ${index}: no 'weight:' found, expected 'weight: ${want}'"
        failed=1
        continue
    fi

    if (( FIX )); then
        sed -i "0,/^weight:/s/^weight:[[:space:]]*[0-9-]\+[[:space:]]*$/weight: ${want}/" "${index}"
        echo "FIXED ${index}: ${got} -> ${want}"
        fixed=$(( fixed + 1 ))
    else
        echo "FAIL  ${index}: weight is ${got}, expected ${want}"
        failed=1
    fi
done < <(find content -mindepth 5 -maxdepth 5 -path 'content/*/news/releases/*/_index.md' | sort)

if (( checked == 0 )); then
    echo "ERROR: found no release section pages under content/*/news/releases/" >&2
    exit 1
fi

if (( FIX )); then
    echo "Checked ${checked} release section pages, fixed ${fixed}."
    exit 0
fi

if (( failed )); then
    cat >&2 <<EOF

Release announcement weights are out of date.
Run 'scripts/check_release_weights.sh --fix' (or 'make fix-release-weights') and commit the result.
EOF
    exit 1
fi

echo "Checked ${checked} release section pages, all weights correct."
