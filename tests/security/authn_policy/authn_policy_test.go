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

package authnpolicy

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

//https://istio.io/docs/tasks/security/authentication/authn-policy/
//https://github.com/istio/istio.io/blob/release-1.5/content/en/docs/tasks/security/authentication/authn-policy/index.md
func TestAuthnPolicy(t *testing.T) {
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__security___authn_policy").
			Add(istioio.Script{
				Input: istioio.Path("scripts/authn_policy.sh"),
			}).

			// Cleanup.
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
set +e # ignore cleanup errors
source ${REPO_ROOT}/content/en/docs/tasks/security/authentication/authn-policy/snips.sh
snip_cleanup_part_1_1
snip_cleanup_part_2_1
snip_cleanup_part_3_1
snip_cleanup_part_3_2
snip_cleanup_part_3_3`,
				},
			}).
			Build())
}
