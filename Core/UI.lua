-- Spellbook-inspired window using Blizzard textures, panel tabs and controls.
local T = Tongues
local UI = T.UI
local function label(parent, text, x, y, width, template)
    local font = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    font:SetPoint("TOPLEFT", x, -y)
    font:SetWidth(width or 620)
    font:SetJustifyH("LEFT")
    font:SetText(text)
    if parent.Parchment then
        font:SetTextColor(0.08,0.045,0.02,1)
        font:SetShadowOffset(0,0)
        font:SetShadowColor(0,0,0,0)
    end
    return font
end
local function button(parent, text, x, y, width, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT", x, -y); b:SetSize(width, 26); b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
local function backdrop(frame)
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,
        insets={left=6,right=6,top=6,bottom=6}})
    frame:SetBackdropColor(1,1,1,1)
    frame:SetBackdropBorderColor(1,0.9,0.72,1)
end
local function parchment(parent, top, bottom)
    local inset = CreateFrame("Frame",nil,parent,"BackdropTemplate")
    inset:SetPoint("TOPLEFT",16,-top); inset:SetPoint("BOTTOMRIGHT",-16,bottom)
    inset:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}})
    inset:SetBackdropColor(0.83,0.73,0.52,1)
    inset:SetBackdropBorderColor(0.64,0.48,0.25,1)
    local paper = inset:CreateTexture(nil,"ARTWORK")
    paper:SetPoint("TOPLEFT",5,-5); paper:SetPoint("BOTTOMRIGHT",-5,5)
    if C_Texture and C_Texture.GetAtlasInfo("QuestDetailsBackgrounds") then
        paper:SetAtlas("QuestDetailsBackgrounds")
    else
        paper:SetTexture("Interface\\QuestFrame\\QuestBG")
        paper:SetTexCoord(0,0.586,0,0.65)
    end
    return inset
end
local function bookIcon(parent, x, y, size)
    local icon = parent:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("TOPLEFT",x,-y); icon:SetSize(size,size)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    icon:SetTexCoord(0.07,0.93,0.07,0.93)
    local rim = parent:CreateTexture(nil,"OVERLAY")
    rim:SetPoint("CENTER",icon,"CENTER",0,0); rim:SetSize(size*1.65,size*1.65)
    rim:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    return icon
end
local function settings() return T.Settings.Character end

-- Shared frame, icon, typography and interaction states for both floating buttons.
local function floatingButton(parent,name,caption)
    local mini = CreateFrame("Button",name,parent,"BackdropTemplate")
    mini:SetSize(174,48); mini:SetClampedToScreen(true); mini:SetMovable(true)
    backdrop(mini)
    mini.Icon = bookIcon(mini,12,10,28)
    local brand = mini:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    brand:SetPoint("TOPLEFT",50,-10); brand:SetWidth(112); brand:SetWordWrap(false); brand:SetText(caption)
    mini.Language = mini:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    mini.Language:SetPoint("TOPLEFT",50,-25); mini.Language:SetWidth(112)
    mini.Language:SetJustifyH("LEFT"); mini.Language:SetWordWrap(false)
    mini:SetFontString(mini.Language)
    local glow = mini:CreateTexture(nil,"HIGHLIGHT")
    glow:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    glow:SetPoint("TOPLEFT",8,-7); glow:SetSize(36,36); glow:SetBlendMode("ADD")
    function mini:Paint()
        local inactive = not settings().Enabled
        local restricted = T:Restricted()
        self.Icon:SetDesaturated(inactive or restricted or not settings().InCharacter)
        brand:SetText(inactive and "Disabled" or restricted and "Chat restricted" or not settings().InCharacter and (caption .. " - OOC") or caption)
        local shade = self.Pressed and 0.65 or 1
        self.Icon:SetVertexColor(shade,shade,shade)
        self:SetBackdropColor(shade,shade,shade,1)
        if inactive then self:SetBackdropBorderColor(0.55,0.55,0.55,1)
        elseif restricted then self:SetBackdropBorderColor(1,0.55,0.18,1)
        elseif self.Hovered then self:SetBackdropBorderColor(1,0.84,0.4,1)
        else self:SetBackdropBorderColor(0.9,0.76,0.52,1) end
    end
    mini:SetScript("OnMouseDown",function(f) f.Pressed=true; f:Paint() end)
    mini:SetScript("OnMouseUp",function(f) f.Pressed=nil; f:Paint() end)
    mini:SetScript("OnEnter",function(f) f.Hovered=true; f:Paint() end)
    mini:SetScript("OnLeave",function(f) f.Hovered=nil; f.Pressed=nil; f:Paint() end)
    return mini
end

function UI:Check(parent, text, key, group, x, y)
    local control = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    control:SetSize(26,26); control:SetPoint("TOPLEFT", x, -y)
    control.Parchment = parent.Parchment
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
        local list=values()
        self:Pick(text,list,getter(),setter,list==T.Language)
    end)
    self.Controls[#self.Controls+1] = function() control:SetText(getter() or T.NONE) end
    return control
end

function UI:Slider(parent, text, getter, setter, y)
    local caption = label(parent,text,12,y,590)
    local control = CreateFrame("Slider",nil,parent,"OptionsSliderTemplate")
    control:SetPoint("TOPLEFT",18,-y-27); control:SetSize(580,18)
    control:SetMinMaxValues(0,100); control:SetValueStep(1); control:SetObeyStepOnDrag(true)
    if control.Low then control.Low:SetText("0%"); control.Low:SetTextColor(0.08,0.045,0.02,1); control.Low:SetShadowOffset(0,0); control.Low:SetShadowColor(0,0,0,0) end
    if control.High then control.High:SetText("100%"); control.High:SetTextColor(0.08,0.045,0.02,1); control.High:SetShadowOffset(0,0); control.High:SetShadowColor(0,0,0,0) end
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
    local formLanguage = T:UpdateFormSpeech()
    self.Mini.Language:SetText(T:SpeechLanguage())
    self.Mini.FormChoice:SetShown(formLanguage ~= nil)
    self.Mini:SetClampRectInsets(0,58,0,formLanguage and -50 or 0)
    if formLanguage then
        self.Mini.FormChoice:SetText("Speak: " .. (T.FormSpeechChoice and settings().Language or formLanguage))
        if settings().Enabled and settings().InCharacter and not T:Restricted() then self.Mini.FormChoice:Enable()
        else self.Mini.FormChoice:Disable() end
    end
    self.Mini:Paint()
    self.Mini.FormChoice:Paint()
    self.Mini.ModeButton:Paint()
    self.Mini:SetShown(not settings().MMH)
    self.Status:SetText(T:Restricted() and "Chat restrictions active — speech processing paused"
        or not settings().Enabled and "Speech processing disabled"
        or "ManyTongues " .. (T.Version or "") .. (settings().InCharacter and "   |   IC speech" or "   |   OOC - outgoing text unchanged"))
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

function UI:PickLanguages()
    self:Pick("Spoken language",T.Language,settings().Language,function(language) T:SetLanguage(language) end,true)
end

function UI:Pick(title, values, selected, callback, allowFavorites)
    if not self.Picker then
        -- Keep the entire selector above the main window's scroll children and tabs.
        local shade = CreateFrame("Frame",nil,self.Frame)
        shade:SetAllPoints(self.Frame); shade:SetFrameStrata("FULLSCREEN_DIALOG")
        shade:SetFrameLevel(self.Frame:GetFrameLevel()+100); shade:EnableMouse(true)
        local dim = shade:CreateTexture(nil,"BACKGROUND")
        dim:SetAllPoints(shade); dim:SetColorTexture(0,0,0,0.68)
        shade:Hide(); self.PickerShade=shade
        local picker = CreateFrame("Frame","ManyTonguesSelectionWindow",self.Frame,"BackdropTemplate")
        picker:SetSize(400,480); picker:SetPoint("CENTER"); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetClampedToScreen(true)
        picker:SetFrameLevel(shade:GetFrameLevel()+10); picker:EnableMouse(true)
        picker:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,
            insets={left=6,right=6,top=6,bottom=6}})
        picker:SetBackdropColor(0.075,0.055,0.035,1)
        picker:SetBackdropBorderColor(1,0.85,0.55,1)
        parchment(picker,82,16)
        picker.Title = label(picker,"",28,16,328,"GameFontNormalLarge")
        local close = CreateFrame("Button",nil,picker,"UIPanelCloseButton")
        close:SetPoint("TOPRIGHT",-3,-3); close:SetScript("OnClick",function() picker:Hide() end)
        local search = CreateFrame("EditBox",nil,picker,"InputBoxTemplate")
        search:SetPoint("TOPLEFT",28,-52); search:SetSize(picker:GetWidth()-56,26); search:SetAutoFocus(false)
        search:SetScript("OnEscapePressed",function() picker:Hide() end)
        local scroll = CreateFrame("ScrollFrame",nil,picker,"UIPanelScrollFrameTemplate")
        -- Inset the rows inside the parchment and reserve a separate scrollbar gutter.
        scroll:SetPoint("TOPLEFT",28,-100); scroll:SetPoint("BOTTOMRIGHT",-48,28)
        local content = CreateFrame("Frame",nil,scroll); content:SetSize(picker:GetWidth()-76,1); content.Parchment=true; scroll:SetScrollChild(content)
        picker.Search,picker.Scroll,picker.Content,picker.Buttons,picker.FavoriteButtons = search,scroll,content,{},{}
        search:SetScript("OnTextChanged",function() self:UpdatePicker() end)
        picker:SetScript("OnHide",function() search:ClearFocus(); shade:Hide() end)
        shade:SetScript("OnMouseDown",function() picker:Hide() end)
        self.Frame:HookScript("OnHide",function() picker:Hide() end)
        table.insert(UISpecialFrames,"ManyTonguesSelectionWindow")
        self.Picker = picker
    end
    local p = self.Picker
    p.Values,p.Selected,p.Callback,p.AllowFavorites = values,selected,callback,allowFavorites
    p.Title:SetText(title); p.Search:SetText(""); p.Scroll:SetVerticalScroll(0)
    self:UpdatePicker(); self.PickerShade:Show(); p:Show(); p.Search:SetFocus()
end

function UI:UpdatePicker()
    local p = self.Picker
    if not p or not p.Values then return end
    local query,index = p.Search:GetText():lower(),0
    local values=T.Keys(p.Values)
    if p.AllowFavorites then
        table.sort(values,function(a,b)
            local favoriteA,favoriteB=settings().Favorites[a]==true,settings().Favorites[b]==true
            if favoriteA~=favoriteB then return favoriteA end
            return a<b
        end)
    end
    for _, value in ipairs(values) do
        if value:lower():find(query,1,true) then
            index = index+1
            local b = p.Buttons[index]
            if not b then
                b = button(p.Content,"",0,(index-1)*28,p.Content:GetWidth(),function(control)
                    p.Callback(control.Value); p:Hide(); T:Refresh()
                end)
                p.Buttons[index] = b
            end
            b:SetWidth(p.Content:GetWidth()-(p.AllowFavorites and 32 or 0))
            local favorite=p.FavoriteButtons[index]
            if p.AllowFavorites then
                if not favorite then
                    favorite=button(p.Content,"",p.Content:GetWidth()-28,(index-1)*28,28,function(control)
                        T:SetFavorite(control.Value,not settings().Favorites[control.Value])
                        GameTooltip:Hide(); self:UpdatePicker()
                    end)
                    favorite:SetScript("OnEnter",function(control)
                        GameTooltip:SetOwner(control,"ANCHOR_RIGHT")
                        GameTooltip:SetText(settings().Favorites[control.Value] and "Remove favorite" or "Add favorite")
                        GameTooltip:Show()
                    end)
                    favorite:SetScript("OnLeave",function() GameTooltip:Hide() end)
                    p.FavoriteButtons[index]=favorite
                end
                favorite.Value=value
                favorite:SetText(settings().Favorites[value] and "*" or "+"); favorite:Show()
            elseif favorite then favorite:Hide() end
            b.Value = value
            b:SetText((value == p.Selected and "> " or "") .. value); b:Show()
        end
    end
    for i=index+1,#p.Buttons do
        p.Buttons[i]:Hide()
        if p.FavoriteButtons[i] then p.FavoriteButtons[i]:Hide() end
    end
    p.Content:SetHeight(math.max(1,index*28))
end

function UI:Build()
    if self.Frame then return end
    self.Controls = {}
    local frame = CreateFrame("Frame","ManyTonguesMainWindow",UIParent,"BackdropTemplate")
    frame:SetSize(700,640); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop",function(f) f:StopMovingOrSizing(); self:SavePosition(f,"MainMenu") end)
    frame:SetScript("OnShow",function(f)
        f:SetScale(math.min(1,(UIParent:GetWidth()-30)/700,(UIParent:GetHeight()-30)/640)); self:Refresh()
    end)
    backdrop(frame); self.Frame = frame; self:Place(frame,"MainMenu")
    bookIcon(frame,28,24,40)
    label(frame,"ManyTongues",86,22,540,"GameFontNormalHuge")
    label(frame,"Languages, dialects & the art of conversation",86,54,540,"GameFontNormalSmall")
    self.Status = label(frame,"",26,613,640,"GameFontNormalSmall")
    parchment(frame,122,42)
    local close = CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-4,-4); close:SetScript("OnClick",function() frame:Hide() end)
    table.insert(UISpecialFrames,"ManyTonguesMainWindow")
    local scroll = CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",28,-138); scroll:SetPoint("BOTTOMRIGHT",-46,58)
    self.Pages,self.Tabs = {},{}
    for index, name in ipairs({"Speech","Languages","Channels","Translators"}) do
        local page = CreateFrame("Frame",nil,scroll); page:SetSize(620,550); page.Parchment=true; page:Hide(); self.Pages[index] = page
        local tab = CreateFrame("Button",nil,frame,"PanelTopTabButtonTemplate")
        tab:SetPoint("TOPLEFT",24+(index-1)*162,-88); tab:SetSize(150,32); tab:SetText(name)
        tab:SetScript("OnClick",function()
            for _, other in ipairs(self.Pages) do other:Hide() end
            scroll:SetScrollChild(page); page:Show(); scroll:SetVerticalScroll(0)
            for _, other in ipairs(self.Tabs) do PanelTemplates_DeselectTab(other) end
            PanelTemplates_SelectTab(tab)
        end)
        self.Tabs[index] = tab
    end
    local speech = self.Pages[1]
    self:Check(speech,"Enable ManyTongues", "Enabled",nil,12,0)
    self:Check(speech,"Speak in character (IC)", "InCharacter",nil,322,0)
    self:Choice(speech,"Spoken language",function() return T.Language end,function() return settings().Language end,function(v) T:SetLanguage(v) end,42)
    self:Choice(speech,"Dialect",function() return T.Dialect end,function() return settings().Dialect end,function(v) settings().Dialect=v end,82)
    self:Choice(speech,"Speech effect",function() return T.Affect end,function() return settings().Affect end,function(v) settings().Affect=v end,122)
    self:Slider(speech,"Effect frequency",function() return settings().AffectFrequency end,function(v) settings().AffectFrequency=v end,164)
    self:Choice(speech,"Roleplay filter",function() return T.Filter end,function() return settings().Filter end,function(v) settings().Filter=v end,246)
    self:Check(speech,"Offer animal language on the floating button", "ShapeshiftLanguage",nil,12,286)
    local function languageOptions() local values=merge({T.Language}); values[T.NONE]=true; return values end
    self:Choice(speech,"Animal language (<None> = form)",languageOptions,function() return settings().FormLanguage end,function(v) settings().FormLanguage=v end,328)
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
    label(languages,"Select a language and set how much your character understands.\nMark favorites with + in the language list; they take priority when cycling.",12,40,590)
    local selected = settings().Language
    self:Choice(languages,"Language",function() return T.Language end,function() return selected end,function(v) selected=v end,104)
    self:Slider(languages,"Fluency",function() return settings().Fluency[T:GetRealLanguage(selected)] or 0 end,function(v) T:SetFluency(selected,v) end,158)
    button(languages,"Speak this language",12,242,210,function() T:SetLanguage(selected) end)
    button(languages,"Forget language",240,242,180,function() settings().Fluency[T:GetRealLanguage(selected)]=nil; T:Refresh() end)
    local favorite=button(languages,"",440,242,168,function()
        T:SetFavorite(selected,not settings().Favorites[selected])
    end)
    self.Controls[#self.Controls+1]=function()
        favorite:SetText(settings().Favorites[selected] and "Unfavorite language" or "Favorite language")
    end
    self:Check(languages,"Learn gradually from other ManyTongues users", "LanguageLearning",nil,12,302)
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

    local mini = floatingButton(UIParent,"ManyTonguesLanguageButton","ManyTongues")
    mini:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp"); mini:RegisterForDrag("LeftButton")
    mini:SetScript("OnDragStart",function(f) f.Dragged=true; f:StartMoving() end)
    mini:SetScript("OnDragStop",function(f)
        f:StopMovingOrSizing(); self:SavePosition(f,"MiniMenu")
        C_Timer.After(0,function() f.Dragged=nil end)
    end)
    mini:SetScript("OnClick",function(f,b)
        if f.Dragged then f.Dragged=nil; return end
        if b=="RightButton" then self:Toggle()
        elseif b=="MiddleButton" or IsShiftKeyDown() then self:PickLanguages()
        else T:CycleLanguage() end
    end)
    mini:EnableMouseWheel(true)
    mini:SetScript("OnMouseWheel",function(_,delta) T:CycleLanguage(delta>0 and -1 or 1) end)
    mini:SetScript("OnEnter",function(f)
        f.Hovered=true; f:Paint()
        GameTooltip:SetOwner(f,"ANCHOR_RIGHT"); GameTooltip:SetText("ManyTongues")
        GameTooltip:AddLine("Left-click / wheel: cycle favorites or known languages\nShift-left / middle-click: choose language and favorites\nRight-click: settings\nIC/OOC button: toggle roleplay speech\nDrag: move",1,1,1); GameTooltip:Show()
    end)
    mini:SetScript("OnLeave",function(f)
        f.Hovered=nil; f.Pressed=nil; f:Paint(); GameTooltip:Hide()
    end)
    mini.ModeButton=CreateFrame("Button",nil,mini,"BackdropTemplate")
    local mode=mini.ModeButton
    mode:SetSize(56,48); mode:SetPoint("TOPLEFT",mini,"TOPRIGHT",2,0); backdrop(mode)
    local modeText=mode:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    modeText:SetPoint("CENTER"); mode:SetFontString(modeText)
    function mode:Paint()
        self:SetText(settings().InCharacter and "IC" or "OOC")
        local shade=self.Pressed and 0.65 or 1
        self:SetBackdropColor(shade,shade,shade,1)
        if self.Hovered then self:SetBackdropBorderColor(1,0.84,0.4,1)
        elseif settings().InCharacter then self:SetBackdropBorderColor(0.9,0.76,0.52,1)
        else self:SetBackdropBorderColor(0.55,0.55,0.55,1) end
    end
    mode:SetScript("OnClick",function() T:ToggleInCharacter() end)
    mode:SetScript("OnMouseDown",function(f) f.Pressed=true; f:Paint() end)
    mode:SetScript("OnMouseUp",function(f) f.Pressed=nil; f:Paint() end)
    mode:SetScript("OnEnter",function(f)
        f.Hovered=true; f:Paint(); GameTooltip:SetOwner(f,"ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle IC / OOC")
        GameTooltip:AddLine("OOC sends your text unchanged. Incoming translations remain active.",1,1,1,true)
        GameTooltip:Show()
    end)
    mode:SetScript("OnLeave",function(f) f.Hovered=nil; f.Pressed=nil; f:Paint(); GameTooltip:Hide() end)
    mini.FormChoice = floatingButton(mini,nil,"Druid form")
    mini.FormChoice:SetPoint("TOPLEFT",mini,"BOTTOMLEFT",0,-2)
    mini.FormChoice:RegisterForClicks("LeftButtonUp")
    mini.FormChoice:SetScript("OnClick",function() T:ToggleFormSpeech() end)
    mini.FormChoice:Hide()
    self.Mini=mini; self:Place(mini,"MiniMenu")
    if not settings().UI.MiniMenu.point then mini:ClearAllPoints(); mini:SetPoint("CENTER",UIParent,"CENTER",0,220) end

    local panel = CreateFrame("Frame")
    label(panel,"ManyTongues",16,16,600,"GameFontNormalLarge")
    label(panel,"Languages, dialects, effects and translations for roleplay.",16,54,600)
    button(panel,"Open ManyTongues settings",16,98,240,function() self.Frame:Show(); self:Refresh() end)
    self.Category=Settings.RegisterCanvasLayoutCategory(panel,"ManyTongues")
    Settings.RegisterAddOnCategory(self.Category)
end
