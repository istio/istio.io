#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
ISTIOCTL=${ISTIOCTL:-istioctl}
ISTIOCTL_DIR=$(readlink -f ${BASE}/_docs/reference/istioctl/)

function commandHeader() {
    title=${1}
    overview=${2}
    order=${3}
    cat <<EOF
---
title: ${title}
overview: ${overview}
order: ${order}
layout: docs
type: markdown
---
EOF
}

function generateIndex() {
    order=${1}
    cat <<EOF
---
title: The Istioctl Command
overview: Options showing how to use the istioctl command.
order: ${order}
layout: docs
type: markdown
---
{% include section-index.html %}
EOF
}

# Generate raw markdown files with istioctl markdown.
rm ${ISTIOCTL_DIR}/* || echo "nothing to clean from ${ISTIOCTL_DIR}/"
mkdir -p ${ISTIOCTL_DIR}
${ISTIOCTL} markdown --dir ${ISTIOCTL_DIR}

order=0

# Patch markdown up with the proper formatting.
for file in ${ISTIOCTL_DIR}/*.md; do
    # Use the first header line as the title.
    title=$(grep -m1 -oP '^## \K.*' ${file})

    # Use non-comment line as the overview
    overview=$(grep -m1 -oP '\K^\w.*' ${file})

    # Arrange pages based on 'ls' alphabetical ordering.
    order=$((${order} + 1))

    # Prepend template header.
    out=$(mktemp)
    commandHeader "${title}" "${overview}" "${order}"| cat - ${file} > ${out}
    cp ${out} ${file}

    # Rename markdown links to html equivalent.
    sed -i 's|\(\[.*\]\)(\(.*\).md)|\1(\2.html)|' ${file}
done

# Generate main index last so it isn't patched by previous steps.
generateIndex 0 > ${ISTIOCTL_DIR}/index.md
