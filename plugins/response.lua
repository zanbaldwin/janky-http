-- Template filters for status codes: status_class and response.
-- `response` draws a mock `curl -i` output with a typical header for the code.

local CLASSES = {
  [1] = "Informational",
  [2] = "Success",
  [3] = "Redirection",
  [4] = "Client error",
  [5] = "Server error",
}

local LOCATION = { "Location", "https://example.com/new-place" }
local RETRY = { "Retry-After", "120" }

local HEADERS = {
  [101] = { { "Upgrade", "websocket" }, { "Connection", "Upgrade" } },
  [103] = { { "Link", "</style.css>; rel=preload; as=style" } },
  [201] = { { "Location", "https://example.com/items/42" } },
  [206] = { { "Content-Range", "bytes 0-1023/4096" } },
  [301] = { LOCATION },
  [302] = { LOCATION },
  [303] = { LOCATION },
  [304] = { { "ETag", '"33a64df5"' } },
  [307] = { LOCATION },
  [308] = { LOCATION },
  [401] = { { "WWW-Authenticate", 'Bearer realm="example"' } },
  [405] = { { "Allow", "GET, HEAD" } },
  [407] = { { "Proxy-Authenticate", 'Basic realm="proxy"' } },
  [416] = { { "Content-Range", "bytes */4096" } },
  [426] = { { "Upgrade", "HTTP/3.0" }, { "Connection", "Upgrade" } },
  [429] = { RETRY },
  [503] = { RETRY },
}

local function valid(code)
  return type(code) == "number" and code % 1 == 0 and code >= 100 and code <= 599
end

local filters = {}

function filters.status_class(code)
  if not valid(code) then return "" end
  return CLASSES[code // 100]
end

function filters.response(code, phrase)
  if not valid(code) then return "" end
  code = math.tointeger(code)
  local reason = '<span class="blank">???</span>'
  if type(phrase) == "string" and phrase ~= "" then
    reason = '<span class="phrase">' .. janky.escape(phrase) .. "</span>"
  end
  local lines = {
    '<span class="prompt">$</span> curl -i https://example.com/',
    'HTTP/1.1 <span class="code c' .. code // 100 .. '">' .. code .. "</span> " .. reason,
  }
  for _, header in ipairs(HEADERS[code] or {}) do
    lines[#lines + 1] = '<span class="header">' .. janky.escape(header[1]) .. ":</span> " .. janky.escape(header[2])
  end
  return janky.html('<pre class="response">' .. table.concat(lines, "\n") .. "</pre>")
end

return { id = "response", api = 1, filters = filters }
