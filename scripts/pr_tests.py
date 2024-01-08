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
import os
import re
from github import Github


def get_script_dependencies(script_path, folder_prefix):
    dependencies = set()
    with open(script_path, 'r') as script_file:
        script_content = script_file.read()

        # Using regular expression to find 'source' followed by a script path
        pattern = r'^source\s+["\']?(.+?)["\']?$'
        matches = (match for match in re.findall(pattern, script_content, re.MULTILINE) if match.startswith(folder_prefix))
        dependencies.update(matches)

    return dependencies


def get_script_dependencies_graph(path_prefix, file_suffix="test.sh"):
    matching_files = [os.path.join(root, file_name) for root, _, files in os.walk(path_prefix) for file_name in files if file_name.endswith(file_suffix)]
    package_dependencies = {}

    for file in matching_files:
        dependencies = get_script_dependencies(file, path_prefix)
        for dep in dependencies:
            dep = os.path.dirname(dep)
            package_dependencies.setdefault(dep, set()).add(os.path.dirname(file))

    return package_dependencies


istio_doc_repo = "istio/istio.io"
doc_file_prefix = "content/en/docs/"
boilerplate_snip_prefix = "content/en/boilerplates/snips/"
istio_go_dependency = "go.mod"
test_framework_pkg = "pkg/test/"
test_framework_util = "tests/"
prow_dir = "prow/"

parser = argparse.ArgumentParser()
parser.add_argument("pull_number", help="pull request to get modified files from")
parser.add_argument("-r", "--repo", help="public repo containing the pull request, default=istio/istio.io")
parser.add_argument("-t", "--token", help="access token for the github repo")
args = parser.parse_args()

pull_number = int(args.pull_number)
repo_name = args.repo if args.repo else istio_doc_repo
access_token = args.token if args.token else None  # Warning: Github rate limit is very low (60 req/hr) without access token
script_dependencies = get_script_dependencies_graph(doc_file_prefix)
try:
    g = Github(access_token)
    repo = g.get_repo(repo_name)
    pr = repo.get_pull(pull_number)

    test_paths = set()

    commits = pr.get_commits()
    for commit in commits:
        files = commit.files
        for file in files:
            filename = file.filename
            if filename.startswith(doc_file_prefix):
                if filename.endswith("test.sh") or filename.endswith("/snips.sh"):
                    relative_file = filename[len(doc_file_prefix):]
                    test_paths.add(relative_file.rsplit('/', 1)[0])
                    # Tentatively add tests that externally imported other module files
                    checked = set()
                    to_check = {os.path.dirname(filename)}
                    while to_check:
                        el = to_check.pop()
                        checked.add(el)
                        if el in script_dependencies:
                            to_add = script_dependencies[el] - checked
                            to_check.update(to_add)
                            test_paths.update(map(lambda file_path: file_path[len(doc_file_prefix):], to_add))
            elif filename == istio_go_dependency or \
                    filename.startswith(test_framework_pkg) or \
                    filename.startswith(test_framework_util) or \
                    filename.startswith(prow_dir) or \
                    filename.startswith(boilerplate_snip_prefix):
                print("ALL")
                sys.exit(0)

    if len(test_paths) == 0:
        print("NONE")
    else:
        print(*test_paths, sep=",")

except Exception as e:
    # fall back to running all tests if anything goes wrong (e.g., rate-limiting)
    print("ALL")
    print("Exception: %s" % str(e), file=sys.stderr)
