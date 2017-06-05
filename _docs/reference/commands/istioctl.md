---
title: istioctl
overview: Istio control interface
layout: docs
order: 1
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

	[destination-policy ingress-rule route-rule]

See http://istio.io/docs/reference for an overview of routing rules
and destination policies.

More information on Mixer's API configuration can be found under the
istioctl mixer command documentation.


### Options

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
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
istioctl completion
```

### Examples

```

# Add the following to .bash_profile.
source <(istioctl completion)

# Create a separate completion file and source that from .bash_profile
istioctl completion > ~/.istioctl-complete.bash
echo "source ~/.istioctl-complete.bash" >> ~/.bash_profile

```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_create"></a>
## istioctl create

Create policies and rules

### Synopsis


Create policies and rules

```
istioctl create
```

### Examples

```

istioctl create -f example-routing.yaml

```

### Options

```
  -f, --file string   Input file with the content of the configuration objects (if not set, command reads from the standard input)
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_delete"></a>
## istioctl delete

Delete policies or rules

### Synopsis


Delete policies or rules

```
istioctl delete
```

### Examples

```

# Delete a rule using the definition in example-routing.yaml.
istioctl delete -f example-routing.yaml

# Delete the rule productpage-default
istioctl delete route-rule productpage-default

```

### Options

```
  -f, --file string   Input file with the content of the configuration objects (if not set, command reads from the standard input)
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_get"></a>
## istioctl get

Retrieve policies and rules

### Synopsis


Retrieve policies and rules

```
istioctl get
```

### Examples

```

# List all route rules
istioctl get route-rules

# List all destination policies
istioctl get destination-policies

# Get a specific rule named productpage-default
istioctl get route-rule productpage-default

```

### Options

```
  -o, --output string   Output format. One of:yaml|short (default "short")
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
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
istioctl kube-inject
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
      --coreDump                  Enable/Disable core dumps in injected Envoy sidecar (--coreDump=true affects all pods in a node and should only be used the cluster admin) (default true)
  -f, --filename string           Input Kubernetes resource filename
      --hub string                Docker hub
      --includeIPRanges string    Comma separated list of IP ranges in CIDR form. If set, only redirect outbound traffic to Envoy for IP ranges. Otherwise all outbound traffic is redirected
      --meshConfig string         ConfigMap name for Istio mesh configuration, key should be "mesh" (default "istio")
  -o, --output string             Modified output Kubernetes resource filename
      --setVersionString string   Override version info injected into resource
      --sidecarProxyUID int       Envoy sidecar UID (default 1337)
      --tag string                Docker tag
      --verbosity int             Runtime verbosity (default 2)
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_mixer"></a>
## istioctl mixer

Istio Mixer configuration

### Synopsis



The Mixer configuration API allows users to configure all facets of the
Mixer.

See [mixer-config]({{home}}/docs/concepts/policy-and-control/mixer-config.html)
for a description of Mixer configuration's scope, subject, and rules.


### Options

```
      --mixer string             (deprecated) Address of the Mixer configuration server as <host>:<port>
      --mixerAPIService string   Name of istio-mixer service. When --kube=false this sets Mixer's address (default "istio-mixer:9094")
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_mixer_rule_create"></a>
## istioctl mixer rule create

Create Istio Mixer rules

### Synopsis


Create Istio Mixer rules

```
istioctl mixer rule create
```

### Examples

```

# Create a new Mixer rule for the given scope and subject.
istioctl mixer rule create global myservice.ns.svc.cluster.local -f mixer-rule.yml

```

### Options

```
  -f, --file string   Input file with contents of the Mixer rule
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
      --mixer string                     (deprecated) Address of the Mixer configuration server as <host>:<port>
      --mixerAPIService string           Name of istio-mixer service. When --kube=false this sets the Mixer's address (default 
      "istio-mixer:9094")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_mixer_rule_get"></a>
## istioctl mixer rule get

Get Istio Mixer rules

### Synopsis



Get a Mixer rule for a given scope and subject.


```
istioctl mixer rule get
```

### Examples

```

# Get the Mixer rule with scope='global' and subject='myservice.ns.svc.cluster.local'
istioctl mixer rule get global myservice.ns.svc.cluster.local

```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
      --mixer string                     (deprecated) Address of the Mixer configuration server as <host>:<port>
      --mixerAPIService string           Name of istio-mixer service. When --kube=false this sets Mixer's address (default 
      "istio-mixer:9094")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_mixer_rule"></a>
## istioctl mixer rule

Istio Mixer Rule configuration

### Synopsis



Create and list Mixer rules in the configuration server.


### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
      --mixer string                     (deprecated) Address of the Mixer configuration server as <host>:<port>
      --mixerAPIService string           Name of istio-mixer service. When --kube=false this sets Mixer's address (default "istio-mixer:9094")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_replace"></a>
## istioctl replace

Replace existing policies and rules

### Synopsis


Replace existing policies and rules

```
istioctl replace
```

### Examples

```

istioctl replace -f example-routing.yaml

```

### Options

```
  -f, --file string   Input file with the content of the configuration objects (if not set, command reads from the standard input)
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="istioctl_version"></a>
## istioctl version

Display version information and exit

### Synopsis


Display version information and exit

```
istioctl version
```

### Options inherited from parent commands

```
      --kube                             Use Kubernetes client to send API requests to Pilot service (default true)
  -c, --kubeconfig string                Use a Kubernetes configuration file instead of in-cluster configuration
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --configAPIservice string          Name of Pilot service. When --kube=false this sets the address of the Pilot service (default "istio-pilot:8081")
  -n, --namespace string                 Select a Kubernetes namespace (default "default")
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

