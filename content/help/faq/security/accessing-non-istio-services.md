---
title: How to disable mutual TLS on clients to access the Kubernetes API Server (or any services that don't have Istio sidecar)?
weight: 60
---

When globally enable mutual TLS, the *global* destination rule matches all services in the cluster, including Kubernetes API Server. However, as the
API server doesn't have Istio sidecar, you will need to set a destination rule to exempt API server from mutual TLS. For example:

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
 name: "api-server"
spec:
 host: "kubernetes.default.svc.cluster.local"
 trafficPolicy:
   tls:
     mode: DISABLE
EOF
{{< /text >}}

> This destination rule is already added to the system as part of the
[Istio installation with default mutual TLS](/docs/setup/kubernetes/quick-start/#option-2-install-istio-with-default-mutual-tls-authentication).

Similarly, you can add destination rules for other non-Istio services. For more examples, see [task](/docs/tasks/security/authn-policy/#request-from-istio-services-to-non-istio-services).