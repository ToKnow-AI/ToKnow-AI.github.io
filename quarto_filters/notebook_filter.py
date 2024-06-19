"""Quarto notebook filter"""

import sys
import re
from nbformat import NotebookNode, v4, write as nb_write
import yaml
import mistune
from bs4 import BeautifulSoup

def get_html(markdown: str) -> BeautifulSoup:
    """
    Converts markdown to HTML using the mistune library and returns a BeautifulSoup object.

    Args:
        markdown (str): The markdown string to be converted.

    Returns:
        BeautifulSoup: A BeautifulSoup object representing the converted HTML.
    """
    html = mistune.create_markdown()(markdown)
    return BeautifulSoup(html, features='html.parser')

def parse_metadata_key(key: str, value: str):
    """
    Parses the metadata key and value and returns a tuple with the parsed key and value.

    Args:
        key (str): The metadata key.
        value (str): The metadata value.

    Returns:
        tuple: A tuple containing the parsed key and value.

    Raises:
        ValueError: If the key type is not 'date' or 'array'.
    """
    key = key.strip()
    value = value.strip()
    (key, *_options) = key.split(',', 1)
    key_dict_options = {
        'strip_markdown': True,
        # 'type': Literal['date', 'array']
        **{
            option_key:option_value
            for option_key,option_value
            in [
                i.strip().split('=')
                for i
                in (_options[0].split(',') if len(_options) > 0 else [])
            ]
        }
    }
    key = key.strip()
    if 'type' not in key_dict_options:
        strip_markdown: str = key_dict_options.get('strip_markdown', 'None')
        strip_markdown_option: bool = \
            strip_markdown is True \
            or str(strip_markdown).lower().strip() == 'true' \
            or str(strip_markdown).lower().strip() == '1'
        if strip_markdown_option:
            new_value: str = get_html(value).get_text().replace("\n\n", "\n").strip()
            return (key, new_value)
        return (key, value)
    key_type = key_dict_options.get('type', 'None').strip()
    if key_type == 'date':
        date_pattern = r'.*(\d{4}\s*-\s*\d{2}\s*-\s*\d{2}).*'
        new_value: str = re.match(date_pattern, value, re.DOTALL).group(1).strip()
        return (key, new_value)
    if key_type == 'array':
        html = get_html(value)
        list_items = html.find_all('li')
        new_values = [item.get_text(strip=True) for item in list_items]
        return (key, new_values)
    raise ValueError(f"type({key_type}) is not in ['date', 'array']")

def remove_lists(markdown_text: str):
    """
    Removes ordered and unordered lists from the given markdown text.

    Args:
        markdown_text (str): The input markdown text.

    Returns:
        str: The markdown text with lists removed.
    """
    # Remove ordered lists
    markdown_text = re.sub(r'^\d+\.\s*', '', markdown_text, flags=re.MULTILINE)
    # Remove unordered lists
    markdown_text = re.sub(r'^\*\s*', '', markdown_text, flags=re.MULTILINE)
    markdown_text = re.sub(r'^\+\s*', '', markdown_text, flags=re.MULTILINE)
    markdown_text = re.sub(r'^-\s*', '', markdown_text, flags=re.MULTILINE)
    return markdown_text

def extract_quarto_metadata(cells: list[NotebookNode]) -> list[NotebookNode]:
    """
    Extracts Quarto metadata from markdown cells in a notebook.

    Args:
        cells (list[NotebookNode]): List of notebook cells.

    Returns:
        list[NotebookNode]: List of notebook cells with Quarto metadata extracted.
    """
    new_cells = []
    metadata = {}
    pattern = r"<!--\s*metadata:\s*(.*?)\s*-->\s*(.*?)\s*(?=<!-- metadata:|$)"

    for cell in cells:
        if cell and cell.cell_type == 'markdown':
            matches = re.findall(pattern, cell.source, re.DOTALL)
            skip_this_cell = False
            for (metadata_key, metadata_value) in matches:
                if len(metadata_key.strip()) > 0 and len(metadata_value) > 0:
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
        source = yaml.dump(
            metadata,
            sort_keys=False,
            indent=4)
        metadata_cell = v4.new_markdown_cell(source=f'---\n{source}\n---')
        new_cells.insert(0, metadata_cell)
    return new_cells

# read notebook from stdin
notebook = v4.reads(sys.stdin.read())

notebook.cells = extract_quarto_metadata(notebook.cells)

# write notebook to stdout
nb_write(notebook, sys.stdout)
