---
title: node_agent
overview: Istio security per-node agent
layout: docs
---
Istio security per-node agent
```
node_agent [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--aws-root-cert <string>||Root Certificate file in AWS environment  (default "/etc/certs/root-cert.pem")
|--ca-address <string>||Istio CA address  (default "istio-ca:8060")
|--env <string>||Node Environment : onprem | gcp | aws  (default "onprem")
|--gcp-ca-address <string>||Istio CA address in GCP environment  (default "istio-ca:8060")
|--gcp-root-cert <string>||Root Certificate file in GCP environment  (default "/etc/certs/root-cert.pem")
|--key-size <int>||Size of generated private key  (default 2048)
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--onprem-cert-chain <string>||Node Agent identity cert file in on premise environment  (default "/etc/certs/cert-chain.pem")
|--onprem-key <string>||Node identity private key file in on premise environment  (default "/etc/certs/key.pem")
|--onprem-root-cert <string>||Root Certificate file in on premise environment  (default "/etc/certs/root-cert.pem")
|--org <string>||Organization for the cert  (default "")
|--workload-cert-ttl <duration>||The requested TTL for the workload  (default 12h0m0s)


## node_agent help

Help provides help for any command in the application.
Simply type node_agent help [path to command] for full details.
```
node_agent help [command] [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])


## node_agent version

Prints out build version information
```
node_agent version [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|--log_as_json ||Whether to format output as JSON or in plain console-friendly format 
|--log_callers ||Include caller information, useful for debugging 
|--log_output_level <string>||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default "info")
|--log_rotate <string>||The path for the optional rotating log file  (default "")
|--log_rotate_max_age <int>||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default 30)
|--log_rotate_max_backups <int>||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default 1000)
|--log_rotate_max_size <int>||The maximum size in megabytes of a log file beyond which the file is rotated  (default 104857600)
|--log_stacktrace_level <string>||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default "none")
|--log_target <stringArray>||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default [stdout])
|--short |-s|Displays a short form of the version information 

