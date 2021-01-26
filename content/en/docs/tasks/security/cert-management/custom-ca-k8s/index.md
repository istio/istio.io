---
title: Custom CA Integration using Kubernetes CSR [Experimental]
description: Shows how to use a Custom Certificate Authority (that integrates with the Kubernetes CSR API) to provision Istio workload certificates (experimental).
weight: 100
keywords: [security,certificate]
aliases:
    - /docs/tasks/security/custom-ca-k8s/
owner: istio/wg-security-maintainers
test: no
---

{{< boilerplate experimental >}}

This feature requires Kubernetes version >= 1.18.

This task shows how to provision Workload Certificates
using a custom certificate authority that integrates with the
[Kubernetes CSR API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/).
This feature leverages [Chiron](/blog/2019/dns-cert/), a lightweight component linked with Istiod that signs certificates using the Kubernetes CSR API.

This task is split into two parts. The first part demonstrates how to use the Kubernetes CA itself to sign workload certificates.
The second part demonstrates how to use a custom CA that integrates with the Kubernetes CSR API to sign your certificates.

## Part 1: Using Kubernetes CA

{{< warning >}}
Note that this example should only be used for basic evaluation. The use of the `kubernetes.io/legacy-unknown` signer is NOT recommended in production environments.
{{< /warning >}}

### Deploying Istio with Kubernetes CA

1. Deploy Istio on the cluster using `istioctl` with the following configuration.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
      apiVersion: install.istio.io/v1alpha1
      kind: IstioOperator
      spec:
        pilot:
          k8s:
            env:
            # Indicate to Istiod that we use an Custom Certificate Authority
            - name: EXTERNAL_CA
              value: ISTIOD_RA_KUBERNETES_API
            # Tells Istiod to use the Kubernetes legacy CA Signer
            - name: K8S_SIGNER
              value: kubernetes.io/legacy-unknown
      EOF
    $ istioctl install --set profile=demo -f ./istio.yaml
    {{< /text >}}

1. Deploy the `bookinfo` sample application in the bookinfo namespace.
    Ensure that the following commands are executed in the Istio root directory.

    {{< text bash >}}
    $ kubectl create ns bookinfo
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml) -n bookinfo
    {{< /text >}}

### Verify that the certificates installed are correct

When the workloads are deployed, above, they send CSR Requests to Istiod which forwards them to the Kubernetes CA for signing.
If all goes well, the signed certificates are sent back to the workloads where they are then installed.
To verify that they have been signed by the Kubernetes CA, you need to first extract the signed certificates.

1. Dump all pods running in the namespace.

    {{< text bash >}}
    $ kubectl get pods -n bookinfo
    {{< /text >}}

    Pick any one of the running pods for the next step.

1. Get the certificate chain and CA root certificate used by the Istio proxies for mTLS.

    {{< text bash >}}
    $ istioctl pc secret <pod-name> -o json > proxy_secret
    {{< /text >}}

    The proxy_secret json file contains the CA root certificate for mTLS in the `trustedCA` field. Note that this certificate is base64 encoded.

1. The certificate used by the Kubernetes CA (specifically the `kubernetes.io/legacy-unknown` signer) is loaded onto the secret associated with every service account in the bookinfo namespace.

    {{< text bash >}}
    $ kubectl get secrets -n bookinfo
    {{< /text >}}

    Pick a secret-name that is associated with any of the service-accounts. These have a "token" in their name.

    {{< text bash >}}
    $ kubectl get secrets -n bookinfo <secret-name> -o json
    {{< /text >}}

    The `ca.crt` field in the output contains the base64 encoded Kubernetes CA certificate.

1. Compare the `ca.cert` obtained in the previous step with the contents of the `TrustedCA` field in the step before. These two should be the same.

1. (Optional) Follow the rest of the steps in the [bookinfo example](/docs/examples/bookinfo/) to ensure that communication between services is working as expected.

### Cleanup Part 1

* Remove the `istio-system` and `bookinfo` namespaces:

    {{< text bash >}}
    $ kubectl delete ns istio-system
    $ kubectl delete ns bookinfo
    {{< /text >}}

## Part 2: Using Custom CA

This assumes that the custom CA implements a controller that has the necessary permissions to read and sign Kubernetes CSR Requests.
Refer to the [Kubernetes CSR documentation](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/) for more details. Note that the steps below are dependent on an external-source and may change.

### Deploy Custom CA controller in the Kubernetes cluster

1. For this example, we use an [open-source Certificate Authority implementation](https://github.com/cert-manager/signer-ca).
    This code builds a controller that reads the CSR resources on the Kubernetes cluster and creates certificates using local keys. Follow the instructions on the page to:
   1. Build the Certificate-Controller docker image
   1. Upload the image to a Docker Registry
   1. Generate the Kubernetes manifest to deploy it

1. Deploy the Kubernetes manifest generated in the previous step on your local cluster in the signer-ca-system namespace.

    {{< text bash >}}
    $ kubectl apply -f local-ca.yaml
    {{< /text >}}

   Ensure that all the services are running.

    {{< text bash >}}
    $ kubectl get services -n signer-ca-system
      NAME                                           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
      signer-ca-controller-manager-metrics-service   ClusterIP   10.8.9.25    none        8443/TCP   72s
    {{< /text >}}

1. Get the public key of the CA. This is encoded in the secret "signer-ca-*" in the signer-ca-system namespace.

    {{< text bash >}}
    $ kubectl get secrets signer-ca-5hff5h74hm -o json
    {{< /text >}}

   The `tls.crt` field contains the base64 encoded public key file. Record this for future use.

### Load the CA root certificate into a secret that istiod can access

1. Load the secret into the istiod namespace.

    {{< text bash >}}
    $ cat <<EOF > ./external-ca-secret.yaml
      apiVersion: v1
      kind: Secret
      metadata:
        name: external-ca-cert
        namespace: istio-system
      data:
      root-cert.pem: <tls.cert from the step above>
      EOF
    $ kubectl apply -f external-ca-secret.yaml
    {{< /text >}}

    This step is necessary for Istio to verify that the workload certificates have been signed by the correct certificate authority and to add the root-cert to the trust bundle for mTLS to work.

### Deploying Istio

1. Deploy Istio on the cluster using `istioctl` with the following configuration.

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      components:
        base:
          k8s:
            overlays:
              # Amend ClusterRole to add permission for istiod to approve certificate signing by custom signer
              - kind: ClusterRole
                name: istiod-istio-system
                patches:
                  - path: rules[-1]
                    value: |
                      apiGroups:
                      - certificates.k8s.io
                      resourceNames:
                      # Name of k8s external Signer in this example
                      - example.com/foo
                      resources:
                      - signers
                      verbs:
                      - approve
        pilot:
          k8s:
            env:
              # Indicate to Istiod that we use an external signer
              - name: EXTERNAL_CA
                value: ISTIOD_RA_KUBERNETES_API
              # Indicate to Istiod the external k8s Signer Name
              - name: K8S_SIGNER
                value: example.com/foo
            overlays:
            - kind: Deployment
              name: istiod
              patches:
                - path: spec.template.spec.containers[0].volumeMounts[-1]
                  value: |
                    # Mount external CA certificate into Istiod
                    name: external-ca-cert
                    mountPath: /etc/external-ca-cert
                    readOnly: true
                - path: spec.template.spec.volumes[-1]
                  value: |
                    name: external-ca-cert
                    secret:
                      secretName: external-ca-cert
                      optional: true
    EOF
    $ istioctl install --set profile=demo -f ./istio.yaml
    {{< /text >}}

1. Deploy the `bookinfo` sample application in the bookinfo namespace.

    {{< text bash >}}
    $ kubectl create ns bookinfo
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml) -n bookinfo
    {{< /text >}}

### Verify that Custom CA certificates installed are correct

When the workloads are deployed, above, they send CSR Requests to Istiod which forwards them to the Kubernetes CA for signing. If all goes well, the signed certificates are sent back to the workloads where they are then installed. To verify that they have indeed been signed by the Kubernetes CA, you need to first extract the signed certificates.

1. Dump all pods running in the namespace.

    {{< text bash >}}
    $ kubectl get pods -n bookinfo
    {{< /text >}}

   Pick any of the running pods for the next step.

1. Get the certificate chain and CA root certificate used by the Istio proxies for mTLS.

    {{< text bash >}}
    $ istioctl pc secret <pod-name> -o json > proxy_secret
    {{< /text >}}

   The `proxy_secret` json file contains the CA root certificate for mTLS in the `trustedCA` field. Note that this certificate is base64 encoded.

1. Compare the CA root certificate obtained in the step above with "root-cert.pem" value in external-ca-cert. These two should be the same.

1. (Optional) Follow the rest of the steps in the [bookinfo example](/docs/examples/bookinfo/) to ensure that communication between services is working as expected.

### Cleanup Part 2

* Remove the `istio-system` and `bookinfo` namespaces:

    {{< text bash >}}
    $ kubectl delete ns istio-system
    $ kubectl delete ns bookinfo
    {{< /text >}}

## Reasons to use this feature

* Added Security - Unlike `plugin-ca-cert` or the default `self-signed` option, enabling this feature means that the CA private keys need not be present in the Kubernetes cluster.

* Custom CA Integration - By specifying a Signer name in the Kubernetes CSR Request, this feature allows Istio to integrate with custom Certificate Authorities using the Kubernetes CSR API interface. This does require the custom CA to implement a Kubernetes controller to watch the `CertificateSigningRequest` and `Certificate` Resources and act on them.
