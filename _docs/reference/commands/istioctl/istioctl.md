---
title: istioctl
overview: Istio control interface
order: 1
layout: docs
type: markdown
---
## istioctl

Istio control interface

### Synopsis



Istio configuration command line utility.

Create, list, modify, and delete configuration resources in the Istio system.

Available routing and traffic management configuration types: [destination-policy ingress-rule route-rule]. See
[here](/docs/reference/traffic-management/routing-and-traffic-management.html)
for an overview of the routing and traffic DSL.

More information on the mixer API configuration can be found under the
istioctl mixer command documentation.


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
* [istioctl get](istioctl_get.html)	 - Retrieve policies and rules
* [istioctl kube-inject](istioctl_kube-inject.html)	 - Inject Envoy sidecar into Kubernetes pod resources
* [istioctl mixer](istioctl_mixer.html)	 - Istio Mixer configuration
* [istioctl replace](istioctl_replace.html)	 - Replace existing policies and rules
* [istioctl version](istioctl_version.html)	 - Display version information and exit

