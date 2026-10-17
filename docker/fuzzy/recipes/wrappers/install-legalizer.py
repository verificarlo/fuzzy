#!/usr/bin/python3
"""Install the IR legalization step immediately before PRISM instrumentation."""
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
needle = '    pass_args = get_opt_pass_args("vfclibinst", libvfcinst)'
if source.count(needle) != 1:
    raise SystemExit('Verificarlo instrumentation entry changed; review the PRISM adapter')
source = source.replace(needle, needle + '''
    if args.prism_backend:
        pass_args = pass_args.replace(
            "-passes=vfclibinst",
            "-load-pass-plugin /opt/fuzzy-src/recipes/wrappers/legalize-prism.so "
            "-passes='function(fuzzy-prism-legalize),vfclibinst'",
        )
''')
path.write_text(source)
