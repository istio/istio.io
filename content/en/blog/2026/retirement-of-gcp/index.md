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
We have yet to decide the exact date, but we will make a follow-up post with the exact date by the end of October 2026.

## Helm Charts

Historically, Istio published Helm charts to `https://istio-release.storage.googleapis.com/charts` as well as `gcr.io/istio-release/charts` as OCI artifacts.
We will remove Helm charts from the above locations in December 2026.
All Helm charts are currently available at `https://blob.istio.io/istio-release/charts` and we will continue to publish them there for the foreseeable future.
All OCI Helm charts are currently available at `ghcr.io/istio/release/charts` and we will continue to publish them there for the foreseeable future.
We expect that 1.30.4+ and 1.31.0+ will **not** have Helm charts published to `gcr.io/istio-release/charts` or `https://istio-release.storage.googleapis.com/charts`.
More information will be available in the release notes.

## Signing Keys

As a result of our migration, we will switch our public/private key pairs.
We will still host the old public key at `https://istio.io/misc/istio-key.pub` for the foreseeable future.
However, newer images will be signed with a new key, which will have the corresponding public key available at `https://istio.io/misc/istio-key-v2.pub`.

We expect the following signing keys to be used for each release:


| Version | Signing Key |
|---------|-------------|
| 1.18.x - 1.29.x | [istio-key.pub](https://istio.io/misc/istio-key.pub) |
| 1.30.1 - 1.30.3 | [istio-key.pub](https://istio.io/misc/istio-key.pub) |
| 1.31.0 | [istio-key.pub](https://istio.io/misc/istio-key.pub) |
| 1.30.4+ | [istio-key-v2.pub](https://istio.io/misc/istio-key-v2.pub) |
| 1.31.1+  | [istio-key-v2.pub](https://istio.io/misc/istio-key-v2.pub) |

## An Apology to our 1.30 Users

Users who wish to use Istio 1.30 into 2027 will have to migrate away from `gcr.io/istio-release` and `registry.istio.io/release` despite the fact that Istio 1.30 is supported until ~February 2027.
We deeply apologize for the inconvenience this will cause to our users.

## What You Need to Do

If you are using `registry.istio.io/release` or `gcr.io/istio-release`, you should migrate to `docker.io/istio` or a pull-through cache as soon as possible.
If you install Istio using our non-OCI Helm charts at `https://istio-release.storage.googleapis.com/charts`, you should migrate to `https://blob.istio.io/istio-release/charts` as soon as possible.
If you install Istio using OCI Helm charts at `gcr.io/istio-release/charts`, you should migrate to `ghcr.io/istio/release/charts` the next time you upgrade Istio.
If you verify the signature of Istio images, keep an eye out for which signing key is used for your Istio version and update your public key accordingly.
This information will be available in the release notes for each Istio version from now on.
