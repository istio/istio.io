#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
ISTIOCTL=${ISTIOCTL:-istioctl}
ISTIOCTL_DIR=$(readlink -f ${BASE}/_docs/reference/istioctl-autogen/)

function mainPageHeader() {
    cat <<EOF
---
category: Reference
title: Istioctl
overview: ${title}
bodyclass: docs
layout: docs
type: markdown
---
EOF
}

function commandHeader() {
    title=${1}
    cat <<EOF
---
category: Reference
title: ${title}
overview: ${title}
parent: Istioctl
bodyclass: docs
layout: docs
type: markdown
---
EOF
}

# Generate markdown files with istioctl.
mkdir -p ${ISTIOCTL_DIR}
rm ${ISTIOCTL_DIR}/*
${ISTIOCTL} markdown --dir ${ISTIOCTL_DIR}

# Patch markdown up with the proper formatting.
for file in ${ISTIOCTL_DIR}/*.md; do
    # Use the first header line as the title.
    title=$(sed -n '/^[^#]/ {p;q;}' ${file})

    # Prepend template header.
    out=$(mktemp)
    case ${file} in
        ${ISTIOCTL_DIR}/istioctl.md)
            mainPageHeader "${title}" | cat - ${file} > ${out}
            ;;
        *)
            commandHeader "${title}" | cat - ${file} > ${out}
            ;;
    esac
    cp ${out} ${file}

    # Rename markdown links to html equivalent.
    sed -i 's|\(\[.*\]\)(\(.*\).md)|\1(\2.html)|' ${file}
done
