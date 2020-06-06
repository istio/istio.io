package setupconfig

import (
	"os"
	"testing"

	"istio.io/istio.io/tests"
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/framework/components/istio"
)

var (
	inst      istio.Instance
	setupSpec = "profile=none"
)

func TestMain(m *testing.M) {
	if !tests.NeedSetup(setupSpec) {
		os.Exit(0)
	}
	framework.NewSuite("profile_none", m).Run()
}

func TestDocs(t *testing.T) {
	tests.TestDocs(t, setupSpec)
}
