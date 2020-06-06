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
	setupSpec = "profile=default"
)

func TestMain(m *testing.M) {
	if !tests.NeedSetup(setupSpec) {
		os.Exit(0)
	}
	testEnvName := environment.Name(os.Getenv("ENV"))

	framework.
		NewSuite("profile_default", m).
		SetupOnEnv(testEnvName, istio.Setup(&inst, nil)).
		Run()
}

func TestDocs(t *testing.T) {
	tests.TestDocs(t, setupSpec)
}
