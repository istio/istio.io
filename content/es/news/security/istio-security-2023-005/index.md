---
title: ISTIO-SECURITY-2023-005
subtitle: Boletín de seguridad
description: Cambios en los permisos RBAC de Istio CNI.
cves: []
cvss: N/A
vector: N/A
releases: ["Todas las versiones anteriores a 1.18.0", "1.18.0 a 1.18.5", "1.19.0 a 1.19.4", "1.20.0"]
publishdate: 2023-12-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

El Comité de Seguridad de Istio recibió un reporte sobre los permisos elevados de Istio CNI. En un nodo ya comprometido, los permisos del `ClusterRole` `istio-cni-repair-role` podían ampliar el alcance del incidente de un solo nodo a todo el clúster.

Para reducir ese riesgo, los mantenedores de Istio están introduciendo gradualmente un cambio en ese `ClusterRole`. En las versiones corregidas, los roles conceden únicamente los permisos que requiere el [modo de reparación seleccionado](/docs/setup/additional-setup/cni/#race-condition--mitigation). Antes del cambio se concedían todos los roles, con permisos más amplios de lo necesario, independientemente de la configuración.

Una opción adicional elimina la necesidad de que Istio CNI tenga permisos RBAC personalizados. Debido a los posibles riesgos de este mecanismo, solo está habilitada de forma predeterminada a partir de Istio 1.21. Estas son las opciones de configuración y sus permisos:

| Configuración | Permisos | Comportamiento ante un error | Notas |
|---------------|----------|-------------------------------|-------|
| `values.cni.repair.deletePods` | `DELETE` sobre pods | Se eliminan los pods. Al volver a programarlos, tendrán la configuración correcta. | Opción predeterminada en Istio 1.20 y versiones anteriores. |
| `values.cni.repair.labelPods` | `UPDATE` sobre pods | Se etiquetan los pods. El usuario debe intervenir de forma manual para resolver el problema. | |
| `values.cni.repair.repairPods` | Ninguno | Los pods se reconfiguran dinámicamente. Cuando se reinicia el contenedor, el pod continúa su ejecución normal. | Opción predeterminada a partir de Istio 1.21. |

El Comité de Seguridad de Istio agradece a `Yuval Avrahami` por reportar el problema y colaborar en su resolución.
