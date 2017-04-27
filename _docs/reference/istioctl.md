---
title: The istioctl Command
overview: Describes the usage and options of the istioctl command-line tool.
          
order: 10

bodyclass: docs
layout: docs
type: markdown
---

**istioctl** is a command line interface for managing an Istio service mesh.  This overview covers
syntax, describes command operations, and provides examples.

# Syntax

*istioctl* commands follow the syntax:

```shell
istioctl <command> [targets] [flags]
```

where *command*, *targets* and *flags* are:

* **command**: the operation to perform, such as `create`, `delete`, `replace`, or `get`.
* **targets**: targets for commands such as delete
* **flags**: Optional flags.  For example specify `--file FILENAME` to specify a configuration file to create from.

# Operations

* **create**: Create policies and rules
* **delete**: Delete policies or rules
* **get**: Retrieve policy/policies or rules
* **replace**: Replace policies and rules
* **version**: Display CLI version information

_Kubernetes specific_
* **kube-inject**: Inject Envoy proxy into Kubernetes Pods
  resources. This command has been added to aid in *istiofying*
  services for Kubernetes and should eventually go away once a proper
  Istio admission controller for Kubernetes is available.

# Policy and Rule types

* **route-rule** Describes a rule for routing network traffic.  See [Route Rules](/docs/reference/routing-and-traffic-management.html#route-rules) for details on routing rules.
* **destination-policy** Describes a policy for traffic destinations. See [Destination Policies](/docs/reference/routing-and-traffic-management.html#destination-policies) for details on destination policies.

# Examples of common operations

`istioctl create [--file FILE]` - Create policies or rules from a file or stdin.

```shell
# Create a rule using the definition in example-routing.yaml.
$ istioctl create -f example-routing.yaml
```

`istioctl delete [TYPE NAME_1 ... NAME_N] [--file FILE]` - Create policies or rules from a file or stdin.

```shell
# Delete a rule using the definition in example-routing.yaml.
$ istioctl delete -f example-routing.yaml
```

```shell
# Delete the rule productpage-default
$ istioctl delete route-rule productpage-default
```

`istioctl get TYPE [NAME] [--output yaml|short]` - List policies or rules in YAML format

```shell
# List route rules
istioctl get route-rules

# List destination policies
istioctl get destination-policies

# Get the rule productpage-default
istioctl get route-rule productpage-default
```

`istioctl replace [--file FILENAME]` - Replace existing policies or rules with another from a file or stdin.

```shell
# Create a rule using the definition in example-routing.yaml.
$ istioctl replace -f example-routing.yaml
```

# kube-inject

`istioctl kube-inject [--filename FILENAME] [--hub HUB] [--meshConfig CONFIGMAP_NAME] [--output FILENAME] [--setVersionString VERSION] [--sidecarProxyUID UID] [--tag TAG] [--verbosity VERBOSITY]` - add Istio components to description

A short term workaround for the lack of a proper istio admision
controller is client-side injection. Use `istioctl kube-inject` to add the
necessary configurations to a Kubernetes resource files.

    istioctl kube-inject -f deployment.yaml -o deployment-with-istio.yaml

Or update the resource on the fly before applying.

    kubectl create -f <(istioctl kube-inject -f depoyment.yaml)

Or update an existing deployment.

    kubectl get deployment -o yaml | istioctl kube-inject -f - | kubectl apply -f -

`istioctl kube-inject` will update
the [PodTemplateSpec](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/#pod-templates) in
Kubernetes Job, DaemonSet, ReplicaSet, and Deployment YAML resource
documents. Support for additional pod-based resource types can be
added as necessary.

Unsupported resources are left unmodified so, for example, it is safe
to run `istioctl kube-inject` over a single file that contains multiple
Service, ConfigMap, and Deployment definitions for a complex
application.

The Istio project is continually evolving so the low-level proxy
configuration may change unannounced. When in doubt re-run `istioctl kube-inject`
on your original deployments.

## kube-inject flags

* `--coreDump` - Enable/Disable core dumps in injected proxy (--coreDump=true affects all pods in a node and should only be used the cluster admin) (default true)
* `--filename FILENAME` - Input kubernetes resource filename
* `--hub HUB` - Docker hub, for example docker.io/istio)
* `--meshConfig CONFIGMAP_NAME` - ConfigMap name for Istio mesh configuration, key should be "mesh" (default "istio")
* `--output FILENAME` - Modified output kubernetes resource filename
* `--setVersionString VERSION` - Override version info injected into resource
* `--sidecarProxyUID UID` - Sidecar proxy UID (default 1337)
* `--tag TAG` - Docker image file tag
* `--verbosity VERBOSITY` - Runtime verbosity (default 2)

# General command line flags

* `--kubeconfig FILENAME` - Use a Kubernetes configuration file instead of in-cluster configuration.  (default _~/.kube/config_)
* `--namespace NAMESPACE` - Kubernetes namespace (default "default")
* `--v LEVEL` - log level for V logs
* `--vmodule MODULESPEC` - comma-separated list of pattern=N settings for file-filtered logging
