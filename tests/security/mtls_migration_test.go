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

	"istio.io/istio.io/pkg/test/istioio"
)

//https://istio.io/docs/tasks/security/mtls-migration/
//https://github.com/istio/istio.io/blob/release-1.2/content/docs/tasks/security/mtls-migration/index.md
func TestMutualTLSMigration(t *testing.T) {

	framework.
		NewTest(t).
		Run(istioio.NewBuilder("tasks__security__mututal_tls_migration").
			Add(istioio.Script{
				Input: istioio.Inline{
					FileName: "create_ns_foo_bar_legacy.sh",
					Value: `
set -e
set -u
set -o pipefail
source ${REPO_ROOT}/content/en/docs/tasks/security/authentication/mtls-migration/snips.sh
# create_ns_foo_bar_legacy
snip_set_up_the_cluster_1
snip_set_up_the_cluster_2`,
				},
			}).

			// Wait for pods to start.
			Add(istioio.MultiPodWait("foo"),
				istioio.MultiPodWait("bar"),
				istioio.MultiPodWait("legacy")).
			Add(istioio.Script{
				Input: istioio.Path("scripts/mtls_migration.txt"),
			}).
			// Cleanup.
			Defer(istioio.Script{
				Input: istioio.Inline{
					FileName: "cleanup.sh",
					Value: `
source ${REPO_ROOT}/content/en/docs/tasks/security/authentication/mtls-migration/snips.sh
snip_clean_up_the_example_2`,
				},
			}).
			Build())
}
