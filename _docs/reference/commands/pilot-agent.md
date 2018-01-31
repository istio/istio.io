---
title: pilot-agent
overview: Istio Pilot agent
layout: docs
---
Istio Pilot provides management plane functionality to the Istio service mesh and Istio Mixer.

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


## pilot-agent help

Help provides help for any command in the application.
Simply type pilot-agent help [path to command] for full details.
```
pilot-agent help [command] [flags]
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


## pilot-agent proxy

Envoy proxy agent
```
pilot-agent proxy [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--availabilityZone <string>||Availability zone  (default "")
|--binaryPath <string>||Path to the proxy binary  (default "/usr/local/bin/envoy")
|--configPath <string>||Path to the generated configuration file directory  (default "/etc/istio/proxy")
|--connectTimeout <duration>||Connection timeout used by Envoy for supporting services  (default 1s)
|--controlPlaneAuthPolicy <string>||Control Plane Authentication Policy  (default "NONE")
|--customConfigFile <string>||Path to the generated configuration file directory  (default "")
|--discoveryAddress <string>||Address of the discovery service exposing xDS (e.g. istio-pilot:8080)  (default "istio-pilot:15003")
|--discoveryRefreshDelay <duration>||Polling interval for service discovery (used by EDS, CDS, LDS, but not RDS)  (default 1s)
|--domain <string>||DNS domain suffix. If not provided uses ${POD_NAMESPACE}.svc.cluster.local  (default "")
|--drainDuration <duration>||The time in seconds that Envoy will drain connections during a hot restart  (default 2s)
|--id <string>||Proxy unique ID. If not provided uses ${POD_NAME}.${POD_NAMESPACE} from environment variables  (default "")
|--ip <string>||Proxy IP address. If not provided uses ${INSTANCE_IP} environment variable.  (default "")
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
|--parentShutdownDuration <duration>||The time in seconds that Envoy will wait before shutting down the parent process during a hot restart  (default 3s)
|--proxyAdminPort <int>||Port on which Envoy should listen for administrative commands  (default 15000)
|--proxyLogLevel <string>||The log level used to start the Envoy proxy (choose from {trace, debug, info, warn, err, critical, off})  (default "info")
|--serviceCluster <string>||Service cluster  (default "istio-proxy")
|--serviceregistry <string>||Select the platform for service registry, options are {Kubernetes, Consul, Eureka}  (default "Kubernetes")
|--statsdUdpAddress <string>||IP Address and Port of a statsd UDP listener (e.g. 10.75.241.127:9125)  (default "")
|--v <Level>|-v|log level for V logs  (default 0)
|--vmodule <moduleSpec>||comma-separated list of pattern=N settings for file-filtered logging  (default )
|--zipkinAddress <string>||Address of the Zipkin service (e.g. zipkin:9411)  (default "")


## pilot-agent version

Prints out build version information
```
pilot-agent version [flags]
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

