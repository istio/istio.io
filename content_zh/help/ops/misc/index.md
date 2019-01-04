---
title: 杂项
description: 关于解决 Istio 常见问题的建议。
weight: 90
force_inline_toc: true
---

## 验证与 Istio Pilot 的连通性

验证与 Pilot 的连接是否正常是很有用的排查问题的步骤。在服务网格中的每一个代理容器都应该能够和 Pilot 进行通信。这可以通过几个简单的步骤完成：

1.  获取 Istio Ingress pod 名称:

    {{< text bash >}}
    $ INGRESS_POD_NAME=$(kubectl get po -n istio-system | grep ingressgateway\- | awk '{print$1}'); echo ${INGRESS_POD_NAME};
    {{< /text >}}

1.  通过 Exec 进入 Istio Ingress pod 中:

    {{< text bash >}}
    $ kubectl exec -it $INGRESS_POD_NAME -n istio-system /bin/bash
    {{< /text >}}

1.  使用 `curl` 测试到 Pilot 的连通性。下面的例子使用 Pilot 默认配置参数和启用双向 TLS 认证来调用 v1 registration API ：

    {{< text bash >}}
    $ curl -k --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem --key /etc/certs/key.pem https://istio-pilot:15003/v1/registration
    {{< /text >}}

    如果禁用双向 TLS 认证:

    {{< text bash >}}
    $ curl http://istio-pilot:15003/v1/registration
    {{< /text >}}

您应该接收到列出在这个服务网格中每个服务的 "service-key" 和 "hosts" 的返回。

## 在 Mac 上本地运行 Istio 时，Zipkin 中没有出现任何追踪轨迹

安装了 Istio，一切似乎都在工作，除了 Zipkin 中没有出现追踪轨迹，但本应该出现。

这可能是由已知的 [Docker 问题](https://github.com/docker/for-mac/issues/1260) 引起的，
容器可能会与宿主机上的时间有明显偏差。如果是这种情况，当你在Zipkin中选择一个非常长的日期范围时，你会发现这些追踪轨迹太早出现了几天。

您还可以通过将 docker 容器内的日期与外部进行比较来确认此问题：

{{< text bash >}}
$ docker run --entrypoint date gcr.io/istio-testing/ubuntu-16-04-slave:latest
Sun Jun 11 11:44:18 UTC 2017
{{< /text >}}

{{< text bash >}}
$ date -u
Thu Jun 15 02:25:42 UTC 2017
{{< /text >}}

要解决此问题，您需要在重新安装 Istio 之前关闭然后重新启动 Docker。

## 如果 kube-apiserver 具有代理设置，则 sidecar 自动注入将失败

当 Kube-apiserver 包含代理设置时，例如：

{{< text yaml >}}
env:
  - name: http_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
  value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
  value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
{{< /text >}}

sidecar 注入将失败。唯一相关的故障日志位于 kube-apiserver 日志中：

{{< text plain >}}
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
{{< /text >}}

确保 pod 和 service CIDR 都没有通过 *_proxy 变量来代理。检查 kube-apiserver 文件和日志以验证配置以及是否正在代理任何请求。

一个解决方法是从 kube-apiserver 配置中删除代理设置，然后重新启动服务器或使用更高版本的 Kubernetes。

向Kubernetes提出了与此相关的问题，此后一直关闭。
[https://github.com/kubernetes/kubeadm/issues/666](https://github.com/kubernetes/kubeadm/issues/666)
[https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)

## Istio 使用的 Envoy 版本是什么？

要查找 envoy 的版本，您可以按照以下步骤操作：

1. `kubectl exec -it PODNAME -c istio-proxy -n NAMESPACE /bin/bash`

1. `curl localhost:15000/server_info`
