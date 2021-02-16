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
	"context"
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"sync"

	"github.com/golang/sync/errgroup"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"

	"istio.io/istio/pkg/config/schema/collection"
	"istio.io/istio/pkg/config/schema/collections"
	"istio.io/istio/pkg/kube"
	"istio.io/istio/pkg/test/scopes"
)

var (
	istioOperatorGVK = schema.GroupVersionResource{
		Group:    "install.istio.io",
		Version:  "v1alpha1",
		Resource: "istiooperators",
	}
	namespaceBlacklist = map[string]bool{
		"istio-system": true,
	}
	kubeResourceWhitelist = map[string]bool{
		"default": true,
	}
	istioResourceWhitelist = map[string]bool{
		"default":      true,
		"istio-system": true,
	}
)

// NewMeshSnapshot creates a new snapshot for the entire mesh.
func NewMeshSnapshot(kubeConfig string) (MeshSnapshot, error) {
	parts := strings.Split(kubeConfig, ":")

	meshSN := MeshSnapshot{}
	var mutex sync.Mutex

	var wg errgroup.Group
	for _, part := range parts {
		part := strings.TrimSpace(part)
		if len(part) == 0 {
			continue
		}

		wg.Go(func() error {
			clientCmd := kube.BuildClientCmd(part, "")

			contextName, err := getKubeContext(clientCmd)
			if err != nil {
				return fmt.Errorf("failed getting context for kubeconfig %s: %v", part, err)
			}

			client, err := kube.NewClient(clientCmd)
			if err != nil {
				return fmt.Errorf("failed creating kube client for context %s: %v", contextName, err)
			}

			clusterSN, err := newClusterSnapshot(client, contextName)
			if err != nil {
				return fmt.Errorf("failed creating snapshot for context %s: %v", contextName, err)
			}

			mutex.Lock()
			meshSN.Clusters = append(meshSN.Clusters, clusterSN)
			mutex.Unlock()
			return nil
		})
	}

	if err := wg.Wait(); err != nil {
		return MeshSnapshot{}, err
	}

	sort.Slice(meshSN.Clusters, func(i, j int) bool {
		return strings.Compare(meshSN.Clusters[i].Context, meshSN.Clusters[j].Context) < 0
	})
	return meshSN, nil
}

func newClusterSnapshot(client kube.Client, contextName string) (ClusterSnapshot, error) {
	mutex := sync.Mutex{}
	clusterSN := ClusterSnapshot{
		Context: contextName,
	}
	nilVal := ClusterSnapshot{}
	namespaces, err := client.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return nilVal, fmt.Errorf("failed listing namespaces for context %s: %v", contextName, err)
	}

	var wg errgroup.Group
	for _, ns := range namespaces.Items {
		namespace := ns.Name

		// Check whether to include the namespace in the list.
		if _, ok := namespaceBlacklist[namespace]; !ok {
			clusterSN.Namespaces = append(clusterSN.Namespaces, namespace)
		}

		includeKubeResources := kubeResourceWhitelist[namespace]
		includeIstioResources := istioResourceWhitelist[namespace]

		if !includeKubeResources && !includeIstioResources {
			// No resources are included for this namespace. Skip it.
			continue
		}

		wg.Go(func() error {
			nsSnapshot := NamespaceSnapshot{
				Namespace: namespace,
			}

			if includeKubeResources {
				// Service
				if services, err := client.CoreV1().Services(namespace).List(context.TODO(), metav1.ListOptions{}); err != nil {
					scopes.Framework.Debugf("failed listing services in namespace %s: %v", namespace, err)
				} else {
					for _, svc := range services.Items {
						nsSnapshot.Services = append(nsSnapshot.Services, svc.Name)
					}
					sort.Strings(nsSnapshot.Services)
				}

				// Deployments
				if deployments, err := client.AppsV1().Deployments(namespace).List(context.TODO(), metav1.ListOptions{}); err != nil {
					scopes.Framework.Debugf("failed listing deployments in namespace %s: %v", namespace, err)
				} else {
					for _, pod := range deployments.Items {
						nsSnapshot.Deployments = append(nsSnapshot.Deployments, pod.Name)
					}
					sort.Strings(nsSnapshot.Deployments)
				}

				// Pods
				if pods, err := client.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{}); err != nil {
					scopes.Framework.Debugf("failed listing pods in namespace %s: %v", namespace, err)
				} else {
					for _, pod := range pods.Items {
						nsSnapshot.Pods = append(nsSnapshot.Pods, pod.Name)
					}
					sort.Strings(nsSnapshot.Pods)
				}

				// ReplicaSets
				if replicaSets, err := client.AppsV1().ReplicaSets(namespace).List(context.TODO(), metav1.ListOptions{}); err != nil {
					scopes.Framework.Debugf("failed listing replicaSets in namespace %s: %v", namespace, err)
				} else {
					for _, rs := range replicaSets.Items {
						nsSnapshot.ReplicaSets = append(nsSnapshot.ReplicaSets, rs.Name)
					}
					sort.Strings(nsSnapshot.ReplicaSets)
				}

				// DaemonSets
				if daemonSets, err := client.AppsV1().DaemonSets(namespace).List(context.TODO(), metav1.ListOptions{}); err != nil {
					scopes.Framework.Debugf("failed listing daemonSets in namespace %s: %v", namespace, err)
				} else {
					for _, ds := range daemonSets.Items {
						nsSnapshot.DaemonSets = append(nsSnapshot.DaemonSets, ds.Name)
					}
					sort.Strings(nsSnapshot.DaemonSets)
				}
			}

			if includeIstioResources {
				// IstioOperator
				res := listResourceGVK(client, namespace, istioOperatorGVK)
				nsSnapshot.IstioOperators = res

				// DestinationRule
				res = listResource(client, namespace, collections.IstioNetworkingV1Alpha3Destinationrules)
				nsSnapshot.DestinationRules = res

				// EnvoyFilter
				res = listResource(client, namespace, collections.IstioNetworkingV1Alpha3Envoyfilters)
				nsSnapshot.EnvoyFilters = res

				// Gateway
				res = listResource(client, namespace, collections.IstioNetworkingV1Alpha3Gateways)
				nsSnapshot.Gateways = res

				// ServiceEntry
				res = listResource(client, namespace, collections.IstioNetworkingV1Alpha3Serviceentries)
				nsSnapshot.ServiceEntries = res

				// Sidecar
				res = listResource(client, namespace, collections.IstioNetworkingV1Alpha3Sidecars)
				nsSnapshot.Sidecars = res

				// VirtualService
				res = listResource(client, namespace, collections.IstioNetworkingV1Alpha3Virtualservices)
				nsSnapshot.VirtualServices = res

				// WorkloadEntry
				res = listResource(client, namespace, collections.IstioNetworkingV1Alpha3Workloadentries)
				nsSnapshot.WorkloadEntries = res

				// AuthorizationPolicy
				res = listResource(client, namespace, collections.IstioSecurityV1Beta1Authorizationpolicies)
				nsSnapshot.AuthorizationPolicies = res

				// PeerAuthentication
				res = listResource(client, namespace, collections.IstioSecurityV1Beta1Peerauthentications)
				nsSnapshot.PeerAuthentications = res

				// RequestAuthentications
				res = listResource(client, namespace, collections.IstioSecurityV1Beta1Requestauthentications)
				nsSnapshot.RequestAuthentications = res

				// Add the namespace snapshot to the map.
				mutex.Lock()
				clusterSN.NamespaceSnapshots = append(clusterSN.NamespaceSnapshots, nsSnapshot)
				mutex.Unlock()
			}
			return nil
		})
	}

	if err := wg.Wait(); err != nil {
		return nilVal, err
	}

	sort.Strings(clusterSN.Namespaces)
	sort.Slice(clusterSN.NamespaceSnapshots, func(i, j int) bool {
		return strings.Compare(clusterSN.NamespaceSnapshots[i].Namespace,
			clusterSN.NamespaceSnapshots[j].Namespace) < 0
	})

	return clusterSN, nil
}

func listResource(client kube.Client, ns string, s collection.Schema) []string {
	return listResourceGVK(client, ns, s.Resource().GroupVersionResource())
}

func listResourceGVK(client kube.Client, ns string, gvk schema.GroupVersionResource) []string {
	out := make([]string, 0)
	res, err := client.Dynamic().Resource(gvk).Namespace(ns).List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		scopes.Framework.Debugf("failed listing %s in namespace %s: %v", gvk.Resource, ns, err)
	} else {
		for _, r := range res.Items {
			out = append(out, r.GetName())
		}
		sort.Strings(out)
	}
	return out
}

type MeshSnapshot struct {
	Clusters []ClusterSnapshot `json:"clusters"`
}

func (s MeshSnapshot) ToJSON() (string, error) {
	out, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return "", err
	}
	return string(out), nil
}

type ClusterSnapshot struct {
	Context            string              `json:"context"`
	Namespaces         []string            `json:"namespaces"`
	NamespaceSnapshots []NamespaceSnapshot `json:"namespaceSnapshots"`
}

type NamespaceSnapshot struct {
	Namespace              string   `json:"namespace"`
	Services               []string `json:"services"`
	Deployments            []string `json:"deployments"`
	Pods                   []string `json:"pods"`
	ReplicaSets            []string `json:"replicaSets"`
	DaemonSets             []string `json:"daemonSets"`
	IstioOperators         []string `json:"istioOperators"`
	DestinationRules       []string `json:"destinationRules"`
	EnvoyFilters           []string `json:"envoyFilters"`
	Gateways               []string `json:"gateways"`
	ServiceEntries         []string `json:"serviceEntries"`
	Sidecars               []string `json:"sidecars"`
	VirtualServices        []string `json:"virtualServices"`
	WorkloadEntries        []string `json:"workloadEntries"`
	AuthorizationPolicies  []string `json:"authorizationPolicies"`
	PeerAuthentications    []string `json:"peerAuthentications"`
	RequestAuthentications []string `json:"requestAuthentications"`
}
