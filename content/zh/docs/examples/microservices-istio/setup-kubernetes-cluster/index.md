---
title: 设置 Kubernetes 集群
overview: 为教程准备 Kubernetes 集群。
weight: 2
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

在这个模块，您将设置一个安装了 Istio 的 Kubernetes 集群，
还将设置整个教程要用到的一个命名空间。

{{< warning >}}
如果您在培训班且讲师已准备好了集群，
直接前往[设置本地机器](/zh/docs/examples/microservices-istio/setup-local-computer)。
{{</ warning >}}

1. 确保您有 [Kubernetes 集群](https://kubernetes.io/zh-cn/docs/tutorials/kubernetes-basics/)的访问权限。
   您可以使用 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/quickstart) 或
   [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started)。

1. 生成一个环境变量用于存储运行教程指令要用到的命名空间的名字。
   可以用任何名字，比如 `tutorial`。

    {{< text bash >}}
    $ export NAMESPACE=tutorial
    {{< /text >}}

1. 创建命名空间：

    {{< text bash >}}
    $ kubectl create namespace $NAMESPACE
    {{< /text >}}

    {{< tip >}}
    如果您是管理员，您可以为每个用户分配一个独立的命名空间。本教程支持多个用户同时在多个命名空间中进行工作。
    {{< /tip >}}

1. 使用 `demo` 配置文件[安装 Istio](/zh/docs/setup/)。

1. 本示例中使用了 [Kiali](/zh/docs/ops/integrations/kiali/)
   和 [Prometheus](/zh/docs/ops/integrations/prometheus/) 附加组件，
   需要安装它们。使用以下命令安装所有插件：

    {{< text bash >}}
    $ kubectl apply -f @samples/addons@
    {{< /text >}}

    {{< tip >}}
    如果尝试安装插件时出错，请尝试再次运行命令。
    因为再次运行命令时可以解决一些时序引起的问题。
    {{< /tip >}}

1. 使用 `kubectl` 命令为这些通用 Istio 服务创建一个 Kubernetes Ingress 资源。
   在教程目前这个阶段要熟悉这些服务并不是必须的。

    - [Grafana](https://grafana.com/docs/guides/getting_started/)
    - [Jaeger](https://www.jaegertracing.io/docs/1.13/getting-started/)
    - [Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
    - [Kiali](https://kiali.io/docs/installation/quick-start/)

    `kubectl` 命令可以通过修改 yaml 配置为每个服务创建 Ingress 资源：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: istio-system
      namespace: istio-system
      annotations:
        kubernetes.io/ingress.class: istio
    spec:
      rules:
      - host: my-istio-dashboard.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
      - host: my-istio-tracing.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tracing
                port:
                  number: 9411
      - host: my-istio-logs-database.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus
                port:
                  number: 9090
      - host: my-kiali.io
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kiali
                port:
                  number: 20001
    EOF
    {{< /text >}}

1. 创建一个角色为 `istio-system` 命名空间提供读权限。要在下面的步骤中限制用户的权限，这个角色是必须要有的。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-system-access
      namespace: istio-system
    rules:
    - apiGroups: ["", "extensions", "apps"]
      resources: ["*"]
      verbs: ["get", "list"]
    EOF
    {{< /text >}}

1. 为每个用户创建服务账号：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    EOF
    {{< /text >}}

1. 限制每个用户的权限。在教程中，用户只需要在他们自己的命名空间中创建资源以及从 `istio-system` 命名空间中读取资源。即使使用您自己的集群，这也是一个好的实践，它可以避免影响您集群中的其他命名空间。

    创建一个角色为每个用户的命名空间提供读写权限。为每个用户赋予这个角色，以及读取 `istio-system` 资源的角色：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    rules:
    - apiGroups: ["", "extensions", "apps", "networking.k8s.io", "networking.istio.io", "authentication.istio.io",
                  "rbac.istio.io", "config.istio.io", "security.istio.io"]
      resources: ["*"]
      verbs: ["*"]
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-access
      namespace: $NAMESPACE
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: ${NAMESPACE}-access
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: ${NAMESPACE}-istio-system-access
      namespace: istio-system
    subjects:
    - kind: ServiceAccount
      name: ${NAMESPACE}-user
      namespace: $NAMESPACE
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: istio-system-access
    EOF
    {{< /text >}}

1. 每个用户需要使用他们自己的 Kubernetes 配置文件。这个配置文件指明了集群的详细信息、服务账号、证书和用户的命名空间。`kubectl` 命令使用这个配置文件在集群上操作。

    为每个用户创建 Kubernetes 配置文件：

    {{< tip >}}
    该命令假定您的集群名为 `tutorial-cluster`。
    如果集群的名称不同，则将所有引用替换为集群的名称。
    {{</ tip >}}

    {{< text bash >}}
    $ cat <<EOF > ./${NAMESPACE}-user-config.yaml
    apiVersion: v1
    kind: Config
    preferences: {}

    clusters:
    - cluster:
        certificate-authority-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        server: $(kubectl config view -o jsonpath="{.clusters[?(.name==\"$(kubectl config view -o jsonpath="{.contexts[?(.name==\"$(kubectl config current-context)\")].context.cluster}")\")].cluster.server}")
      name: ${NAMESPACE}-cluster

    users:
    - name: ${NAMESPACE}-user
      user:
        as-user-extra: {}
        client-key-data: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
        token: $(kubectl get secret $(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name}) -n $NAMESPACE -o jsonpath={.data.token} | base64 --decode)

    contexts:
    - context:
        cluster: ${NAMESPACE}-cluster
        namespace: ${NAMESPACE}
        user: ${NAMESPACE}-user
      name: ${NAMESPACE}

    current-context: ${NAMESPACE}
    EOF
    {{< /text >}}

1. 为 `${NAMESPACE}-user-config.yaml` 配置文件设置环境变量 `KUBECONFIG`：

    {{< text bash >}}
    $ export KUBECONFIG=$PWD/${NAMESPACE}-user-config.yaml
    {{< /text >}}

1. 打印当前命名空间以确认配置文件已生效：

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    在输出中可以看到命名空间的名字。

1. 如果您为自己设置好了集群，复制前面步骤中提到的 `${NAMESPACE}-user-config.yaml`
   文件到您的本地机器，`${NAMESPACE}` 就是前面步骤中的命名空间。
   比如，`tutorial-user-config.yaml`。教程中您将会再次用到这个文件。

    如果您是讲师，则将生成的配置文件发送给每个学员。学员必须将该配置文件复制到自己本地的计算机。

恭喜，您为您的教程设置好了集群！

您已经准备好[设置本地机器](/zh/docs/examples/microservices-istio/setup-local-computer)了。
