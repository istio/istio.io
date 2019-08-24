---
title: Istio 1.3 with SDS Announcement
description: Istio 1.3 with SDS Announcement.
publishdate: 2019-08-23
attribution: Phillip Quy Le (Google)
keywords: [security, PKI, certificate, nodeagent, sds]
---

In Istio 1.3, we have made a change to take advantage of improvements in Kubernetes in order to more
securely issue certificates for workloads.

When a Citadel Agent (the agent that runs on a node and is responsible for obtaining certificates)
sends a Certificate Signing Request to Citadel to get a certificate and private key for a workload,
it includes a JWT issued by the Kubernetes API server. Citadel then sends a `TokenReview` request to
the API server to verify the JWT. If the JWT is authenticated, Citadel then extracts information
from the JWT such as service account name to issue the certificate for the workload.

Before Kubernetes 1.12, the JWT tokens that API server issues have two problems:

1. These tokens do not have important fields, such as `aud` or `exp`. See [Bound Service Tokens](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/auth/bound-service-account-tokens.md) for more info.
1. These tokens are injected into pods as secrets. See [Service Account Token Volumes](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/svcacct-token-volume-source.md) for motivation.

Trustworthy JWTs (new JWTs that do not suffer from the two aforementioned problems) were introduced
in Kubernetes 1.12 (beta). Starting from Istio 1.3, we will only support trustworthy JWTs when SDS
is enabled. That being said, before upgrading to Istio 1.3 with SDS, please make sure you're using
a supported version of Kubernetes.

If your workloads are running on:

- GKE, simply upgrade your cluster version to at least 1.12.
- Kubernetes on-prem and GKE on-prem, please add extra configurations to your Kubernetes. You may
also want to refer to the api-server page for the most up-to-date flag names.
- For other environments, check with your providers.
    - As of today, AWS and IBM Cloud do not support trustworthy JWT feature yet, but are actively
    working on this.
    - If your vendor does not support trustworthy JWTs, you will need to fall back to file mount in
    Istio 1.3.