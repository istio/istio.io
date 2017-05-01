---
title: istioctl delete
overview: Delete policies or rules
order: 3
layout: docs
type: markdown
---
## istioctl delete

Delete policies or rules

### Synopsis



Example usage:

	# Delete a rule using the definition in example-routing.yaml.
	$ istioctl delete -f example-routing.yaml

	# Delete the rule productpage-default
	$ istioctl delete route-rule productpage-default


```
istioctl delete
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

