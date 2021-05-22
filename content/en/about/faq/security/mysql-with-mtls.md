---
title: MySQL Connectivity Troubleshooting
description: Troubleshooting MySQL connectivity issue due to PERMISSIVE mode.
weight: 95
keywords: [mysql,mtls]
---

You may find MySQL can't connect after installing Istio. This is because MySQL is a [server first](/docs/ops/deployment/requirements/#server-first-protocols) protocol,
which can interfere with Istio's protocol detection. In particular, using `PERMISSIVE` mTLS mode, may cause issues.
You may see error messages such as `ERROR 2013 (HY000): Lost connection to MySQL server at
'reading initial communication packet', system error: 0`.

This can be fixed by ensuring `STRICT` or `DISABLE` mode is used, or that all clients are configured
to send mTLS. See [server first protocols](/docs/ops/deployment/requirements/#server-first-protocols) for more information.
