---
title: 通过 SDS 进行身份认证
description: Istio 中如何通过启用 SDS （密钥发现服务）来进行身份认证。
weight: 30
keywords: [security,auth-sds]
aliases:
    - /zh/docs/tasks/security/auth-sds/
---

这个任务是讲述 Istio 中如何通过启动 [SDS（密钥发现服务）](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration)来进行身份认证的。

在 Istio 1.1 之前，Istio workload 的密钥和证书都是由 Citadel 生成的，并且通过挂载 secret-volume 文件的方式下发给 sidecar 上。
这种做法有下面一些小缺陷：

* 证书替换期间的性能下降问题：
  在证书替换的时候，Envoy 通过热重启来获取新的密钥和证书，这会导致性能下降。

* 有潜在的安全风险：
  workload 提供的密钥是通过 Kubernetes 证书来下发的，可以看已知的[风险](https://kubernetes.io/docs/concepts/configuration/secret/#risks)。

这些问题都在 Istio 1.1 中通过提供 SDS 身份认证解决了。
整个过程可以描述如下：

1. workload 边车 Envoy 向 Citadel 代理请求密钥和证书：Citadel 代理是一个 SDS 服务，作为每个节点上的 `DaemonSet` 运行。 Envoy 在请求时会传一个 Kubernetes 服务帐号的 JWT 到代理。

1. Citadel 代理产生密钥对并且发送 CSR 请求给 Citadel 服务：Citadel 服务验证收到的 JWT 并且向 Citadel 颁发证书。

1. Citadel 代理发送回密钥和证书给到 workload 边车。

这样做有如下优势：

* 私钥是永远不会离开节点的：只保存在 Citadel 代理上和 Envoy 边车的内存中。

* 再也不需要挂载密钥卷了：不在依赖 Kubernetes 的密钥。

* Envoy 边车可以通过 SDS 的 API 动态的更新密钥和证书：证书的更换也不再需要重启 Envoy 了。

## 开始之前{## before-you-begin}

参考[Istio 安装指南](/zh/docs/setup/install/helm/) 来设置启动 SDS 和全局双向 TLS 。

## 通过 SDS 使用密钥/证书为服务到服务提供双向 TLS{## service-to-service-mutual-TLS-using key/certificate-provisioned-through-SDS}

参考[认证策略任务](/zh/docs/tasks/security/authentication/authn-policy/)来设置测试服务。

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
{{< /text >}}

验证是否所有的双向 TLS 请求都已经成功：

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

## 验证看是不是没有生成密钥卷文件{## verifying-no-secret-volume-mounted-file-is-generated}

下面来验证是不是没有生成密钥卷文件，先访问部署的 workload 边车容器：

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo  -- /bin/bash
{{< /text >}}

你可以看到 `/etc/certs` 目录下没有挂载密钥文件。

## 使用 pod 上的安全策略来保护 SDS {## securing-SDS-with-pod-security-policies}

Istio 的密钥发现服务（SDS）使用 Citadel 代理通过 Unix domain 套接字来给 Envoy 边车分发证书。 所有在同一个 Kubernetes 节点上的 pod 通过 Unix domain 套接字共享同一个 Citadel 代理。

为了防止对 Unix domain 套接字的意外修改，需要启用[pod 安全策略](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)来限制 pod 对 Unix domain 套接字的权限。否则，有权限修改 deployment 的恶意用户会劫持 Unix domain 套接字来断开 SDS 服务，或者会从运行在同一个 Kubernetes 节点上的其它 pod 那里偷取身份证书。

可以通过执行以下步骤来启用 pod 安全策略：

1. Citadel代理创建成功 Unix domain 套接字才能启动成功。通过实施下面的 pod 安全策略才能只启用 Citadel 代理对 Unix domain 套接字的修改权限。

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

1. 要阻止其它 pod 修改 Unix domain 套接字，就要修改配置项 `allowedHostPaths` ，读写权限配置为`readOnly: true`， 这个选项是 Citadel 代理用于配置 Unix domain 套接字路径的。

    {{< warning >}}
   假设以下的 pod 安全策略是之前其它 pod 没有使用过的。如果你已经实施了其它的 pod 安全策略，则给已经存在的策略新增以下的配置值，而不是直接实施配置。
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

1. 给你的平台启用 pod 安全策略。不同的平台启用的 pod 安全策略是不一样的。请参考你用平台的相关文档。如果在使用 Google Kubernetes Engine (GKE)，你必须[启用 pod 安全策略控制器](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#enabling_podsecuritypolicy_controller)。

    {{< warning >}}
    在启用 pod 安全策略之前要先授权它所需要的权限。一旦策略启用，授权不足 pod 将会无法启动。
    {{< /warning >}}

1. 使用下面的命令重启 Citadel 代理：

    {{< text bash >}}
    $ kubectl delete pod -l 'app=istio-nodeagent' -n istio-system
    pod "istio-nodeagent-dplx2" deleted
    pod "istio-nodeagent-jrbmx" deleted
    pod "istio-nodeagent-rz878" deleted
    {{< /text >}}

1. 为了验证 Citadel 代理能否使用启用了的 pod 安全策略，等待几秒钟并且执行下面的命令来确认 Citadel 代理已经成功启动。

    {{< text bash >}}
    $ kubectl get pod -l 'app=istio-nodeagent' -n istio-system
    NAME                    READY   STATUS    RESTARTS   AGE
    istio-nodeagent-p4p7g   1/1     Running   0          4s
    istio-nodeagent-qdwj6   1/1     Running   0          5s
    istio-nodeagent-zsk2b   1/1     Running   0          14s
    {{< /text >}}

1. 执行下面的命令来启动一个 normal pod。

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

1. 为了验证 normal pod 能不能使用启用了的 pod 安全策略，再等几秒钟并且执行下面的命令来确认 normal pod 已经成功启动。

    {{< text bash >}}
    $ kubectl get pod -l 'app=normal'
    NAME                      READY   STATUS    RESTARTS   AGE
    normal-64c6956774-ptpfh   2/2     Running   0          8s
    {{< /text >}}

1. 启动一个恶意 pod， 这个 pod 会尝试挂载一个有写权限的 Unix domain 套接字。

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

1. 为了验证这个 Unix domain 套接字被保护了，执行下面的命令来确认这个恶意 pod 无法启动，因为有安全策略。

    {{< text bash >}}
    $ kubectl describe rs -l 'app=malicious' | grep Failed
    Pods Status:    0 Running / 0 Waiting / 0 Succeeded / 0 Failed
      ReplicaFailure   True    FailedCreate
      Warning  FailedCreate  4s (x13 over 24s)  replicaset-controller  Error creating: pods "malicious-7dcfb8d648-" is forbidden: unable to validate against any pod security policy: [spec.containers[0].volumeMounts[0].readOnly: Invalid value: false: must be read-only]
    {{< /text >}}

## 清理{## cleanup}

1. 清理测试服务和 Istio 控制面。

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ kubectl delete -f istio-auth-sds.yaml
    {{< /text >}}

1. 根据你的平台文档关闭你集群的 pod 安全策略。如果你在使用 GKE，参考[关闭 pod 安全策略控制器](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#disabling_podsecuritypolicy_controller)。

1. 删除 pod 安全策略和测试 deployments：

    {{< text bash >}}
    $ kubectl delete psp istio-sds-uds istio-nodeagent
    $ kubectl delete role istio-nodeagent -n istio-system
    $ kubectl delete rolebinding istio-nodeagent -n istio-system
    $ kubectl delete clusterrole istio-sds-uds
    $ kubectl delete clusterrolebinding istio-sds-uds
    $ kubectl delete deploy malicious
    $ kubectl delete deploy normal
    {{< /text >}}

## 注意事项{## caveats}

目前，SDS 身份提供流程有以下注意事项：

* SDS 目前只支持[Alpha](/zh/about/feature-stages/#security-and-policy-enforcement)版本。

* 目前还无法流畅的将群集从使用密钥卷装载方式迁移到使用 SDS ， 功能还在开发中。
