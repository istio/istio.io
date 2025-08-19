---
title: Handling Docker Hub rate limiting
description: How to ensure your clusters are not impacted by Docker Hub rate limiting.
publishdate: 2020-12-07
attribution: John Howard (Google)
keywords: [docker]
target_release: 1.8
---

Since November 20th, 2020, Docker Hub has introduced [rate limits](https://www.docker.com/increase-rate-limits) on image pulls.

Because Istio uses [Docker Hub](https://hub.docker.com/u/istio) as the default registry, usage on a large cluster may lead
to pods failing to startup due to exceeding rate limits. This can be especially problematic for Istio, as there is typically
the Istio sidecar image alongside most pods in the cluster.

## Mitigations

Istio allows you to specify a custom docker registry which you can use to make container images be fetched from your private registry. This can be configured by passing `--set hub=<some-custom-registry>` at installation time.

Istio provides official mirrors to [Google Container Registry](https://gcr.io/istio-release). This can be configured with `--set hub=gcr.io/istio-release`. This is available for Istio 1.5+.

Alternatively, you can copy the official Istio images to your own registry. This is especially useful if your cluster runs in an environment with a registry tailored for your use case (for example, on AWS you may want to mirror images to Amazon ECR) or you have air gapped security requirements where access to public registries is restricted. This can be done with the following script:

{{< text bash >}}
$ SOURCE_HUB=istio
$ DEST_HUB=my-registry # Replace this with the destination hub
$ IMAGES=( install-cni operator pilot proxyv2 ) # Images to mirror.
$ VERSIONS=( 1.7.5 1.8.0 ) # Versions to copy
$ VARIANTS=( "" "-distroless" ) # Variants to copy
$ for image in $IMAGES; do
$ for version in $VERSIONS; do
$ for variant in $VARIANTS; do
$   name=$image:$version$variant
$   docker pull $SOURCE_HUB/$name
$   docker tag $SOURCE_HUB/$name $DEST_HUB/$name
$   docker push $DEST_HUB/$name
$   docker rmi $SOURCE_HUB/$name
$   docker rmi $DEST_HUB/$name
$ done
$ done
$ done
{{< /text >}}
