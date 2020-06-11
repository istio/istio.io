// Copyright Istio Authors. All Rights Reserved.
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

package egress

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

func TestGatewayTlsOrigination(t *testing.T) {
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__traffic_management__egress_gateways_tls_origination").
			Add(istioio.Script{
				Input: istioio.Path("scripts/gateway_tls_origination.sh"),
			}).
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
set +e # ignore cleanup errors
source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/snips.sh"
snip_cleanup_the_tls_origination_example_1,
snip_cleanup_the_tls_origination_example_2`,
				},
			}).
			Build())
}
