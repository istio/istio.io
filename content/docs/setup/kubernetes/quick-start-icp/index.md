---
title: Quick Start with IBM Cloud Private
description: How to quickly setup Istio using IBM Cloud Private.
weight: 21
keywords: [kubernetes,icp]
---

Follow these instructions to install and run Istio in the
[IBM Cloud Private](https://www.ibm.com/cloud/private)
using the `Catalog` module.

This guide installs the current release version of Istio.

## Prerequisites

- You need to have an available IBM Cloud Private cluster. Otherwise, you can follow [Installing IBM Cloud Private-CE](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/installing/install_containers_CE.html) to create an IBM Cloud Private cluster.

## Deploy Istio via the Catalog module

- Log in to the **IBM Cloud Private** console.
- Click `Catalog` on the right side of the navigation bar.
- Click `Filter` on the right side of the search box and select the `ibm-charts` checking box.
- Click `Operations` in the left navigation pane.

{{< image width="100%" ratio="50%"
    link="./istio-catalog-1.png"
    caption="IBM Cloud Private - Istio Catalog"
    >}}

- Click `ibm-istio` in the right panel.

{{< image width="100%" ratio="50%"
    link="./istio-catalog-2.png"
    caption="IBM Cloud Private - Istio Catalog"
    >}}

- (Optional) Change the Istio version using `CHART VERSION` drop-down.
- Click the `Configure` button.

{{< image width="100%" ratio="50%"
    link="./istio-installation-1.png"
    caption="IBM Cloud Private - Istio Installation"
    >}}

- Input the Helm release name (e.g. istio-1.0.3) and select `istio-system` as the target namespace.
- Agree to the license terms.
- (Optional) Customize the installation parameters by clicking `All parameters`.
- Click the `Install` button.

{{< image width="100%" ratio="50%"
    link="./istio-installation-2.png"
    caption="IBM Cloud Private - Istio Installation"
    >}}

After it is installed, you can find it by searching for its release name on the **Helm Releases** page.

{{< image width="100%" ratio="40%"
    link="./istio-release.png"
    caption="IBM Cloud Private - Istio Installation"
    >}}

## Upgrade or Rollback

- Log in to the **IBM Cloud Private** console.
- Click the menu button on the left side of the navigation bar.
- Click `Workloads` and select `Helm Releases`.
- Find the installed Istio using its release name.
- Click `Action` link and select `upgrade` or `rollback`.

{{< image width="100%" ratio="50%"
    link="./istio-upgrade-1.png"
    caption="IBM Cloud Private - Istio Upgrade or Rollback"
    >}}

{{< image width="100%" ratio="50%"
    link="./istio-upgrade-2.png"
    caption="IBM Cloud Private - Istio Upgrade or Rollback"
    >}}

## Uninstalling

- Log in to the **IBM Cloud Private** console.
- Click the menu button on the left side of the navigation bar.
- Click `Workloads` and select `Helm Releases`.
- Find the installed Istio using its release name.
- Click `Action` link and select `delete`.

{{< image width="100%" ratio="50%"
    link="./istio-deletion.png"
    caption="IBM Cloud Private - Istio Uninstalling"
    >}}