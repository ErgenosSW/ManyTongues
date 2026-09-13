-- Speech engine using the original Tongues dictionaries and dialect rules.
local T = Tongues
local wordPattern = "[%a\128-\255']+"

local function orderedKeys(values)
    local keys = T.Keys(values)
    table.sort(keys, function(a, b) if #a == #b then return a < b end return #a > #b end)
    return keys
end

local function matchCase(original, replacement)
    if original == original:upper() then return replacement:upper() end
    if original:match("^%u") then return (replacement:gsub("^%a", string.upper)) end
    return replacement
end

function T:ApplyEffect(message, stages)
    for _, stage in ipairs(stages or {}) do
        for _, pattern in ipairs(orderedKeys(stage)) do message = message:gsub(pattern, stage[pattern]) end
    end
    return message
end

function T:Substitute(message, stages)
    for _, stage in ipairs(stages or {}) do
        for _, key in ipairs(orderedKeys(stage)) do
            local pattern = "%f[%a\128-\2550-9']" .. key:lower() .. "%f[^%a\128-\2550-9']"
            local result, position = {}, 1
            local lower = message:lower()
            while position <= #message do
                local first, last = lower:find(pattern, position)
                if not first or last < first then result[#result + 1] = message:sub(position); break end
                result[#result + 1] = message:sub(position, first - 1)
                result[#result + 1] = matchCase(message:sub(first, last), stage[key])
                position = last + 1
            end
            message = table.concat(result)
        end
    end
    return message
end

-- Original hash for interoperability on ordinary words; bound very long words
-- before IEEE floating point overflow can produce an invalid dictionary index.
function T.Hash(word)
    local primes = {5347,5351,5381,5387,5393,5399,5407,5413,5419,5431,5437,5441,5443,5449}
    local hash = 5381
    for index = 1, #word do
        local byte = word:byte(index)
        hash = hash * primes[byte % #primes + 1] + byte
        if hash > 1e290 then hash = math.fmod(hash, 2147483647) end
    end
    return hash
end

function T:TranslateWord(message, language)
    language = self:GetRealLanguage(language)
    local dictionary = self.Language[language]
    if not dictionary or #dictionary == 0 then return message end
    return (message:gsub(wordPattern, function(word)
        for _, ignored in ipairs(dictionary.ignore or {}) do
            if ignored:lower() == word:lower() then return word end
        end
        for original, replacement in pairs(dictionary.substitute or {}) do
            if original:lower() == word:lower() then return matchCase(word, replacement) end
        end
        local bucket = dictionary[math.min(#word, #dictionary)]
        if not bucket or #bucket == 0 then return word end
        return matchCase(word, bucket[math.fmod(self.Hash(word:lower()), #bucket) + 1])
    end))
end

function T:Understand(message, language, fluency)
    fluency = self.Number(fluency, 0, 0, 100)
    return self.MapText(message, function(text)
        return (text:gsub(wordPattern, function(word)
            if fluency >= 100 or (fluency > 0 and math.fmod(self.Hash(word:lower()), 100) < fluency) then return word end
            return self:TranslateWord(word, language)
        end))
    end)
end

function T:Style(message)
    local settings = self.Settings.Character
    return self.MapText(message, function(text)
        -- Parenthesized out-of-character messages remain readable.
        if message:match("^%s*%(") then return text end
        local filter = self.Filter[settings.Filter] or {}
        text = self:Substitute(text, filter.filters)
        text = self:ApplyEffect(text, filter.affects)
        local dialect = self.Dialect[settings.Dialect] or {}
        for _, field in ipairs({"filters", "substitute", "exceptions"}) do text = self:Substitute(text, dialect[field]) end
        for _, field in ipairs({"rules", "mutation", "remap", "affects"}) do text = self:ApplyEffect(text, dialect[field]) end
        local affect = self.Affect[settings.Affect] or {}
        if settings.AffectFrequency > 0 and math.random(100) <= settings.AffectFrequency then
            text = self:ApplyEffect(text, affect.substitute)
        end
        return text
    end)
end

function T:NativeLanguages()
    local languages = {}
    for index = 1, GetNumLanguages() do
        local name, id = GetLanguageByIndex(index)
        if name and id and (not C_ChatInfo.CanPlayerSpeakLanguage or C_ChatInfo.CanPlayerSpeakLanguage(id)) then languages[name] = id end
    end
    return languages
end

function T:SpeechLanguage()
    local s = self.Settings.Character
    if not s.ShapeshiftLanguage or select(2, UnitClass("player")) ~= "DRUID" then return s.Language end
    -- Spell IDs are independent of the client's UI language.
    local forms = {[768] = "Cat", [5487] = "Bear", [783] = "Stag", [1066] = "Seal",
        [24858] = T_Moonkin, [33891] = T_Trentish, [114282] = T_Trentish,
        [33943] = T_Bird, [40120] = T_Bird}
    local creatures = LibStub("LibBabble-CreatureType-3.0"):GetLookupTable()
    for index = 1, GetNumShapeshiftForms() do
        local _, active, _, spellID = GetShapeshiftFormInfo(index)
        if self.Accessible(active, spellID) and active then
            if s.FormLanguage ~= self.NONE then return s.FormLanguage end
            local language = forms[spellID]
            if spellID == 783 then
                if IsSwimming() then language = "Seal" elseif IsFlying() then language = T_Bird end
            end
            if language and not self.Language[language] then language = creatures[language] end
            if self.Language[language] then return language end
        end
    end
    return s.Language
end

T.ChannelKeys = {PARTY="Party", PARTY_LEADER="Party", RAID="Raid", RAID_LEADER="Raid",
    RAID_WARNING="RaidAlert", GUILD="Guild", OFFICER="Officer", INSTANCE_CHAT="Battleground",
    INSTANCE_CHAT_LEADER="Battleground", WHISPER="Targetted", WHISPER_INFORM="Targetted"}
T.SpeechChannels = {SAY=true,YELL=true,PARTY=true,RAID=true,RAID_WARNING=true,GUILD=true,
    OFFICER=true,INSTANCE_CHAT=true,WHISPER=true}

function T:PrepareMessage(message, channel)
    local s = self.Settings.Character
    if not s.Enabled or not self.SpeechChannels[channel] or message:match("^%s*%(") then return message end
    local key = self.ChannelKeys[channel]
    if key and s.Screen[key] then return message end
    local language = self:SpeechLanguage()
    local native = self:NativeLanguages()
    local human = self:Style(message)
    local languageID = native[language]
    local wire = human
    if not languageID then
        wire = "[" .. language .. "] " .. self.MapText(human, function(text) return self:TranslateWord(text, language) end)
        languageID = select(2, GetDefaultLanguage("player"))
    end
    return wire, languageID, language, human
end
