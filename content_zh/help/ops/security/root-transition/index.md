---
title: 延长自签发证书的有效期
description: 学习如何延长 Istio 自签发根证书的有效期。
weight: 90
keywords: [security, PKI, certificate, Citadel]
---

因为历史原因，Istio 的自签发证书只有一年的有效期。如果你是用的是 Istio 的自签发证书，就需要在它们过期之前订好计划进行根证书的更迭。根证书过期可能会导致集群范围内的意外中断。

{{< tip >}}
我们认为每年更换根证书和密钥是一个安全方面的最佳实践，我们会在后续内容中介绍如何完成根证书和密钥的轮转过程。
{{< /tip >}}

为了了解根证书的剩余有效期，请参考下面[过程中的第一步](#root-transition-procedure)。

我们提供了下面的过程，用于完成根证书更新工作。Envoy 进程不需要进行重启来载入新的根证书，也就不会影响长链接了。要了解 Envoy 的热启动过程及其影响范围，请参考相关的[文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/hot_restart#arch-overview-hot-restart)和[博客](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)。

## 场景 {#scenarios}

如果目前没有使用双向 TLS 功能，未来也不准备使用，那么无需进行任何操作。可以选择升级到 1.0.8、1.1.8 或者更晚的版本，避免未来产生这一问题。

如果目前没有使用双向 TLS，但是未来准备采用，建议跟随下列步骤进行更新。

如果目前正在使用自签署证书支持的双向 TLS，请跟随下面的步骤进行操作，并检查当前部署是否受到影响。

## 根证书迁移过程 {#root-transition-procedure}

1. 检查根证书是否过期：

    下载[脚本](https://raw.githubusercontent.com/istio/tools/master/bin/root-transition.sh)到一个包含有 `kubectl` 并能以此访问集群的机器上。

    {{< text bash>}}
    $ wget https://raw.githubusercontent.com/istio/tools/master/bin/root-transition.sh
    $ chmod +x root-transition.sh
    $ ./root-transition.sh check
    ...
    ===YOU HAVE 30 DAYS BEFORE THE ROOT CERT EXPIRES!=====
    {{< /text >}}

    在根证书到期之前执行剩余步骤，以防系统停机。

1. 执行根证书更新过程：

    在更新过程中，Envoy 可能会热启动，来载入新的证书。
    During the transition, the Envoy sidecars may be hot-restarted to reload the new certificates.
    This may have some impact on your traffic. Please refer to
    [Envoy hot restart](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/hot_restart#arch-overview-hot-restart)
    and read [this](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)
    blog post for more details.

    {{< warning >}}
    If your Pilot does not have an Envoy sidecar, consider installing Envoy sidecar for your Pilot.
    Because the Pilot has issue using the old root certificate to verify the new workload certificates.
    This may cause disconnection between Pilot and Envoy.
    Please see the [here](#how-to-check-if-pilot-has-an-envoy-sidecar) for how to check.
    The [Istio upgrade guide](/docs/setup/kubernetes/upgrade/steps/)
    by default installs Pilot with Envoy sidecar.
    {{< /warning >}}

    {{< text bash>}}
    $ ./root-transition.sh transition
    Create new ca cert, with trust domain as cluster.local
    Wed Jun  5 19:11:15 PDT 2019 delete old ca secret
    secret "istio-ca-secret" deleted
    Wed Jun  5 19:11:15 PDT 2019 create new ca secret
    secret/istio-ca-secret created
    pod "istio-citadel-8574b88bcd-j7v2d" deleted
    Wed Jun  5 19:11:18 PDT 2019 restarted Citadel, checking status
    NAME                             READY     STATUS    RESTARTS   AGE
    istio-citadel-8574b88bcd-l2g74   1/1       Running   0          3s
    New root certificate:
    Certificate:
        Data:
            ...
            Validity
                Not Before: Jun  6 03:24:43 2019 GMT
                Not After : Jun  3 03:24:43 2029 GMT
            Subject: O = cluster.local
            ...
    Your old certificate is stored as old-ca-cert.pem, and your private key is stored as ca-key.pem
    Please save them safely and privately.
    {{< /text >}}

1. Verify the new workload certificates are generated:

    {{< text bash>}}
    $ ./root-transition.sh verify
    ...
    Checking the current root CA certificate is propagated to all the Istio-managed workload secrets in the cluster.
    Root cert MD5 is 8fa8229ab89122edba73706e49a55e4c
    Checking namespace: default
      Secret default.istio.default is updated.
      Secret default.istio.sleep is updated.
    Checking namespace: istio-system
      Secret istio-system.istio.default is updated.
      ...
    ------All Istio keys and certificates are updated in secret!
    {{< /text >}}

    If this command fails, wait a minute and run the command again.
    It takes some time for Citadel to propagate the certificates.

1. Upgrade to Istio 1.0.8, 1.1.8 or later:

    {{< warning >}}
    To ensure the control plane components and Envoy sidecars all load the new certificates and keys, this step is mandatory.
    {{< /warning >}}

    Upgrade your control plane and `istio-proxy` sidecars to 1.0.8, 1.1.8 or later.
    Please follow the Istio [upgrade procedure](/docs/setup/kubernetes/upgrade/steps/).

1. Verify the new workload certificates are loaded by Envoy:

    You can verify whether an Envoy has received the new certificates.
    The following command shows an example to check the Envoy’s certificate for pod _foo_ running in namespace _bar_.

    {{< text bash>}}
    $ kubectl exec -it foo -c istio-proxy -n bar -- curl http://localhost:15000/certs | head -c 1000
    {
     "certificates": [
      {
       "ca_cert": [
          ...
          "valid_from": "2019-06-06T03:24:43Z",
          "expiration_time": ...
       ],
       "cert_chain": [
        {
          ...
        }
    {{< /text >}}

    Please inspect the `valid\_from` value of the `ca\_cert`.
    If it matches the `_Not_ _Before_` value in the new certificate as shown in Step 2,
    your Envoy has loaded the new root certificate.

## Troubleshooting

### Can I upgrade to 1.0.8, 1.1.8 or later first, and then do the root transition?

Yes, you can. You can upgrade to 1.0.8, 1.1.8 or later as normal.
After that, follow the root transition steps and in Step 4,
manually restart Galley, Pilot and sidecar-injector to ensure they load the new root certificates.

### Why my workloads do not pick up the new certificates (in Step 5)?

Please make sure you have updated to 1.0.8, 1.1.8 or later for the `istio-proxy` sidecars in Step 4.

{{< warning >}}
If you are using Istio releases 1.1.3 - 1.1.7, the Envoy may not be hot-restarted
after the new certificates are generated.
{{< /warning >}}

### Why my Pilot does not work and logs "handshake error"?

This may because the Pilot is
[not using an Envoy sidecar](#how-to-check-if-pilot-has-an-envoy-sidecar),
while the `controlPlaneSecurity` is enabled.
In this case, restart both Galley and Pilot to ensure they load the new certificates.
As an example, the following commands redeploy a pod for Galley / Pilot by removing a pod.

{{< text bash>}}
$ kubectl delete po <galley-pod> -n istio-system
$ kubectl delete po <pilot-pod> -n istio-system
{{< /text >}}

### How to check if Pilot has an Envoy sidecar

If the following command shows `1/1`, that means your Pilot does not have an Envoy sidecar,
otherwise, if it is showing `2/2`, your Pilot is using an Envoy sidecar.

{{< text bash>}}
$ kubectl get po -l istio=pilot -n istio-system
istio-pilot-569bc6d9c-tfwjr   1/1     Running   0          11m
{{< /text >}}

### I can't deploy new workloads with the sidecar-injector

This may happen if you did not upgrade to 1.0.8, 1.1.8 or later.
Try to restart the sidecar injector.
The sidecar injector will reload the certificate after the restart:

{{< text bash>}}
$ kubectl delete po -l istio=sidecar-injector -n istio-system
pod "istio-sidecar-injector-788bd8fc48-x9gdc" deleted
{{< /text >}}
