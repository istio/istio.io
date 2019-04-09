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
import linecache
import string
import sys
import os
import re

from ruamel import yaml

#
# Reads a documented Helm values.yaml file and produces a
# MD formatted table.  pip install ruamel to obtain the proper
# YAML decoder.  ruamel maintains ordering and comments.  The
# comments are needed in order to decode the commented helm
# values.yaml file
#
ISTIO_CONFIG_DIR = "istio/install/kubernetes/helm/istio"
YAML_CONFIG_DIR = ISTIO_CONFIG_DIR + "/charts"
VALUES_YAML = "values.yaml"
ISTIO_IO_DIR = os.path.abspath(__file__ + "/../../")
CONFIG_INDEX_DIR = "content/docs/reference/config/installation-options/index.md"

def endOfTheList(context, lineNum, lastLineNum, totalNum):
    flag = 0
    valueList = []
    nextLineNum = lineNum + 1
    currentLine = context[lastLineNum]
    whitespaces = (len(currentLine) - len(currentLine.lstrip())) / 2

    if lineNum != lastLineNum:
        return False, valueList

    for nextLineNum in range(lineNum + 1, totalNum):
        nextLine = context[nextLineNum]

        if  len(nextLine.lstrip()) != 0 and '#' != nextLine.lstrip()[0] and ':' in nextLine:
            if whitespaces >= (len(nextLine) - len(nextLine.lstrip())) / 2:
                if flag == 0:
                    valueList.append(currentLine.split(':', 1)[1].strip())
                return True, valueList
            else:
                return True, valueList
        elif len(nextLine.lstrip()) != 0 and '#' !=  nextLine.lstrip()[0] and ':' not in nextLine and len(nextLine.strip()) != 0:
            value = nextLine.replace(' ', '')
            valueList.append(value.lstrip('-').strip())
            flag += 1;
        nextLineNum += 1

    if lastLineNum == totalNum - 1 and len(currentLine.lstrip()) != 0 and '#' != currentLine.lstrip()[0]:
        valueList.append(currentLine.split(':', 1)[1].strip())

    return True, valueList

prdict = collections.defaultdict(list)

def decode_helm_yaml(s):
    ret_val = ''
    #
    # Iterate through all the directories under /istio/install/kubernetes/heml/subcharts 
    # and process the configuration options from the respective values.yaml. The
    # configuration option name is the name of the directory that contains values.yaml.
    # This name will be passed in to the the function process_helm_yaml
    #
    subchart_dir = os.path.join(ISTIO_IO_DIR, YAML_CONFIG_DIR)
    for cfile in os.listdir(subchart_dir):
        values_yaml_dir = os.path.join(subchart_dir, cfile)
        values_yaml_file = os.path.join(values_yaml_dir, VALUES_YAML)
        process_helm_yaml(values_yaml_file, cfile)

    #
    # Process configuration options in values.yaml under istio/install/kubernetes/helm/istio.
    # The configuration option names are present in the values.yaml, hence we do not need to
    # pass it to process_helm_yaml.
    #
    istio_yaml_config_dir = os.path.join(ISTIO_IO_DIR, ISTIO_CONFIG_DIR)
    values_yaml_file = os.path.join(istio_yaml_config_dir, VALUES_YAML)
    process_helm_yaml(values_yaml_file, '')

    return ret_val

def process_helm_yaml(values_yaml, option):
        ret_val = ''
        storekey = ''
        desc = ''
        newkey = ''
        whitespaces = 0
        flag = 0
        lineNum = 0
        newConfigList = []
        loaded = None

        context = linecache.getlines(values_yaml)
        totalNum = len(context)
        lastLineNum = 0
        key = option
        
        count = 0
        with open(values_yaml, 'r') as f_v:
            d_v = f_v.read()
            loaded = yaml.round_trip_load(d_v)

        for lineNum in range(0, totalNum):
            if  context[lineNum].strip().startswith('- '):
                pass
            elif '#' in context[lineNum] and '#' == context[lineNum].lstrip()[0]:
                if "Description: " in context[lineNum]:
                    desc = context[lineNum].strip()
            elif ':' in context[lineNum] and '#' != context[lineNum].lstrip()[0]:
                lastLineNum = lineNum
                if flag == 1:
                    whitespaces = (len(context[lineNum]) - len(context[lineNum].lstrip())) / 2
                    periods = key.count('.')
                    if (option == ''):
                        while (whitespaces <= periods):
                            key = key.rstrip(string.ascii_letters[::-1] + string.digits + '_' + '-' + '/').rstrip('.')
                            whitespaces += 1
                    else:
                        while (whitespaces < periods) :
                            key = key.rstrip(string.ascii_letters[::-1] + string.digits + '_' + '-' + '/').rstrip('.')
                            whitespaces += 1
                        flag = 0

                key = key + '.' + context[lineNum].split(':', 1)[0].strip()
                isEnd, ValueList  = endOfTheList(context, lineNum, lastLineNum, totalNum)
                if isEnd == True:
                    flag = 1;

            storekey = key
            sk = storekey.split('.', 2)
            if len(sk) > 1:
                storekey = '.'.join(sk[:1]).lstrip('.')
            else:
                storekey = '.'.join(sk[:0]).lstrip('.')

            #
            # If we are processing the configurations options within the values.yaml under istio,
            # if the options have already been processed (from the subcharts directory), then we
            # do not want to process it again. If the configuration option has not been processed
            # before, then it is a new configuration option which needs to be processed (for e.g,
            # global, istiocoredns)
            #
            # option == '' - This condition means that we are looking at the values.yaml under the
            #                istio directory. Hence, the configuration option names will be inside
            #                the values.yaml file. (On the other hand, for the values.yaml file under
            #                the subcharts directory, we get the name of the configuration option
            #                from the name of the directories under the subcharts directory.)
            # newConfigList - This list is used to track configuration options in istio/values.yaml
            #                that haven't been processed before (or that does not have a corresponding
            #                directory under subcharts directory with values.yaml. E.g: global,
            #                istiocoredns)
            # 
            # This first condition checks that if this is the values.yaml file under istio directory,
            # and the configuration option to process (storekey) has not already been processed (this
            # conditions: "prdict.get(storekey) != None and (storekey in newConfigList)" together
            # makes sure that the condition where some parameters for a new configuration option like
            # 'global' has been processed and entered into the dictionary 'prdict' is still processed
            # because it is in the newConfigList. If a configuration option was processed from
            # the values.yaml under the subcharts directory, it will not be in the newConfigList.
            # subcharts directory), then go ahead and process the parameters for this option.
            # 
            if option == '' and prdict.get(storekey) != None and (storekey in newConfigList):
                pass
            #
            # This second condition checks if this is the values.yaml file under istio directory, and
            # the configuration option to process (storekey) has not been processed (this could
            # happen the first time we read a configuration option from the istio/values.yaml file),
            # then add this configuration option to the newConfigList to mark it as an option that
            # needs to be processed.
            #
            elif option == '' and prdict.get(storekey) == None:
                newConfigList.append(storekey)
            #
            # This third condition checks if this is the values.yaml file under istio directory,
            # and the configuration option to process (storekey) has already been processed and if
            # this is not a new configuration option, (this could happen if we have already 
            # processed the corresponding values.yaml under the subcharts directory), then ignore
            # this configuration option and do not process the values in this file.
            #
            elif option == '' and prdict.get(storekey) != None:
                continue

            if  len(context[lastLineNum].lstrip()) != 0 and '#' != context[lastLineNum].lstrip()[0]:
                isEnd, ValueList  = endOfTheList(context, lineNum, lastLineNum, totalNum)

                if (isEnd == True):
                    flag = 1
                    keysplit = key.split('.')
                    for kv in keysplit:
                        if kv != '':
                            newkey = newkey + '.' + kv

                    newkey = newkey.lstrip('.')

                    # Filling Description Fields            
                    if ( "." in newkey):
                        plist = newkey.split('.')
                        da = None
                        for item in plist:
                            desc = ''
                            # If this is the same as the configuration option name, then 
                            # continue to the next key in the list
                            if item.rstrip() == option.rstrip():
                                continue
                            if da is None:
                                if loaded.ca.items:
                                    if item in loaded.ca.items:
                                        desc = processComments(loaded.ca.items[item])
                                da = loaded[item]
                            elif isinstance(da, dict):
                                if item in da.keys()[0]:
                                    commentTokens = da.ca.comment
                                    if commentTokens is not None:
                                        desc = processComments(commentTokens)
                                    
                                if da.ca.items:
                                    if item in da.ca.items:
                                        desc = desc + processComments(da.ca.items[item])
                                    da = da[item]
                                else:
                                    if item in da.keys():
                                        da = da.get(item)
                                    else:
                                        da = da.values()[0]
                                    
                    ValueStr = (' ').join(ValueList)
                    if ValueStr:
                        if (desc in ValueStr):
                            ValueStr= ValueStr.replace("#"+desc, "")
                            desc = desc.replace('`','')
                        desc = sanitizeValueStr(desc)
                        if desc.strip():
                            desc = '`' + desc.strip() + '`'
                        prdict[storekey].append("| `%s` | `%s` | %s |" % (newkey, ValueStr.rstrip(), desc))
                    desc = ''

                    key = newkey
                    newkey = ''
                    
            lineNum += 1
        return ret_val

def processComments(comments):
    description = ''
    for c in comments:
        if c is None:
            pass
        elif isinstance(c, list):
            for comment in c:
                if (comment is None):
                    pass
                else:
                    # We want to avoid including commented out key: value pairs in the values.yaml as
                    # part of the description/comments. For example: 
                    #    # minAvailable: 1
                    #    # maxUnavailable: 1
                    #    # - secretName: grafana-tls
                    #    sessionAffinityEnabled: false
                    # We do not want the commented out key-value pairs (minAvailable,maxUnavailable, secretName)
                    # to be included as part of the description for 'sessionAffinityEnabled'
                    # 
                    pattern = re.compile("#\s[-\s]*[\S]+:(?:\s(?!\S+:)\S+)*" )
                    groups = pattern.match(comment.value)
                    if groups:
                        description=''
                        break
                    if comment.value.endswith('\n\n'):
                        description=''
                    else:
                        if comment.value.rstrip() == '#':
                            continue
                        else:
                            description = description + comment.value.replace('`','').replace("#",'').rstrip()
        elif isinstance(c, yaml.Token):
            description = description + c.value.rstrip().replace("#",'')
    
    return description


def sanitizeValueStr(value):
    # We can include more special characters later if they need to
    # be escaped. For now just including the 'pipe' symbol appearing
    # in the value of a configuration option.
    # e.g: | `global.tracer.lightstep.secure` | `true     # example: true\|false` |  |
    # 
    # Without escaping the 'pipe' character, it was interpreting it as the end/start
    # of table column. Using the example above, without escaping the pipe symbol, it 
    # was interpreting it as:
    # | `global.tracer.lightstep.secure` | `true   # example: true |false` |  |
    #
    regex = re.compile("\|")
    if value != None and regex.search(value) != None:
        value = value.replace("|", "\|");
    return value
        
    
with open(os.path.join(ISTIO_IO_DIR, CONFIG_INDEX_DIR), 'r') as f:
    endReached = False

    data = f.read().split('\n')
    for d in data:
        print d
        if "<!-- AUTO-GENERATED-START -->" in d:
            break

    # transform values.yaml into a encoded string dictionary
    pyaml = yaml.YAML()
    pyaml.explicit_start = True
    pyaml.dump('', sys.stdout, transform=decode_helm_yaml)

    # Order the encoded string dictionary
    od = collections.OrderedDict(sorted(prdict.items(), key=lambda t: t[0]))

    # Print encoded string dictionary
    for k, v in od.items():
        print ("## `%s` options\n" % k)
        print '| Key | Default Value | Description |'
        print '| --- | --- | --- |'
        for value in v:
            print ('%s' % (value))
        print ('')

    for d in data:
        if "<!-- AUTO-GENERATED-END -->" in d:
            endReached = True
        if endReached:
            print d
