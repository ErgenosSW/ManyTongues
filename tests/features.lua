-- Exercise public behavior, asynchronous peer replies and the actual binding bodies.
return function(T,M,test,eq,event)
local serializer=LibStub('AceSerializer-3.0')
local function reset()
    local s=T.Settings.Character
    s.Enabled=true; s.InCharacter=true; s.Favorites={}; s.ShapeshiftLanguage=true
    s.Dialect=T.NONE; s.Affect=T.NONE; s.Filter=T.NONE; s.FormLanguage=T.NONE
    s.Fluency.Common=100; s.Fluency.Darnassian=100; s.Fluency.Draconic=100
    s.Screen.Self=false; s.MMH=false
    M.restricted=false; M.class=nil; M.form=nil; M.shift=false
    M.messages={}; M.wire={}; T.History={}; T.Pending={}; T.Learning={}; T.Rates={}; T.LastLesson={}
    for key in pairs(T.CommStats) do T.CommStats[key]=0 end
    T:SetLanguage('Common')
    return s
end
local function capture()
    local original, requests=T.CommSend,{}
    T.CommSend=function(_,target,...)
        requests[#requests+1]={target=target,data={...}}
        return true
    end
    return requests,function() T.CommSend=original end
end
local function count(values) local n=0; for _ in pairs(values) do n=n+1 end; return n end
local function reply(sender,data)
    T:ReceiveComm('Tongues2',serializer:Serialize(data),'WHISPER',sender)
end

test('independent peer translates burst messages with out-of-order replies',function()
    reset()
    local requests,restore=capture()
    local peer=setmetatable({Ready=true,History={},Rates={},Learning={},Pending={},LastLesson={},
        CommStats={timedOut=0},Settings={Character={Enabled=true,LanguageLearning=false}}},{__index=T})
    local replies={}
    peer.CommSend=function(_,target,...) replies[#replies+1]={...}; return true end
    peer:Remember('[Draconic] one','First sentence','Draconic','CHAT_MSG_SAY')
    peer:Remember('[Draconic] two','Second sentence','Draconic','CHAT_MSG_SAY')
    for i,word in ipairs({'one','two'}) do
        T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Speaker-Realm','Draconic',100,'[Draconic] '..word,nil,nil,nil,i)
    end
    restore(); eq(count(T.Pending),2)
    for _,request in ipairs(requests) do
        peer:ReceiveComm('Tongues2',serializer:Serialize(request.data),'WHISPER','Tester-Realm')
    end
    eq(#replies,2)
    reply('Speaker-Realm',replies[2]); reply('Speaker-Realm',replies[1])
    eq(count(T.Pending),0); eq(T.CommStats.received,2)
    assert(M.messages[1]:find('Second sentence',1,true))
    assert(M.messages[2]:find('First sentence',1,true))
    reply('Speaker-Realm',replies[1]); eq(#M.messages,2)
end)
test('tokens isolate senders, channels, windows and pet replies',function()
    reset(); local _,restore=capture()
    local frame=CreateFrame('Frame'); frame.id=2
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Peer','Draconic',100,'[Draconic] one')
    T:RequestTranslation(frame,'CHAT_MSG_YELL','Peer','Draconic',100,'[Draconic] two')
    local first,second
    for _,pending in pairs(T.Pending) do
        if pending.frameID==1 then first=pending else second=pending end
    end
    restore()
    reply('Intruder',{'TR','CHAT_MSG_SAY',1,'Draconic','Wrong peer',first.token})
    reply('Peer',{'TR','CHAT_MSG_YELL',1,'Draconic','Wrong channel',first.token})
    reply('Peer',{'TR','CHAT_MSG_SAY',2,'Draconic','Wrong window',first.token})
    eq(#M.messages,0); eq(count(T.Pending),2)
    reply('Peer',{'TR','CHAT_MSG_YELL',2,'Draconic','Second frame',second.token})
    assert(frame.messages[#frame.messages]:find('Second frame',1,true))
    reply('Peer',{'TR','CHAT_MSG_SAY',1,'Draconic','First frame',first.token})
    eq(count(T.Pending),0)
    local _,restorePet=capture()
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_EMOTE','Peer','Draconic',100,'pet one','pet','Fluffy','says')
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_EMOTE','Peer','Draconic',100,'mount one','mount','Horse','says')
    restorePet()
    local pet
    for _,p in pairs(T.Pending) do if p.kind=='pet' then pet=p end end
    local before=#M.messages
    reply('Peer',{'MNR',100,1,'Draconic','Horse','says','Wrong kind',pet.token})
    eq(#M.messages,before)
    reply('Peer',{'RP',100,1,'Draconic','Fluffy','says','Pet voice',pet.token})
    assert(M.messages[#M.messages]:find('Pet voice',1,true))
end)
test('ambiguous legacy replies never consume overlapping requests',function()
    reset(); local _,restore=capture()
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','OldPeer','Draconic',100,'one')
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','OldPeer','Draconic',100,'two')
    restore()
    reply('OldPeer',{'TR','CHAT_MSG_SAY',1,'Draconic','Uncorrelated'})
    eq(#M.messages,0); eq(count(T.Pending),2); eq(T.CommStats.ambiguous,1)
    local token=next(T.Pending)
    reply('OldPeer',{'TR','CHAT_MSG_SAY',1,'Draconic','Matched',token})
    reply('OldPeer',{'TR','CHAT_MSG_SAY',1,'Draconic','Still ambiguous'})
    eq(#M.messages,1); eq(count(T.Pending),1)
    T.Pending={}; local _,restoreSingle=capture()
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','SinglePeer','Draconic',100,'single')
    restoreSingle()
    reply('SinglePeer',{'TR','CHAT_MSG_SAY',1,'Draconic','Legacy single'})
    assert(M.messages[#M.messages]:find('Legacy single',1,true)); eq(count(T.Pending),0)
end)
test('line IDs distinguish repeated text and deduplicate the same delivery',function()
    reset(); local _,restore=capture()
    for _,id in ipairs({100,101,101}) do
        T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Peer','Draconic',100,'same',nil,nil,nil,id)
    end
    eq(count(T.Pending),2)
    T.Pending={}
    local s=T.Settings.Character; s.Fluency.Draconic=100
    T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','[Draconic] same','Peer','Common',nil,nil,nil,nil,nil,nil,nil,400)
    T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','[Draconic] same','Peer','Common',nil,nil,nil,nil,nil,nil,nil,401)
    eq(count(T.Pending),2)
    for _,entry in pairs(T.Pending) do assert(entry.lineID==400 or entry.lineID==401) end
    restore()
end)
test('pending queues have peer and global limits and expire without replies',function()
    reset(); local _,restore=capture()
    for i=1,40 do T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Peer','Draconic',100,'wire'..i) end
    eq(count(T.Pending),32); eq(T.CommStats.queueFull,8)
    T.Pending={}
    for i=1,270 do T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Peer'..i,'Draconic',100,'wire') end
    eq(count(T.Pending),256)
    M.time=M.time+21; T:PrunePending()
    eq(count(T.Pending),0); eq(T.CommStats.timedOut,256)
    restore()
end)
test('blocked communication does not create phantom pending requests',function()
    reset(); M.restricted=true
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Peer','Draconic',100,'wire')
    eq(count(T.Pending),0); eq(T.CommStats.blocked,1); eq(T.CommStats.requested,0)
    M.restricted=false
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=function() return true end
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Peer','Draconic',100,'wire')
    eq(count(T.Pending),0); eq(T.CommStats.blocked,2)
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=nil
end)
test('OOC preserves exact outgoing text and native editbox language',function()
    local s=reset(); T:SetLanguage('Darnassian')
    local box=CreateFrame('EditBox'); box.languageID=7; box:SetText('Hello')
    T:PreSend(box); eq(box.languageID,2)
    local history=#T.History; local sent=#M.wire
    T.UI.Mini.ModeButton:Click(); assert(not s.InCharacter)
    local text='Zażółć |Hitem:42|h[Item]|h - unchanged'
    box:SetText(text); T:PreSend(box)
    eq(box:GetText(),text); eq(box.languageID,7); eq(#T.History,history); eq(#M.wire,sent)
    eq(T.UI.Mini.ModeButton:GetText(),'OOC')
    T:Command('ic'); assert(s.InCharacter); eq(s.Language,'Darnassian')
    local _,id=T:PrepareMessage('Hello','SAY'); eq(id,2)
end)
test('OOC keeps incoming translation active and stops pet and form speech',function()
    local s=reset(); T:Command('ooc'); assert(not s.InCharacter)
    local _,restore=capture()
    T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','[Draconic] secret','Peer','Common')
    restore(); eq(count(T.Pending),1)
    local token=next(T.Pending)
    reply('Peer',{'TR','CHAT_MSG_SAY',1,'Draconic','Readable while OOC',token})
    assert(M.messages[#M.messages]:find('Readable while OOC',1,true))
    local before=#M.wire; M.pet='Kitty'; T:AnimalSpeak('pet','Hello'); eq(#M.wire,before)
    M.form=768; T:Refresh(); assert(T.UI.Mini.FormChoice.disabled)
    T:ToggleFormSpeech(); eq(T.FormSpeechChoice,nil)
    T:Command('toggle'); assert(s.InCharacter); assert(not T.UI.Mini.FormChoice.disabled)
    M.form=nil; M.pet=nil; T:Refresh()
end)
test('favorites drive forward and backward cycling with a known-language fallback',function()
    local s=reset()
    assert(T:SetFavorite('Draconic',true)); assert(T:SetFavorite('Darnassian',true))
    assert(not T:SetFavorite('No such language',true))
    T:SetLanguage('Common'); T:CycleLanguage(); eq(s.Language,'Darnassian')
    T:CycleLanguage(); eq(s.Language,'Draconic')
    T:CycleLanguage(); eq(s.Language,'Darnassian')
    T:CycleLanguage(-1); eq(s.Language,'Draconic')
    T:Command('favorite Draconic'); assert(not s.Favorites.Draconic)
    T:CycleLanguage(); eq(s.Language,'Darnassian')
    T:SetFavorite('Darnassian',false); s.Fluency={Common=100}
    T:SetLanguage('Draconic'); T:CycleLanguage(); eq(s.Language,'Common')
end)
test('favorite picker sorts, edits and selects languages from the floating button',function()
    local s=reset(); T:SetFavorite('Draconic',true)
    T.UI.Mini:Click('MiddleButton')
    local p=T.UI.Picker
    assert(p:IsShown() and p.AllowFavorites); eq(p.Buttons[1].Value,'Draconic')
    eq(p.FavoriteButtons[1]:GetText(),'*')
    p.Search:SetText('Common'); eq(p.Buttons[1].Value,'Common')
    p.FavoriteButtons[1]:Click(); assert(s.Favorites.Common)
    p.Buttons[1]:Click(); eq(s.Language,'Common'); assert(not p:IsShown())
    T.UI.Mini:Fire('OnMouseWheel',1); eq(s.Language,'Draconic')
    M.shift=true; T.UI.Mini:Click('LeftButton'); M.shift=false; assert(p:IsShown())
    T.UI:Pick('Dialect',T.Dialect,s.Dialect,function() end)
    assert(not p.AllowFavorites)
    for _,b in ipairs(p.FavoriteButtons) do assert(not b:IsShown()) end
    p:Hide()
end)
test('new preferences survive reload and malformed favorites are repaired',function()
    local s=reset(); T:SetFavorite('Draconic',true); T:SetInCharacter(false)
    s.Favorites.Missing=true; s.Favorites.Common='bad'; s.Favorites[7]=true
    T:LoadSettings(); s=T.Settings.Character
    assert(not s.InCharacter and s.Favorites.Draconic)
    eq(s.Favorites.Missing,nil); eq(s.Favorites.Common,nil); eq(s.Favorites[7],nil)
    s.InCharacter='bad'; T:LoadSettings(); assert(s.InCharacter)
    eq(s.SchemaVersion,3)
end)
test('doctor prints session diagnostics without chat content or peer names',function()
    reset(); local _,restore=capture()
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','PrivatePeer','Draconic',100,'PRIVATE WORDS')
    restore(); M.time=M.time+21; T:Command('doctor')
    local report=table.concat(M.messages,'\n')
    assert(report:find('timed out',1,true)); assert(report:find('IC',1,true))
    assert(not report:find('PRIVATE WORDS',1,true)); assert(not report:find('PrivatePeer',1,true))
    eq(count(T.Pending),0)
end)
test('actual keyboard binding bodies toggle mode and cycle favorites',function()
    local s=reset(); local file=assert(io.open('Bindings.xml')); local xml=file:read('*a'); file:close()
    local bodies={}
    for name,body in xml:gmatch('<Binding%s+name="([^"]+)"[^>]*>(.-)</Binding>') do bodies[name]=assert(loadstring(body)) end
    assert(BINDING_HEADER_MANYTONGUES and BINDING_NAME_MANYTONGUES_TOGGLE_IC)
    bodies.MANYTONGUES_TOGGLE_IC(); assert(not s.InCharacter)
    bodies.MANYTONGUES_TOGGLE_IC(); assert(s.InCharacter)
    T:SetFavorite('Draconic',true); bodies.MANYTONGUES_NEXT_LANGUAGE(); eq(s.Language,'Draconic')
end)
test('blocked learning requests do not suppress the next retry',function()
    local s=reset(); s.LanguageLearning=true
    local original,attempts=T.CommSend,0
    local ok,err=pcall(function()
        T.CommSend=function() attempts=attempts+1; return false end
        T:RequestLearning('LearningPeer','Draconic',50)
        eq(T.Learning['learningpeer-realm:Draconic'],nil)
        T.CommSend=function() attempts=attempts+1; return true end
        T:RequestLearning('LearningPeer','Draconic',50)
        eq(attempts,2)
        assert(T.Learning['learningpeer-realm:Draconic'])
        T:RequestLearning('LearningPeer','Draconic',50)
        eq(attempts,2)
    end)
    T.CommSend=original
    if not ok then error(err) end
end)
test('disabled addon blocks both pet and mount speech commands',function()
    local s=reset(); s.Enabled=false; M.pet='Kitty'; M.mount='Horse'
    local sent,history=#M.wire,#T.History
    SlashCmdList.PETSPEAK('Do not send this')
    SlashCmdList.MOUNTSPEAK('Do not send this either')
    eq(#M.wire,sent); eq(#T.History,history)
    M.pet=nil; M.mount=nil
end)
reset()
end
