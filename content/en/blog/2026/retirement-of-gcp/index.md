---
title: "ACTION REQUIRED FOR GOOGLE CONTAINER REGISTRY USERS, scream tests, and our move to AWS"
description: What you can do with your Helm charts and signing keys to ensure you are not impacted by the migration to AWS.
publishdate: 2026-08-21
attribution: Steven Jin (Microsoft), Keith Mattix (Solo.io)
keywords: [Istio,Container Registry,Helm]
---

This year, Istio is migrating all of our infrastructure from Google Cloud Platform to Amazon Web Services due to changes in our funding model.
This post describes the transition of our container images, Helm charts, other release artifacts (RPMs, DEBs, source code, SPDX documents, `istioctl`, and licenses), signing keys, and **upcoming scream tests where we will disable access to all GCP-hosted artifacts**.

## Container Images

In a [previous blog post](../retirement-of-gcr.io-follow-up/), we announced that the `gcr.io/istio-release` and `registry.istio.io` container registries will be decommissioned in December 2026 and we would only publish Istio container images to Docker Hub.
Starting with Istio 1.31, we will only publish Istio container images to `docker.io/istio`.
Please see [the previous blog post](../retirement-of-gcr.io-follow-up/) for details on migrating away from `gcr.io/istio-release` and `registry.istio.io`.

## Helm Charts and Other Release Artifacts

Historically, Istio published Helm charts to `https://istio-release.storage.googleapis.com/charts` as well as `gcr.io/istio-release/charts` as OCI artifacts.
Similarly, we published other release artifacts (RPMs, DEBs, source code, SPDX documents, `istioctl`, and licenses) to `https://istio-release.storage.googleapis.com/releases`.
Helm charts and other release artifacts will be removed from the above locations in December 2026.
All Helm charts of all Istio versions are currently available at `https://blob.istio.io/istio-release/charts` and we will continue to publish them there for the foreseeable future.
All OCI Helm charts of all Istio versions are currently available at `ghcr.io/istio/release/charts` and we will continue to publish them there for the foreseeable future.
All other release artifacts of all Istio versions are currently available at `https://blob.istio.io/istio-release/releases` and we will continue to publish them there for the foreseeable future.
Istio 1.30 will be the last minor version with Helm charts, OCI Helm charts, and images published to `gcr.io/istio-release` and `https://istio-release.storage.googleapis.com/charts`.
Istio 1.31 will **not** have Helm charts, OCI Helm charts, nor images published to `gcr.io/istio-release/` or `https://istio-release.storage.googleapis.com/charts`.
More information will be available in the release notes.

## Signing Keys

As a result of our migration, we will switch our public/private key pairs.
We will still host the old public key at `https://istio.io/misc/istio-key.pub` for the foreseeable future.
However, newer images will be signed with a new key, which will have the corresponding public key available at `https://istio.io/misc/istio-key-v2.pub`.

We expect the following signing keys to be used for each release:

| Version | Signing Public Key |
|---------|-------------|
| 1.18.x - 1.30.x | `https://istio.io/misc/istio-key.pub` |
| 1.31.0 | `https://istio.io/misc/istio-key.pub` |
| 1.31.1+  | `https://istio.io/misc/istio-key-v2.pub` |

## Scream Tests and What You Need to Do

We will be conducting a series of "scream tests" where we will temporarily disable access to `gcr.io/istio-release`, `registry.istio.io/release`, and `https://blob.istio.io/istio-release/charts`.
The first scream test will be September 15th, 2026 from 3:00 PM to 4:00 PM UTC.
The second scream test will be October 13th, 2026 from 3:00 PM to 6:00 PM UTC.
The third scream test will be November 17th, 2026 from 3:00 PM to 9:00 PM UTC.
The fourth and last scream test will be from December 8th, 2026 3:00 PM UTC to December 9th, 2026 3:00 PM UTC.

If you are using `registry.istio.io/release` or `gcr.io/istio-release`, you should migrate to `docker.io/istio` or a pull-through cache as soon as possible.
If you install Istio using Helm charts from `https://istio-release.storage.googleapis.com/charts`, you should migrate to `https://blob.istio.io/istio-release/charts` as soon as possible.
If you install Istio using OCI Helm charts at `gcr.io/istio-release/charts`, you should migrate to `ghcr.io/istio/release/charts` as soon as possible.
If you verify the signature of Istio images, keep an eye out for which signing key is used for your Istio version and update your public key accordingly.
You should complete your migration as soon as possible to avoid any disruption in your Istio deployments.
