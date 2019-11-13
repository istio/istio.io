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

# This script obtains the operator's yaml files and constructs them into
# one manifest. Additionally IstioControlPlane custom resources are generated
# for each of the profiles for easy switching between deployment modes.

if [[ "$1" != "" ]]; then
  SOURCE_BRANCH_NAME="$1"
else
  SOURCE_BRANCH_NAME="master"
fi

# Find the output directory
scriptpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
rootdir=$(dirname "${scriptpath}")
output_dir="${rootdir}/static"

# Temporary directories securely created
tempdir_operator="$(mktemp -d)"

# Upstream GIT tags or branches used for the operator repo.
operator_tag="${SOURCE_BRANCH_NAME}"

# Add profiles here to have them automatically added to the website.
# It is important to also document these files, which is not done automatically.

operator_profiles=( "default" "demo" "sds" "minimal" )

rm -f "${output_dir}"/operator.yaml
touch "${output_dir}"/operator.yaml
echo "operator/*"
pushd "${tempdir_operator}" >/dev/null || exit
git clone -q --single-branch --branch "${operator_tag}" https://github.com/istio/operator.git
pushd operator >/dev/null || exit
git checkout -q "${operator_tag}"

# Generate the profiles
for profile in "${operator_profiles[@]}"
do
	cp deploy/crds/istio_v1alpha2_istiocontrolplane_cr.yaml "${output_dir}"/operator-profile-"${profile}".yaml
	sed -i "s/profile: default/profile: ${profile}/g" "${output_dir}"/operator-profile-"${profile}".yaml
done

# Great care should be taken when modifying the ordering of this list. This
# script cats these files together in order with a yaml separator.

operator_manifest_files=( "deploy/namespace.yaml" "deploy/crds/istio_v1alpha2_istiocontrolplane_crd.yaml" "deploy/service_account.yaml" "deploy/clusterrole.yaml" "deploy/clusterrole_binding.yaml" "deploy/service.yaml" "deploy/operator.yaml" )

# Generate the main manifest
cat "${operator_manifest_files[@]}" >> "${output_dir}"/operator.yaml

popd >/dev/null || exit
rm -rf "${tempdir_operator}" > /dev/null 2>&1
