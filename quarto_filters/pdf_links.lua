local read_metadata = require "utils.read_metadata"
local str_starts_with = require "utils.str_starts_with"

return {
  ---@param link pandoc.Link
  ---@return pandoc.Link
  Link = function (link)
    if not quarto.doc.is_format('pdf') then
      return link
    end
    
    local site_url = pandoc.utils.stringify(
      read_metadata(
        quarto.project.directory .. '/_quarto.yml')['website']['site-url'])

    if site_url and str_starts_with(link.target, site_url) then
      return link
    end

    -- Handle links in PDF!!
    link.target = site_url

    return link
  end
}
