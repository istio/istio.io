# Setup Configs for istio.io Doc Tests

Each folder under `tests/setup` corresponds to an istio setup configuration. Currently supported setup configurations include: `profile_default` to install the default profile, `profile_demo` to install the demo profile, and `profile_none` to not installing istio at all.

## Adding a Setup Config

To add a setup configuration, create a new go file `tests/setup/<your_config_name>/doc_test.go` using the following template. Three modifications are required.

```go
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

	"istio.io/istio.io/tests"
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/framework/components/istio"
	"istio.io/istio/pkg/test/framework/resource/environment"
)

var (
	inst      istio.Instance
	setupSpec = "profile=demo" // this is to appear in test scripts following '# @setup'
)

func TestMain(m *testing.M) {
	if !tests.NeedSetup(setupSpec) {
		os.Exit(0)
	}
	testEnvName := environment.Name(os.Getenv("ENV"))

	framework.
		NewSuite("profile_demo", m). // test suite name
		SetupOnEnv(testEnvName, istio.Setup(&inst, setupConfig)).
		Run()
}

func TestDocs(t *testing.T) {
	tests.TestDocs(t, setupSpec)
}

func setupConfig(cfg *istio.Config) {
	// specify what your config requires
}
```
