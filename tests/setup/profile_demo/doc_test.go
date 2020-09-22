// Copyright 2020 Istio Authors
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
package setupconfig

import (
	"os"
	"testing"

	"istio.io/istio.io/pkg/test/istioio"
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/framework/components/istio"
	"istio.io/istio/pkg/test/framework/resource"
)

var (
	inst      istio.Instance
	setupSpec = "profile=demo"
)

func TestMain(m *testing.M) {
	if !istioio.NeedSetup(setupSpec) {
		os.Exit(0)
	}

	framework.
		NewSuite(m).
		Setup(istio.Setup(&inst, setupConfig)).
		RequireSingleCluster().
		Run()
}

func TestDocs(t *testing.T) {
	istioio.TestDocs(t, setupSpec)
}

func setupConfig(ctx resource.Context, cfg *istio.Config) {
	cfg.ControlPlaneValues = "profile: demo"
}
