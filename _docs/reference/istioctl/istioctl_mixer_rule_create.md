---
title: istioctl mixer rule create
overview: Create Istio Mixer rules
order: 8
bodyclass: docs
layout: docs
type: markdown
---
## istioctl mixer rule create

Create Istio Mixer rules

### Synopsis



Example usage:

    # Create a new Mixer rule for the given scope and subject.
    istioctl mixer rule create global myservice.ns.svc.cluster.local -f mixer-rule.yml


```
istioctl mixer rule create
```

### Options

```
  -f, --file string   Input file with contents of the Mixer rule
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

