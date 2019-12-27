---
title: Security Vulnerabilities
description: How we handle security vulnerabilities.
weight: 35
icon: vulnerabilities
---

We are very grateful to the security researchers and users that report
back Istio security vulnerabilities. We investigate every report thoroughly.

## Reporting a vulnerability

To make a report, send an email to the private
[istio-security-vulnerability-reports@googlegroups.com](mailto:istio-security-vulnerability-reports@googlegroups.com)
mailing list with the vulnerability details. For normal product bugs
unrelated to latent security vulnerabilities, please head to
our [Reporting Bugs](/pt-br/about/bugs/) page to learn what to do.

### When to report a security vulnerability?

Send us a report whenever you:

- Think Istio has a potential security vulnerability.
- Are unsure whether or how a vulnerability affects Istio.
- Think a vulnerability is present in another project that Istio
depends on. For example, Envoy, Docker, or Kubernetes.

### When not to report a security vulnerability?

Don't send a vulnerability report if:

- You need help tuning Istio components for security.
- You need help applying security related updates.
- Your issue is not security related.

## Evaluation

The Istio security team acknowledges and analyzes each vulnerability report within three
work days.

Any vulnerability information you share with the Istio security team stays
within the Istio project. We don't disseminate the information to other
projects. We only share the information as needed to fix the issue.

We keep the reporter updated as the status of the security issue moves
from `triaged`, to `identified fix`, to `release planning`.

## Fixing the issue

Once a security vulnerability has been fully characterized, a fix is developed by the Istio team.
The development and testing for the fix happens in a private GitHub repository in order to prevent
premature disclosure of the vulnerability.

## Early disclosure

The Istio project maintains a mailing list for private early disclosure of security vulnerabilities. The list is used to provide actionable
information to close Istio partners. The list is not intended for individuals to find out about security issues.

See [Early Disclosure of Security Vulnerabilities](https://github.com/istio/community/blob/master/EARLY-DISCLOSURE.md) to get more information.

## Public disclosure

On the day chosen for public disclosure, a sequence of activities takes place as quickly as possible:

- Changes are merged from the private GitHub repository holding the fix into the appropriate set of public
branches.

- Release engineers ensure all necessary binaries are promptly built and published.

- Once the binaries are available, an announcement is sent out on the following channels:

    - The [Istio blog](/pt-br/blog)
    - The [Announcements](https://discuss.istio.io/c/announcements) category on discuss.istio.io
    - The [Istio Twitter feed](https://twitter.com/IstioMesh)
    - The [#announcements channel on Slack](https://istio.slack.com/messages/CFXS256EQ/)

As much as possible this announcement will be actionable, and include any mitigating steps customers can take prior to
upgrading to a fixed version. The recommended target time for these announcements is 16:00 UTC from Monday to Thursday.
This means the announcement will be seen morning Pacific, early evening Europe, and late evening Asia.
