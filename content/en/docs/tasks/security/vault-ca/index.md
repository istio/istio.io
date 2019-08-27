---
title: Istio Vault CA Integration
description: This task shows you how to integrate a Vault Certificate Authority with Istio for mutual TLS.
weight: 10
keywords: [security,certificate]
---

{{< warning >}}
The following information describes an experimental feature, which is intended
for evaluation purposes only.
{{< /warning >}}

This task shows you how to integrate a [Vault Certificate Authority (CA)](https://www.vaultproject.io/) with Istio to issue certificates
for workloads in the mesh. Istio Vault integration is an experimental feature. This task includes a demo of Istio mutual TLS using certificates issued by a Vault CA.

## Before you begin

* Create a new Kubernetes cluster to run the example in this tutorial.
* Istio Vault CA integration uses Kubernetes service account for authentication
so it only works in Kubernetes environments. This task uses Kubernetes version 1.11.

## Certificate request flow

At high level, an Istio proxy (i.e., Envoy) requests a certificate from Node Agent
through SDS. Node Agent sends a CSR (Certificate Signing Request), with the Kubernetes service
account token of the Istio proxy attached, to Vault CA. Vault CA authenticates and authorizes
the CSR based on the Kubernetes service account token and returns the signed certificate
to Node Agent, which returns the signed certificate to the Istio proxy.

## Install Istio with mutual TLS and SDS enabled

1.  Install Istio with mutual TLS and SDS enabled using [Helm](/docs/setup/install/helm/#prerequisites)
    and Node Agent sending certificate signing requests to a testing Vault CA:

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    $ kubectl create namespace istio-system
    $ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
    $ helm template \
        --name=istio \
        --namespace=istio-system \
        --set global.mtls.enabled=true \
        --values install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml \
        install/kubernetes/helm/istio > istio-auth.yaml
    $ kubectl apply -f istio-auth.yaml
    {{< /text >}}

The yaml file [`values-istio-example-sds-vault.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml)
contains the configuration that enables SDS (secret discovery service) in Istio.
The Vault CA related configuration is set as environmental variables:

{{< text yaml >}}
env:
- name: CA_ADDR
  value: "https://34.83.129.211:8200"
- name: CA_PROVIDER
  value: "VaultCA"
- name: "VAULT_ADDR"
  value: "https://34.83.129.211:8200"
- name: "VAULT_AUTH_PATH"
  value: "auth/kubernetes/login"
- name: "VAULT_ROLE"
  value: "istio-cert"
- name: "VAULT_SIGN_CSR_PATH"
  value: "istio_ca/sign/istio-pki-role"
{{< /text >}}

1.  The testing Vault server used in this tutorial has the IP
    address `34.83.129.211`. Create a service entry with the address of the testing
    Vault server:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: vault-service-entry
    spec:
      hosts:
      - vault-server
      addresses:
      - 34.83.129.211/32
      ports:
      - number: 8200
        name: https
        protocol: HTTPS
      location: MESH_EXTERNAL
    EOF
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
    you must edit the `vault-citadel-sa` service account to use the example Kubernetes service account
    that has already been configured on the testing Vault CA for authentication and authorization.
    When integrating your Vault server with Istio for issuing certificates, you are responsible to
    configure your Vault server's authentication and authorization for Kubernetes service accounts.

    To learn more about configuring a Vault CA for Kubernetes authentication and authorization,
    visit the [Vault Kubernetes `auth` method reference documentation](https://www.vaultproject.io/docs/auth/kubernetes.html).
    See the [configuring a basic Vault server section](#configuring-a-basic-vault-server) for an example on
    how to authenticate and authorize Kubernetes service accounts.

    {{< text bash >}}
    $ export SA_SECRET_NAME=$(kubectl get serviceaccount vault-citadel-sa -o=jsonpath='{.secrets[0].name}')
    $ kubectl patch secret ${SA_SECRET_NAME} -p='{"data":{"token": "ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklpSjkuZXlKcGMzTWlPaUpyZFdKbGNtNWxkR1Z6TDNObGNuWnBZMlZoWTJOdmRXNTBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5dVlXMWxjM0JoWTJVaU9pSmtaV1poZFd4MElpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WldOeVpYUXVibUZ0WlNJNkluWmhkV3gwTFdOcGRHRmtaV3d0YzJFdGRHOXJaVzR0TnpSMGQzTWlMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObGNuWnBZMlV0WVdOamIzVnVkQzV1WVcxbElqb2lkbUYxYkhRdFkybDBZV1JsYkMxellTSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMblZwWkNJNklqSmhZekF6WW1FeUxUWTVNVFV0TVRGbE9TMDVOamt3TFRReU1ERXdZVGhoTURFeE5DSXNJbk4xWWlJNkluTjVjM1JsYlRwelpYSjJhV05sWVdOamIzVnVkRHBrWldaaGRXeDBPblpoZFd4MExXTnBkR0ZrWld3dGMyRWlmUS5wWjhTaXlOZU8wcDFwOEhCOW9YdlhPQUkxWENKWktrMndWSFhCc1RTektXeGxWRDlIckhiQWNTYk8yZGxoRnBlQ2drbnQ2ZVp5d3ZoU2haSmgyRjYtaUhQX1lvVVZvQ3FRbXpqUG9CM2MzSm9ZRnBKby05alROMV9tTlJ0WlVjTnZZbC10RGxUbUJsYUtFdm9DNVAyV0dWVUYzQW9Mc0VTNjZ1NEZHOVdsbG1MVjkyTEcxV05xeF9sdGtUMXRhaFN5OVdpSFFneXpQcXd0d0U3MlQxakFHZGdWSW9KeTFsZlNhTGFtX2JvOXJxa1JsZ1NnLWF1OUJBalppREd0bTl0ZjNsd3JjZ2ZieGNjZGxHNGpBc1RGYTJhTnMzZFc0TkxrN21GbldDSmEtaVdqLVRnRnhmOVRXLTlYUEswZzNvWUlRMElkMENJVzJTaUZ4S0dQQWpCLWc="}}'
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

## Configuring a basic Vault server

The Vault server administrator is responsible of hosting and managing the server. When signing a CSR, Istio Citadel Agent
passes the Kubernetes service account token of the workload and the CSR to the Vault server,
which authenticates and authorizes the request (e.g., based on the
[Vault Kubernetes `auth` method](https://www.vaultproject.io/docs/auth/kubernetes.html)) and
returns the signed certificate to Istio Citadel Agent, if the request is authorized.
Based on their security requirements, owners of Vault servers may configure various
certificate issuance policies for Kubernetes service accounts and certificate
signing requests.

The following instructions configure an example basic Vault server to authenticate and authorize a CSR
based on the Vault Kubernetes auth method.

{{< warning >}}
The instructions here are for illustrative purposes only. Please consult with security experts
to set up the security configuration and certificate issuance policies of your Vault servers.
{{< /warning >}}

The instructions are based on the
posts [1](https://evalle.xyz/posts/integration-kubernetes-with-vault-auth/) and
[2](https://github.com/coreos/vault-operator/blob/master/doc/user/kubernetes-auth-backend.md).

1.  Create a Kubernetes cluster to host an example basic Vault server.
    In the Kubernetes cluster created, install, initialize, unseal, and login Vault.
    Examples of install, initialize, unseal, and login Vault can be found in the post
    [1](https://evalle.xyz/posts/integration-kubernetes-with-vault-auth/).
    The example Vault server used in this guide is of 0.10.3 release version,
    downloadable from the [docker hub](https://hub.docker.com/_/vault?tab=tags&page=1).

1.  Follow the post [2](https://github.com/coreos/vault-operator/blob/master/doc/user/kubernetes-auth-backend.md)
    to set up a Kubernetes service account for Vault token review.

    {{< text bash >}}
    $ kubectl create serviceaccount vault-tokenreview
    $ kubectl apply -f - <<EOF
    apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: vault-tokenreview-binding
      namespace: default
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: system:auth-delegator
    subjects:
    - kind: ServiceAccount
      name: vault-tokenreview
      namespace: default
    EOF
    $ SECRET_NAME=$(kubectl get serviceaccount vault-tokenreview -o jsonpath='{.secrets[0].name}')
    $ TR_ACCOUNT_TOKEN=$(kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.token}' | base64 --decode)
    {{< /text >}}

1.  Follow the post [2](https://github.com/coreos/vault-operator/blob/master/doc/user/kubernetes-auth-backend.md)
    to enable and configure the Vault Kubernetes Auth method. The parameters `kubernetes_host`
    and `kubernetes_ca_cert` are described in the
    [Vault API document](https://www.vaultproject.io/api/auth/kubernetes/index.html#kubernetes_host).

    {{< text bash >}}
    $ vault auth enable kubernetes
    $ vault write auth/kubernetes/config kubernetes_host=<your-kubernetes-host> \
        kubernetes_ca_cert=<your-kubernetes-ca-cert> token_reviewer_jwt=$TR_ACCOUNT_TOKEN
    {{< /text >}}

1.  Follow the post [2](https://github.com/coreos/vault-operator/blob/master/doc/user/kubernetes-auth-backend.md)
    to create a Vault policy and a role bound to the `default` service account.

    {{< text bash >}}
    $ cat <<EOF > ./policy.hcl
    {
        "name": "istio-cert",
        "path": {
            "istio_ca/sign/istio-pki-role": {
                "capabilities": ["update", "read"]
            }
        }
    }
    EOF
    $ vault write sys/policy/istio-cert policy=@./policy.hcl
    $ vault write auth/kubernetes/role/istio-cert \
        bound_service_account_names=default \
        bound_service_account_namespaces=default \
        policies=istio-cert \
        ttl=10h
    {{< /text >}}

1.  Create a PKI secret engine for the example Vault CA and configure its private key and certificate.
    The `pem_bundle` is a file containing the private key and certificate created by you for the example Vault CA.
    An example `pem_bundle` can be found [here](https://www.terraform.io/docs/providers/vault/r/pki_secret_backend_config_ca.html).
    An example of creating CA certificate and key can be found in
    the post [1](https://evalle.xyz/posts/integration-kubernetes-with-vault-auth/).

    {{< text bash >}}
    $ vault secrets enable -path=istio_ca -description="An example Vault CA" pki
    $ vault write istio_ca/config/ca pem_bundle=<the-file-storing-private-key-and-certificate-of-the-example-Vault-CA>
    {{< /text >}}

1. Create a role in the example Vault CA.

    {{< text bash >}}
    $ vault write istio_ca/roles/istio-pki-role allow_any_name=true require_cn=false \
        allowed_uri_sans="*" use_csr_sans=true basic_constraints_valid_for_non_ca=true \
        key_usage="DigitalSignature","KeyEncipherment"
    {{< /text >}}

1.  If you like to sign a CSR at the example Vault CA,
    save to a file the token of the `default` Kubernetes service account that has been configured on the example Vault.
    The following command saves the `default` Kubernetes service account to a file `default-service-account.yaml`.

    {{< text bash >}}
    $ kubectl get secret $(kubectl get serviceaccount default -o=jsonpath='{.secrets[0].name}') -o yaml > default-service-account.yaml
    {{< /text >}}

    Create a [Kubernetes service](https://kubernetes.io/docs/concepts/services-networking/service/) to expose
    your example Vault CA,
    e.g., [the link](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/)
    contains instructions to expose your application through a load balancer.
    Edit the yaml file [`values-istio-example-sds-vault.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml)
    to set the address of CA provider and Vault to be the address of your example Vault CA, and set
    the TLS root certificate of your example Vault CA.

    After that, similar to the steps at the beginning of this guide,
    deploy Istio, edit the secret of the `vault-citadel-sa` service account to use
    the `default` Kubernetes service account that has been configured on your example Vault,
    and deploy the `httpbin` and `sleep` backends.
