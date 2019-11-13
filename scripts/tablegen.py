#!/usr/bin/python

# Copyright 2017,2018 Istio Authors. All Rights Reserved.
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

import collections
from collections import deque
import requests
import os
import string
import sys

from jinja2 import Template
from ruamel.yaml import YAML

# Reads a documented Helm values.yaml file and produces a
# MD formatted table.  pip install ruamel to obtain the proper
# YAML decoder.  ruamel maintains ordering and comments.  The
# comments are needed in order to decode the commented helm
# values.yaml file

# An exercise for the reader is to clean up all of the sloppy try
# error catching clauses.

ISTIO_CONFIG_DIR = "install/kubernetes/helm/istio"
YAML_CONFIG_DIR = ISTIO_CONFIG_DIR + "/charts"
VALUES_YAML = "values.yaml"
CONFIG_INDEX_DIR = "content/en/docs/reference/config/installation-options/index.md"
ISTIO_REPO = "https://github.com/istio/istio.git@release-1.4"
ISTIO_LOCAL_REPO = "istio-repo"


prdict = collections.defaultdict(list)


def downloadIstioRepo():
    repoInfo = ISTIO_REPO.split('@')
    repo_url = repoInfo[0]
    repo_release = repoInfo[1]
    curl_command = "git clone --depth=1 -q -b %s %s %s"
    status = os.system(curl_command % (repo_release, repo_url, ISTIO_LOCAL_REPO))
    if status != 0:
        print("An error occured trying to clone Istio repo for release: %s." % releaseName)
        exit()


def deleteIstioRepo():
    os.system("rm -rf %s" % ISTIO_LOCAL_REPO)



def flatten(d, sep="."):
    obj = collections.OrderedDict()
    global global_lc
    global_lc = 0

    def recurse(t, parent_key=""):
#        if hasattr(t, 'lc'):
#            lc = int(t.lc.line)
        lc = global_lc

        if isinstance(t, list):
            for idx, k in enumerate(t):
                global_lc += 1
                recurse(k, parent_key=(parent_key + '[' + str(idx) + ']') if parent_key else str(idx))
        elif isinstance(t, dict):
            for k,v in t.items():
                global_lc += 1
                recurse(v, parent_key + sep + k if parent_key else k)
        else:
            obj[parent_key] = { 'value': t, 'line': lc }

    recurse(d)

    return obj


inp = """\
# example
name:
  # details
  family: Smith   # very common
  given: Alice    # one of the siblings
"""


# Read one helm values.yaml value
def read_helm_value_file(file, cfile):
    print("%s" % file)

    # Store key for this section
    if len(cfile):
        dictkey = cfile
        cfile = cfile + '.'
    else:
        dictkey = 'global.'


    # Iterate list of YAML parse event nodes converting to a queue of KV pairs with comments
    # intact. For every KV pair, I push the key and the value.  When I am ready to ouput, the
    # key and value pair are popped together and then stored in a string.
    yaml = YAML(typ='rt')
    with open(file, "r+") as f:
        new_f = f.readlines()
        f.seek(0)
        for line in new_f:
            if '#E' not in line:
                f.write(line)
        f.truncate()

    f = open(file, 'r')
    data = f.read()
    data = data.replace("[]", "")
    data = data.replace("{}", "")

    data = yaml.load(data)
    res = flatten(data)
    for k, v in res.items():
#        description = v['description']
        description = v['line']
        prdict[dictkey].append({'key': cfile + k, 'default': v['value'], 'description': description})
        print('{} {} {}'.format(cfile + k, v['value'], description))
    return


# Read all helm values.yaml files
def read_helm_value_files():
    #
    # Iterate through all the directories under /istio/install/kubernetes/helm/subcharts
    # and process the configuration options from the respective values.yaml. The
    # configuration option name is the name of the directory that contains values.yaml.
    # This name will be passed in to the the function process_helm_yaml
    #
    subchart_dir = os.path.join(ISTIO_LOCAL_REPO, YAML_CONFIG_DIR)
    for cfile in os.listdir(subchart_dir):
        values_yaml_dir = os.path.join(subchart_dir, cfile)
        values_yaml_file = os.path.join(values_yaml_dir, VALUES_YAML)
        read_helm_value_file(values_yaml_file, cfile)

    #
    # Process configuration options in values.yaml under istio/install/kubernetes/helm/istio.
    # The configuration option names are present in the values.yaml, hence we do not need to
    # pass it to process_helm_yaml.
    #
    istio_yaml_config_dir = os.path.join(ISTIO_LOCAL_REPO, ISTIO_CONFIG_DIR)
    values_yaml_file = os.path.join(istio_yaml_config_dir, VALUES_YAML)
    read_helm_value_file(values_yaml_file, '')


# Jinja2 template
html = '''
<table>
    <thead>
    <tr>
        <th>Key</th>
        <th>Default Value</th>
        <th>Description</th>
    </tr>
    </thead>
    <tbody>
{% for output in values %}
            <tr>
                <td>{{ output["key"] }}</td>
                <td>{{ output["default"] }}</td>
                <td>{{ output["description"] }}</td>
            </tr>
{% endfor %}
    </tbody>
</table>

'''


def main():
    # HTML template
    template = Template(html)

#    downloadIstioRepo()

#    read_helm_value_files()

    read_helm_value_file('istio-repo/install/kubernetes/helm/istio/charts/gateways/values.yaml', 'gateways')

    od = collections.OrderedDict(sorted(prdict.items(), key=lambda t: t[0]))

    index_file = open(CONFIG_INDEX_DIR, 'r+')

    meta = ''
    for d in index_file:
        meta = meta + d
        if "<!-- AUTO-GENERATED-START -->" in d:
            break

    index_file.seek(0)
    index_file.write(meta)

    # Print encoded string dictionary
    for k, v in od.items():
        index_file.write("## `%s` options\n" % k)
        out = template.render(values=v)
        index_file.write(out)
        index_file.write('\n')

    index_file.write("\n<!-- AUTO-GENERATED-END -->\n")
    index_file.truncate()
    index_file.close()

#    deleteIstioRepo()


if __name__ == "__main__":
    main()
