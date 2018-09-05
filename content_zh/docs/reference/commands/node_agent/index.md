---
title: node_agent
description: 每个节点代理的 Istio 安全性。
generator: pkg-collateral-docs
number_of_entries: 3
---

每个节点代理的 Istio 安全性。

```bash
node_agent [flags]

```

| 参数 | 描述 |
| --- | --- |
| `--ca-address <string>` | Istio CA 地址（默认\`istio\-citadel：8060\`） |
| `--cert-chain <string>` | 节点代理身份证书文件（默认\`/ etc / certs / cert\-chain.pem\`） |
| `--env <string>` | 节点环境：未指定| onprem | gcp | aws（默认\`未指定\`） |
| `--experimental-dual-use` | 启用两用模式。 使用与 SAN 相同的 CommonName 生成证书。 |
| `--key <string>` | 节点代理私钥文件（默认\`/ etc / certs / key.pem\`） |
| `--key-size <int>` | 生成私钥的大小（默认为“2048”） |
| `--log_as_json` | 是将输出格式化为 JSON 还是以简单的控制台友好格式 |
| `--log_caller <string>` | 以逗号分隔的范围列表，其中包含被调用信息，范围可以是\[default\]中的任何一个（默认为\`\`） |
| `--log_output_level <string>` | 要输出的消息的最小日志记录级别可以是\[debug，info，warn，error，none\]之一（默认为\`default：info\`） |
| `--log_rotate <string>` | 可选旋转日志文件的路径（默认为\`\`） |
| `--log_rotate_max_age <int>` | 日志文件超过文件旋转的最大年龄（0表示无限制）（默认为“30”） |
| `--log_rotate_max_backups <int>` | 删除旧文件之前要保留的最大日志文件备份数（0表示无限制）（默认为“1000”） |
| `--log_rotate_max_size <int>` | 日志文件的最大大小（以兆字节为单位），超过该日志文件将旋转文件（默认为“104857600”） |
| `--log_stacktrace_level <string>` | 捕获堆栈跟踪的最小日志记录级别可以是\[debug，info，warn，error，none\]之一（默认为“default：none”） |
| `--log_target <stringArray>` | 输出日志的路径集。 这可以是任何路径以及特殊值 stdout 和 stderr（默认\`\[stdout\]\`） |
| `--org <string>` | 证书组织（默认\`\`） |
| `--platform <string>` | 平台 istio 运行于：vm | k8s（默认\`vm\`） |
| `--root-cert <string>` | 根证书文件（默认\`/ etc / certs / root\-cert.pem\`） |
| `--workload-cert-ttl <duration>` | 请求的工作负载 TTL（默认为“2160h0m0s”） |

## node\_agent 版本[](#node_agent-version)

打印出构建版本信息

```bash
node_agent version [flags]

```

| 参数 | 缩写 | 描述 |
| --- | --- | --- |
| `--log_as_json` |  | 是将输出格式化为 JSON 还是以简单的控制台友好格式 |
| `--log_caller <string>` |  | 以逗号分隔的范围列表，其中包含被调用信息，范围可以是\[default\]中的任何一个（默认为\`\`） |
| `--log_output_level <string>` |  | 要输出的消息的最小日志记录级别可以是\[debug，info，warn，error，none\]之一（默认为\`default：info\`） |
| `--log_rotate <string>` |  | 可选旋转日志文件的路径（默认为\`\`） |
| `--log_rotate_max_age <int>` |  | 日志文件超过文件旋转的最大年龄（0表示无限制）（默认为“30”） |
| `--log_rotate_max_backups <int>` |  | 删除旧文件之前要保留的最大日志文件备份数（0表示无限制）（默认为“1000”） |
| `--log_rotate_max_size <int>` |  | 日志文件的最大大小（以兆字节为单位），超过该日志文件将旋转文件（默认为“104857600”） |
| `--log_stacktrace_level <string>` |  | 捕获堆栈跟踪的最小日志记录级别可以是\[debug，info，warn，error，none\]之一（默认为“default：none”） |
| `--log_target <stringArray>` |  | 输出日志的路径集。 这可以是任何路径以及特殊值 stdout 和 stderr（默认\`\[stdout\]\`） |
| `--short` | `-s` | 显示版本信息的简短形式 |