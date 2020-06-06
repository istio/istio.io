package setupconfig

import (
	"os"
	"testing"

	"istio.io/istio.io/tests"
	"istio.io/istio/pkg/test/framework"
)

var (
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
