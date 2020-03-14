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
	"istio.io/istio/pkg/test/framework/components/istio"
	"istio.io/istio/pkg/test/framework/label"
	"istio.io/istio/pkg/test/framework/resource/environment"
)

var (
	inst istio.Instance
)

func TestMain(m *testing.M) {
	// Integration test for the ingress SDS Gateway flow.
	framework.
		NewSuite("trafficmanagement_ingress", m).
		Label(label.CustomSetup).
		SetupOnEnv(environment.Kube, istio.Setup(&inst, setupForSDS)).
		RequireEnvironment(environment.Kube).
		Run()

}

func setupForSDS(cfg *istio.Config) {
	if cfg == nil {
		return
	}
	cfg.Values["gateways.istio-egressgateway.enabled"] = "false"
}
