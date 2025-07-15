---
title: ¿Puedo habilitar TLS mutuo para algunos servicios mientras lo dejo deshabilitado para otros servicios en el mismo cluster?
weight: 20
---

La [política de autenticación](/es/docs/concepts/security/#authentication-policies) puede ser mesh-wide (lo que afecta a todos los servicios de la malla), namespace-wide
(todos los servicios del mismo namespace) o específicamente del servicio. Puede tener una o varias políticas para configurar TLS mutuo para los servicios de un cluster de la forma que desee.
