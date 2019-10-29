---
title: ReferencedResourceNotFound
layout: analysis-message
---

This message occurs when your Configuration Resource Definition (CRD) file
contains a resource that has a reference to another resource that does not
exist. For example, you have a destination rule defined with a combination of a
host and subset that doesn't exist.

To resolve this problem, look for the resource type in the detailed error
message, correct the CRD file and try again.
