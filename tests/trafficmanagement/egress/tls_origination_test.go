package egress

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

func TestTlsOrigination(t *testing.T) {
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__traffic_management__egress_tls_origination").
			Add(istioio.Script{
				Input: istioio.Path("scripts/tls_origination.sh"),
			}).
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
set +e # ignore cleanup errors
source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/egress/egress-tls-origination/snips.sh"
snip_cleanup_1
snip_cleanup_2`,
				},
			}).
			Build())
}
