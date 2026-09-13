-- Standalone, scrollable settings window. Uses supported basic frame templates.
local T = Tongues
local UI = T.UI
local function label(parent, text, x, y, width, template)
    local font = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    font:SetPoint("TOPLEFT", x, -y)
    font:SetWidth(width or 620)
    font:SetJustifyH("LEFT")
    font:SetText(text)
    return font
end
local function button(parent, text, x, y, width, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT", x, -y); b:SetSize(width, 26); b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
local function backdrop(frame)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(0.045,0.055,0.075,0.98)
    frame:SetBackdropBorderColor(0.3,0.36,0.43,1)
end
local function settings() return T.Settings.Character end

function UI:Check(parent, text, key, group, x, y)
    local control = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    control:SetSize(26,26); control:SetPoint("TOPLEFT", x, -y)
    local caption = label(control,text,30,6,group and 240 or 550)
    control:SetScript("OnClick",function(self)
        local values = group and settings()[group] or settings()
        values[key] = self:GetChecked() and true or false
        T:Refresh()
    end)
    self.Controls[#self.Controls+1] = function() control:SetChecked((group and settings()[group] or settings())[key]) end
    return control, caption
end

function UI:Choice(parent, text, values, getter, setter, y)
    label(parent,text,12,y+6,260)
    local control = button(parent,"",278,y,330,function()
        self:Pick(text,values(),getter(),setter)
    end)
    self.Controls[#self.Controls+1] = function() control:SetText(getter() or T.NONE) end
    return control
end

function UI:Slider(parent, text, getter, setter, y)
    local caption = label(parent,text,12,y,590)
    local control = CreateFrame("Slider",nil,parent,"OptionsSliderTemplate")
    control:SetPoint("TOPLEFT",18,-y-27); control:SetSize(580,18)
    control:SetMinMaxValues(0,100); control:SetValueStep(1); control:SetObeyStepOnDrag(true)
    if control.Low then control.Low:SetText("0%") end
    if control.High then control.High:SetText("100%") end
    control:SetScript("OnValueChanged",function(_, value)
        if self.Refreshing then return end
        setter(math.floor(value+0.5)); T:Refresh()
    end)
    self.Controls[#self.Controls+1] = function()
        local value = getter(); control:SetValue(value); caption:SetText(text .. ": " .. string.format("%.0f%%",value))
    end
    return control
end

function UI:SavePosition(frame, key)
    local point, _, relativePoint, x, y = frame:GetPoint()
    settings().UI[key] = {point=point,relativePoint=relativePoint,xOfs=x,yOfs=y}
end

function UI:Place(frame, key)
    local p = settings().UI[key] or {}
    local anchors = {TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,CENTER=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    frame:ClearAllPoints()
    frame:SetPoint(anchors[p.point] and p.point or "CENTER", UIParent,
        anchors[p.relativePoint] and p.relativePoint or "CENTER",T.Number(p.xOfs,0,-3000,3000),T.Number(p.yOfs,0,-2000,2000))
end

function UI:Refresh()
    if not self.Frame or self.Refreshing then return end
    self.Refreshing = true
    for _, refresh in ipairs(self.Controls) do refresh() end
    self.Mini:SetText("Tongues\n" .. settings().Language)
    self.Mini:SetShown(not settings().MMH)
    self.Status:SetText(T:Restricted() and "Chat restrictions active — speech processing paused" or "Ready · " .. (T.Version or ""))
    self.Refreshing = false
end

function UI:Toggle()
    self.Frame:SetShown(not self.Frame:IsShown())
    self:Refresh()
end

function UI:ResetPosition()
    settings().UI.MainMenu, settings().UI.MiniMenu = {}, {}
    self:Place(self.Frame,"MainMenu"); self:Place(self.Mini,"MiniMenu")
    self.Mini:ClearAllPoints(); self.Mini:SetPoint("CENTER",UIParent,"CENTER",0,220)
end

function UI:Pick(title, values, selected, callback)
    if not self.Picker then
        local picker = CreateFrame("Frame","TonguesSelectionWindow",self.Frame,"BackdropTemplate")
        picker:SetSize(400,460); picker:SetPoint("CENTER"); picker:SetFrameStrata("DIALOG"); picker:SetClampedToScreen(true)
        backdrop(picker)
        picker.Title = label(picker,"",16,16,340,"GameFontNormalLarge")
        local close = CreateFrame("Button",nil,picker,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-3,-3); close:SetScript("OnClick",function() picker:Hide() end)
        local search = CreateFrame("EditBox",nil,picker,"InputBoxTemplate")
        search:SetPoint("TOPLEFT",22,-52); search:SetSize(350,26); search:SetAutoFocus(false)
        search:SetScript("OnEscapePressed",function() picker:Hide() end)
        local scroll = CreateFrame("ScrollFrame",nil,picker,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",16,-94); scroll:SetPoint("BOTTOMRIGHT",-36,16)
        local content = CreateFrame("Frame",nil,scroll); content:SetSize(344,1); scroll:SetScrollChild(content)
        picker.Search,picker.Scroll,picker.Content,picker.Buttons = search,scroll,content,{}
        search:SetScript("OnTextChanged",function() self:UpdatePicker() end)
        picker:SetScript("OnHide",function() search:ClearFocus() end)
        table.insert(UISpecialFrames,"TonguesSelectionWindow")
        self.Picker = picker
    end
    local p = self.Picker
    p.Values,p.Selected,p.Callback = values,selected,callback
    p.Title:SetText(title); p.Search:SetText(""); p.Scroll:SetVerticalScroll(0)
    self:UpdatePicker(); p:Show(); p.Search:SetFocus()
end

function UI:UpdatePicker()
    local p = self.Picker
    if not p or not p.Values then return end
    local query,index = p.Search:GetText():lower(),0
    for _, value in ipairs(T.Keys(p.Values)) do
        if value:lower():find(query,1,true) then
            index = index+1
            local b = p.Buttons[index]
            if not b then
                b = button(p.Content,"",0,(index-1)*28,340,function(control)
                    p.Callback(control.Value); p:Hide(); T:Refresh()
                end)
                p.Buttons[index] = b
            end
            b.Value = value
            b:SetText((value == p.Selected and "> " or "") .. value); b:Show()
        end
    end
    for i=index+1,#p.Buttons do p.Buttons[i]:Hide() end
    p.Content:SetHeight(math.max(1,index*28))
end

function UI:Build()
    if self.Frame then return end
    self.Controls = {}
    local frame = CreateFrame("Frame","TonguesMainWindow",UIParent,"BackdropTemplate")
    frame:SetSize(700,600); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop",function(f) f:StopMovingOrSizing(); self:SavePosition(f,"MainMenu") end)
    frame:SetScript("OnShow",function(f)
        f:SetScale(math.min(1,(UIParent:GetWidth()-30)/700,(UIParent:GetHeight()-30)/600)); self:Refresh()
    end)
    backdrop(frame); self.Frame = frame; self:Place(frame,"MainMenu")
    label(frame,"Tongues",22,20,600,"GameFontNormalHuge")
    self.Status = label(frame,"",22,54,640,"GameFontDisableSmall")
    local close = CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() frame:Hide() end)
    table.insert(UISpecialFrames,"TonguesMainWindow")
    local scroll = CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",20,-124); scroll:SetPoint("BOTTOMRIGHT",-40,24)
    self.Pages,self.Tabs = {},{}
    for index, name in ipairs({"Speech","Languages","Channels","Translators"}) do
        local page = CreateFrame("Frame",nil,scroll); page:SetSize(628,550); page:Hide(); self.Pages[index] = page
        self.Tabs[index] = button(frame,name,20+(index-1)*164,86,154,function()
            for _, other in ipairs(self.Pages) do other:Hide() end
            scroll:SetScrollChild(page); page:Show(); scroll:SetVerticalScroll(0)
            for _, tab in ipairs(self.Tabs) do tab:Enable() end
            self.Tabs[index]:Disable()
        end)
    end
    local speech = self.Pages[1]
    self:Check(speech,"Enable Tongues", "Enabled",nil,12,0)
    self:Choice(speech,"Spoken language",function() return T.Language end,function() return settings().Language end,function(v) T:SetLanguage(v) end,42)
    self:Choice(speech,"Dialect",function() return T.Dialect end,function() return settings().Dialect end,function(v) settings().Dialect=v end,82)
    self:Choice(speech,"Speech effect",function() return T.Affect end,function() return settings().Affect end,function(v) settings().Affect=v end,122)
    self:Slider(speech,"Effect frequency",function() return settings().AffectFrequency end,function(v) settings().AffectFrequency=v end,164)
    self:Choice(speech,"Roleplay filter",function() return T.Filter end,function() return settings().Filter end,function(v) settings().Filter=v end,246)
    self:Check(speech,"Automatically switch language in druid forms", "ShapeshiftLanguage",nil,12,286)
    local function languageOptions() local values=merge({T.Language}); values[T.NONE]=true; return values end
    self:Choice(speech,"Form language (<None> = auto)",languageOptions,function() return settings().FormLanguage end,function(v) settings().FormLanguage=v end,328)
    self:Choice(speech,"Pet language (<None> = auto)",languageOptions,function() return settings().PetLanguage end,function(v) settings().PetLanguage=v end,368)
    self:Choice(speech,"Mount language (<None> = auto)",languageOptions,function() return settings().MountLanguage end,function(v) settings().MountLanguage=v end,408)
    self:Check(speech,"Hide floating language button", "MMH",nil,12,452)
    label(speech,"Preview a /say message (nothing is sent)",12,500,600,"GameFontNormal")
    local input = CreateFrame("EditBox",nil,speech,"InputBoxTemplate")
    input:SetPoint("TOPLEFT",18,-532); input:SetSize(580,28); input:SetAutoFocus(false); input:SetMaxLetters(255)
    input:SetText("Hello, my friend."); input:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    local preview = label(speech,"",12,606,590)
    button(speech,"Preview",12,570,130,function()
        local message = T:PrepareMessage(input:GetText(),"SAY"); preview:SetText(message)
    end)
    button(speech,"Reset window positions",170,570,230,function() self:ResetPosition() end)
    speech:SetHeight(720)

    local languages = self.Pages[2]
    label(languages,"Understanding languages",12,4,590,"GameFontNormalLarge")
    label(languages,"Select a language and set how much your character understands.\n30% or more includes it in the floating button's language cycle.",12,40,590)
    local selected = settings().Language
    self:Choice(languages,"Language",function() return T.Language end,function() return selected end,function(v) selected=v end,104)
    self:Slider(languages,"Fluency",function() return settings().Fluency[T:GetRealLanguage(selected)] or 0 end,function(v) T:SetFluency(selected,v) end,158)
    button(languages,"Speak this language",12,242,210,function() T:SetLanguage(selected) end)
    button(languages,"Forget language",240,242,180,function() settings().Fluency[T:GetRealLanguage(selected)]=nil; T:Refresh() end)
    self:Check(languages,"Learn gradually from other Tongues users", "LanguageLearning",nil,12,302)
    local known = label(languages,"",12,352,590)
    self.Controls[#self.Controls+1] = function()
        local lines={"Known languages:"}
        for _, language in ipairs(T.Keys(settings().Fluency)) do
            lines[#lines+1]=language .. "  —  " .. string.format("%.0f%%",settings().Fluency[language])
        end
        known:SetText(table.concat(lines,"\n")); languages:SetHeight(390+#lines*18)
    end

    local channels = self.Pages[3]
    label(channels,"Keep these channels readable",12,0,600,"GameFontNormalLarge")
    label(channels,"Checked channels skip language processing in both directions.",12,32,600)
    local groups={{"Party","Party"},{"Raid","Raid"},{"RaidAlert","Raid warning"},{"Guild","Guild"},
        {"Officer","Officer"},{"Battleground","Instance"},{"Targetted","Whispers"}}
    for index, group in ipairs(groups) do self:Check(channels,group[2],group[1],"Screen",12+((index-1)%2)*310,70+math.floor((index-1)/2)*34) end
    self:Check(channels,"Own incoming messages","Self","Screen",322,172)
    label(channels,"Share readable translations",12,244,600,"GameFontNormalLarge")
    label(channels,"These options send extra readable copies to the selected recipients.\nCopies are sent only when the relevant group/channel is available.",12,280,600)
    local copies={{"Self","Show a local copy"},{"Targetted","Whisper current target"},{"Party","Party"},{"Raid","Raid"},
        {"RaidAlert","Raid warning"},{"Guild","Guild"},{"Officer","Officer"},{"Battleground","Instance"}}
    for index, group in ipairs(copies) do self:Check(channels,group[2],group[1],"Translations",12+((index-1)%2)*310,338+math.floor((index-1)/2)*34) end
    channels:SetHeight(520)

    local translators = self.Pages[4]
    label(translators,"Personal translators",12,0,600,"GameFontNormalLarge")
    label(translators,"Players on this list receive readable whispers when you speak.\nUse Name-Realm for players from another realm.",12,40,590)
    local name = CreateFrame("EditBox",nil,translators,"InputBoxTemplate")
    name:SetPoint("TOPLEFT",18,-104); name:SetSize(360,28); name:SetAutoFocus(false); name:SetMaxLetters(100)
    name:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    local function add()
        if T:AddTranslator(name:GetText()) then name:SetText(""); name:ClearFocus() else T:Print("Enter a new valid player name.") end
    end
    name:SetScript("OnEnterPressed",add); button(translators,"Add",400,104,120,add)
    local rows = {}
    self.Controls[#self.Controls+1] = function()
        for index, player in ipairs(settings().Translators) do
            if not rows[index] then
                local row = {label=label(translators,"",12,160+(index-1)*34,390)}
                row.remove = button(translators,"Remove",420,152+(index-1)*34,140,function(b) T:RemoveTranslator(b.Player) end)
                rows[index]=row
            end
            local row=rows[index]; row.label:SetText(player); row.label:Show(); row.remove.Player=player; row.remove:Show()
        end
        for index=#settings().Translators+1,#rows do rows[index].label:Hide(); rows[index].remove:Hide() end
        translators:SetHeight(200+#settings().Translators*34)
    end
    self.Tabs[1]:Click()
    frame:Hide()

    local mini = CreateFrame("Button","TonguesLanguageButton",UIParent,"UIPanelButtonTemplate")
    mini:SetSize(130,36); mini:SetClampedToScreen(true); mini:SetMovable(true)
    mini:RegisterForClicks("LeftButtonUp","RightButtonUp"); mini:RegisterForDrag("LeftButton")
    mini:SetScript("OnDragStart",function(f) f.Dragged=true; f:StartMoving() end)
    mini:SetScript("OnDragStop",function(f)
        f:StopMovingOrSizing(); self:SavePosition(f,"MiniMenu")
        C_Timer.After(0,function() f.Dragged=nil end)
    end)
    mini:SetScript("OnClick",function(f,b)
        if f.Dragged then f.Dragged=nil; return end
        if b=="RightButton" then self:Toggle() else T:CycleLanguage() end
    end)
    mini:SetScript("OnEnter",function(f)
        GameTooltip:SetOwner(f,"ANCHOR_RIGHT"); GameTooltip:SetText("Tongues")
        GameTooltip:AddLine("Left-click: next language\nRight-click: settings\nDrag: move",1,1,1); GameTooltip:Show()
    end)
    mini:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.Mini=mini; self:Place(mini,"MiniMenu")
    if not settings().UI.MiniMenu.point then mini:ClearAllPoints(); mini:SetPoint("CENTER",UIParent,"CENTER",0,220) end

    local panel = CreateFrame("Frame")
    label(panel,"Tongues",16,16,600,"GameFontNormalLarge")
    label(panel,"Languages, dialects, effects and translations for roleplay.",16,54,600)
    button(panel,"Open Tongues settings",16,98,240,function() self.Frame:Show(); self:Refresh() end)
    self.Category=Settings.RegisterCanvasLayoutCategory(panel,"Tongues")
    Settings.RegisterAddOnCategory(self.Category)
end
