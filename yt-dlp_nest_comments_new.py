#!/usr/bin/env python3
 
"""
SPDX-License-Identifier: MIT https://opensource.org/licenses/MIT
Copyright c 2021 pukkandan.ytdlp@gmail.com
 
 
* Input file is an info.json (with comments) that yt-dlp (https://github.com/yt-dlp/yt-dlp) wrote
* Change FIELDS according to your needs
 
The output file will be in the format:
[{
  'text': 'comment 1',
  ...
  'replies': [{
    'text': 'reply 1',
    ...
    'replies': [...],
  }, ...],
}, ...]
"""
 
import os.path
import json
import argparse
from datetime import datetime
 
 
def get_fields(dct):
    for name, fn in FIELDS.items():
        val = fn(dct, name)
        if val is not None:
            yield name, val
 
 
def filter_func(comments):
    return [dict(get_fields(c)) for c in comments]
 
 
FIELDS = {
    'text': dict.get,
    'author': dict.get,
    'timestamp': lambda dct, name: dct.get(name) and datetime.strftime(
        datetime.utcfromtimestamp(dct.get(name)), '%Y/%m/%d'),
    # Add more fields here
    'replies': lambda dct, name: filter_func(dct.get(name, [])) or None
}
 
 
parser = argparse.ArgumentParser()
parser.add_argument(
    '--input-file', '-i',
    dest='inputfile', metavar='FILE', required=True,
    help='File to read video metadata from (info.json)')
parser.add_argument(
    '--output-file', '-o',
    dest='outputfile', metavar='FILE', required=True,
    help='File to write comments to (json / html)')
args = parser.parse_args()
 
 
ext = os.path.splitext(args.outputfile)[1][1:]
if ext == 'html':  # Error early
    try:
        from json2html import json2html
    except ImportError:
        raise SystemExit('ERROR: json2html is required for html output. Install it with  pip install json2html')
elif ext != 'json':
    raise SystemExit(f'ERROR: Only json and html formats are supported, not {ext}')
 
 
print('Reading file')
with open(args.inputfile, encoding='utf-8') as f:
    info_dict = json.load(f)
 
comment_data = {c['id']: c for c in sorted(
       info_dict['comments'], key=lambda c: c.get('timestamp') or 0, reverse=True)}
   
count = len(info_dict['comments'])
del info_dict
nested_comments = []
for i, (cid, c) in enumerate(comment_data.items(), 1):
    print(f'Processing comment {i}/{count}', end='\r')
    parent = nested_comments if c['parent'] == 'root' else comment_data[c['parent']].setdefault('replies', [])
    parent.append(c)
del parent
 
 
print('')
nested_comments = filter_func(nested_comments)
 
 
if ext == 'json':
    print('Converting to json')
    out = json.dumps(nested_comments, indent=4, ensure_ascii=False)
 
 
elif ext == 'html':
    print('Converting to html')
    out = json2html.convert(nested_comments)
 
 
del nested_comments
del comment_data
print('Writing file')
with open(args.outputfile, 'w', encoding='utf-8') as f:
    f.write(out)
print('Done')