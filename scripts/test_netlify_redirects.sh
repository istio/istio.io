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

# Test the Netlify redirect scripts by checking various URLs
# Usage: ./test-netlify-redirects.sh [<base_url>]
set -e

if [[ "$#" -ne 0 ]]; then
    BASE_URL="$*"
else
    BASE_URL="https://preliminary.istio.io"
fi

URLS=(
  # Should redirect
  "/v1.1/uk"
  "/v1.1/uk/"
  "/v1.10/news/support/announcing-1.9-eol/"
  "/v1.15/get-involved/"
  "/v1.20/blog"
  "/v1.20/uk/"
  "/v1.21/uk/blog"
  "/v1.21/zh/"
  "/v1.22/zh/news"
  "/v1.23/about"
  "/v1.24/uk/search"
  "/v1.24/zh"
  "/v1.24/zh/"
  "/v1.25/zh/get-involved"
  "/v1.26/"

  # Should NOT redirect
  "/archive/"
  "/v1.20/docs/concepts"
  "/v1.21/zh/docs/setup"
  "/v1.22/docs/ops/diagnostic-tools"
  "/v1.22/docs/ops/diagnostic-tools/"
  "/v1.22/zh/docs/reference/config"
  "/v1.23/docs/"
  "/v1.24/docs/"
  "/v1.24/uk/docs/"
  "/v1.24/zh/docs/tasks/security"
  "/v1.24/zh/docs/tasks/security/"
  "/v1.25/zh/docs/tasks/security"

  # /latest URLs (should not redirect)
  "/latest"
  "/latest/"
  "/latest/blog"
  "/latest/docs/"
  "/latest/uk/"
  "/latest/uk/blog"
  "/latest/zh/"
  "/latest/zh/docs"
)

for path in "${URLS[@]}"; do
  full_url="${BASE_URL}${path}"
  response=$(curl -s -o /dev/null -w "%{http_code} %{redirect_url}" "$full_url")
  http_code=$(echo "$response" | cut -d' ' -f1)
  redirect_url=$(echo "$response" | cut -d' ' -f2-)

  if [[ "$http_code" == "301" || "$http_code" == "302" ]]; then
    echo "[REDIRECT] $path → $redirect_url"
  elif [[ "$http_code" == "200" ]]; then
    echo "[OK]       $path"
  else
    echo "[?]        $path - Status: $http_code"
  fi
done

