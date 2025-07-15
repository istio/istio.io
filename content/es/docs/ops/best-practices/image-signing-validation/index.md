---
title: Image Signing and Validation
description: Describes how to use image signatures to verify the provenance of Istio images.
weight: 35
aliases: []
keywords: [install,signing]
owner: istio/wg-environments-maintainers
test: n/a
---

This page describes how to use [Cosign](https://github.com/sigstore/cosign) to
validate the provenance of Istio image artifacts.

Cosign is a tool developed as part of the
[sigstore](https://www.sigstore.dev) project, which
simplifies signing and validation of signed Open Container Initiative (OCI) artifacts,
such as container images.

Starting with Istio 1.12, we sign all officially published container images as part of our release
process. End users can then verify these images using
the process described below.

This process is suitable for either manual execution or integration with build
or deployment pipelines for automated verification of artifacts.

## Prerequisites

Before you begin, please do the following:

1. Download the latest
   [Cosign](https://github.com/sigstore/cosign/releases/latest) build for your
   architecture, as well as its signature.
1. Validate the `cosign` binary signature:

   {{< text bash >}}
$ openssl dgst -sha256 \
    -verify <(curl -ssL https://raw.githubusercontent.com/sigstore/cosign/main/release/release-cosign.pub) \
    -signature <(cat /path/to/cosign.sig | base64 -d) \
    /path/to/cosign-binary
    {{< /text >}}

1. Make the binary executable (`chmod +x`) and move to a location on the `PATH`

## Validating Image

To validate a container image, do the following:

{{< text bash >}}
$ ./cosign-binary verify --key "https://istio.io/misc/istio-key.pub" {{< istio_docker_image "pilot" >}}
{{< /text >}}

This process will work for any released image or release candidate built with the Istio build infrastructure.

An example with output:

{{< text bash >}}
$ cosign verify --key "https://istio.io/misc/istio-key.pub" gcr.io/istio-release/pilot:1.12.0


Verification for gcr.io/istio-release/pilot:1.12.0 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
  - Any certificates were verified against the Fulcio roots.

[{"critical":{"identity":{"docker-reference":"gcr.io/istio-release/pilot"},"image":{"docker-manifest-digest":"sha256:c37fd83f6435ca0966d653dc6ac42c9fe5ac11d0d5d719dfe97de84acbf7a32d"},"type":"cosign container image signature"},"optional":null}]
{{< /text >}}
