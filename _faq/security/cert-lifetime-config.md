---
title: How to configure the lifetime for Istio certificates?
order: 70
type: markdown
---
{% include home.html %}

For the workloads running in Kubernetes, the lifetime of their Istio certificates is controlled by the
`workload-cert-ttl` flag on Istio CA. The default value is 19 hours. This value should be no greater than
`max-workload-cert-ttl` of the Istio CA.

The Istio CA uses a flag `max-workload-cert-ttl` to control the maximum lifetime for Istio certificates issued to
workloads. The default value is 7 days. If `workload-cert-ttl` on CA or node agent is greater than
`max-workload-cert-ttl`, Istio CA will fail issuing the certificate.

Modify the `istio-auth.yaml` file to customize the CA configuration.
The following modification specifies that the Istio certificates for workloads running in Kubernetes
has 1 hours lifetime. Besides that, the maximum allowed Istio certificate lifetime is 48 hours.

```bash
...
kind: Deployment
...
metadata:
  name: istio-ca
  namespace: istio-system
spec:
  ...
  template:
    ...
    spec:
      ...
      containers:
      - name: istio-ca
        ...
        args:
          - --workload-cert-ttl=1h # Lifetime of certificates issued to workloads in Kubernetes.
          - --max-workload-cert-ttl=48h # Maximum lifetime of certificates issued to workloads by the CA.
```

For the workloads running on VMs and bare metal hosts, the lifetime of their Istio certificates is specified by the
`workload-cert-ttl` flag on each node agent. The default value is also 19 hours. This value should be no greater than
`max-workload-cert-ttl` of the Istio CA.

To customize this configuration, the argument for the node agent service should be modified.
After [setting up th machines]({{home}}/docs/setup/kubernetes/mesh-expansion.html#setting-up-the-machines) for Istio
mesh expansion, modify the file `/lib/systemd/system/istio-auth-node-agent.service` on the VMs or bare metal hosts:

```bash
...
[Service]
ExecStart=/usr/local/bin/node_agent --workload-cert-ttl=24h # Specify certificate lifetime for workloads on this machine.
Restart=always
StartLimitInterval=0
RestartSec=10
...
```

The above configuraiton specifies that the Istio certificates for workloads running on this VM or bare metal host
will have 24 hours lifetime.

After configuring the service, restart the node agent by running `systemctl daemon-reload`.