---
title: mixs
description: Mixer 是 Istio 在基础设施后端之上的抽象。
generator: pkg-collateral-docs
number_of_entries: 9
---

Mixer 是 Istio 与基础设施后端集成的关键，是策略评估和遥测报告的关键。

## `mixs crd`

Mixer 中提供 `CRD（CustomResourceDefinition）`

## `mixs crd 适配器`

列出可用适配器的 CRD

```bash
mixs crd adapter [flags]

```

## `mixs crd all`

列出所有 CRD

```bash
mixs crd all [flags]

```

## `mixs crd 实例`

列出可用实例种类的 CRD（网格函数）

```bash
mixs crd instance [flags]

```

## `mixs 探针`

检查本地运行的服务器的活跃度或准备情况

```bash
mixs probe [flags]

```

| 参数 | 描述 |
| --- | --- |
| `--interval <duration>` | 用于检查目标文件上次修改时间的持续时间。 （默认为\`0s\`） |
| `--log_as_json` | 是将输出格式化为 JSON 还是以简单的控制台友好格式 |
| `--log_caller <string>` | `以逗号分隔的范围列表，包括调用者信息，范围可以是\[adapter，api，attributes，default，grpcAdapter，mcp，mcp\-creds\]中的任何一个（默认为\`\`）` |
| `--log_output_level <string>` | `以逗号分隔的最小每范围日志记录级别的消息输出，格式为<scope>：<level>，<scope>：<level>，...其中 scope 可以是\[adapters，api，attributes，之一， default，grpcAdapter，mcp，mcp\-creds\]和 level 可以是\[debug，info，warn，error，none\]之一（默认为\`default：info\`）` |
| `--log_rotate <string>` | 可选旋转日志文件的路径（默认为\`\`） |
| `--log_rotate_max_age <int>` | 日志文件超过文件旋转的最大年龄（0表示无限制）（默认为“30”） |
| `--log_rotate_max_backups <int>` | 删除旧文件之前要保留的最大日志文件备份数（0表示无限制）（默认为“1000”） |
| `--log_rotate_max_size <int>` | 日志文件的最大大小（以兆字节为单位），超过该日志文件将旋转文件（默认为“104857600”） |
| `--log_stacktrace_level <string>` | `捕获堆栈跟踪的逗号分隔的最小每范围日志记录级别，格式为<scope>：<level>，<scope：level>，...其中 scope 可以是\[adapters，api，attributes，之一， default，grpcAdapter，mcp，mcp\-creds\]和 level 可以是\[debug，info，warn，error，none\]之一（默认为\`default：none\`）` |
| `--log_target <stringArray>` | `输出日志的路径集。 这可以是任何路径以及特殊值 stdout 和 stderr（默认\`\[stdout\]\`）` |
| `--probe-path <string>` | 用于检查可用性的文件的路径。 （默认\`\`） |

## `mixs 服务器`

将 Mixer 作为服务器启动

```bash
mixs server [flags]

```

| 参数 | 缩写 | 描述 |
| --- | --- | --- |
| `--adapterWorkerPoolSize <int>` |  | 适配器工作池中的最大 `gorout` 数量（默认为“1024”） |
| `--address <string>` |  | 用于 `Mixer` 的 `gRPC API` 的地址，例如 `tcp://127.0.0.1:9092`或 `unix:///path/to/file`（默认为\`\`） |
| `--apiWorkerPoolSize <int>` |  | API 工作池中的最大 `gorout` 数量（默认为“1024”） |
| `--caCertFile <string>` |  | 根证书颁发机构的证书文件的位置（默认为\`/etc/istio/certs/root\-cert.pem\`） |
| `--certFile <string>` |  | 双向 TLS 的证书文件的位置（默认\`/etc/istio/certs/cert\-chain.pem\`） |
| `--configDefaultNamespace <string>` |  | 命名空间用于存储网格宽配置。 （默认\`istio\-system\`） |
| `--configStoreURL <string>` |  | 配置存储的 URL。 对于文件系统，使用 k8s://path\_to\_kubeconfig，fs：//，对于 `MCP/Galley`，使用 `mcp://<address>`。 如果 path\_to\_kubeconfig 为空，则使用群集内 kubeconfig。 （默认\`\`） |
| `--ctrlz_address <string>` |  | 监听 ControlZ 内省设施的 IP 地址。 使用'\*'表示所有地址。 （默认\`127.0.0.1\`） |
| `--ctrlz_port <uint16>` |  | 用于 ControlZ 内省工具的 IP 端口（默认为\`9876\`） |
| `--keyFile <string>` |  | 双向 TLS 的密钥文件的位置（默认\`/etc/istio/certs/key.pem\`） |
| `--livenessProbeInterval <duration>` |  | 更新活动探测文件的时间间隔。 （默认为\`0s\`） |
| `--livenessProbePath <string>` |  | 活动探针文件的路径。 （默认\`\`） |
| `--log_as_json` |  | 是将输出格式化为 JSON 还是以简单的控制台友好格式 |
| `--log_caller <string>` |  | 以逗号分隔的范围列表，包括调用者信息，范围可以是\[`adapter`，api，attributes，default，`grpcAdapter`，`mcp`，`mcp-creds`\]中的任何一个（默认为\`\`） |
| `--log_output_level <string>` |  | 以逗号分隔的最小每范围日志记录级别的消息输出，格式为<scope>：<level>，<scope>：<level>，...其中 scope 可以是\[`adapters`，api，`attributes`， default，`grpcAdapter`，mcp，`mcp-creds`\] 之一和 level 可以是\[debug，info，warn，error，none\]之一（默认为\`default：info\`） |
| `--log_rotate <string>` |  | 可选旋转日志文件的路径（默认为\`\`） |
| `--log_rotate_max_age <int>` |  | 日志文件超过文件旋转的最大年龄（0表示无限制）（默认为“30”） |
| `--log_rotate_max_backups <int>` |  | 删除旧文件之前要保留的最大日志文件备份数（0表示无限制）（默认为“1000”） |
| `--log_rotate_max_size <int>` |  | 日志文件的最大大小（以兆字节为单位），超过该日志文件将旋转文件（默认为“104857600”） |
| `--log_stacktrace_level <string>` |  | 捕获堆栈跟踪的逗号分隔的最小每范围日志记录级别，格式为`<scope>：<level>，<scope：level>，...`其中 scope 可以是\[`adapters`，api，`attributes`， default，`grpcAdapter`，mcp，`mcp-creds`\]，之一和 level 可以是\[debug，info，warn，error，none\]之一（默认为\`default：none\`） |
| `--log_target <stringArray>` |  | 输出日志的路径集。 这可以是任何路径以及特殊值 `stdout` 和 `stderr`（默认\`\[stdout\]\`） |
| `--maxConcurrentStreams <uint>` |  | 每个连接的最大未完成 RPC 数（默认为“1024”） |
| `--maxMessageSize <uint>` |  | 单个 gRPC 消息的最大大小（默认为“1048576”） |
| `--monitoringPort <uint16>` |  | 用于公开 Mixer 自我监控信息的 HTTP 端口（默认为“9093”） |
| `--numCheckCacheEntries <int32>` |  | 检查结果缓存中的最大条目数（默认为“1500000”） |
| `--port <uint16>` | `-p` | 用于 `Mixer` 的 gRPC API 的 TCP 端口，如果未指定地址选项（默认为“9091”） |
| `--profile` |  | 通过 Web 界面主机启用性能分析：port/debug/pprof |
| `--readinessProbeInterval <duration>` |  | 准备探针的更新文件的间隔。 （默认为\`0s\`） |
| `--readinessProbePath <string>` |  | 准备探针的文件路径。（默认\`\`） |
| `--singleThreaded` |  | 如果为 true，则每个对 `Mixer` 的请求将在单个 go 例程中执行（对于调试很有用） |
| `--trace_jaeger_url <string>` |  | Jaeger HTTP 收集器的 URL（例如：`http://jaeger:14268/api/traces?format=jaeger.thrift`）。 （默认\`\`） |
| `--trace_log_spans` |  | 是否记录跟踪跨度。 |
| `--trace_zipkin_url <string>` |  | Zipkin 收集器的 URL（例如：`http://zipkin:9411/api/v1/spans`）。 （默认\`\`） |

## `mixs 版本`

打印出版本信息

```bash
mixs version [flags]

```

| 参数 | 缩写 | 描述 |
| --- | --- | --- |
| `--short` | `-s` | 显示版本信息的简短形式 |