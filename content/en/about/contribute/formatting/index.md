---
title: Follow Formatting Standards
description: Explains the standard markup used to format Istio documentation.
weight: 10
aliases:
keywords: [contribute]
---

This page shows the formatting standards for the Istio documentation. Istio uses
Markdown to markup the content and Hugo to build the website. To ensure
consistency across our documentation, we have agreed on these formatting standards.

## Don't use capitalization for emphasis

Only use the original capitalization found in the code or configuration files
when referencing those values directly. Use back-ticks \`\` around the
referenced value to make the connection explicit. For example, use
`IstioRoleBinding`, not `Istio Role Binding` or `istio role binding`.

If you are not referencing values or code directly, use normal sentence
capitalization, for example, "The Istio role binding configuration takes place
in a YAML file."

## Use angle brackets for placeholders

Use angle brackets for placeholders in commands or code samples. Tell the reader
what the placeholder represents. For example:

{{< text markdown >}}

1. Display information about a pod:

    {{</* text bash */>}}
    $ kubectl describe pod <pod-name>
    {{</* /text */>}}

    Where `<pod-name>` is the name of one of your pods.

{{< /text >}}

## Use **bold** to emphasize user interface elements

|Do                | Don't
|------------------|------
|Click **Fork**.   | Click "Fork".
|Select **Other**. | Select 'Other'.

## Use _italics_ to emphasize new terms

|Do                                         | Don't
|-------------------------------------------|---
|A _cluster_ is a set of nodes ...          | A "cluster" is a set of nodes ...
|These components form the _control plane_. | These components form the **control plane**.

Use the `gloss` shortcode and add glossary entries for new terms.

## Use `back-ticks` around file names, directories, and paths

|Do                                   | Don't
|-------------------------------------|------
|Open the `foo.yaml` file.         | Open the foo.yaml file.
|Go to the `/content/en/docs/tasks` directory.  | Go to the /content/en/docs/tasks directory.
|Open the `/data/args.yaml` file. | Open the /data/args.yaml file.

## Use `back-ticks` around inline code and commands

|Do                          | Don't
|----------------------------|------
|The `foo run` command creates a `Deployment`. | The "foo run" command creates a `Deployment`.
|For declarative management, use `foo apply`. | For declarative management, use "foo apply".

Use code-blocks for commands you intend readers to execute. Only use inline code
and commands to mention specific labels, flags, values, functions, objects,
variables, modules, or commands.

## Use `back-ticks` around object field names

|Do                                                               | Don't
|-----------------------------------------------------------------|------
|Set the value of the `ports` field in the configuration file. | Set the value of the "ports" field in the configuration file.
|The value of the `rule` field is a `Rule` object.           | The value of the "rule" field is a `Rule` object.
