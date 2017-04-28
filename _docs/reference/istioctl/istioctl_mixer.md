---
title: istioctl mixer
overview: Istio Mixer configuration
order: 7
bodyclass: docs
layout: docs
type: markdown
---
## istioctl mixer

Istio Mixer configuration

### Synopsis



The Mixer configuration API allows users to configure all facets of the
Mixer.

See https://istio.io/docs/concepts/policy-and-control/mixer-config.html
for a description of Mixer configuration's scope, subject, and rules.

Example usage:

	# The Mixer config server can be accessed from outside the
    # Kubernetes cluster using port forwarding.
    CONFIG_PORT=$(kubectl get pod -l istio=mixer \
		-o jsonpath='{.items[0].spec.containers[0].ports[1].containerPort}')
    export ISTIO_MIXER_API_SERVER=localhost:${CONFIG_PORT}
    kubectl port-forward $(kubectl get pod -l istio=mixer \
		-o jsonpath='{.items[0].metadata.name}') ${CONFIG_PORT}:${CONFIG_PORT} &


### Options

```
  -m, --mixer string   Address of the Mixer configuration server as <host>:<port>
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
* [istioctl mixer rule](istioctl_mixer_rule.html)	 - Istio Mixer Rule configuration

