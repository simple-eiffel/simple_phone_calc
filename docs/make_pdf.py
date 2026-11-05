"""Builds docs/simple_phone_calc_howto.pdf from HOWTO.md, with headless Edge.

Needs the Python packages markdown, pygments and pymupdf, and Microsoft Edge.
"""
import os
import re
import subprocess
import tempfile

import fitz
import markdown
from pygments.formatters import HtmlFormatter
from pygments.style import Style
from pygments.token import Comment, Keyword, Name, Number, Operator, String, Text

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'simple_phone_calc_howto.pdf')
EDGE = r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
BACKGROUND = (20 / 255, 22 / 255, 28 / 255)
MUTED = (168 / 255, 164 / 255, 150 / 255)


class Dark(Style):
    background_color = '#20232C'
    styles = {
        Text: '#ECE7DA',
        Comment: 'italic #A8A496',
        Keyword: 'bold #E8C36A',
        Keyword.Type: '#E8C36A',
        Name: '#ECE7DA',
        Name.Class: 'bold #9CC4E4',
        Name.Function: '#ECE7DA',
        Number: '#F2B8B5',
        String: '#A9D5A0',
        Operator: '#D8D3C6',
    }


CSS = '''
@page { size: Letter; margin: 0.8in 0.85in 0.85in 0.85in; }
@page :first { margin: 0; }
html, body { margin: 0; padding: 0; background: transparent; }
body { color: #ECE7DA; font-family: "Segoe UI", sans-serif; font-size: 10.6pt; line-height: 1.55;
       -webkit-print-color-adjust: exact; print-color-adjust: exact; }
.cover { height: 11in; width: 8.5in; position: relative; overflow: hidden; break-after: page; }
.cover .band { position: absolute; left: 0; top: 0; bottom: 0; width: 0.28in; background: #E8C36A; }
.cover .words { position: absolute; left: 0.95in; top: 1.15in; width: 3.75in; }
.cover .kicker { color: #E8C36A; font-size: 11pt; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; }
.cover h1 { display: block; font-size: 40pt; line-height: 1.08; margin: 0.28in 0 0.3in; color: #ECE7DA; font-weight: 600; }
.cover .sub { font-size: 14.5pt; color: #D8D3C6; line-height: 1.4; }
.cover .note { margin-top: 0.4in; font-size: 10.5pt; color: #A8A496; line-height: 1.6; }
.cover .foot { position: absolute; left: 0.95in; bottom: 0.8in; color: #A8A496; font-size: 10pt; }
.cover .phone { position: absolute; right: 0.6in; top: 1.15in; width: 2.75in; padding: 0.12in; background: #2A2E38; border-radius: 0.3in; }
.cover .phone img { width: 100%; display: block; border-radius: 0.2in; }
.toc { break-after: page; }
.toc h2 { border: 0; margin-top: 0; }
.toc ol { list-style: none; padding: 0; margin: 0.2in 0 0; }
.toc li { display: flex; align-items: baseline; padding: 6pt 0; border-bottom: 1px solid #2A2E38; font-size: 11.5pt; }
.toc a { color: #ECE7DA; text-decoration: none; flex: 1; }
.toc .n { color: #E8C36A; font-weight: 600; }
h1 { display: none; }
h2 { color: #E8C36A; font-size: 19pt; font-weight: 600; line-height: 1.2; margin: 0.42in 0 0.12in; padding-bottom: 5pt;
     border-bottom: 1px solid #454A58; break-after: avoid; }
h3 { color: #ECE7DA; font-size: 13pt; font-weight: 600; margin: 0.25in 0 0.06in; break-after: avoid; }
p { margin: 0 0 8pt; orphans: 3; widows: 3; }
p:has(+ .codehilite), p:has(+ figure), p:has(+ ul), p:has(+ ol) { break-after: avoid; }
ul, ol { margin: 0 0 9pt; padding-left: 0.24in; }
li { margin-bottom: 3pt; }
a { color: #E8C36A; }
strong { color: #F3EEE2; font-weight: 600; }
code { font-family: Consolas, monospace; font-size: 9.3pt; background: #20232C; padding: 0.5pt 3pt; border-radius: 3pt; color: #F0DDA8; }
.codehilite { background: #20232C; border-left: 3pt solid #E8C36A; border-radius: 4pt; padding: 7pt 10pt; margin: 0 0 11pt; break-inside: avoid; }
.codehilite pre { margin: 0; white-space: pre-wrap; font-family: Consolas, monospace; font-size: 8.9pt; line-height: 1.42; color: #ECE7DA; }
.codehilite code, pre code { background: none; padding: 0; color: inherit; font-size: inherit; }
pre { margin: 0; }
table { width: 100%; border-collapse: collapse; margin: 0 0 11pt; font-size: 9.8pt; break-inside: avoid; }
th { color: #E8C36A; text-align: left; font-weight: 600; border-bottom: 1.5pt solid #454A58; padding: 4pt 6pt; }
td { border-bottom: 1px solid #2A2E38; padding: 4pt 6pt; vertical-align: top; }
figure { margin: 8pt 0 13pt; break-inside: avoid; text-align: center; }
figure img { max-width: 100%; max-height: 5.4in; border-radius: 6pt; }
figcaption { color: #A8A496; font-size: 9.2pt; margin-top: 5pt; }
'''


def body_html():
    text = open(os.path.join(HERE, '..', 'HOWTO.md'), encoding='utf-8').read()
    text = re.sub(r'^!\[The calculator\].*\n', '', text, flags=re.M)
    text = re.sub(r'^\*\*Prefer paper.*\n', '', text, flags=re.M)
    html = markdown.markdown(text, extensions=['fenced_code', 'tables', 'sane_lists', 'codehilite'],
                             extension_configs={'codehilite': {'guess_lang': False, 'noclasses': False}})
    html = re.sub(r'<p><img alt="([^"]*)" src="docs/images/([^"]+)" ?/?></p>\s*<p><em>(.*?)</em></p>',
                  lambda m: '<figure><img alt="%s" src="images/%s"><figcaption>%s</figcaption></figure>' % m.groups(), html, flags=re.S)
    sections = []

    def anchor(match):
        sections.append(match.group(1))
        return '<h2 id="s%d">%s</h2>' % (len(sections), match.group(1))

    return re.sub(r'<h2>(.*?)</h2>', anchor, html), sections


def page_html(body, sections, pages):
    rows = ''.join('<li><a href="#s%d">%s</a><span class="n">%s</span></li>' % (i + 1, s, pages.get(i + 1, ''))
                   for i, s in enumerate(sections))
    cover = '''<div class="cover"><div class="band"></div>
<div class="words"><div class="kicker">Simple Eiffel</div>
<h1>Build an Android app in Eiffel</h1>
<div class="sub">From an empty folder to a calculator on a phone.</div>
<div class="note">You write Eiffel and nothing else: no Java, no Kotlin, no XML layouts, no Gradle.</div></div>
<div class="phone"><img src="images/calculator.png" alt="The calculator"></div>
<div class="foot">simple_phone_calc 1.0.0 &nbsp;&middot;&nbsp; github.com/simple-eiffel/simple_phone_calc</div></div>'''
    toc = '<div class="toc"><h2>Contents</h2><ol>%s</ol></div>' % rows
    pygments_css = HtmlFormatter(style=Dark).get_style_defs('.codehilite')
    return ('<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Build an Android app in Eiffel</title><style>'
            + CSS + pygments_css + '.codehilite { background: #20232C; }</style></head><body>' + cover + toc + body + '</body></html>')


def render(html, target):
    source = os.path.join(HERE, '_print.html')
    open(source, 'w', encoding='utf-8').write(html)
    with tempfile.TemporaryDirectory() as profile:
        subprocess.run([EDGE, '--headless=new', '--disable-gpu', '--no-pdf-header-footer', '--no-first-run',
                        '--user-data-dir=' + profile, '--virtual-time-budget=8000',
                        '--print-to-pdf=' + target, 'file:///' + source.replace(os.sep, '/')],
                       check=True, capture_output=True, timeout=120)
    os.remove(source)


def section_pages(path, sections):
    doc = fitz.open(path)
    found = {}
    for i, title in enumerate(sections):
        plain = re.sub(r'<[^>]+>', '', title).replace('&amp;', '&')
        for n in range(2, doc.page_count):
            if plain in doc[n].get_text():
                found[i + 1] = n + 1
                break
    doc.close()
    return found


def finish(path, sections, pages):
    doc = fitz.open(path)
    for n, page in enumerate(doc):
        page.draw_rect(page.rect, color=None, fill=BACKGROUND, overlay=False)
        if n > 0:
            page.insert_text((page.rect.width - 72, page.rect.height - 34), str(n + 1), fontname='helv', fontsize=9, color=MUTED)
            page.insert_text((61, page.rect.height - 34), 'Build an Android app in Eiffel', fontname='helv', fontsize=8.5, color=MUTED)
    doc.set_metadata({'title': 'Build an Android app in Eiffel', 'author': 'Larry Rix',
                      'subject': 'simple_phone_calc: from an empty folder to a calculator on a phone',
                      'creator': 'simple_phone_calc docs/make_pdf.py', 'producer': ''})
    doc.set_toc([[1, re.sub(r'<[^>]+>', '', s), pages[i + 1]] for i, s in enumerate(sections) if i + 1 in pages])
    doc.save(OUT, garbage=4, deflate=True)
    doc.close()


def main():
    body, sections = body_html()
    with tempfile.TemporaryDirectory() as work:
        first = os.path.join(work, 'first.pdf')
        render(page_html(body, sections, {}), first)
        pages = section_pages(first, sections)
        second = os.path.join(work, 'second.pdf')
        render(page_html(body, sections, pages), second)
        finish(second, sections, section_pages(second, sections))
    print('wrote', os.path.basename(OUT), len(sections), 'sections')


main()
