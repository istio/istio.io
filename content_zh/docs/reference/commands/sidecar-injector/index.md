# Sidecar 注入器

Kubernetes 自动注入 Istio sidecar 的 webhook。

```bash
Sidecar 注入器 [选项]
```

| 选项                               | 描述                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| `--caCertFile <string>`            | HTTPS x509 证书文件（默认为 `/etc/istio/certs/root-cert.pem`） |
| `--healthCheckFile <string>`       | 健康检查打开时，定期更新的状态文件（默认为 `''`）            |
| `--healthCheckInterval <duration>` | 配置 --healthCheckFile 选项制定的健康检查文件的更新频率（默认为 `0s`） |
| `--injectConfig <string>`          | Istio sidecar 注入配置和模板文件（默认为 `/etc/istio/inject/config`） |
| `--kubeconfig <string>`            | 指定 kubeconfig 文件目录，Istio 不在 Kubernetes pod 中运行时，必须指定该参数（默认为 `''`） |
| `--log_as_json`                    | 配置是否用 JSON 格式化日志输出                               |
| `--log_caller <string>`            | 指定调用方信息的逗号分割 scope，可以是以下任意类型 [default, model]（默认为 `''`） |
| `--log_output_level <string>`      | 以逗号分隔的 scope 日志输出等级，格式为 <scope>:<level>,<scope>:<level>,... scope 支持[default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:info`） |
| `--log_rotate <string>`            | 日志切割文件路径，可选（默认为 `''`）                        |
| `--log_rotate_max_age <int>`       | 以天为单位，配置日志切割的间隔（0 表示无限制）（默认为 `30`） |
| `--log_rotate_max_backups <int>`   | 日志切割文件备份保留的最大个数（0 表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>`      | 以兆为单位，配置日志文件大小的上限，如超过，进行日志切割（默认为 `104857600`） |
| `--log_stacktrace_level <string>`  | 以逗号分隔的 scope stack trace 捕获日志等级，格式为 <scope>:<level>,<scope:level>,... scope 支持 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:none`） |
| `--log_target <stringArray>`       | 输出日志路径的数组，可以配置任何路径，包括 stdout、stderr 等特殊值（默认为 `[stdout]`） |
| `--meshConfig <string>`            | Istio mesh 配置文件（默认为 `/etc/istio/config/mesh`）       |
| `--port <int>`                     | Webhook 端口（默认为 `443`）                                 |
| `--tlsCertFile <string>`           | HTTPS x509 证书文件（默认为 `/etc/istio/certs/cert-chain.pem`） |
| `--tlsKeyFile <string>`            | 和 --tlsCertFile 匹配的 x509 私钥文件（默认为 `/etc/istio/certs/key.pem`） |
| `--webhookConfigName <string>`     | Kubernetes mutatingwebhookconfiguration 资源名（默认为 `istio-sidecar-injector`） |
| `--webhookName <string>`           | webhook 配置中 webhook 项名（默认为 `sidecar-injector.istio.io`） |

## sidecar 注入器探针

检查本地运行服务器的保活和可用性

```bash
Sidecar 注入器探针 [选项]
```

| 选项                               | 描述                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| `--caCertFile <string>`            | HTTPS x509 证书（默认为 `/etc/istio/certs/root-cert.pem`）   |
| `--healthCheckFile <string>`       | 健康检查打开时，定期更新的状态文件（默认为 `''`）            |
| `--healthCheckInterval <duration>` | 配置 --healthCheckFile 选项指定的健康检查文件的更新频率（默认为 `0s`） |
| `--injectConfig <string>`          | Istio sidecar 注入配置和模板文件（默认为 `/etc/istio/inject/config`） |
| `--interval <duration>`            | 检查目标文件是否更新的时间间隔（默认为 `0s`）                |
| `--kubeconfig <string>`            | 指定 kubeconfig 文件目录，Istio 不在 Kubernetes pod 中运行时，必须指定该参数（默认为 `''`） |
| `--log_as_json`                    | 配置是否用 JSON 格式化日志输出                               |
| `--log_caller <string>`            | 指定调用方信息的逗号分割 scope，可以是以下任意类型 [default, model]（默认为 `''`） |
| `--log_output_level <string>`      | 以逗号分隔的 scope 日志输出等级，格式为 <scope>:<level>,<scope>:<level>,... scope 可为 [default model] 日志等级包括 [debug, info, warn, error, none] （默认为 `default:info`） |
| `--log_rotate <string>`            | 日志切割文件路径，可选（默认为 `''`）                        |
| `--log_rotate_max_age <int>`       | 以天为单位，配置日志切割的间隔（0 表示无限制）（默认为 `30`） |
| `--log_rotate_max_backups <int>`   | 日志切割文件备份保留的最大个数（0 表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>`      | 以兆为单位，配置日志文件大小的上限，如超过，进行日志切割（默认为 `104857600`） |
| `--log_stacktrace_level <string>`  | 以逗号分隔的 stack trace 捕获日志等级，最小界别为 scope，格式为 <scope>:<level>,<scope:level>,... scope 支持 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:none`） |
| `--log_target <stringArray>`       | 输出日志路径的数组，可以配置任何路径，包括 stdout、stderr 等特殊值（默认为 `[stdout]`） |
| `--meshConfig <string>`            | Istio mesh 配置文件（默认为 `/etc/istio/config/mesh`）       |
| `--port <int>`                     | Webhook 端口（默认为 `443`）                                 |
| `--probe-path <string>`            | 检查可用性的文件路径（默认为 `''`）                          |
| `--tlsCertFile <string>`           | HTTPS x509 证书文件（默认为 `/etc/istio/certs/cert-chain.pem`） |
| `--tlsKeyFile <string>`            | 和 --tlsCertFile 匹配的 x509 私钥文件（默认为 `/etc/istio/certs/key.pem`） |
| `--webhookConfigName <string>`     | Kubernetes mutatingwebhookconfiguration 资源名（默认为 `istio-sidecar-injector`） |
| `--webhookName <string>`           | webhook 配置中 webhook 项名（默认为 `sidecar-injector.istio.io`） |

## Sidecar 注入器版本

输出构建版本信息

```bash
Sidecar 注入器版本 [选项]
```

| 选项                               | 缩写 | 描述                                                         |
| ---------------------------------- | ---- | ------------------------------------------------------------ |
| `--caCertFile <string>`            |      | HTTPS x509 证书文件（默认为 `/etc/istio/certs/root-cert.pem`） |
| `--healthCheckFile <string>`       |      | 健康检查打开时，定期更新的状态文件（默认为 `''`）            |
| `--healthCheckInterval <duration>` |      | 配置 --healthCheckFile 选项制定的健康检查文件的更新频率（默认为 `0s`） |
| `--injectConfig <string>`          |      | Istio sidecar 注入配置和模板文件（默认为 `/etc/istio/inject/config`） |
| `--kubeconfig <string>`            |      | 指定 kubeconfig 文件目录，Istio 不在 Kubernetes pod 中运行时，必须指定该参数（默认为 `''`） |
| `--log_as_json`                    |      | 配置是否用 JSON 格式化日志输出                               |
| `--log_caller <string>`            |      | 指定调用方信息的逗号分割 scope，可以是以下任意类型 [default, model]（默认为 ``） |
| `--log_output_level <string>`      |      | 以逗号分隔的 scope 日志输出等级，格式为 <scope>:<level>,<scope>:<level>,... scope 支持[default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:info`） |
| `--log_rotate <string>`            |      | 日志切割文件路径，可选（默认为 `''`）                        |
| `--log_rotate_max_age <int>`       |      | 以天为单位，配置日志切割的间隔（0 表示无限制）（默认为 `30`） |
| `--log_rotate_max_backups <int>`   |      | 日志切割文件备份保留的最大个数（0 表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>`      |      | 以兆为单位，配置日志文件大小的上限，如超过，进行日志切割（默认为 `104857600`） |
| `--log_stacktrace_level <string>`  |      | 以逗号分隔的 scope stack trace 捕获日志等级，格式为 <scope>:<level>,<scope:level>,... scope 支持 [default, model]，日志等级包括 [debug, info, warn, error, none] （默认为 `default:none`） |
| `--log_target <stringArray>`       |      | 输出日志路径的数组，可以配置任何路径，包括 stdout、stderr 等特殊值（默认为 `[stdout]`） |
| `--meshConfig <string>`            |      | Istio mesh 配置文件（默认为 `/etc/istio/config/mesh`）       |
| `--port <int>`                     |      | Webhook 端口（默认为 `443`）                                 |
| `--short`                          | `-s` | 显示版本信息的短格式                                         |
| `--tlsCertFile <string>`           |      | HTTPS x509 证书文件（默认为 `/etc/istio/certs/cert-chain.pem`） |
| `--tlsKeyFile <string>`            |      | 和 --tlsCertFile 匹配的 x509 私钥文件（默认为 `/etc/istio/certs/key.pem`） |
| `--webhookConfigName <string>`     |      | Kubernetes mutatingwebhookconfiguration 资源名（默认为 `istio-sidecar-injector`） |
| `--webhookName <string>`           |      | webhook 配置中，webhook 项的名字（默认为 `sidecar-injector.istio.io`） |
