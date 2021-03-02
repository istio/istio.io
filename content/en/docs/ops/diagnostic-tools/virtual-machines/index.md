---
title: Debugging Virtual Machines
description: Describes tools and techniques to diagnose issues with Virtual Machines.
weight: 80
keywords: [debug,virtual-machines,envoy]
owner: istio/wg-environments-maintainers
test: n/a
---

This page describes how to troubleshoot issues with Istio deployed to Virtual Machines.
Before reading this, you should take the steps in [Virtual Machine Installation](/docs/setup/install/virtual-machine/).
Additionally, [Virtual Machine Architecture](/docs/ops/deployment/vm-architecture/) can help you understand how the components interact.

Troubleshooting an Istio Virtual Machine installation is similar to troubleshooting issues with proxies running inside Kubernetes, but there are some key differences to be aware of.

While much of the same information is available on both platforms, accessing this information differs.

## Monitoring health

The Istio sidecar is typically run as a `systemd` unit. To ensure its running properly, you can check that status:

{{< text bash >}}
$ systemctl status istio
{{< /text  >}}

Additionally, the sidecar health can be programmatically check at its health endpoint:

{{< text bash >}}
$ curl localhost:15021/healthz/ready -I
{{< /text  >}}

## Logs

Logs for the Istio proxy can be found in a few places.

To access the `systemd` logs, which has details about the initialization of the proxy:

{{< text bash >}}
$ journalctl -f -u istio -n 1000
{{< /text  >}}

The proxy will redirect `stderr` and `stdout` to `/var/log/istio/istio.err.log` and  `/var/log/istio/istio.log`, respectively.
To view these in a format similar to `kubectl`:

{{< text bash >}}
$ tail /var/log/istio/istio.err.log /var/log/istio/istio.log -Fq -n 100
{{< /text  >}}

Log levels can be modified by changing the `cluster.env` configuration file. Make sure to restart `istio` if it is already running:

{{< text bash >}}
$ echo "ISTIO_AGENT_FLAGS=\"--log_output_level=dns:debug --proxyLogLevel=debug\"" >> /var/lib/istio/envoy/cluster.env
$ systemctl restart istio
{{< /text  >}}

## Iptables

To ensure `iptables` rules have been successfully applied:

{{< text bash >}}
$ sudo iptables-save
...
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
{{< /text  >}}

## Istioctl

Most `istioctl` commands will function properly with virtual machines. For example, `istioctl proxy-status` can be used to view all connected proxies:

{{< text bash >}}
$ istioctl proxy-status
NAME           CDS        LDS        EDS        RDS      ISTIOD                    VERSION
vm-1.default   SYNCED     SYNCED     SYNCED     SYNCED   istiod-789ffff8-f2fkt     {{< istio_full_version >}}
{{< /text  >}}

However, `istioctl proxy-config` relies on functionality in Kubernetes to connect to a proxy, which will not work for virtual machines.
Instead, a file containing the configuration dump from Envoy can be passed. For example:

{{< text bash >}}
$ curl -s localhost:15000/config_dump | istioctl proxy-config clusters --file -
SERVICE FQDN                            PORT      SUBSET  DIRECTION     TYPE
istiod.istio-system.svc.cluster.local   443       -       outbound      EDS
istiod.istio-system.svc.cluster.local   15010     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15012     -       outbound      EDS
istiod.istio-system.svc.cluster.local   15014     -       outbound      EDS
{{< /text  >}}

## Automatic registration

When a virtual machine connects to Istiod, a `WorkloadEntry` will automatically be created. This enables
the virtual machine to become a part of a `Service`, similar to an `Endpoint` in Kubernetes.

To check these are created correctly:

{{< text bash >}}
$ kubectl get workloadentries
NAME             AGE   ADDRESS
vm-10.128.0.50   14m   10.128.0.50
{{< /text  >}}

## Certificates

Virtual machines handle certificates differently than Kubernetes Pods, which use a Kubernetes-provided service account token
to authenticate and renew mTLS certificates. Instead, existing mTLS credentials are used to authenticate with the certificate authority and
renew certificates.

The status of these certificates can be viewed in the same way as in Kubernetes:

{{< text bash >}}
$ curl -s localhost:15000/config_dump | ./istioctl proxy-config secret --file -
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     true           251932493344649542420616421203546836446     2021-01-29T18:07:21Z     2021-01-28T18:07:21Z
ROOTCA            CA             ACTIVE     true           81663936513052336343895977765039160718      2031-01-26T17:54:44Z     2021-01-28T17:54:44Z
{{< /text  >}}

Additionally, these are persisted to disk to ensure downtime or restarts do not lose state.

{{< text bash >}}
$ ls /etc/certs
cert-chain.pem  key.pem  root-cert.pem
{{< /text  >}}
