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
	"istio.io/istio/pkg/test/framework/components/istio"
	"istio.io/istio/pkg/test/framework/label"
	"istio.io/istio/pkg/test/framework/resource/environment"
)

var (
	ist istio.Instance
)

func TestMain(m *testing.M) {
	framework.NewSuite("security", m).
		Label(label.CustomSetup).
		SetupOnEnv(environment.Kube, istio.Setup(&ist, setupConfig)).
		RequireEnvironment(environment.Kube).
		Run()
}

//grafana is disabled in the default test framework config. Enable it.
func setupConfig(cfg *istio.Config) {
	if cfg == nil {
		return
	}

	cfg.Values["grafana.enabled"] = "true"
}
