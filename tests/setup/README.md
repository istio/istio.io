# Setup Configs for istio.io Doc Tests

Each folder under `tests/setup` corresponds to an istio setup configuration. Currently supported setup configurations include: `profile_default` to install the default profile, `profile_demo` to install the demo profile, `profile_minimal` to install the minimal profile and `profile_none` to not install istio at all.

## Adding a Setup Config

To add a setup configuration, create a new go file `tests/setup/<your_config_name>/doc_test.go` using the following template. Two modifications are required.

```go
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
package setupconfig

import (
	"os"
	"testing"

	"istio.io/istio.io/pkg/test/istioio"
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/framework/components/istio"
)

var (
	inst      istio.Instance
	setupSpec = "profile=demo" // this is to appear in test scripts following '# @setup'
)

func TestMain(m *testing.M) {
	if !istioio.NeedSetup(setupSpec) {
		os.Exit(0)
	}

	framework.
		NewSuite(m).
		Setup(istio.Setup(&inst, setupConfig)).
		Run()
}

func TestDocs(t *testing.T) {
	istioio.TestDocs(t, setupSpec)
}

func setupConfig(cfg *istio.Config) {
	// specify what your config requires
}
```
