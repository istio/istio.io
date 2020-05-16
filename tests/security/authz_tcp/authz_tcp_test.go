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

package authztcp

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

//https://istio.io/docs/tasks/security/authorization/authz-tcp/
//https://github.com/istio/istio.io/blob/release-1.5/content/en/docs/tasks/security/authorization/authz-tcp/index.md
func TestAuthzTCP(t *testing.T) {
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__security___authz_tcp").
			Add(istioio.Script{
				Input: istioio.Inline{
					FileName: "create_ns_foo_with_tcpecho_sleep.sh",
					Value: `
source ${REPO_ROOT}/content/en/docs/tasks/security/authorization/authz-tcp/snips.sh
snip_before_you_begin_1`,
				},
			}).
			Add(istioio.MultiPodWait("foo")).
			Add(istioio.Script{
				Input: istioio.Path("scripts/authz_tcp.txt"),
			}).

			// Cleanup.
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
source ${REPO_ROOT}/content/en/docs/tasks/security/authorization/authz-tcp/snips.sh
snip_clean_up_1`,
				},
			}).
			Build())
}
