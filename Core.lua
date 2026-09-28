local ADDON_NAME = ...

ComfyBattleText = ComfyBattleText or {}
local A = ComfyBattleText

A.name = ADDON_NAME or "ComfyBattleText"
A.version = "0.7"
A.buildDate = "28.09.2026"
A.status = "Beta"
A.gameVersion = "WoW Forever 1.60.1"
A.targetBuild = "70009"
A.interface = 16001
A.author = "TheRealDoubleG"
A.discord = "the.real.double.g"
A.github = "https://github.com/TheRealDoubleG/ComfyBattleText"

local defaults = {
    enabled = true,
    battle = {
        category = "incoming",

        incoming = {
            enabled = true,
            damage = true,
            healing = true,
            misses = true,
            fontSize = 20,
            direction = "UP",
        },

        outgoing = {
            enabled = true,
            damage = true,
            healing = true,
            misses = true,
            petDamage = true,
            fontSize = 20,
            direction = "UP",
        },

        notifications = {
            enabled = true,
            interrupts = true,
            dispels = true,
            fontSize = 19,
            direction = "UP",
        },

        nameplates = {
            enabled = false,
            damage = true,
            healing = false,
            misses = true,
            fontSize = 18,
            lifetime = 1.15,
        },

        filters = {
            incomingDamageMin = 0,
            incomingHealingMin = 0,
            outgoingDamageMin = 0,
            outgoingHealingMin = 0,
            hidePeriodicDamage = false,
            hidePeriodicHealing = false,
            spellBlacklist = "",
        },

        debug = {
            enabled = false,
            maxEvents = 30,
        },

        appearance = {
            shortNumbers = true,
            showSpellName = true,
            showSpellIcon = true,
            schoolColors = true,
            critScale = 1.35,
            lifetime = 2.25,
            speed = 72,
            maxMessages = 12,
            unlockAreas = false,
            mergeWindow = 0.15,
            fontPath = "Fonts\\FRIZQT__.TTF",
            colors = {
                incomingDamage = "FF4738",
                healing = "4DFF6B",
                outgoingDamage = "FFD126",
                miss = "FFC72E",
                interrupt = "FF8C2E",
                dispel = "59D1FF",
            },
        },

        areas = {
            incoming = {x = -285, y = 0, width = 250, height = 330},
            outgoing = {x = 285, y = 0, width = 250, height = 330},
            notifications = {x = 0, y = 175, width = 320, height = 220},
        },
    },

    optionsWindow = {point="CENTER", relativePoint="CENTER", x=0, y=20},
    ui = {windowLocked=false, windowOpacity=100, showWindowBorder=true, backgroundAlpha=92},
}

function A:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyBattleText:|r " .. tostring(msg))
    end
end

function A:GetClientBuildInfo()
    if type(GetBuildInfo) ~= "function" then return "?", "?", "?", nil end
    local v,b,d,i = GetBuildInfo()
    return tostring(v or "?"), tostring(b or "?"), tostring(d or "?"), tonumber(i)
end

function A:GetCompatibilityStatus()
    local _,_,_,i = self:GetClientBuildInfo()
    if i and tonumber(i) == tonumber(self.interface) then
        return true, self:T("COMPAT_MATCH")
    end
    return false, self:T("COMPAT_UPDATE_REQUIRED")
end

function A:InitializeDB()
    self:InitializeProfileStorage(defaults, "ComfyBattleTextDB")
end

function A:SetEnabled(v)
    if not self.db then return false end
    self.db.enabled = v and true or false
    if self.RefreshFeature then self:RefreshFeature() end
    if self.RefreshOptions then self:RefreshOptions() end
    return true
end

function A:GetComfyProfileProvider() return self end
function A:OpenOptions() if self.ShowOptions then self:ShowOptions() end end

SLASH_COMFYBATTLETEXT1 = "/comfybattletext"
SLASH_COMFYBATTLETEXT2 = "/cbt"
SlashCmdList.COMFYBATTLETEXT = function(msg)
    msg = tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "test" then
        if A.TestMessages then A:TestMessages() end
    elseif msg == "anchors" then
        if A.db and A.db.battle and A.db.battle.appearance then
            A.db.battle.appearance.unlockAreas = not A.db.battle.appearance.unlockAreas
            if A.RefreshAreaFrames then A:RefreshAreaFrames() end
            A:Print(A.db.battle.appearance.unlockAreas and A:T("ANCHORS_ON") or A:T("ANCHORS_OFF"))
        end
    elseif msg == "reset" then
        if A.ResetAreaPositions then A:ResetAreaPositions() end
    elseif msg == "debug" then
        if A.db and A.db.battle and A.db.battle.debug then
            A.db.battle.debug.enabled = not A.db.battle.debug.enabled
            A:Print(A.db.battle.debug.enabled and A:T("DEBUG_ON") or A:T("DEBUG_OFF"))
            if A.RefreshFeatureOptions then A:RefreshFeatureOptions() end
        end
    else
        A:OpenOptions()
    end
end

local e = CreateFrame("Frame")
e:RegisterEvent("ADDON_LOADED")
e:RegisterEvent("PLAYER_LOGIN")
e:SetScript("OnEvent", function(_, ev, arg1)
    if ev == "ADDON_LOADED" and arg1 == A.name then
        A:InitializeDB()
        if A.InitializeFeature then A:InitializeFeature() end
        if A.InitializeOptions then A:InitializeOptions() end
    elseif ev == "PLAYER_LOGIN" and A.RefreshFeature then
        A:RefreshFeature()
    end
end)
