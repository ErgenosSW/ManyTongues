-- Retail lifecycle, commands and supported chat integration.
local addonName = ...
local T = Tongues
T.Version = C_AddOns.GetAddOnMetadata(addonName or "Tongues", "Version")
T.TargetInterface = 120100

local defaults = {
    Enabled=true, LanguageLearning=true, ShapeshiftLanguage=true, MMH=false,
    Dialect="<None>", Affect="<None>", Filter="<None>", AffectFrequency=100,
    FormLanguage="<None>", PetLanguage="<None>", MountLanguage="<None>",
    Translations={Self=false,Targetted=false,Party=false,Guild=false,Officer=false,Raid=false,RaidAlert=false,Battleground=false},
    Screen={Self=false,Targetted=false,Party=true,Guild=true,Officer=true,Raid=true,RaidAlert=true,Battleground=true},
    Fluency={}, Translators={}, UI={MainMenu={},MiniMenu={}},
}

local function fill(values, template)
    for key, default in pairs(template) do
        if type(default) == "table" then
            if type(values[key]) ~= "table" then values[key] = {} end
            fill(values[key], default)
        elseif type(values[key]) ~= type(default) then values[key] = default end
    end
end

function T:LoadSettings()
    for _, kind in ipairs({"Language","Dialect","Affect","Filter"}) do
        for key, value in pairs(self.Custom[kind] or {}) do self[kind][key] = value end
    end
    local fresh = type(Tongues_Character) ~= "table"
    Tongues_Character = fresh and {} or Tongues_Character
    Tongues_Global = type(Tongues_Global) == "table" and Tongues_Global or {}
    -- Convert old numeric strings before applying typed defaults.
    Tongues_Character.AffectFrequency = self.Number(Tongues_Character.AffectFrequency, 100, 0, 100)
    fill(Tongues_Character, defaults)
    local s = Tongues_Character
    self.Settings = {Character=s, Global=Tongues_Global}
    s.Faction, s.Race, s.Class = UnitFactionGroup("player"), UnitRace("player"), UnitClass("player")
    for _, key in ipairs({"Dialect", "Affect", "Filter"}) do
        if not self[key][s[key]] then s[key] = self.NONE end
    end
    for _, key in ipairs({"FormLanguage","PetLanguage","MountLanguage"}) do
        if not self.Language[s[key]] then s[key] = self.NONE end
    end
    for language, value in pairs(s.Fluency) do
        if type(language) ~= "string" then s.Fluency[language] = nil
        else s.Fluency[language] = self.Number(value, 0, 0, 100) end
    end
    local native = self:NativeLanguages()
    if fresh then
        for language in pairs(native) do s.Fluency[self:GetRealLanguage(language)] = 100 end
    end
    local defaultLanguage = GetDefaultLanguage("player")
    if not self.Language[s.Language] then
        s.Language = self.Language[defaultLanguage] and defaultLanguage or T_Common
    end
    if fresh then s.Fluency[self:GetRealLanguage(s.Language)] = 100 end
    local translators = s.Translators
    s.Translators = {}
    for _, name in ipairs(translators) do self:AddTranslator(name, true) end
    for _, position in pairs(s.UI) do
        if type(position) == "table" then position.relativeTo = nil end
    end
    s.SchemaVersion = 2
end

function T:SetLanguage(language)
    local resolved = self:Resolve(self.Language, language)
    if not resolved then return false, "Unknown language: " .. tostring(language) end
    self.Settings.Character.Language = resolved
    self:Refresh()
    return true
end

function T:SetFluency(language, fluency)
    language = self:Resolve(self.Language, language)
    if not language then return false end
    self.Settings.Character.Fluency[self:GetRealLanguage(language)] = self.Number(fluency, 0, 0, 100)
    self:Refresh()
    return true
end

function T:CycleLanguage()
    local choices = {}
    for _, language in ipairs(self.Keys(self.Language)) do
        if (self.Settings.Character.Fluency[self:GetRealLanguage(language)] or 0) >= 30 then choices[#choices + 1] = language end
    end
    if #choices == 0 then return end
    local index = 0
    for i, language in ipairs(choices) do if language == self.Settings.Character.Language then index = i; break end end
    self:SetLanguage(choices[index % #choices + 1])
end

function T:AddTranslator(name, quiet)
    if type(name) ~= "string" then return false end
    name = name:match("^%s*(.-)%s*$")
    if name == "" or #name > 100 or name:find("[%s|%c]") then return false end
    for _, other in ipairs(self.Settings.Character.Translators) do if name:lower() == other:lower() then return false end end
    table.insert(self.Settings.Character.Translators, name)
    if not quiet then self:Refresh() end
    return true
end

function T:RemoveTranslator(name)
    for index = #self.Settings.Character.Translators, 1, -1 do
        if self.Settings.Character.Translators[index]:lower() == name:lower() then
            table.remove(self.Settings.Character.Translators, index)
        end
    end
    self:Refresh()
end

function T:Send(message, channel, languageID, target)
    if self:Restricted() or not self.Accessible(message, target) then return false end
    if type(message) ~= "string" or message == "" or #message > 255 then return false end
    C_ChatInfo.SendChatMessage(message, channel, languageID, target)
    return true
end

function T:Remember(wire, human, language, channel, kind, name, verb, target)
    self.History = self.History or {}
    table.insert(self.History, 1, {wire=wire,human=human,language=language,channel=channel,
        kind=kind,name=name,verb=verb,target=target,time=GetTime()})
    while #self.History > 30 do table.remove(self.History) end
end

function T:ShareTranslation(human, language, originalChannel)
    local s = self.Settings.Character
    if originalChannel == "WHISPER" then return end
    if s.Translations.Self then self:Print("[" .. language .. "] " .. human) end
    local copy = "[Translation - " .. language .. "] " .. human
    local destinations = {}
    local function whisper(name)
        if name and not destinations[name] then self:Send(copy, "WHISPER", nil, name); destinations[name] = true end
    end
    if s.Translations.Targetted and UnitIsPlayer("target") then
        local name, realm = UnitFullName("target")
        whisper(name and (realm and realm ~= "" and name .. "-" .. realm or name))
    end
    for _, name in ipairs(s.Translators) do whisper(name) end
    for channel, key in pairs({PARTY="Party",RAID="Raid",RAID_WARNING="RaidAlert",GUILD="Guild",OFFICER="Officer",INSTANCE_CHAT="Battleground"}) do
        local available = ((channel == "GUILD" or channel == "OFFICER") and IsInGuild())
            or (channel == "PARTY" and IsInGroup(LE_PARTY_CATEGORY_HOME))
            or (channel == "RAID" and IsInRaid(LE_PARTY_CATEGORY_HOME))
            or (channel == "RAID_WARNING" and IsInRaid(LE_PARTY_CATEGORY_HOME) and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")))
            or (channel == "INSTANCE_CHAT" and IsInGroup(LE_PARTY_CATEGORY_INSTANCE))
        if s.Translations[key] and available then self:Send(copy, channel) end
    end
end

function T:PreSend(editBox)
    if not self.Ready or self:Restricted() then return end
    self.EditBoxes = self.EditBoxes or setmetatable({}, {__mode="k"})
    local previous = self.EditBoxes[editBox]
    if previous and self.Accessible(editBox.languageID) and editBox.languageID == previous.applied then
        editBox.languageID = previous.original
    end
    self.EditBoxes[editBox] = nil
    local text, channel = editBox:GetText(), editBox:GetChatType()
    if not self.Accessible(text, channel) or type(text) ~= "string" or text == "" then return end
    local wire, languageID, language, human = self:PrepareMessage(text, channel)
    if not language then return end
    if #wire > 255 then
        -- Leave the user's text and language untouched instead of silently cutting links/UTF-8.
        self:Print("The transformed message exceeds 255 bytes. Shorten it; this message will be sent unchanged.")
        return
    end
    self.EditBoxes[editBox] = {original=editBox.languageID, applied=languageID}
    editBox:SetText(wire)
    editBox.languageID = languageID
    local target = channel == "WHISPER" and editBox:GetTellTarget() or nil
    self:Remember(wire, human, language, "CHAT_MSG_" .. channel, nil, nil, nil, target)
    self:ShareTranslation(human, language, channel)
end

function T:Receive(frame, event, message, sender, language, ...)
    if not self.Ready or not self.Settings.Character.Enabled or self:Restricted()
        or not self.Accessible(message, sender, language, ...) then return end
    if self.Settings.Character.Screen.Self and type(sender) == "string"
        and Ambiguate(sender, "none") == UnitName("player") then return end
    local channel = event:sub(10)
    local key = self.ChannelKeys[channel]
    if key and self.Settings.Character.Screen[key] then return end
    if type(message) ~= "string" or message:match("^%[Translation %- ") then return end
    local tagged = message:match("^%[([^%]]+)%] ")
    local kind, animalName, verb, petLanguage = message:match("^'s (pet) (.-) (%S+), \"%[([^%]]+)%] ")
    if not kind then kind, animalName, verb, petLanguage = message:match("^'s (mount) (.-) (%S+), \"%[([^%]]+)%] ") end
    local resolved = self:Resolve(self.Language, tagged or petLanguage or language)
    if not resolved then return end
    local fluency = self.Settings.Character.Fluency[self:GetRealLanguage(resolved)] or 0
    if tagged or petLanguage or not self:NativeLanguages()[language] then
        self:RequestTranslation(frame, event, sender, resolved, fluency, message, kind, animalName, verb)
        -- Always retain the original; absent/nonresponsive addons must never swallow chat.
        return
    end
    local transformed = self:Understand(message, resolved, fluency)
    if self.Settings.Character.Filter ~= self.NONE then
        local filter = self.Filter[self.Settings.Character.Filter] or {}
        transformed = self.MapText(transformed, function(text)
            return self:ApplyEffect(self:Substitute(text, filter.filters), filter.affects)
        end)
    end
    if fluency < 100 then self:RequestLearning(sender, resolved, fluency) end
    return false, transformed, sender, language, ...
end

function T:AnimalSpeak(kind, text)
    if not self.Ready or self:Restricted() then self:Print("Speech is unavailable while chat is restricted."); return end
    if text == "" then self:Print("Enter text after /petspeak or /mountspeak."); return end
    local name, language, verb
    local s = self.Settings.Character
    if kind == "pet" then
        name = UnitName("pet")
        local family = UnitCreatureFamily("pet")
        if not self.Accessible(name, family) then return end
        local data = self.PetTable[family] or {}
        language, verb = data.Language, data.Speaktype
        if s.PetLanguage ~= self.NONE then language = s.PetLanguage end
    else
        for _, id in ipairs(C_MountJournal.GetMountIDs()) do
            local mountName, _, _, active = C_MountJournal.GetMountInfoByID(id)
            if self.Accessible(active, mountName) and active then name = mountName; break end
        end
        if name then
            for _, pattern in ipairs(self.Keys(self.MountTable)) do
                if name:lower():find(pattern:lower(), 1, true) then
                    local data = self.MountTable[pattern]; language, verb = data.Language, data.Speaktype; break
                end
            end
        end
        if s.MountLanguage ~= self.NONE then language = s.MountLanguage end
    end
    if not name then self:Print("No active " .. kind .. "."); return end
    language = self:Resolve(self.Language, language) or self:SpeechLanguage()
    verb = verb or "says"
    local wire = "'s " .. kind .. " " .. name .. " " .. verb .. ", \"[" .. language .. "] " .. self:Understand(text, language, 0) .. "\""
    if #wire > 255 then self:Print("Shorten the message to fit the chat limit."); return end
    if self:Send(wire, "EMOTE") then self:Remember(wire, text, language, "CHAT_MSG_EMOTE", kind, name, verb) end
end

function T:Command(text)
    text = (text or ""):match("^%s*(.-)%s*$")
    local command, rest = text:match("^(%S+)%s*(.-)$")
    if not command or command:lower() == "opt" then self.UI:Toggle(); return end
    command = command:lower()
    local s = self.Settings.Character
    if command == "help" then
        self:Print("/tongues [language] | opt | cycle | add <language> <0-100> | remove <language> | dialect <name> | affect <name> [0-100] | roleplay | shapeshift | translate <Name-Realm> | reset | list")
    elseif command == "cycle" then self:CycleLanguage()
    elseif command == "reset" then self.UI:ResetPosition()
    elseif command == "roleplay" then s.Filter = s.Filter == self.NONE and "Roleplay" or self.NONE
    elseif command == "shapeshift" then
        if rest == "true" then s.ShapeshiftLanguage = true elseif rest == "false" then s.ShapeshiftLanguage = false else s.ShapeshiftLanguage = not s.ShapeshiftLanguage end
    elseif command == "add" then
        local language, fluency = rest:match("^(.-)%s+([%d.]+)$")
        if not self:SetFluency(language, fluency) then self:Print("Use: /tongues add <language> <0-100>") end
    elseif command == "remove" then
        local language = self:Resolve(self.Language, rest)
        if language then s.Fluency[self:GetRealLanguage(language)] = nil end
    elseif command == "dialect" or command == "affect" then
        local kind = command == "dialect" and "Dialect" or "Affect"
        local name, frequency = rest:match("^(.-)%s+(%d+)$")
        name = self:Resolve(self[kind], kind == "Affect" and (name or rest) or rest)
        if rest == "" then name = self.NONE end
        if name then s[kind] = name; if frequency and kind == "Affect" then s.AffectFrequency = self.Number(frequency,100,0,100) end
        else self:Print("Unknown " .. command .. ".") end
    elseif command == "translate" then
        if not self:AddTranslator(rest) then self:RemoveTranslator(rest) end
    elseif command == "list" then
        for _, language in ipairs(self.Keys(s.Fluency)) do self:Print(language .. ": " .. s.Fluency[language] .. "%") end
    else
        local ok, reason = self:SetLanguage(command == "language" and rest or text)
        if not ok then self:Print(reason) end
    end
    self:Refresh()
end

function T:Initialize()
    if self.Ready then return end
    self:LoadSettings()
    self.Ready = true
    self.UI:Build()
    self:InitializeComm()
    SLASH_TONGUES1 = "/tongues"
    SlashCmdList.TONGUES = function(text) self:Command(text) end
    SLASH_DIALECT1 = "/dialect"
    SlashCmdList.DIALECT = function(text) self:Command("dialect " .. text) end
    SLASH_PETSPEAK1, SLASH_PETSPEAK2 = "/petspeak", "/ps"
    SLASH_MOUNTSPEAK1, SLASH_MOUNTSPEAK2 = "/mountspeak", "/ms"
    SlashCmdList.PETSPEAK = function(text) self:AnimalSpeak("pet",text) end
    SlashCmdList.MOUNTSPEAK = function(text) self:AnimalSpeak("mount",text) end
    EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", function(_, box) self:PreSend(box) end, self)
    for _, channel in ipairs({"SAY","YELL","PARTY","PARTY_LEADER","RAID","RAID_LEADER","RAID_WARNING","GUILD","OFFICER","INSTANCE_CHAT","INSTANCE_CHAT_LEADER","WHISPER","WHISPER_INFORM","EMOTE"}) do
        ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_" .. channel, function(...) return self:Receive(...) end)
    end
    self.Broker = LibStub("LibDataBroker-1.1"):NewDataObject("Tongues", {
        type="data source",text=self.Settings.Character.Language,icon="Interface\\Icons\\Spell_Holy_Silence",
        OnClick=function(_, button) if button == "RightButton" then self.UI:Toggle() else self:CycleLanguage() end end,
        OnTooltipShow=function(tooltip) tooltip:AddLine("Tongues"); tooltip:AddLine("Left: next language. Right: settings.") end,
    })
    self:Refresh()
end

T.Frame = CreateFrame("Frame")
T.Frame:RegisterEvent("ADDON_LOADED")
T.Frame:RegisterEvent("PLAYER_LOGIN")
T.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
T.Frame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
T.Frame:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" then T:Initialize()
    elseif T.Ready then T:Refresh() end
end)
