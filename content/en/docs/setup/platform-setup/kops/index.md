---
title: Kops
description: Instructions to set up Kops for use with Istio.
weight: 33
skip_seealso: true
keywords: [platform-setup,kubernetes,kops]
owner: istio/wg-environments-maintainers
test: no
---

{{< tip >}}
No special configuration is required to run Istio on Kubernetes clusters version 1.22 or newer. For prior Kubernetes versions, you will need to continue to perform these steps.
{{< /tip >}}

If you wish to run Istio [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration) (SDS) for your mesh on Kops managed clusters, you must add [extra configurations](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) to enable service account token projection volumes in the api-server.

1. Open the configuration file:

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. Add the following in the configuration file:

    {{< text yaml >}}
    kubeAPIServer:
        apiAudiences:
        - api
        - istio-ca
        serviceAccountIssuer: kubernetes.default.svc
    {{< /text >}}

1. Perform the update:

    {{< text bash >}}
    $ kops update cluster
    $ kops update cluster --yes
    {{< /text >}}

1. Launch the rolling update:

    {{< text bash >}}
    $ kops rolling-update cluster
    $ kops rolling-update cluster --yes
    {{< /text >}}
