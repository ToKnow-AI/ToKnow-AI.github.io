"""Quarto notebook filter to copy to output directory"""

import os
import sys
from nbformat import v4, write as nb_write
import json

# read notebook from stdin
notebook = v4.reads(sys.stdin.read())

# with open('quarto.env', 'w+', encoding='utf-8') as f:
#     json.dump(dict(os.environ), f, indent=4)

# write notebook to stdout
nb_write(notebook, sys.stdout)

# execute:
#   keep-ipynb: true
