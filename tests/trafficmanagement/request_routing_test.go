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

package trafficmanagement

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

func TestRequestRouting(t *testing.T) {
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__traffic_management__request_routing").
			Add(istioio.Script{
				Input: istioio.Path("scripts/request_routing.sh"),
			}).
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
set +e # ignore cleanup errors
source ${REPO_ROOT}/content/en/docs/tasks/traffic-management/request-routing/snips.sh
source ${REPO_ROOT}/tests/util/samples.sh
snip_cleanup_1
cleanup_bookinfo_sample
cleanup_sleep_sample`,
				},
			}).
			Build())
}
