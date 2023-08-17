#!/usr/bin/python

# Copyright Istio Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import sys
import re
import os
import yaml

linenum = 0
snipnum = 0
section = ""

current_snip = None
multiline_cmd = False
output_started = False
snippets = []
boilerplates = []  # Should be ordered to avoid non-deterministic results in `gencheck_istio`

HEADER = """#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          %s
####################################################################################################
"""

startsnip = re.compile(r"^(\s*){{< text (syntax=)?\"?(\w+)\"? .*>}}$")
boilerplate = re.compile(r"^\s*{{< boilerplate\s*\"?([a-zA-Z0-9-]+)\"? >}}$")
snippetid = re.compile(r"snip_id=(\w+)")
githubfile = re.compile(r"^(.*)(?<![A-Za-z0-9])@([\w\.\-_/]+)@(.*)$")
execit = re.compile(r"^(.*kubectl exec.*) -it (.*)$")
heredoc = re.compile(r"<<\s*\\?EOF")
sectionhead = re.compile(r"^##+ ([^{]*)({.*})?$")
invalidchar = re.compile(r"[^0-9a-zA-Z_]")

parser = argparse.ArgumentParser()
parser.add_argument("markdown", help="markdown file from which snippets are extracted")
parser.add_argument("-d", "--snipdir", help="output directory for extracted snippets, default=markdown directory")
parser.add_argument("-p", "--prefix", help="prefix for each snippet, default=snip", default="snip")
parser.add_argument("-f", "--snipfile", help="name of the output snippet file")
parser.add_argument("-b", "--boilerplatedir", help="directory containing boilerplate snippets")
args = parser.parse_args()

markdown = args.markdown
snipdir = args.snipdir if args.snipdir else os.path.dirname(markdown)
snipprefix = args.prefix if args.prefix else "snip"
boilerplatedir = args.boilerplatedir if args.boilerplatedir else None

if args.snipfile:
    snipfile = args.snipfile
else:
    snipfile = "snips.sh" if markdown.split('/')[-1] == "index.md" else markdown.split('/')[-1] + "_snips.sh"

print("generating snips: " + os.path.join(snipdir, snipfile))

with open("data/args.yml", 'r') as stream:
    docs_config = yaml.safe_load(stream)

try:
    source_branch_name = docs_config['source_branch_name']
    istio_version = docs_config['version']
    istio_full_version = docs_config['full_version']
    istio_previous_version = docs_config['previous_version']
    istio_full_version_revision = istio_full_version.replace(".", "-")
    istio_previous_version_revision = istio_previous_version.replace(".", "-")
    k8s_gateway_api_version = docs_config['k8s_gateway_api_version']
except:
    sys.stderr.write('failed to retrieve data from "data/args.yml"\n')
    sys.exit(1)

with open(markdown, 'rt', encoding='utf-8') as mdfile:
    for line in mdfile:
        linenum += 1

        # Replace github file token with release-specific URL.
        github_url = "https://raw.githubusercontent.com/istio/istio/" + source_branch_name
        line = line.replace("{{< github_file >}}", github_url)
        line = line.replace("istioctl install", "istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true")

        match = sectionhead.match(line)
        if match:
            snipnum = 0
            section = invalidchar.sub('', match.group(1).strip().replace(" ", "_")).lower()
            continue

        match = startsnip.match(line)
        if match:
            snipnum += 1
            indent = match.group(1)
            kind = match.group(3)
            match = snippetid.search(line)
            if match:
                if match.group(1) == "none":
                    continue
                id = snipprefix + "_" + match.group(1)
            else:
                id = "%s_%s_%d" % (snipprefix, section, snipnum)
            if kind == "bash":
                script = "\n%s() {\n" % id
            else:
                script = "\n! read -r -d '' %s <<\ENDSNIP\n" % id
            current_snip = {"start": linenum, "id": id, "kind": kind, "indent": indent, "script": ["", script]}
            snippets.append(current_snip)
            continue

        match = boilerplate.match(line)
        if match:
            name = match.group(1)
            if not os.path.isfile(f'{boilerplatedir}/{name}.sh'):
                print(f"--> boilerplate {name} does not have snippets")
                continue
            if not name in boilerplates:
                boilerplates.append(name)
            continue

        if current_snip != None:
            if current_snip["indent"] and line.startswith(current_snip["indent"]):
                _, line = line.split(current_snip["indent"], 1)
            if "{{< /text >}}" in line:
                if current_snip["kind"] == "bash" and not output_started:
                    script = "}\n"
                else:
                    script = "ENDSNIP\n"
                current_snip["script"].append(script)
                current_snip = None
                multiline_cmd = False
                output_started = False
            else:
                if current_snip["kind"] == "bash":
                    if line.startswith("$ "):
                        line = line[2:]
                    else:
                        if multiline_cmd:
                            if line == "EOF\n":
                                multiline_cmd = False
                        elif not current_snip["script"][-1].endswith("\\\n"):
                            # command output
                            if not output_started:
                                current_snip["script"].append("}\n\n! read -r -d '' %s_out <<\ENDSNIP\n" % id)
                                output_started = True
                    while True:
                        match = githubfile.match(line)
                        if not match:
                            break
                        line = match.group(1) + match.group(2) + match.group(3) + "\n"
                    match = execit.match(line)
                    if match:
                        msg = "ERROR: 'kubectl exec -it' will not work in test environment. Please remove -it from .md line: " + str(linenum)
                        line = line + ">>> %s\n" % msg
                        print("    " + msg)
                    if heredoc.search(line):
                        multiline_cmd = True
                line = line.replace("{{< istio_version >}}", istio_version)
                line = line.replace("{{< istio_full_version >}}", istio_full_version)
                line = line.replace("{{< istio_previous_version >}}", istio_previous_version)
                line = line.replace("{{< istio_full_version_revision >}}", istio_full_version_revision)
                line = line.replace("{{< istio_previous_version_revision >}}", istio_previous_version_revision)
                line = line.replace("{{< k8s_gateway_api_version >}}", k8s_gateway_api_version)
                current_snip["script"].append(line)

if len(boilerplates) > 0:
    if boilerplatedir is None:
        print("boilerplate snippet directory is not defined. Use -b option to specify it")
        sys.exit(1)

if len(snippets) == 0 and len(boilerplates) == 0:
    print("--> no snippet or boilerplate. skipping..")
    sys.exit(0)

with open(os.path.join(snipdir, snipfile), 'w', encoding='utf-8') as f:
    f.write(HEADER % markdown.split("content/en/")[1] if "content/en/" in markdown else markdown)

    # There is an assumption here that boilerplate snippets generated
    # would be named <boilerplate-name>.sh. See scripts/gen_snip.sh
    # for generating all snippets. There is some coupling between the two.
    for bp in boilerplates:
        boilerplate_snippets = f'{boilerplatedir}/{bp}.sh'
        source_line = f'source "{boilerplate_snippets}"\n'
        f.write(source_line)

    for snippet in snippets:
        lines = snippet["script"]
        for line in lines:
            f.write(line)
