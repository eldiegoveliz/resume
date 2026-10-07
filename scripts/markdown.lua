-- Preserve résumé content while removing LaTeX-only presentation.
function Header(header)
  header.level = header.level + 1
  return header
end

function Div(div)
  if div.classes:includes("center") then
    local paragraph = div.content[1]
    if paragraph and paragraph.t == "Para" then
      local name = paragraph.content[1]
      if name and name.t == "Strong" then
        local contact = pandoc.List()
        for i = 2, #paragraph.content do
          local inline = paragraph.content[i]
          if i ~= 2 or inline.t ~= "LineBreak" then
            contact:insert(inline)
          end
        end
        local blocks = pandoc.List({
          pandoc.Header(1, name.content),
          pandoc.Para(contact),
        })
        for i = 2, #div.content do
          blocks:insert(div.content[i])
        end
        return blocks
      end
    end
  end
  return div.content
end

function Underline(underline)
  return underline.content
end
