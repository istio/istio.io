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

REPEAT=${REPEAT:-100}
THRESHOLD=${THRESHOLD:-1}

# verify calls curl to send requests to productpage via ingressgateway.
# - The 1st argument is the expected http response code
# - The remaining arguments are the expected text in the http response
# Return 0 if both the code and text is found in the response for continuously $THRESHOLD times,
# otherwise return 1.
#
# Examples:
# 1) Expect http code 200 and "reviews", "ratings" in the body: verify 200 "reviews" "ratings"
# 2) Expect http code 403 and "RBAC: access denied" in the body: verify 200 "RBAC: access denied"
# 3) Expect http code 200 only: verify 200
function verify {
  lastResponse=""
  wantCode=$1
  shift
  wantText=("$@")
  goodResponse=0

  ingress_url="http://istio-ingressgateway.istio-system/productpage"
  sleep_pod=$(kubectl get pod -l app=sleep -n default -o 'jsonpath={.items..metadata.name}')

  for ((i=1; i<="$REPEAT"; i++)); do
    set +e
    response=$(kubectl exec "${sleep_pod}" -c sleep -n "default" -- curl "${ingress_url}" -s -w "\n%{http_code}\n")
    set -e
    mapfile -t respArray <<< "$response"
    code=${respArray[-1]}
    body=${response}

    matchedText=0
    if [ "$code" == "$wantCode" ]; then
      for want in "${wantText[@]}"; do
        if [[ "$body" = *$want* ]]; then
          matchedText=$((matchedText + 1))
        else
          lastResponse="$code\n$body"
        fi
      done
    else
      lastResponse="$code\n$body"
    fi

    if [[ "$matchedText" == "$#" ]]; then
      goodResponse=$((goodResponse + 1))
    else
      goodResponse=0
    fi

    if (( "$goodResponse">="$THRESHOLD" )); then
      return 0
    fi
  done

  echo -e "want code ${wantCode} and text: $(printf "%s, " "${wantText[@]}")\ngot: ${lastResponse}\n"
  return 1
}

kubectl label namespace default istio-injection=enabled --overwrite
startup_sleep_sample # needed for sending test requests with curl

# launch the bookinfo app
startup_bookinfo_sample

# TODO: Using reviews-v3 in this test. Should update the doc to do so as well, to make sure ratings request
#       are configured when it demonstrates denial of access to the ratings service.
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml
_wait_for_istio virtualservice default reviews

snip_configure_access_control_for_workloads_using_http_traffic_1
_wait_for_istio authorizationpolicy default deny-all

# Verify we don't have access.
verify 403 "RBAC: access denied"

snip_configure_access_control_for_workloads_using_http_traffic_2
_wait_for_istio authorizationpolicy default productpage-viewer

# Verify we have access to the productpage, but not to details and reviews.
verify 200 "William Shakespeare" "Error fetching product details" "Error fetching product reviews"

snip_configure_access_control_for_workloads_using_http_traffic_3
snip_configure_access_control_for_workloads_using_http_traffic_4
_wait_for_istio authorizationpolicy default details-viewer
_wait_for_istio authorizationpolicy default reviews-viewer

# Verify we have access to the productpage, but ratings are still not available.
verify 200 "William Shakespeare" "Ratings service is currently unavailable"

snip_configure_access_control_for_workloads_using_http_traffic_5
_wait_for_istio authorizationpolicy default ratings-viewer

# Verify we now have access.
verify 200 "William Shakespeare" "Book Details" "Book Reviews"

# @cleanup
set +e # ignore cleanup errors
snip_clean_up_1
# remaining cleanup (undocumented).
cleanup_bookinfo_sample
cleanup_sleep_sample
kubectl delete -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml
