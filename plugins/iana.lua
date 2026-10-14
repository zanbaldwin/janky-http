-- Data generator: reason phrases and references from the IANA HTTP status code registry.
-- `prepare` downloads the registry CSV once and stores one record per code in the cache.

local URL = "https://www.iana.org/assignments/http-status-codes/http-status-codes-1.csv"
local FORMAT = 1

local function csv_row(line)
  local fields, i, n = {}, 1, #line
  while i <= n + 1 do
    if line:sub(i, i) == '"' then
      local value, j = {}, i + 1
      while j <= n do
        local c = line:sub(j, j)
        if c == '"' and line:sub(j + 1, j + 1) == '"' then
          value[#value + 1] = '"'
          j = j + 2
        elseif c == '"' then
          j = j + 1
          break
        else
          value[#value + 1] = c
          j = j + 1
        end
      end
      fields[#fields + 1] = table.concat(value)
      i = j + 1
    else
      local stop = line:find(",", i, true) or n + 1
      fields[#fields + 1] = line:sub(i, stop - 1)
      i = stop + 1
    end
  end
  return fields
end

local function rfc_link(reference)
  local rfc, section = reference:match("RFC (%d+), Section ([%d%.]+)")
  rfc = rfc or reference:match("RFC (%d+)")
  if not rfc then return nil end
  local url = "https://www.rfc-editor.org/rfc/rfc" .. rfc
  if section then url = url .. "#section-" .. section end
  return { rfc = rfc, section = section, url = url }
end

local function prepare(vars)
  local url = vars.url or URL
  local index = janky.cache.get("index")
  if type(index) == "table" and index.format == FORMAT and index.url == url then
    return
  end
  local response = janky.http.request { url = url, headers = { accept = "text/csv" } }
  if response.status ~= 200 then
    error("IANA HTTP " .. response.status .. ": " .. response.body:sub(1, 200), 0)
  end
  local count = 0
  for line in response.body:gmatch("[^\r\n]+") do
    local row = csv_row(line)
    local code = row[1] and row[1]:match("^(%d%d%d)$")
    if code and row[2] ~= "Unassigned" then
      local phrase = row[2]
      local obsolete = phrase:find("%(OBSOLETED%)") ~= nil
      phrase = phrase:gsub("%s*%(OBSOLETED%)", "")
      janky.cache.put("code:" .. code, {
        phrase = phrase,
        obsolete = obsolete,
        reference = row[3] or "",
      })
      count = count + 1
    end
  end
  if count == 0 then error("the IANA registry has no status codes", 0) end
  janky.cache.put("index", { format = FORMAT, url = url, count = count })
  janky.log("indexed " .. count .. " status codes")
end

local function plan(job, vars)
  return { key = { url = vars.url or URL, v = FORMAT }, units = 1, unit = "lookups" }
end

local function generate(job, vars)
  local code = tostring(job.input)
  if not code:match("^[1-5]%d%d$") then
    error("the input must be a status code from 100 to 599", 0)
  end
  local record = janky.cache.get("code:" .. code)
  if type(record) ~= "table" then
    return { value = {}, warning = "not in the IANA registry" }
  end
  local link = rfc_link(record.reference)
  if link then
    record.rfc = link.rfc
    record.section = link.section
    record.url = link.url
  end
  return { value = record }
end

return {
  id = "iana",
  api = 1,
  generates = "data",
  variables = {
    url = { type = "string" },
  },
  plan = plan,
  prepare = prepare,
  generate = generate,
}
