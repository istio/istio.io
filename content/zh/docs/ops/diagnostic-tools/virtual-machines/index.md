---
title: 虚拟机调试
description: 介绍关于虚拟机调试的技术和工具。
weight: 80
keywords: [debug,virtual-machines,envoy]
owner: istio/wg-environments-maintainers
test: n/a
---

本页介绍如何对 Istio 部署至虚拟机时出现的问题进行诊断和排除。
在此之前，请确保您已经按照[虚拟机安装](/zh/docs/setup/install/virtual-machine/)指南完成了相应操作。
此外阅读[虚拟机体系架构](/zh/docs/ops/deployment/vm-architecture/)可以帮助您更好的了解组件间是如何交互的。

对 Istio 部署至虚拟机进行故障排除跟对 Kubernetes
内运行的代理问题进行故障排除是类似的，但还是有一些关键点需要注意。

虽然在两个平台上都可以获得许多相同的信息，但对这些信息的访问是不同的。

## 健康检查 {#monitoring-health}

Istio Sidecar 通常作为一个 `systemd` 服务（unit）运行。
您可以检查其状态来确保运行正常：

{{< text bash >}}
$ systemctl status istio
{{< /text  >}}

除此之外您还可以在端点（endpoint）侧以编程的方式检查来 Sidecar
的运行情况：

{{< text bash >}}
$ curl localhost:15021/healthz/ready -I
{{< /text  >}}

## 日志 {#logs}

Istio 代理的日志可以在以下地方找到。

访问 `systemd` 日志获取有关于代理的初始化信息:

{{< text bash >}}
$ journalctl -f -u istio -n 1000
{{< /text  >}}

代理会将 `stderr` 日志和 `stdout` 日志分别重定向到
`/var/log/istio/istio.err.log` 和  `/var/log/istio/istio.log`。
您可以以类似于 `kubectl` 的格式查看这些内容：

{{< text bash >}}
$ tail /var/log/istio/istio.err.log /var/log/istio/istio.log -Fq -n 100
{{< /text  >}}

修改配置文件 `cluster.env` 可以调整日志级别。如果 `istio`
已经在运行，请务必重新启动服务：

{{< text bash >}}
$ echo "ISTIO_AGENT_FLAGS=\"--log_output_level=dns:debug --proxyLogLevel=debug\"" >> /var/lib/istio/envoy/cluster.env
$ systemctl restart istio
{{< /text  >}}

## Iptables {#iptables}

确保 `iptables` 规则已经生效：

{{< text bash >}}
$ sudo iptables-save
...
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
{{< /text  >}}

## Istioctl {#istioctl}

绝大部分 `istioctl` 指令能在虚拟机中正常运行。例如利用
`istioctl proxy-status` 指令查看所有已连接的代理：

{{< text bash >}}
$ istioctl proxy-status
NAME           CDS        LDS        EDS        RDS      ISTIOD                    VERSION
vm-1.default   SYNCED     SYNCED     SYNCED     SYNCED   istiod-789ffff8-f2fkt     {{< istio_full_version >}}
{{< /text  >}}

然而由于 `istioctl proxy-config` 依赖于 Kubernetes
中的连接代理的功能，因此这对条指令无法在虚拟机环境工作。
不过我们可以传递一个包含 Envoy 配置的文件来替代，例如：

{{< text bash >}}
$ curl -s localhost:15000/config_dump | istioctl proxy-config clusters --file -
SERVICE FQDN                            PORT      SUBSET  DIRECTION     TYPE
istiod.istio-system.svc.cluster.local   443       -       outbound      EDS
istiod.istio-system.svc.cluster.local   15010     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15012     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15014     -       outbound      EDS
{{< /text  >}}

## 自动注册 {#automatic-registration}

当虚拟机连接到 Istiod 时，会自动创建一个 `WorkloadEntry`。
这使得虚拟机成为 `Service` 的一部分，类似于 Kubernetes
中的 `Endpoint`。

检查这些配置是否正确创建:

{{< text bash >}}
$ kubectl get workloadentries
NAME             AGE   ADDRESS
vm-10.128.0.50   14m   10.128.0.50
{{< /text  >}}

## 证书{#certificates}

虚拟机处理证书的方式与 Kubernetes Pod 不同，Kubernetes Pod
使用 Kubernetes 提供的 SA 令牌来（service account token）来验证和续订
mTLS 证书。虚拟机则是使用现有的 mTLS 凭据向证书颁发机构进行身份验证并续订证书。

可以使用与 Kubernetes 相同的方式查看这些证书的状态：

{{< text bash >}}
$ curl -s localhost:15000/config_dump | ./istioctl proxy-config secret --file -
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           251932493344649542420616421203546836446     2021-01-29T18:07:21Z     2021-01-28T18:07:21Z
ROOTCA            CA             ACTIVE     true           81663936513052336343895977765039160718      2031-01-26T17:54:44Z     2021-01-28T17:54:44Z
{{< /text  >}}

除此之外, 这些证书需要持久化到磁盘上，以确保停机或重新启动不会丢失。

{{< text bash >}}
$ ls /etc/certs
cert-chain.pem  key.pem  root-cert.pem
{{< /text  >}}
