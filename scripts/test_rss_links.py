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

"""Exercise RSS URL rendering with both deployed and local Hugo base URLs."""

import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parent.parent


class URLParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        self.urls.extend(value for name, value in attrs if name in ("href", "src", "xlink:href"))


class RSSLinksTest(unittest.TestCase):
    def test_rendered_urls(self):
        for base_url in ("https://example.org/latest/", "https://example.org/", "/latest/", ""):
            with self.subTest(base_url=base_url), tempfile.TemporaryDirectory() as temporary:
                site = Path(temporary)
                (site / "layouts/partials").mkdir(parents=True)
                (site / "content/blog/post").mkdir(parents=True)
                shutil.copy(ROOT / "layouts/partials/rss_content.html", site / "layouts/partials/rss_content.html")
                (site / "hugo.toml").write_text(
                    '[outputs]\nhome = ["RSS"]\n[outputFormats.RSS]\nbaseName = "feed"\n'
                    '[markup.goldmark.renderer]\nunsafe = true\n')
                (site / "layouts/rss.xml").write_text(
                    '<rss><channel><link>{{ absURL "" }}</link>{{ range .Site.RegularPages }}<item>'
                    '<link>{{ .Permalink }}</link><description>{{ `<![CDATA[` | safeHTML }}'
                    '{{ partial "rss_content.html" . }}{{ `]]>` | safeHTML }}</description>'
                    '</item>{{ end }}</channel></rss>')
                prefix = urlsplit(base_url).path or "/"
                (site / "content/blog/post/index.md").write_text(
                    '---\ntitle: RSS URLs\n---\n'
                    '<a href="/news/example/">Site path</a>\n'
                    f'<img src="{prefix}blog/post/image.gif">\n'
                    f'<a href="{prefix}blog/post/file.pdf?download=1#page=2">File</a>\n'
                    '<a href="other/?a=1&amp;b=2#fragment">Page path</a>\n'
                    '<a href="#section">Fragment</a>\n'
                    '<img src="image.png">\n'
                    '<a href="//external.example/path">Protocol relative</a>\n'
                    '<a href="https://external.example/path">External</a>\n'
                    '<a href="mailto:example@example.org">Email</a>\n')
                for filename in ("image.gif", "file.pdf", "image.png"):
                    (site / "content/blog/post" / filename).write_bytes(b"RSS fixture")
                subprocess.run(["hugo", "--source", str(site), "--baseURL", base_url],
                               check=True, capture_output=True, text=True)
                feed = ET.parse(site / "public/feed.xml")
                site_url = feed.findtext("channel/link")
                post_url = feed.findtext("channel/item/link")
                parser = URLParser()
                parser.feed(feed.findtext("channel/item/description"))
                self.assertEqual(parser.urls, [
                    site_url + "news/example/", post_url + "image.gif",
                    post_url + "file.pdf?download=1#page=2", post_url + "other/?a=1&b=2#fragment",
                    post_url + "#section", post_url + "image.png",
                    ("https:" if urlsplit(base_url).scheme else "") + "//external.example/path",
                    "https://external.example/path", "mailto:example@example.org",
                ])
                for index in (1, 2, 5):
                    path = unquote(urlsplit(parser.urls[index]).path).removeprefix(prefix)
                    self.assertTrue((site / "public" / path).is_file(), parser.urls[index])
                self.assertEqual(self.check(site / "public").returncode, 0)

    def test_checker_rejects_unresolved_and_repeated_paths(self):
        for base_url, url in (
            ("https://example.org/latest/", "/news/example/"),
            ("https://example.org/latest/", "https://example.org/latest/latest/blog/image.gif"),
            ("/latest/", "/latest/latest/blog/image.gif"),
            ("/", "image.gif"),
            ("/", "#section"),
        ):
            with self.subTest(base_url=base_url, url=url), tempfile.TemporaryDirectory() as temporary:
                site = Path(temporary)
                (site / "feed.xml").write_text(
                    f'<rss><channel><link>{base_url}</link><item><description>'
                    f'<![CDATA[<a href="{url}">Link</a>]]></description></item></channel></rss>')
                self.assertNotEqual(self.check(site).returncode, 0)

    @staticmethod
    def check(directory):
        return subprocess.run([sys.executable, str(ROOT / "scripts/check_rss_links.py"), str(directory)],
                              capture_output=True, text=True)


if __name__ == "__main__":
    unittest.main()
