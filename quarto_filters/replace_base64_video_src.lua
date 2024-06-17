local str_ends_with = require "utils.str_ends_with"
local notebook_special_comments_walker = require "utils.notebook_special_comments_walker"
local is_output_cell = require "utils.is_output_cell"

---get_youtube_image
---@param video_src string
---@return string|nil
local get_youtube_image = function(video_src)
  local video_id = 
    -- "www.youtube.com/watch?v=kCc8FmEb1nY"
    string.match(video_src, ".+youtube.com/watch%?v%=(.+)$") or
    -- "https://youtu.be/kCc8FmEb1nY?si=77OsaKikOnJgRRRy"
    string.match(video_src, ".+youtu.be/([%w]+).*$") or
    -- "https://www.youtube.com/embed/kCc8FmEb1nY?si=XspSx2xnp7xhYgDe"
    string.match(video_src, ".+youtube.com/embed/(.+)%?.+$")
  if video_id then
    return 'https://img.youtube.com/vi/' .. video_id .. '/hqdefault.jpg'
  end
  return nil
end

local makeBox = function (text, url, icon, color)
  local youtube_image_src = get_youtube_image(url)
  if not youtube_image_src then
    local blocks = pandoc.RawInline(
      'latex',
      '\\href{' .. url .. '}{ \
          \\begin{centering} \
            \\begin{tcolorbox}[\
                hbox,\
                colframe='.. color .. ',\
                colback=white] \
                { \\Large { \
                    \\textcolor{' .. color .. '}{' .. icon .. '} \
                    \\textbf{' .. text .. '} \
                }} \
            \\end{tcolorbox}\
          \\end{centering}\
      }')
    return pandoc.Div(blocks)
  else
    local pandoc_image_attributes = {
      id = tostring({}):sub(10),
      width = '90%' -- width=0.9\\textwidth
    }
    local latex_top_raw_block = pandoc.RawInline(
      'latex',
      '\\begin{centering} \
          \\begin{tcolorbox}[\
              hbox,\
              colframe='.. color .. ',\
              colback=white, \
              left=0pt, right=0pt, top=0pt, bottom=0pt,\
              title=' .. text ..', \
              fonttitle=\\bfseries] \
              \\begin{tikzpicture} \
              \\node[inner sep = 0pt] (a) {')
    -- \\includegraphics[width=0.5\\textwidth]{' .. youtube_image_src .. '}\
    -- we have done this so that quarto can download the image, pandoc doesnt embend online images to pdf
    local pandoc_image_block = pandoc.Image(
      pandoc_image_attributes.id, 
      youtube_image_src, 
      pandoc_image_attributes.id, 
      pandoc_image_attributes)
    local latex_bottom_raw_block = pandoc.RawInline(
      'latex',
                '};\
                \\node[anchor=center] at (a.center) {\
                    \\textcolor{' .. color .. '}{{\\fontsize{70}{0}\\selectfont {' .. icon .. '}}} \
                };\
              \\end{tikzpicture}\
          \\end{tcolorbox}\
      \\end{centering}')
    return pandoc.Div(
      pandoc.Link(
        pandoc.List{ latex_top_raw_block, pandoc_image_block, latex_bottom_raw_block }, 
        url))
  end
end

-- Function to return video block for PDF
---@param video_src string
---@return pandoc.Block
local function pdf_src_block(video_src)
  local video = makeBox(
    "Click to watch the video at Youtube.", 
    video_src, 
    "\\faYoutube", 
    "youtubeColor")
  return video
end

-- Function to return videovideo_src block for HTML
---@param video_src string
---@param meta pandoc.MetaBlocks
---@return pandoc.Block,pandoc.MetaBlocks
local function html_src_block(video_src, meta)
  local video_blocks = quarto.utils.string_to_blocks("{{< video " .. video_src .. " >}}")
  local youtube_image_src = get_youtube_image(video_src)
  if youtube_image_src and not meta['image'] then
    -- https://github.com/quarto-dev/quarto-cli/discussions/9767
    video_blocks:insert(
      pandoc.RawInline(
        "html", 
        "<img class='preview-image hidden' src='" .. youtube_image_src .. "' />"))
  end
  return pandoc.Div(video_blocks), meta
end

-- Function to extract base64 video
---@param video_src table<'key'|'value', string>
---@param block pandoc.Block
---@param meta pandoc.MetaBlocks
---@return pandoc.Block, pandoc.MetaBlocks
local function replace_base64_video_src(video_src, block, meta)
  if not (str_ends_with(quarto.doc.input_file, ".ipynb")) then
    return block, meta
  end
  
  if quarto.doc.is_format('pdf') then
    return pdf_src_block(video_src.value), meta
  end

  if quarto.doc.is_format('html') then
    return html_src_block(video_src.value, meta)
  end
  
  return block, meta
end

return notebook_special_comments_walker('video-src', replace_base64_video_src, is_output_cell)