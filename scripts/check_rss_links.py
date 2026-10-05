#!/usr/bin/env python3

# Copyright Istio Authors
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

"""Check that RSS item links and images work without the website's context."""

import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit


class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.relative_urls = []

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in ("href", "src", "xlink:href") and value and not urlsplit(value).scheme:
                self.relative_urls.append(value)


def main():
    directory = Path(sys.argv[1] if len(sys.argv) > 1 else "public")
    feeds = sorted(directory.rglob("feed.xml"))
    if not feeds:
        sys.exit(f"No RSS feeds found in {directory}")

    failed = False
    for feed in feeds:
        parser = LinkParser()
        for item in ET.parse(feed).findall("channel/item"):
            parser.feed(item.findtext("description", ""))
        if parser.relative_urls:
            print(f"{feed}: {len(parser.relative_urls)} relative URLs, including {parser.relative_urls[:3]}")
            failed = True
    if failed:
        sys.exit(1)
    print(f"Checked absolute URLs in {len(feeds)} RSS feeds")


if __name__ == "__main__":
    main()
