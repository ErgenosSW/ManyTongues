-- Run from the Tongues directory: lua5.1 tests/run.lua
local passed=0
local function test(name,fn)
    local ok,err=pcall(fn)
    if not ok then error('FAIL '..name..': '..tostring(err),0) end
    passed=passed+1; print('PASS '..name)
end
local function eq(actual,expected) assert(actual==expected,tostring(actual)..' ~= '..tostring(expected)) end

dofile('tests/wow_mock.lua')
local loaded={}
local function loadFile(path)
    path=path:gsub('\\','/')
    if path:match('%.xml$') then
        local f=assert(io.open(path)); local text=f:read('*a'); f:close()
        for child in text:gmatch('<Script%s+file="([^"]+)"') do loadFile((path:match('^(.-)[^/]+$') or '')..child) end
    elseif path:match('%.lua$') then
        assert(loadfile(path))('Tongues',{})
        loaded[#loaded+1]=path
    end
end
for line in io.lines('Tongues.toc') do
    if line:match('%S') and not line:match('^%s*#') then loadFile(line) end
end
local T=Tongues
local function event(event,...)
    T.Frame.scripts.OnEvent(T.Frame,event,...)
end

test('load full TOC and libraries without removed API',function()
    eq(ChatThrottleLib.version,32)
    event('ADDON_LOADED','Tongues'); event('PLAYER_LOGIN')
    assert(T.Ready and T.UI.Mini and T.UI.Category)
end)
local s=T.Settings.Character
if os.getenv('TONGUES_LOCALE') then
    test('localized dictionaries, dialects and GUI bootstrap',function()
        for language in pairs(T.Language) do assert(type(T:TranslateWord('Hello friend',language))=='string') end
        for dialect in pairs(T.Dialect) do s.Dialect=dialect; T:Style('Hello my friend') end
        T.UI:Toggle(); assert(T.UI.Frame:IsShown())
    end)
    print('OK locale '..Mock.locale); os.exit(0)
end

test('settings persist on reload and repair invalid fields',function()
    s.Language='Draconic'; s.Fluency.Draconic='75'; s.AffectFrequency='25'; s.UI.MainMenu.relativeTo=UIParent
    T:LoadSettings(); s=T.Settings.Character
    eq(s.Language,'Draconic'); eq(s.Fluency.Draconic,75); eq(s.AffectFrequency,25); eq(s.UI.MainMenu.relativeTo,nil)
    eq(s,Tongues_Character)
end)
test('multiword commands and effect frequency',function()
    T:Command('affect Stutter 0'); eq(s.Affect,'Stutter'); eq(s.AffectFrequency,0)
    T:Command('add Draconic 100'); eq(s.Fluency.Draconic,100)
    T:Command('dialect'); eq(s.Dialect,'<None>')
    T:Command('shapeshift false'); eq(s.ShapeshiftLanguage,false)
end)
test('translator removal preserves other names',function()
    s.Translators={}; assert(T:AddTranslator('Alice-Realm')); assert(T:AddTranslator('Bob-Realm'))
    assert(not T:AddTranslator('alice-realm')); T:RemoveTranslator('Alice-Realm')
    eq(#s.Translators,1); eq(s.Translators[1],'Bob-Realm'); s.Translators={}
end)
test('markup and Unicode remain intact',function()
    local link='|cffaabbcc|Hitem:123:0|h[Special Sword]|h|r'
    local result=T:Understand('Zażółć '..link..' |Ticon:12|t |Aatlas:12:12|a', 'Draconic',0)
    assert(result:find(link,1,true)); assert(result:find('|Ticon:12|t',1,true)); assert(result:find('|Aatlas:12:12|a',1,true))
    eq(T:Understand('Zażółć gęślą jaźń','Draconic',100),'Zażółć gęślą jaźń')
end)
test('all dictionaries and dialects process text',function()
    for language in pairs(T.Language) do
        local ok, result=pcall(T.TranslateWord,T,'Hello traveler! Zażółć 123 '..string.rep('z',255),language); assert(ok,language .. ': ' .. tostring(result)); assert(type(result)=='string',language)
    end
    s.Affect=T.NONE
    for dialect in pairs(T.Dialect) do s.Dialect=dialect; assert(type(T:Style('Hello my friend! I cannot believe this.'))=='string',dialect) end
    s.Dialect=T.NONE
    for affect in pairs(T.Affect) do s.Affect=affect; s.AffectFrequency=100; T:Style('Hello my friend!') end
    s.Affect=T.NONE
end)
test('current pre-send event transforms exactly once without sending itself',function()
    Mock.wire={}; T:SetLanguage('Draconic'); s.Filter=T.NONE
    local box=CreateFrame('EditBox'); box:SetText('Hello friend')
    local callback=Mock.events['ChatFrame.OnEditBoxPreSendText']; callback[1](callback[2],box)
    assert(box:GetText():find('[Draconic]',1,true)); eq(#Mock.wire,0); eq(box.languageID,7)
    eq(T.History[1].human,'Hello friend')
end)
test('native language selection uses language ID',function()
    T:SetLanguage('Darnassian'); local wire,id=T:PrepareMessage('Hello','SAY')
    eq(wire,'Hello'); eq(id,2)
end)
test('channel bypass, OOC, disabled addon and long text',function()
    T:SetLanguage('Draconic'); eq(T:PrepareMessage('Hello','GUILD'),'Hello')
    eq(T:PrepareMessage('(OOC hello)','SAY'),'(OOC hello)')
    s.Enabled=false; eq(T:PrepareMessage('Hello','SAY'),'Hello'); s.Enabled=true
    local box=CreateFrame('EditBox'); box:SetText(string.rep('a',250)); T:PreSend(box)
    -- Long source words can shrink; use preserved markup to ensure the output exceeds the limit.
    local text='|Hitem:1|h['..string.rep('x',240)..']|h'
    box:SetText(text); T:PreSend(box); eq(box:GetText(),text)
end)
test('restricted and secret chat is not examined or changed',function()
    Mock.restricted=true
    local box=CreateFrame('EditBox'); box:SetText('Hello'); T:PreSend(box); eq(box:GetText(),'Hello')
    eq(T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY',{secret=true},'Other','Common'),nil)
    assert(not T:Send('Hello','SAY')); Mock.restricted=false
    eq(T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY',{secret=true},'Other','Common'),nil)
end)
test('incoming filter preserves trailing event arguments and original without peer',function()
    s.Fluency.Common=0
    local result={T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Hello','Other','Common','channel',nil,'flags')}
    eq(result[1],false); assert(result[2]~='Hello'); eq(result[4],'Common'); eq(result[5],'channel'); eq(result[7],'flags')
    eq(T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','[Draconic] xyz','Other','Common'),nil)
end)
test('malformed and unsolicited addon replies are rejected',function()
    local count=#Mock.messages
    T:ReceiveComm('Tongues2','garbage','WHISPER','Other')
    local serializer=LibStub('AceSerializer-3.0')
    for _,p in ipairs({{},{'TR','CHAT_MSG_SAY',1,'Draconic','injected'},{'LR','Draconic',999},{'RT',{}}}) do
        T:ReceiveComm('Tongues2',serializer:Serialize(p),'WHISPER','Unsolicited')
    end
    eq(#Mock.messages,count)
end)
test('correlated translation replies display at saved frame',function()
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Peer','Draconic',100,'[Draconic] abc')
    local pending
    for _,v in pairs(T.Pending) do if v.sender=='peer-realm' then pending=v end end
    assert(pending)
    local serializer=LibStub('AceSerializer-3.0')
    T:ReceiveComm('Tongues2',serializer:Serialize({'TR','CHAT_MSG_SAY',1,'Draconic','Hello',pending.token}),'WHISPER','Peer')
    assert(Mock.messages[#Mock.messages]:find('Hello',1,true))
end)
test('pet and mount speech handle absent units and active units',function()
    local before=#Mock.wire
    Mock.pet=nil; T:AnimalSpeak('pet','Hello')
    Mock.mount=nil; T:AnimalSpeak('mount','Hello')
    eq(#Mock.wire,before)
    Mock.pet='Kitty'; T:AnimalSpeak('pet','Hello'); assert(T.History[1].kind=='pet')
    Mock.mount='New Midnight Mount'; T:AnimalSpeak('mount','Hello'); assert(T.History[1].kind=='mount')
end)
test('druid form overrides only apply while shapeshifted',function()
    s.ShapeshiftLanguage=true; s.FormLanguage='Draconic'; T:SetLanguage('Common')
    Mock.form=nil; eq(T:SpeechLanguage(),'Common')
    Mock.form=768; eq(T:SpeechLanguage(),'Draconic')
    s.FormLanguage=T.NONE; eq(T:SpeechLanguage(),'Cat'); Mock.form=nil
end)
test('private translations cannot be requested by another player',function()
    local box=CreateFrame('EditBox'); box.channel='WHISPER'; box.target='Friend-Realm'; box:SetText('Private words')
    T:SetLanguage('Draconic'); T:PreSend(box)
    assert(T:FindSpeech('Draconic',nil,nil,'CHAT_MSG_WHISPER','Intruder')==nil)
    assert(T:FindSpeech('Draconic',nil,nil,'CHAT_MSG_WHISPER','Friend-Realm'))
end)
test('own-message bypass works',function()
    s.Screen.Self=true; s.Fluency.Common=0
    eq(T:Receive(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Hello','Tester','Common'),nil)
    s.Screen.Self=false
end)
test('learning replies are bounded and accepted once',function()
    Mock.time=Mock.time+31; s.LanguageLearning=true; s.Fluency.Draconic=10
    T:RequestLearning('Teacher','Draconic',10)
    local data=LibStub('AceSerializer-3.0'):Serialize({'LR','Draconic',10000})
    T:ReceiveComm('Tongues2',data,'WHISPER','Teacher'); eq(s.Fluency.Draconic,11)
    T:ReceiveComm('Tongues2',data,'WHISPER','Teacher'); eq(s.Fluency.Draconic,11)
end)
test('expired and mismatched translation replies are ignored',function()
    T:RequestTranslation(DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY','Late','Draconic',100,'[Draconic] abc')
    local count=#Mock.messages
    local serializer=LibStub('AceSerializer-3.0')
    T:ReceiveComm('Tongues2',serializer:Serialize({'TR','CHAT_MSG_SAY',1,'Draconic','wrong','bad-token'}),'WHISPER','Late')
    eq(#Mock.messages,count); Mock.time=Mock.time+21
    T:ReceiveComm('Tongues2',serializer:Serialize({'TR','CHAT_MSG_SAY',1,'Draconic','late'}),'WHISPER','Late')
    eq(#Mock.messages,count)
end)
test('Blizzard-scrambled native text can request a recent translation',function()
    T:Remember('Hello','Hello','Darnassian','CHAT_MSG_SAY')
    assert(T:FindSpeech('Darnassian','Anu dor',nil,'CHAT_MSG_SAY','Peer'))
    assert(not T:FindSpeech('Darnassian','[Darnassian] wrong',nil,'CHAT_MSG_SAY','Peer'))
end)
test('empty language cycle and invalid saved settings are safe',function()
    local fluency=s.Fluency; s.Fluency={}; T:CycleLanguage(); s.Fluency=fluency
    s.AffectFrequency=0/0; s.Dialect='missing'; s.UI.MainMenu.xOfs=math.huge
    T:LoadSettings(); eq(s.AffectFrequency,100); eq(s.Dialect,T.NONE)
    T.UI:Place(T.UI.Frame,'MainMenu')
end)
test('bypassing subsequent messages restores the editbox language',function()
    local box=CreateFrame('EditBox'); box.languageID=7
    T:SetLanguage('Darnassian'); box:SetText('Hello'); T:PreSend(box); eq(box.languageID,2)
    box:SetText('(OOC text)'); T:PreSend(box); eq(box.languageID,7)
end)
test('separate addon traffic restrictions are respected',function()
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=function() return true end
    assert(not T:CommSend('Peer','RT',100,'CHAT_MSG_SAY',1,'Draconic'))
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=nil
end)
test('actual AceComm transport sends and reassembles multipart packets',function()
    -- Drain earlier application packets, then loop a fresh packet through the actual library.
    Mock.time=Mock.time+60; ChatThrottleLib.OnUpdate(ChatThrottleLib.Frame,60)
    Mock.wire={}
    local received
    local endpoint={}; LibStub('AceComm-3.0'):Embed(endpoint)
    endpoint:RegisterComm('TonguesTest',function(prefix,text,distribution,sender) received=text end)
    local text=string.rep('A long message with UTF-8: zażółć. ',35)
    endpoint:SendCommMessage('TonguesTest',text,'WHISPER','Peer')
    for i=1,8 do Mock.time=Mock.time+5; ChatThrottleLib.OnUpdate(ChatThrottleLib.Frame,5) end
    local count=0
    for _,packet in ipairs(Mock.wire) do
        if packet[1]=='TonguesTest' then
            count=count+1; assert(#packet[2]<=255)
            AceComm30Frame:Fire('OnEvent','CHAT_MSG_ADDON',packet[1],packet[2],packet[3],'Peer')
        end
    end
    assert(count>1); eq(received,text)
end)
test('GUI tabs, search, selection, sliders, toggles, reopen and reset',function()
    T.UI:Toggle(); assert(T.UI.Frame:IsShown())
    for _,tab in ipairs(T.UI.Tabs) do tab:Click() end
    T.UI:Pick('Language',T.Language,s.Language,function(language) T:SetLanguage(language) end)
    T.UI.Picker.Search:SetText('Draconic'); assert(T.UI.Picker.Buttons[1].Value=='Draconic')
    T.UI.Picker.Buttons[1]:Click(); eq(s.Language,'Draconic'); assert(not T.UI.Picker:IsShown())
    for _,f in ipairs(Mock.frames) do
        if f.kind=='Slider' then f:SetValue(42) end
        if f.kind=='CheckButton' and f.scripts.OnClick then f:SetChecked(true); f:Click() end
    end
    for _,f in ipairs(Mock.frames) do
        if f.kind=='Button' and f:GetText()=='Preview' then f:Click() end
    end
    T.UI.Mini:Fire('OnDragStart'); T.UI.Mini:Fire('OnDragStop'); assert(Mock.timer); Mock.timer()
    T.UI.Mini:Click('RightButton'); assert(not T.UI.Frame:IsShown()); T.UI.Mini:Click('RightButton')
    T.UI:ResetPosition(); T.UI:Toggle(); T.UI:Toggle(); assert(T.UI.Frame:IsShown())
end)
print(string.format('OK: %d tests; %d TOC Lua files loaded',passed,#loaded))
