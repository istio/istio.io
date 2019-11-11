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

from jinja2 import Template
from ruamel.yaml import YAML
from ruamel.yaml import events

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

prdict = dict()


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


prdict = collections.defaultdict(list)


# Turn a comment blob into a string
def sanitize_comment(comment):
    for cmt in comment:
        if cmt is None:
            continue
        # multiline comment
        if isinstance(cmt, list):
            return_string = ''
            for cmt2 in cmt:
                return_string = return_string + cmt2.value.lstrip('#')
            return(return_string)
        # single line comment
        else:
            return(cmt.value.lstrip('#'))


# Read one helm values.yaml value
def read_helm_value_file(file, cfile):
    comment = deque(list())
    key_queue = deque(list())
    cmt = ''

    print("%s" % file)
    f = open(file, 'r')

    # Store key for this section
    if len(cfile):
        key_queue.append(cfile)

    # Iterate list of YAML parse event nodes converting to a queue of KV pairs with comments
    # intact. For every KV pair, I push the key and the value.  When I am ready to ouput, the
    # key and value pair are popped together and then stored in a string.
    yaml = YAML(typ='rt')
    nodes = yaml.parse(f)

    key = True
    # The ordering of this loop is critical. Don't muck with it without understanding how
    # events are produced by ruamel's parser.
    for node in nodes:
        print(node)
        if hasattr(node, 'comment'):
            if node.comment is None:
                pass
            else:
                cmt = sanitize_comment(node.comment)
                if cmt is None:
                    pass
                else:
                    cmt.replace('{{', '{{ \'{{\' }}')
                    cmt.replace('}}', '{{ \'}}\' }}')
                    comment.append(cmt)
        if isinstance(node, events.SequenceStartEvent):
            key = True
        if isinstance(node, events.MappingStartEvent):
            key = True
        if isinstance(node, events.ScalarEvent):
            if hasattr(node, 'value'):
                key_queue.append(node.value)
            if key == False:
                value = key_queue.pop()
                try:
                    cmt = comment.popleft()
                except:
                    cmt = ''
                try:
                    dict_item = {'Key': '.'.join(key_queue), 'Default': value, 'Description': cmt}
                    print(dict_item)
                    if cfile=='':
                        prdict['global'].append(dict_item)
                    else:
                        prdict[cfile].append(dict_item)
                except:
                    pass
                if len(key_queue):
                    key_queue.pop()
                key = True
            elif key == True:
                key = False
        if isinstance(node, events.SequenceEndEvent):
            key = True
            if len(key_queue):
                key_queue.pop()
                pass
        if isinstance(node, events.MappingEndEvent):
            key = True
            if len(key_queue):
                key_queue.pop()


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
#'istio-repo/install/kubernetes/helm/istio/charts/galley', 'galley')


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
                <td>{{ output["Key"] }}</td>
                <td>{{ output["Default"] }}</td>
                <td>{{ output["Description"] }}</td>
            </tr>
{% endfor %}
    </tbody>
</table>

'''


def main():
    # HTML template
    template = Template(html)

    downloadIstioRepo()
#    read_helm_value_file('istio-repo/install/kubernetes/helm/istio/charts/galley/values.yaml', 'galley')

    read_helm_value_files()

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

    deleteIstioRepo()


if __name__ == "__main__":
    main()
