---
title: pilot
overview: Istio Pilot
layout: docs
---
Istio Pilot provides fleet-wide traffic management capabilities in the Istio Service Mesh.

|Option|Shorthand|Description
|------|---------|-----------
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
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## pilot discovery

Start Istio proxy discovery service
```
pilot discovery [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--admission-registration-delay <duration>||Time to delay webhook registration after starting webhook server  (default 0s)
|--admission-secret <string>||Name of k8s secret for pilot webhook certs  (default "pilot-webhook")
|--admission-service <string>||Service name the admission controller uses during registration  (default "istio-pilot")
|--admission-service-port <int>||HTTPS port of the admission service. Must be 443 if service has more than one port   (default 443)
|--admission-webhook-name <string>||Webhook name for Pilot admission controller  (default "pilot-webhook.istio.io")
|--appNamespace <string>|-a|Restrict the applications namespace the controller manages; if not set, controller watches all namespaces  (default "")
|--cfConfig <string>||Cloud Foundry config file  (default "")
|--configDir <string>||Directory to watch for updates to config yaml files. If specified, the files will be used as the source of config, rather than a CRD client.  (default "")
|--consulconfig <string>||Consul Config file for discovery  (default "")
|--consulserverURL <string>||URL for the Consul server  (default "")
|--discovery_cache ||Enable caching discovery service responses 
|--domain <string>||DNS domain suffix  (default "cluster.local")
|--eurekaserverURL <string>||URL for the Eureka server  (default "")
|--kubeconfig <string>||Use a Kubernetes configuration file instead of in-cluster configuration  (default "")
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
|--meshConfig <string>||File name for Istio mesh configuration. If not specified, a default mesh will be used.  (default "/etc/istio/config/mesh")
|--monitoringPort <int>||HTTP port to use for the exposing pilot self-monitoring information  (default 9093)
|--namespace <string>|-n|Select a namespace where the controller resides. If not set, uses ${POD_NAMESPACE} environment variable  (default "")
|--port <int>||Discovery service port  (default 8080)
|--profile ||Enable profiling via web interface host:port/debug/pprof 
|--registries <stringSlice>||Comma separated list of platform service registries to read from (choose one or more from {Kubernetes, Consul, Eureka, CloudFoundry, Mock})  (default [Kubernetes])
|--resync <duration>||Controller resync interval  (default 1m0s)
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )
|--webhookEndpoint <string>||Webhook API endpoint (supports DNS, IP, and unix domain socket.  (default "")


## pilot help

Help provides help for any command in the application.
Simply type pilot help [path to command] for full details.
```
pilot help [command] [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
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
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )


## pilot version

Prints out build version information
```
pilot version [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
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
|--short |-s|Displays a short form of the version information 
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )

