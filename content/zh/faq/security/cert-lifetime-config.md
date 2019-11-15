---
title: How to configure the lifetime for Istio certificates?
weight: 70
---

For the workloads running in Kubernetes, the lifetime of their Istio certificates is controlled by the
`workload-cert-ttl` flag on Citadel. The default value is 90 days. This value should be no greater than
`max-workload-cert-ttl` of Citadel.

Citadel uses a flag `max-workload-cert-ttl` to control the maximum lifetime for Istio certificates issued to
workloads. The default value is 90 days. If `workload-cert-ttl` on Citadel or node agent is greater than
`max-workload-cert-ttl`, Citadel will fail issuing the certificate.

Modify the `istio-demo.yaml` file to customize the Citadel configuration.
The following modification specifies that the Istio certificates for workloads running in Kubernetes
has 1 hours lifetime. Besides that, the maximum allowed Istio certificate lifetime is 48 hours.

{{< text plain >}}
...
kind: Deployment
...
metadata:
  name: istio-citadel
  namespace: istio-system
spec:
  ...
  template:
    ...
    spec:
      ...
      containers:
      - name: citadel
        ...
        args:
          - --workload-cert-ttl=1h # Lifetime of certificates issued to workloads in Kubernetes.
          - --max-workload-cert-ttl=48h # Maximum lifetime of certificates issued to workloads by Citadel.
{{< /text >}}

For the workloads running on VMs and bare metal hosts, the lifetime of their Istio certificates is specified by the
`workload-cert-ttl` flag on each node agent. The default value is also 90 days. This value should be no greater than
`max-workload-cert-ttl` of Citadel.

To customize this configuration, the argument for the node agent service should be modified.
After [setting up the machines](/docs/examples/virtual-machines/single-network/#setting-up-the-vm) for Istio
mesh expansion, modify the file `/lib/systemd/system/istio-auth-node-agent.service` on the VMs or bare metal hosts:

{{< text plain >}}
...
[Service]
ExecStart=/usr/local/bin/node_agent --workload-cert-ttl=24h # Specify certificate lifetime for workloads on this machine.
Restart=always
StartLimitInterval=0
RestartSec=10
...
{{< /text >}}

The above configuration specifies that the Istio certificates for workloads running on this VM or bare metal host
will have 24 hours lifetime.

After configuring the service, restart the node agent by running `systemctl daemon-reload`.
