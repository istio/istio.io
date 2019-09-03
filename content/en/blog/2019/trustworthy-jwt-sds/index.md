---
title: Change in Secret Discovery Service in Istio 1.3
description: Taking advantage of Kubernetes trustworthy JWTs to issue certificates for workload instances more securely.
publishdate: 2019-09-10
attribution: Phillip Quy Le (Google)
keywords: [security, PKI, certificate, nodeagent, sds]
---

In Istio 1.3, we are taking advantage of improvements in Kubernetes to issue certificates for workload instances more securely.

When a Citadel Agent (the agent that runs on a node and is responsible for obtaining certificates)
sends a certificate signing request to Citadel to get a certificate for a workload instance,
it includes the JWT that the Kubernetes API server issued representing the service account of the workload instance.
If Citadel can authenticate the JWT, then it extracts the service account name needed to issue the certificate for the workload instance.

The API server prior to Kubernetes 1.12 issues JWTs that present the following problems:

1. The tokens don't have important fields to limit their scope of usage, such as `aud` or `exp`. See [Bound Service Tokens](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/auth/bound-service-account-tokens.md) for more info.
1. The tokens are mounted onto all the pods without a way to opt-out. See [Service Account Token Volumes](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/svcacct-token-volume-source.md) for motivation.

The `trustworthy` JWTs were introduced in Kubernetes 1.12 to solve the aforementioned issues.
However, Kubernetes didn't support the `aud` to be anything other than the API server audience until [Kubernetes 1.13](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.13.md).
To better secure the mesh, Istio 1.3 only supports `trustworthy` JWTs and sets the `aud` to a specific value (for example, the value is `istio-ca` in Citadel) when you enable SDS.
Before upgrading your Istio deployment to 1.3 with SDS enabled, verify that you use Kubernetes 1.13 or later.

Make the following considerations based on your platform of choice:

- **GKE:** Upgrade your cluster version to at least 1.13.
- **On-prem Kubernetes** and **GKE on-prem:** Add [extra configurations](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) to your Kubernetes. You may
also want to refer to the [api-server page](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/) for the most up-to-date flag names.
- For other platforms, check with your provider. If your vendor does not support trustworthy JWTs, you will need to fall back to the file-mount approach to propagate the workload keys and certificates in Istio 1.3.
