---
title: Istio Security Vulnerability Disclosure Information
description: Responsible disclosure for Istio security vulnerabilities
weight: 35
aliases:
    - /security-vulnerabilities.html
    - /security-vulnerabilities/index.html
---
## How to report a security vulnerability?

We’re very grateful for security researchers and users that report Istio security vulnerabilities to us. We will thoroughly investigated every report. 

To make a report, please email the private [istio-security-vulnerabilities@google.com](mailto:istio-security-vulnerabilities@google.com) list with the vulnerability details and the details expected for [Istio bug reports](https://istio.io/help/bugs/).

### When should I report a security vulnerability?

- You think you discovered a potential security vulnerability in Istio
- You are unsure whether/how a vulnerability affects Istio
- You think you discovered a vulnerability in another project that Istio depends on (e.g., Envoy, docker, Kubernetes)

### When should I NOT report a security vulnerability?

- You need help tuning Istio components for security
- You need help applying security related updates
- Your issue is not security related

## Security vulnerability response

Each report is acknowledged and analyzed by Istio security team members within 3 working days. 

Any vulnerability information shared with Istio security team stays within Istio project and will not be disseminated to other projects unless it is necessary to get the issue fixed.

As the security issue moves from triage, to identified fix, to release planning, we will keep the reporter updated.

## Public disclosure timing

A public disclosure date is negotiated between the Istio security team and the bug submitter. We prefer to fully disclose the bug as soon as possible once a user mitigation is available. It is reasonable to delay disclosure when the bug or the fix is not yet fully understood, the solution is not well-tested, or for vendor coordination. The timeframe for disclosure is from immediate (especially if it's already publicly known) to a few weeks. As a basic default, we expect report date to disclosure date to be on the order of 7 days. The Istio security team holds the final say when setting a disclosure date.
