---
title: Istio Vault CA Integration
description: Show how to integrate with Vault CA for mutual TLS.
weight: 10
keywords: [security,certificate]
---

This task walks you through an example of integrating Istio with a [Vault CA](https://www.vaultproject.io/) to issue certificates
to Istio workloads and shows a demo of Istio mutual TLS using certificates issued by a Vault CA.

## Before you begin

* Create a new Kubernetes cluster to run the example in this tutorial.

## Certificate request flow

At high level, an Istio proxy (i.e., Envoy) requests a certificate from Node Agent
through SDS. Node Agent sends a CSR (Certificate Signing Request), with the Kubernetes service
account token of the Istio proxy attached, to Vault CA. Vault CA authenticates and authorizes
the CSR based on the Kubernetes service account token and returns the signed certificate
to Node Agent, which returns the signed certificate to the Istio proxy.

## Install Istio with mutual TLS and SDS enabled

1.  Install Istio with mutual TLS and SDS enabled using [Helm](/docs/setup/kubernetes/install/helm/#prerequisites)
and Node Agent sending certificate signing
requests to a testing Vault CA:

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    $ cat install/kubernetes/namespace.yaml > istio-auth.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-* >> istio-auth.yaml
    $ helm template \
        --name=istio \
        --namespace=istio-system \
        --set global.mtls.enabled=true \
        --set global.proxy.excludeIPRanges="35.233.249.249/32" \
        --values install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml \
        install/kubernetes/helm/istio >> istio-auth.yaml
    $ kubectl create -f istio-auth.yaml
    {{< /text >}}

The testing Vault server used in this tutorial has the IP
address `35.233.249.249`. The configuration
`global.proxy.excludeIPRanges="35.233.249.249/32"` whitelists the IP address of
the testing Vault server, so that Envoy will not intercept the traffic from
Node Agent to Vault.

The yaml file [`values-istio-example-sds-vault.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml)
contains the configuration that enables SDS (secret discovery service) in Istio.
The Vault CA related configuration is set as environmental variables:

{{< text yaml >}}
env:
- name: CA_ADDR
  value: "https://35.233.249.249:8200"
- name: CA_PROVIDER
  value: "VaultCA"
- name: "VAULT_ADDR"
  value: "https://35.233.249.249:8200"
- name: "VAULT_AUTH_PATH"
  value: "auth/kubernetes/login"
- name: "VAULT_ROLE"
  value: "istio-cert"
- name: "VAULT_SIGN_CSR_PATH"
  value: "istio_ca/sign/istio-pki-role"
{{< /text >}}

## Deploy testing workloads

This section deploys testing workloads `httpbin` and `sleep`. When the sidecar of a
testing workload requests a certificate through SDS, Node Agent will send
certificate signing requests to Vault.

1.  Generate the deployment for an example `httpbin` backend and an example `sleep` backend:

    {{< text bash >}}
    $ istioctl kube-inject -f @samples/httpbin/httpbin-vault.yaml@ > httpbin-injected.yaml
    $ istioctl kube-inject -f @samples/sleep/sleep-vault.yaml@ > sleep-injected.yaml
    {{< /text >}}

1.  Create a service account `vault-citadel-sa`:

    {{< text bash >}}
    $ kubectl create serviceaccount vault-citadel-sa
    {{< /text >}}

1.  Edit the service account `vault-citadel-sa` to use an example JWT token that has been configured
on the testing Vault CA. The reason of this configuration is that a Vault CA requires authentication
and authorization of Kubernetes service accounts.
For the information about configuring Vault for Kubernetes authentication and authorization,
please refer to [Vault Kubernetes auth method](https://www.vaultproject.io/docs/auth/kubernetes.html).

    {{< text bash >}}
    $ export SA_SECRET_NAME=$(kubectl get serviceaccount vault-citadel-sa -o=jsonpath='{.secrets[0].name}')
    $ kubectl edit secret ${SA_SECRET_NAME}

    # When editing the secret, change the field "token" to: ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklpSjkuZXlKcGMzTWlPaUpyZFdKbGNtNWxkR1Z6TDNObGNuWnBZMlZoWTJOdmRXNTBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5dVlXMWxjM0JoWTJVaU9pSmtaV1poZFd4MElpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WldOeVpYUXVibUZ0WlNJNkluWmhkV3gwTFdOcGRHRmtaV3d0YzJFdGRHOXJaVzR0Y21aeFpHb2lMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObGNuWnBZMlV0WVdOamIzVnVkQzV1WVcxbElqb2lkbUYxYkhRdFkybDBZV1JsYkMxellTSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMblZwWkNJNklqSXpPVGs1WXpZMUxUQTRaak10TVRGbE9TMWhZekF6TFRReU1ERXdZVGhoTURBM09TSXNJbk4xWWlJNkluTjVjM1JsYlRwelpYSjJhV05sWVdOamIzVnVkRHBrWldaaGRXeDBPblpoZFd4MExXTnBkR0ZrWld3dGMyRWlmUS5STkgxUWJhcEpLUG1rdFYzdENucGl6N2hvWXB2MVRNNkxYelRoT3RhRHA3TEZwZUFOWmNKMXpWUWR5czNFZG5sa3J5a0dNZXBFanNkTnVUNm5kSGZoOGpSSkFadU5XTlBHcmh4ejRCZVVhT3FaZzN2N0F6SmxNZUZLallfZmlUWVlkMmdCWlp4a3B2MUZ2QVBpaEhZbmcyTmVOMm5LYmlaYnNuWk5VMXFGZHZiZ0NJU2FGcVRmMGRoNzVPemdDWF8xRmg2SE9BN0FOZjdwNTIyUERXX0JSbG4wUlR3VUpvdkNwR2VpTkNHZHVqR2lOTERaeUJjZHRpa1k1cnlfS1hUZHJWQWNUVXZJNmx4d1JiT05OZnVOOGhySURsOTV2SmpoVWxFLU8tX2N4OHFXdFhOZHFKbE1qZTFTc2lQQ0w0dXE3ME9lcEdfSTRhU3pDMm84YUR0bFE=
    {{< /text >}}

1.  Deploy the example backends:

    {{< text bash >}}
    $ kubectl apply -f httpbin-injected.yaml
    $ kubectl apply -f sleep-injected.yaml
    {{< /text >}}

## Istio mutual TLS with Vault CA integration

This section provides a demo of Istio mutual TLS with Vault CA integration. With the previous steps,
mutual TLS is enabled for the Istio deployment and the testing workloads `httpbin` and `sleep` receive
certificates from the testing Vault CA. When sending a curl request from the `sleep` workload
to the `httpbin` workload, the request goes through a mutual TLS protected channel constructed from
the certificates issued by the Vault CA.

1.  Send a `curl` request from the `sleep` workload to the `httpbin` workload.
The request should succeed with a 200 response code since it goes through a mutual TLS protected channel
constructed from the certificates issued by the Vault CA.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -s -o /dev/null -w "%{http_code}" httpbin:8000/headers
    200
    {{< /text >}}

1.  Send a `curl` request from the `sleep` Envoy sidecar to the `httpbin` workload.
The request should fail because the `httpbin` requires a mutual TLS connection while the request
from the sidecar does not use mutual TLS.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -s -o /dev/null -w "%{http_code}" httpbin:8000/headers
    000command terminated with exit code 56
    {{< /text >}}

1.  After finishing the above demo, you have completed the task in this
document, which integrates Istio with an external Vault CA and demonstrates
Istio mutual TLS with the certificates issued from the Vault CA.

## Cleanup

After completing this tutorial, you may delete the testing cluster created
at the beginning of this tutorial.

