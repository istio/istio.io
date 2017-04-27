---
category: Reference
title: Inject istio sidecar proxy into kubernetes resources
overview: Inject istio sidecar proxy into kubernetes resources
parent: Istioctl
bodyclass: docs
layout: docs
type: markdown
---
## istioctl kube-inject

Inject istio sidecar proxy into kubernetes resources

### Synopsis



Use kube-inject to manually inject istio sidecar proxy into kubernetes
resource files. Unsupported resources are left unmodified so it is
safe to run kube-inject over a single file that contains multiple
Service, ConfigMap, Deployment, etc. definitions for a complex
application. Its best to do this when the resource is initially
created.

Example usage:

	kubectl apply -f <(istioctl kube-inject -f <resource.yaml>)


```
istioctl kube-inject
```

### Options

```
      --coreDump                  Enable/Disable core dumps in injected proxy (--coreDump=true affects all pods in a node and should only be used the cluster admin) (default true)
  -f, --filename string           Input kubernetes resource filename
      --hub string                Docker hub
      --includeIPRanges string    Comma separated list of IP ranges in CIDR form. If set, only redirect outbound traffic to Envoy for IP ranges. Otherwise all outbound traffic is redirected
      --meshConfig string         ConfigMap name for Istio mesh configuration, key should be "mesh" (default "istio")
  -o, --output string             Modified output kubernetes resource filename
      --setVersionString string   Override version info injected into resource
      --sidecarProxyUID int       Sidecar proxy UID (default 1337)
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

