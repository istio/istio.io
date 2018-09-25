---
title: pilot-discovery
description: Istio Pilot.
generator: pkg-collateral-docs
number_of_entries: 5
---

## pilot-discovery

Istio Pilot 在 Istio 服务网格中提供了更全面的流量管理能力。

标识    | 描述
------- | -----------
--ctrlz_address \<string> |  为 ControlZ 内省设备侦听的 IP 地址。使用 '*' 表示所有地址。  (默认 `127.0.0.1`)
--ctrlz_port \<uint16> | 用于 ControlZ 内省设施的 IP 端口。  (默认 `9876`)
--log_as_json | 是否已格式化的 JSON 格式输出或者是无格式化的控制台友好输出
--log_caller \<string> | 使用逗号分割的作用域列表,其中可以包含调用这信息，作用域可以是任何 [ads, default, model, rbac] (默认 ``)
--log_output_level \<string> | 以逗号分割的最小每个范围日志界别的消息输出, 格式为 \<scope>:\<level>,\<scope>:\<level>,... 作用域可以为 [ads, default, model, rbac]，等级可以为 [debug, info, warn, error, none] (默认 `default:info`)
--log_rotate \<string> | The path for the optional rotating log file  (默认 ``)
--log_rotate_max_age \<int> | The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (默认 `30`)
--log_rotate_max_backups \<int> | The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (默认 `1000`)
--log_rotate_max_size \<int> | The maximum size in megabytes of a log file beyond which the file is rotated  (默认 `104857600`)
--log_stacktrace_level \<string> | Comma-separated minimum per-scope logging level at which stack traces are captured, in the form of \<scope>:\<level>,\<scope:level>,... where scope can be one of [ads, default, model, rbac] and level can be one of [debug, info, warn, error, none]  (默认 `default:none`)
--log_target \<stringArray> | The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (默认 `[stdout]`)

## pilot-discovery discovery

启动 Istio 代理服务发现。

> pilot-discovery discovery [flags]

Flags | Shorthand | Description |
----- | --------- | ----------- |
--appNamespace \<string> | -a | Restrict the applications namespace the controller manages; if not set, controller watches all namespaces  (默认 ``)
--cfConfig \<string> | |Cloud Foundry config file  (默认 ``)
--clusterRegistriesConfigMap \<string> | |ConfigMap map for clusters config store  (默认 ``)
--clusterRegistriesNamespace \<string> | |Namespace for ConfigMap which stores clusters configs  (默认 ``)
--configDir \<string> | |Directory to watch for updates to config yaml files. If specified, the files will be used as the source of config, rather than a CRD client.  (默认 ``)
--consulserverInterval \<duration> | |Interval (in seconds) for polling the Consul service registry  (默认 `2s`)
--consulserverURL \<string> | |URL for the Consul server  (默认 ``)
--ctrlz_address \<string> | |The IP Address to listen on for the ControlZ introspection facility. Use '*' to indicate all addresses.  (默认 `127.0.0.1`)
--ctrlz_port \<uint16> | |The IP port to use for the ControlZ introspection facility  (默认 `9876`)
--discoveryCache | |Enable caching discovery service responses 
--domain \<string> | |DNS domain suffix  (默认 `cluster.local`)
--grpcAddr \<string> | |Discovery service grpc address  (默认 `:15010`)
--httpAddr \<string> | |Discovery service HTTP address  (默认 `:8080`)
--kubeconfig \<string> | |Use a Kubernetes configuration file instead of in-cluster configuration  (默认 ``)
--log_as_json | |Whether to format output as JSON or in plain console-friendly format 
--log_caller \<string> | |Comma-separated list of scopes for which to include caller information, scopes can be any of [ads, default, model, rbac]  (默认 ``)
--log_output_level \<string> | |Comma-separated minimum per-scope logging level of messages to output, in the form of \<scope>:\<level>,\<scope>:\<level>,... where scope can be one of [ads, default, model, rbac] and level can be one of [debug, info, warn, error, none]  (默认 `default:info`)
--log_rotate \<string> | |The path for the optional rotating log file  (默认 ``)
--log_rotate_max_age \<int> | |The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (默认 `30`)
--log_rotate_max_backups \<int> | |The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (默认 `1000`)
--log_rotate_max_size \<int> | |The maximum size in megabytes of a log file beyond which the file is rotated  (默认 `104857600`)
--log_stacktrace_level \<string> | |Comma-separated minimum per-scope logging level at which stack traces are captured, in the form of \<scope>:\<level>,\<scope:level>,... where scope can be one of [ads, default, model, rbac] and level can be one of [debug, info, warn, error, none]  (默认 `default:none`)
--log_target \<stringArray> | |The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (默认 `[stdout]`)
--mcpServerAddrs \<stringSlice> | |comma separated list of mesh config protocol server addresses  (默认 `[]`)
--meshConfig \<string> | |File name for Istio mesh configuration. If not specified, a default mesh will be used.  (默认 `/etc/istio/config/mesh`)
--monitoringAddr \<string> | |HTTP address to use for the exposing pilot self-monitoring information  (默认 `:9093`)
--namespace \<string> | -n | Select a namespace where the controller resides. If not set, uses ${POD_NAMESPACE} environment variable  (默认 ``)
--plugins \<stringSlice> | |comma separated list of networking plugins to enable  (默认 `[authn,authz,health,mixer,envoyfilter]`)
--profile | |Enable profiling via web interface host:port/debug/pprof 
--registries \<stringSlice> | |Comma separated list of platform service registries to read from (choose one or more from {Kubernetes, Consul, CloudFoundry, Mock, Config})  (默认 `[Kubernetes]`)
--resync \<duration> | |Controller resync interval  (默认 `1m0s`)
--secureGrpcAddr \<string> | |Discovery service grpc address, with https  (默认 `:15012`)

## pilot-discovery request

Makes an HTTP request to Pilot metrics/debug endpoint

> pilot-discovery request \<method> \<path> [flags]

Flags | Description
----- | -----------
--ctrlz_address \<string> | 为 ControlZ 内省设备侦听的 IP 地址。使用 '*' 表示所有地址。  (默认 `127.0.0.1`)
--ctrlz_port \<uint16> | 用于 ControlZ 内省设施的 IP 端口。  (默认 `9876`)
--log_as_json | 是否已格式化的 JSON 格式输出或者是无格式化的控制台友好输出
--log_caller \<string> | Comma-separated list of scopes for which to include caller information, scopes can be any of [ads, default, model, rbac]  (默认 ``)
--log_output_level \<string> | Comma-separated minimum per-scope logging level of messages to output, in the form of \<scope>:\<level>,\<scope>:\<level>,... where scope can be one of [ads, default, model, rbac] and level can be one of [debug, info, warn, error, none]  (默认 `default:info`)
--log_rotate \<string> | The path for the optional rotating log file  (默认 ``)
--log_rotate_max_age \<int> | The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (默认 `30`)
--log_rotate_max_backups \<int> | The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (默认 `1000`)
--log_rotate_max_size \<int> | The maximum size in megabytes of a log file beyond which the file is rotated  (默认 `104857600`)
--log_stacktrace_level \<string> | Comma-separated minimum per-scope logging level at which stack traces are captured, in the form of \<scope>:\<level>,\<scope:level>,... where scope can be one of [ads, default, model, rbac] and level can be one of [debug, info, warn, error, none]  (默认 `default:none`)
--log_target \<stringArray> | The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (默认 `[stdout]`)

## pilot-discovery version

Prints out build version information

> pilot-discovery version [flags]

Flags | Shorthand | Description
----- | --------- | -----------
--ctrlz_address \<string> | | 为 ControlZ 内省设备侦听的 IP 地址。使用 '*' 表示所有地址。 (默认 `127.0.0.1`)
--ctrlz_port \<uint16> | | 用于 ControlZ 内省设施的 IP 端口。  (默认 `9876`)
--log_as_json | | 是否已格式化的 JSON 格式输出或者是无格式化的控制台友好输出
--log_caller \<string> | | Comma-separated list of scopes for which to include caller information, scopes can be any of [ads, default, model, rbac]  (默认 ``)
--log_output_level \<string> | | Comma-separated minimum per-scope logging level of messages to output, in the form of \<scope>:\<level>,\<scope>:\<level>,... where scope can be one of [ads, default, model, rbac] and level can be one of [debug, info, warn, error, none]  (默认 `default:info`)
--log_rotate \<string> | |The path for the optional rotating log file  (默认 ``)
--log_rotate_max_age \<int> | |The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (默认 `30`)
--log_rotate_max_backups \<int> | |The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (默认 `1000`)
--log_rotate_max_size \<int> | |The maximum size in megabytes of a log file beyond which the file is rotated  (默认 `104857600`)
--log_stacktrace_level \<string> | |Comma-separated minimum per-scope logging level at which stack traces are captured, in the form of \<scope>:\<level>,\<scope:level>,... where scope can be one of [ads, default, model, rbac] and level can be one of [debug, info, warn, error, none]  (默认 `default:none`)
--log_target \<stringArray> | |The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (默认 `[stdout]`)
--short | -s | 显示版本信息到简短形式