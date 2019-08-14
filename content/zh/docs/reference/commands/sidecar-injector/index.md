---
title: sidecar-injector
weight: 10
description: 自动注入 Istio sidecar 的 Kubernetes webhook。
---

## sidecar-injector

自动注入 Istio sidecar 的 Kubernetes webhook。

{{< text bash >}}
$ sidecar-injector [选项]
{{< /text >}}

| 选项                               | 描述                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| `--caCertFile <string>`            | HTTPS x509 证书文件（默认为 `/etc/istio/certs/root-cert.pem`） |
| `--healthCheckFile <string>`       | 健康检查打开时，定期更新的文件（默认为 `''`）            |
| `--healthCheckInterval <duration>` | `--healthCheckFile` 选项指定的健康检查文件的更新频率（默认为 `0s`） |
| `--injectConfig <string>`          | 包含 Istio sidecar 注入配置和模板的文件（默认为 `/etc/istio/inject/config`） |
| `--kubeconfig <string>`            | kubeconfig 文件所在目录，Istio 不在 Kubernetes pod 中运行时，必须指定该参数（默认为 `''`） |
| `--log_as_json`                    | 是否用 JSON 格式化日志输出                               |
| `--log_caller <string>`            | 以逗号为分隔符的域（scope）列表，包含调用方信息，域（scope）可以是以下任意类型 [default, model]（默认为 `''`） |
| `--log_output_level <string>`      | 以逗号为分隔符的域（scope）列表，指定每个域（scope）的日志输出等级，格式为 `<scope>:<level>,<scope>:<level>,...`，域（scope）支持以下类型 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:info`） |
| `--log_rotate <string>`            | 日志轮转文件路径，可选（默认为 `''`）                        |
| `--log_rotate_max_age <int>`       | 日志文件的最大寿命，以天为单位，超出后会进行轮转（`0` 表示无限制）（默认为 `30`） |
| `--log_rotate_max_backups <int>`   | 日志文件备份保留的最大数量（`0` 表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>`      | 日志文件大小的上限，以 M 为单位，超出后进行轮转（默认为 `104857600`） |
| `--log_stacktrace_level <string>`  | 以逗号为分隔符的域（scope）列表，配置每个域（scope）的 stack trace 日志等级，格式为 `<scope>:<level>,<scope>:<level>,...`，域（scope）支持以下类型 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:none`） |
| `--log_target <stringArray>`       | 输出日志路径的数组，可以是任何路径，包括 `stdout`、`stderr` 等特殊值（默认为 `[stdout]`） |
| `--meshConfig <string>`            | Istio mesh 配置文件（默认为 `/etc/istio/config/mesh`）       |
| `--port <int>`                     | Webhook 端口（默认为 `443`）                                 |
| `--tlsCertFile <string>`           | HTTPS x509 证书文件（默认为 `/etc/istio/certs/cert-chain.pem`） |
| `--tlsKeyFile <string>`            | 和 `--tlsCertFile` 匹配的 x509 私钥文件（默认为 `/etc/istio/certs/key.pem`） |
| `--webhookConfigName <string>`     | Kubernetes `mutatingwebhookconfiguration` 资源名（默认为 `istio-sidecar-injector`） |
| `--webhookName <string>`           | webhook 配置中 webhook 项名（默认为 `sidecar-injector.istio.io`） |

## sidecar-injector probe

检查本地运行服务器的活性和是否就绪

{{< text bash >}}
$ sidecar-injector probe [选项]
{{< /text >}}

| 选项                               | 描述                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| `--caCertFile <string>`            | HTTPS x509 证书（默认为 `/etc/istio/certs/root-cert.pem`）   |
| `--healthCheckFile <string>`       | 健康检查打开时，定期更新的文件（默认为 `''`）            |
| `--healthCheckInterval <duration>` | `--healthCheckFile` 选项指定的健康检查文件的更新频率（默认为 `0s`） |
| `--injectConfig <string>`          | 包含 Istio sidecar 注入配置和模板的文件（默认为 `/etc/istio/inject/config`） |
| `--interval <duration>`            | 检查目标文件是否更新的周期（默认为 `0s`）                |
| `--kubeconfig <string>`            | kubeconfig 文件所在目录，Istio 不在 Kubernetes pod 中运行时，必须指定该参数（默认为 `''`） |
| `--log_as_json`                    | 是否用 JSON 格式化日志输出                               |
| `--log_caller <string>`            | 以逗号为分隔符的域（scope）列表，包含调用方信息，域（scope）可以是以下任意类型 [default, model]（默认为 `''`） |
| `--log_output_level <string>`      | 以逗号为分隔符的域（scope）列表，指定每个域（scope）的日志输出等级，格式为 `<scope>:<level>,<scope>:<level>,...`，域（scope）支持以下类型 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:info`） |
| `--log_rotate <string>`            | 日志轮转文件路径，可选（默认为 `''`）                        |
| `--log_rotate_max_age <int>`       | 日志文件的最大寿命，以天为单位，超出后会进行轮转（0 表示无限制）（默认为 `30`） |
| `--log_rotate_max_backups <int>`   | 日志文件备份保留的最大数量（0 表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>`      | 日志文件大小的上限，以 M 为单位，超出后进行轮转（默认为 `104857600`） |
| `--log_stacktrace_level <string>`  | 以逗号为分隔符的域（scope）列表，配置每个域（scope）的 stack trace 日志等级，格式为 `<scope>:<level>,<scope>:<level>,...`，域（scope）支持以下类型 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:none`） |
| `--log_target <stringArray>`       | 输出日志路径的数组，可以是任何路径，包括 `stdout`、`stderr` 等特殊值（默认为 `[stdout]`） |
| `--meshConfig <string>`            | Istio mesh 配置文件（默认为 `/etc/istio/config/mesh`）       |
| `--port <int>`                     | Webhook 端口（默认为 `443`）                                 |
| `--probe-path <string>`            | 检查可用性的文件路径（默认为 `''`）                          |
| `--tlsCertFile <string>`           | HTTPS x509 证书文件（默认为 `/etc/istio/certs/cert-chain.pem`） |
| `--tlsKeyFile <string>`            | 和 `--tlsCertFile` 匹配的 x509 私钥文件（默认为 `/etc/istio/certs/key.pem`） |
| `--webhookConfigName <string>`     | Kubernetes `mutatingwebhookconfiguration` 资源名（默认为 `istio-sidecar-injector`） |
| `--webhookName <string>`           | webhook 配置中 webhook 项名（默认为 `sidecar-injector.istio.io`） |

## sidecar-injector version

输出构建版本信息

{{< text bash >}}
$ sidecar-injector version [选项]
{{< /text >}}

| 选项                               | 缩写 | 描述                                                         |
| ---------------------------------- | ---- | ------------------------------------------------------------ |
| `--caCertFile <string>`            |      | HTTPS x509 证书文件（默认为 `/etc/istio/certs/root-cert.pem`） |
| `--healthCheckFile <string>`       |      | 健康检查打开时，定期更新的文件（默认为 `''`）            |
| `--healthCheckInterval <duration>` |      | `--healthCheckFile` 选项指定的健康检查文件的更新频率（默认为 `0s`） |
| `--injectConfig <string>`          |      | 包含 Istio sidecar 注入配置和模板的文件（默认为 `/etc/istio/inject/config`） |
| `--kubeconfig <string>`            |      | kubeconfig 文件所在目录，Istio 不在 Kubernetes pod 中运行时，必须指定该参数（默认为 `''`） |
| `--log_as_json`                    |      | 是否用 JSON 格式化日志输出                               |
| `--log_caller <string>`            |      | 以逗号为分隔符的域（scope）列表，包含调用方信息，域（scope）可以是以下任意类型 [default, model]（默认为 ``） |
| `--log_output_level <string>`      |      | 以逗号为分隔符的域（scope）列表，指定每个域（scope）的日志输出等级，格式为 `<scope>:<level>,<scope>:<level>,...`，域（scope）支持以下类型 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:info`）|
| `--log_rotate <string>`            |      | 日志轮转文件路径，可选（默认为 `''`）                        |
| `--log_rotate_max_age <int>`       |      | 日志文件的最大寿命，以天为单位，超出后会进行轮转（0 表示无限制）（默认为 `30`） |
| `--log_rotate_max_backups <int>`   |      | 日志文件备份保留的最大数量（0 表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>`      |      | 日志文件大小的上限，以 M 为单位，超出后进行轮转（默认为 `104857600`） |
| `--log_stacktrace_level <string>`  |      | 以逗号为分隔符的域（scope）列表，配置每个域（scope）的 stack trace 日志等级，格式为 `<scope>:<level>,<scope>:<level>,...`，域（scope）支持以下类型 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:none`）|
| `--log_target <stringArray>`       |      | 输出日志路径的数组，可以是任何路径，包括 `stdout`、`stderr` 等特殊值（默认为 `[stdout]`） |
| `--meshConfig <string>`            |      | Istio mesh 配置文件（默认为 `/etc/istio/config/mesh`）       |
| `--port <int>`                     |      | Webhook 端口（默认为 `443`）                                 |
| `--short`                          | `-s` | 显示版本信息的短格式                                         |
| `--tlsCertFile <string>`           |      | HTTPS x509 证书文件（默认为 `/etc/istio/certs/cert-chain.pem`） |
| `--tlsKeyFile <string>`            |      | 和 `--tlsCertFile` 匹配的 x509 私钥文件（默认为 `/etc/istio/certs/key.pem`） |
| `--webhookConfigName <string>`     |      | Kubernetes `mutatingwebhookconfiguration` 资源名（默认为 `istio-sidecar-injector`） |
| `--webhookName <string>`           |      | webhook 配置中，webhook 项的名字（默认为 `sidecar-injector.istio.io`） |
