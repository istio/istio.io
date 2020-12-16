#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"

# @setup profile=default

kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

# export the INGRESS_ environment variables
_set_ingress_environment_variables

# create the Ingress resource
snip_configuring_ingress_using_an_ingress_resource_1

# access exposed httpbin URL
_verify_elided snip_configuring_ingress_using_an_ingress_resource_2 "$snip_configuring_ingress_using_an_ingress_resource_2_out"

# Access other URL
_verify_elided snip_configuring_ingress_using_an_ingress_resource_3 "$snip_configuring_ingress_using_an_ingress_resource_3_out"

# Test IngressClass and pathType
kubectl apply -f - <<< "$snip_specifying_ingressclass_1"

get_headers() {
curl -s -H "Foo: bar" -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}
_verify_contains get_headers '"Foo": "bar"'

# @cleanup

set +e # ignore cleanup errors
snip_cleanup_1
