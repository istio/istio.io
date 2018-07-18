> 这个任务使用了新的API： [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). 老版本的API已经被弃用了，并会在Istio的下一个发布版本中被移除掉。如果你需要使用旧版本的API，请参考这篇文档：[here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

# 流量镜像

这一任务演示istio的流量跟踪和流量镜像功能。流量镜像是一个有力的工具，在业务团队对生产系统进行变更的过程中，这一能力能够有效的降低风险。流量镜像功能通过使用镜像服务对流量进行实时复制，并且这个过程发生在主服务的关键请求路径带中。

> Mirroring brings a copy of live traffic to a mirrored service and happens out of band of the critical request path for the primary service.
> 上句翻译存疑，目前也找不到合适的测试方法进行验证。

## 开始之前

- 遵循[安装指南](../../setup)设置Istio。
- 启动两个版本的`httpbin`服务，并确保对其日志的访问能力。

httpbin-v1：

~~~bash
cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: httpbin-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
        ports:
        - containerPort: 8080
EOF
~~~

httpbin-v2：

~~~bash
cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: httpbin-v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: httpbin
        version: v2
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        command: ["gunicorn", "--access-logfile", "-", "-b", "0.0.0.0:8080", "httpbin:app"]
        ports:
        - containerPort: 8080
EOF
~~~

httpbin的Kubernetes Service：

~~~bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: http
    port: 8080
  selector:
    app: httpbin
EOF
~~~

- 启动`sleep`服务，然后我们就可以使用`curl`来提供装载量。

`sleep`服务

~~~bash
cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: sleep
    spec:
      containers:
      - name: sleep
        image: tutum/curl
        command: ["/bin/sleep","infinity"]
        imagePullPolicy: IfNotPresent
EOF
~~~

## 镜像

接下来让我们建立一个场景来演示istio的流量镜像能力。我们现在有两个版本的`httpbin`服务。缺省情况下，Kubernetes会在这两个版本的服务之间进行负载均衡。我们使用Istio的路由能力，强制所有流量到`httpbin`服务的`v1`版本中去。

### 创建缺省路由策略

创建缺省的路由规则，把所有流量导向`v1`版本的`httpbin`服务。

~~~bash
cat <<EOF | istioctl create -f -
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: httpbin-default-v1
spec:
  destination:
    name: httpbin
  precedence: 5
  route:
  - labels:
      version: v1
EOF
~~~

> 提示:如果你安装或调试的Istio中打开了 mTLS Authentication ，你必须添加[TLSSettings.TLSmode]( /docs/reference/config/istio.networking.v1alpha3/#TLSSettings-TLSmode) 作为[TLSSettings](/docs/reference/config/istio.networking.v1alpha3/#TLSSettings) reference中的一个noted。

现在所有流量都进入`httpbin v1`服务，我们尝试发送一些请求：

~~~bash
export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'

{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    "Host": "httpbin:8080",
    "User-Agent": "curl/7.35.0",
    "X-B3-Sampled": "1",
    "X-B3-Spanid": "eca3d7ed8f2e6a0a",
    "X-B3-Traceid": "eca3d7ed8f2e6a0a",
    "X-Ot-Span-Context": "eca3d7ed8f2e6a0a;eca3d7ed8f2e6a0a;0000000000000000"
  }
}
~~~

如果我们检查一下`v1`和`v2`两个版本的`httpbin`服务的所属Pod的日志，会发现只有`v1`版本的Pod中出现了访问记录：

~~~
$  kubectl logs -f httpbin-v1-2113278084-98whj -c httpbin
127.0.0.1 - - [07/Feb/2018:00:07:39 +0000] "GET /headers HTTP/1.1" 200 349 "-" "curl/7.35.0"
~~~

### 改变路由规则，创建到`v2`的镜像

~~~bash
cat <<EOF | istioctl create -f -
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: mirror-traffic-to-httbin-v2
spec:
  destination:
    name: httpbin
  precedence: 11
  route:
  - labels:
      version: v1
    weight: 100
  - labels:
      version: v2
    weight: 0
  mirror:
    name: httpbin
    labels:
      version: v2
EOF
~~~

这一规则指定`100%`的流量进入`v1`，进入`v2`的流量是`0%`。目前这样的古怪设置是必须的，我们需要这样的一条来通知后端，根据这一内容对Envoy集群进行配置，我们会在这方面进行改进，以便今后不再需要制定`0%`权重的路由。

最后一段要求对流量进行复制，发送给`httpbin v2`服务。当流量被流量镜像功能复制的同时，这些请求会在`Host/Authority`头部加入`-shadow`字样，发送给镜像服务。例如`cluster-1`变成了`cluster-1-shadow`。另外，镜像请求是发完即忘的，对于镜像流量的请求响应是会被丢弃的。

如果我们再一次发送请求：

`kubectl exec -it $SLEEP_POD -c sleep -- sh -c 'curl  http://httpbin:8080/headers'`

我们会在`v1`和`v2`两个版本的Pod中都看到访问记录。`v2`中看到的访问日志实际上是访问`v1`的流量的镜像引发的。

## 清理

1. 删除规则

  ~~~
  istioctl delete routerule mirror-traffic-to-httbin-v2
  istioctl delete routerule httpbin-default-v1
  ~~~

2. 关闭httpbin服务和客户端。

  ~~~
  kubectl delete deploy httpbin-v1 httpbin-v2 sleep
  kubectl delete svc httpbin
  ~~~

## 下一步

阅读[镜像配置参考](../../reference/config/istio.routing.v1alpha1.html)，可以获得更多流量复制配置方面的信息。
