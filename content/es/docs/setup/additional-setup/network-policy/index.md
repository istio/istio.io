---
title: NetworkPolicy
description: Despliega recursos opcionales de Kubernetes NetworkPolicy para los componentes de Istio.
weight: 75
keywords: [networkpolicy,security,helm]
owner: istio/wg-networking-maintainers
test: no
---

Istio puede desplegar opcionalmente recursos de Kubernetes [`NetworkPolicy`](https://kubernetes.io/docs/concepts/services-networking/network-policies/) para sus componentes. Esto es útil en clústeres que aplican una política de red de denegación por defecto, lo cual es un requisito común en entornos protegidos.

Cuando está habilitado, se crean recursos `NetworkPolicy` para istiod, istio-cni, ztunnel y los gateways instalados mediante Helm, definiendo los puertos de ingress que necesita cada componente. Todo el egress se permite de forma predeterminada, ya que componentes como istiod necesitan conectarse a endpoints definidos por el usuario (por ejemplo, URLs de JWKS). El `NetworkPolicy` del gateway incluye automáticamente los puertos de servicio configurados en los valores de Helm del gateway.

{{< warning >}}
Los gateways creados a través de la Gateway API de Kubernetes o la [inyección de gateway](/es/docs/setup/additional-setup/gateway/#deploying-a-gateway), los proxies waypoint y los sidecars **no** están cubiertos por el `NetworkPolicy` integrado de Istio; debes crear y gestionar los recursos `NetworkPolicy` para ellos por separado. Esto es intencional: gestionar automáticamente el `NetworkPolicy` para estos proxies requeriría otorgar a istiod permisos para crear y modificar recursos `NetworkPolicy` en todo el clúster, lo que afectaría negativamente la postura de seguridad del control plane.
{{< /warning >}}

{{< tip >}}
Para obtener información sobre cómo interactúa el modo ambient con `NetworkPolicy` en tus pods de aplicación, consulta [Ambient y NetworkPolicy de Kubernetes](/es/docs/ambient/usage/networkpolicy/).
{{< /tip >}}

## Habilitar NetworkPolicy

Para habilitar `NetworkPolicy`, establece `global.networkPolicy.enabled=true` durante la instalación.

Con `istioctl`:

{{< text bash >}}
$ istioctl install --set values.global.networkPolicy.enabled=true
{{< /text >}}

Con Helm, pasa el ajuste a cada chart:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true
$ helm install ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-ingressgateway istio/gateway -n istio-ingress --set global.networkPolicy.enabled=true
{{< /text >}}

## Revisar las políticas generadas

El `NetworkPolicy` de cada componente permite el ingress en los puertos específicos que ese componente necesita, y permite todo el egress (ya que componentes como istiod necesitan conectarse a endpoints definidos por el usuario, como URLs de JWKS).

Puedes previsualizar los recursos `NetworkPolicy` exactos que se crearán usando `helm template`:

{{< text bash >}}
$ helm template istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

Para inspeccionar las políticas después de la instalación:

{{< text bash >}}
$ kubectl get networkpolicy -n istio-system
{{< /text >}}

## Personalizar NetworkPolicy

Los recursos `NetworkPolicy` creados por Istio son intencionalmente amplios: las reglas de ingress usan selectores `from` vacíos, lo que significa que se permite el tráfico desde cualquier origen en los puertos listados. Esto se debe a que el origen del tráfico legítimo (por ejemplo, kube-apiserver, Prometheus, pods de aplicación) varía entre clústeres.

Si necesitas políticas más restrictivas, puedes deshabilitar el `NetworkPolicy` integrado de Istio y crear el tuyo propio, usando la salida de `helm template` como punto de partida.
