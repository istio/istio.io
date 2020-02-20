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
	"istio.io/istio/pkg/test/istioio"
)

// TestHTTPSOverlayMtlEnabled simulates the task in docs/tasks/security/authentication/https-overlay/
// with a sidecar and global mTLS is enabled
func TestHTTPSOverlayMtlEnabled(t *testing.T) {
	framework.
		NewTest(t).
		Run(istioio.NewBuilder("ops__security__authentication__https_overlay").
			Add(istioio.Script{
				Input: istioio.Path("../scripts/https_overlay_setup.txt"),
			}).
			Add(istioio.Script{
				Input: istioio.Path("../scripts/https_overlay_with_sidecar_global_mtls_enabled.txt"),
			}).
			Defer(istioio.Script{
				Input: istioio.Path("../scripts/https_overlay_cleanup.txt"),
			}).
			Build())
}
