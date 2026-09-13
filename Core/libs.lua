-- Shared helpers. Language/dialect data retain their original authorship notices.
Tongues = { Custom = {}, UI = {}, NONE = "<None>" }
local T = Tongues

-- Used by the original data files when composing substitution tables.
function merge(tables)
    local result = {}
    for _, values in ipairs(tables) do
        for key, value in pairs(values) do result[key] = value end
    end
    return result
end

function T.Keys(values)
    local keys = {}
    for key in pairs(values or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

function T.Number(value, default, minimum, maximum)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then number = default end
    return math.max(minimum, math.min(maximum, number))
end

function T.Accessible(...)
    if canaccessallvalues then return canaccessallvalues(...) end
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if issecretvalue and issecretvalue(value) then return false end
    end
    return true
end

function T:Restricted()
    return C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() or false
end

function T:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffb6d89dTongues:|r " .. message)
end

function T:GetRealLanguage(language)
    local seen = {}
    while self.Language[language] and self.Language[language].alias and not seen[language] do
        seen[language] = true
        language = self.Language[language].alias
    end
    return language
end

function T:Resolve(values, text)
    if type(text) ~= "string" then return end
    text = text:match("^%s*(.-)%s*$")
    if values[text] then return text end
    for key in pairs(values) do if key:lower() == text:lower() then return key end end
end

-- Keep links, textures and markup intact; transform only ordinary text.
function T.MapText(text, transform)
    local output, position = {}, 1
    while position <= #text do
        local start = text:find("|", position, true)
        if not start then output[#output + 1] = transform(text:sub(position)); break end
        if start > position then output[#output + 1] = transform(text:sub(position, start - 1)) end
        local tail = text:sub(start)
        local token = tail:match("^(|H.-|h.-|h)") or tail:match("^(|T.-|t)")
            or tail:match("^(|A.-|a)") or tail:match("^(|c%x%x%x%x%x%x%x%x)")
            or tail:match("^(|r)") or tail:match("^(||)") or "|"
        output[#output + 1] = token
        position = start + #token
    end
    return table.concat(output)
end

function T:Refresh()
    if self.UI.Refresh then self.UI:Refresh() end
    if self.Broker then self.Broker.text = self.Settings.Character.Language end
end
