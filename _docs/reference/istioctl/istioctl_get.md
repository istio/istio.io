---
title: istioctl get
overview: Retrieve policies and rules
order: 4
bodyclass: docs
layout: docs
type: markdown
---
## istioctl get

Retrieve policies and rules

### Synopsis



Example usage:

	# List all route rules
	istioctl get route-rules

	# List all destination policies
	istioctl get destination-policies

	# Get a specific rule named productpage-default
	istioctl get route-rule productpage-default


```
istioctl get
```

### Options

```
  -o, --output string   Output format. One of:yaml|short (default "short")
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

