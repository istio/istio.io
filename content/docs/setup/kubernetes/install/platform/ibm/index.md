---
title: Install Istio using the IBM Cloud
linktitle: IBM Cloud
description: Instructions to install Istio using IBM Cloud Public or IBM Cloud Private.
weight: 70
keywords: [kubernetes,ibm,icp]
aliases:
    - /docs/setup/kubernetes/quick-start-ibm/
---

Follow this flow to install and configure an Istio mesh in IBM Cloud.

You can use the [managed Istio add-on for IBM Cloud Kubernetes Service](#managed-istio-add-on)
in IBM Cloud Public, [install Istio manually](#manual-istio-install) in IBM Cloud Public,
or install Istio in [IBM Cloud Private](#ibm-cloud-private).

## IBM Cloud Public

### Managed Istio add-on

[Istio on IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-istio) provides a seamless installation of Istio, automatic updates and lifecycle management of Istio control plane components, and integration with platform logging and monitoring tools. With one click, you can get all Istio core components, additional tracing, monitoring, and visualization, and the Bookinfo sample app up and running. Istio on IBM Cloud Kubernetes Service is offered as a managed add-on, so IBM Cloud automatically keeps all your Istio components up to date.

To install the managed Istio add-on in IBM Cloud Public, you can use the UI or the CLI.

**To use the UI**:

1. In your [cluster dashboard](https://cloud.ibm.com/kubernetes/clusters), click the name of a cluster.

1. Click the **Add-ons** tab.

1. On the Istio card, click **Install**. The Istio check box is already selected. To also install the Istio extras and BookInfo sample app, select the Istio Extras and the Istio Sample check boxes.

    {{< image link="./add-on-install.png" caption="Enable managed Istio add-ons in the IBM Cloud console" >}}

1. Click Install. On the Istio card, verify that the add-ons you enabled are listed.

**To use the CLI**:

1. Install the `istio`, `istio-extras`, and `istio-sample-bookinfo` add-ons.

    {{< text bash >}}
    $ ibmcloud ks cluster-addon-enable istio --cluster <cluster_name_or_ID>
    {{< /text >}}

    {{< text bash >}}
    $ ibmcloud ks cluster-addon-enable istio-extras --cluster <cluster_name_or_ID>
    {{< /text >}}

    {{< text bash >}}
    $ ibmcloud ks cluster-addon-enable istio-sample-bookinfo --cluster <cluster_name_or_ID>
    {{< /text >}}

1. Verify that the Istio services are deployed and their corresponding pods have a `STATUS` of `Running`.

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

1. Verify that the BookInfo microservices are deployed and their corresponding pods have a `STATUS` of `Running`.

    {{< text bash >}}
    $ kubectl get svc -n default
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n default
    {{< /text >}}

### Manual Istio install

Follow [these instructions](/docs/setup/kubernetes/) to install and run the current release version of Istio in [IBM Cloud Public](https://www.ibm.com/cloud/) using the IBM Cloud Kubernetes Service (IKS).

To upgrade Istio in an existing IKS cluster, follow the [upgrade instructions](/docs/setup/kubernetes/upgrade) instead.

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
- Click `Repositories` drop-down on the right side of the search box.
- Select the `ibm-charts` check box.
- Input `istio` in the search box.

{{< image link="./istio-catalog-1.png" caption="IBM Cloud Private - Istio Catalog" >}}

- Click `ibm-istio` in the right panel.

{{< image link="./istio-catalog-2.png" caption="IBM Cloud Private - Istio Catalog" >}}

- (Optional) Change the Istio version using the `CHART VERSION` drop-down.
- Click the `Configure` button at the bottom right corner.

{{< image link="./istio-installation-1.png" caption="IBM Cloud Private - Istio Installation" >}}

- Input the Helm release name (e.g. `istio`).
- Select `istio-system` as the target namespace.
- Select `local-cluster` as target cluster.
- If you agree with the license terms, check the agree to license terms box.
- (Optional) Customize the installation parameters by clicking `All parameters`.
- Click the `Install` button.

{{< image link="./istio-installation-2.png" caption="IBM Cloud Private - Istio Installation" >}}

After Istio is installed, you can find it by searching for its release name on the **Helm Releases** page.

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
