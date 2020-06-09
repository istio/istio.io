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
	setupSpec = "profile=default setup=dns_cert"
)

func TestMain(m *testing.M) {
	if !tests.NeedSetup(setupSpec) {
		os.Exit(0)
	}
	testEnvName := environment.Name(os.Getenv("ENV"))

	framework.
		NewSuite("profile_default_setup_dns_cert", m).
		SetupOnEnv(testEnvName, istio.Setup(&inst, setupConfig)).
		Run()
}

func TestDocs(t *testing.T) {
	tests.TestDocs(t, setupSpec)
}

func setupConfig(cfg *istio.Config) {
	if cfg == nil {
		return
	}
	cfg.ControlPlaneValues = `
values:
  meshConfig:
    certificates:
      - secretName: dns.example1-service-account
        dnsNames: [example1.istio-system.svc, example1.istio-system]
      - secretName: dns.example2-service-account
        dnsNames: [example2.istio-system.svc, example2.istio-system]
`
}
