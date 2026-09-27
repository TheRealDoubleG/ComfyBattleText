ComfyBattleText = ComfyBattleText or {}
local A = ComfyBattleText

A.messagePool = A.messagePool or {incoming={}, outgoing={}, notifications={}}
A.activeMessages = A.activeMessages or {}
A.nameplatePool = A.nameplatePool or {}
A.activeNameplateMessages = A.activeNameplateMessages or {}
A.nameplateByGUID = A.nameplateByGUID or {}

local DEFAULT_AREAS = {
    incoming = {x=-285,y=0,width=250,height=330},
    outgoing = {x=285,y=0,width=250,height=330},
    notifications = {x=0,y=175,width=320,height=220},
}

local SCHOOL_COLORS = {
    [1]  = {0.88,0.80,0.58},
    [2]  = {1.00,0.90,0.25},
    [4]  = {1.00,0.35,0.12},
    [8]  = {0.30,0.95,0.35},
    [16] = {0.35,0.80,1.00},
    [32] = {0.68,0.38,0.92},
    [64] = {0.88,0.45,1.00},
}

local function SafeNumber(v)
    local ok,n = pcall(tonumber,v)
    if ok then return n end
end

local function SafeBool(v)
    local ok,b = pcall(function() return v and true or false end)
    if ok then return b end
    return false
end

local function Clamp(v,lo,hi)
    v=SafeNumber(v) or lo
    if v<lo then return lo end
    if v>hi then return hi end
    return v
end

local function CompactNumber(value)
    value=math.max(0,SafeNumber(value) or 0)
    if value>=1000000 then
        local v=value/1000000
        return (v>=10 and string.format("%.0fm",v) or string.format("%.1fm",v)):gsub("%.0m","m")
    elseif value>=1000 then
        local v=value/1000
        return (v>=10 and string.format("%.0fk",v) or string.format("%.1fk",v)):gsub("%.0k","k")
    end
    return tostring(math.floor(value+0.5))
end

local function SpellIcon(spellID)
    spellID=SafeNumber(spellID)
    if not spellID then return nil end
    if C_Spell and type(C_Spell.GetSpellTexture)=="function" then
        local ok,v=pcall(C_Spell.GetSpellTexture,spellID)
        if ok and v then return v end
    end
    if type(GetSpellTexture)=="function" then
        local ok,v=pcall(GetSpellTexture,spellID)
        if ok and v then return v end
    end
    if type(GetSpellInfo)=="function" then
        local ok,_,_,icon=pcall(GetSpellInfo,spellID)
        if ok and icon then return icon end
    end
end

local function SchoolColor(school)
    school=SafeNumber(school) or 1
    for bit,color in pairs(SCHOOL_COLORS) do
        if bit32 and type(bit32.band)=="function" then
            local ok,v=pcall(bit32.band,school,bit)
            if ok and v~=0 then return color end
        elseif school==bit then
            return color
        end
    end
    return SCHOOL_COLORS[1]
end

local function MissText(value)
    value=tostring(value or "MISS")
    local map={
        MISS="MISS", DODGE="DODGE", PARRY="PARRY", BLOCK="BLOCK",
        EVADE="EVADE", IMMUNE="IMMUNE", DEFLECT="DEFLECT", REFLECT="REFLECT",
        RESIST="RESIST", ABSORB="ABSORB",
    }
    return map[value] or value
end

function A:FormatAmount(amount)
    amount=SafeNumber(amount) or 0
    if self.db and self.db.battle.appearance.shortNumbers then return CompactNumber(amount) end
    return tostring(math.floor(amount+0.5))
end

function A:DecorateText(text,spellID,spellName)
    local cfg=self.db and self.db.battle and self.db.battle.appearance
    if not cfg then return tostring(text or "") end
    local out=tostring(text or "")
    if cfg.showSpellIcon and spellID then
        local icon=SpellIcon(spellID)
        if icon then out="|T"..tostring(icon)..":16:16:0:0|t "..out end
    end
    if cfg.showSpellName and spellName and spellName~="" then out=out.."  "..tostring(spellName) end
    return out
end

function A:GetAreaConfig(key)
    return self.db and self.db.battle and self.db.battle.areas and self.db.battle.areas[key]
end

function A:GetRouteConfig(key)
    return self.db and self.db.battle and self.db.battle[key]
end

function A:SaveAreaPosition(key)
    local frame=self.areaFrames and self.areaFrames[key]
    local cfg=self:GetAreaConfig(key)
    if not frame or not cfg then return end
    local x,y=frame:GetCenter()
    local ux,uy=UIParent:GetCenter()
    if x and y and ux and uy then cfg.x=x-ux; cfg.y=y-uy end
end

function A:CreateAreaFrame(key,label)
    self.areaFrames=self.areaFrames or {}
    if self.areaFrames[key] then return self.areaFrames[key] end

    local f=CreateFrame("Frame","ComfyBattleTextArea_"..key,UIParent,"BackdropTemplate")
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10})
    f:SetBackdropColor(0.03,0.03,0.03,0.28)
    f:SetBackdropBorderColor(1,0.82,0,0.75)

    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    title:SetPoint("CENTER")
    title:SetText(label)
    title:SetTextColor(1,0.82,0,0.9)
    f.anchorTitle=title

    f:SetScript("OnDragStart",function(self)
        if not A.db or not A.db.battle.appearance.unlockAreas then return end
        self:StartMoving()
    end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing()
        A:SaveAreaPosition(key)
    end)

    self.areaFrames[key]=f
    return f
end

function A:CreateAreaFrames()
    self:CreateAreaFrame("incoming",self:T("INCOMING"))
    self:CreateAreaFrame("outgoing",self:T("OUTGOING"))
    self:CreateAreaFrame("notifications",self:T("NOTIFICATIONS"))
    self:RefreshAreaFrames()
end

function A:RefreshAreaFrames()
    if not self.db then return end
    self:CreateAreaFrame("incoming",self:T("INCOMING"))
    self:CreateAreaFrame("outgoing",self:T("OUTGOING"))
    self:CreateAreaFrame("notifications",self:T("NOTIFICATIONS"))

    local unlocked=self.db.battle.appearance.unlockAreas and true or false
    for key,frame in pairs(self.areaFrames or {}) do
        local cfg=self:GetAreaConfig(key) or DEFAULT_AREAS[key]
        frame:SetSize(Clamp(cfg.width,160,500),Clamp(cfg.height,100,500))
        frame:ClearAllPoints()
        frame:SetPoint("CENTER",UIParent,"CENTER",SafeNumber(cfg.x) or 0,SafeNumber(cfg.y) or 0)
        frame:EnableMouse(unlocked)
        frame:SetBackdropColor(0.03,0.03,0.03,unlocked and 0.28 or 0)
        frame:SetBackdropBorderColor(1,0.82,0,unlocked and 0.75 or 0)
        frame.anchorTitle:SetAlpha(unlocked and 0.9 or 0)
        frame:Show()
    end
end

function A:ResetAreaPositions()
    if not self.db then return end
    for key,d in pairs(DEFAULT_AREAS) do
        local cfg=self.db.battle.areas[key]
        for k,v in pairs(d) do cfg[k]=v end
    end
    self:RefreshAreaFrames()
end

function A:GetMessageFont(areaKey)
    self.messagePool[areaKey]=self.messagePool[areaKey] or {}
    local pool=self.messagePool[areaKey]
    local fs=table.remove(pool)
    if fs then fs:Show(); fs:SetAlpha(1); return fs end
    local parent=self.areaFrames and self.areaFrames[areaKey] or UIParent
    fs=parent:CreateFontString(nil,"OVERLAY")
    fs:SetJustifyH("CENTER")
    fs:SetShadowOffset(1,-1)
    fs:SetShadowColor(0,0,0,0.95)
    return fs
end

function A:ReleaseMessage(entry)
    if not entry or not entry.fs then return end
    entry.fs:Hide()
    entry.fs:ClearAllPoints()
    self.messagePool[entry.areaKey]=self.messagePool[entry.areaKey] or {}
    self.messagePool[entry.areaKey][#self.messagePool[entry.areaKey]+1]=entry.fs
end

function A:CountAreaMessages(areaKey)
    local n=0
    for _,entry in ipairs(self.activeMessages) do if entry.areaKey==areaKey then n=n+1 end end
    return n
end

function A:TrimArea(areaKey)
    local maxMessages=math.floor(Clamp(self.db.battle.appearance.maxMessages,3,30))
    while self:CountAreaMessages(areaKey)>=maxMessages do
        local oldestIndex,oldestAge
        for i,entry in ipairs(self.activeMessages) do
            if entry.areaKey==areaKey and (not oldestAge or entry.age>oldestAge) then
                oldestIndex,oldestAge=i,entry.age
            end
        end
        if not oldestIndex then break end
        local old=table.remove(self.activeMessages,oldestIndex)
        self:ReleaseMessage(old)
    end
end

function A:PushText(areaKey,text,color,size,critical)
    if not self.db or not self.db.enabled then return end
    local route=self:GetRouteConfig(areaKey)
    if not route or route.enabled==false then return end
    local area=self.areaFrames and self.areaFrames[areaKey]
    if not area then self:CreateAreaFrames(); area=self.areaFrames and self.areaFrames[areaKey] end
    if not area then return end

    self:TrimArea(areaKey)
    local fs=self:GetMessageFont(areaKey)
    local fontSize=Clamp(size or route.fontSize or 20,10,42)
    if critical then fontSize=fontSize*Clamp(self.db.battle.appearance.critScale,1,2) end
    local font=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    pcall(fs.SetFont,fs,font,fontSize,"OUTLINE")
    fs:SetText(tostring(text or ""))
    color=color or {1,1,1}
    fs:SetTextColor(color[1] or 1,color[2] or 1,color[3] or 1,1)

    local slot=self:CountAreaMessages(areaKey)
    local entry={
        fs=fs,areaKey=areaKey,age=0,
        lifetime=Clamp(self.db.battle.appearance.lifetime,0.7,5),
        speed=Clamp(self.db.battle.appearance.speed,20,180),
        direction=route.direction=="DOWN" and "DOWN" or "UP",
        slot=slot,
        size=fontSize,
    }
    self.activeMessages[#self.activeMessages+1]=entry
    self:UpdateMessage(entry)
end

function A:UpdateMessage(entry)
    local area=self.areaFrames and self.areaFrames[entry.areaKey]
    if not area or not entry.fs then return end
    local _,h=area:GetSize()
    h=SafeNumber(h) or 250
    local spacing=entry.size+3
    local drift=entry.age*entry.speed
    local y
    if entry.direction=="DOWN" then
        y=(h/2)-20-(entry.slot*spacing)-drift
    else
        y=(-h/2)+20+(entry.slot*spacing)+drift
    end
    entry.fs:ClearAllPoints()
    entry.fs:SetPoint("CENTER",area,"CENTER",0,y)
    local fadeStart=entry.lifetime*0.68
    local alpha=1
    if entry.age>fadeStart then alpha=math.max(0,1-(entry.age-fadeStart)/math.max(0.01,entry.lifetime-fadeStart)) end
    entry.fs:SetAlpha(alpha)
end

function A:GetNameplateMessageFrame()
    local f=table.remove(self.nameplatePool)
    if f then f:Show(); f:SetAlpha(1); return f end
    f=CreateFrame("Frame",nil,UIParent)
    f:SetSize(180,30)
    f.text=f:CreateFontString(nil,"OVERLAY")
    f.text:SetPoint("CENTER")
    f.text:SetShadowOffset(1,-1)
    f.text:SetShadowColor(0,0,0,0.95)
    return f
end

function A:ReleaseNameplateMessage(entry)
    if not entry or not entry.frame then return end
    entry.frame:Hide()
    entry.frame:ClearAllPoints()
    entry.frame:SetParent(UIParent)
    self.nameplatePool[#self.nameplatePool+1]=entry.frame
end

function A:PushNameplateText(destGUID,text,color,critical)
    local cfg=self.db and self.db.battle and self.db.battle.nameplates
    if not cfg or not cfg.enabled or not destGUID then return end
    local plate=self.nameplateByGUID[destGUID]
    if not plate or not plate:IsShown() then return end

    local f=self:GetNameplateMessageFrame()
    f:SetParent(plate)
    f:SetFrameStrata(plate:GetFrameStrata() or "MEDIUM")
    f:SetFrameLevel((plate:GetFrameLevel() or 1)+15)
    local size=Clamp(cfg.fontSize,10,36)
    if critical then size=size*Clamp(self.db.battle.appearance.critScale,1,2) end
    pcall(f.text.SetFont,f.text,STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,"OUTLINE")
    f.text:SetText(tostring(text or ""))
    color=color or {1,1,1}
    f.text:SetTextColor(color[1] or 1,color[2] or 1,color[3] or 1,1)

    local entry={frame=f,plate=plate,age=0,lifetime=Clamp(cfg.lifetime,0.5,3),size=size}
    self.activeNameplateMessages[#self.activeNameplateMessages+1]=entry
end

function A:UpdateAnimations(elapsed)
    for i=#self.activeMessages,1,-1 do
        local entry=self.activeMessages[i]
        entry.age=entry.age+elapsed
        if entry.age>=entry.lifetime then
            table.remove(self.activeMessages,i)
            self:ReleaseMessage(entry)
        else
            self:UpdateMessage(entry)
        end
    end

    for i=#self.activeNameplateMessages,1,-1 do
        local entry=self.activeNameplateMessages[i]
        entry.age=entry.age+elapsed
        if entry.age>=entry.lifetime or not entry.plate or not entry.plate:IsShown() then
            table.remove(self.activeNameplateMessages,i)
            self:ReleaseNameplateMessage(entry)
        else
            local y=22+(entry.age*58)
            entry.frame:ClearAllPoints()
            entry.frame:SetPoint("CENTER",entry.plate,"CENTER",0,y)
            local alpha=1
            if entry.age>entry.lifetime*0.55 then
                alpha=math.max(0,1-(entry.age-entry.lifetime*0.55)/(entry.lifetime*0.45))
            end
            entry.frame:SetAlpha(alpha)
        end
    end
end

function A:RegisterNameplate(unit)
    if not unit or type(UnitGUID)~="function" then return end
    local ok,guid=pcall(UnitGUID,unit)
    if not ok or not guid then return end
    if C_NamePlate and type(C_NamePlate.GetNamePlateForUnit)=="function" then
        local good,plate=pcall(C_NamePlate.GetNamePlateForUnit,unit)
        if good and plate then self.nameplateByGUID[guid]=plate end
    end
end

function A:UnregisterNameplate(unit)
    if not unit or type(UnitGUID)~="function" then return end
    local ok,guid=pcall(UnitGUID,unit)
    if ok and guid then self.nameplateByGUID[guid]=nil end
end

function A:RefreshGUIDs()
    if type(UnitGUID)=="function" then
        local ok,p=pcall(UnitGUID,"player"); self.playerGUID=ok and p or nil
        local ok2,pet=pcall(UnitGUID,"pet"); self.petGUID=ok2 and pet or nil
    end
end

function A:DamagePayload(data,subevent)
    if subevent=="SWING_DAMAGE" then
        return SafeNumber(data[12]),nil,self:T("MELEE"),SafeNumber(data[14]) or 1,SafeBool(data[18])
    elseif subevent=="ENVIRONMENTAL_DAMAGE" then
        return SafeNumber(data[13]),nil,tostring(data[12] or ""),SafeNumber(data[15]) or 1,SafeBool(data[19])
    elseif subevent=="SPELL_DAMAGE" or subevent=="SPELL_PERIODIC_DAMAGE" or subevent=="RANGE_DAMAGE" or subevent=="DAMAGE_SHIELD" then
        return SafeNumber(data[15]),SafeNumber(data[12]),data[13],SafeNumber(data[17]) or SafeNumber(data[14]) or 1,SafeBool(data[21])
    end
end

function A:HealPayload(data,subevent)
    if subevent=="SPELL_HEAL" or subevent=="SPELL_PERIODIC_HEAL" then
        return SafeNumber(data[15]),SafeNumber(data[12]),data[13],SafeBool(data[18])
    end
end

function A:MissPayload(data,subevent)
    if subevent=="SWING_MISSED" then return tostring(data[12] or "MISS"),nil,self:T("MELEE") end
    if subevent=="SPELL_MISSED" or subevent=="RANGE_MISSED" then return tostring(data[15] or "MISS"),SafeNumber(data[12]),data[13] end
end

function A:HandleDamage(data,subevent,sourceGUID,destGUID)
    local amount,spellID,spellName,school,critical=self:DamagePayload(data,subevent)
    if not amount or amount<=0 then return end
    local ownSource=sourceGUID and (sourceGUID==self.playerGUID or sourceGUID==self.petGUID)
    local fromPet=sourceGUID and self.petGUID and sourceGUID==self.petGUID
    local incoming=destGUID and destGUID==self.playerGUID

    if incoming and self.db.battle.incoming.damage then
        local text=self:DecorateText("-"..self:FormatAmount(amount),spellID,spellName)
        self:PushText("incoming",text,{1.00,0.28,0.22},self.db.battle.incoming.fontSize,critical)
    end

    if ownSource and self.db.battle.outgoing.damage and (not fromPet or self.db.battle.outgoing.petDamage) then
        local color=self.db.battle.appearance.schoolColors and SchoolColor(school) or {1.00,0.82,0.15}
        local text=self:DecorateText(self:FormatAmount(amount),spellID,spellName)
        self:PushText("outgoing",text,color,self.db.battle.outgoing.fontSize,critical)
        if self.db.battle.nameplates.damage then self:PushNameplateText(destGUID,text,color,critical) end
    end
end

function A:HandleHeal(data,subevent,sourceGUID,destGUID)
    local amount,spellID,spellName,critical=self:HealPayload(data,subevent)
    if not amount or amount<=0 then return end
    local ownSource=sourceGUID and (sourceGUID==self.playerGUID or sourceGUID==self.petGUID)
    local incoming=destGUID and destGUID==self.playerGUID

    if incoming and self.db.battle.incoming.healing then
        local text=self:DecorateText("+"..self:FormatAmount(amount),spellID,spellName)
        self:PushText("incoming",text,{0.30,1.00,0.42},self.db.battle.incoming.fontSize,critical)
    end

    if ownSource and self.db.battle.outgoing.healing and not incoming then
        local text=self:DecorateText("+"..self:FormatAmount(amount),spellID,spellName)
        self:PushText("outgoing",text,{0.30,1.00,0.42},self.db.battle.outgoing.fontSize,critical)
        if self.db.battle.nameplates.healing then self:PushNameplateText(destGUID,text,{0.30,1.00,0.42},critical) end
    end
end

function A:HandleMiss(data,subevent,sourceGUID,destGUID)
    local missType,spellID,spellName=self:MissPayload(data,subevent)
    if not missType then return end
    local ownSource=sourceGUID and (sourceGUID==self.playerGUID or sourceGUID==self.petGUID)
    local incoming=destGUID and destGUID==self.playerGUID
    local label=MissText(missType)
    local text=self:DecorateText(label,spellID,spellName)
    local color={1.00,0.78,0.18}

    if incoming and self.db.battle.incoming.misses then self:PushText("incoming",text,color,self.db.battle.incoming.fontSize,false) end
    if ownSource and self.db.battle.outgoing.misses then
        self:PushText("outgoing",text,color,self.db.battle.outgoing.fontSize,false)
        if self.db.battle.nameplates.misses then self:PushNameplateText(destGUID,text,color,false) end
    end
end

function A:HandleNotification(data,subevent,sourceGUID)
    if not sourceGUID or (sourceGUID~=self.playerGUID and sourceGUID~=self.petGUID) then return end
    if subevent=="SPELL_INTERRUPT" and self.db.battle.notifications.interrupts then
        local extraName=data[16]
        local spellID=SafeNumber(data[12])
        local text=self:T("INTERRUPT")..": "..tostring(extraName or "?")
        self:PushText("notifications",self:DecorateText(text,spellID,nil),{1.00,0.55,0.18},self.db.battle.notifications.fontSize,false)
    elseif (subevent=="SPELL_DISPEL" or subevent=="SPELL_STOLEN") and self.db.battle.notifications.dispels then
        local extraName=data[16]
        local spellID=SafeNumber(data[12])
        local text=self:T("DISPEL")..": "..tostring(extraName or "?")
        self:PushText("notifications",self:DecorateText(text,spellID,nil),{0.35,0.82,1.00},self.db.battle.notifications.fontSize,false)
    end
end

function A:HandleCombatLog()
    if not self.db or not self.db.enabled or type(CombatLogGetCurrentEventInfo)~="function" then return end
    local ok,data=pcall(function() return {CombatLogGetCurrentEventInfo()} end)
    if not ok or type(data)~="table" then return end
    local subevent=data[2]
    local sourceGUID=data[4]
    local destGUID=data[8]
    if not subevent then return end

    if subevent=="SWING_DAMAGE" or subevent=="ENVIRONMENTAL_DAMAGE" or subevent=="SPELL_DAMAGE"
        or subevent=="SPELL_PERIODIC_DAMAGE" or subevent=="RANGE_DAMAGE" or subevent=="DAMAGE_SHIELD" then
        self:HandleDamage(data,subevent,sourceGUID,destGUID)
    elseif subevent=="SPELL_HEAL" or subevent=="SPELL_PERIODIC_HEAL" then
        self:HandleHeal(data,subevent,sourceGUID,destGUID)
    elseif subevent=="SWING_MISSED" or subevent=="SPELL_MISSED" or subevent=="RANGE_MISSED" then
        self:HandleMiss(data,subevent,sourceGUID,destGUID)
    elseif subevent=="SPELL_INTERRUPT" or subevent=="SPELL_DISPEL" or subevent=="SPELL_STOLEN" then
        self:HandleNotification(data,subevent,sourceGUID)
    end
end

function A:TestMessages()
    if not self.db then return end
    self:PushText("incoming","-842  "..self:T("MELEE"),{1.00,0.28,0.22},self.db.battle.incoming.fontSize,false)
    self:PushText("incoming","+1.4k  Heal",{0.30,1.00,0.42},self.db.battle.incoming.fontSize,true)
    self:PushText("outgoing","2.8k  Fireball",{1.00,0.35,0.12},self.db.battle.outgoing.fontSize,true)
    self:PushText("outgoing","DODGE",{1.00,0.78,0.18},self.db.battle.outgoing.fontSize,false)
    self:PushText("notifications",self:T("INTERRUPT")..": Frostbolt",{1.00,0.55,0.18},self.db.battle.notifications.fontSize,false)
end

function A:ApplyAll()
    if not self.db then return end
    self:CreateAreaFrames()
    self:RefreshAreaFrames()
    if not self.db.enabled then
        for _,entry in ipairs(self.activeMessages) do if entry.fs then entry.fs:Hide() end end
        for _,entry in ipairs(self.activeNameplateMessages) do if entry.frame then entry.frame:Hide() end end
    end
end

function A:RefreshFeature()
    self:ApplyAll()
end

function A:InitializeFeature()
    self:RefreshGUIDs()
    self:CreateAreaFrames()

    local f=CreateFrame("Frame")
    self.eventFrame=f
    for _,ev in ipairs({"COMBAT_LOG_EVENT_UNFILTERED","UNIT_PET","PLAYER_ENTERING_WORLD","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED"}) do
        pcall(f.RegisterEvent,f,ev)
    end

    f:SetScript("OnEvent",function(_,event,...)
        if event=="COMBAT_LOG_EVENT_UNFILTERED" then
            A:HandleCombatLog()
        elseif event=="UNIT_PET" then
            local unit=...
            if unit=="player" then A:RefreshGUIDs() end
        elseif event=="PLAYER_ENTERING_WORLD" then
            A:RefreshGUIDs()
            A:RefreshAreaFrames()
        elseif event=="NAME_PLATE_UNIT_ADDED" then
            A:RegisterNameplate(...)
        elseif event=="NAME_PLATE_UNIT_REMOVED" then
            A:UnregisterNameplate(...)
        end
    end)

    f:SetScript("OnUpdate",function(_,elapsed)
        A:UpdateAnimations(SafeNumber(elapsed) or 0)
    end)

    self:ApplyAll()
end

local function CategoryButton(page,text,x,y,width,onClick)
    local b=CreateFrame("Button",nil,page,"UIPanelButtonTemplate")
    b:SetSize(width or 155,24)
    b:SetPoint("TOPLEFT",x,y)
    b:SetText(text)
    b:SetScript("OnClick",onClick)
    return b
end

function A:ShowBattleCategory(category)
    if not self.battleCategoryPages then return end
    self.db.battle.category=category
    for key,frame in pairs(self.battleCategoryPages) do frame:SetShown(key==category) end
    for key,button in pairs(self.battleCategoryButtons or {}) do
        if button.LockHighlight then
            if key==category then button:LockHighlight() else button:UnlockHighlight() end
        end
    end
end

local function AddDirection(ui,parent,key,y)
    local label=parent:CreateFontString(nil,"ARTWORK","GameFontNormal")
    label:SetPoint("TOPLEFT",10,y)
    label:SetText(A:T("DIRECTION"))
    ui.CreateDropdown(parent,140,y+12,170,
        function() return {{value="UP",text=A:T("DIR_UP")},{value="DOWN",text=A:T("DIR_DOWN")}} end,
        function() return A.db.battle[key].direction end,
        function(v) A.db.battle[key].direction=v end)
end

function A:BuildGeneralOptions(page,ui)
    self.battleCategoryPages={}
    self.battleCategoryButtons={}

    local categories={
        {"incoming",self:T("CAT_INCOMING")},
        {"outgoing",self:T("CAT_OUTGOING")},
        {"notifications",self:T("CAT_NOTIFICATIONS")},
        {"nameplates",self:T("CAT_NAMEPLATES")},
        {"appearance",self:T("CAT_APPEARANCE")},
    }

    for i,entry in ipairs(categories) do
        local key,label=entry[1],entry[2]
        local button=CategoryButton(page,label,20,-95-(i-1)*32,155,function() A:ShowBattleCategory(key) end)
        self.battleCategoryButtons[key]=button
        local sub=CreateFrame("Frame",nil,page)
        sub:SetPoint("TOPLEFT",195,-85)
        sub:SetPoint("BOTTOMRIGHT",-20,20)
        sub:Hide()
        self.battleCategoryPages[key]=sub
    end

    local p=self.battleCategoryPages.incoming
    local t=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); t:SetPoint("TOPLEFT",10,-5); t:SetText(self:T("SECTION_INCOMING"))
    ui.CreateCheck(p,self:T("ENABLE_INCOMING"),10,-45,function() return A.db.battle.incoming.enabled end,function(v) A.db.battle.incoming.enabled=v end)
    ui.CreateCheck(p,self:T("SHOW_DAMAGE"),10,-80,function() return A.db.battle.incoming.damage end,function(v) A.db.battle.incoming.damage=v end)
    ui.CreateCheck(p,self:T("SHOW_HEALING"),10,-115,function() return A.db.battle.incoming.healing end,function(v) A.db.battle.incoming.healing=v end)
    ui.CreateCheck(p,self:T("SHOW_MISSES"),10,-150,function() return A.db.battle.incoming.misses end,function(v) A.db.battle.incoming.misses=v end)
    ui.CreateSlider(p,self:T("FONT_SIZE"),12,36,1,20,-235,function() return A.db.battle.incoming.fontSize end,function(v) A.db.battle.incoming.fontSize=math.floor(v+0.5) end,function(v) return tostring(math.floor(v+0.5)) end)
    AddDirection(ui,p,"incoming",-300)

    p=self.battleCategoryPages.outgoing
    t=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); t:SetPoint("TOPLEFT",10,-5); t:SetText(self:T("SECTION_OUTGOING"))
    ui.CreateCheck(p,self:T("ENABLE_OUTGOING"),10,-45,function() return A.db.battle.outgoing.enabled end,function(v) A.db.battle.outgoing.enabled=v end)
    ui.CreateCheck(p,self:T("SHOW_DAMAGE"),10,-80,function() return A.db.battle.outgoing.damage end,function(v) A.db.battle.outgoing.damage=v end)
    ui.CreateCheck(p,self:T("SHOW_HEALING"),10,-115,function() return A.db.battle.outgoing.healing end,function(v) A.db.battle.outgoing.healing=v end)
    ui.CreateCheck(p,self:T("SHOW_MISSES"),10,-150,function() return A.db.battle.outgoing.misses end,function(v) A.db.battle.outgoing.misses=v end)
    ui.CreateCheck(p,self:T("SHOW_PET_DAMAGE"),10,-185,function() return A.db.battle.outgoing.petDamage end,function(v) A.db.battle.outgoing.petDamage=v end)
    ui.CreateSlider(p,self:T("FONT_SIZE"),12,36,1,20,-270,function() return A.db.battle.outgoing.fontSize end,function(v) A.db.battle.outgoing.fontSize=math.floor(v+0.5) end,function(v) return tostring(math.floor(v+0.5)) end)
    AddDirection(ui,p,"outgoing",-335)

    p=self.battleCategoryPages.notifications
    t=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); t:SetPoint("TOPLEFT",10,-5); t:SetText(self:T("SECTION_NOTIFICATIONS"))
    ui.CreateCheck(p,self:T("ENABLE_NOTIFICATIONS"),10,-45,function() return A.db.battle.notifications.enabled end,function(v) A.db.battle.notifications.enabled=v end)
    ui.CreateCheck(p,self:T("SHOW_INTERRUPTS"),10,-80,function() return A.db.battle.notifications.interrupts end,function(v) A.db.battle.notifications.interrupts=v end)
    ui.CreateCheck(p,self:T("SHOW_DISPELS"),10,-115,function() return A.db.battle.notifications.dispels end,function(v) A.db.battle.notifications.dispels=v end)
    ui.CreateSlider(p,self:T("FONT_SIZE"),12,36,1,20,-200,function() return A.db.battle.notifications.fontSize end,function(v) A.db.battle.notifications.fontSize=math.floor(v+0.5) end,function(v) return tostring(math.floor(v+0.5)) end)
    AddDirection(ui,p,"notifications",-265)

    p=self.battleCategoryPages.nameplates
    t=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); t:SetPoint("TOPLEFT",10,-5); t:SetText(self:T("SECTION_NAMEPLATES"))
    ui.CreateCheck(p,self:T("ENABLE_NAMEPLATES"),10,-45,function() return A.db.battle.nameplates.enabled end,function(v) A.db.battle.nameplates.enabled=v end)
    ui.CreateCheck(p,self:T("SHOW_DAMAGE"),10,-80,function() return A.db.battle.nameplates.damage end,function(v) A.db.battle.nameplates.damage=v end)
    ui.CreateCheck(p,self:T("SHOW_HEALING"),10,-115,function() return A.db.battle.nameplates.healing end,function(v) A.db.battle.nameplates.healing=v end)
    ui.CreateCheck(p,self:T("SHOW_MISSES"),10,-150,function() return A.db.battle.nameplates.misses end,function(v) A.db.battle.nameplates.misses=v end)
    ui.CreateSlider(p,self:T("FONT_SIZE"),12,32,1,20,-235,function() return A.db.battle.nameplates.fontSize end,function(v) A.db.battle.nameplates.fontSize=math.floor(v+0.5) end,function(v) return tostring(math.floor(v+0.5)) end)
    ui.CreateSlider(p,self:T("MESSAGE_LIFETIME"),0.5,2.5,0.05,315,-235,function() return A.db.battle.nameplates.lifetime end,function(v) A.db.battle.nameplates.lifetime=math.floor(v*20+0.5)/20 end,function(v) return string.format("%.2fs",v) end)

    p=self.battleCategoryPages.appearance
    t=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); t:SetPoint("TOPLEFT",10,-5); t:SetText(self:T("SECTION_APPEARANCE"))
    ui.CreateCheck(p,self:T("SHORT_NUMBERS"),10,-45,function() return A.db.battle.appearance.shortNumbers end,function(v) A.db.battle.appearance.shortNumbers=v end)
    ui.CreateCheck(p,self:T("SHOW_SPELL_NAME"),10,-80,function() return A.db.battle.appearance.showSpellName end,function(v) A.db.battle.appearance.showSpellName=v end)
    ui.CreateCheck(p,self:T("SHOW_SPELL_ICON"),10,-115,function() return A.db.battle.appearance.showSpellIcon end,function(v) A.db.battle.appearance.showSpellIcon=v end)
    ui.CreateCheck(p,self:T("SCHOOL_COLORS"),10,-150,function() return A.db.battle.appearance.schoolColors end,function(v) A.db.battle.appearance.schoolColors=v end)
    ui.CreateCheck(p,self:T("UNLOCK_AREAS"),10,-185,function() return A.db.battle.appearance.unlockAreas end,function(v) A.db.battle.appearance.unlockAreas=v; A:RefreshAreaFrames() end)
    ui.CreateSlider(p,self:T("CRIT_SCALE"),1,2,0.05,20,-270,function() return A.db.battle.appearance.critScale end,function(v) A.db.battle.appearance.critScale=math.floor(v*20+0.5)/20 end,function(v) return string.format("%.2fx",v) end)
    ui.CreateSlider(p,self:T("MESSAGE_LIFETIME"),0.7,5,0.1,315,-270,function() return A.db.battle.appearance.lifetime end,function(v) A.db.battle.appearance.lifetime=math.floor(v*10+0.5)/10 end,function(v) return string.format("%.1fs",v) end)
    ui.CreateSlider(p,self:T("SCROLL_SPEED"),20,180,5,20,-355,function() return A.db.battle.appearance.speed end,function(v) A.db.battle.appearance.speed=math.floor(v+0.5) end,function(v) return tostring(math.floor(v+0.5)) end)
    ui.CreateSlider(p,self:T("MAX_MESSAGES"),3,30,1,315,-355,function() return A.db.battle.appearance.maxMessages end,function(v) A.db.battle.appearance.maxMessages=math.floor(v+0.5) end,function(v) return tostring(math.floor(v+0.5)) end)
    ui.CreateButton(p,self:T("TEST_TEXT"),10,-420,150,function() A:TestMessages() end)
    ui.CreateButton(p,self:T("RESET_AREAS"),175,-420,190,function() A:ResetAreaPositions() end)

    local note=page:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    note:SetPoint("BOTTOMLEFT",195,20)
    note:SetWidth(520)
    note:SetJustifyH("LEFT")
    note:SetText(self:T("FOREVER_NOTE"))

    self:ShowBattleCategory(self.db.battle.category or "incoming")
end
