---
title: Install Istio using the IBM Cloud
description: Instructions to install Istio using IBM Cloud Public or IBM Cloud Private.
weight: 70
keywords: [kubernetes,ibm,icp]
aliases:
    - /docs/setup/kubernetes/quick-start-gke-dm/
    - /docs/setup/kubernetes/quick-start-ibm/
---

Follow this path to install and configure an Istio mesh in IBM Cloud.

You can use the [managed Istio add-on for IBM Cloud Kubernetes Service](#managed-istio-add-on)
in IBM Cloud Public, use Helm to install Istio in [IBM Cloud Public](#ibm-cloud-public),
or install Istio in [IBM Cloud Private](#ibm-cloud-private).

## Managed Istio add-on

Istio on IBM Cloud Kubernetes Service provides a seamless installation of Istio, automatic updates and lifecycle management of Istio control plane components, and integration with platform logging and monitoring tools. With one click, you can get all Istio core components, additional tracing, monitoring, and visualization, and the Bookinfo sample app up and running. Istio on IBM Cloud Kubernetes Service is offered as a managed add-on, so IBM Cloud automatically keeps all your Istio components up to date.

To install the managed Istio add-on in IBM Cloud Public, see the [IBM Cloud Kubernetes Service documentation](https://cloud.ibm.com/docs/containers?topic=containers-istio).

## IBM Cloud Public

Follow these instructions to install and run the current release version of Istio in
[IBM Cloud Public](https://www.ibm.com/cloud/)
by using Helm and the IBM Cloud Kubernetes Service.

### Prerequisites - IBM Cloud Public

-  [Install the IBM Cloud CLI, the IBM Cloud Kubernetes Service plug-in, and the Kubernetes CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_install).
- Istio has been tested with these Kubernetes releases: 1.11, 1.12, 1.13. If you do not have a cluster available with a tested Kubernetes version, [create or update an existing cluster to a tested version](https://cloud.ibm.com/docs/containers?topic=containers-clusters).
-  Target the CLI to your cluster by running `ibmcloud ks cluster-config <cluster_name_or_ID> --export` and copying, pasting and running the command in the output.

{{< warning >}}
Make sure to use the `kubectl` CLI version that matches the Kubernetes version of your cluster.
{{< /warning >}}

### Initialize Helm and Tiller

1. Install the [Helm CLI](https://docs.helm.sh/using_helm/#installing-helm).

1. If a service account has not already been installed for Tiller, install one:

    {{< text bash >}}
    $ kubectl apply -f @install/kubernetes/helm/helm-service-account.yaml@
    {{< /text >}}

1. Initialize Helm and install Tiller:

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

### Deploy the Istio Helm charts

1. Install the `istio-init` chart to bootstrap all the Istio CRDs:

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
    {{< /text >}}

    Verify that all `56` Istio CRDs were committed to the Kubernetes api-server using the following command:

    {{< text bash >}}
    $ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
    56
    {{< /text >}}

1. Install the Helm chart to your cluster:

    {{< tip >}}
    The Istio `demo` profile (`install/kubernetes/helm/istio/values-istio-demo.yaml`) is specified in the following command to support the IBM Cloud Kubernetes Service free cluster, which only contains a single worker providing fewer resources than needed.
    If using a paid cluster of sufficient size, you can remove the `--values` parameter which will use the default Istio configuration values instead.
    {{< /tip >}}

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio --name istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-demo.yaml
    {{< /text >}}

1. Ensure the pods for the 9 Istio services and the pod for Prometheus are all fully deployed:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                      READY   STATUS      RESTARTS   AGE
    grafana-57586c685b-sjs2s                  1/1     Running     0          57m
    istio-citadel-754b8b478-ggf7s             1/1     Running     0          57m
    istio-egressgateway-748fb48647-npjgx      1/1     Running     0          57m
    istio-galley-c66f4f44c-nwb4m              1/1     Running     0          57m
    istio-ingressgateway-5d444855c8-9ksvn     1/1     Running     0          57m
    istio-init-crd-10-xcfqb                   0/1     Completed   0          19h
    istio-init-crd-11-nslct                   0/1     Completed   0          19h
    istio-init-crd-certmanager-10-2l8hs       0/1     Completed   0          19h
    istio-pilot-6f6fff9944-twzcp              2/2     Running     0          57m
    istio-policy-7b6bfcf94d-v6sr7             2/2     Running     2          57m
    istio-sidecar-injector-6657dd87b9-ccg87   1/1     Running     0          57m
    istio-telemetry-77d557f66-nsn87           2/2     Running     2          57m
    istio-tracing-6994cd89bb-gcssk            1/1     Running     0          57m
    kiali-69d6978b45-5zjzl                    1/1     Running     0          57m
    prometheus-5488844b5c-vwd9p               1/1     Running     0          57m
    servicegraph-86b55fc8b8-k87n9             1/1     Running     0          57m
    {{< /text >}}

### Upgrade

1. Upgrade the `istio-init` chart to keep all the [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) (CRDs) up to date. The `--install` parameter will run an install if the chart doesn't exist.

    {{< text bash >}}
    $ helm upgrade --install istio-init install/kubernetes/helm/istio-init --namespace istio-system
    {{< /text >}}

1. Check that all the CRD creation jobs completed successfully to verify that the Kubernetes API server received all the CRDs. The second column is the number of completions for the job.

    {{< text bash >}}
    $ kubectl get job --namespace istio-system | grep istio-init-crd
    {{< /text >}}

1. Upgrade the `istio` chart:

    {{< text bash >}}
    $ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
    {{< /text >}}

### Uninstall

1. Uninstall steps:

    {{< warning >}}
    Uninstalling this chart does not delete Istio's registered CRDs. Istio, by design, expects
    CRDs to leak into the Kubernetes environment. As CRDs contain all the runtime configuration
    data needed to configure Istio. Because of this, we consider it better for operators to
    explicitly delete the runtime configuration data rather than unexpectedly lose it.
    {{< /warning >}}

    {{< text bash >}}
    $ helm delete --purge istio
    $ helm delete --purge istio-init
    {{< /text >}}

1. If desired, run the following command to delete all CRDs:

    {{< warning >}}
    Deleting CRDs deletes any configuration changes that you have made to Istio.
    {{< /warning >}}

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
    {{< /text >}}

## IBM Cloud Private

Follow these instructions to install and run Istio in
[IBM Cloud Private](https://www.ibm.com/cloud/private)
using the `Catalog` module.

This guide installs the current release version of Istio.

### Prerequisites - IBM Cloud Private

- You need to have an available IBM Cloud Private cluster. Otherwise, you can follow [Installing IBM Cloud Private-CE](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/installing/install_containers_CE.html) to create an IBM Cloud Private cluster.

### Deploy Istio via the Catalog module

- Log in to the **IBM Cloud Private** console.
- Click `Catalog` on the right side of the navigation bar.
- Click `Filter` on the right side of the search box and select the `ibm-charts` check box.
- Click `Operations` in the left navigation pane.

{{< image link="./istio-catalog-1.png" caption="IBM Cloud Private - Istio Catalog" >}}

- Click `ibm-istio` in the right panel.

{{< image link="./istio-catalog-2.png" caption="IBM Cloud Private - Istio Catalog" >}}

- (Optional) Change the Istio version using the `CHART VERSION` drop-down.
- Click the `Configure` button.

{{< image link="./istio-installation-1.png" caption="IBM Cloud Private - Istio Installation" >}}

- Input the Helm release name (e.g. `istio-1.0.3`) and select `istio-system` as the target namespace.
- Agree to the license terms.
- (Optional) Customize the installation parameters by clicking `All parameters`.
- Click the `Install` button.

{{< image link="./istio-installation-2.png" caption="IBM Cloud Private - Istio Installation" >}}

After it is installed, you can find it by searching for its release name on the **Helm Releases** page.

{{< image link="./istio-release.png" caption="IBM Cloud Private - Istio Installation" >}}

### Upgrade or Rollback

- Log in to the **IBM Cloud Private** console.
- Click the menu button on the left side of the navigation bar.
- Click `Workloads` and select `Helm Releases`.
- Find the installed Istio using its release name.
- Click `Action` and select `Upgrade` or `Rollback`.

{{< image link="./istio-upgrade-1.png" caption="IBM Cloud Private - Istio Upgrade or Rollback" >}}

{{< image link="./istio-upgrade-2.png" caption="IBM Cloud Private - Istio Upgrade or Rollback" >}}

### Uninstalling

- Log in to the **IBM Cloud Private** console.
- Click the menu button on the left side of the navigation bar.
- Click `Workloads` and select `Helm Releases`.
- Find the installed Istio using its release name.
- Click `Action` and select `Delete`.

{{< image link="./istio-deletion.png" caption="IBM Cloud Private - Istio Uninstalling" >}}
