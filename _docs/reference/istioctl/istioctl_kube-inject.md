---
title: istioctl kube-inject
overview: Inject Envoy sidecar into Kubernetes pod resources
order: 5
layout: docs
type: markdown
---
## istioctl kube-inject

Inject Envoy sidecar into Kubernetes pod resources

### Synopsis




Automatic Envoy sidecar injection via k8s admission controller is not
ready yet. Instead, use kube-inject to manually inject Envoy sidecar
into Kubernetes resource files. Unsupported resources are left
unmodified so it is safe to run kube-inject over a single file that
contains multiple Service, ConfigMap, Deployment, etc. definitions for
a complex application. Its best to do this when the resource is
initially created.

k8s.io/docs/concepts/workloads/pods/pod-overview/#pod-templates is
updated for Job, DaemonSet, ReplicaSet, and Deployment YAML resource
documents. Support for additional pod-based resource types can be
added as necessary.

The Istio project is continually evolving so the Istio sidecar
configuration may change unannounced. When in doubt re-run istioctl
kube-inject on deployments to get the most up-to-date changes.

Example usage:

	# Update resources on the fly before applying.
	kubectl apply -f <(istioctl kube-inject -f <resource.yaml>)

	# Create a persistent version of the deployment with Envoy sidecar
	# injected. This is particularly useful to understand what is
	# being injected before committing to Kubernetes API server.
	istioctl kube-inject -f deployment.yaml -o deployment-with-istio.yaml

	# Update an existing deployment.
	kubectl get deployment -o yaml | istioctl kube-inject -f - | kubectl apply -f -



```
istioctl kube-inject
```

### Options

```
      --coreDump                  Enable/Disable core dumps in injected Envoy sidecar (--coreDump=true affects all pods in a node and should only be used the cluster admin) (default true)
  -f, --filename string           Input Kubernetes resource filename
      --hub string                Docker hub
      --includeIPRanges string    Comma separated list of IP ranges in CIDR form. If set, only redirect outbound traffic to Envoy for IP ranges. Otherwise all outbound traffic is redirected
      --meshConfig string         ConfigMap name for Istio mesh configuration, key should be "mesh" (default "istio")
  -o, --output string             Modified output Kubernetes resource filename
      --setVersionString string   Override version info injected into resource
      --sidecarProxyUID int       Envoy sidecar UID (default 1337)
      --tag string                Docker tag
      --verbosity int             Runtime verbosity (default 2)
```

### Options inherited from parent commands

```
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

### SEE ALSO
* [istioctl](istioctl.html)	 - Istio control interface

