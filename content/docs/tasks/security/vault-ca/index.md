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
As the time of writing, the latest Istio code is on the release-1.1 branch
with a commit id of `4b6189fb170ce30c885fd83d8f8d20807d42929c`.
To make the instructions reproducible, sync the Istio code to the above commit.

    {{< text bash >}}
    $ mkdir -p ~/go/src/istio.io
    $ cd ~/go/src/istio.io
    $ git clone https://github.com/istio/istio.git
    $ cd istio
    $ git checkout release-1.1
    $ git reset --hard 4b6189fb170ce30c885fd83d8f8d20807d42929c
    {{< /text >}}

1.  Edit the `Makefile` under the root of the Istio repository to enable SDS.
Change the line 695 to 697 in the `Makefile` to the content in the revised block.

The line 695 to 697 in the original `Makefile` is as follows.

    {{< text bash >}}
    ${EXTRA_HELM_SETTINGS} \
    --values install/kubernetes/helm/istio/values.yaml \
    install/kubernetes/helm/istio >> install/kubernetes/istio-auth.yaml
    {{< /text >}}

After the revision, the above block becomes as follows.

    {{< text bash >}}
    ${EXTRA_HELM_SETTINGS} \
    --set global.proxy.excludeIPRanges="35.233.249.249/32" \
    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml \
    install/kubernetes/helm/istio >> install/kubernetes/istio-auth.yaml
    {{< /text >}}

The yaml file `install/kubernetes/helm/istio/values-istio-sds-auth.yaml`
contains the configuration that enables SDS (secret discovery service) in Istio.
The testing Vault server used in this tutorial has the IP
address `35.233.249.249`. The configuration
`global.proxy.excludeIPRanges="35.233.249.249/32"` whitelists the IP address of
the testing Vault server, so that Envoy will not intercept the traffic from
Node Agent to Vault.

1.  Generate `istio-auth.yaml`:

    {{< text bash >}}
    $ HUB=gcr.io/istio-release TAG=release-1.1-20190115-09-15 make generate_yaml
    {{< /text >}}

1.  Deploy `istio-auth.yaml`:

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    $ kubectl apply -f install/kubernetes/istio-auth.yaml
    {{< /text >}}

## Deploy a Node Agent that signs certificates at Vault

This section deploys a testing workload `httpbin` and a Node Agent that sends
certificate signing requests to Vault. The sidecar of the testing workload
requests for a certificate through SDS.

1.  Delete the daemon set of the original Node Agent before deploying
the new Node Agent that signs certificates at Vault:

    {{< text bash >}}
    $ kubectl delete daemonset istio-nodeagent -n istio-system
    {{< /text >}}

1.  Download the
[Istio install package](https://storage.googleapis.com/istio-prerelease/daily-build/release-1.1-20190115-09-15/istio-release-1.1-20190115-09-15-linux.tar.gz)
and decompress it:

    {{< text bash >}}
    $ tar xfz istio-release-1.1-20190115-09-15-linux.tar.gz
    $ cd istio-release-1.1-20190115-09-15
    {{< /text >}}

1.  Generate the deployment for an example httpbin backend:

    {{< text bash >}}
    $ bin/istioctl kube-inject -f samples/httpbin/httpbin.yaml > httpbin-injected.yaml
    {{< /text >}}

1.  Based on [the example httpbin deployment]({{< github_file >}}/security/samples/vault/httpbin/httpbin-injected-edited.yaml),
edit `httpbin-injected.yaml` to add to the deployment a Node Agent
that goes to the testing Vault CA to sign certificates. In addition, add the
volume mount in the example deployment on `/etc/certs` to `httpbin-injected.yaml`.
If you prefer, you may also directly use the given example deployment file.
The Vault CA related configuration is set as environmental variables in
the deployment file. The testing Vault server is at `https://35.233.249.249:8200`.

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

1.  After the editing, run the deployment:

    {{< text bash >}}
    $ kubectl apply -f httpbin-injected.yaml
    {{< /text >}}
    
1.  Wait a moment for the deployment to be ready before viewing the logs of Node Agent:

    {{< text bash >}}
    $ kubectl logs $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c citadel-agent
    {{< /text >}}

1.  Because in this example, Vault is not configured to accept the k8s JWT
service account from the httpbin workload, you should see that Vault rejects the
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


