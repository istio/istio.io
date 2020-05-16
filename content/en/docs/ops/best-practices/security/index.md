---
title: Security Best Practices
description: Best practices for securing applications using Istio.
force_inline_toc: true
weight: 30
---

This section provides some deployment guidelines to help keep a service mesh secure.

## Use namespaces for isolation

If there are multiple service operators (a.k.a. [SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering))
deploying different services in a medium- or large-size cluster, we recommend creating a separate
[Kubernetes namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/) for each SRE team to isolate their access.
For example, you can create a `team1-ns` namespace for `team1`, and `team2-ns` namespace for `team2`, such
that both teams cannot access each other's services.

{{< warning >}}
If Citadel is compromised, all its managed keys and certificates in the cluster may be exposed.
We **strongly** recommend running Citadel in a dedicated namespace (for example, `istio-citadel-ns`), to restrict access to
the cluster to only administrators.
{{< /warning >}}

Let us consider a three-tier application with three services: `photo-frontend`,
`photo-backend`, and `datastore`. The photo SRE team manages the
`photo-frontend` and `photo-backend` services while the datastore SRE team
manages the `datastore` service. The `photo-frontend` service can access
`photo-backend`, and the `photo-backend` service can access `datastore`.
However, the `photo-frontend` service cannot access `datastore`.

In this scenario, a cluster administrator creates three namespaces:
`istio-citadel-ns`, `photo-ns`, and `datastore-ns`. The administrator has
access to all namespaces and each team only has access to its own namespace.
The photo SRE team creates two service accounts to run `photo-frontend` and
`photo-backend` respectively in the `photo-ns` namespace. The datastore SRE
team creates one service account to run the `datastore` service in the
`datastore-ns` namespace. Moreover, we need to enforce the service access
control in [Istio Mixer](/docs/reference/config/policy-and-telemetry/) such that
`photo-frontend` cannot access datastore.

In this setup, Kubernetes can isolate the operator privileges on managing the services.
Istio manages certificates and keys in all namespaces
and enforces different access control rules to the services.

## Configure third party service account tokens

To authenticate with the Istio control plane, the Istio proxy will use a Service Account token. Kubernetes supports two forms of these tokens:

* Third party tokens, which have a scoped audience and expiration.
* First party tokens, which have no expiration and are mounted into all pods.

Because the properties of the first party token are less secure, Istio will default to using third party tokens. However, this feature is not enabled on all Kubernetes platforms.

If you are using `istioctl` to install, support will be automatically detected. This can be done manually as well, and configured by passing `--set values.global.jwtPolicy=third-party-jwt` or `--set values.global.jwtPolicy=first-party-jwt`.

To determine if your cluster supports third party tokens, look for the `TokenRequest` API:

    {{< text bash >}}
    $ kubectl get --raw /api/v1 | jq '.resources[] | select(.name | index("serviceaccounts/token"))'
    {
        "name": "serviceaccounts/token",
        "singularName": "",
        "namespaced": true,
        "group": "authentication.k8s.io",
        "version": "v1",
        "kind": "TokenRequest",
        "verbs": [
            "create"
        ]
    }
    {{< /text >}}

While most cloud providers support this feature now, many local development tools and custom installations may not. To enable this feature, please refer to the [Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection).
