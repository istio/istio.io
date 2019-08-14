---
title: pilot-discovery
description: Istio Pilot。
generator: pkg-collateral-docs
number_of_entries: 5
---

## pilot-discovery

Istio Pilot 在 Istio 服务网格中提供了更全面的流量管理能力。

标识    | 描述
------- | -----------
`--ctrlz_address <string>` | 要监听的控件的 IP 地址。使用 '*' 表示所有地址。（默认 `127.0.0.1`）
`--ctrlz_port <uint16>` | 要监听的空间的 IP 端口。（默认 `9876`）
`--log_as_json` | 是否已格式化的 JSON 格式输出或者是无格式化的控制台友好输出
`--log_caller <string>` | 使用逗号分割的作用域列表,其中可以包含调用这信息，作用域可以是任何 `[ads, default, mcp-creds, model, rbac]`（默认 `''`）
`--log_output_level <string>` | 以逗号分割的最小每个范围日志界别的消息输出, 格式为 `<scope>:<level>,<scope>:<level>`,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]`（默认 `default:info`）
`--log_rotate <string>` | 可选循环日志文件路径（默认 `''`）
`--log_rotate_max_age <int>` | 日志文件循环的最大天数（0表示无限制）（默认 `30`）
`--log_rotate_max_backups <int>`| 删除旧文件之前保留的日志文件备份的最大数量（0表示无限制）（默认 `1000`）
`--log_rotate_max_size <int>` | 单个日志文件循环的最大大小（默认 `104857600`）
`--log_stacktrace_level <string>` | 以逗号分割的最小每个范围日志界别的消息输出, 格式为 \< scope>:\< level>,\< scope>:\< level>,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]` (默认 `default:none`)
`--log_target <stringArray>` | 设置日志输出路径集合。可以是任何路径，也可以是特殊值 `stdout` 和 `stderr`（默认 `[stdout]`）

## pilot-discovery discovery

启动 Istio 代理服务发现。

{{< text plain >}}
pilot-discovery discovery [flags]
{{< /text >}}

标识 | 缩写 | 描述 |
----- | --------- | ----------- |
`--appNamespace <string>` | -a | 限制控制器管理的应用程序的命名空间；如果未设置，控制器将监控所有命名空间（默认 `''`）
`--cfConfig <string>` | | Cloud Foundry 配置文件（默认 `''`）
`--clusterRegistriesConfigMap <string>` | | ConfigMap 集群配置存储映射表（默认 `''`）
`--clusterRegistriesNamespace <string>` | | ConfigMap 存储集群配置的命名空间（默认 `''`）
`--configDir <string>` | | 文件目录用于监控 yaml 文件的更新。如果有指定，文件将作为配置源，而不是 CRD 的客户端。（默认 `''`）
`--consulserverInterval <duration>` | | 轮询 Consul 服务注册的区间间隔（秒为单位）（默认 `2s`）
`--consulserverURL <string>` | | Consul 服务的 URL（默认 `''`）
`--ctrlz_address <string>` | | 要监听的控件的 IP 地址。使用 '*' 表示所有地址。(默认 `127.0.0.1`)
`--ctrlz_port <uint16>` | | 要监听的空间的 IP 端口。(默认 `9876`)
`--discoveryCache` | | 启用缓存服务发现响应
`--domain <string>` | | DNS 域名后缀（默认 `cluster.local`）
`--grpcAddr <string>` | | 服务发现 grpc 地址（默认 `:15010`）
`--httpAddr <string>` | | 服务发现 HTTP 地址（默认 `:8080`）
`--kubeconfig <string>` | | 使用 Kubernetes 配置文件替换集群配置（默认 `''`)
`--log_as_json` | | 是否已格式化的 JSON 格式输出或者是无格式化的控制台友好输出
`--log_caller <string>` | | 使用逗号分割的作用域列表,其中可以包含调用这信息，作用域可以是任何 `[ads, default, mcp-creds, model, rbac]` （默认 `''`)
`--log_output_level <string>` | | 以逗号分割的最小每个范围日志界别的消息输出， 格式为 `<scope>:<level>,<scope>:<level>`,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]`（默认 `default:info`）
`--log_rotate <string>` | | 可选循环日志文件路径（默认 `''`)
`--log_rotate_max_age <int>` | | 日志文件循环的最大天数（0表示无限制）（默认 `30`)
`--log_rotate_max_backups <int>` | | 删除旧文件之前保留的日志文件备份的最大数量 (0表示无限制) （默认 `1000`)
`--log_rotate_max_size <int>` | | 单个日志文件循环的最大大小（默认 `104857600`）
`--log_stacktrace_level <string>` | | 以逗号分割的最小每个范围日志界别的消息输出, 格式为 `<scope>:<level>,<scope>:<level>`,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]` (默认 `default:none`)
`--log_target <stringArray>` | | 设置日志输出路径集合。可以是任何路径，也可以是特殊值 `stdout` 和 `stderr` (默认 `[stdout]`)
`--mcpServerAddrs <stringSlice>` | | 以逗号分割的 Mesh 配置协议服务器地址列表（默认 `[]`）
`--meshConfig <string>` | |Istio mesh 配置的文件名。如果为指定，使用默认的 mesh。（默认 `/etc/istio/config/mesh`）
`--monitoringAddr <string>` | | 用于暴露 pilot 自我监控信息的 HTTP 地址（默认 `:9093`）
`--namespace <string>` | -n | 选择控制器驻留的命名空间。如果未设置，则使用 `${POD_NAMESPACE}` 环境变量（默认 `''`）
`--plugins <stringSlice>` | | 启用由逗号分隔的网络插件列表（默认 `[authn,authz,health,mixer,envoyfilter]`）
`--profile` | | 通过 web 接口实现配置文件 host:port/debug/pprof
`--registries <stringSlice>` | | 从以逗号分割的平台服务注册列表中读取（选择一个或多个 `{Kubernetes, Consul, CloudFoundry, Mock, Config}`）（默认 `[Kubernetes]`）
`--resync <duration>` | | 控制器再次同步时间间隔（默认 `1m0s`）
`--secureGrpcAddr <string>` | | 使用 https 的服务发现 grpc 地址（默认 `:15012`）

## pilot-discovery request

对 Pilot metrics/debug 端点发送 HTTP 请求。

{{< text plain >}}
pilot-discovery request <method> <path> [flags]
{{< /text >}}

标识 | 描述
----- | -----------
`--ctrlz_address <string>` | 要监听的控件的 IP 地址。使用 '*' 表示所有地址。  (默认 `127.0.0.1`)
`--ctrlz_port <uint16>` | 要监听的控件的 IP 端口。  (默认 `9876`)
`--log_as_json` | 是否已格式化的 JSON 格式输出或者是无格式化的控制台友好输出
`--log_caller <string>` | 使用逗号分割的作用域列表,其中可以包含调用这信息，作用域可以是任何 `[ads, default, mcp-creds, model, rbac]` (默认 `''`)
`--log_output_level <string>` | 以逗号分割的最小每个范围日志界别的消息输出，格式为 `<scope>:<level>,<scope>:<level>`,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]`（默认 `default:info`）
`--log_rotate <string>` | 可选循环日志文件路径(默认 `''`)
`--log_rotate_max_age <int>` | 日志文件循环的最大天数（0表示无限制）(默认 `30`)
`--log_rotate_max_backups <int>` | 删除旧文件之前保留的日志文件备份的最大数量 (0表示无限制) (默认 `1000`)
`--log_rotate_max_size <int>` | 单个日志文件循环的最大大小（默认 `104857600`）
`--log_stacktrace_level <string>` | 以逗号分割的最小每个范围日志界别的消息输出, 格式为 `<scope>:<level>,<scope>:<level>`,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]` (默认 `default:none`)
`--log_target <stringArray>` | 设置日志输出路径集合。可以是任何路径，也可以是特殊值 `stdout` 和 `stderr` (默认 `[stdout]`)

## pilot-discovery version

打印版本信息

{{< text plain >}}
pilot-discovery version [flags]
{{< /text >}}

标识 | 缩写 | 描述
----- | --------- | -----------
`--ctrlz_address <string>` | | 要监听的控件的 IP 地址。使用 '*' 表示所有地址。 (默认 `127.0.0.1`)
`--ctrlz_port <uint16>` | | 要监听的空间的 IP 端口。  (默认 `9876`)
`--log_as_json` | | 是否已格式化的 JSON 格式输出或者是无格式化的控制台友好输出
`--log_caller <string>` | | 使用逗号分割的作用域列表,其中可以包含调用这信息，作用域可以是任何 `[ads, default, mcp-creds, model, rbac]` (默认 `''`)
`--log_output_level <string>` | | 以逗号分割的最小每个范围日志界别的消息输出，格式为 `<scope>:<level>,<scope>:<level>`,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]`（默认 `default:info`）
`--log_rotate <string>` | | 可选循环日志文件路径(默认 `''`)
`--log_rotate_max_age <int>` | |  日志文件循环的最大天数（0表示无限制）(默认 `30`)
`--log_rotate_max_backups <int>` | | 删除旧文件之前保留的日志文件备份的最大数量 (0表示无限制) (默认 `1000`)
`--log_rotate_max_size <int>` | | 单个日志文件循环的最大大小（默认 `104857600`）
`--log_stacktrace_level <string>` | | 以逗号分割的最小每个范围日志界别的消息输出, 格式为 `<scope>:<level>,<scope>:<level>`,... 作用域可以为 `[ads, default, mcp-creds, model, rbac]`，等级可以为 `[debug, info, warn, error, fatal, none]` (默认 `default:none`）
`--log_target <stringArray>` | | 设置日志输出路径集合。可以是任何路径，也可以是特殊值 `stdout` 和 `stderr` (默认 `[stdout]`)
`--short` | -s | 显示版本信息到简短形式
