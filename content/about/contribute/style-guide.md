---
title: Style Guide
description: Explains the dos and donts of writing Istio documentation.
weight: 70
aliases:
    - /docs/welcome/contribute/style-guide.html
    - /docs/reference/contribute/style-guide.html
---

This page provides content guidelines for the Istio documentation.
These are guidelines, not rules, so use your best judgment, and feel free to
propose changes to this document in a pull request.

## Formatting standards

### Use consistent capitalization

Don't split configuration type names into separate words and follow the original capitalization. For
example, use `IstioRoleBinding`, not `Istio Role Binding` or `istio role binding`.

### Use angle brackets for placeholders

Use angle brackets for placeholders. Tell the reader what a placeholder
represents.

1.  Display information about a pod:

    ```command
    $ kubectl describe pod <pod-name>
    ```

    where `<pod-name>` is the name of one of your pods.

### Use **bold** for user interface elements

|Do               |Don't
|-----------------|------
|Click **Fork**.  |Click "Fork".
|Select **Other**.|Select 'Other'.

### Use _italics_ to define or introduce new terms

|Do                                         |Don't
|-------------------------------------------|---
|A _cluster_ is a set of nodes ...          |A "cluster" is a set of nodes ...
|These components form the _control plane_. |These components form the **control plane**.

### Use `code` style for filenames, directories, and paths

|Do                                   | Don't
|-------------------------------------|------
|Open the `istio.yaml` file.         | Open the istio.yaml file.
|Go to the `/content/docs/tasks` directory.  | Go to the /content/docs/tasks directory.
|Open the `/data/args.yaml` file. | Open the /data/args.yaml file.

### Use `code` style for inline code and commands

|Do                          | Don't
|----------------------------|------
|The `kubectl run` command creates a `Deployment`.|The "kubectl run" command creates a `Deployment`.
|For declarative management, use `kubectl apply`.|For declarative management, use "kubectl apply".

### Use `code` style for object field names

|Do                                                               | Don't
|-----------------------------------------------------------------|------
|Set the value of the `ports` field in the configuration file. | Set the value of the "ports" field in the configuration file.
|The value of the `rule` field is a `Rule` object.           | The value of the "rule" field is a `Rule` object.

### Only capitalize the first letter of headings

For any headings, only apply an uppercase letter to the first word of the heading,
except if a word is a proper noun or an acronym.

|Do                      | Don't
|------------------------|-----
|Configuring rate limits | Configuring Rate Limits
|Using Envoy for ingress | Using envoy for ingress
|Using HTTPS             | Using https

## Terminology standards

Some standard terms we want to use consistently within the documentation for clarity.

### Envoy

We prefer to use “Envoy” as it’s a more concrete term than "proxy" and will resonate if used
consistently throughout the docs.

Synonyms:

- “Envoy sidecar” - ok
- “Envoy proxy” - ok
- “The Istio proxy” -- best to avoid unless you’re talking about advanced scenarios where another proxy might be used.
- “Sidecar”  -- mostly restricted to conceptual docs
- “Proxy -- only if context is obvious

Related Terms:

- Proxy agent  - This is a minor infrastructural component and should only show up in low-level detail documentation.
It is not a proper noun.

### Mixer

Mixer is a proper noun and should be used as such:

- “You configure Mixer by ….”
- “Mixer provides a standard vehicle for implementing organizational wide policy”

### Attributes

Not a proper noun but we should attempt to consistently use the term to describe inputs to Mixer and NOT use the term when talking about other
forms of configuration.

### Load balancing

No dash, it's *load balancing* not *load-balancing*.

### Service mesh

Not a proper noun. Use in place of service fabric.

### Service version

Use in the context of routing and multiple finer-grained versions of a service. Avoid using “service tags” or “service labels”
which are the mechanism to identify the service versions, not the thing itself.

## Best practices

### Use present tense

|Do                           | Don't
|-----------------------------|------
|This command starts a proxy. | This command will start a proxy.

Exception: Use future or past tense if it is required to convey the correct
meaning.

### Use active voice

|Do                                         | Don't
|-------------------------------------------|------
|You can explore the API using a browser.   | The API can be explored using a browser.
|The YAML file specifies the replica count. | The replica count is specified in the YAML file.

Exception: Use passive voice if active voice leads to an awkward construction.

### Use simple and direct language

Use simple and direct language. Avoid using unnecessary phrases, such as saying "please."

|Do                          | Don't
|----------------------------|------
|To create a `ReplicaSet`, ... | In order to create a `ReplicaSet`, ...
|See the configuration file. | Please see the configuration file.
|View the Pods.              | With this next command, we'll view the Pods.

### Address the reader as "you"

|Do                                     | Don't
|---------------------------------------|------
|You can create a `Deployment` by ...     | We'll create a `Deployment` by ...
|In the preceding output, you can see...| In the preceding output, we can see ...

### Create useful links

There are good hyperlinks, and bad hyperlinks. The common practice of calling links *here*  or *click here* are examples of
bad hyperlinks. Check out this excellent article explaining what makes a good hyperlink and try to keep these guidelines in
mind when creating or reviewing site content.

[Why “click here” is a terrible link, and what to write instead](http://stephanieleary.com/2015/05/why-click-here-is-a-terrible-link-and-what-to-write-instead/).

### Avoid using "we"

Using "we" in a sentence can be confusing, because the reader might not know
whether they're part of the "we" you're describing.

|Do                                        | Don't
|------------------------------------------|------
|Version 1.4 includes ...                  | In version 1.4, we have added ...
|Istio provides a new feature for ... | We provide a new feature ...
|This page teaches you how to use pods.    | In this page, we are going to learn about pods.

### Avoid jargon and idioms

Some readers speak English as a second language. Avoid jargon and idioms to help make their understanding easier.

|Do                    | Don't
|----------------------|------
|Internally, ...       | Under the hood, ...
|Create a new cluster. | Turn up a new cluster.

### Avoid statements about the future

Avoid making promises or giving hints about the future. If you need to talk about
an alpha feature, put the text under a heading that identifies it as alpha
information.

### Avoid statements that will soon be out of date

Avoid words like "currently" and "new." A feature that is new today might not be
considered new in a few months.

|Do                                  | Don't
|------------------------------------|------
|In version 1.4, ...                 | In the current version, ...
|The Federation feature provides ... | The new Federation feature provides ...

## What's next

- Learn about [creating a new documentation topic](/about/contribute/writing-a-new-topic/).

- Learn about [creating a documentation pull request](/about/contribute/creating-a-pull-request/).
