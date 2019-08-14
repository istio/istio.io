---
title: galley
weight: 10
description: Galley 为 Istio 提供配置管理服务。
---

## 简介

Galley 为 Istio 提供配置管理服务。

## 全局选项

|选项|描述|
|---|---|
|`--kubeconfig <string>`|使用 Kubernetes 配置文件，而不使用 in-cluster 配置（缺省值 `''`）|
|`--log_as_json`|是否将输出格式化为 JSON，缺省情况下会以控制台友好的纯文本格式进行输出|
|`--log_caller <string>`|以逗号作为分隔符的列表，用于指定日志中包含的调用者信息的范围，范围可以从这一列表中选择：`[ads, default, model, rbac]` （缺省值 `''`）
|`--log_output_level <string>`|以逗号作为分隔符的列表，指定每个范围的日志级别，格式为 `<scope>:<level>,<scope>:<level>...`，`scope` 是 `[ads, default, model, rbac]` 中的一个，日志级别可以选择 `[debug, info, warn, error, none]`（缺省值 `default:info`）|
|`--log_rotate <string>`|日志轮转文件的路径（缺省值 `''`）
|`--log_rotate_max_age <int>`|日志文件的最大寿命，以天为单位，超出之后会进行轮转（`0` 代表无限制，缺省值 `30`）
|`--log_rotate_max_backups <int>`|日志文件备份的最大数量，超出这一数量之后就会删除比较陈旧的文件。（`0` 代表无限制，缺省值 `1000`）
|`--log_rotate_max_size <int>`|日志文件的最大尺寸，以 M 为单位，超出限制之后会进行轮转（缺省值 `104857600`）|
|`--log_stacktrace_level <string>`|以逗号作为分隔符的列表，用于指定 Stack trace 时每个范围的最小日志级别，大致是 `<scope>:<level>,<scope:level>...` 的形式，`scope` 是 `[ads, default, model, rbac]` 中的一个，日志级别可以选择 `[debug, info, warn, error, none]`，（缺省值 `default:none`）|
|`--log_target <stringArray>`|一组用于输出日志的路径。可以是任何路径，也可以是 `stdout` 和 `stderr` 之类的特殊值。（缺省值 `[stdout]`）|
|`--resyncPeriod <duration>`|Kubernetes 资源扫描的同步周期。（缺省值 `0s`）|

## galley probe

检查本地运行的服务器的存活和就绪状态。

{{< text bash >}}
$ galley probe [选项]
{{< /text >}}

|选项|描述|
|---|---|
|`--interval <duration>`|检查目标文件最后修改时间的周期。（缺省值 `0s`）|
|`--probe-path <string>`|可用性检查文件的路径。（缺省值 `0s`）|

## galley server

启动 Galley 服务器。

{{< text bash >}}
$ galley server [选项]
{{< /text >}}

|选项|描述|
|---|---|
|`--address <string>`|Galley 的 gRPC API 地址，例如 `tcp://127.0.0.1:9092` 或者 `unix:///path/to/file`。（缺省值：`tcp://127.0.0.1:9901`）|
|`--ctrlz_address <string>`|监听 ControlZ 内省设施的 IP 地址。`*` 代表所有地址。（缺省值 `127.0.0.1`）|
|`--ctrlz_port <uint16>`|监听 ControlZ 内省设施的端口。（缺省 `9876`）|
|`--kubeConfig <string>`|Kubeconfig 文件的路径。（缺省值 `''`）|
|`--livenessProbeInterval <duration>`|更新存活检测文件的时间间隔。（缺省值 `0s`）|
|`--livenessProbePath <string>`|用于存活检测的文件路径。（缺省值 `''`）|
|`--maxConcurrentStreams <uint>`|每个连接的最大未完成 RPC 数。（缺省值 `1024`）|
|`--maxReceivedMessageSize <uint>`|每个 gRPC 消息的最大尺寸。（缺省值 `1048576`）|
|`--readinessProbeInterval <duration>`|就绪检测文件的更新间隔。（缺省值 `0s`）|
|`--readinessProbePath <string>`|就绪检测文件的路径。（缺省值 `''`）|

## `galley validator`

运行一个 https 服务器，用来进行 Istio 的配置验证。用 Kubernetes 验证 Webhook 进行 Pilot 和 Mixer 配置的验证。

{{< text bash >}}
$ galley validator [选项]
{{< /text >}}

|选项|描述|
|---|---|
|`--caCertFile <string>`|用于签署 `--tlsCertFile` 以及 `--tlsKeyFile` 中指定的证书和密钥的 `caBundle` 文件。（缺省值 `/etc/istio/certs/root-cert.pem`）|
|`--deployment-name <string>`|Galley Deployment 名称。（缺省值 `istio-galley`）|
|`--deployment-namespace <string>`|Galley Deployment 所在的命名空间。（缺省值 `istio-system`）|
|`--healthCheckFile <string>`|在启用了健康监测的情况下，进行周期性更新的文件名。（缺省值 `''`）|
|`--healthCheckInterval <string>`|`--healthCheckFile` 所指定的健康检查文件名称的更新频率。（缺省值 `0s`）|
|`--monitoringPort <duration>`|用于自监控信息的开放端口。（缺省值 `9093`）|
|`--port <uint>`|用于验证服务的 HTTPS 端口。如果服务端口不止一个，这里取值必须是 443.（缺省值 `443`）|
|`--tlsCertFile <string>`| 用于 x509 认证的证书文件。（缺省值 `/etc/istio/certs/cert-chain.pem`）|
|`--tlsKeyFile <string>`|对应 `--tlsCertFile` 证书文件的 x509 密钥。（缺省值 `/etc/istio/certs/key.pem` ）|
|`--webhook-config-file <string>`|包含 Kubernetes 验证 Webhook 验证 YAML 的文件名。如果没有指定这一文件，验证功能关闭。（缺省值 `''`）|

## galley version

输出版本信息。

{{< text bash >}}
$ galley version [选项]
{{< /text >}}

|选项|缩写|描述|
|---|---|---|
|`--short`|`-s`|显示版本概要信息。|
