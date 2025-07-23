---
title: Service Mesh
test: n/a
---

Un *service mesh* o simplemente *malla* es una capa de infraestructura que permite
comunicación gestionada, observable y segura entre
[instancias de workload](/es/docs/reference/glossary/#workload-instance).

Los nombres de servicios combinados con un Namespace son únicos dentro de un mesh.
En un mesh [multicluster](/es/docs/reference/glossary/#multicluster), por ejemplo,
el servicio `bar` en el Namespace `foo` en `cluster-1` se considera el mismo
servicio que el servicio `bar` en el Namespace `foo` en `cluster-2`.

Dado que las [identidades](/es/docs/reference/glossary/#identity) se comparten dentro del service
mesh, las [instancias de workload](/es/docs/reference/glossary/#workload-instance) pueden autenticar comunicación con cualquier otra [instancia de
workload](/es/docs/reference/glossary/#workload-instance) dentro del mismo service mesh.
