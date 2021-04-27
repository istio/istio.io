---
title: 处理 Docker Hub 速率限制
description: 如何确保您的集群不受 Docker Hub 速率限制的影响。
publishdate: 2020-12-07
attribution: John Howard (Google)
keywords: [docker]
target_release: 1.8
---

从 2020 年 11 月 20 日开始，Docker Hub 在镜像拉取中引入了[速率限制](https://www.docker.com/increase-rate-limits)。

因为 Istio 使用 [Docker Hub](https://hub.docker.com/u/istio) 作为默认镜像仓库，所以在大型集群上使用可能会由于超出速率限制导致 Pod 无法启动。这对 Istio 来说有很大问题，因为通常 Istio 的 sidecar 镜像与集群中的大多数 Pod 是一起启动的。

## 防范{#mitigation}

Istio 允许您指定一个自定义 docker 镜像仓库，可用于从您的私有仓库中获取容器镜像。在安装时通过 `--set hub=<some-custom-registry>` 来配置。

Istio 在 [Google 容器仓库](https://gcr.io/istio-release) 提供了官方镜像。可以通过 `--set hub=gcr.io/istio-release` 来配置。这适用于 Istio 1.5 及以上版本。

或者，您可以将 Istio 官方镜像拷贝到您自己的镜像仓库中。根据您的使用场景，如果您的集群运行在特定镜像仓库的环境中（例如，在 AWS 上，您可能希望将镜像映射到 Amazon ECR），或者您对安全性有严格的要求（对公共仓库的访问受限制），则此操作特别有用。您可以使用以下脚本完成此操作：

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
