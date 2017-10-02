---
title: Service Name
type: markdown
---
A unique name for a **Service**, identifying it within the **Service Mesh**.
A **Service** may not be renamed and maintain its identity, each **Service Name** is unique.
A **Service** may have multiple versions, but a **Service Name** is version-independent.
  * **Service Names** are accessible in Istio configuration as the `source.service` and `destination.service` attributes.
