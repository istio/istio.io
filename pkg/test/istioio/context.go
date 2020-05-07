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

package istioio

import (
	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/framework/components/environment/kube"
)

// Context for the currently executing test.
type Context struct {
	framework.TestContext
}

// KubeEnv casts the test environment as a *kube.Environment. If the cast fails, fails the test.
func (ctx Context) KubeEnv() *kube.Environment {
	e, ok := ctx.Environment().(*kube.Environment)
	if !ok {
		ctx.Fatalf("test framework unable to get Kubernetes environment")
	}
	return e
}
