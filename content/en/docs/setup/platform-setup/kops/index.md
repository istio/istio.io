---
title: KOPS on AWS
description: Instructions to setup Kops for use with Istio.
weight: 20
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/kops/
    - /docs/setup/kubernetes/platform-setup/kops/
keywords: [platform-setup,kubernetes,kops]
---

Follow these instructions to prepare an AWS cluster with Kops for Istio.

When you install a new cluster with Kubernetes version 1.9+, the prerequisite to
enable `admissionregistration.k8s.io/v1beta1` is covered.

For Kubernetes clusters <=1.15 , you must update the list of admission controllers.

1. Open the configuration file:

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. Add the following in the configuration file:

    {{< text yaml >}}
    kubeAPIServer:
        admissionControl:
        - NodeRestriction
    {{< /text >}}

For Kubernetes clusters >=1.16 , you must update the list of admission controllers.

1. Open the configuration file:

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. Add the following in the configuration file:

    {{< text yaml >}}
    kubeAPIServer:
        admissionControl:
        - NamespaceLifecycle
        - LimitRanger
        - ServiceAccount
        - PersistentVolumeLabel
        - DefaultStorageClass
        - DefaultTolerationSeconds
        - MutatingAdmissionWebhook
        - ValidatingAdmissionWebhook
        - ResourceQuota
        - NodeRestriction
        - Priority
    {{< /text >}}

If you wish to run Istio SDS in version 1.3+ on kubernetes 1.11, you must enable service account token projection volumes in the api-server, as well as the feature gates.

1. Open the configuration file:

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. Add the following in the configuration file:

    {{< text yaml >}}
    kubeAPIServer:
        featureGates:
            TokenRequest: "true"
            TokenRequestProjection: "true"
        apiAudiences:
        - api
        - istio-ca
        serviceAccountIssuer: kubernetes.default.svc
        serviceAccountKeyFile:
        - /srv/kubernetes/server.key
        serviceAccountSigningKeyFile: /srv/kubernetes/server.key
    {{< /text >}}

If you wish to run Istio SDS in version 1.3+ on kubernetes 1.12+, you must enable service account token projection volumes in the api-server.

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
        serviceAccountKeyFile:
        - /srv/kubernetes/server.key
        serviceAccountSigningKeyFile: /srv/kubernetes/server.key
    {{< /text >}}


If you have made any changes to the cluser config:

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

1. For clusters <=1.15, Validate the update with the `kubectl` client on the `kube-api` pod, you
   should see new admission controller:

    {{< text bash >}}
    $ for i in `kubectl \
      get pods -n kube-system | grep api | awk '{print $1}'` ; \
      do  kubectl describe pods -nkube-system \
      $i | grep "/usr/local/bin/kube-apiserver"  ; done
    {{< /text >}}

1. Review the output:

    Kubernetes up to 1.9:

    {{< text plain >}}
    [...]
    --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,
    PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,
    MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,
    NodeRestriction,Priority
    [...]
    {{< /text >}}

    Kubernetes 1.10+:

    {{< text plain >}}
    [...]
    --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,
    PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,
    MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,
    NodeRestriction,Priority
    [...]
    {{< /text >}}
