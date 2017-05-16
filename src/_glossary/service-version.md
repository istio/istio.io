---
title: Service Version
type: markdown
---
In a continuous deployment scenario, for a given service,
there can be multiple sets of instances running potentially different
variants of the application binary or config. These variants are not necessarily
different API versions. They could be iterative changes to the same service,
deployed in different environments (prod, staging, dev, etc.). Common
scenarios where this occurs include A/B testing, canary rollouts, etc. The
choice of a particular version can be decided based on various criterion
(headers, url, etc.) and/or by weights assigned to each version.  Each
service has a default version consisting of all its instances.
