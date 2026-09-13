-- Deliberately excludes removed globals (SendChatMessage, GetSpellInfo, etc.).
Mock = {frames={},messages={},wire={},events={},time=100,restricted=false,locale=os.getenv('TONGUES_LOCALE') or 'enUS'}
local M=Mock
local methods={}
function methods:SetScript(event, fn) self.scripts[event]=fn end
function methods:HookScript(event, fn)
    local old=self.scripts[event]; self.scripts[event]=function(...) if old then old(...) end; fn(...) end
end
function methods:Fire(event, ...) if self.scripts[event] then return self.scripts[event](self,...) end end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:UnregisterAllEvents() self.events={} end
function methods:UnregisterEvent(event) self.events[event]=nil end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width or 640 end
function methods:GetHeight() return self.height or 480 end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(self.point or {'CENTER',UIParent,'CENTER',0,0}) end
function methods:ClearAllPoints() self.point=nil end
function methods:SetText(text) self.text=text; self:Fire('OnTextChanged',false) end
function methods:GetText() return self.text or '' end
function methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function methods:Show() local was=self.shown; self.shown=true; if not was then self:Fire('OnShow') end end
function methods:Hide() local was=self.shown; self.shown=false; if was then self:Fire('OnHide') end end
function methods:IsShown() return self.shown end
function methods:SetChecked(checked) self.checked=checked end
function methods:GetChecked() return self.checked end
function methods:SetValue(value) self.value=value; self:Fire('OnValueChanged',value) end
function methods:GetValue() return self.value end
function methods:SetScrollChild(child) assert(child and child~=self); self.child=child end
function methods:GetID() return self.id or 1 end
function methods:GetName() return self.name end
function methods:SetAttribute(key,value) self[key]=value end
function methods:GetAttribute(key) return self[key] end
function methods:GetTellTarget() return self.target end
function methods:GetChatType() return self.channel or 'SAY' end
function methods:AddMessage(text,...) self.messages=self.messages or {}; table.insert(self.messages,text); table.insert(M.messages,text) end
function methods:Disable() self.disabled=true end
function methods:Enable() self.disabled=false end
function methods:Click(button) if not self.disabled then self:Fire('OnClick',button or 'LeftButton') end end
function methods:CreateFontString(name) return CreateFrame('FontString',name,self) end
function methods:CreateTexture(name) return CreateFrame('Texture',name,self) end
for _,name in ipairs({'SetJustifyH','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetMinMaxValues',
    'SetValueStep','SetObeyStepOnDrag','SetFrameStrata','SetClampedToScreen','SetMovable','EnableMouse',
    'RegisterForDrag','StartMoving','StopMovingOrSizing','SetScale','SetAutoFocus','SetFocus','ClearFocus',
    'SetVerticalScroll','SetMaxLetters','RegisterForClicks','SetOwner','AddLine','SetAlpha','SetParent'}) do
    methods[name]=function(self,...) self[name .. 'Args']={...} end
end
function CreateFrame(kind,name,parent,template)
    if name then assert(not _G[name],'duplicate frame '..name) end
    local f=setmetatable({kind=kind,name=name,parent=parent,template=template,scripts={},events={},shown=true}, {__index=methods})
    M.frames[#M.frames+1]=f
    if name then _G[name]=f end
    return f
end
UIParent=CreateFrame('Frame','UIParent'); UIParent:SetSize(1920,1080)
DEFAULT_CHAT_FRAME=CreateFrame('Frame','ChatFrame1'); DEFAULT_CHAT_FRAME.id=1
GameTooltip=CreateFrame('Frame','GameTooltip')
UISpecialFrames,SlashCmdList={},{}
function GetLocale() return M.locale end
function GetTime() return M.time end
function GetFramerate() return 60 end
function GetNormalizedRealmName() return 'Realm' end
function UnitName(unit) if unit=='target' then return M.target elseif unit=='pet' then return M.pet else return 'Tester' end end
function UnitFullName(unit) return UnitName(unit),'Realm' end
function UnitClass() return 'Druid','DRUID' end
function UnitRace() return 'Night Elf','NightElf' end
function UnitFactionGroup() return 'Alliance' end
function UnitCreatureFamily() return 'Cat' end
function UnitIsPlayer(unit) return unit=='target' and M.target~=nil end
function GetNumLanguages() return 2 end
function GetLanguageByIndex(i) if i==1 then return T_Common or 'Common',7 else return T_Darnassian or 'Darnassian',2 end end
function GetDefaultLanguage() return T_Common or 'Common',7 end
function GetNumShapeshiftForms() return M.form and 1 or 0 end
function GetShapeshiftFormInfo() return 1,true,true,M.form end
function IsSwimming() return false end
function IsFlying() return false end
function IsInGuild() return false end
function IsInGroup() return false end
function IsInRaid() return false end
function UnitIsGroupLeader() return false end
function UnitIsGroupAssistant() return false end
LE_PARTY_CATEGORY_HOME,LE_PARTY_CATEGORY_INSTANCE=1,2
ChatTypeInfo={SAY={r=1,g=1,b=1},EMOTE={r=1,g=.5,b=.5}}
C_AddOns={GetAddOnMetadata=function() return '2.0.0-dev' end}
C_ChatInfo={InChatMessagingLockdown=function() return M.restricted end,
 SendChatMessage=function(...) table.insert(M.wire,{...}) end,
 SendAddonMessage=function(...) table.insert(M.wire,{...}); return 0 end,
 SendAddonMessageLogged=function() return 0 end,RegisterAddonMessagePrefix=function() return true end}
C_BattleNet={SendGameData=function() end}
C_MountJournal={GetMountIDs=function() return {1} end,GetMountInfoByID=function() return M.mount,nil,nil,M.mount~=nil end}
EventRegistry={RegisterCallback=function(_,event,callback,owner) M.events[event]={callback,owner} end}
ChatFrameUtil={AddMessageEventFilter=function(event,callback) M.events[event]=callback end}
Settings={RegisterCanvasLayoutCategory=function(frame,name) return {frame=frame,name=name} end,RegisterAddOnCategory=function() end}
C_Timer={After=function(_,fn) Mock.timer=fn end}
Enum={}
function Ambiguate(name) return name:gsub('%-Realm$','') end
function issecretvalue(value) return type(value)=='table' and value.secret==true end
function securecallfunction(fn,...) return fn(...) end
function hooksecurefunc(object,key,fn)
    assert(type(object)=='table' and type(object[key])=='function','attempt to hook removed API')
end
function geterrorhandler() return function(message) error(message) end end
function wipe(t) for k in pairs(t) do t[k]=nil end; return t end
table.wipe=wipe
strmatch,strsplit,strsub,strfind=strmatch or string.match,function() end,string.sub,string.find

-- WoW extends Lua 5.1 xpcall with variadic arguments.
local originalXpcall=xpcall
function xpcall(fn,handler,...)
    local args,n={...},select('#',...)
    return originalXpcall(function() return fn(unpack(args,1,n)) end,handler)
end
