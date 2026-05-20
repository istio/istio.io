---
title: "Istio está migrando los registros de contenedores"
description: Lo que puedes hacer hoy para asegurarte de que tus clústeres no se vean afectados por la retirada de `gcr.io/istio-release`.
publishdate: 2026-03-23
attribution: Steven Jin (Microsoft), John Howard (Solo.io)
keywords: [Istio,Helm,Container Registry]
---

Debido a cambios en el modelo de financiación de Istio, las imágenes de Istio dejarán de estar disponibles en `gcr.io/istio-release` a partir del 1 de enero de 2027.
Es decir, los clústeres que hagan referencia a imágenes alojadas en `gcr.io/istio-release` podrían fallar al crear nuevos pods en 2027.

De hecho, estamos migrando completamente todos los artefactos de Istio fuera de Google Cloud, incluidos los Helm charts.
Las comunicaciones futuras cubrirán la migración de los Helm charts y otros artefactos.
Esta publicación se centra en lo que puedes hacer hoy en respuesta a la migración del registro de contenedores de 2027.

## ¿Me afecta esto?

Por defecto, las instalaciones de Istio usan Docker Hub (`docker.io/istio`) como registro de contenedores, pero muchos usuarios optan por usar el espejo `gcr.io/istio-release`.
Puedes verificar si estás usando el espejo con el siguiente comando.

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("gcr.io/istio-release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

El comando anterior listará todos los pods que usan imágenes alojadas en `gcr.io/istio-release`.
Si hay algún pod de este tipo, probablemente necesitarás migrar.

{{< tip >}}
Incluso si estás usando Docker Hub como tu registro, te sugerimos que migres a `registry.istio.io` por si las imágenes de Istio dejan de estar disponibles en Docker Hub en el futuro.
Consulta más detalles a continuación.
{{< /tip >}}

## Qué hacer hoy

Aunque planeamos mantener las imágenes disponibles en `gcr.io/istio-release` hasta finales de 2026,
hemos configurado `registry.istio.io` como el nuevo hogar para las imágenes de Istio.
Por favor, migra a usar `registry.istio.io` lo antes posible.

### Usando `istioctl`

Si instalas Istio con `istioctl`, puedes actualizar tu configuración de `IstioOperator` de la siguiente manera:

{{< text yaml >}}
# istiooperator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  # ...
  hub: registry.istio.io/release
  # El resto puede permanecer igual, a menos que hagas referencia a imágenes de `gcr.io/istio-release` en otro lugar
{{< /text >}}

e instala Istio usando esta configuración

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

También puedes pasar el registro como argumento de línea de comandos

{{< text bash >}}
$ istioctl install --set hub=registry.istio.io/release # el resto de tus argumentos
{{< /text >}}

### Usando Helm

Si usas Helm para instalar Istio, actualiza tu archivo de valores con lo siguiente:

{{< text yaml >}}
# ...
hub: registry.istio.io/release
global:
  hub: registry.istio.io/release
# El resto puede permanecer igual, a menos que hagas referencia a imágenes de `gcr.io/istio-release` en otro lugar
{{< /text >}}

Luego, actualiza tu instalación de Helm con tu nuevo archivo de valores.

### Espejos privados

Tu organización podría extraer imágenes de `gcr.io/istio-release`, enviarlas a un registro privado y hacer referencia al registro privado en tu instalación de Istio.
Este proceso seguirá funcionando, pero tendrás que extraer desde `registry.istio.io/release` en lugar de `gcr.io/istio-release`.
