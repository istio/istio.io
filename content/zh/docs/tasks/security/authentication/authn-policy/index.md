---
title: 认证策略
description: 为您展示如何使用 Istio 认证策略设置双向 TLS 和基础终端用户认证。
weight: 10
keywords: [security,authentication]
aliases:
    - /zh/docs/tasks/security/istio-auth.html
    - /zh/docs/tasks/security/authn-policy/
---

本任务涵盖了您在启用、配置和使用 Istio 认证策略时可能需要做的主要工作。更多基本概念介绍请查看[认证总览](/zh/docs/concepts/security/#authentication)。

## 开始之前{#before-you-begin}

* 理解 Istio [认证策略](/zh/docs/concepts/security/#authentication-policies)和[双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication)相关概念。
* 在 Kubernetes 集群中安装 Istio 并禁用全局双向 TLS (例如，使用[安装步骤](/zh/docs/setup/getting-started)提到的 demo 配置文件，或者设置 `global.mtls.enabled` 安装选项为 false )。

### 设置{#setup}

我们的示例用到两个命名空间 `foo` 和 `bar`，以及两个服务 `httpbin` 和 `sleep`，这两个服务都带有 Envoy sidecar proxy 一起运行。我们也会用到两个运行在 `legacy` 命名空间下不带 sidecar 的 `httpbin` 和 `sleep` 实例。如果您想要使用相同的示例尝试任务，执行如下命令：

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

您可以在命名空间 `foo`、`bar` 或 `legacy` 下的任意 `sleep` pod 中使用 `curl` 发送一个 HTTP 请求给 `httpbin.foo`、`httpbin.bar` 或 `httpbin.legacy` 来验证。所有请求应该都成功返回 HTTP 代码 200。

例如，这里的一个从 `sleep.bar` 到 `httpbin.foo` 的检查可达性的命令：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name}) -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

这个单行命令可以方便地遍历所有可达性组合：

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 200
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

您还应该要验证系统中是否有默认的网格认证策略，可执行如下命令：

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
No resources found.
{{< /text >}}

{{< text bash >}}
$ kubectl get meshpolicies.authentication.istio.io
NAME      AGE
default   3m
{{< /text >}}

最后同样重要的是，验证示例服务没有应用 destination rule。您可以检查现有 destination rule 中的 `host:` 值并确保它们不匹配。例如：

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
    host: istio-policy.istio-system.svc.cluster.local
    host: istio-telemetry.istio-system.svc.cluster.local
{{< /text >}}

{{< tip >}}
您可能会看到 destination rules 配置了除上面显示以外的其他 hosts，这依赖于 Istio 的版本。但是，应该没有 destination rules 配置 `foo`、`bar` 和 `legacy` 命名空间中的 hosts，也没有配置通配符 `*`
{{< /tip >}}

## 自动双向 TLS{#auto-mutual-TLS}

默认情况下，Istio 跟踪迁移到 Istio 代理的服务器工作负载，并配置客户端代理以自动将双向 TLS 流量发送到这些工作负载，并将纯文本流量发送到没有 sidecar 的工作负载。

因此，具有代理的工作负载之间的所有流量都使用双向 TLS，而无需执行任何操作。例如，检查 `httpbin/header` 请求的响应。
使用双向 TLS 时，代理会将 `X-Forwarded-Client-Cert` 标头注入到后端的上游请求。存在该标头说明流量使用双向 TLS。例如：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl http://httpbin.foo:8000/headers -s | grep X-Forwarded-Client-Cert
"X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=<redacted>"
{{< /text >}}

当服务器没有 sidecar 时， `X-Forwarded-Client-Cert` 标头将不会存在，这意味着请求是纯文本的。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert
{{< /text >}}

## 全局启用 Istio 双向 TLS{#globally-enabling-Istio-mutual-TLS}

设置一个启用双向 TLS 的网格范围的认证策略，提交如下 *mesh authentication policy* ：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "authentication.istio.io/v1alpha1"
kind: "MeshPolicy"
metadata:
  name: "default"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

{{< tip >}}
网格认证策略使用[通用认证策略 API](/zh/docs/reference/config/security/istio.authentication.v1alpha1/)，它定义在集群作用域 `MeshPolicy` CRD 中。
 {{< /tip >}}

该策略规定网格上的所有工作负载只接收使用 TLS 的加密请求。如您所见，该认证策略的类型为：`MeshPolicy`。策略的名字必须是 `default`，并且不含 `targets` 属性（目的是应用到网格中所有服务上）。

这时候，只有接收方配置使用双向 TLS。如果您在 *Istio services* 之间执行 `curl` 命令（即，那些带有 sidecars 的服务），由于客户端仍旧使用纯文本，所有请求都会失败并报 503 错误。

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 503
sleep.foo to httpbin.bar: 503
sleep.bar to httpbin.foo: 503
sleep.bar to httpbin.bar: 503
{{< /text >}}

配置客户端，您需要设置 [destination rules](/zh/docs/concepts/traffic-management/#destination-rules) 来使用双向 TLS。也可以使用多 destination rules，为每个合适的服务（或命名空间）都配置一个。不过，更方便地方式是创建一个规则使用通配符 `*` 匹配所有服务，因此这也和网格范围的认证策略作用等同。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  host: "*.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< tip >}}
* 从 Istio 1.1 开始，只有客户端命名空间，服务端命名空间和 `global` 命名空间（默认是 `istio-system`）中的 destination rules 会按顺序提供给服务。
* Host 值 `*.local` 限制只与集群中的服务匹配，而不是外部服务。同时注意，destination rule 的名字或命名空间没有做限制。
* 在 `ISTIO_MUTUAL` TLS 模式下，Istio 将根据密钥和证书（例如客户端证书，密钥和 CA 证书）的内部实现为它们设置路径。
{{< /tip >}}

别忘了 destination rules 也可用于非授权原因例如设置金丝雀发布，不过要适用同样的优先顺序。因此，如果一个服务不管什么原因要求一个特定的 destination rule —— 例如，配置负载均衡 —— 这个规则必须包含一个简单的 `ISTIO_MUTUAL` 模式的 TLS 块，否则它将会被网格或者命名空间范围的 TLS 设置覆盖并使 TLS 失效。

重新执行上述测试命令，您将看到所有 Istio 服务间的请求现在都成功完成。

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

### 从非 Istio 服务到 Istio 服务的请求{#request-from-non-Istio-services-to-Istio-services}

非 Istio 服务，例如 `sleep.legacy` 没有 sidecar，所以它不能将要求的 TLS 连接初始化到 Istio 服务。这会导致从 `sleep.legacy` 到 `httpbin.foo` 或者 `httpbin.bar` 的请求失败：

{{< text bash >}}
$ for from in "legacy"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

{{< tip >}}
由于 Envoy 拒绝纯文本请求的方式，您将会在这个例子中看到 `curl` 返回 56 代码（接收网络数据失败）。
{{< /tip >}}

这个按预期工作，而且很不幸，没有解决办法，除非降低对这些服务的认证条件要求。

### 从 Istio 服务到非 Istio 服务的请求{#request-from-Istio-services-to-non-Istio-services}

尝试从 `sleep.foo` (或者 `sleep.bar`) 发送请求给 `httpbin.legacy`。您将看到请求失败，因为 Istio 按照指示在 destination rule 中配置了客户端使用双向 TLS，但是 `httpbin.legacy` 没有 sidecar，所以它处理不了。

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.legacy: 503
sleep.bar to httpbin.legacy: 503
{{< /text >}}

为了解决这个问题，我们可以为 `httpbin.legacy` 添加一个 destination rule 覆盖 TLS 设置。例如：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "httpbin-legacy"
 namespace: "legacy"
spec:
 host: "httpbin.legacy.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}

在您添加了 destination rule 后再次测试，确保它能通过：

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.legacy: 200
{{< /text >}}

{{< tip >}}
这个 destination rule 在服务端（`httpbin.legacy`）的命名空间中，因此它优先于定义在 `istio-system` 中的全局 destination rule。
{{< /tip >}}

### 请求从 Istio 服务到 Kubernetes API server{#request-from-Istio-services-to-Kubernetes-API-server}

Kubernetes API server 没有 sidecar，所以来自 Istio 服务的请求如 `sleep.foo` 将会失败，这跟发送请求给任何非 Istio 服务有相同的问题。

{{< text bash >}}
$ TOKEN=$(kubectl describe secret $(kubectl get secrets | grep default-token | cut -f1 -d ' ' | head -1) | grep -E '^token' | cut -f2 -d':' | tr -d ' \t')
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl https://kubernetes.default/api --header "Authorization: Bearer $TOKEN" --insecure -s -o /dev/null -w "%{http_code}\n"
000
command terminated with exit code 35
{{< /text >}}

再次，我们通过覆盖 API server (`kubernetes.default`) 的 destination rule 来纠正它。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "api-server"
 namespace: istio-system
spec:
 host: "kubernetes.default.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}

{{< tip >}}
当您安装 Istio 并启用双向 TLS 时，这个规则，会跟全局认证策略和上述 destination rule 一起被自动注入到系统中。
{{< /tip >}}

重新执行上述测试命令确认在规则添加后会返回 200：

{{< text bash >}}
$ TOKEN=$(kubectl describe secret $(kubectl get secrets | grep default-token | cut -f1 -d ' ' | head -1) | grep -E '^token' | cut -f2 -d':' | tr -d ' \t')
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl https://kubernetes.default/api --header "Authorization: Bearer $TOKEN" --insecure -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 清除部分 1{#cleanup-part-1}

删除在场景中添加的全局认证策略和 destination rules：

{{< text bash >}}
$ kubectl delete meshpolicy default
$ kubectl delete destinationrules httpbin-legacy -n legacy
$ kubectl delete destinationrules api-server -n istio-system
$ kubectl delete destinationrules default -n istio-system
{{< /text >}}

## 为每个命名空间或者服务启用双向 TLS{#enable-mutual-TLS-per-namespace-or-service}

除了为您的整个网格指定一个认证策略，Istio 也支持您为特定的命名空间或者服务指定策略。一个命名空间范围的策略优先级高于网格范围的策略，而服务范围的策略优先级更高。

### 命名空间范围的策略{#namespace-wide-policy}

下述示例展示为命名空间 `foo` 中的所有服务启用双向 TLS 的策略。如你所见，它使用的类型是 `Policy` 而不是 `MeshPolicy`，在这个案例中指定命名空间为 `foo`。如果您没有指定命名空间的值，策略将会应用默认命名空间。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "default"
  namespace: "foo"
spec:
  peers:
  - mtls: {}
EOF
{{< /text >}}

{{< tip >}}
与 *网格范围的策略* 类似，命名空间范围的策略必须命名为 `default`，并且没有限制任何具体服务（没有 `targets` 部分）。
{{< /tip >}}

添加相应的 destination rule：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "default"
  namespace: "foo"
spec:
  host: "*.foo.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< tip >}}
Host `*.foo.svc.cluster.local` 限制只匹配 `foo` 命名空间中的服务。
{{< /tip >}}

由于这些策略和 destination rule 只应用于命名空间 `foo` 中的服务，您应该会看到只有从没有 sidecar 的客户端(`sleep.legacy`) 到 `httpbin.foo` 的请求开始失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### 特定服务策略{#service-specific-policy}

您也可以为特定服务设置认证策略和 destination rule。执行这个命令为 `httpbin.bar` 服务设置另一个策略。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
EOF
{{< /text >}}

添加一个 destination rule：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
spec:
  host: "httpbin.bar.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< tip >}}
* 本示例中，我们 **不** 在元数据中指定命名空间而是将它放在命令行上（`-n bar`），这也有相同的作用。
* 认证策略和 destination rule 的名字没有限制。为了简单起见，本示例使用服务本身的名字。
{{< /tip >}}

再次，执行探查命令。跟预期一样，从 `sleep.legacy` 到 `httpbin.bar` 的请求开始失败因为同样的问题。

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

如果我们在命名空间 `bar` 中还有其它服务，我们应该会看到请求它们的流量将不会受到影响。除了添加更多服务来演示这个行为，我们也可以稍微编辑策略将其应用到一个具体端口：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
    ports:
    - number: 1234
  peers:
  - mtls: {}
EOF
{{< /text >}}

对 destination rule 也做相应修改：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
spec:
  host: httpbin.bar.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
    portLevelSettings:
    - port:
        number: 1234
      tls:
        mode: ISTIO_MUTUAL
EOF
{{< /text >}}

这个新策略将只应用在 `httpbin` 服务的 `1234` 端口。结果，双向 TLS 在 `8000` 端口上会再次失效而来自 `sleep.legacy` 的请求将会恢复正常工作。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.bar:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 策略优先级{#policy-precedence}

为了演示特定服务策略比命名空间范围的策略优先级高，您可以像下面一样为 `httpbin.foo` 添加一个禁用双向 TLS 的策略。
注意您已经为所有在命名空间 `foo` 中的服务创建了命名空间范围的策略来启用双向 TLS 并观察到从 `sleep.legacy` 到 `httpbin.foo` 的请求都会失败（如上所示）。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "overwrite-example"
spec:
  targets:
  - name: httpbin
EOF
{{< /text >}}

添加 destination rule:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "overwrite-example"
spec:
  host: httpbin.foo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

重新执行来自 `sleep.legacy` 的请求，您应该又会看到请求成功返回 200 代码，证明了特定服务策略覆盖了命名空间范围的策略。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 清除部分 2{#cleanup-part-2}

删除上面步骤中创建的策略和 destination rules：

{{< text bash >}}
$ kubectl delete policy default overwrite-example -n foo
$ kubectl delete policy httpbin -n bar
$ kubectl delete destinationrules default overwrite-example -n foo
$ kubectl delete destinationrules httpbin -n bar
{{< /text >}}

## 终端用户认证{#end-user-authentication}

为了体验这个特性，您需要一个有效的 JWT。该 JWT 必须和您用于该 demo 的 JWKS 终端对应。在这个教程中，我们使用来自 Istio 代码基础库的 [JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) 和 [JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json)
同时，为了方便，通过 `ingressgateway` 暴露 `httpbin.foo`（更多细节，查看 [ingress 任务](/zh/docs/tasks/traffic-management/ingress/)）。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: foo
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: foo
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - route:
    - destination:
        port:
          number: 8000
        host: httpbin.foo.svc.cluster.local
EOF
{{< /text >}}

获取 ingress IP

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

执行一个查询测试

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

现在，为 `httpbin.foo` 添加一个要求配置终端用户 JWT 的策略。下面的命令假定 `httpbin.foo` 没有特定服务策略（如果您执行了[清除](#cleanup-part-2)所述的操作，就会是这样）。您可以执行 `kubectl get policies.authentication.istio.io -n foo` 进行确认。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
spec:
  targets:
  - name: httpbin
  origins:
  - jwt:
      issuer: "testing@secure.istio.io"
      jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

之前相同的 `curl` 命令将会返回 401 错误代码，由于服务器结果期望 JWT 却没有提供：

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

附带上上面生成的有效 token 将返回成功：

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

为了观察 JWT 验证的其它方面，使用脚本 [`gen-jwt.py`]({{< github_tree >}}/security/tools/jwt/samples/gen-jwt.py) 生成新 tokens 带上不同的发行人、受众、有效期等等进行测试。这个脚本可以从 Istio 库下载：

{{< text bash >}}
$ wget {{< github_file >}}/security/tools/jwt/samples/gen-jwt.py
$ chmod +x gen-jwt.py
{{< /text >}}

您还需要 `key.pem` 文件：

{{< text bash >}}
$ wget {{< github_file >}}/security/tools/jwt/samples/key.pem
{{< /text >}}

{{< tip >}}
下载 [jwcrypto](https://pypi.org/project/jwcrypto) 库，如果您还没有在您的系统上安装的话。
{{< /tip >}}

例如，下述命令创建一个 5 秒钟过期的 token。如您所见，Istio 使用这个 token 刚开始认证请求成功，但是 5 秒后拒绝了它们。

{{< text bash >}}
$ TOKEN=$(./gen-jwt.py ./key.pem --expire 5)
$ for i in `seq 1 10`; do curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"; sleep 1; done
200
200
200
200
200
401
401
401
401
401
{{< /text >}}

您也可以给一个 ingress gateway 添加一个 JWT 策略（例如，服务 `istio-ingressgateway.istio-system.svc.cluster.local`）。
这个常用于为绑定到这个 gateway 的所有服务定义一个 JWT 策略，而不是单独的服务。

### 按路径要求的终端用户认证{#end-user-authentication-with-per-path-requirements}

终端用户认证可以基于请求路径启用或者禁用。如果您想要让某些路径禁用认证就非常有用，例如，用于健康检查或者状态报告的路径。
您也可以为不同的路径指定不同的 JWT。

{{< warning >}}
按路径要求的终端用户认证在 Istio 1.1 中是一个实验性的特性并 **不** 推荐在生产环境中使用。
{{< /warning >}}

#### 为指定路径禁用终端用户认证{#disable-end-user-authentication-for-specific-paths}

修改 `jwt-example` 策略禁用路径 `/user-agent` 的终端用户认证：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
spec:
  targets:
  - name: httpbin
  origins:
  - jwt:
      issuer: "testing@secure.istio.io"
      jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
      trigger_rules:
      - excluded_paths:
        - exact: /user-agent
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

确认 `/user-agent` 路径允许免 JWT tokens 访问：

{{< text bash >}}
$ curl $INGRESS_HOST/user-agent -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

确认不带 JWT tokens 的非 `/user-agent` 路径拒绝访问：

{{< text bash >}}
$ curl $INGRESS_HOST/headers -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

#### 为指定路径启用终端用户认证{#enable-end-user-authentication-for-specific-paths}

修改 `jwt-example` 策略启用路径 `/ip` 的终端用户认证：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
spec:
  targets:
  - name: httpbin
  origins:
  - jwt:
      issuer: "testing@secure.istio.io"
      jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
      trigger_rules:
      - included_paths:
        - exact: /ip
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

确认不带 JWT tokens 的非 `/ip` 路径允许访问：

{{< text bash >}}
$ curl $INGRESS_HOST/user-agent -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

确认不带 JWT tokens 的 `/ip` 路径拒绝访问：

{{< text bash >}}
$ curl $INGRESS_HOST/ip -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

确认带有效 JWT token 的 `/ip` 路径允许访问：

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" $INGRESS_HOST/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 带双向 TLS 的终端用户认证{#end-user-authentication-with-mutual-TLS}

终端用户认证和双向 TLS 可以共用。修改上面的策略定义双向 TLS 和终端用户 JWT 认证：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "jwt-example"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
  origins:
  - jwt:
      issuer: "testing@secure.istio.io"
      jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
  principalBinding: USE_ORIGIN
EOF
{{< /text >}}

添加一个 destination rule：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin"
  namespace: "foo"
spec:
  host: "httpbin.foo.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

{{< tip >}}
如果您已经启用网格范围或者命名空间范围的 TLS，那么 host `httpbin.foo` 已经被这些 destination rule 覆盖。
因此，您不需要添加这个 destination rule 。另外，您仍然需要添加 `mtls` 段到认证策略，因为特定服务策略将完全覆盖网格范围（或者命名空间范围）的策略。
{{< /tip >}}

修改这些后，从 Istio 服务，包括 ingress gateway，到 `httpbin.foo` 的流量将使用双向 TLS。上述测试命令将仍然会正常工作。给定正确的 token，从 Istio 服务直接到 `httpbin.foo` 的请求也会正常工作：

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
200
{{< /text >}}

然而，来自非 Istio 服务，使用纯文本的请求将会失败：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name}) -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
000
command terminated with exit code 56
{{< /text >}}

### 清除部分 3{#cleanup-part-3}

1. 删除认证策略：

    {{< text bash >}}
    $ kubectl -n foo delete policy jwt-example
    {{< /text >}}

1. 删除 destination rule：

    {{< text bash >}}
    $ kubectl -n foo delete destinationrule httpbin
    {{< /text >}}

1. 如果您不打算研究后续任务，您只需简单删除测试命名空间即可删除所有资源：

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}
