-- Tongues2 wire compatibility, with bounded requests and correlated replies.
local T = Tongues
local serializer = LibStub("AceSerializer-3.0")
local function identity(name)
    if not name:find("-",1,true) then name=name .. "-" .. GetNormalizedRealmName() end
    return name:lower()
end
local function stringValue(value) return type(value)=="string" and #value<=4096 end
local function recent(entry) return entry and GetTime()-entry.time <= 20 end

function T:CommSend(target, ...)
    if self:Restricted() or not self.Settings.Character.Enabled
        or (C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()) then return false end
    self.Comm:SendCommMessage("Tongues2",serializer:Serialize({...}),"WHISPER",target,"NORMAL")
    return true
end

function T:RequestTranslation(frame,event,sender,language,fluency,wire,kind,name,verb)
    if not stringValue(sender) or fluency<=0 or not self.Comm then
        if stringValue(sender) then self:RequestLearning(sender,language,fluency) end
        return
    end
    local frameID = frame:GetID()
    if not frameID or frameID<=0 then return end
    local key = identity(sender) .. ":" .. event .. ":" .. frameID .. ":" .. language
    local old = self.Pending[key]
    if recent(old) and old.wire==wire then return end
    self.RequestID=self.RequestID+1
    local token=tostring(self.RequestID)
    self.Pending[key]={time=GetTime(),frame=frame,event=event,language=language,fluency=fluency,
        sender=identity(sender),wire=wire,kind=kind,name=name,verb=verb,token=token,frameID=frameID}
    if kind then
        self:CommSend(sender,kind=="pet" and "PR" or "RMN",fluency,name,frameID,language,verb,wire,token)
    else
        self:CommSend(sender,"RT",fluency,event,frameID,language,wire,token)
    end
    self:RequestLearning(sender,language,fluency)
end

function T:RequestLearning(sender,language,fluency)
    if not self.Comm or not self.Settings.Character.LanguageLearning or fluency>=100 or self:Restricted() then return end
    if identity(sender)==identity(UnitName("player")) then return end
    local key=identity(sender) .. ":" .. language
    if recent(self.Learning[key]) then return end
    self.Learning[key]={time=GetTime(),language=language}
    local s=self.Settings.Character
    self:CommSend(sender,"RL",language,s.Faction,s.Race,s.Class,1,fluency)
end

function T:FindSpeech(language,wire,kind,event,sender)
    for _, entry in ipairs(self.History or {}) do
        if recent(entry) and entry.language==language and entry.kind==kind
            and (not event or entry.channel==event)
            and (not wire or entry.wire==wire or (not kind and not wire:match("^%[")))
            and (entry.channel ~= "CHAT_MSG_WHISPER" or (sender and entry.target and identity(sender)==identity(entry.target))) then return entry end
    end
end

function T:DisplayReply(sender,event,frameID,language,message,token,kind)
    if not stringValue(event) or not stringValue(language) or not stringValue(message) then return end
    local key=identity(sender) .. ":" .. event .. ":" .. tostring(frameID) .. ":" .. language
    local pending=self.Pending[key]
    if not recent(pending) or pending.kind~=kind or (token and token~=pending.token) then return end
    self.Pending[key]=nil
    local readable=self:Understand(message,language,pending.fluency)
    local prefix=sender
    if kind then prefix=prefix .. "'s " .. (pending.name or kind) end
    local color=ChatTypeInfo[event:sub(10)] or ChatTypeInfo.SAY
    pending.frame:AddMessage("[Tongues · " .. language .. "] " .. prefix .. ": " .. readable,color.r,color.g,color.b)
end

function T:ReceiveComm(prefix,text,distribution,sender)
    if not self.Ready or not self.Settings.Character.Enabled or self:Restricted()
        or not self.Accessible(prefix,text,distribution,sender) then return end
    if prefix~="Tongues2" or distribution~="WHISPER" or not stringValue(sender) or not stringValue(text) then return end
    local ok,payload=serializer:Deserialize(text)
    if not ok or type(payload)~="table" or type(payload[1])~="string" then return end
    -- Only a flat list of primitive values belongs to this protocol.
    for key,value in pairs(payload) do
        if type(key)~="number" or key<1 or key>12 or key%1~=0
            or (type(value)~="number" and type(value)~="string") then return end
        if type(value)=="string" and #value>4096 then return end
    end
    local op=payload[1]
    local now=GetTime()
    local rateKey=identity(sender)
    local rate=self.Rates[rateKey]
    if not rate or now-rate.time>1 then rate={time=now,count=0}; self.Rates[rateKey]=rate end
    rate.count=rate.count+1
    if rate.count>30 then return end
    -- Expire all peer state; repeated messages must not grow tables indefinitely.
    for _, cache in ipairs({self.Pending,self.Learning,self.Rates}) do
        for key,entry in pairs(cache) do if now-entry.time>30 then cache[key]=nil end end
    end
    for key,time in pairs(self.LastLesson) do if now-time>30 then self.LastLesson[key]=nil end end
    if op=="RT" then
        local _,fluency,event,frameID,language,wire,token=unpack(payload)
        if not stringValue(language) or not stringValue(event) or type(frameID)~="number" or (wire~=nil and not stringValue(wire)) then return end
        local speech=self:FindSpeech(language,wire,nil,event,sender)
        if speech then self:CommSend(sender,"TR",event,frameID,language,speech.human,token) end
    elseif op=="TR" then
        self:DisplayReply(sender,payload[2],payload[3],payload[4],payload[5],payload[6])
    elseif op=="PR" or op=="RMN" then
        local _,fluency,name,frameID,language,verb,wire,token=unpack(payload)
        if not stringValue(language) or type(frameID)~="number" or (wire~=nil and not stringValue(wire)) then return end
        local kind=op=="PR" and "pet" or "mount"
        local speech=self:FindSpeech(language,wire,kind)
        if speech then self:CommSend(sender,kind=="pet" and "RP" or "MNR",fluency,frameID,language,speech.name,speech.verb,speech.human,token) end
    elseif op=="RP" or op=="MNR" then
        self:DisplayReply(sender,"CHAT_MSG_EMOTE",payload[3],payload[4],payload[7],payload[8],op=="RP" and "pet" or "mount")
    elseif op=="RL" then
        local _,language,faction,race,class,frameID,fluency=unpack(payload)
        if not stringValue(language) or not stringValue(faction) or not stringValue(race) or not stringValue(class) then return end
        local s=self.Settings.Character
        if not s.LanguageLearning or faction~=s.Faction then return end
        if not (self:FindSpeech(language) or self:FindSpeech(language,nil,"pet") or self:FindSpeech(language,nil,"mount")) then return end
        local dictionary=self.Language[self:GetRealLanguage(language)]
        if not dictionary or not dictionary.Difficulty then return end
        fluency=self.Number(fluency,0,0,100)
        local own=s.Fluency[self:GetRealLanguage(language)] or 0
        if own<fluency or fluency>=100 then return end
        local last=self.LastLesson[rateKey .. language] or 0
        if now-last<15 then return end
        local d=dictionary.Difficulty
        local difficulty=math.max(1,(d.default or 0)+(d[faction] or 0)+(d[race] or 0)+(d[class] or 0))
        if math.random(1,math.max(1,math.floor(difficulty)))<=100 then
            self.LastLesson[rateKey .. language]=now; self:CommSend(sender,"LR",language,1)
        end
    elseif op=="LR" then
        local language=payload[2]
        if not stringValue(language) or not self.Settings.Character.LanguageLearning then return end
        local key=rateKey .. ":" .. language
        if not recent(self.Learning[key]) then return end
        self.Learning[key]=nil
        local real=self:GetRealLanguage(language)
        if not self.Language[real] then return end
        local gained=self.Number(payload[3],0,0,1)
        local current=self.Settings.Character.Fluency[real] or 0
        self:SetFluency(real,current+gained)
        if gained>0 then self:Print(language .. " skill +" .. gained) end
    end
end

function T:InitializeComm()
    self.Comm={}
    LibStub("AceComm-3.0"):Embed(self.Comm)
    self.Pending,self.Learning,self.Rates,self.LastLesson,self.RequestID={},{},{},{},0
    self.Comm:RegisterComm("Tongues2",function(...) self:ReceiveComm(...) end)
end
