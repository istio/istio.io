// Copyright Istio Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package security

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

// TestAuthorizationForHTTPServices simulates the task in https://www.istio.io/docs/tasks/security/authz-http/
func TestAuthorizationForHTTPServices(t *testing.T) {
	//t.Skip("https://github.com/istio/istio/issues/18511")
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__security__authorization_for_http_services").
			Add(istioio.Script{
				Input: istioio.Path("scripts/authz_http.sh"),
			}).
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
set +e # ignore cleanup errors
source ${REPO_ROOT}/content/en/docs/tasks/security/authorization/authz-http/snips.sh
source ${REPO_ROOT}/tests/util/samples.sh
snip_clean_up_1
# remaining cleanup (undocumented).
cleanup_bookinfo_sample
cleanup_sleep_sample
kubectl delete -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml
`,
				},
			}).Build())
}
