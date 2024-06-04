import sys
from nbformat import NotebookNode, v4, write as nb_write
import re
import yaml
import mistune
from bs4 import BeautifulSoup

def get_html(markdown) -> BeautifulSoup:
    html = mistune.create_markdown()(markdown)
    return BeautifulSoup(html, features='html.parser')

def parse_metadata_key(key: str, value: str):
    options_pattern = r"\s*(.*?)\s*,\s*type=(.*)\s*"
    type_match = re.findall(options_pattern, key, re.IGNORECASE)
    if len(type_match) == 0:
        return (key, get_html(value).get_text().replace("\n\n", "\n"))
    (key, type) = type_match[0]
    if type == 'date':
        date_pattern = r'.*(\d{4}\s*-\s*\d{2}\s*-\s*\d{2}).*'
        return (key, re.match(date_pattern, value, re.DOTALL).group(1))
    elif type == 'array':
        html = get_html(value)
        list_items = html.find_all('li')
        return (key, [item.get_text(strip=True) for item in list_items])
    raise Exception(f"type({type}) is not in ['date', 'array']")

def remove_lists(markdown_text):
    # Remove ordered lists
    markdown_text = re.sub(r'^\d+\.\s*', '', markdown_text, flags=re.MULTILINE)
    
    # Remove unordered lists
    markdown_text = re.sub(r'^\*\s*', '', markdown_text, flags=re.MULTILINE)
    markdown_text = re.sub(r'^\+\s*', '', markdown_text, flags=re.MULTILINE)
    markdown_text = re.sub(r'^-\s*', '', markdown_text, flags=re.MULTILINE)
    
    return markdown_text

def extract_quarto_metadata(cells: list[NotebookNode]) -> list[NotebookNode]:
    new_cells = []
    metadata = {}
    pattern = r"<!--\s*metadata:\s*(.*?)\s*-->\s*(.*?)\s*(?=<!-- metadata:|$)"

    for cell in cells:
        if cell and cell.cell_type == 'markdown':
            matches = re.findall(pattern, cell.source, re.DOTALL)
            skip_this_cell = False
            for (metadata_key, metadata_value) in matches:
                metadata_value = metadata_value.strip()
                if len(metadata_key) > 0 and len(metadata_value) > 0:
                    metadata_key, metadata_value = parse_metadata_key(metadata_key, metadata_value)
                    # html list in listings page spoils UI.
                    metadata[metadata_key] = \
                        metadata.get(metadata_key, []) + metadata_value \
                            if isinstance(metadata_value, list) \
                            else metadata_value
                    skip_this_cell = True
            if skip_this_cell:
                continue
        new_cells.append(cell)
    if any(metadata):
        source = yaml.dump(metadata)
        metadata_cell = v4.new_markdown_cell(source=f'---\n{source}\n---')
        new_cells.insert(0, metadata_cell)
    return new_cells

# read notebook from stdin
notebook = v4.reads(sys.stdin.read())

notebook.cells = extract_quarto_metadata(notebook.cells)

# write notebook to stdout 
nb_write(notebook, sys.stdout)