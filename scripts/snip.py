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
snippetid = re.compile(r"snip_id=(\w+)")
githubfile = re.compile(r"^(.*)(?<![A-Za-z0-9])@([\w\.\-_/]+)@(.*)$")
execit = re.compile(r"^(.*kubectl exec.*) -it (.*)$")
heredoc = re.compile(r"<<\s*\\?EOF")
sectionhead = re.compile(r"^##+ (.*)$")
invalidchar = re.compile(r"[^0-9a-zA-Z_]")

if len(sys.argv) < 2:
    print("usage: python snip.py mdfile [ snipdir ]")
    sys.exit(1)

markdown = sys.argv[1]

if len(sys.argv) > 2:
    snipdir = sys.argv[2]
else:
    snipdir = os.path.dirname(markdown)

snipfile = "snips.sh" if markdown.split('/')[-1] == "index.md" else markdown.split('/')[-1] + "_snips.sh"

print("generating snips: " + os.path.join(snipdir, snipfile))

with open("data/args.yml", 'r') as stream:
    docs_config = yaml.safe_load(stream)

try:
    source_branch_name = docs_config['source_branch_name']
except:
    sys.stderr.write('"source_branch_name" not defined in "data/args.yml"\n')
    sys.exit(1)

with open(markdown, 'rt', encoding='utf-8') as mdfile:
    for line in mdfile:
        linenum += 1

        # Replace github file token with release-specific URL.
        github_url = "https://raw.githubusercontent.com/istio/istio/" + source_branch_name
        line = line.replace("{{< github_file >}}", github_url)

        match = sectionhead.match(line)
        if match:
            snipnum = 0
            section = invalidchar.sub('', match.group(1).replace(" ", "_")).lower()
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
                id = "snip_" + match.group(1)
            else:
                id = "snip_%s_%d" % (section, snipnum)
            if kind == "bash":
                script = "\n%s() {\n" % id
            else:
                script = "\n! read -r -d '' %s <<\ENDSNIP\n" % id
            current_snip = {"start": linenum, "id": id, "kind": kind, "indent": indent, "script": ["", script]}
            snippets.append(current_snip)
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
                        print("    WARNING: -it should be removed from kubectl exec of .md line: " + str(linenum))
                    if heredoc.search(line):
                        multiline_cmd = True
                current_snip["script"].append(line)

with open(os.path.join(snipdir, snipfile), 'w', encoding='utf-8') as f:
    f.write(HEADER % markdown.split("content/en/")[1] if "content/en/" in markdown else markdown)
    for snippet in snippets:
        lines = snippet["script"]
        for line in lines:
            f.write(line)
