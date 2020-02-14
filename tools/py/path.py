import os
import os.path
import sys




def paths(item):
  realpath = os.path.realpath(item)
  paths = []
  while os.path.islink(item):
    paths.append(item)
    item = os.readlink(item)
  paths.append(realpath)
  return paths


if sys.argv[1] == '-c':
  print('\n'.join(' -> '.join(paths(x)) for x in sys.argv[2:]))
else:
  print('\n'.join(os.path.realpath(x) for x in sys.argv[1:]))
