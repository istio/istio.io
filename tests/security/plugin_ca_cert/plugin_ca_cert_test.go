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

package plugincacert

import (
	"testing"

	"istio.io/istio/pkg/test/framework"

	"istio.io/istio.io/pkg/test/istioio"
)

//https://istio.io/docs/tasks/security/plugin-ca-cert/
//https://github.com/istio/istio.io/blob/release-1.5/content/en/docs/tasks/security/plugin-ca-cert/index.md
func TestPluginCACert(t *testing.T) {

	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__security___plugin_ca_cert").
			Add(istioio.Script{
				Input: istioio.Inline{
					FileName: "create_ns_foo_with_httpbin_sleep.sh",
					Value: `
set -e
set -u
set -o pipefail
source ${REPO_ROOT}/content/en/docs/tasks/security/plugin-ca-cert/snips.sh
# create_ns_foo_with_httpbin_sleep
snip_deploying_example_services_1
snip_deploying_example_services_2`,
				},
			}).
			// Wait for pods to start.
			Add(istioio.MultiPodWait("foo")).
			Add(istioio.Script{
				Input: istioio.Path("scripts/plugin_ca_cert.txt"),
			}).
			// Cleanup.
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
source ${REPO_ROOT}/content/en/docs/tasks/security/plugin-ca-cert/snips.sh
snip_cleanup_1`,
				},
			}).
			Build())
}
