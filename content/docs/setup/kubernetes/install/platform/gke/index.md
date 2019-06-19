---
title: Install Istio on the Google Kubernetes Engine
linktitle: Google Kubernetes Engine
description: Instructions to install Istio using the Google Kubernetes Engine (GKE).
weight: 65
keywords: [kubernetes,gke,google]
aliases:
    - /docs/setup/kubernetes/quick-start-gke-dm/
    - /docs/setup/kubernetes/quick-start/
---

Follow this flow to install and configure an Istio mesh Istio in the
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) (GKE).

## Prerequisites

- This sample requires a valid Google Cloud Platform project with billing
  enabled. If you are not an existing GCP user, you may be able to enroll for a
  $300 US [Free Trial](https://cloud.google.com/free/) credit.

- Ensure that the [Google Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com/)
  is enabled for your project (also found by navigating to "APIs &amp;
  Services" -> "Dashboard" in the navigation bar). If you do not see "API
  enabled", then you may enable the API by clicking the "Enable this API"
  button.

- You must install and configure the [`gcloud` command line tool](https://cloud.google.com/sdk/docs/)
  and include the `kubectl` component (`gcloud components install kubectl`).
  If you don't want to install the `gcloud` client on your own machine, you can
  use `gcloud` via [Google Cloud Shell](https://cloud.google.com/shell/docs/)
  to perform the same tasks.

- {{< warning_icon >}} You must set your default compute service account to include:

    - `roles/container.admin`  (Kubernetes Engine Admin)
    - `Editor`  (on by default)

To set this up, navigate to the **IAM** section of the [Cloud Console](https://console.cloud.google.com/iam-admin/iam/project) as shown below and find your default GCE/GKE service account in the following form: `projectNumber-compute@developer.gserviceaccount.com`: by default it should just have the **Editor** role. Then in the **Roles** drop-down list for that account, find the **Kubernetes Engine** group and select the role **Kubernetes Engine Admin**. The **Roles** listing for your account will change to **Multiple**.

{{< image link="./dm_gcp_iam.png" caption="GKE-IAM Service" >}}

Then add the `Kubernetes Engine Admin` role:

{{< image width="70%" link="./dm_gcp_iam_role.png" caption="GKE-IAM Role" >}}

## Setup using Istio on GKE

Refer to [Installing Istio on GKE](https://cloud.google.com/kubernetes-engine/docs/tutorials/installing-istio) for instructions on creating a cluster with Istio installed.

You can now try out one of the Istio examples like [Bookinfo](/docs/examples/bookinfo/).
