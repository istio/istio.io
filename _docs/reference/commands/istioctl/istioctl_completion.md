---
title: istioctl completion
overview: Generate bash completion for Istioctl
order: 13
layout: docs
type: markdown
---
## istioctl completion

Generate bash completion for Istioctl

### Synopsis



Output shell completion code for the bash shell. The shell output must
be evaluated to provide interactive completion of istioctl
commands.

Examples:

    # Add the following to .bash_profile.
    source <(istioctl completion)

    # Create a separate completion file and source that from .bash_profile
    istioctl completion > ~/.istioctl-complete.bash
    echo "source ~/.istioctl-complete.bash" >> ~/.bash_profile


```
istioctl completion
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

