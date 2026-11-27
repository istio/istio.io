---
title: Firma y validación de imágenes
description: Describe cómo usar las firmas de imágenes para verificar la procedencia de las imágenes de Istio.
weight: 35
aliases: []
keywords: [install,signing]
owner: istio/wg-environments-maintainers
test: n/a
---

Esta página describe cómo usar [Cosign](https://github.com/sigstore/cosign) para
validar la procedencia de los artefactos de imagen de Istio.

Cosign es una herramienta desarrollada como parte del proyecto
[sigstore](https://www.sigstore.dev), que
simplifica la firma y la validación de artefactos firmados de la Open Container Initiative (OCI),
como las imágenes de contenedor.

A partir de Istio 1.12, firmamos todas las imágenes de contenedor publicadas oficialmente como parte de nuestro proceso
de lanzamiento. Así, los usuarios finales pueden verificar estas imágenes con
el proceso que se describe a continuación.

Este proceso sirve tanto para ejecutarlo manualmente como para integrarlo en pipelines de compilación
o de despliegue y verificar los artefactos de forma automatizada.

## Requisitos previos

Antes de empezar, haz lo siguiente:

1. Descarga la última
   compilación de [Cosign](https://github.com/sigstore/cosign/releases/latest) para tu
   arquitectura, junto con su firma.
1. Valida la firma del binario `cosign`:

    {{< text bash >}}
    $ openssl dgst -sha256 \
        -verify <(curl -ssL https://raw.githubusercontent.com/sigstore/cosign/main/release/release-cosign.pub) \
        -signature <(cat /path/to/cosign.sig | base64 -d) \
        /path/to/cosign-binary
     {{< /text >}}

1. Haz que el binario sea ejecutable (`chmod +x`) y muévelo a una ubicación incluida en el `PATH`

## Validar una imagen

Las versiones 1.31.1 y posteriores están firmadas con la clave pública
`https://istio.io/misc/istio-key-v2.pub`. Usa
`https://istio.io/misc/istio-key.pub` para las versiones anteriores.

Para validar una imagen de contenedor, haz lo siguiente:

{{< text bash >}}
$ ./cosign-binary verify --key <public key url> {{< istio_docker_image "pilot" >}}
{{< /text >}}

Este proceso funciona con cualquier imagen publicada o release candidate compilada con la infraestructura de compilación de Istio.

Un ejemplo con su salida:

{{< text bash >}}
$ cosign verify --key "https://istio.io/misc/istio-key-v2.pub" docker.io/istio/pilot:1.31.1


Verification for docker.io/istio/pilot:1.31.1 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
  - Any certificates were verified against the Fulcio roots.

[{"critical":{"identity":{"docker-reference":"docker.io/istio/pilot"},"image":{"docker-manifest-digest":"sha256:c37fd83f6435ca0966d653dc6ac42c9fe5ac11d0d5d719dfe97de84acbf7a32d"},"type":"cosign container image signature"},"optional":null}]
{{< /text >}}
