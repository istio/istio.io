---
title: istio_ca
description: Istio 证书颁发（CA）。
generator: pkg-collateral-docs
number_of_entries: 4
---

Istio 证书颁发（CA）。

{{< text bash >}}
$ istio_ca [flags]

{{< /text >}}

| 参数 | 描述 |
| --- | --- |
| `--append-dns-names` | 将 DNS 名称附加到 webhook 服务的证书。|
| `--cert-chain <string>` | 证书链文件的路径（ 默认为 `''`） |
| `--citadel-storage-namespace <string>` | Citadel pod 正在运行的命名空间。如果通过显式文件或其他存储机制指定了，则不会使用。（默认 `istio-system`） |
| `--ctrlz_address <string>` | 监听 ControlZ 内省设施的 IP 地址。使用 `'*'` 表示所有地址。（默认 `127.0.0.1`） |
| `--ctrlz_port <uint16>` | 用于 ControlZ 内省工具的 IP 端口（ 默认为 `9876`） |
| `--custom-dns-names <string>` | `account.namespace: customdns` 名称列表，以逗号分隔。（默认 `''`） |
| `--enable-profiling` | 启用监视 Citadel 的性能分析。|
| `--experimental-dual-use` | 启用两用模式。使用与 `SAN` 相同的 `CommonName` 生成证书。|
| `--grpc-host-identities <string>` | istio ca server 的主机名列表，以逗号分隔。（默认 `istio-ca`，`istio-citadel`） |
| `--grpc-port <int>` | Citadel GRPC 服务器的端口号。如果未指定，Citadel 将不会提供 GRPC 请求。（默认为 `8060`） |
| `--identity-domain <string>` | 用于标识的域（`default: cluster.local`）（默认为 `cluster.local`） |
| `--key-size <int>` | 生成私钥的大小（默认为 `2048`） |
| `--kube-config <string>` | 指定 kubeconfig 文件的路径。必须在不在 Kubernetes pod 内运行时指定。（默认 `''`） |
| `--listened-namespace <string>` | 选择要监听的 CA 的命名空间。如果未指定，Citadel 会尝试使用 ${NAMESPACE} 环境变量。如果两者都未设置，Citadel 将监听所有名称空间。（默认 `''`） |
| `--liveness-probe-interval <duration>` | 更新存活探针文件的时间间隔。（默认为 `0s`） |
| `--liveness-probe-path <string>` | 存活探针文件的路径。（默认 `''`） |
| `--log_as_json` | 输出控制台友好的 JSON 格式 |
| `--log_caller <string>` | 以逗号分隔的范围列表，其中包含调用者信息，范围可以是\[default，model\]中的任何一个（默认为 `''`） |
| `--log_output_level <string>` | 要输出的消息的最小日志记录级别，格式为 `<scope>` :  `<level>` ， `<scope>` :  `<level>` ，...其中 scope 可以是\[default，model\]之一和 level 可以是\[debug，info，warn，error，none\]之一（ 默认为 `default: info`） |
| `--log_rotate <string>` | 可选分割日志文件的路径（默认为 `''`） |
| `--log_rotate_max_age <int>` | 日志文件超过文件分割的最大寿命，将自动分割（以天为单位,0 表示无限制）（默认为 `30`） |
| `--log_rotate_max_backups <int>` | 删除旧文件之前要保留的最大日志文件备份数（0表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>` | 日志文件的最大大小（以兆为单位），超过该值日志文件将分割文件（默认为 `104857600`） |
| `--log_stacktrace_level <string>` | 捕获堆栈追踪的日志记录级别，逗号分隔的最小的每个范围，格式为 `<scope>` :  `<level>` ，`<scope: level>`，...其中 scope 可以是\[default，model\]之一和 level 可以是\[debug，info，warn，error，none\]之一（ 默认 `default: none`） |
| `--log_target <stringArray>` | 输出日志的路径集。这可以是任何路径以及特殊值 `stdout` 和 `stderr`（ 默认 `[stdout]`） |
| `--max-workload-cert-ttl <duration>` | 已发布工作负载证书的最大 TTL（默认为 `2160h0m0s`） |
| `--monitoring-port <int>` | 用于监控 Citadel 的端口号。如果未指定，Citadel 将禁用监控。（ 默认 `9093`） |
| `--org <string>` | 证书组织（ 默认 `''`） |
| `--probe-check-interval <duration>` | 检查 CA 的活跃性的间隔。（ 默认 `30s`） |
| `--requested-ca-cert-ttl <duration>` | 请求的工作负载 TTL（默认为 `8760h0m0s`） |
| `--root-cert <string>` | 根证书文件的路径（ 默认为 `''`） |
| `--self-signed-ca` | 指示是否使用自动生成的自签名 CA 证书。设置为 true 时，将忽略 `'--signing-cert'` 和 `'--signing-key'` 选项。|
| `--self-signed-ca-cert-ttl <duration>` | 自签名 CA 根证书的 TTL（默认为 `8760h0m0s`） |
| `--sign-ca-certs` | Citadel 是否为其他 CA 签署证书 |
| `--signing-cert <string>` | CA 签名证书文件的路径（默认为 `''`） |
| `--signing-key <string>` | CA 签名密钥文件的路径（默认为 `''`） |
| `--upstream-ca-address <string>` | 上游 CA 的 IP: 端口地址。设置后，CA 将依赖上游 Citadel 来配置自己的证书。（默认 `''`） |
| `--workload-cert-grace-period-ratio <float32>` | 工作负载证书轮换宽期限或者周期，作为工作负载证书 TTL 的比例。（默认 `0.5`） |
| `--workload-cert-min-grace-period <duration>` | 最小工作负载证书轮换宽期限或者周期。（ 默认 `10m0s`） |
| `--workload-cert-ttl <duration>` | 已发布工作负载证书的 TTL（ 默认为 `2160h0m0s`） |

## istio\_ca probe

检查本地运行的服务器的活跃度或准备情况

{{< text bash >}}
$ istio_ca probe [flags]

{{< /text >}}

| 参数 | 描述 |
| --- | --- |
| `--ctrlz_address <string>` | 监听 ControlZ 内省设施的 IP 地址。使用 `'*'` 表示所有地址。（ 默认 `127.0.0.1`） |
| `--ctrlz_port <uint16>` | 用于 ControlZ 内省工具的 IP 端口（ 默认为 `9876`） |
| `--interval <duration>` | 用于检查目标文件上次修改时间的持续时间。（ 默认为 `0s`） |
| `--log_as_json` | 输出控制台友好的 JSON 格式 |
| `--log_caller <string>` | 以逗号分隔的范围列表，其中包含调用者信息，范围可以是\[default，model\]中的任何一个（ 默认为 `''`） |
| `--log_output_level <string>` | 要输出的消息的最小日志记录级别，格式为 `<scope>` :  `<level>` ， `<scope>` :  `<level>` ，...其中 scope 可以是\[default，model\] 之一和 level 可以是\[debug，info，warn，error，none\]之一（ 默认为 `default: info`） |
| `--log_rotate <string>` | 可选分割日志文件的路径（ 默认为 `''`） |
| `--log_rotate_max_age <int>` | 日志文件超过文件分割的最大寿命（以天为单位，0表示无限制），将分割文件（默认为 `30`） |
| `--log_rotate_max_backups <int>` | 删除旧文件之前要保留的最大日志文件备份数（0表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>` | 日志文件的最大大小（以兆为单位），超过该值日志文件将分割文件（默认为 `104857600`） |
| `--log_stacktrace_level <string>` | 捕获堆栈追踪的日志记录级别，逗号分隔的最小的每个范围，格式为 `<scope>` :  `<level>` ，`<scope: level>`，...其中 scope 可以是\[default，model\] 之一和 level 可以是\[debug，info，warn，error，none\]之一（ 默认 `default: none`） |
| `--log_target <stringArray>` | 输出日志的路径集。这可以是任何路径以及特殊值 `stdout` 和 `stderr`（ 默认 `[stdout]`） |
| `--probe-path <string>` | 用于检查可用性的文件的路径。（ 默认 `''`） |

## istio\_ca version

打印出版本信息

{{< text bash >}}
$ istio_ca version [flags]

{{< /text >}}

| 参数 | 缩写 | 描述 |
| --- | --- | --- |
| `--ctrlz_address <string>` |  | 监听 ControlZ 内省设施的 IP 地址。使用 `'*'` 表示所有地址。（ 默认 `127.0.0.1`） |
| `--ctrlz_port <uint16>` |  | 用于 ControlZ 内省工具的 IP 端口（ 默认为 `9876`） |
| `--log_as_json` |  | 是输出控制台友好的 JSON 格式 |
| `--log_caller <string>` |  | 以逗号分隔的范围列表，其中包含调用者信息，范围可以是\[default，model\]中的任何一个（ 默认为 `''`） |
| `--log_output_level <string>` |  | 要输出的消息的最小日志记录级别，格式为 `<scope>` :  `<level>` ， `<scope>` :  `<level>` ，...其中 scope 可以是\[default，model\] 之一和 level 可以是\[debug，info，warn，error，none\]之一（ 默认为 `default: info`） |
| `--log_rotate <string>` |  | 可选分割日志文件的路径（ 默认为 `''`） |
| `--log_rotate_max_age <int>` |  | 日志文件超过文件分割的最大寿命（以天为单位，0表示无限制），将分割日志文件（默认为 `30`） |
| `--log_rotate_max_backups <int>` |  | 删除旧文件之前要保留的最大日志文件备份数（0表示无限制）（默认为 `1000`） |
| `--log_rotate_max_size <int>` |  | 日志文件的最大大小（以兆为单位），超过该日志文件将分割文件（默认为 `104857600`） |
| `--log_stacktrace_level <string>` |  | 捕获堆栈追踪的日志记录级别，逗号分隔的最小的每个范围，格式为 `<scope>` :  `<level>` ，`<scope: level>`，...其中 scope 可以是\[default，model\] 之一和 level 可以是\[debug，info，warn，error，none\]之一（ 默认 `default: none`） |
| `--log_target <stringArray>` |  | 输出日志的路径集。这可以是任何路径以及特殊值 `stdout` 和 `stderr`（ 默认 `[stdout]`） |
| `--short` | `-s` | 显示简短的版本信息 |
