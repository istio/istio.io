---
title: 在双栈模式中安装 Istio
description: 在双栈 Kubernetes 集群上以双栈模式安装和使用 Istio。
weight: 70
keywords: [dual-stack]
owner: istio/wg-networking-maintainers
test: yes
---

{{< boilerplate experimental >}}

## 先决条件 {#prerequisites}

* Istio 1.17 或更高版本。
* Kubernetes 1.23 或更高版本并[配置为双栈操作](https://kubernetes.io/zh-cn/docs/concepts/services-networking/dual-stack/)。

## 安装步骤 {#installation-steps}

如果您想使用 `kind` 进行测试，可以使用以下命令建立双栈集群：

{{< text syntax=bash snip_id=none >}}
$ kind create cluster --name istio-ds --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
EOF
{{< /text >}}

要为 Istio 启用双栈，您需要使用以下配置修改 `IstioOperator` 或 Helm 值。

{{< tabset category-name="dualstack" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_DUAL_STACK: "true"
  values:
    pilot:
      env:
        ISTIO_DUAL_STACK: "true"
    # 以下值是可选的，可以根据您的要求使用
    gateways:
      istio-ingressgateway:
        ipFamilyPolicy: RequireDualStack
      istio-egressgateway:
        ipFamilyPolicy: RequireDualStack
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text syntax=yaml snip_id=none >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ISTIO_DUAL_STACK: "true"
values:
  pilot:
    env:
      ISTIO_DUAL_STACK: "true"
  # 以下值是可选的，可以根据您的要求使用
  gateways:
    istio-ingressgateway:
      ipFamilyPolicy: RequireDualStack
    istio-egressgateway:
      ipFamilyPolicy: RequireDualStack
{{< /text >}}

{{< /tab >}}

{{< tab name="Istioctl" category-value="istioctl" >}}

{{< text syntax=bash snip_id=none >}}
$ istioctl install --set values.pilot.env.ISTIO_DUAL_STACK=true --set meshConfig.defaultConfig.proxyMetadata.ISTIO_DUAL_STACK="true" --set values.gateways.istio-ingressgateway.ipFamilyPolicy=RequireDualStack --set values.gateways.istio-egressgateway.ipFamilyPolicy=RequireDualStack -y
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 验证 {#verification}

1. 创建三个命名空间：

    * `dual-stack`: `tcp-echo` 将监听 IPv4 和 IPv6 地址。
    * `ipv4`: `tcp-echo` 将仅侦听 IPv4 地址。
    * `ipv6`: `tcp-echo` 将仅侦听 IPv6 地址。

    {{< text bash >}}
    $ kubectl create namespace dual-stack
    $ kubectl create namespace ipv4
    $ kubectl create namespace ipv6
    {{< /text >}}

1. 在所有这些命名空间以及 `default` 命名空间上启用 Sidecar 注入：

    {{< text bash >}}
    $ kubectl label --overwrite namespace default istio-injection=enabled
    $ kubectl label --overwrite namespace dual-stack istio-injection=enabled
    $ kubectl label --overwrite namespace ipv4 istio-injection=enabled
    $ kubectl label --overwrite namespace ipv6 istio-injection=enabled
    {{< /text >}}

1. 在命名空间中创建 [tcp-echo]({{< github_tree >}}/samples/tcp-echo) 部署：

    {{< text bash >}}
    $ kubectl apply --namespace dual-stack -f @samples/tcp-echo/tcp-echo-dual-stack.yaml@
    $ kubectl apply --namespace ipv4 -f @samples/tcp-echo/tcp-echo-ipv4.yaml@
    $ kubectl apply --namespace ipv6 -f @samples/tcp-echo/tcp-echo-ipv6.yaml@
    {{< /text >}}

1. 部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用程序以用作发送请求的测试源。

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. 验证到达双栈 Pod 的流量：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo.dual-stack 9000"
    hello dualstack
    {{< /text >}}

1. 验证到达 IPv4 Pod 的流量：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv4 | nc tcp-echo.ipv4 9000"
    hello ipv4
    {{< /text >}}

1. 验证到达 IPv6 Pod 的流量：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
    hello ipv6
    {{< /text >}}

1. 验证 Envoy 侦听器：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl proxy-config listeners "$(kubectl get pod -n dual-stack -l app=tcp-echo -o jsonpath='{.items[0].metadata.name}')" -n dual-stack --port 9000
    {{< /text >}}

    您将看到侦听器现在绑定到多个地址，但仅限于双堆栈服务。其他服务将仅侦听单个 IP 地址。

    {{< text syntax=json snip_id=none >}}
        "name": "fd00:10:96::f9fc_9000",
        "address": {
            "socketAddress": {
                "address": "fd00:10:96::f9fc",
                "portValue": 9000
            }
        },
        "additionalAddresses": [
            {
                "address": {
                    "socketAddress": {
                        "address": "10.96.106.11",
                        "portValue": 9000
                    }
                }
            }
        ],
    {{< /text >}}

1. 验证虚拟入站地址是否配置为同时侦听 `0.0.0.0` 和 `[::]`。

    {{< text syntax=json snip_id=none >}}
    "name": "virtualInbound",
    "address": {
        "socketAddress": {
            "address": "0.0.0.0",
            "portValue": 15006
        }
    },
    "additionalAddresses": [
        {
            "address": {
                "socketAddress": {
                    "address": "::",
                    "portValue": 15006
                }
            }
        }
    ],
    {{< /text >}}

1. 验证 Envoy 端点是否被配置为同时路由到 IPv4 和 IPv6：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl proxy-config endpoints "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" --port 9000
    ENDPOINT                 STATUS      OUTLIER CHECK     CLUSTER
    10.244.0.19:9000         HEALTHY     OK                outbound|9000||tcp-echo.ipv4.svc.cluster.local
    10.244.0.26:9000         HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
    fd00:10:244::1a:9000     HEALTHY     OK                outbound|9000||tcp-echo.dual-stack.svc.cluster.local
    fd00:10:244::18:9000     HEALTHY     OK                outbound|9000||tcp-echo.ipv6.svc.cluster.local
    {{< /text >}}

现在您可以在您的环境中试验双栈服务！

## 清理 {#cleanup}

1. 清理应用程序命名空间和部署

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    $ kubectl delete ns dual-stack ipv4 ipv6
    {{< /text >}}
