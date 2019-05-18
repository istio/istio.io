---
title: 通过 SDS 提供身份服务
description: 展示启用 SDS 来为 Istio 提供身份服务的过程。
weight: 70
keywords: [security,auth-sds]
---

该任务展示了启用 [SDS (secret discovery service)](https://www.envoyproxy.io/docs/envoy/latest/configuration/secret#config-secret-discovery-service) 来为 Istio 提供身份服务的过程。

Istio 1.1 之前，Istio 为工作负载提供的密钥和证书是由 Citadel 生成并使用加载 Secret 卷的方式分发给 Sidecar 的，这种方式有几大缺陷：

* 证书轮换造成的性能损失：
    证书发生轮换时，Envoy 会进行热重启以加载新的证书和密钥，会造成性能下降。

* 潜在的安全漏洞：
    工作负载的私钥使用 Kubernetes Secret 的方式进行分发，存在一定[风险](https://kubernetes.io/docs/concepts/configuration/secret/#risks)。

在 Istio 1.1 之中，上述问题可以使用 SDS 来解决。下面描述了它的工作流程：

1. 工作负载的 Sidecar 从 Citadel 代理中请求密钥和证书：Citadel 代理是一个 SDS 服务器，这一代理以 `DaemonSet` 的形式在每个节点上运行，在这一请求中，Envoy 把 Kubernetes service account 的 JWT 传递给 Citadel 代理。

1. Citadel 代理生成密钥对，并向 Citadel 发送 CSR 请求：
    Citadel 校验 JWT，并给 Citadel 代理签发证书。

1. Citadel 代理把密钥和证书返回给工作负载的 Sidecar。

这种方法有如下好处：

* 私钥不会离开节点：私钥仅存在于 Citadel 代理和 Envoy Sidecar 的内存中。

* 不再需要加载 Secret 卷：去掉对 Kubernetes Secret 的依赖。

* Sidecar 能够利用 SDS API 动态的刷新密钥和证书：证书轮换过程不再需要重启 Envoy。

## 开始之前 {#before-you-begin}

* 使用 [Helm](/zh/docs/setup/kubernetes/install/helm/) 安装 Istio，并启用 SDS 和全局的双向 TLS：

    {{< text bash >}}
    $ cat install/kubernetes/namespace.yaml > istio-auth-sds.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-* >> istio-auth-sds.yaml
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system --values @install/kubernetes/helm/istio/values-istio-sds-auth.yaml@ >> istio-auth-sds.yaml
    $ kubectl create -f istio-auth-sds.yaml
    {{< /text >}}

## 通过 SDS 提供的密钥和证书支持服务间的双向 TLS {#sds-mutual}

参考[认证策略任务](/zh/docs/tasks/security/authn-policy/)中的内容，部署测试服务。

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
{{< /text >}}

验证双向 TLS 请求是否成功：

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

## 验证：没有通过加载 Secret 卷的方式生成的文件 {#no-secret-volume}

要验证是否有通过加载 Secret 卷的方式生成的文件，可以访问工作负载的 Sidecar 容器：

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo  -- /bin/bash
{{< /text >}}

这里会看到，在 `/etc/certs` 文件夹中没有加载 Secret 卷生成的文件。

## 使用 pod 安全策略提高安全性

Istio Secret 发现服务（SDS）使用 Citadel 代理通过 Unix domain socket 将证书分发给 Envoy sidecar。
在同一个 Kubernetes 节点中运行的所有 pod 共享 Citadel 代理和 Unix domain socket。

要防止对 Unix domain socket 进行恶意修改，请启用 pod 安全策略以限制 pod 对 Unix domain socket 的权限。
否则，恶意 pod 可能会劫持 Unix domain socket 以破坏 SDS 服务或从同一 Kubernetes 节点上运行的其他 pod 窃取身份凭证。

要启用 pod 安全策略，请执行以下步骤：

1. Citadel 代理无法启动，除非它可以创建所需的 Unix domain socket。应用以下 pod 安全策略仅允许 Citadel 代理修改 Unix domain socket：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: extensions/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: istio-nodeagent
    spec:
      allowedHostPaths:
      - pathPrefix: "/var/run/sds"
      seLinux:
        rule: RunAsAny
      supplementalGroups:
        rule: RunAsAny
      runAsUser:
        rule: RunAsAny
      fsGroup:
        rule: RunAsAny
      volumes:
      - '*'
    ---
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-nodeagent
      namespace: istio-system
    rules:
    - apiGroups:
      - extensions
      resources:
      - podsecuritypolicies
      resourceNames:
      - istio-nodeagent
      verbs:
      - use
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: istio-nodeagent
      namespace: istio-system
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: istio-nodeagent
    subjects:
    - kind: ServiceAccount
      name: istio-nodeagent-service-account
      namespace: istio-system
    EOF
    {{< /text >}}

1. 要阻止其他 pod 修改 UNIX Domain Socket，请将 Citadel 代理用于 UNIX Domain Socket 的路径的 `allowedHostPaths` 配置更改为 `readOnly: true`。

    {{< warning >}}
    以下 pod 安全策略假定之前未应用其他 pod 安全策略。如果您已应用其他 pod 安全策略，请将以下配置值添加到现有策略，而不是直接应用配置。
    {{< /warning >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: extensions/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: istio-sds-uds
    spec:
     # 保护 UNIX Domain Socket 免受未经授权的修改
     allowedHostPaths:
     - pathPrefix: "/var/run/sds"
       readOnly: true
     # 允许 istio sidecar 注入工作
     allowedCapabilities:
     - NET_ADMIN
     seLinux:
       rule: RunAsAny
     supplementalGroups:
       rule: RunAsAny
     runAsUser:
       rule: RunAsAny
     fsGroup:
       rule: RunAsAny
     volumes:
     - '*'
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-sds-uds
    rules:
    - apiGroups:
      - extensions
      resources:
      - podsecuritypolicies
      resourceNames:
      - istio-sds-uds
      verbs:
      - use
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: istio-sds-uds
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: istio-sds-uds
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:serviceaccounts
    EOF
    {{< /text >}}

1. 为您的平台启用 pod 安全策略。每个支持的平台都会以不同方式启用 pod 安全策略，请参阅适用于您的平台的相关文档。
   如果您使用的是 Google Kubernetes Engine（GKE），则必须[启用 pod 安全策略控制器](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#enabling_podsecuritypolicy_controller)。

    {{< warning >}}
    在启用它之前，在 pod 安全策略中授予所有必需的权限。启用该策略后，如果 pods 需要任何未授予的权限，则无法启动。
    {{< /warning >}}

1. 运行以下命令以重新启动 Citadel 代理：

    {{< text bash >}}
    $ kubectl delete pod -l 'app=nodeagent' -n istio-system
    pod "istio-nodeagent-dplx2" deleted
    pod "istio-nodeagent-jrbmx" deleted
    pod "istio-nodeagent-rz878" deleted
    {{< /text >}}

1. 要验证 Citadel 代理是否使用启用的 pod 安全策略，请等待几秒钟并运行以下命令以确认代理已成功启动：

    {{< text bash >}}
    $ kubectl get pod -l 'app=nodeagent' -n istio-system
    NAME                    READY   STATUS    RESTARTS   AGE
    istio-nodeagent-p4p7g   1/1     Running   0          4s
    istio-nodeagent-qdwj6   1/1     Running   0          5s
    istio-nodeagent-zsk2b   1/1     Running   0          14s
    {{< /text >}}

1. 运行以下命令以启动普通 pod。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: normal
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: normal
        spec:
          containers:
          - name: normal
            image: pstauffer/curl
            command: ["/bin/sleep", "3650d"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

1. 要验证正常 pod 是否与启用了 pod 安全策略一起使用，请等待几秒钟并运行以下命令以确认正常 pod 已成功启动。

    {{< text bash >}}
    $ kubectl get pod -l 'app=normal'
    NAME                      READY   STATUS    RESTARTS   AGE
    normal-64c6956774-ptpfh   2/2     Running   0          8s
    {{< /text >}}

1. 启动一个恶意 pod，尝试使用写入权限挂载 UNIX Domain Socket。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: malicious
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: malicious
        spec:
          containers:
          - name: malicious
            image: pstauffer/curl
            command: ["/bin/sleep", "3650d"]
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: sds-uds
              mountPath: /var/run/sds
          volumes:
          - name: sds-uds
            hostPath:
              path: /var/run/sds
              type: ""
    EOF
    {{< /text >}}

1. 要验证 UNIX Domain Socket 是否受保护，请运行以下命令以确认由于 pod 安全策略而无法启动恶意 pod：

    {{< text bash >}}
    $ kubectl describe rs -l 'app=malicious' | grep Failed
    Pods Status:    0 Running / 0 Waiting / 0 Succeeded / 0 Failed
      ReplicaFailure   True    FailedCreate
      Warning  FailedCreate  4s (x13 over 24s)  replicaset-controller  Error creating: pods "malicious-7dcfb8d648-" is forbidden: unable to validate against any pod security policy: [spec.containers[0].volumeMounts[0].readOnly: Invalid value: false: must be read-only]
    {{< /text >}}

## 清理 {#cleanup}

1. 清理测试服务以及 Istio 控制面：

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ kubectl delete -f istio-auth-sds.yaml
    {{< /text >}}

1. Disable the pod security policy in the cluster using the documentation of your platform. If you are using GKE,
   [disable the pod security policy controller](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#disabling_podsecuritypolicy_controller).

1. Delete the pod security policy and the test deployments:

    {{< text bash >}}
    $ kubectl delete psp istio-sds-uds istio-nodeagent
    $ kubectl delete role istio-nodeagent -n istio-system
    $ kubectl delete rolebinding istio-nodeagent -n istio-system
    $ kubectl delete clusterrole istio-sds-uds
    $ kubectl delete clusterrolebinding istio-sds-uds
    $ kubectl delete deploy malicious
    $ kubectl delete deploy normal
    {{< /text >}}

## 注意事项 {#caveats}

目前 SDS 的身份服务有几点需要注意的地方：

* 要启用控制面加密，还需要加载 Secret 卷。控制面的 SDS 支持还在开发之中。

* 从 Secret 卷到 SDS 的平滑迁移过程，也还在开发之中。
