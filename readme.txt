                        Shell Tools

Shell tools                                                    J. Parker

  Make using the shell a bit easier with a few tools and workspace. These are all bash specific at the moment, but I may switch shells someday.


Shell Startup

  Tools should be initialized in ~/.profile or similar. Setup consists of sourcing init.bash

Dependencies

  They sort of depend on each other and they all depend on the functions defined in init.bash

Conventions

  Shell tools are at their core just scripts that are soruced when bash is started. The power lies in the conventions that they follow, especially when one gets used to it. Here's a rough sketch:

  1. Filename is: $name.sh
      ex: mytool.sh

  2. Public functions start with "${name}."
      ex: mytool.do-something, mytool.run-tests

  3. Private functions start with "_${name}"
      ex: _mytool.internal-func

  4. Sometimes, it makes sense for there to also be a function that is the same name of the tool.
      ex: mytool() { ... }

  5. _${name}.setup() is a special function. If it is defined, it will run after all tools have been sourced, but in no particular order relative to other .setup() functions.
      ex: _mytool.setup() { ... }

Notable Tools

  Workspaces - ws.sh

  Workspaces provide a way to keep commonly used shell commands for a particular project (of any type) all in one place. This was loosely inspired by virtualenv. Workspaces can be "entered", which just means that the workspace.sh file sitting in the project's main directory is sourced and you get a cool little PS1 addition.

  In addition to that, workspaces can be symlinked into $shtools_root/workspaces to enable discovery and tab completion. This really speeds up getting into the flow of things. Finally, the comma ',' command (COMMAnd, get it?) is abused to do some nify command forwarding. If you use the comma by itself, it 'cd's  to the project's home directory.


  Fill - py/fill.py

  Fill is a dead simple template filling engine. It processes templates line by line (read from stdin) and spits them out filled with whatever key=value pairs you give it on the command line.

  eg: $ echo "my name is {{name}}" | py fill name=mike
      > my name is mike

Caveats

  - Nothing is guaranteed to work

  - This will almost definitely break your shell
