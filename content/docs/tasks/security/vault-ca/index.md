---
title: Istio Vault CA integration
description: Tutorial on how to plug in a Vault CA for issuing certificates in Istio.
weight: 10
keywords: [security,certificate]
---

This tutorial walks you through an example to plug in a Vault CA for issuing
certificates in Istio.

## Before you begin

* Create a new Kubernetes cluster to run the example in this tutorial.

* On GKE, you may set the value of the `CLUSTER`, `ZONE`, and `PROJECT`
environmental variables based on your GKE cluster and run the following
`gcloud` command to fetch the credentials for your cluster.

    {{< text bash >}}
    $ export CLUSTER=YOUR-CLUSTER-NAME
    $ export ZONE=YOUR-CLUSTER-ZONE
    $ export PROJECT=YOUR-GKE-PROJECT-NAME
    $ gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project $PROJECT
    {{< /text >}}

## Install Istio with SDS enabled

1.  Use `git clone` to download the latest Istio source code.

    {{< text bash >}}
    $ mkdir -p ~/go/src/istio.io
    $ cd ~/go/src/istio.io
    $ git clone https://github.com/istio/istio.git
    $ cd istio
    {{< /text >}}

1.  Install Istio with SDS enabled and Node Agent sending certificate signing
requests to a testing Vault CA (this example uses the latest release on
2019-01-15, you may also use other releases):

    {{< text bash >}}
    $ export HUB=gcr.io/istio-release
    $ export TAG=release-1.1-20190115-09-15
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    $ helm dep update --skip-refresh install/kubernetes/helm/istio
    $ ./install/updateVersion.sh -a ${HUB},${TAG} >/dev/null 2>&1
    $ cat install/kubernetes/namespace.yaml > istio-auth.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-* >> istio-auth.yaml
    $ helm template --set global.tag=${TAG} \
        --name=istio \
        --namespace=istio-system \
        --set global.hub=${HUB} \
        --set global.mtls.enabled=true \
        --set global.controlPlaneSecurityEnabled=true \
        --set global.proxy.excludeIPRanges="35.233.249.249/32" \
        --values install/kubernetes/helm/istio/values-istio-example-sds-vault.yaml \
        install/kubernetes/helm/istio >> istio-auth.yaml
    $ kubectl create -f istio-auth.yaml
    {{< /text >}}

The testing Vault server used in this tutorial has the IP
address `35.233.249.249`. The configuration
`global.proxy.excludeIPRanges="35.233.249.249/32"` whitelists the IP address of
the testing Vault server, so that Envoy will not intercept the traffic from
Node Agent to Vault.

The yaml file `install/kubernetes/helm/istio/values-istio-example-sds-vault.yaml`
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

## Deploy a testing workload

This section deploys a testing workload `httpbin`. When the sidecar of the
testing workload requests for a certificate through SDS, Node Agent will send
certificate signing requests to Vault.

1.  Download the Istio install package
(the example here uses [this Istio release package](https://storage.googleapis.com/istio-prerelease/daily-build/release-1.1-20190115-09-15/istio-release-1.1-20190115-09-15-linux.tar.gz))
and decompress it:

    {{< text bash >}}
    $ tar xfz istio-release-1.1-20190115-09-15-linux.tar.gz
    $ cd istio-release-1.1-20190115-09-15
    {{< /text >}}

1.  Generate the deployment for an example `httpbin` backend:

    {{< text bash >}}
    $ bin/istioctl kube-inject -f samples/httpbin/httpbin.yaml > httpbin-injected.yaml
    {{< /text >}}

1.  Deploy the example backend:

    {{< text bash >}}
    $ kubectl apply -f httpbin-injected.yaml
    {{< /text >}}

1.  List the pods of Node Agent:

    {{< text bash >}}
    $ kubectl get pod -n istio-system -l app=nodeagent -o jsonpath={.items..metadata.name}
    {{< /text >}}

1.  View the logs of each Node Agent. The Node Agent residing on
the same node as the testing workload will contain Vault related logs.

    {{< text bash >}}
    $ kubectl logs -n istio-system THE-POD-NAME-FROM-PREVIOUS-COMMAND
    {{< /text >}}

1.  Because in this example, Vault is not configured to accept the k8s JWT
service account from the `httpbin` workload, you should see that Vault rejects the
signing requests with the following logs.

    {{< text plain >}}
    2019-01-16T19:42:19.274291Z     info    SDS gRPC server start, listen "/var/run/sds/uds_path"
    2019-01-16T19:42:22.015814Z     error   failed to login Vault: Error making API request.
    URL: PUT https://35.233.249.249:8200/v1/auth/kubernetes/login
    Code: 500. Errors:
    * service account name not authorized
    2019-01-16T19:42:22.016112Z     error   Failed to sign cert for "default": failed to login Vault at https://35.233.249.249:8200: Error making API request.
    {{< /text >}}

1.  With the above logs generated, you have completed the tutorial in this
article, which plugs in an external Vault CA and routes the certificate signing
requests to Vault.

## Cleanup

After completing this tutorial, you may delete the testing cluster created
at the beginning of this tutorial.

