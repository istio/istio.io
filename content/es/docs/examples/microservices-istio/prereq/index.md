---
title: Prerrequisitos
overview: Verificar los prerrequisitos para este tutorial.
weight: 1
owner: istio/wg-docs-maintainers
test: n/a
---

{{< boilerplate work-in-progress >}}

Para este tutorial necesitas un Cluster de Kubernetes con un namespace para los
módulos del tutorial y una computadora local para ejecutar los comandos. Si tienes tu
propio cluster, asegúrate de que tu cluster satisfaga los prerrequisitos.

Si estás en un taller y los instructores proporcionan un cluster, deja que
ellos manejen los prerrequisitos del cluster, mientras tú avanzas para configurar tu computadora
local.

## Clúster de Kubernetes

Asegúrate de que se cumplan las siguientes condiciones:

- Tienes privilegios de administrador en la máquina virtual que ejecuta un Cluster de Kubernetes llamado
  `tutorial-cluster` y privilegios de administrador en la máquina virtual donde se ejecuta.
- Puedes crear un namespace en el cluster para cada participante.

## Computadora local

Asegúrate de que se cumplan las siguientes condiciones:

- Tienes acceso de escritura al archivo `/etc/hosts` de la computadora local.
- Tienes la capacidad y permisos para descargar, instalar y ejecutar herramientas de línea de comandos en la computadora local.
- Tienes conectividad a Internet durante la duración del tutorial.
