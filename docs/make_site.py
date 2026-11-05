"""Builds docs/index.html from HOWTO.md. Needs the Python package `markdown`."""
import os
import markdown

here = os.path.dirname(os.path.abspath(__file__))
text = open(os.path.join(here, '..', 'HOWTO.md'), encoding='utf-8').read()
text = text.replace('](docs/images/', '](images/')
body = markdown.markdown(text, extensions=['fenced_code', 'tables', 'sane_lists'])
page = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Build an Android app in Eiffel</title>
<link rel="stylesheet" href="css/style.css">
</head>
<body>
<main>
<p><a href="https://github.com/simple-eiffel/simple_phone_calc">simple_phone_calc on GitHub</a></p>
''' + body + '''
</main>
</body>
</html>
'''
open(os.path.join(here, 'index.html'), 'w', encoding='utf-8').write(page)
