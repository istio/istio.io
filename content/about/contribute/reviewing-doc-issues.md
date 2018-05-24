---
title: Doc Issues
description: Explains the process involved in accepting documentation updates.
weight: 60
aliases:
    - /docs/welcome/contribute/reviewing-doc-issues.html
---

This page explains how documentation issues are reviewed and prioritized for the
[istio/istio.github.io](https://github.com/istio/istio.github.io) repository.
The purpose is to provide a way to organize issues and make it easier to contribute to
Istio documentation. The following should be used as the standard way of prioritizing,
labeling, and interacting with issues.

## Prioritizing Issues

The following labels and definitions should be used to prioritize issues. If you change the priority of an issue, please comment on
the issue with your reasoning for the change.

<table>
<tr>
    <td>P1</td>
    <td><ul>
        <li>Major content errors affecting more than 1 page</li>
        <li>Broken code sample on a heavily trafficked page</li>
        <li>Errors on a “getting started” page</li>
        <li>Well known or highly publicized customer pain points</li>
        <li>Automation issues</li>
    </ul></td>
</tr>

<tr>
    <td>P2</td>
    <td><ul>
        <li>Default for all new issues</li>
        <li>Broken code for sample that is not heavily used</li>
        <li>Minor content issues in a heavily trafficked page</li>
        <li>Major content issues on a lower-trafficked page</li>
    </ul></td>
</tr>

<tr>
    <td>P3</td>
    <td><ul>
        <li>Typos and broken anchor links</li>
    </ul></td>
</tr>
</table>

## Handling special issue types

If a single problem has one or more issues open for it, the problem should be consolidated into a single issue. You should decide which issue to keep open
(or open a new issue), port over all relevant information, link related issues, and close all the other issues that describe the same problem. Only having
a single issue to work on will help reduce confusion and avoid duplicating work on the same problem.

Depending on where a dead link is reported, different actions are required to resolve the issue. Dead links in the reference
docs are automation issues and should be assigned a P1 until the problem can be fully understood. All other dead links are issues
that need to be manually fixed and can be assigned a P3.
