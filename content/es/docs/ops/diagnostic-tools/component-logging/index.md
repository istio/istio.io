---
title: Registro de componentes
description: Describe cómo usar el registro a nivel de componente para obtener información sobre el comportamiento de un componente en ejecución.
weight: 70
keywords: [ops]
aliases:
  - /help/ops/component-logging
  - /docs/ops/troubleshooting/component-logging
owner: istio/wg-user-experience-maintainers
test: no
---

Los componentes de Istio se construyen con un framework de registro flexible que ofrece varias funciones y controles para
ayudar a operar estos componentes y facilitar el diagnóstico. Controlas estas funciones de registro pasando
opciones de línea de comandos al iniciar los componentes.

## Ámbitos de registro {#logging-scopes}

Los mensajes de registro que emite un componente se clasifican por *ámbitos* (scopes). Un ámbito representa un conjunto de mensajes de registro relacionados que
puedes controlar como un todo. Cada componente tiene ámbitos distintos, según las funciones que
ofrece. Todos los componentes tienen el ámbito `default`, que se usa para los mensajes de registro sin categoría.

Por ejemplo, en el momento de escribir esto, `istioctl` tiene 25 ámbitos, que representan distintas áreas funcionales del comando:

- `ads`, `adsc`, `all`, `analysis`, `authn`, `authorization`, `ca`, `cache`, `cli`, `default`, `installer`, `klog`, `mcp`, `model`, `patch`, `processing`, `resource`, `source`, `spiffe`, `tpath`, `translator`, `util`, `validation`, `validationController`, `wle`

Pilot-Agent, Pilot-Discovery y el Istio Operator tienen sus propios ámbitos, que puedes descubrir consultando su [documentación de referencia](/es/docs/reference/commands/).

Cada ámbito tiene un único nivel de salida, que puede ser uno de los siguientes:

1. none
1. error
1. warn
1. info
1. debug

donde `none` no produce ninguna salida para el ámbito y `debug` produce la máxima cantidad de salida. El nivel por defecto para todos los ámbitos
es `info`, que busca proporcionar la cantidad adecuada de información de registro para operar Istio en condiciones normales.

Para controlar el nivel de salida, usa la opción de línea de comandos `--log_output_level`. Por ejemplo:

{{< text bash >}}
$ istioctl analyze --log_output_level klog:none,cli:info
{{< /text >}}

Además de controlar el nivel de salida desde la línea de comandos, también puedes controlar el nivel de salida de un componente en ejecución
mediante su interfaz [ControlZ](/es/docs/ops/diagnostic-tools/controlz).

## Controlar la salida {#controlling-output}

Normalmente, los mensajes de registro se envían al flujo de salida estándar del componente. La opción `--log_target` te permite dirigir la salida a
cualquier número de ubicaciones distintas. Le pasas a la opción una lista de rutas del sistema de archivos separadas por comas, junto con los valores
especiales `stdout` y `stderr` para indicar los flujos de salida estándar y de error estándar, respectivamente.

Normalmente, los mensajes de registro se emiten en un formato fácil de leer para las personas. Puedes usar la opción `--log_as_json` para forzar la salida en JSON,
que puede resultar más fácil de procesar para las herramientas.

## Rotación de registros {#log-rotation}

Los componentes del control plane de Istio pueden gestionar automáticamente la rotación de registros, lo que facilita dividir registros grandes en archivos de registro más pequeños.
La opción `--log_rotate` te permite especificar el nombre de archivo base que se usará para la rotación. Se usarán nombres derivados para cada
archivo de registro.

La opción `--log_rotate_max_age` te permite especificar el número máximo de días antes de que se produzca la rotación del archivo, mientras que la opción `--log_rotate_max_size`
te permite especificar el tamaño máximo en megabytes antes de que se produzca la rotación. Por último, la opción `--log_rotate_max_backups` te permite controlar
el número máximo de archivos rotados que se conservan; los archivos más antiguos se eliminan automáticamente.

## Depuración de componentes {#component-debugging}

Las opciones `--log_caller` y `--log_stacktrace_level` te permiten controlar si la información de registro incluye
información de nivel de programador. Esto es útil cuando intentas localizar errores en un componente, pero no se
suele usar en la operación diaria.
