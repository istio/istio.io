---
title: "Inject workload with Kata Containers in Istio"
description: "Besides generic container runtime, inject workload with Kata Containers in Istio."
publishdate: 2023-03-02
attribution: "Steve(Huailong) Zhang (Intel)"
keywords: [Istio, Kata, security]
---

Based on [Kata Containers](https://github.com/kata-containers) definition, it's natural for me to think about how to achieve the Kata Containers as one of multiple container runtimes in Istio to inject the workload. The good news is that I successfully deploy it in my environment, and this blog will introduce what's the benefit can we get from the Kata and how to deploy it.

## What's the benefit of using Kata Containers to Istio?

There is one critical difference for Kata to be a special container runtime: Kata runtime enforces a deeper level of isolation between containers. However, it's different from common virtual machines to take a minute or two for starting and wasting a fair amount of hardware resources on isolation, Kata starts just as fast and consumes resources just as efficiently as other containers. The containers become more secure with the fewest cost.

{{< image link="./traditional-containers-vs-Kata-containers.png" caption="Traditional containers VS Kata Containers" >}}

Therefore, it may be a good choice to gain a security pod environment without consuming much resources for Istio user.

## How to deploy workloads injection with Kata Containers in Istio?

### Environment Prepared

* Containerd
    * 1.5.6
* Kata Runtime
    * 3.0.2
* Kubernetes Cluster via kubeadm (do not use Kind)
    * 1.23
* Istio
    * 1.17-dev

### Install Kata Containers

There are 6 methods to install Kata Containers via the [installation guides](https://github.com/kata-containers/kata-containers/blob/main/docs/install/README.md), I have tried 2 of them (Using snap and Manual), and I recommend the `Manual` because it's mess to me when using snap. So let's get into [Manual guides](https://github.com/kata-containers/kata-containers/blob/main/docs/install/container-manager/containerd/containerd-install.md).

Highlights key steps:

* Move all files into `/opt/kata` in `<YOUR-WORKDIR>/opt/kata/` after untar the Kata Containers install package. There should be 4 folders under the directory of `/opt/kata`: `bin`, `libexec`, `runtime-rs`, `share`
* Copy `/opt/kata/share/defaults/kata-containers/configuration.toml` into `/etc/kata-containers/configuration.toml` Note: please choose the corrected configuration file for you, and create the directory `/etc/kata-containers` if not exists
* Create 5 symbolic links for Kata Containers installation files by following commands:

{{< text bash >}}
$ ln -s /opt/kata/bin/kata-runtime /usr/local/bin/kata-runtime
$ ln -s /opt/kata/bin/containerd-shim-kata-v2 /usr/local/bin/containerd-shim-kata-v2
$ ln -s /opt/kata/bin/kata-monitor /usr/local/bin/kata-monitor
$ ln -s /opt/kata/bin/kata-collect-data.sh /usr/local/bin/kata-collect-data.sh
$ ln -s /opt/kata/bin/qemu-system-x86_64 /usr/local/bin/qemu-system-x86_64
{{< /text >}}

Please refer to [Kata Containers installation guides](https://github.com/kata-containers/kata-containers/blob/main/docs/install/README.md) for more detail.

### Configure Containerd correctly

This content is included in [Configuration Containerd to use Kata Containers](https://github.com/kata-containers/kata-containers/blob/main/docs/how-to/containerd-kata.md#configuration), however, I just want to simply the `plugins` section configuration for Containerd by using [runtime class](https://kubernetes.io/docs/concepts/containers/runtime-class/) as below:

{{< text toml >}}
[plugins."io.containerd.grpc.v1.cri".containerd]
  default_runtime_name = "runc"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
      runtime_type = "io.containerd.kata.v2"
      privileged_without_host_devices = true
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata.options]
        ConfigPath = "/opt/kata/share/defaults/kata-containers/configuration.toml"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type = "io.containerd.runc.v2"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        SystemdCgroup = true
{{< /text >}}

In this configuration, I define 2 types of runtime: `runc` and `kata` and default by `runc`.

Note: please restart Containerd if the config is changed, such as `sudo systemctl daemon-reload` and `sudo systemctl restart containerd`.

### Configure kubelet correctly

This content is included in [Configure kubelet to use Kata Containers](https://github.com/kata-containers/kata-containers/blob/main/docs/how-to/how-to-use-k8s-with-containerd-and-kata.md#configure-kubelet-to-use-containerd), the configuration file `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf` is below:

{{< text plain >}}
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock --cgroup-driver=systemd"
{{< /text >}}

### Injects workload with Kata Containers in Istio

Generally, there should be no difference for user to install k8s cluster and Istio, such as I install cluster via `kubeadm` command `kubeadm init --cri-socket=unix:///run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16 --v=5 --ignore-preflight-errors=all` and install Istio via `istioctl` command `istioctl install -y`.

Based on the `containerd` configuration as before, `runc` is the default container runtime, then check it via `sudo systemctl status containerd`

{{< image link="./containerd-with-runc-by-default.png" caption="Containerd with Runc Running by Default" >}}

I use [runtime class](https://kubernetes.io/docs/concepts/containers/runtime-class/) to launch the Kata Containers, and its yaml file `kata-runtimeclass.yaml` is below:

{{< text yaml >}}
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata-runtime
handler: kata
{{< /text >}}

The `RuntimeClass` CR name is `kata-runtime` and field `handler` is specified to `kata`. Create this CR by command:

{{< text bash >}}
$ kubectl apply -f kata-runtimeclass.yaml
{{< /text >}}

I use `httpbin` as an example by using `httpbin.yaml`, however, there should be a little change for it, and the final yaml is below:

{{< text yaml >}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      runtimeClassName: kata-runtime
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
{{< /text >}}

Be careful then you can find that there is extra field `runtimeClassName: kata-runtime` in `containers` section of  `Deployment`. And I already define the `RuntimeClass` CR `kata-runtime`. Another note is that service account `httpbin` is necessary because the Kata Containers need a cluster role.

It's time to deploy this service by command:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f httpbin-hsm.yaml )
{{< /text >}}

**Verify the workload as below:**

{{< image link="./containerd-with-runc-by-default.png" caption="Containerd with Runc Running by Default" >}}

There is new property of Runtime Class Name showing in above red rectangle box.

**Verify the Containerd status as below:**

{{< image link="./containerd-with-kata-container.png" caption="Containerd for workload which Needs Kata" >}}

Besides the Containerd `containerd-shim-runc-v2`, there also are some other processes for Kata showing in above red rectangle box, such as `containerd-shim-kata-v2`, `virtiofsd` and `qemu-system-x86_64`. Because I deploy the service which requires Kata Containers to inject in Cluster.

## Conclusion

There are 2 conclusions from above practice:

* Basically, there are no much differences for using Kata Containers with other generic container runtimes in Istio from my use case: deploy httpbin and bookinfo, but we still need to verify more other things, such as network situation, Istio CNI enable and so on.
* There may be multiple container runtimes according to different requirements in Istio later in the same environment at the same time, and we need to aware of this.
