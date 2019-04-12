---
title: Istio Vault CA Integration
description: This task shows you how to integrate a Vault Certificate Authority with Istio for mutual TLS.
weight: 10
keywords: [security,certificate]
---

This task shows you how to integrate a [Vault Certificate Authority (CA)](https://www.vaultproject.io/) with Istio to issue certificates
for workloads in the mesh. This task includes a demo of Istio mutual TLS using certificates issued by a Vault CA.

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
    and Node Agent sending certificate signing requests to a testing Vault CA:

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

## Deploy workloads for testing

This section deploys the `httpbin` and `sleep` workloads for testing. When the sidecar of a
testing workload requests a certificate through SDS, Node Agent will send
certificate signing requests to Vault.

1.  Generate the deployments for the `httpbin` and `sleep` backends:

    {{< text bash >}}
    $ istioctl kube-inject -f @samples/httpbin/httpbin-vault.yaml@ > httpbin-injected.yaml
    $ istioctl kube-inject -f @samples/sleep/sleep-vault.yaml@ > sleep-injected.yaml
    {{< /text >}}

1.  Create the `vault-citadel-sa` service account for the Vault CA:

    {{< text bash >}}
    $ kubectl create serviceaccount vault-citadel-sa
    {{< /text >}}

1.  Since the Vault CA requires the authentication and authorization of Kubernetes service accounts,
    you must edit the `vault-citadel-sa` service account to use the example JWT configured
    on the testing Vault CA.
    To learn more about configuring a Vault CA for Kubernetes authentication and authorization,
    visit the [Vault Kubernetes `auth` method reference documentation](https://www.vaultproject.io/docs/auth/kubernetes.html).

    {{< text bash >}}
    $ export SA_SECRET_NAME=$(kubectl get serviceaccount vault-citadel-sa -o=jsonpath='{.secrets[0].name}')
    $ kubectl patch secret ${SA_SECRET_NAME} -p='{"data":{"token": "ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklpSjkuZXlKcGMzTWlPaUpyZFdKbGNtNWxkR1Z6TDNObGNuWnBZMlZoWTJOdmRXNTBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5dVlXMWxjM0JoWTJVaU9pSmtaV1poZFd4MElpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WldOeVpYUXVibUZ0WlNJNkluWmhkV3gwTFdOcGRHRmtaV3d0YzJFdGRHOXJaVzR0Y21aeFpHb2lMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObGNuWnBZMlV0WVdOamIzVnVkQzV1WVcxbElqb2lkbUYxYkhRdFkybDBZV1JsYkMxellTSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMblZwWkNJNklqSXpPVGs1WXpZMUxUQTRaak10TVRGbE9TMWhZekF6TFRReU1ERXdZVGhoTURBM09TSXNJbk4xWWlJNkluTjVjM1JsYlRwelpYSjJhV05sWVdOamIzVnVkRHBrWldaaGRXeDBPblpoZFd4MExXTnBkR0ZrWld3dGMyRWlmUS5STkgxUWJhcEpLUG1rdFYzdENucGl6N2hvWXB2MVRNNkxYelRoT3RhRHA3TEZwZUFOWmNKMXpWUWR5czNFZG5sa3J5a0dNZXBFanNkTnVUNm5kSGZoOGpSSkFadU5XTlBHcmh4ejRCZVVhT3FaZzN2N0F6SmxNZUZLallfZmlUWVlkMmdCWlp4a3B2MUZ2QVBpaEhZbmcyTmVOMm5LYmlaYnNuWk5VMXFGZHZiZ0NJU2FGcVRmMGRoNzVPemdDWF8xRmg2SE9BN0FOZjdwNTIyUERXX0JSbG4wUlR3VUpvdkNwR2VpTkNHZHVqR2lOTERaeUJjZHRpa1k1cnlfS1hUZHJWQWNUVXZJNmx4d1JiT05OZnVOOGhySURsOTV2SmpoVWxFLU8tX2N4OHFXdFhOZHFKbE1qZTFTc2lQQ0w0dXE3ME9lcEdfSTRhU3pDMm84YUR0bFE="}}'
    {{< /text >}}

1.  Deploy the `httpbin` and `sleep` backends:

    {{< text bash >}}
    $ kubectl apply -f httpbin-injected.yaml
    $ kubectl apply -f sleep-injected.yaml
    {{< /text >}}

## Istio mutual TLS with Vault CA integration

This section demos the use of mutual TLS with the Vault CA integration. In the previous steps,
you enabled mutual TLS for the Istio mesh and the `httpbin` and `sleep` workloads. These workloads receive
certificates from a testing Vault CA. When you send a `curl` request from the `sleep` workload
to the `httpbin` workload, the request goes through a mutual TLS protected channel constructed
with the certificates the Vault CA issued.

1.  Send a `curl` request from the `sleep` workload to the `httpbin` workload.
    The request succeeds with a `200` response code if it goes through the
    mutual TLS protected channel constructed with the certificates issued by the Vault CA.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -s -o /dev/null -w "%{http_code}" httpbin:8000/headers
    200
    {{< /text >}}

1.  To verify that not all requests are successful, send a `curl`
    request from the `sleep` Envoy sidecar to the `httpbin` workload.
    The request fails because the request from the sidecar to the `httpbin` workload did not use mutual TLS.

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -s -o /dev/null -w "%{http_code}" httpbin:8000/headers
    000command terminated with exit code 56
    {{< /text >}}

**Congratulations!** You successfully integrated a Vault CA with Istio to use mutual TLS
between workloads using the certificates the Vault CA issued.

## Cleanup

After completing this tutorial, you may delete the testing cluster created
at the beginning of this tutorial.

