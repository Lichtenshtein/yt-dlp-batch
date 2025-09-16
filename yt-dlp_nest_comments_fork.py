#!/usr/bin/env python3

import warnings
warnings.filterwarnings('ignore')

"""
Forked and modified from pukkandan/ytdlp_nest_comments.py:
https://gist.github.com/pukkandan/ee737fec64822f2552caf3ca4cbf5db7
which included this license and copyright information:
"SPDX-License-Identifier: MIT https://opensource.org/licenses/MIT
Copyright © 2021 pukkandan.ytdlp@gmail.com"

Convert YouTube comments from an info.json file (acquired via
yt-dlp --write-comments) to HTML.
"""

import os.path
import json
import argparse
import logging
from datetime import datetime
import html

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

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
    help='File to write comments to (html)')
args = parser.parse_args()

ext = os.path.splitext(args.outputfile)[1][1:]
if ext != 'html':
    raise SystemExit(f'ERROR: Only html format is supported, not {ext}')

logging.info('Reading file')
try:
    with open(args.inputfile, encoding='utf-8') as f:
        info_dict = json.load(f)
except FileNotFoundError:
    logging.error(f'File {args.inputfile} not found')
    raise
except json.JSONDecodeError:
    logging.error(f'Error decoding JSON from file {args.inputfile}')
    raise

comment_data = {c['id']: c for c in sorted(
    info_dict['comments'], key=lambda c: c.get('timestamp') or 0)}
count = len(info_dict['comments'])
nested_comments = []
for i, (cid, c) in enumerate(comment_data.items(), 1):
    logging.info(f'Processing comment {i}/{count}')
    parent = nested_comments if c['parent'] == 'root' else comment_data[c['parent']].setdefault('replies', [])
    parent.append(c)

nested_comments = filter_func(nested_comments)

logging.info('Converting to html')

def wrap_html(data, top_level=True):
    html_content = '<ul>'
    for comment in data:
        author = html.escape(comment.get("author", "Anonymous"))
        text = html.escape(comment["text"]).replace('\n', '<br>')  # Convert newlines to <br>
        timestamp = html.escape(comment.get("timestamp", ""))

        html_content += f'<li><div class="comment-box">'
        html_content += f'<p><strong>{author}:</strong> <div class="comment-text">{text}</div></p>'  # Wrap text in div with a class for styling
        if timestamp:
            html_content += f'<p><small>{timestamp}</small></p>'
        if 'replies' in comment and comment['replies']:
            html_content += wrap_html(comment['replies'], top_level=False)
        html_content += '</div></li>'
    html_content += '</ul>'

    if top_level:
        style = '''
        <style>
            .comment-box {
                border: 1px solid #ccc;
                padding: 10px;
            }
            .comments ul {
                list-style-type: none;
                padding-left: 10px;
            }
            .comment-text {
                white-space: pre-wrap; /* Preserve whitespace and line breaks */
            }
            @media (prefers-color-scheme: dark) {
                body {
                    background-color: #121212;
                    color: #e0e0e0;
                }
                .comment-box {
                    border-color: #444;
                }
            }
        </style>
        '''
        meta = '<meta charset="UTF-8">'
        return f'{meta}{style}<div class="comments">{html_content}</div>'
    return html_content

out = wrap_html(nested_comments)

logging.info('Writing file')
try:
    with open(args.outputfile, 'w', encoding='utf-8') as f:
        f.write(out)
    logging.info('Done')
except IOError as e:
    logging.error(f'Error writing to file {args.outputfile}: {e}')
    raise