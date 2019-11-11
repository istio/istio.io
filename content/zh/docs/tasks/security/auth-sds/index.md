---
title: 通过 SDS 提供身份服务
description: 演示 Istio 如何通过 SDS (Secret Discovery Service) 来提供身份服务。
weight: 70
keywords: [security,auth-sds]
---

该任务演示 Istio 如何通过 [SDS (secret discovery service)](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration) 来提供身份服务。

Istio 1.1 之前，Istio 为工作负载提供的密钥和证书是由 Citadel 生成并使用加载 Secret 卷的方式分发给 Sidecar 的，这种方式有几大缺陷：

* 证书轮换造成的性能损失：
    证书发生轮换时，Envoy 会进行热重启以加载新的证书和密钥，会造成性能下降。

* 潜在的安全漏洞：
    工作负载的私钥使用 Kubernetes Secret 的方式进行分发，存在一定[风险](https://kubernetes.io/docs/concepts/configuration/secret/#risks)。

在 Istio 1.1 之中，上述问题可以使用 SDS 来解决。以下描述了它的工作流程：

1. 工作负载 Envoy sidecar 从 Citadel 代理中请求密钥和证书：Citadel 代理是一个 SDS 服务器，这一代理以 `DaemonSet` 的形式在每个节点上运行，在这一请求中，Envoy 把 Kubernetes service account 的 JWT 传递给 Citadel 代理。

1. Citadel 代理生成密钥对，并向 Citadel 发送 CSR 请求：
    Citadel 校验 JWT，并给 Citadel 代理签发证书。

1. Citadel 代理把密钥和证书返回给工作负载的 Sidecar。

这种方法有如下好处：

* 私钥不会离开节点：私钥仅存在于 Citadel 代理和 Envoy Sidecar 的内存中。

* 不再需要加载 Secret 卷：去掉对 Kubernetes Secret 的依赖。

* Sidecar 能够利用 SDS API 动态的刷新密钥和证书：证书轮换过程不再需要重启 Envoy。

## 开始之前 {#before-you-begin}

* 按照 [安装说明](/zh/docs/setup/install/istioctl/) 安装 Istio，并启用 SDS 和全局的双向 TLS：

## 通过 SDS 提供的密钥和证书支持服务间的双向 TLS{#service-to-service-mutual-TLS-using-key-certificate-provisioned-through-SDS}

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

## 验证没有通过加载 Secret 卷的方式生成的文件{#verifying-no-secret-volume-mounted-file-is-generated}

验证是否存在通过加载 Secret 卷的方式生成的文件，可以访问工作负载的 Sidecar 容器：

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo  -- /bin/bash
{{< /text >}}

这里会看到，在 `/etc/certs` 文件夹中没有加载 Secret 卷生成的文件。

## 通过 pod 安全策略加固 SDS {#securing-sds-with-pod-security-policies}

Istio 的密钥分发服务（SDS，Secret Discovery Service）通过 Citadel 代理将证书分发到 Envoy sidecar，传输过程基于 Unix domain socket 。所有位于同一 Kubernetes node 节点的 pod 共用一个 Citadel 代理和 Unix domain socket。

为了避免对 Unix domain socket 的意外修改，可以开启 [pod 安全策略](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) 限制 pod 对 Unix domain socket 的权限。否则，一个有权限修改 deployment 的恶意用户可以通过劫持 Unix domain socket 来破坏 SDS 服务，或者窃取运行在相同 Kubernetes 节点上的其他 pod 的证书。

可以按照以下步骤开启 pod 安全策略：

1. Citadel 代理如果没有权限创建 Unix domain socket，它会启动失败。因此，应用以下 pod 安全策略只允许 Citadel 代理修改 Unix domain socket：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: policy/v1beta1
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

1. 为了禁止其他 pod 修改 Unix domain socket 文件，修改它们的 pod 安全策略配置项 `allowedHostPaths`（为只读 `readOnly: true`），目录为 Citadel 代理配置 Unix domain socket 路径。

    {{< warning >}}
    以下 pod 安全策略假设之前没有应用过其他 pod 安全策略。如果存在其他策略，不需要直接创建下面的配置，只需将它的内容添加到现有的策略中。
    {{< /warning >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: policy/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: istio-sds-uds
    spec:
     # Protect the unix domain socket from unauthorized modification
     allowedHostPaths:
     - pathPrefix: "/var/run/sds"
       readOnly: true
     # Allow the istio sidecar injector to work
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

1. 在你的平台上开启 pod 安全策略。每一个平台中开启它的步骤不同，请阅读平台相关的文档。如果您使用的是 Google Kubernetes Engine (GKE)，可以按照[开启 pod 安全策略控制器](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#enabling_podsecuritypolicy_controller)来操作。

    {{< warning >}}
    在您开启它之前，需要授予所有必须的权限。一旦策略开启，如果 pod 需要的某个权限没有授予，则 pod 将不能启动。
    {{< /warning >}}

1. 执行以下命令重启 Citadel 代理：

    {{< text bash >}}
    $ kubectl delete pod -l 'app=nodeagent' -n istio-system
    pod "istio-nodeagent-dplx2" deleted
    pod "istio-nodeagent-jrbmx" deleted
    pod "istio-nodeagent-rz878" deleted
    {{< /text >}}

1. 验证 Citadel 代理启用了 pod 安全策略。等待几秒钟，然后执行以下命令确认代理成功启动：

    {{< text bash >}}
    $ kubectl get pod -l 'app=nodeagent' -n istio-system
    NAME                    READY   STATUS    RESTARTS   AGE
    istio-nodeagent-p4p7g   1/1     Running   0          4s
    istio-nodeagent-qdwj6   1/1     Running   0          5s
    istio-nodeagent-zsk2b   1/1     Running   0          14s
    {{< /text >}}

1. 执行以下命令启动普通 pod：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: normal
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: normal
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

1. 验证普通 pod 已启用 pod 安全策略。等待几秒钟，执行以下命令以确认它成功启动：

    {{< text bash >}}
    $ kubectl get pod -l 'app=normal'
    NAME                      READY   STATUS    RESTARTS   AGE
    normal-64c6956774-ptpfh   2/2     Running   0          8s
    {{< /text >}}

1. 开启一个恶意的 pod，在该 pod 中尝试以写权限挂载 Unix domain socket：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: malicious
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: malicious
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

1. 验证 Unix domain socket 确实受到保护。执行以下命令，确认恶意的 pod 由于启用了 pod 安全策略而启动失败：

    {{< text bash >}}
    $ kubectl describe rs -l 'app=malicious' | grep Failed
    Pods Status:    0 Running / 0 Waiting / 0 Succeeded / 0 Failed
      ReplicaFailure   True    FailedCreate
      Warning  FailedCreate  4s (x13 over 24s)  replicaset-controller  Error creating: pods "malicious-7dcfb8d648-" is forbidden: unable to validate against any pod security policy: [spec.containers[0].volumeMounts[0].readOnly: Invalid value: false: must be read-only]
    {{< /text >}}

## 清理{#cleanup}

1. 清理测试服务以及 Istio 控制面：

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ kubectl delete -f istio-auth-sds.yaml
    {{< /text >}}

1. 按照你集群所在平台相关文档，关闭 pod 安全策略功能。如果你使用的 GKE，请按照[关闭 pod 安全策略控制器文档](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#disabling_podsecuritypolicy_controller)操作.

1. 删除所有用于测试的 pod 安全策略以及 deployment：

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

* SDS 的支持目前处于 [Alpha](/about/feature-stages/#security-and-policy-enforcement) 阶段。

* 从 Secret 挂载卷到 SDS 的平滑迁移过程，也还在开发之中。
