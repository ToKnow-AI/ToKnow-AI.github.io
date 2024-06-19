local read_file = require "utils.read_file"
local read_metadata = require "utils.read_metadata"
local must_have_one_main_category = require "must_have_one_main_category"

--- Check if a Pandoc element is an inline or a block element
---@param elem any The Pandoc element to check
---@return boolean True if the element is an inline element, false if it's a block element
local function is_inline_element (elem)
  local inline_types = {
    Str = true,
    Emph = true,
    Strong = true,
    Strikeout = true,
    Superscript = true,
    Subscript = true,
    SmallCaps = true,
    Quoted = true,
    Cite = true,
    Code = true,
    Space = true,
    LineBreak = true,
    Math = true,
    RawInline = true,
    Link = true,
    Image = true,
    Note = true,
    Span = true
  }

  return elem.t and inline_types[elem.t] == true
end

---@param elements pandoc.Blocks|pandoc.List
---@return pandoc.List
local function blocks_to_inlines (elements)
  local result = pandoc.List:new {}
  if elements then
    for _, child in ipairs(elements) do
      if child.content and not is_inline_element(child) then
        result:extend(blocks_to_inlines(child.content))
      else
        if is_inline_element(child) then
          result:insert(child)
        else
          result:extend(pandoc.utils.blocks_to_inlines({ child }))
        end
      end
    end
  end
  return result
end

return {
  ---@param doc pandoc.Pandoc
  ---@return pandoc.Pandoc
  Pandoc = function (doc)
    local general_disclaimer = quarto.project.directory .. '/posts/_general-disclaimer.md'

    local disclaimer_blocks = pandoc.List {
      pandoc.Strong(pandoc.Emph('Disclaimer:')),
      pandoc.Space()
    }

    local general_disclaimer_inlines = quarto.utils.string_to_inlines(read_file(general_disclaimer))
    disclaimer_blocks:extend(general_disclaimer_inlines)

    --- @type table
    local categories = doc.meta['categories']
    if must_have_one_main_category.compare_categories(categories, { 'cyber security' }) then
      disclaimer_blocks:extend(pandoc.read('<br/>', 'html').blocks)
      local security_disclaimer = quarto.project.directory .. '/posts/_security-disclaimer.md'
      local security_disclaimer_inlines = quarto.utils.string_to_inlines(read_file(security_disclaimer))
      disclaimer_blocks:extend(security_disclaimer_inlines)
    end

    local site_url = pandoc.utils.stringify(
      read_metadata(
        quarto.project.directory .. '/_quarto.yml')['website']['site-url'])
    local read_more = quarto.utils.string_to_inlines(
      'Read more: [/terms-of-service](' .. site_url .. '/terms-of-service)')
    disclaimer_blocks:insert(pandoc.Space())
    disclaimer_blocks:insert(pandoc.Strong(pandoc.Emph(read_more)))

    --- @type pandoc.Inlines
    local custom_disclaimer = doc.meta['disclaimer']
    if custom_disclaimer then
      disclaimer_blocks:extend(pandoc.read('<br/>', 'html').blocks)
      quarto.log.debug('custom_disclaimer', custom_disclaimer, type(custom_disclaimer))
      disclaimer_blocks:insert(pandoc.Strong(pandoc.Emph(custom_disclaimer)))
      doc.meta['disclaimer'] = nil
    end

    local div = pandoc.Div(
      pandoc.Para(blocks_to_inlines(disclaimer_blocks)),
      pandoc.Attr('', { 'disclaimer' }, {}))
    if quarto.doc.is_format('pdf') then
      doc.blocks:insert(
        pandoc.RawInline('latex', '{\\tiny '))
    end
    doc.blocks:insert(pandoc.HorizontalRule())
    doc.blocks:insert(div)
    if quarto.doc.is_format('pdf') then
      doc.blocks:insert(
        pandoc.RawInline('latex', ' }'))
    end
    return doc
  end
}
