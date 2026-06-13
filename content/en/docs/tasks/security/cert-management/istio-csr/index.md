---
title: External Certificates using cert-manager
description: Shows how to use a Custom Certificate Authority via cert-manager to provision Istio workload certificates.
weight: 110
keywords: [security,certificates]
aliases:
    - /docs/tasks/security/istio-csr/
owner: istio/wg-security-maintainers
test: yes
---

This task shows how to provision Control Plane and Workload Certificates with an
external Certificate Authority using [cert-manager](https://cert-manager.io).
[cert-manager](https://cert-manager.io) is a x509 certificate operator for
Kubernetes that supports a number of
[Issuers](https://cert-manager.io/docs/configuration/), representing Certificate
Authorities that can sign certificates.

The [istio-csr](https://github.com/cert-manager/istio-csr) project installs an
agent that is responsible for verifying incoming certificate signing requests
from Istio mesh workloads, and signs them through cert-manager via a configured
Issuer.

{{< warning >}}
It is currently only recommended to use istio-csr for newly created Istio
clusters, until Certificate Authority rotation is supported.
{{< /warning >}}

## Installing cert-manager and istio-csr

{{< tip >}}
In this example we will install and use a self signed Certificate Authority
cert-manager Issuer, however you may want to make use of another Issuer type
such as [Venafi](https://cert-manager.io/docs/configuration/venafi/),
[Vault](https://cert-manager.io/docs/configuration/vault/), or an [External
Issuer](https://cert-manager.io/docs/configuration/external/).
{{< /tip >}}

1.  Install cert-manager using your [preferred
    method](https://cert-manager.io/docs/installation/kubernetes/), such as
    through helm:

    {{< text bash >}}
    $ kubectl create ns cert-manager
    $ helm repo add jetstack https://charts.jetstack.io
    $ helm repo update
    $ helm install \
     cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --set installCRDs=true
    {{< /text >}}

    Verify cert-manager is running:

    {{< text bash >}}
    $ kubectl get pods -n cert-manager
    NAME                                       READY   STATUS    RESTARTS   AGE
    cert-manager-756bb56c5-8csd8               1/1     Running   0          60s
    cert-manager-cainjector-86bc6dc648-d7bhd   1/1     Running   0          60s
    cert-manager-webhook-66b555bb5-wwsgw       1/1     Running   0          60s
    {{< /text >}}

1.  Create a cert-manager Issuer in the `istio-system` namespace that will be
    used for signing all Istio certificates. This example will bootstrap a self
    signed CA Issuer type, however can be exchanged for any other private
    [Certificate Authority Issuer](https://cert-manager.io/docs/configuration/)
    type.

    {{< warning >}}
    Publicly trusted certificates are discouraged being used. The ACME
    Issuer type is not supported for signing Istio certificates.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl create ns istio-system
    $ kubectl apply -n istio-system -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: selfsigned
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: cert-manager-istio-ca
    spec:
      isCA: true
      duration: 2160h # 90d
      secretName: cert-manager-istio-ca
      commonName: cert-manager-istio-ca
      subject:
        organizations:
        - cert-manager
      issuerRef:
        name: selfsigned
        kind: Issuer
        group: cert-manager.io
    ---
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: cert-manager-istio-ca
    spec:
      ca:
        secretName: cert-manager-istio-ca
    EOF
    {{< /text >}}

    Ensure that the created Issuer in the `istio-system` namespace is ready.

    {{< text bash >}}
    $ kubectl get issuers -n istio-system
    NAME         READY   AGE
    istio-ca     True    17s
    {{< /text >}}

1.  Now install [istio-csr](https://github.com/cert-manager/istio-csr) which is
    configured to use the Issuer just created. If using another Issuer type, you
    may need to set the root CA of that configured Issuer when installing.

    {{< text bash >}}
    $ helm install -n cert-manager cert-manager-istio-csr jetstack/cert-manager-istio-csr \
    --set certificate.name=cert-manager-istio-ca # --set certificate.rootCA="Issuer root CA"
    {{< /text >}}

    Verify that istio-csr is installed, and the istiod serving Certificate is ready.

    {{< text bash >}}
    $ kubectl get pods -n cert-manager
    NAME                                       READY   STATUS    RESTARTS   AGE
    cert-manager-756bb56c5-8csd8               1/1     Running   0          5m3s
    cert-manager-cainjector-86bc6dc648-d7bhd   1/1     Running   0          5m3s
    cert-manager-istio-csr-696954b7c7-8d9gg    1/1     Running   0          54s
    cert-manager-webhook-66b555bb5-wwsgw       1/1     Running   0          5m3s
    {{< /text >}}

    {{< text bash >}}
    $ kc get certs -n istio-system
    NAME                    READY   SECRET                  AGE
    istiod                  True    istiod-tls              68s
    {{< /text >}}

## Deploy Istio

1.  Deploy Istio on the cluster using `istioctl` with the following
    configuration.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
    spec:
      profile: "demo"
      values:
        global:
          # Change certificate provider to cert-manager istio agent for istio agent
          caAddress: cert-manager-istio-csr.cert-manager.svc:443
      components:
        pilot:
          k8s:
            env:
              # Disable istiod CA Sever functionality
            - name: ENABLE_CA_SERVER
              value: "false"
            overlays:
            - apiVersion: apps/v1
              kind: Deployment
              name: istiod
              patches:

                # Mount istiod serving and webhook certificate from Secret mount
              - path: spec.template.spec.containers.[name:discovery].args[7]
                value: "--tlsCertFile=/etc/cert-manager/tls/tls.crt"
              - path: spec.template.spec.containers.[name:discovery].args[8]
                value: "--tlsKeyFile=/etc/cert-manager/tls/tls.key"
              - path: spec.template.spec.containers.[name:discovery].args[9]
                value: "--caCertFile=/etc/cert-manager/ca/root-cert.pem"

              - path: spec.template.spec.containers.[name:discovery].volumeMounts[6]
                value:
                  name: cert-manager
                  mountPath: "/etc/cert-manager/tls"
                  readOnly: true
              - path: spec.template.spec.containers.[name:discovery].volumeMounts[7]
                value:
                  name: ca-root-cert
                  mountPath: "/etc/cert-manager/ca"
                  readOnly: true

              - path: spec.template.spec.volumes[6]
                value:
                  name: cert-manager
                  secret:
                    secretName: istiod-tls
              - path: spec.template.spec.volumes[7]
                value:
                  name: ca-root-cert
                  configMap:
                    secretName: istiod-tls
                    defaultMode: 420
                    name: istio-ca-root-cert
    EOF
    $ istioctl install --set profile=demo -f ./istio.yaml
    {{< /text >}}

1. Deploy the `bookinfo` sample application in the bookinfo namespace.

    {{< text bash >}}
    $ kubectl create ns bookinfo
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml) -n bookinfo
    {{< /text >}}

## Verify that Custom CA certificates installed are correct

When the workloads are deployed, above, they send CSR Requests to istio-csr
which verifies the request, and creates a
[`CertificateRequest`](https://cert-manager.io/docs/concepts/certificaterequest/)
resource, configured to be signed by the Issuer previously defined. After
cert-manager has signed this certificate, it is returned back to the workload.
To verify that they have indeed been signed by the configured Issuer CA, you
need to first extract the signed certificates.

1.  Dump all pods running in the namespace.

    {{< text bash >}}
    $ kubectl get pods -n bookinfo
    {{< /text >}}

   Pick any of the running pods for the next step.

1.  Get the certificate chain and CA root certificate used by the Istio proxies
    for mTLS.

    {{< text bash >}}
    $ istioctl pc secret -n bookinfo <pod-name> -o json > proxy_secret
    {{< /text >}}

    The `proxy_secret` json file contains the CA root certificate for mTLS in the
    `ROOTCA` object. Note that this certificate is base64 encoded.

1.  Compare the CA root certificate obtained in the step above with the root CA
    of your configured Issuer. In the example above, this can be found in the
    Secret `cert-manager-istio-ca` in the `istio-system` namespace. These two
    should be the same.

1.  (Optional) Follow the rest of the steps in the [bookinfo
    example](/docs/examples/bookinfo/) to ensure that communication between
    services is working as expected.

### Cleanup

1. Remove the `bookinfo` namespace, and uninstall Istio:

    {{< text bash >}}
    $ kubectl delete ns bookinfo
    $ istioctl x uninstall --purge
    {{< /text >}}

1. Uninstall istio-csr and cert-manager

    {{< text bash >}}
    $ helm uninstall -n cert-manager cert-manager-istio-csr
    $ helm uninstall -n cert-manager cert-manager
    {{< /text >}}

## Reasons to use this feature

* Custom CA Integration - Any Issuer type supported by cert-manager, core to
the project or externally developed by the community, can be used to integrate
with Istio.

* Added Security - Most Issuers supported by cert-manager sign certificates
remotetly, meaning no CA key material is stored in the cluster.
