---
title: Custom CA Integration using Kubernetes CSR
description: Shows how to use a Custom Certificate Authority (that integrates with the Kubernetes CSR API) to provision Istio workload certificates.
weight: 100
keywords: [security,certificate]
aliases:
    - /docs/tasks/security/custom-ca-k8s/
owner: istio/wg-security-maintainers
test: no
status: Experimental
---

{{< boilerplate experimental >}}

This feature requires Kubernetes version >= 1.18.

This task shows how to provision Workload Certificates
using a custom certificate authority that integrates with the
[Kubernetes CSR API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/). Different workload can get their certificate signed from different cert-signer. Each cert-signer is effectively a different CA. It is expected that workloads whose certificates are issued from the same cert-signer can talk MTLS to each other while workloads signed by different signers cannot.
This feature leverages [Chiron](/blog/2019/dns-cert/), a lightweight component linked with Istiod that signs certificates using the Kubernetes CSR API.

For this example, we use [open-source cert-manager](https://cert-manager.io).
Cert-manager has added [experimental Support for Kubernetes `CertificateSigningRequests`](https://cert-manager.io/docs/usage/kube-csr/) starting from version 1.4

## Deploy Custom CA controller in the Kubernetes cluster

1. Deploy cert-manager according to the [installation doc](https://cert-manager.io/docs/installation/).
   {{< warning >}}
   Note: Make sure to enable feature gate: `--feature-gates=ExperimentalCertificateSigningRequestControllers=true`
   {{< /warning >}}

1. Create three self signed cluster issuers `istio-system`, `foo` and `bar` for cert-manager.
   Note: Namespace issuers and other types of issuers can also be used.

## Export root certificate for cluster issuer

    {{< text bash >}}
    $ export istioca=$(kubectl get clusterissuers istio-system -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' |base64 -d)

    $ export fooca=$(kubectl get clusterissuers foo -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' |base64 -d)

    $ export barca=$(kubectl get clusterissuers bar -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' |base64 -d)
    {{< /text >}}

## Deploy Istio with default cert-signer info

1. Deploy Istio on the cluster using `istioctl` with the following configuration. The `ISTIO_META_CERT_SIGNER` is the default cert-signer for workloads.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_META_CERT_SIGNER: istio-system
        caCertificates:
        - pem: |
          $istioca
          certSigners:
          - clusterissuers.cert-manager.io/istio-system
        - pem: |
          $fooca
          certSigners:
          - clusterissuers.cert-manager.io/foo
        - pem: |
          $barca
          certSigners:
          - clusterissuers.cert-manager.io/bar
      components:
        pilot:
          k8s:
            env:
            - name: CERT_SIGNER_DOMAIN
              value: clusterissuers.cert-manager.io
            - name: EXTERNAL_CA
              value: ISTIOD_RA_KUBERNETES_API
            - name: PILOT_CERT_PROVIDER
              value: k8s.io/clusterissuers.cert-manager.io/istio-system
            overlays:
              - kind: ClusterRole
                name: istiod-clusterrole-istio-system
                patches:
                  - path: rules[-1]
                    value: |
                      apiGroups:
                      - certificates.k8s.io
                      resourceNames:
                      - clusterissuers.cert-manager.io/foo
                      - clusterissuers.cert-manager.io/bar
                      - clusterissuers.cert-manager.io/istio-system
                      resources:
                      - signers
                      verbs:
                      - approve
    EOF
    $ istioctl install -f ./istio.yaml
    {{< /text >}}

1. Deploy the `proxyconfig-bar.yaml` in the `bar` namespace to define cert-signer for workloads under `bar` namespace.

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-bar.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: barpc
      namespace: bar
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: bar
    EOF
    $ kubectl apply  -f ./proxyconfig-bar.yaml
    {{< /text >}}

1. Deploy the `proxyconfig-foo.yaml` in the foo namespace to define cert-signer for workloads under `foo` namespace.

    {{< text bash >}}
    $ cat <<EOF > ./proxyconfig-bar.yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ProxyConfig
    metadata:
      name: foopc
      namespace: foo
    spec:
      environmentVariables:
        ISTIO_META_CERT_SIGNER: foo
    EOF
    $ kubectl apply  -f ./proxyconfig-foo.yaml
    {{< /text >}}

1. Deploy the `httpbin` and `sleep` sample application in the `foo` and `bar` namespaces.

    {{< text bash >}}
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl label ns bar istio-injection=enabled
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n foo
    $ kubectl apply -f samples/sleep/sleep.yaml -n foo
    $ kubectl apply -f samples/httpbin/httpbin.yaml -n bar
    $ kubectl apply -f samples/sleep/sleep.yaml -n bar
    {{< /text >}}

## Verify the network connectivity between `httpbin` and `sleep` within the same namespace

When the workloads are deployed, above, they send CSR Requests with related signer info. Istiod forwards the CSR request to the custom CA for signing. The custom CA will use the correct cluster issuer or issuer to sign the cert back. Workloads under `foo` namespace will use  `foo` cluster issuers while workloads under `bar` namespace will use the `bar` cluster issuers. To verify that they have indeed been signed by correct cluster issuers, We can verify workloads under the same namespace can communicate will while workloads under the different namespace should not work.

1. Check network connectivity between service `sleep` and `httpbin` under `foo` namespace.

    {{< text bash >}}
    $ export SLEEP_POD_FOO=$(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec -it $SLEEP_POD_FOO -n foo -c sleep curl http://httpbin.foo:8000/html
    <!DOCTYPE html>
    <html>
      <head>
      </head>
      <body>
          <h1>Herman Melville - Moby-Dick</h1>

          <div>
            <p>
              Availing himself of the mild...
            </p>
          </div>
      </body>
     {{< /text >}}

1. Check network connectivity between service `sleep`  under `foo` namespace and `httpbin` under `bar` namespace.

    {{< text bash >}}
    $ export SLEEP_POD_FOO=$(kubectl get pod -n foo -l app=sleep -o jsonpath={    .items..metadata.name})
    $ kubectl exec -it $SLEEP_POD_FOO -n foo -c sleep curl http://httpbin.bar:8000/html
    upstream connect error or disconnect/reset before headers. reset reason: connection failure, transport failure reason: TLS error: 268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED
   {{< /text >}}

## Cleanup

* Remove the `istio-system`, `foo` and `bar` namespaces:

    {{< text bash >}}
    $ kubectl delete ns istio-system
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    {{< /text >}}

## Reasons to use this feature

* Custom CA Integration - By specifying a Signer name in the Kubernetes CSR Request, this feature allows Istio to integrate with custom Certificate Authorities using the Kubernetes CSR API interface. This does require the custom CA to implement a Kubernetes controller to watch the `CertificateSigningRequest` Resources and act on them.

* Better multi-tenancy - By specifying different cert-signer for different workload, certificate for different tenant's workloads can be signed by different CA.