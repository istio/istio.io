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

- You need to have an available IBM Cloud Private cluster.

## Deploy Istio via the Catalog module

- Log on to the **IBM Cloud Private** console.
- Click **Catalog** on right of the navigation bar.
- Click **Filter** on right of the search box and select the **ibm-charts** checkbox
- Click **Operations** on the left navigation pane.
- Click the **ibm-istio** in the right panel.

{{< image width="100%" ratio="50%"
    link="./catalog-istio.png"
    caption="IBM Cloud Private - Istio Catalog"
    >}}

- (Optional) You can change the Istio version from **CHART VERSION** dropdown box as you desire
- Click the **Configure** button.
- Input the Helm release name (e.g. istio-1.0.3) and select `istio-system` as the target namespace
- Agree the license
- (Optional) You can customize the installation parameters by click **All parameters** as you desire
- Click the **Install** button.

{{< image width="100%" ratio="50%"
    link="./install-istio.png"
    caption="IBM Cloud Private - Istio Installation"
    >}}

After installed, you can find the Istio from **Helm Releases** page with its release name.

{{< image width="100%" ratio="50%"
    link="./istio-release.png"
    caption="IBM Cloud Private - Istio Installation"
    >}}

## Upgrate or Rollback
- Log on to the **IBM Cloud Private** console.
- Click the menu button on left of the navigation bar.
- Click **Workloads** and select **Helm Releases**
- Find the istalled Istio with its release name.
- Click **Action** link and selete upgrate or rollback action.

## Uninstalling
- Log on to the **IBM Cloud Private** console.
- Click the menu button on left of the navigation bar.
- Click **Workloads** and select **Helm Releases**
- Find the istalled Istio with its release name.
- Click **Action** link and selete delete action.