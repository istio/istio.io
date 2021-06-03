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
	"errors"
	"fmt"
	"sort"
	"strings"

	"k8s.io/client-go/tools/clientcmd"

	"istio.io/istio/pkg/test/framework"
	"istio.io/istio/pkg/test/framework/components/environment/kube"
)

func getKubeConfig(ctx framework.TestContext) string {
	kubeEnv := ctx.Environment().(*kube.Environment)
	if ctx.Clusters().IsMulticluster() {
		return strings.Join(kubeEnv.Settings().KubeConfig, ":")
	}
	return kubeEnv.Settings().KubeConfig[0]
}

func getKubeContext(clientCmd clientcmd.ClientConfig) (string, error) {
	raw, err := clientCmd.RawConfig()
	if err != nil {
		return "", fmt.Errorf("failed retrieving raw config: %v", err)
	}
	if len(raw.CurrentContext) != 0 {
		return raw.CurrentContext, nil
	}

	// Gather all the context names and sort.
	contexts := make([]string, 0, len(raw.Contexts))
	for name := range raw.Contexts {
		contexts = append(contexts, name)
	}
	sort.Strings(contexts)

	if len(contexts) > 0 {
		return contexts[0], nil
	}
	return "", errors.New("no contexts available")
}
