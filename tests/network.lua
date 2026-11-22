-- Separate addon globals; actual AceComm/ChatThrottleLib transport in every client.
-- Shuffle whole messages but preserve multipart order, matching the transport contract.
local nativeLoadfile=loadfile
local base={}; for key,value in pairs(_G) do base[key]=value end
local function client(name,saved)
    local env=setmetatable({},{__index=base}); env._G=env
    env.loadfile=function(path)
        local fn,err=nativeLoadfile(path); if fn then setfenv(fn,env) end; return fn,err
    end
    env.dofile=function(path) return assert(env.loadfile(path))() end
    env.dofile('tests/wow_mock.lua')
    local originalName=env.UnitName
    env.UnitName=function(unit) if unit=='player' then return name end; return originalName(unit) end
    local function load(path)
        path=path:gsub('\\','/')
        if path:match('%.xml$') then
            local f=assert(io.open(path)); local xml=f:read('*a'); f:close()
            for child in xml:gmatch('<Script%s+file="([^"]+)"') do load((path:match('^(.-)[^/]+$') or '')..child) end
        elseif path:match('%.lua$') then assert(env.loadfile(path))('Tongues',{}) end
    end
    for line in io.lines('Tongues.toc') do if line:match('%S') and not line:match('^%s*#') then load(line) end end
    if saved then
        env.Tongues_Character=saved.Tongues_Character
        env.Tongues_Global=saved.Tongues_Global
    end
    env.Tongues:Initialize()
    if not saved then
        env.Tongues:SetLanguage('Draconic')
        env.Tongues.Settings.Character.Fluency.Draconic=100
    end
    return {name=name..'-Realm',env=env,T=env.Tongues,read=0}
end
local function advance(clients,seconds)
    for tick=1,seconds*4 do
        for _,c in ipairs(clients) do
            c.env.Mock.time=c.env.Mock.time+0.25
            c.env.ChatThrottleLib.OnUpdate(c.env.ChatThrottleLib.Frame,0.25)
        end
    end
end
local function packets(c)
    local groups,current={},nil
    for i=c.read+1,#c.env.Mock.wire do
        local packet=c.env.Mock.wire[i]
        if packet[1]=='Tongues2' then
            assert(#packet[2]<=255,'Packet exceeds WoW limit')
            local code=packet[2]:byte(1)
            if code==1 then
                assert(not current,'Interleaved multipart stream')
                current={sender=c.name,target=packet[4],parts={packet}}
            elseif code==2 or code==3 then
                assert(current,'Missing multipart start'); current.parts[#current.parts+1]=packet
                if code==3 then groups[#groups+1]=current; current=nil end
            else groups[#groups+1]={sender=c.name,target=packet[4],parts={packet}} end
        else error('Unexpected regular chat send in transport test') end
    end
    assert(not current,'Transport not fully drained'); c.read=#c.env.Mock.wire
    return groups
end
local function deliver(group,destination)
    assert(group.target==destination.name or group.target==destination.name:gsub('%-Realm$',''),'Wrong target')
    for _,packet in ipairs(group.parts) do
        destination.env.AceComm30Frame:Fire('OnEvent','CHAT_MSG_ADDON',packet[1],packet[2],packet[3],group.sender)
    end
end
local function rng(seed) return function(n) seed=(seed*48271)%2147483647; return seed%n+1 end end
local translated,multipart,totalPackets=0,0,0
for seed=1,20 do
    local random=rng(seed)
    local alice,bob,reader=client('Alice'),client('Bob'),client('Reader')
    local clients={alice,bob,reader}; local byName={ [alice.name]=alice,[bob.name]=bob,[reader.name]=reader }
    assert(alice.env.LibStub~=bob.env.LibStub and alice.T.Settings~=reader.T.Settings,'Shared addon state')
    assert(alice.env.ChatThrottleLib~=reader.env.ChatThrottleLib,'Shared throttle state')
    reader.T:SetInCharacter(false)
    local expected={}
    for i=1,8 do
        for _,speaker in ipairs({alice,bob}) do
            local human='Case '..seed..' '..speaker.name..' '..i..': '..string.rep('a',180)
            local box=speaker.env.CreateFrame('EditBox'); box:SetText(human)
            local presend=speaker.env.Mock.events['ChatFrame.OnEditBoxPreSendText']; presend[1](presend[2],box)
            local wire=box:GetText(); assert(wire:find('[Draconic]',1,true),'Speech did not transform')
            local receive=reader.env.Mock.events.CHAT_MSG_SAY
            receive(reader.env.DEFAULT_CHAT_FRAME,'CHAT_MSG_SAY',wire,speaker.name,'Common',nil,nil,nil,nil,nil,nil,nil,i*2+(speaker==alice and 0 or 1))
            expected[human]=true
        end
    end
    advance(clients,8)
    local requests=packets(reader); assert(#requests==16,'Request count: '..#requests)
    while #requests>0 do
        local group=table.remove(requests,random(#requests))
        deliver(group,byName[group.target]); totalPackets=totalPackets+#group.parts
    end
    advance(clients,8)
    local replies={}
    for _,speaker in ipairs({alice,bob}) do
        for _,group in ipairs(packets(speaker)) do
            replies[#replies+1]=group; if #group.parts>1 then multipart=multipart+1 end
        end
    end
    assert(#replies==16,'Missing peer responses: '..#replies)
    while #replies>0 do
        local group=table.remove(replies,random(#replies)); deliver(group,reader); totalPackets=totalPackets+#group.parts
        if random(3)==1 then deliver(group,reader); totalPackets=totalPackets+#group.parts end
    end
    local received=reader.T.CommStats.received
    assert(received==16,'Replies lost or duplicated: '..received); assert(next(reader.T.Pending)==nil,'Pending requests not consumed')
    local seen={}
    for _,message in ipairs(reader.env.Mock.messages) do
        local human=message:match('^%[ManyTongues .-%] [^:]+: (.*)$')
        assert(human and expected[human],'Unexpected/corrupt translation: '..message)
        assert(not seen[human],'Duplicate displayed'); seen[human]=true
    end
    for human in pairs(expected) do assert(seen[human],'Missing translation') end
    translated=translated+received
    if seed%5==0 then collectgarbage('collect') end
end
assert(multipart>0,'Multipart not exercised')
print(string.format('NETWORK OK: 20 scenarios, 60 isolated client instances, %d translations, %d multipart replies, %d delivered packets',translated,multipart,totalPackets))

-- Optional real SavedVariables are read in a restricted data environment and never copied
-- into the repository, logged, written back or transmitted to another client.
local migrated=0
for _,path in ipairs(arg or {}) do
    local state={}
    local chunk=assert(nativeLoadfile(path),'Cannot parse saved settings')
    setfenv(chunk,state)
    local instructions=0
    debug.sethook(function()
        instructions=instructions+10000
        if instructions>1000000 then error('Saved settings exceeded instruction budget') end
    end,'',10000)
    local ok=pcall(chunk)
    debug.sethook()
    assert(ok,'Saved settings are not plain supported data')
    local previous=state.Tongues_Character
    local language=type(previous)=='table' and previous.Language
    local mode
    if type(previous)=='table' then mode=previous.InCharacter end
    local c=client('MigrationTest',state)
    local s=c.T.Settings.Character
    assert(s.SchemaVersion==3)
    if language and c.T.Language[language] then assert(s.Language==language,'Selected language lost') end
    if type(mode)=='boolean' then assert(s.InCharacter==mode,'IC/OOC preference lost') end
    for _,position in pairs(s.UI) do
        if type(position)=='table' then assert(position.relativeTo==nil,'Frame reference in saved position') end
    end
    c.T.UI:Toggle(); c.T.UI:PickLanguages(); c.T.UI.Picker:Hide()
    c.T:ToggleInCharacter(); c.T:ToggleInCharacter()
    assert(type(s.Favorites)=='table' and type(s.Fluency)=='table')
    migrated=migrated+1
end
if migrated>0 then print('MIGRATION OK: '..migrated..' supplied saved-variable files; source files untouched') end

-- A deterministic user-action sequence checks state transitions against a separate model.
local actor=client('ActionTest')
local T,M,s=actor.T,actor.env.Mock,actor.T.Settings.Character
local random=rng(739391)
local model={ic=true,language='Draconic',form=nil,animal=false,favorites={}}
local languages={'Common','Darnassian','Draconic'}
for step=1,500 do
    local action=random(8)
    if action==1 then
        T.UI.Mini.ModeButton:Click(); model.ic=not model.ic
    elseif action==2 then
        model.language=languages[random(#languages)]; model.animal=false
        T:SetLanguage(model.language)
    elseif action==3 then
        local forms={768,5487,false}; local form=forms[random(#forms)] or nil
        if form~=model.form then model.animal=false end
        model.form=form; M.form=form
        T.Frame.scripts.OnEvent(T.Frame,'UPDATE_SHAPESHIFT_FORM')
    elseif action==4 then
        if model.ic and model.form then model.animal=not model.animal end
        T.UI.Mini.FormChoice:Click()
    elseif action==5 then
        local language=languages[random(#languages)]
        model.favorites[language]=not model.favorites[language] or nil
        T:Command('favorite '..language)
    elseif action==6 then
        T.UI.Mini:Click('MiddleButton')
        local picker=T.UI.Picker
        assert(picker:IsShown() and picker.AllowFavorites,'Quick picker did not open')
        local language=languages[random(#languages)]
        picker.Search:SetText(language)
        local target
        for _,button in ipairs(picker.Buttons) do
            if button:IsShown() and button.Value==language then target=button; break end
        end
        assert(target,'Search failed'); target:Click()
        model.language=language; model.animal=false
        assert(not picker:IsShown() and not T.UI.PickerShade:IsShown(),'Picker did not close')
    elseif action==7 then
        local before=model.ic
        T.UI.Mini:Fire('OnMouseWheel',random(2)==1 and 1 or -1)
        model.language=s.Language; model.animal=false
        local favorites=false
        for _,favorite in pairs(model.favorites) do if favorite then favorites=true end end
        if favorites then assert(model.favorites[s.Language],'Cycle left favorite set')
        else assert((s.Fluency[T:GetRealLanguage(s.Language)] or 0)>=30,'Cycle selected an unknown language') end
        assert(before==s.InCharacter,'Cycling changed roleplay mode')
    else
        local box=actor.env.CreateFrame('EditBox'); box.languageID=7
        local text='Zażółć |Hitem:42|h[Unchanged item]|h '..step
        box:SetText(text)
        local before=#(T.History or {})
        local callback=M.events['ChatFrame.OnEditBoxPreSendText']; callback[1](callback[2],box)
        if not model.ic then
            assert(box:GetText()==text and box.languageID==7,'OOC altered outgoing message')
            assert(#(T.History or {})==before,'OOC added speech to translation history')
        end
    end
    local speech=model.animal and (model.form==768 and 'Cat' or 'Bear') or model.language
    assert(s.InCharacter==model.ic and s.Language==model.language,'User preference diverged')
    assert(T:SpeechLanguage()==speech,'Automatic or stale form-language selection')
    assert(T.UI.Mini.ModeButton:GetText()==(model.ic and 'IC' or 'OOC'),'Mode button stale')
    assert(T.UI.Mini.FormChoice:IsShown()==(model.form~=nil),'Form button visibility stale')
    for _,language in ipairs(languages) do assert((s.Favorites[language]==true)==(model.favorites[language]==true),'Favorite diverged') end
end
print('ACTIONS OK: 500 deterministic mode, form, favorite, picker and outgoing-message actions')
