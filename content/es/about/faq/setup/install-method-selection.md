---
title: ¿Qué método de instalación de Istio debo usar?
weight: 10
---

Además de la sencilla instalación de evaluación de [introducción](/es/docs/setup/getting-started), existen varios métodos diferentes
que puede utilizar para instalar Istio. Cuál debe usar depende de sus requisitos de producción.
A continuación se enumeran algunas de las ventajas y desventajas de cada uno de los métodos disponibles:

1. [instalación de istioctl](/es/docs/setup/install/istioctl/)

    La ruta de instalación y gestión más sencilla y cualificada con alta seguridad.
    Este es el método recomendado por la comunidad para la mayoría de los casos de uso.

    Ventajas:

    - Validación exhaustiva de la configuración y verificación del estado.
    - Utiliza la API `IstioOperator`, que proporciona amplias opciones de configuración/personalización.

    Desventajas:

    - Se deben gestionar varios binarios, uno por cada versión menor de Istio.
    - El comando `istioctl` puede establecer valores automáticamente en función de su entorno de ejecución,
      produciendo así instalaciones variables en diferentes entornos de Kubernetes.

1. [Instalar usando Helm](/es/docs/setup/install/helm/)

    Permite una fácil integración con flujos de trabajo basados en Helm y la eliminación automática de recursos durante las actualizaciones.

    Ventajas:

    - Enfoque familiar que utiliza herramientas estándar de la industria.
    - Gestión nativa de versiones y actualizaciones de Helm.

    Desventajas:

    - Menos comprobaciones y validaciones en comparación con `istioctl install`.
    - Algunas tareas administrativas requieren más pasos y tienen una mayor complejidad.

1. Aplicar un manifiesto de Kubernetes generado

    - [Generación de manifiestos de Kubernetes con `istioctl`](/es/docs/setup/install/istioctl/#generate-a-manifest-before-installation)
    - [Generación de manifiestos de Kubernetes con `helm`](/es/docs/setup/install/helm/#generate-a-manifest-before-installation)

    Este método es adecuado cuando se requiere una auditoría estricta o un aumento de los manifiestos de salida, o si existen restricciones de herramientas de terceros.

    Ventajas:

    - Más fácil de integrar con herramientas que no usan `helm` o `istioctl`.
    - No se requieren herramientas de instalación que no sean `kubectl`.

    Desventajas:

    - No se realizan comprobaciones en tiempo de instalación, detección de entorno o validaciones compatibles con ninguno de los métodos anteriores.
    - No se admite la gestión de la instalación ni la capacidad de actualización.
    - La experiencia del usuario es menos optimizada.
    - La notificación de errores durante la instalación no es tan sólida.

Las instrucciones de instalación para todos estos métodos están disponibles en la [página de instalación de Istio](/es/docs/setup/install).
