import os.path as op
import sys


def abspath(item):
  return op.abspath(op.expanduser(item))


def resolve(item):
  return op.realpath(op.expanduser(item))


if sys.argv[1] == '-l':
  print('\n'.join(resolve(x) for x in sys.argv[2:]))
else:
  print('\n'.join(abspath(x) for x in sys.argv[1:]))
