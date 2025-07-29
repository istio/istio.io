---
title: ¿Es ztunnel un único punto de fallo?
weight: 25
---

El ztunnel de Istio no introduce un único punto de fallo (SPOF) en un cluster de Kubernetes. Los fallos de ztunnel se limitan a un único nodo, que se considera un componente falible en un cluster. Se comporta de la misma manera que otra infraestructura crítica para el nodo que se ejecuta en cada cluster, como el kernel de Linux, el tiempo de ejecución del contenedor, etc. En un sistema diseñado correctamente, las interrupciones de los nodos no provocan interrupciones del cluster. [Más información](https://blog.howardjohn.info/posts/ambient-spof/).