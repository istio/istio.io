---
title: istioctl
overview: Istio control interface
layout: docs
order: 20
type: markdown
---

<a name="istioctl_cmd"></a>
## istioctl

Istio control interface

### Synopsis



Istio configuration command line utility.

Create, list, modify, and delete configuration resources in the Istio
system.

Available routing and traffic management configuration types:

	[route-rule ingress-rule egress-rule destination-policy]

See http://istio.io/docs/reference for an overview of routing rules
and destination policies.



### Options

```
  -h, --help                             help for istioctl
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_completion"></a>
## istioctl completion

Generate bash completion for Istioctl

### Synopsis



Output shell completion code for the bash shell. The shell output must
be evaluated to provide interactive completion of istioctl
commands.

```
istioctl completion [flags]
```

### Examples

```

# Add the following to .bash_profile.
source <(istioctl completion)

# Create a separate completion file and source that from .bash_profile
istioctl completion > ~/.istioctl-complete.bash
echo "source ~/.istioctl-complete.bash" >> ~/.bash_profile

```

### Options

```
  -h, --help   help for completion
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_context-create"></a>
## istioctl context-create

Create a kubeconfig file suitable for use with istioctl in a non kubernetes environment

### Synopsis


Create a kubeconfig file suitable for use with istioctl in a non kubernetes environment

```
istioctl context-create --api-server http://<ip>:<port> [flags]
```

### Examples

```
# Create a config file for the api server.
istioctl context-create --api-server http://127.0.0.1:8080
```

### Options

```
      --api-server string   URL for Istio api server
      --context string      Kubernetes configuration file context name (default "istio")
  -h, --help                help for context-create
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_create"></a>
## istioctl create

Create policies and rules

### Synopsis


Create policies and rules

```
istioctl create [flags]
```

### Examples

```
istioctl create -f example-routing.yaml
```

### Options

```
  -f, --file string   Input file with the content of the configuration objects (if not set, command reads from the standard input)
  -h, --help          help for create
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_delete"></a>
## istioctl delete

Delete policies or rules

### Synopsis


Delete policies or rules

```
istioctl delete <type> <name> [<name2> ... <nameN>] [flags]
```

### Examples

```
# Delete a rule using the definition in example-routing.yaml.
istioctl delete -f example-routing.yaml

# Delete the rule productpage-default
istioctl delete routerule productpage-default
```

### Options

```
  -f, --file string   Input file with the content of the configuration objects (if not set, command reads from the standard input)
  -h, --help          help for delete
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_get"></a>
## istioctl get

Retrieve policies and rules

### Synopsis


Retrieve policies and rules

```
istioctl get <type> [<name>] [flags]
```

### Examples

```
# List all route rules
istioctl get routerules

# List all destination policies
istioctl get destinationpolicies

# Get a specific rule named productpage-default
istioctl get routerule productpage-default
```

### Options

```
  -h, --help            help for get
  -o, --output string   Output format. One of:yaml|short (default "short")
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_kube-inject"></a>
## istioctl kube-inject

Inject Envoy sidecar into Kubernetes pod resources

### Synopsis




Automatic Envoy sidecar injection via k8s admission controller is not
ready yet. Instead, use kube-inject to manually inject Envoy sidecar
into Kubernetes resource files. Unsupported resources are left
unmodified so it is safe to run kube-inject over a single file that
contains multiple Service, ConfigMap, Deployment, etc. definitions for
a complex application. Its best to do this when the resource is
initially created.

k8s.io/docs/concepts/workloads/pods/pod-overview/#pod-templates is
updated for Job, DaemonSet, ReplicaSet, and Deployment YAML resource
documents. Support for additional pod-based resource types can be
added as necessary.

The Istio project is continually evolving so the Istio sidecar
configuration may change unannounced. When in doubt re-run istioctl
kube-inject on deployments to get the most up-to-date changes.


```
istioctl kube-inject [flags]
```

### Examples

```

# Update resources on the fly before applying.
kubectl apply -f <(istioctl kube-inject -f <resource.yaml>)

# Create a persistent version of the deployment with Envoy sidecar
# injected. This is particularly useful to understand what is
# being injected before committing to Kubernetes API server.
istioctl kube-inject -f deployment.yaml -o deployment-with-istio.yaml

# Update an existing deployment.
kubectl get deployment -o yaml | istioctl kube-inject -f - | kubectl apply -f -

```

### Options

```
      --coreDump                   Enable/Disable core dumps in injected Envoy sidecar (--coreDump=true affects all pods in a node and should only be used the cluster admin) (default true)
      --debug                      Use debug images and settings for the sidecar (default true)
  -f, --filename string            Input Kubernetes resource filename
  -h, --help                       help for kube-inject
      --hub string                 Docker hub (default "docker.io/istio")
      --imagePullPolicy string     Sets the container image pull policy. Valid options are Always,IfNotPresent,Never.The default policy is IfNotPresent. (default "IfNotPresent")
      --includeIPRanges string     Comma separated list of IP ranges in CIDR form. If set, only redirect outbound traffic to Envoy for IP ranges. Otherwise all outbound traffic is redirected
      --meshConfigMapName string   ConfigMap name for Istio mesh configuration, key should be "mesh" (default "istio")
  -o, --output string              Modified output Kubernetes resource filename
      --setVersionString string    Override version info injected into resource
      --sidecarProxyUID int        Envoy sidecar UID (default 1337)
      --tag string                 Docker tag (default "c371d111adb3da6f4edf0091716380ab97087886")
      --verbosity int              Runtime verbosity (default 2)
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_register"></a>
## istioctl register

Registers a service instance (e.g. VM) joining the mesh

### Synopsis


Registers a service instance (e.g. VM) joining the mesh

```
istioctl register <svcname> <ip> [name1:]port1 [name2:]port2 ... [flags]
```

### Options

```
  -a, --annotations stringSlice   List of string annotations to apply if creating a service/endpoint; e.g. -a foo=bar,test,x=y
  -h, --help                      help for register
  -l, --labels stringSlice        List of labels to apply if creating a service/endpoint; e.g. -l env=prod,vers=2
  -s, --serviceaccount string     Service account to link to the service (default "default")
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_replace"></a>
## istioctl replace

Replace existing policies and rules

### Synopsis


Replace existing policies and rules

```
istioctl replace [flags]
```

### Examples

```
istioctl replace -f example-routing.yaml	
```

### Options

```
  -f, --file string   Input file with the content of the configuration objects (if not set, command reads from the standard input)
  -h, --help          help for replace
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_version"></a>
## istioctl version

Display version information

### Synopsis


Display version information

```
istioctl version [flags]
```

### Options

```
  -h, --help   help for version
```

### Options inherited from parent commands

```
  -i, --istioNamespace string            Istio system namespace (default "istio-system")
  -c, --kubeconfig string                Kubernetes configuration file (default "/home/kuat/.kube/config")
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
  -n, --namespace string                 Config namespace (default "default")
  -p, --platform string                  Istio host platform (default "kube")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

