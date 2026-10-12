import sys

from . import cli, loop

if sys.argv[1:2] == ["loop"]:
    sys.exit(loop.main(sys.argv[2:]))
sys.exit(cli.main(sys.argv[1:]))
