---
title: Reporting Security Vulnerabilities
description: Responsible disclosure for Istio security vulnerabilities.
weight: 35
icon: vulnerabilities
---

We are very grateful to the security researchers and users that report
back Istio security vulnerabilities. We investigate every report thoroughly.

To make a report, send an email to the private
[`istio-security-vulnerabilities@google.com`](mailto:istio-security-vulnerabilities@google.com)
mailing list with the vulnerability details. For normal product bugs
unrelated to latent security vulnerabilities, please head to
our [Reporting Bugs](/about/bugs/) page to learn what to do.

## When to report a security vulnerability?

Send us a report whenever you:

- Think Istio has a potential security vulnerability.
- Are unsure whether or how a vulnerability affects Istio.
- Think a vulnerability is present in another project that Istio
depends on. For example, Envoy, Docker, or Kubernetes.

## When not to report a security vulnerability?

Don't send a vulnerability report if:

- You need help tuning Istio components for security.
- You need help applying security related updates.
- Your issue is not security related.

## Security vulnerability response

The Istio security team acknowledges and analyzes each report within three
work days.

Any vulnerability information you share with the Istio security team stays
within the Istio project. We don't disseminate the information to other
projects. We only share the information as needed to fix the issue.

We keep the reporter updated as the status of the security issue moves
from `triaged`, to `identified fix`, to `release planning`.

## Public disclosure timing

The Istio security team and the bug submitter negotiate a public
disclosure date between them. We prefer to fully disclose the bug as
soon as possible once a user mitigation is available.
We consider reasonable to delay disclosure when the bug or the fix is
not yet fully understood, the solution is not well-tested, or for
vendor coordination. The time frame for disclosure is from immediate,
especially if the bug is known publicly already, to a few weeks.
As a basic default, we expect the report date and the disclosure date
to be on the order of seven days apart. The Istio security team holds
the final say on setting a disclosure date.
