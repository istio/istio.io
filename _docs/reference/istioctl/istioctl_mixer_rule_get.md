---
title: istioctl mixer rule get
overview: Get Istio Mixer rules
order: 9
layout: docs
type: markdown
---
## istioctl mixer rule get

Get Istio Mixer rules

### Synopsis



Get a Mixer rule for a given scope and subject.

Example usage:

	# Get the Mixer rule with scope='global' and subject='myservice.ns.svc.cluster.local'
    istioctl mixer rule get global myservice.ns.svc.cluster.local


```
istioctl mixer rule get
```

### Options inherited from parent commands

```
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -m, --mixer string                     Address of the Mixer configuration server as <host>:<port>
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

### SEE ALSO
* [istioctl mixer rule](istioctl_mixer_rule.html)	 - Istio Mixer Rule configuration

