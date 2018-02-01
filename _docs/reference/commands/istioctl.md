---
title: istioctl
overview: Istio control interface
layout: docs
---

Istio configuration command line utility.

Create, list, modify, and delete configuration resources in the Istio
system.

Available routing and traffic management configuration types:

	[routerule ingressrule egressrule destinationpolicy]

See https://istio.io/docs/reference/ for an overview of routing rules
and destination policies.



|Option|Shorthand|Description
|------|---------|-----------
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl context-create

Create a kubeconfig file suitable for use with istioctl in a non kubernetes environment
```
istioctl context-create --api-server http://<ip>:<port> [flags]
```


### Examples

```

		# Create a config file for the api server.
		istioctl context-create --api-server http://127.0.0.1:8080
		
```


|Option|Shorthand|Description
|------|---------|-----------
|--api-server <string>||URL for Istio api server  (default "")
|--context <string>||Kubernetes configuration file context name  (default "istio")
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl create

Create policies and rules
```
istioctl create [flags]
```


### Examples

```

			istioctl create -f example-routing.yaml
			
```


|Option|Shorthand|Description
|------|---------|-----------
|--file <string>|-f|Input file with the content of the configuration objects (if not set, command reads from the standard input)  (default "")
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl delete

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


|Option|Shorthand|Description
|------|---------|-----------
|--file <string>|-f|Input file with the content of the configuration objects (if not set, command reads from the standard input)  (default "")
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl deregister

De-registers a service instance
```
istioctl deregister <svcname> <ip> [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl gen-deploy

istioctl gen-deploy produces deployment files to run the minimum Istio control for the set of features requested by the --feature flag. If no features are provided, we create deployments for the default control plane: Pilot, Mixer, CA, and Ingress Proxies, with mTLS enabled.
```
istioctl gen-deploy [flags]
```


### Examples

```
istioctl gen-deploy --features routing,policy,sidecar-injector -o helm
```


|Option|Shorthand|Description
|------|---------|-----------
|--debug ||If true, uses debug images instead of release images 
|--features <stringArray>|-f|List of Istio features to enable. Accepts any combination of "mtls", "telemetry", "routing", "ingress", "policy", "sidecar-injector".  (default [])
|--helm-chart-dir <string>||The directory to find the helm charts used to render Istio deployments. -o yaml uses these to render the helm chart locally.  (default ".")
|--hyperkube-hub <string>||The container registry to pull Hyperkube images from  (default "quay.io/coreos/hyperkube")
|--hyperkube-tag <Hyperkube>||The tag to use to pull the Hyperkube container  (default "0.4.0")
|--ingress-node-port <uint16>||If provided, Istio ingress proxies will run as a NodePort service mapped to the port provided by this flag. Note that this flag is ignored unless the "ingress" feature flag is provided too.  (default 0)
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--out <string>|-o|Output format. Acceptable values are:
					"helm": produces contents of values.yaml
					"yaml": produces Kubernetes deployments  (default "helm")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--values <string>||Path to the Helm values.yaml file used to render YAML deployments locally when --out=yaml. Flag values are ignored in favor of using the file directly.  (default "")
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl get

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


|Option|Shorthand|Description
|------|---------|-----------
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--output <string>|-o|Output format. One of:yaml|short  (default "short")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl help

Help provides help for any command in the application.
Simply type istioctl help [path to command] for full details.
```
istioctl help [command] [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl kube-inject



kube-inject manually injects envoy sidecar into kubernetes
workloads. Unsupported resources are left unmodified so it is safe to
run kube-inject over a single file that contains multiple Service,
ConfigMap, Deployment, etc. definitions for a complex application. Its
best to do this when the resource is initially created.

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
# injected.
istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml

# Update an existing deployment.
kubectl get deployment -o yaml | istioctl kube-inject -f - | kubectl apply -f -

```


|Option|Shorthand|Description
|------|---------|-----------
|--coreDump ||Enable/Disable core dumps in injected Envoy sidecar (--coreDump=true affects all pods in a node and should only be used the cluster admin) 
|--debug ||Use debug images and settings for the sidecar 
|--emitTemplate ||Emit sidecar template based on parameterized flags 
|--filename <string>|-f|Input Kubernetes resource filename  (default "")
|--hub <string>||Docker hub  (default "unknown")
|--imagePullPolicy <string>||Sets the container image pull policy. Valid options are Always,IfNotPresent,Never.The default policy is IfNotPresent.  (default "IfNotPresent")
|--includeIPRanges <string>||Comma separated list of IP ranges in CIDR form. If set, only redirect outbound traffic to Envoy for IP ranges. Otherwise all outbound traffic is redirected  (default "")
|--injectConfigFile <string>||injection configuration filename  (default "")
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--meshConfigFile <string>||mesh configuration filename. Takes precedence over --meshConfigMapName if set  (default "")
|--meshConfigMapName <string>||ConfigMap name for Istio mesh configuration, key should be "mesh"  (default "istio")
|--namespace <string>|-n|Config namespace  (default "")
|--output <string>|-o|Modified output Kubernetes resource filename  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--setVersionString <string>||Override version info injected into resource  (default "")
|--sidecarProxyUID <uint>||Envoy sidecar UID  (default 1337)
|--tag <string>||Docker tag  (default "unknown")
|--v <Level>|-v|log level for V logs  (default 0)
|--verbosity <int>||Runtime verbosity  (default 2)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl register

Registers a service instance (e.g. VM) joining the mesh
```
istioctl register <svcname> <ip> [name1:]port1 [name2:]port2 ... [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--annotations <stringSlice>|-a|List of string annotations to apply if creating a service/endpoint; e.g. -a foo=bar,test,x=y  (default [])
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--labels <stringSlice>|-l|List of labels to apply if creating a service/endpoint; e.g. -l env=prod,vers=2  (default [])
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--serviceaccount <string>|-s|Service account to link to the service  (default "default")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl replace

Replace existing policies and rules
```
istioctl replace [flags]
```


### Examples

```

			istioctl replace -f example-routing.yaml
			
```


|Option|Shorthand|Description
|------|---------|-----------
|--file <string>|-f|Input file with the content of the configuration objects (if not set, command reads from the standard input)  (default "")
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## istioctl version

Prints out build version information
```
istioctl version [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--istioNamespace <string>|-i|Istio system namespace  (default "istio-system")
|--kubeconfig <string>|-c|Kubernetes configuration file  (default "/Users/mtail/.kube/config")
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_backtrace_at <traceLocation>||when logging hits line file:N, emit a stack trace  (default :0)
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--namespace <string>|-n|Config namespace  (default "")
|--platform <string>|-p|Istio host platform  (default "kube")
|--short |-s|Displays a short form of the version information 
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )

