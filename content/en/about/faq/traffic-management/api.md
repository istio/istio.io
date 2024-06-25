---
title: Which API version should I use?
weight: 10
---

Always use the primary/latest API version declared in the CRD, as this will give you the most up-to-date functionality and the system will handle any necessary version conversions transparently.

One can also use the oldest API version that you need to support, to ensure compatibility with all your users for integration authors, the system will handle converting the requests/responses to the primary/latest version behind the scenes.

The key is that the different API versions are just different "views" of the same underlying resource, so you can use the version that best suits your needs, and the system will take care of the version conversions. 