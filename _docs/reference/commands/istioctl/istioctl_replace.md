---
title: istioctl replace
overview: Replace existing policies and rules
order: 11
layout: docs
type: markdown
---
## istioctl replace

Replace existing policies and rules

### Synopsis



Example usage:

	# Create a rule using the definition in example-routing.yaml.
	istioctl replace -f example-routing.yaml


```
istioctl replace
```

### Options

```
  -f, --file string   Input file with the content of the configuration objects (if not set, command reads from the standard input)
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

