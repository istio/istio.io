---
title: istio_ca
overview: Istio Certificate Authority (CA)
layout: docs
---
Istio Certificate Authority (CA)
```bash
istio_ca [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--ca-cert-ttl <duration>`||The TTL of self-signed CA root certificate  (default `8760h0m0s`)
|`--cert-chain <string>`||Speicifies path to the certificate chain file  (default `""`)
|`--grpc-hostname <string>`||Specifies the hostname for GRPC server.  (default `"localhost"`)
|`--grpc-port <int>`||Specifies the port number for GRPC server. If unspecified, Istio CA will not server GRPC request.  (default `0`)
|`--istio-ca-storage-namespace <string>`||Namespace where the Istio CA pods is running. Will not be used if explicit file or other storage mechanism is specified.  (default `"istio-system"`)
|`--kube-config <string>`||Specifies path to kubeconfig file. This must be specified when not running inside a Kubernetes pod.  (default `""`)
|`--log_as_json`||Whether to format output as JSON or in plain console-friendly format 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_callers`||Include caller information, useful for debugging 
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--log_output_level <string>`||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default `"info"`)
|`--log_rotate <string>`||The path for the optional rotating log file  (default `""`)
|`--log_rotate_max_age <int>`||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default `30`)
|`--log_rotate_max_backups <int>`||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default `1000`)
|`--log_rotate_max_size <int>`||The maximum size in megabytes of a log file beyond which the file is rotated  (default `104857600`)
|`--log_stacktrace_level <string>`||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default `"none"`)
|`--log_target <stringArray>`||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default `[stdout]`)
|`--logtostderr`||log to standard error instead of files 
|`--max-workload-cert-ttl <duration>`||The max TTL of issued workload certificates  (default `168h0m0s`)
|`--namespace <string>`||Select a namespace for the CA to listen to. If unspecified, Istio CA tries to use the ${NAMESPACE} environment variable. If neither is set, Istio CA listens to all namespaces.  (default `""`)
|`--root-cert <string>`||Specifies path to the root certificate file  (default `""`)
|`--self-signed-ca-org <string>`||The issuer organization used in self-signed CA certificate (default to k8s.cluster.local)  (default `"k8s.cluster.local"`)
|`--self-signed-ca`||Indicates whether to use auto-generated self-signed CA certificate. When set to true, the '--signing-cert' and '--signing-key' options are ignored. 
|`--signing-cert <string>`||Specifies path to the CA signing certificate file  (default `""`)
|`--signing-key <string>`||Specifies path to the CA signing key file  (default `""`)
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)
|`--workload-cert-ttl <duration>`||The TTL of issued workload certificates  (default `1h0m0s`)


## istio_ca version

Prints out build version information
```bash
istio_ca version [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--log_as_json`||Whether to format output as JSON or in plain console-friendly format 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_callers`||Include caller information, useful for debugging 
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--log_output_level <string>`||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default `"info"`)
|`--log_rotate <string>`||The path for the optional rotating log file  (default `""`)
|`--log_rotate_max_age <int>`||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default `30`)
|`--log_rotate_max_backups <int>`||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default `1000`)
|`--log_rotate_max_size <int>`||The maximum size in megabytes of a log file beyond which the file is rotated  (default `104857600`)
|`--log_stacktrace_level <string>`||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default `"none"`)
|`--log_target <stringArray>`||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default `[stdout]`)
|`--logtostderr`||log to standard error instead of files 
|`--short`|`-s`|Displays a short form of the version information 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)

