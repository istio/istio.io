---
title: 调试授权
description: 展示如何调试授权功能。
weight: 5
keywords: [debug,security,authorization,RBAC]
---

这篇文章展示了如何调试 Istio 的授权。

{{< idea >}}
按照[报告错误](/zh/about/bugs)的说明，在您的电子邮件中包含集群状态存档会非常有用。
{{< /idea >}}

## 确保授权正常启用

`rbacConfig` 默认集群单例自定义资源在全局上控制授权功能。

1. 运行下面的命令来展示已有的 `RbacConfig`:

    {{< text bash >}}
    $ kubectl get rbacconfigs.rbac.istio.io --all-namespaces
    {{< /text >}}

1. 确保 `RbacConfig` 只有**一个**实例，并且名为 `default`。否则 Istio 会关闭授权功能，并且忽略所有的授权策略。

    {{< text plain >}}
    NAMESPACE   NAME      AGE
    default     default   1d
    {{< /text >}}

1. 如果有多余一个 `RbacConfig` 实例，将额外的 `RbacConfig` 实例删除，并且保证**只有一个**叫做 `default` 的实例。

## 确保 Pilot 接受授权策略

Pilot 将授权策略转换并且分发给代理。下面的步骤可以帮你确保 Pilot 正常工作：

1. 运行下面的命令来导入 Pilot `ControlZ`:

    {{< text bash >}}
    $ kubectl port-forward $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -n istio-system 9876:9876
    {{< /text >}}

1. 确认你看到如下输出：

    {{< text plain >}}
    Forwarding from 127.0.0.1:9876 -> 9876
    {{< /text >}}

1. 启动你的浏览器，并且通过 `http://127.0.0.1:9876/scopez/` 访问 `ControlZ` 页面。

1. 将 `rbac` 的输出级别改为 `debug`。

1. 使用 `Ctrl+C` 来结束你在步骤1中启动的 port-forward 命令。

1. 通过下面的命令来打印 Pilot 的日志，并且搜索 `rbac`：

    {{< tip >}}
    你可以需要先删除然后重新下发你的授权策略，这样debug日志才能正常被生成。
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl logs $(kubectl -n istio-system get pods -l istio=pilot -o jsonpath='{.items[0].metadata.name}') -c discovery -n istio-system | grep rbac
    {{< /text >}}

1. 检查输出并且验证：

    * 没有错误。
    * 有一个`"built filter config for ..."`的消息，它表示这些服务的过滤器被生成了。

1. 例如你可能会看到和下面相似的内容：

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

    它表示 Pilot 生成了：

    * 由于没有匹配上任何授权策略，为 `sleep.foo.svc.cluster.local` 生成了一个空的配置。并且 Istio 默认会拒绝所有访问这个服务的请求。
    * 为 `productpage.default.svc.cluster.local` 生成了一个配置，并且 Istio 会允许任何人通过 GET 方法访问它。

## 确保 Pilot 成功的将授权策略分发给了代理

Pilot 将授权策略分发给代理。下面的步骤能帮助你确认这一步是正常工作的：

{{< tip >}}
这里的应用都假设你在使用 [Bookinfo 程序](/zh/docs/examples/bookinfo)，如果不是的话，你需要将`-l app=productpage` 替换为你的真实pod。
{{< /tip >}}

1. 运行下面的命令来获取 `productpage` 服务的代理配置文件拷贝:

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/config_dump -s
    {{< /text >}}

1. 检查日志并且确认：

    * 日志中包含 `envoy.filters.http.rbac` 过滤器来在每一个请求来的时候实施授权策略。
    * Istio 根据你更新的授权策略相对应的更新过滤器。

1. 下面的输出表示 `productpage` 的代理启用了 `envoy.filters.http.rbac` 过滤器。里面的规则是所有人都能通过 `GET` 方法访问。`shadow_rules` 并没有被使用，你可以忽略它。

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
          } ],
         "principals": [ {
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

## 确保代理正确执行授权策略

代理是最终执行授权策略的部分。下面的步骤可以帮助你确定代理是正常工作的。

{{< tip >}}
这里的应用都假设你在使用 [Bookinfo 程序](/zh/docs/examples/bookinfo)，如果不是的话，你需要将`-l app=productpage` 替换为你的真实pod。
{{< /tip >}}

1. 通过一下命令打开授权 debug 日志：

    {{< text bash >}}
    $ kubectl exec  $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl localhost:15000/logging?rbac=debug -s
    {{< /text >}}

1. 确认你看到如下日志：

    {{< text plain >}}
    ... ...
    rbac: debug
    ... ...
    {{< /text >}}

1. 在你的浏览器访问 `productpage` 生成一些日志。

1. 通过下面的命令打印代理的日志。

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=productpage -o jsonpath='{.items[0].metadata.name}') -c istio-proxy
    {{< /text >}}

1. 检查输出并且确认：
    * 输出的日志会根据请求是否被允许，要么显示 `enforce allowed` 要么显示 `enforced denied`。
    * 你的授权策略期望从收到的请求中提取数据。

1. 下面的输出表示这有一个 `GET` 请求访问 `/productpage` 路径，并且授权策略允许这个请求。`shadow denied` 没有产生作用，你可以忽略它。

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
