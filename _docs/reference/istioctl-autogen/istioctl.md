---
category: Reference
title: Istioctl
overview: Istio control interface
index: true
bodyclass: docs
layout: docs
type: markdown
---
## istioctl

Istio control interface

### Synopsis


Istio configuration command line utility. Available configuration types: [destination-policy ingress-rule route-rule]

### Options

```
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

### SEE ALSO
* [istioctl completion](istioctl_completion.html)	 - Generate bash completion for Istioctl
* [istioctl create](istioctl_create.html)	 - Create policies and rules
* [istioctl delete](istioctl_delete.html)	 - Delete policies or rules
* [istioctl get](istioctl_get.html)	 - Retrieve a policy or rule
* [istioctl kube-inject](istioctl_kube-inject.html)	 - Inject istio sidecar proxy into kubernetes resources
* [istioctl mixer](istioctl_mixer.html)	 - Istio Mixer configuration
* [istioctl replace](istioctl_replace.html)	 - Replace policies and rules
* [istioctl version](istioctl_version.html)	 - Display version information and exit
