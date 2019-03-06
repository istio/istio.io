---
title: 调试授权
description: 展示授权功能的调试过程。
weight: 5
keywords: [debug,security,authorization,RBAC]
---

这篇文章展示了调试 Istio 授权功能的过程。

{{< idea >}}
如果能够按照[报告错误](/zh/about/bugs)的说明生成集群状态存档，会对调试过程产生很大帮助
{{< /idea >}}

## 确保授权功能已经正确启用

`ClusterRbacConfig` 是一个集群级的单例 CRD，用于控制全局的授权功能。

1. 运行下面的命令来列出现存的 `ClusterRbacConfig`：

    {{< text bash >}}
    $ kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
    {{< /text >}}

1. 这里应该**只有一个** `ClusterRbacConfig` 实例，其名称应该是 `default`。否则 Istio 会禁用授权功能并忽略所有策略。

    {{< text plain >}}
    NAMESPACE   NAME      AGE
    default     default   1d
    {{< /text >}}

1. 如果上面步骤中出现了不止一个的 `ClusterRbacConfig` 实例，请删除其它的 `ClusterRbacConfig`，保证集群之中只有一个名为 `default` 的 `ClusterRbacConfig`。

## 检查 Pilot 的工作状态

Pilot 负责对授权策略进行转换，并将其传播给 Sidecar。下面的的步骤可以用于确认 Pilot 是否能够正常工作：

1. 运行下列命令，导出 Pilot 的 `ControlZ`：

    {{< text bash >}}
    $ kubectl port-forward $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -n istio-system 9876:9876
    {{< /text >}}

1. 正常情况下应该看到如下输出：

    {{< text plain >}}
    Forwarding from 127.0.0.1:9876 -> 9876
    {{< /text >}}

1. 用浏览器打开 `http://127.0.0.1:9876/scopez/`，浏览 `ControlZ` 页面。

1. 将 `rbac` 输出级别修改为 `debug`。

1. 在步骤 1 中打开的终端窗口中输入 `Ctrl+C`，终止端口转发进程。

1. 输出 Pilot 日志，在其中搜索 `rbac`：

    {{< tip >}}
    你可能需要先删除并重建授权策略，以保证调试日志能够根据这些策略正常生成。
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system | grep rbac
    {{< /text >}}

1. 检查输出：

    * 没有出现错误。
    * 出现 `"built filter config for ..."` 消息，意味着为目标服务生成了过滤器。

1. 例如你可能会看到类似这样的内容：

    {{< text plain >}}
    2018-07-26T22:25:41.009838Z debug rbac building filter config for {sleep.foo.svc.cluster.local map[app:sleep pod-template-hash:3326367878] map[destination.name:sleep destination.namespace:foo destination.user:default]}
    2018-07-26T22:25:41.009915Z info  rbac no service role in namespace foo
    2018-07-26T22:25:41.009957Z info  rbac no service role binding in namespace foo
    2018-07-26T22:25:41.010000Z debug rbac generated filter config: { }
    2018-07-26T22:25:41.010114Z info  rbac built filter config for sleep.foo.svc.cluster.local
    2018-07-26T22:25:41.182400Z debug rbac building filter config for {productpage.default.svc.cluster.local map[pod-template-hash:2600844901 version:v1 app:productpage] map[destination.name:productpage destination.namespace:default destination.user:bookinfo-productpage]}
    2018-07-26T22:25:41.183131Z debug rbac checking role app2-grpc-viewer
    2018-07-26T22:25:41.183214Z debug rbac role skipped for no AccessRule matched
    2018-07-26T22:25:41.183255Z debug rbac checking role productpage-viewer
    2018-07-26T22:25:41.183281Z debug rbac matched AccessRule[0]
    2018-07-26T22:25:41.183390Z debug rbac generated filter config: {policies:<key:"productpage-viewer" value:<permissions:<and_rules:<rules:<or_rules:<rules:<header:<name:":method" exact_match:"GET" > > > > > > principals:<and_ids:<ids:<any:true > > > > >  }
    2018-07-26T22:25:41.184407Z info  rbac built filter config for productpage.default.svc.cluster.local
    {{< /text >}}

    说明 Pilot 生成了：

    * 针对 `sleep.foo.svc.cluster.local` 的配置是空的，原因是没有符合条件的策略可以使用，结果是 Istio 缺省情况下，会禁止所有对这一服务的访问。

    * `productpage.default.svc.cluster.local` 的配置让 Istio 放行所有针对该服务的 GET 访问。

## 确认 Pilot 正确的将策略分发给了代理服务器

Pilot 负责向代理服务器分发授权策略。下面的步骤用来确认 Pilot 的分发工作状态。

{{< tip >}}
这里的命令假设用户已经部署了 [Bookinfo](/zh/docs/examples/bookinfo/)，否则的话应该将 `"-l app=productpage"` 部分根据实际情况进行替换。
{{< /tip >}}

1. 运行下面的命令，获取 `productpage` 服务的代理配置信息：

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/config_dump -s
    {{< /text >}}

1. 校验日志内容：

    * 日志中包含了一个 `envoy.filters.http.rbac` 过滤器，会针对进入请求执行授权策略。
    * 授权策略更新之后，Istio 会据此更新过滤器。

1. 后续输出表明，`productpage` 的代理服务器启用了 `envoy.filters.http.rbac` 过滤器，这个过滤器允许任何人通过 `GET` 方法进行访问。`shadow_rules` 没有生效，可以安全忽略。

    {{< text json >}}
    {
     "name": "envoy.filters.http.rbac",
     "config": {
      "rules": {
       "policies": {
        "productpage-viewer": {
         "permissions": [
          {
           "and_rules": {
            "rules": [
             {
              "or_rules": {
               "rules": [
                {
                 "header": {
                  "exact_match": "GET",
                  "name": ":method"
                 }
                }
               ]
              }
             }
            ]
           }
          }
         ],
         "principals": [
          {
           "and_ids": {
            "ids": [
             {
              "any": true
             }
            ]
           }
          }
         ]
        }
       }
      },
      "shadow_rules": {
       "policies": {}
      }
     }
    },
    {{< /text >}}

## 确认策略在代理服务器中正确执行

代理是授权策略的最终实施者。下面的步骤帮助用户确认代理的工作情况：

{{< tip >}}
这里的命令假设用户已经部署了 [Bookinfo](/zh/docs/examples/bookinfo/)，否则的话应该将 `"-l app=productpage"` 部分根据实际情况进行替换。
{{< /tip >}}

1. 在代理中打开授权调试日志：

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -X POST localhost:15000/logging?rbac=debug -s
    {{< /text >}}

1. 检查输出内容是否包含如下内容：

    {{< text plain >}}
    active loggers:
      ... ...
      rbac: debug
      ... ...
    {{< /text >}}

1. 在浏览器中打开 `productpage`，以便生成日志。

1. 用命令输出代理日志：

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. 检查日志内容：

    * 输出日志中可能包含 `enforced allowed` 或者 `enforced denied`，表示请求被允许或者拒绝。

    * 授权策略需要从请求中获取数据。

1. 下面的输出表示，有请求 `productpage` 的 `GET` 请求被策略放行。

    `shadow denied` 没有实际效果，可以忽略。

    {{< text plain >}}
    ...
    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:79] checking request: remoteAddress: 10.60.0.139:51158, localAddress: 10.60.0.93:9080, ssl: uriSanPeerCertificate: spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account, subjectPeerCertificate: O=, headers: ':authority', '35.238.0.62'
    ':path', '/productpage'
    ':method', 'GET'
    'upgrade-insecure-requests', '1'
    'user-agent', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36'
    'dnt', '1'
    'accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
    'accept-encoding', 'gzip, deflate'
    'accept-language', 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7'
    'x-forwarded-for', '10.60.0.1'
    'x-forwarded-proto', 'http'
    'x-request-id', 'e23ea62d-b25d-91be-857c-80a058d746d4'
    'x-b3-traceid', '5983108bf6d05603'
    'x-b3-spanid', '5983108bf6d05603'
    'x-b3-sampled', '1'
    'x-istio-attributes', 'CikKGGRlc3RpbmF0aW9uLnNlcnZpY2UubmFtZRINEgtwcm9kdWN0cGFnZQoqCh1kZXN0aW5hdGlvbi5zZXJ2aWNlLm5hbWVzcGFjZRIJEgdkZWZhdWx0Ck8KCnNvdXJjZS51aWQSQRI/a3ViZXJuZXRlczovL2lzdGlvLWluZ3Jlc3NnYXRld2F5LTc2NjY0Y2NmY2Ytd3hjcjQuaXN0aW8tc3lzdGVtCj4KE2Rlc3RpbmF0aW9uLnNlcnZpY2USJxIlcHJvZHVjdHBhZ2UuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbApDChhkZXN0aW5hdGlvbi5zZXJ2aWNlLmhvc3QSJxIlcHJvZHVjdHBhZ2UuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbApBChdkZXN0aW5hdGlvbi5zZXJ2aWNlLnVpZBImEiRpc3RpbzovL2RlZmF1bHQvc2VydmljZXMvcHJvZHVjdHBhZ2U='
    'content-length', '0'
    'x-envoy-internal', 'true'
    'sec-istio-authn-payload', 'CkVjbHVzdGVyLmxvY2FsL25zL2lzdGlvLXN5c3RlbS9zYS9pc3Rpby1pbmdyZXNzZ2F0ZXdheS1zZXJ2aWNlLWFjY291bnQSRWNsdXN0ZXIubG9jYWwvbnMvaXN0aW8tc3lzdGVtL3NhL2lzdGlvLWluZ3Jlc3NnYXRld2F5LXNlcnZpY2UtYWNjb3VudA=='
    , dynamicMetadata: filter_metadata {
      key: "istio_authn"
      value {
        fields {
          key: "request.auth.principal"
          value {
            string_value: "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
          }
        }
        fields {
          key: "source.principal"
          value {
            string_value: "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"
          }
        }
      }
    }

    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:88] shadow denied
    [2018-07-26 20:39:18.060][152][debug][rbac] external/envoy/source/extensions/filters/http/rbac/rbac_filter.cc:98] enforced allowed
    ...
    {{< /text >}}

