---
title: 通过 istioctl describe 检查您的网格
description: 展示如何使用 istioctl describe 来验证网格中的 Pod 的配置。
weight: 30
keywords: [traffic-management, istioctl, debugging, kubernetes]
aliases:
  - /zh/docs/ops/troubleshooting/istioctl-describe
owner: istio/wg-user-experience-maintainers
test: no
---

{{< boilerplate experimental-feature-warning >}}

在 Istio 1.3 中，我们新增了 [`istioctl experimental describe`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod)
命令。一些配置可以影响 {{< gloss >}}Pod{{< /gloss >}}，要理解这些配置，
您可以利用这个命令行工具得到一些必要的信息。这份指南向您展示如何使用这个实验性质的命令来查看一个
Pod 是否在网格中并验证它的配置。

该命令的基本用法如下：

{{< text bash >}}
$ istioctl experimental describe <pod-name>[.<namespace>]
{{< /text >}}

向 Pod 名字后面加上一个命名空间与使用 `istioctl` 的 `-n`
参数来指定一个非默认的命名空间效果一样。

{{< tip >}}
和所有其它 `istioctl` 命令一样，您可以地用 `x` 来代替
`experimental`。
{{< /tip >}}

该指南假定您已经在您的网格中部署了 [Bookinfo](/zh/docs/examples/bookinfo/) 示例。
如果您还没部署，先参考[启动应用服务](/zh/docs/examples/bookinfo/#start-the-application-services)和[确定 ingress 的 IP 和端口](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)。

## 验证 pod 是否在网格中 {#verify-a-pod-is-in-the-mesh}

如果 Pod 里没有 {{< gloss >}}Envoy{{< /gloss >}} 代理或者代理没启动，`istioctl describe`
命令会返回一个警告。另外，如果 [Pod 的 Istio 需求](/zh/docs/ops/deployment/requirements/)未完全满足，
该命令也会警告。

例如，下面的命令发出的警告表示一个 `kube-dns` Pod 不被包含在服务网格内，
因为它没有 Sidecar：

{{< text bash >}}
$ export KUBE_POD=$(kubectl -n kube-system get pod -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod -n kube-system $KUBE_POD
Pod: coredns-f9fd979d6-2zsxk
   Pod Ports: 53/UDP (coredns), 53 (coredns), 9153 (coredns)
WARNING: coredns-f9fd979d6-2zsxk is not part of mesh; no Istio sidecar
--------------------
2021-01-22T16:10:14.080091Z     error   klog    an error occurred forwarding 42785 -> 15000: error forwarding port 15000 to pod 692362a4fe313005439a873a1019a62f52ecd02c3de9a0957cd0af8f947866e5, uid : failed to execute portforward in network namespace "/var/run/netns/cni-3c000d0a-fb1c-d9df-8af8-1403e6803c22": failed to dial 15000: dial tcp4 127.0.0.1:15000: connect: connection refused[]
Error: failed to execute command on sidecar: failure running port forward process: Get "http://localhost:42785/config_dump": EOF
{{< /text >}}

但对于服务网格内的 Pod，如 Bookinfo 的 `ratings` 服务，该命令就不会报警，
而是输出该 Pod 的 Istio 配置：

{{< text bash >}}
$ export RATINGS_POD=$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')
$ istioctl experimental describe pod $RATINGS_POD
Pod: ratings-v1-7dc98c7588-8jsbw
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP targets pod port 9080
{{< /text >}}

该输出展示了下列信息：

- Pod 内的服务容器的端口，如本例中的 `ratings` 容器的 `9080`。
- Pod 内的 `istio-proxy` 容器的端口，如本例中的 `15090`。
- Pod 内的服务所用的协议，如本例中的端口 `9080` 上的 `HTTP`。

## 验证 destination rule 配置{#verify-destination-rule-configurations}

您可以使用 `istioctl describe` 查看哪些
[destination rule 规则](/zh/docs/concepts/traffic-management/#destination-rules)被用来将请求路由到
Pod。例如，应用 Bookinfo [双向 TLS destination rule 规则]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml)：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

现在再来 `describe` 一次 `ratings` 的 Pod：

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pod: ratings-v1-f745cf57b-qrxl2
   Pod Ports: 9080 (ratings), 15090 (istio-proxy)
--------------------
Service: ratings
   Port: http 9080/HTTP
DestinationRule: ratings for "ratings"
   Matching subsets: v1
      (Non-matching subsets v2,v2-mysql,v2-mysql-vm)
   Traffic Policy TLS Mode: ISTIO_MUTUAL
{{< /text >}}

该命令现在显示了更多的输出：

- 用于路由到 `ratings` 服务的请求的 destination rule。
- 匹配该 Pod 的 `ratings` destination rule 的子集，本例中为 `v1`。
- 该 destination rule 所定义的其它子集。
- 该 Pod 同时接受 HTTP 和 双向 TLS 请求，客户端使用双向 TLS。

## 验证 virtual service 规则 {#verify-virtual-service-configurations}

当 [virtual services](/zh/docs/concepts/traffic-management/#virtual-services)
配置路由到一个 Pod 时，`istioctl describe` 也会在它的输出中包含这些路由。
例如，应用 [Bookinfo virtual services]({{< github_file>}}/samples/bookinfo/networking/virtual-service-all-v1.yaml)
这个将所有请求都路由到 `v1` Pod 的规则：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

然后，describe 一个实现了 `reviews` 服务的 `v1` 版本的 Pod：

{{< text bash >}}
$ export REVIEWS_V1_POD=$(kubectl get pod -l app=reviews,version=v1 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   1 HTTP route(s)
{{< /text >}}

该输出包括了与上面展示的 `ratings` Pod 类似的信息，同时还有 virtual service
的到该 Pod 的路由。

`istioctl describe` 命令不仅仅展示影响该 Pod 的 virtual service。
如果一条 virtual service 配置了 Pod 的服务主机但却没有流量到达它，
该命令将会输出一个警告。这种情况可能会发生在 virtual service
实际上已经不再将流量路由到该 Pod 的子集而拦截了流量时。例如：

{{< text bash >}}
$ export REVIEWS_V2_POD=$(kubectl get pod -l app=reviews,version=v2 -o jsonpath='{.items[0].metadata.name}')
$ istioctl x describe pod $REVIEWS_V2_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Route to non-matching subset v1 for (everything)
{{< /text >}}

该警告包含了这个问题的原因，检查了多少个路由，甚至还会告诉您其它路由的信息。
在本例中，没有流量会到达 `v2` 的 Pod，因为 virtual service
中的路由将所有流量都路由到 `v1` 子集。

如果您选择删除掉 Bookinfo destination rules：

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

您可以看到 `istioctl describe` 的另外一个有用的功能：

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Warning: Route to subset v1 but NO DESTINATION RULE defining subsets!
{{< /text >}}

该输出说明您删除了 destination rule，但是依赖它的 virtual service 还在。
Virtual service 想将流量路由到 `v1` 子集，但是没有 destination rule
来定义 `v1` 子集。 因此，要去 `v1` 的流量就无法流向该 Pod。

如果您现在刷新浏览器来向 Bookinfo 发送一个新的请求，您将会看到这条消息：
`Error fetching product reviews`。要修复这个问题，请重新应用 destination rule：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

重新刷新浏览器，可以看到应用恢复工作了，运行 `istioctl experimental describe pod $REVIEWS_V1_POD`
也不再报出警告了。

## 验证流量路由{#verifying-traffic-routes}

`istioctl describe` 命令还可以展示流量的分隔权重。
例如，运行如下命令将 90% 的流量路由到 `reviews` 服务的 `v1` 子集，将
10% 路由到 `v2` 子集：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-90-10.yaml@
{{< /text >}}

现在来 describe `reviews v1` Pod：

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   Weight 90%
{{< /text >}}

该输出显示了 `reviews` virtual service 在 `v1` 子集上有 90% 的权重。

该功能对于别的类型的路由也很有用。例如，您可以部署指定请求头的路由：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
{{< /text >}}

然后，再次 describe 该 Pod：

{{< text bash >}}
$ istioctl x describe pod $REVIEWS_V1_POD
...
VirtualService: reviews
   WARNING: No destinations match pod subsets (checked 2 HTTP routes)
      Route to non-matching subset v2 for (when headers are end-user=jason)
      Route to non-matching subset v3 for (everything)
{{< /text >}}

该输出显示了一个警告，因为该 Pod 在 `v1` 子集。
但是，如果请求头包含 `end-user=jason`，该 virtual service 配置将会把流量路由到 `v2` 子集，
其余情况下都路由到 `v3` 子集。

## 验证严格双向 TLS{#verifying-strict-mutual-TLS}

按照[双向 TLS 迁移](/zh/docs/tasks/security/authentication/mtls-migration/)的说明，您可以为
`ratings` 服务启用严格双向 TLS：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "ratings-strict"
spec:
  selector:
    matchLabels:
      app: ratings
  mtls:
    mode: STRICT
EOF
{{< /text >}}

运行下列命令来 describe `ratings` 的 Pod：

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
Pilot reports that pod enforces mTLS and clients speak mTLS
{{< /text >}}

该输出说明到 `ratings` Pod 的请求已被锁定并且是安全的。

尽管如此，一个部署在切换双向 TLS 到 `STRICT` 模式时有时还是会中断。
这可能是因为 destination rule 与新配置不匹配。例如，如果您配置 Bookinfo
的客户端不用双向 TLS 而是用[普通 HTTP destination rules]({{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml)：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

如果您在浏览器中打开 Bookinfo，您会看到 `Ratings service is currently unavailable`。
想知道原因，请运行以下命令：

{{< text bash >}}
$ istioctl x describe pod $RATINGS_POD
...
WARNING Pilot predicts TLS Conflict on ratings-v1-f745cf57b-qrxl2 port 9080 (pod enforces mTLS, clients speak HTTP)
  Check DestinationRule ratings/default and AuthenticationPolicy ratings-strict/default
{{< /text >}}

该输出包含了一个警告，描述了 destination rule 和认证策略之间的冲突。

您可以通过应用一个使用双向 TLS 的 destination rule 来修复问题：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
{{< /text >}}

## 结论和清理 {#conclusion-and-cleanup}

我们对于 `istioctl x describe` 命令的期望是帮助您理解您的 Istio
网格中的流量和安全配置。

我们也希望能听到您的改善意见！
请在 [https://discuss.istio.io](https://discuss.istio.io) 参与讨论。

运行以下命令以删除 Bookinfo 的 Pod 和本指南中用到的配置：

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl delete -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
$ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}
