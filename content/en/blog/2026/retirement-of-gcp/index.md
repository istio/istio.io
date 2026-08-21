---
title: "An update on our move to AWS"
description: What you can do with your Helm charts and signing keys to ensure you are not impacted by the migration to AWS.
publishdate: 2026-08-21
attribution: Steven Jin (Microsoft), Keith Mattix (Solo.io)
keywords: [Istio,Container Registry,Helm]
---

In a [previous blog post](../retirement-of-gcr.io-follow-up/), we announced that Istio will retire the `gcr.io/istio-release` container registry in December 2026 and switch to `registry.istio.io/release` as the replacement registry for Istio images.
This post describes the transition of our Helm charts and signing keys.

As a reminder, **we will retire `registry.istio.io/release` and `gcr.io/istio-release` in December 2026**.
We have yet to decide the exact date, but we will make a follow-up post with the exact date by the end of November 2026.

## Helm Charts

Historically, Istio published Helm charts to `https://istio-release.storage.googleapis.com/charts` as well as `gcr.io/istio-release/charts` as OCI artifacts.
We will remove Helm charts from the above locations in December 2026.
All Helm charts of all Istio versions are currently available at `https://blob.istio.io/istio-release/charts` and we will continue to publish them there for the foreseeable future.
All OCI Helm charts of all Istio versions are currently available at `ghcr.io/istio/release/charts` and we will continue to publish them there for the foreseeable future.
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

If you are using `registry.istio.io/release` or `gcr.io/istio-release`, you should migrate to `docker.io/istio` or a pull-through cache as soon as possible.
If you install Istio using our non-OCI Helm charts at `https://istio-release.storage.googleapis.com/charts`, you should migrate to `https://blob.istio.io/istio-release/charts` as soon as possible.
If you install Istio using OCI Helm charts at `gcr.io/istio-release/charts`, you should migrate to `ghcr.io/istio/release/charts` the next time you upgrade Istio.
If you verify the signature of Istio images, keep an eye out for which signing key is used for your Istio version and update your public key accordingly.
This information will be available in the release notes for each Istio version from now on.
You should complete your migration before December 2026 to avoid any disruption in your Istio deployments.

To minimize disruption to our users, we will conduct a series of "scream tests" in December, where we will temporarily disable access to `gcr.io/istio-release`.
We will have more details on the exact dates and times of these tests in a follow-up post in November 2026.
