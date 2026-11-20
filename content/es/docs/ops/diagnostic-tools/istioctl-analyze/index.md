---
title: Diagnosticar tu configuración con istioctl analyze
description: Te muestra cómo usar istioctl analyze para identificar posibles problemas en tu configuración.
weight: 40
keywords: [istioctl, debugging, kubernetes]
owner: istio/wg-user-experience-maintainers
test: yes
---

`istioctl analyze` es una herramienta de diagnóstico que puede detectar posibles problemas en tu
configuración de Istio. Puede ejecutarse contra un clúster en ejecución o contra un conjunto de archivos de configuración locales.
También puede ejecutarse contra una combinación de ambos, lo que te permite detectar problemas antes de
aplicar cambios a un clúster.

## Empieza en menos de un minuto {#getting-started-in-under-a-minute}

Puedes analizar tu clúster de Kubernetes actual en ejecución con:

{{< text syntax=bash snip_id=analyze_all_namespaces >}}
$ istioctl analyze --all-namespaces
{{< /text >}}

¡Y eso es todo! Te dará las recomendaciones que correspondan.

Por ejemplo, si olvidaste habilitar la inyección de Istio (un problema muy común), obtendrías el siguiente mensaje 'Info':

{{< text syntax=plain snip_id=analyze_all_namespace_sample_response >}}
Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

Corrige el problema:

{{< text syntax=bash snip_id=fix_default_namespace >}}
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

Luego vuelve a intentarlo:

{{< text syntax=bash snip_id=try_with_fixed_namespace >}}
$ istioctl analyze --namespace default
✔ No validation issues found when analyzing namespace: default.
{{< /text >}}

## Analizar clústeres en ejecución, archivos locales o ambos {#analyzing-live-clusters-local-files-or-both}

Analiza el clúster actual en ejecución, simulando el efecto de aplicar archivos yaml adicionales
como `bookinfo-gateway.yaml` y `destination-rule-all.yaml` del directorio `samples/bookinfo/networking`:

{{< text syntax=bash snip_id=analyze_sample_destrule >}}
$ istioctl analyze @samples/bookinfo/networking/bookinfo-gateway.yaml@ @samples/bookinfo/networking/destination-rule-all.yaml@
Error [IST0101] (Gateway default/bookinfo-gateway samples/bookinfo/networking/bookinfo-gateway.yaml:9) Referenced selector not found: "istio=ingressgateway"
Error [IST0101] (VirtualService default/bookinfo samples/bookinfo/networking/bookinfo-gateway.yaml:41) Referenced host not found: "productpage"
Warning [IST0174] (DestinationRule default/details samples/bookinfo/networking/destination-rule-all.yaml:49) The host details defined in the DestinationRule does not match any services in the mesh.
Warning [IST0174] (DestinationRule default/productpage samples/bookinfo/networking/destination-rule-all.yaml:1) The host productpage defined in the DestinationRule does not match any services in the mesh.
Warning [IST0174] (DestinationRule default/ratings samples/bookinfo/networking/destination-rule-all.yaml:29) The host ratings defined in the DestinationRule does not match any services in the mesh.
Warning [IST0174] (DestinationRule default/reviews samples/bookinfo/networking/destination-rule-all.yaml:12) The host reviews defined in the DestinationRule does not match any services in the mesh.
Error: Analyzers found issues when analyzing namespace: default.
See https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}

Analiza toda la carpeta `networking`:

{{< text syntax=bash snip_id=analyze_networking_directory >}}
$ istioctl analyze samples/bookinfo/networking/
{{< /text >}}

Analiza todos los archivos yaml de la carpeta `networking`:

{{< text syntax=bash snip_id=analyze_all_networking_yaml >}}
$ istioctl analyze samples/bookinfo/networking/*.yaml
{{< /text >}}

Los ejemplos anteriores analizan un clúster en ejecución. La herramienta también permite analizar
un conjunto de archivos de configuración yaml de Kubernetes locales, o una combinación de archivos locales y un
clúster en ejecución. Al analizar un conjunto de archivos locales, se espera que ese conjunto sea completamente autocontenido.
Normalmente, esto se usa para analizar el conjunto completo de archivos de configuración que se van a desplegar
en un clúster. Para usar esta función, simplemente agrega el flag `--use-kube=false`.

Analiza todos los archivos yaml de la carpeta `networking`:

{{< text syntax=bash snip_id=analyze_all_networking_yaml_no_kube >}}
$ istioctl analyze --use-kube=false samples/bookinfo/networking/*.yaml
{{< /text >}}

Puedes ejecutar `istioctl analyze --help` para ver el conjunto completo de opciones.

## Uso avanzado {#advanced}

### Habilitar mensajes de validación en el estado de los recursos {#enabling-validation-messages-for-resource-status}

{{< boilerplate experimental-feature-warning >}}

A partir de la v1.5, Istio puede configurarse para realizar análisis de configuración junto con
la distribución de configuración, que es su principal responsabilidad, mediante el flag `istiod.enableAnalysis`.
Este análisis usa la misma lógica y los mismos mensajes de error que `istioctl analyze`.
Los mensajes de validación del análisis se escriben en el subrecurso status del recurso de Istio afectado.

Por ejemplo, si tienes un gateway mal configurado en tu virtual service "ratings",
al ejecutar `kubectl get virtualservice ratings` obtendrías algo como:

{{< text syntax=yaml snip_id=vs_yaml_with_status >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
...
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
...
status:
  observedGeneration: "1"
  validationMessages:
  - documentationUrl: https://istio.io/v{{< istio_version >}}/docs/reference/config/analysis/ist0101/
    level: ERROR
    type:
      code: IST0101
{{< /text >}}

`enableAnalysis` se ejecuta en segundo plano y mantiene actualizado el campo status de un recurso
con su estado de validación actual. Ten en cuenta que esto no sustituye a `istioctl analyze`:

- No todos los recursos tienen un campo status personalizado (por ejemplo, los recursos `namespace` de Kubernetes),
  por lo que esos recursos no mostrarán los mensajes de validación asociados.
- `enableAnalysis` solo funciona en versiones de Istio a partir de la 1.5, mientras que
  `istioctl analyze` puede usarse con versiones anteriores.
- Aunque facilita ver qué falla en un recurso concreto,
  es más difícil obtener una visión global del estado de validación en la mesh.

Puedes habilitar esta función con:

{{< text syntax=bash snip_id=install_with_custom_config_analysis >}}
$ istioctl install --set values.global.istiod.enableAnalysis=true
{{< /text >}}

### Ignorar mensajes específicos del analizador mediante la CLI {#ignoring-specific-analyzer-messages-via-cli}

A veces puede resultarte útil ocultar o ignorar mensajes del analizador en determinados casos.
Por ejemplo, imagina una situación en la que se emite un mensaje sobre un recurso para el que no tienes permisos de actualización:

{{< text syntax=bash snip_id=analyze_k_frod >}}
$ istioctl analyze -k --namespace frod
Info [IST0102] (Namespace frod) The namespace is not enabled for Istio injection. Run 'kubectl label namespace frod istio-injection=enabled' to enable it, or 'kubectl label namespace frod istio-injection=disabled' to explicitly mark it as not needing injection.
{{< /text >}}

Como no tienes permisos para actualizar el namespace, no puedes resolver el mensaje
anotando el namespace. En su lugar, puedes indicarle a `istioctl analyze` que suprima el mensaje anterior para ese recurso:

{{< text syntax=bash snip_id=analyze_suppress0102 >}}
$ istioctl analyze -k --namespace frod --suppress "IST0102=Namespace frod"
✔ No validation issues found when analyzing namespace: frod.
{{< /text >}}

La sintaxis que se usa para la supresión es la misma que se usa en todo `istioctl` para referirse a
recursos: `<kind> <name>.<namespace>`, o simplemente `<kind> <name>` para recursos con ámbito de clúster como
`Namespace`. Si quieres suprimir varios objetos, puedes repetir el argumento `--suppress` o usar comodines:

{{< text syntax=bash snip_id=analyze_suppress_frod_0107_baz >}}
$ # Suppress code IST0102 on namespace frod and IST0107 on all pods in namespace baz
$ istioctl analyze -k --all-namespaces --suppress "IST0102=Namespace frod" --suppress "IST0107=Pod *.baz"
{{< /text >}}

### Ignorar mensajes específicos del analizador mediante anotaciones {#ignoring-specific-analyzer-messages-via-annotations}

También puedes ignorar mensajes específicos del analizador usando una anotación en el recurso.
Por ejemplo, para ignorar el código IST0107 (`MisplacedAnnotation`) en el recurso `deployment/my-deployment`:

{{< text syntax=bash snip_id=annotate_for_deployment_suppression >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107
{{< /text >}}

Para ignorar varios códigos en un recurso, separa cada código con una coma:

{{< text syntax=bash snip_id=annotate_for_deployment_suppression_107 >}}
$ kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107,IST0002
{{< /text >}}

## Ayúdanos a mejorar esta herramienta {#helping-us-improve-this-tool}

Seguimos agregando más capacidades de análisis y nos encantaría que nos ayudaras a identificar más casos de uso.
Si descubriste alguna trampa de configuración de Istio, alguna situación complicada que te haya causado
problemas, abre un issue y cuéntanoslo. Quizá podamos detectar ese problema automáticamente para que
otras personas puedan descubrirlo y evitarlo desde el principio.

Para ello, [abre un issue](https://github.com/istio/istio/issues) describiendo tu escenario. Por ejemplo:

- Revisar todos los virtual services
- Para cada uno, revisar su lista de gateways
- Si alguno de los gateways no existe, generar un error

Ya tenemos un analizador para este escenario concreto, así que esto es solo un ejemplo para ilustrar qué
tipo de información deberías proporcionar.

## Preguntas y respuestas {#qa}

- **¿Para qué versión de Istio está pensada esta herramienta?**

    Como con otras herramientas de `istioctl`, en general recomendamos usar una versión descargada
    que coincida con la versión desplegada en tu clúster.

    Por ahora, el análisis suele ser compatible con versiones anteriores, de modo que puedes,
    por ejemplo, ejecutar la versión {{< istio_version >}} de `istioctl analyze` contra
    un clúster que ejecute una versión anterior de Istio 1.x y esperar obtener resultados útiles.
    Las reglas de análisis que no tengan sentido con una versión anterior de Istio se omitirán.

    Si decides usar el `istioctl` más reciente para analizar un clúster
    que ejecuta una versión anterior de Istio, te sugerimos guardarlo en una carpeta separada
    de la versión del binario que usas para gestionar tu versión de Istio desplegada.

- **¿Qué analizadores se admiten actualmente?**

    Todavía estamos trabajando en documentar los analizadores. Mientras tanto, puedes ver
    todos los analizadores en el [código fuente de Istio]({{< github_tree >}}/pkg/config/analysis/analyzers).

    También puedes ver qué [mensajes de análisis de configuración](/es/docs/reference/config/analysis/)
    se admiten para hacerte una idea de lo que se cubre actualmente.

- **¿Puede el análisis dañar mi clúster?**

    El análisis nunca cambia el estado de la configuración. Es una operación completamente de solo lectura
    que nunca alterará el estado de un clúster.

- **¿Y el análisis que va más allá de la configuración?**

    Hoy en día, el análisis se basa únicamente en la configuración de Kubernetes, pero en el futuro
    nos gustaría ir más allá. Por ejemplo, podríamos permitir que los analizadores también revisen
    los registros para generar recomendaciones.

- **¿Dónde puedo averiguar cómo corregir los errores que obtengo?**

    El conjunto de [mensajes de análisis de configuración](/es/docs/reference/config/analysis/)
    contiene descripciones de cada mensaje junto con las correcciones sugeridas.
