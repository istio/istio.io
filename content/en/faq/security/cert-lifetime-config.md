---
title: How to configure the lifetime for Istio certificates?
weight: 70
---

For the workloads running in Kubernetes, the lifetime of their Istio certificates is controlled by the
`workload-cert-ttl` flag on Citadel. The default value is 90 days. This value should be no greater than
`max-workload-cert-ttl` of Citadel.

Citadel uses a flag `max-workload-cert-ttl` to control the maximum lifetime for Istio certificates issued to
workloads. The default value is 90 days. If `workload-cert-ttl` on Citadel or the Istio Agent is greater than
`max-workload-cert-ttl`, Citadel will fail issuing the certificate.

You can modify a [generated manifest](/docs/setup/install/istioctl/#generate-a-manifest-before-installation)
file to customize the Citadel configuration.
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
`workload-cert-ttl` flag on each Istio Agent. The default value is also 90 days. This value should be no greater than
`max-workload-cert-ttl` of Citadel.
