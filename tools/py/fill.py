#!/usr/bin/env python3

import os
import os.path
import sys
import re
import argparse

HelpText = """
Replaces all {{var}} style templates with values found in args and optionally
with environment variables.
Acceptable variable names match the regex '[A-Za-z0-9_]+'.
"""

# TODO: Have it also read from a configuration file?

class TemplateFiller:

  VarRegex = re.compile(r'{{[A-Za-z0-9_]+}}')

  def __init__(self, lookupList, default=None):
    self.ll = lookupList
    self.foundCount = 0
    self.lineCount = 0
    self.notFound = []
    self.matchFn = lambda m: self.onMatch(m)
    self.default = default

  def onMatch(self, match):
    key = match[0][2:-2]
    for d in self.ll:
      if key in d:
        self.foundCount += 1
        return d[key]

    self.notFound.append((self.lineCount, key))
    return self.default if self.default else match[0]

  def fillLine(self, text):
    outline = re.sub(TemplateFiller.VarRegex, self.matchFn, text)
    self.lineCount += 1
    return outline

  def debugText(self):
    t = ['KeyValue Sources:']
    for i, l in enumerate(self.ll):
      t.append(f"{i}:")
      for k, v in l.items():
        t.append(f"\t{k} -> {v}")

    t.append(f"Found: {filler.foundCount}")
    t.append(f"Lines: {filler.lineCount}")
    t.append("Not Found (line: key):")
    for l, k in filler.notFound:
      t.append(f"\t{l}: {k}")

    return '\n'.join(t)


def makeKV(args):
  d = {}
  fails = []
  for pair in args:
    (k, e, v) = pair.partition('=')
    if e:
      d[k] = v
    else:
      fails.append(k)
  return (d, fails)


if __name__ == '__main__':
  parser = argparse.ArgumentParser(description=HelpText)
  parser.add_argument("--quiet", action="store_true", help="Don't report missing keys")
  parser.add_argument("--env", action="store_true", help="Also use environmnt vars")
  parser.add_argument("--notfound", help="The value to use for any keys not found. Implies --quiet")
  parser.add_argument("--debug", action="store_true", help="Dump debugging text to stderr")
  parser.add_argument("kv", nargs='*', help="The key-value pairs to use for template filling, in the format key=value")
  args = parser.parse_args()

  Options = {
    "quiet": args.quiet or args.notfound is not None,
    "use_env": args.env,
    "debug": args.debug,
    "not_found": args.notfound
  }

  kvList, failures = makeKV(args.kv)

  if failures:
    print(f'failure: Bad KV pairs in args: {failures}', file=sys.stderr)
    exit(1)

  lookupList = (kvList, os.environ) if Options['use_env'] else (kvList,)
  filler = TemplateFiller(lookupList, Options['not_found'])

  for line in sys.stdin:
    sys.stdout.write(filler.fillLine(line))

  if filler.notFound and not Options['quiet']:
    txt = [f'{l}: {k}' for l, k in filler.notFound]
    print(
      'No match found for the following (line: key):\n{}'.format('\n'.join(txt)),
      file=sys.stderr)

  if Options['debug']:
    print(f"Options: {Options}", file=sys.stderr)
    print(filler.debugText(), file=sys.stderr)

  if filler.notFound and Options['not_found'] is None:
    exit(1)
  else:
    exit(0)

