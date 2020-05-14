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

package ingress

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

func TestSecureIngress(t *testing.T) {
	// Check the version of curl. This test requires the --retry-connrefused arg.
	curl.RequireMinVersionOrFail(t, semver.MustParse("7.52.0"))
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__traffic_management__secure_ingress").
			Add(istioio.Script{
				Input: istioio.Path("scripts/secure_ingress.sh"),
			}).
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
set +e # ignore cleanup errors
source ${REPO_ROOT}/content/en/docs/tasks/traffic-management/ingress/secure-ingress/snips.sh
snip_cleanup_1
snip_cleanup_2
snip_cleanup_3`,
				},
			}).
			Build())
}
