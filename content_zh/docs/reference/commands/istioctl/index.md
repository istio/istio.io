---
title: istioctl
weight: 30
description: Istio 控制界面。
---

## 简介

Istio 的命令行配置工具。

用于在 Istio 系统中创建、列出、修改以及删除配置资源。

可用的路由和流量管理配置类型：

[`virtualservice` `gateway` `destinationrule` `serviceentry` `httpapispec` `httpapispecbinding` `quotaspec` `quotaspecbinding` `servicerole` `servicerolebinding` `policy`]

阅读[参考文档](https://istio.io/docs/reference/)，可以获知更多 Istio 路由方面的内容。

## 全局选项

下表为全局参数，在每个子命令中都可以使用表格中的选项。

|选项|缩写|描述|
|---|---|---|
|`--context <string>`|| Istio 使用的 kubeconfig 上下文名称（缺省值 `''`）|
|`--istioNamespace <string>`|`-i`|Istio 所在的命名空间（缺省值 `istio-system`）|
|`--kubeconfig <string>`|`-c`|Kubernetes 配置文件（缺省值 `''`）|
|`--log_as_json`||是否将输出格式化为 JSON，缺省情况下会以控制台友好的纯文本格式进行输出|
|`--log_caller <string>`||以逗号作为分隔符的列表，用于指定日志中包含的调用者信息的范围，范围可以从这一列表中选择：`[ads, default, model, rbac]` （缺省值 `''`）
|`--log_output_level <string>`||以逗号作为分隔符的列表，指定每个范围的日志级别，格式为 `<scope>:<level>,<scope>:<level>...`，`scope` 是 `[ads, default, model, rbac]` 中的一个，日志级别可以选择 `[debug, info, warn, error, none]`（缺省值 `default:info`）|
|`--log_rotate <string>`||日志轮转文件的路径（缺省值 `''`）
|`--log_rotate_max_age <int>`||日志文件的最大寿命，以天为单位，超出之后会进行轮转（`0` 代表无限制，缺省值 `30`）
|`--log_rotate_max_backups <int>`||日志文件备份的最大数量，超出这一数量之后就会删除比较陈旧的文件。（`0` 代表无限制，缺省值 `1000`）
|`--log_rotate_max_size <int>`||日志文件的最大尺寸，以 M 为单位，超出限制之后会进行轮转（缺省值 `104857600`）|
|`--log_stacktrace_level <string>`||以逗号作为分隔符的列表，用于指定 Stack trace 时每个范围的最小日志级别，大致是 `<scope>:<level>,<scope:level>...` 的形式，`scope` 是 `[ads, default, model, rbac]` 中的一个，日志级别可以选择 `[debug, info, warn, error, none]`，（缺省值 `default:none`）|
|`--log_target <stringArray>`||一组用于输出日志的路径。可以是任何路径，也可以是 `stdout` 和 `stderr` 之类的特殊值。（缺省值 `[stdout]`）|
|`--namespace <string>`|`-n`|配置所在命名空间 （缺省值 ``）|
|`--platform <string>`|`-p`|Istio 主机平台（缺省值 `kube`）|

## `istioctl authn`

这一组命令用于同 Istio 认证策略进行交互。

该命令支持的子命令列表如下：

- `tls-check`

典型用例：

检查认证策略和目标规则之间的 TLS 设置是否匹配：

{{< text bash >}}
$ istioctl authn tls-check
{{< /text >}}

## `istioctl authn tls-check`

要求 Pilot 进行检查，服务注册表中的每个服务都在使用什么认证策略以及目标规则，以及 TLS 设置是否匹配。

基本用法：

{{< text bash >}}
$ istioctl [<服务>] [选项]
{{< /text >}}

典型用例：

{{< text shell >}}
# 检查服务注册表中所有已知服务的设置
istioclt authn tls-check

# 检查特定的某个服务
istioclt authn tls-check foo.bar.svc.cluster.local
{{< /text >}}

## `istioctl context-create`

在非 Kubernetes 环境中为 `istioctl` 创建一个 kubeconfig 文件。

基本用法：

{{< text bash >}}
$ istioctl context-create --api-server http://<ip 地址>:<端口> [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--api-server <string>`|| Istio api-server 的 URL（缺省值 `''`）|

典型用例：

{{< text shell >}}
# 为 API Server 创建一个配置文件：
istioctl context-create --api-server http://127.0.0.1:8080
{{< /text >}}

## `istioctl create`

创建策略或规则。

基本用法：

{{< text bash >}}
$ istioctl create [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--file <string>`|-f|用包含配置对象内容的文件作为命令输入（如果没有设置，命令会从标准输入中进行读取，缺省值 `''`）|

典型用例：

{{< text bash >}}
$ istioctl create -f example-routing.yaml
{{< /text >}}

## `istioctl delete`

删除策略或规则。

{{< text shell >}}
istioctl delete <类型> <名称> [<名称2> ... <名称 N>] [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--file <string>`|-f|用包含配置对象内容的文件作为命令输入（如果没有设置，命令会从标准输入中进行读取，缺省值 `''`）|

典型用例：

{{< text shell >}}
# 删除在文件 example-routing.yaml 中定义的规则
istioctl delete -f example-routing.yaml

# 删除 bookinfo 虚拟服务
istioctl delete virtualservice bookinfo
{{< /text >}}

## `istioctl deregister`

解除服务实例的注册。

{{< text bash >}}
$ istioctl deregister <服务名称> <ip 地址> [选项]
{{< /text >}}

## `istioctl experimental`

实验性命令，未来可能会修改或者弃用。

该命令支持的子命令列表如下：

- `convert-ingress`
- `metrics`
- `rbac`

## `istioctl experimental convert-ingress`

将 Ingress 转化为 VirtualService 配置。其输出内容可以作为 Istio 配置的起点，可能需要进行一些小修改。如果指定配置无法完美的完成转化，就会出现警告信息。输入内容必须是 Kubernetes Ingress。`Istioctl` 中已经移除了对 v1alpha1 的 Istio 规则的转换支持。

基本用法：

{{< text bash >}}
$ istioctl experimental convert-ingress [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--filenames <stringSlice>`|`-f`|输入文件名称（缺省值 `[]`）|

典型用例：

{{< text bash >}}
$ istioctl experimental convert-ingress -f samples/bookinfo/platform/kube/bookinfo-ingress.yaml
{{< /text >}}

## `istioctl experimental metrics`

在 Kubernetes 中可以使用这一命令打印指定服务的指标数据。

该命令会查找 Istio 系统命名空间中运行的 Prometheus Pod；接下来会为每个工作负载执行一系列的查询，得出以下指标：每秒总请求数、错误率以及请求延迟的 `p50`、`p90` 和 `p99` 分布。查询结果会输出到控制台，用工作负载名称进行分组。

返回的所有指标都是来自于服务端的报告的。这意味着延迟和错误率数据是来自于服务自身，而不是客户端（也不是客户端的聚合）。错误率和延迟的计算周期为一分钟。

{{< text bash >}}
$ istioctl experimental metrics <工作负载名称>...
{{< /text >}}

典型用例：

{{< text shell >}}
# 获取工作负载  productpage-v1 的指标数据
istioctl experimental metrics productpage-v1
# 获取多个不同命名空间中不同服务的指标数据
istioctl experimental metrics productpage-v1.foo reviews-v1.bar ratings-v1.baz
{{< /text >}}

## `istioctl experimental rbac`

这一组命令用来操作 Istio RBAC 策略。例如查询特定请求在当前 Istio RBAC 策略中是否会被拒绝。

{{< text shell >}}
# 查询是否允许用户 test 对服务 rating 进行 GET /v1/health 操作。
istioctl experimental rbac can -u test GET rating /v1/health
{{< /text >}}

## `istioctl experimental rbac can`

这一命令可以用来查询特定请求在当前 Istio RBAC 策略之中，是否会被拒绝。其原理是根据命令行中提供的主体和动作，构建一个请求，用来检查当前 Istio RBAC 策略是否会按照设计进行工作。需要注意的是，这个请求只会在本地用来评估 Istio RBAC 策略的实际效果，并不会产生真正的请求。

基本用法：

{{< text bash >}}
$ istioctl experimental rbac can <方法> <服务> <路径> [选项]
{{< /text >}}

- **方法**：指 HTTP 方法，例如 `GET` 和 `POST` 等。
- **服务**：服务名称。
- **路径**：服务中的 HTTP 路径。

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--action-properties <stringArray>`|`-a`|动作的附加数据。用 `name1=value1,name2=value2,...` 的方式赋值（缺省值为 `[]`）|
|`--groups <string>`|`-g`|主体的组名称或者 ID（缺省值 `''`）|
|`--subject-properties <stringArray>`|`-s`|主体的附加数据。用 `name1=value1,name2=value2,...` 的方式赋值（缺省值为 `[]`）
|`--user <string>`|`-u`|主体的用户名称或者 ID（缺省值 `''`）|

典型用例：

{{< text script >}}
# 查询是否允许用户 test 对服务 rating 进行 GET /v1/health 操作。
istioctl experimental rbac can -u test GET rating /v1/health

# 查询是否允许 product-page 服务对 ratings 服务的 /data 路径发起 POST 请求，其中的 ratings 服务需带有标签：version=dev
istioctl experimental rbac can -s service=product-page POST rating /data -a version=dev
{{< /text >}}

## `istioctl gen-deploy`

用于生成 Istio 的部署文件。

基本用法：

{{< text bash >}}
$ istioctl gen-deploy [选项]
{{< /text >}}

可用参数列表如下：

|选项|描述|
|---|---|
|`--debug`|如果为 True，会使用 Debug 镜像代替普通镜像|
|`--helm-chart-dir <string>`|在这一目录中查找 Helm chart 用来渲染生成 Istio 部署。（缺省值 `.`）|
|`--hyperkube-hub <string>`|用于拉取 Hyperkube 镜像的容器仓库（缺省值 `quay.io/coreos/hyperkube`）|
|`--hyperkube-tag <Hyperkube>`|Hyperkube 镜像的 Tag（缺省值 `v1.7.6_coreos.0`）|
|`--ingress-node-port <uint16>`|如果指定了这一选项，Istio ingress 会以 NodePort 的形式运行，并映射到这一选项指定的端口。注意，如果 `ingress` 选项没有打开，这一选项会被忽略（缺省值 `0`）|
|`--values <string>`|`values.yaml` 文件的路径，在使用 `--out=yaml` 时，会用来在本地渲染 YAML。如果直接使用这一文件，会忽略上面的选项值（缺省值 `''`）|

典型用例：

{{< text bash >}}
$ istioctl gen-deploy --values myvalues.yaml
{{< /text >}}

## `istioctl get`

获取规则和策略。

基本用法：

{{< text bash >}}
$ istioctl get <类型> [<名称>] [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--all-namespaces`||如果使用这一参数，会列出所有命名空间中的对象。当前 context 以及 `--namespace` 指定的命名空间都会被忽略|
|`--namespace <string>`|`-n`|目标命名空间（缺省值 `''`）|
|`--output <string>`|`-o`|输出格式，可选内容包括 `yaml` 以及 `short`（缺省值 `short`）|

典型用例：

{{< text script >}}
# 列出所有虚拟服务
istioctl get virtualservices

# 列出所有目标规则
istioctl get destinationrules

# 获取名为 bookinfo 的虚拟服务
istioctl get virtualservice bookinfo
{{< /text >}}

## `istioctl kube-inject`

`kube-inject` 子命令用来将 Envoy sidecar 注入到 Kubernetes 负载之中。执行过程中如果遇到无法支持的资源，会保持原样不进行修改，因此对于复杂应用中包含多种资源的输入文件来说，该命令也是安全的。资源初创时就是该操作的最佳执行时机。

目前 `Job`、`DaemonSet`、`ReplicaSet`、`Pod` 以及 `Deployment` 对象的 YAML 文档，都可以使用这一命令进行处理，修改其中的 [Pod Template](https://k8s.io/docs/concepts/workloads/pods/pod-overview/#pod-templates)，如果有必要的话，可以加入更多对基于 Pod 的资源类型的支持。

Istio 项目是一个持续进化的项目，所以 Istio sidecar 的配置可能在不经公示的情况下发生变更。在怀疑配置过期的时候，可以重新运行注入命令来更新注入代码。

`istioctl` 中内置了缺省的 Sidecar 注入模板，还可以使用参数 `--injectConfigFile` 或者 `--injectConfigMapName` 进行覆盖。这两个参数会覆盖其他的模板配置参数，例如 `--hub` 和 `--tag`。

基本用法：

{{< text bash >}}
$ istioctl kube-inject [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--filename <string>`|`-f`|Kubernetes 资源文件名（缺省值 `''`）|
|`--injectConfigFile <string>`||注入配置文件名，不能和 `--injectConfigMapName` 同时使用（缺省值 `''`）|
|`--injectConfigMapName <string>`||Istio sidecar 注入配置的 ConfigMap 名称，Key 名称是 `config`。这个选项会覆盖任何其他的 Sidecar 注入配置选项，例如 `--hub`（缺省值 `istio-sidecar-injector`）|
|`--output <string>`|`-o`|注入后输出的资源文件名（缺省值 `''`）|

典型用例：

{{< text shell >}}
# 在 Apply 之前进行对资源文件进行更新。
kubectl apply -f <(istioctl kube-inject -f <resource.yaml>)

# 对资源文件执行 Envoy sidecar 注入之后，保存为文件。
istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml

# 在线修改一个正在运行的 Deployment。
kubectl get deployment -o yaml | istioctl kube-inject -f - | kubectl apply -f -

# 使用 Configmap `istio-inject` 进行 Envoy sidecar 的注入，并生成持久化文件。
istioctl kube-inject -f deployment.yaml -o deployment-injected.yaml --injectConfigMapName istio-inject
{{< /text >}}

## `istioctl proxy-config`

这一组命令用来从 Envoy 中获取配置信息。

该命令支持的子命令列表如下：

- bootstrap
- cluster
- route

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--output <string>`|`-o`|输出格式，可选 `json` 或者 `short`（缺省值 `short`）|

典型用例：

{{< text shell >}}
# 从 Envoy 实例中获取代理配置方面的信息
istioctl proxy-config <clusters|listeners|routes|bootstap> <pod-name>
{{< /text >}}

## `istioctl proxy-config bootstrap`

在指定 Pod 中获取 Envoy 实例的启动信息。

基本用法：

{{< text bash >}}
$ istioctl proxy-config bootstrap <pod-name> [flags]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--output <string>`|`-o`|输出格式，可选 `json` 或者 `short`（缺省值 `short`）|

典型用例：

{{< text shell >}}
# 在指定 Pod 的 Envoy 中获取完整的 Bootstrap 信息。
istioctl proxy-config bootstrap <pod-name>
{{< /text >}}

## `istioctl proxy-config cluster`

从指定 Pod 中的 Envoy 实例里读取集群配置信息。

基本用法：

{{< text bash >}}
$ istioctl proxy-config cluster <pod-name> [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--direction <string>`||使用 `direction` 字段对集群进行过滤（缺省值 `''`）|
|`--fqdn <string>`||使用服务 `fqdn` 字段对集群进行过滤（缺省值 `''`）|
|`--output <string>`|`-o`|输出格式，可选 `json` 或者 `short`（缺省值 `short`）|
|`--port <int>`||使用 `port` 字段对集群进行过滤 (缺省值 `0`)|
|`--subset <string>`||使用 `subset` 字段对集群进行过滤 (缺省值 `''`)|

典型用例：

{{< text shell >}}
# 从选定 Pod 的 Envoy 中获取集群配置的概要信息。
istioctl proxy-config clusters <pod-name>

# 使用 9080 端口获取集群概要信息。
istioctl proxy-config clusters <pod-name> --port 9080

# 获取 FQDN 为 details.default.svc.cluster.local 的完整的集群信息
istioctl proxy-config clusters <pod-name> --fqdn details.default.svc.cluster.local --direction inbound -o json
{{< /text >}}

## `istioctl proxy-config listener`

从选定 Pod 的 Envoy 中获取监听器信息。

基本用法：

{{< text bash >}}
$ istioctl proxy-config listener <pod-name> [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--address <string>`||使用 `address` 对监听器进行过滤（缺省值 `''`）|
|`--output <string>`|`-o`|输出格式，可选 `json` 或者 `short`（缺省值 `short`）|
|`--port <int>`||使用 `port` 对监听器进行过滤（缺省值 `0`）|
|`--type <string>`||使用 `type` 对监听器进行过滤（缺省值 `''`）|

典型用例：

{{< text shell >}}
# 从指定 Pod 的 Envoy 中获取监听器配置概要信息。
istioctl proxy-config listeners <pod-name>

# 获取 9080 端口的监听器概要信息。
istioctl proxy-config listeners <pod-name> --port 9080

# 使用通配符地址（0.0.0.0）获取完整的 HTTP 监听器信息。
istioctl proxy-config listeners <pod-name> --type HTTP --address 0.0.0.0 -o json
{{< /text >}}

## `istioctl proxy-config route`

获取最后发送和最后确认的从 Pilot 到网格中每个 Envoy 的 xDS 同步信息。

基本用法：

{{< text bash >}}
$ istioctl proxy-status [<proxy-name>] [参数]
{{< /text >}}

典型用例：

{{< text shell >}}
# 获取网格中每个 Envoy 的同步状态。
istioctl proxy-status

# 获取单一 Envoy 的同步信息。
istioctl proxy-status istio-egressgateway-59585c5b9c-ndc59.istio-system
{{< /text >}}

## `istioctl register`

把一个服务实例（例如虚拟机）注册到网格之中。

基本用法：

{{< text bash >}}
$ istioctl register <svcname> <ip> [name1:]port1 [name2:]port2 ... [flags]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--annotations <stringSlice>`|`-a`|一个字符串列表，用于给注册服务或者端点提供注解，例如 `-a foo=bar,test,x=y` （缺省值 `[]`）|
|`--serviceaccount <string>`|`-s`|绑定到该服务的 Service account（缺省值 `default`）|

## `istioctl replace`

替换现存的策略和规则。

基本用法：

{{< text bash >}}
$ istioctl replace [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--file <string>`|`-f`|用包含配置对象内容的文件作为命令输入（如果没有设置，命令会从标准输入中进行读取，缺省值 `''`）|

典型用例：

{{< text bash >}}
$ istioctl replace -f example-routing.yaml
{{< /text >}}

## `istioctl version`

输出版本信息。

基本用法：

{{< text bash >}}
$ istioctl version [选项]
{{< /text >}}

可用参数列表如下：

|选项|缩写|描述|
|---|---|---|
|`--short`|`-s`|显示摘要信息|