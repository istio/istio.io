---
title: How can services that use Istio access non-Istio services?
weight: 40
---

When mutual TLS is globally enabled, the *global* destination rule matches all services in the cluster, whether or not these services have an Istio sidecar.
This includes the Kubernetes API server, as well as any non-Istio services in the cluster. To communicate with such services from services that have an Istio
sidecar, you need to set a destination rule to exempt the service. For example:

{{< text bash >}}
$ kubectl apply -f - <<EOF
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

{{< tip >}}
This destination rule is already added to the system when
Istio is installed with mutual TLS enabled.
{{< /tip >}}

Similarly, you can add destination rules for other non-Istio services. For more examples, see [task](/pt-br/docs/tasks/security/authentication/authn-policy/#request-from-istio-services-to-non-istio-services).
