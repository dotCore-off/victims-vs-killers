PB = PB or {}
PB.Config = PB.Config or {}

local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true
}

hook.Add("HUDShouldDraw", "PB.HideDefaultUIs", function(name)
    if (hide[name]) then return false end
end)

hook.Add("DrawDeathNotice", "PB.DrawNoticeHide", function()
    return 0, 0
end)

if (IsValid(PB_HUD)) then
    PB_HUD:Remove()
end

local function createDermaHUD(ply)
    if (IsValid(PB_HUD)) then
        PB_HUD:Remove()
    end

    PB_HUD = vgui.Create("DPanel")
    PB_HUD:ParentToHUD()
    PB_HUD:SetSize(ScrW(), ScrH())
    PB_HUD.Think = function(self2)
        local shouldDraw = hook.Run("HUDShouldDraw", "CHudGMod")
        if (!shouldDraw) then
            self2:Remove()
        end
    end
    PB_HUD.Paint = function() end

    PB_HUD.main = vgui.Create("DPanel", PB_HUD)
    PB_HUD.main:SetSize(ScrW() * 0.13, 105)
    PB_HUD.main:SetPos(10, ScrH() - 10 - PB_HUD.main:GetTall())
    PB_HUD.main.Paint = function(self2, w, h)
        draw.RoundedBox(8, 0, 0, w, h, BOTCHED.FUNC.GetTheme(1, 200))

        local boxSize = PB_HUD.model:GetTall()
        local tc = team.GetColor(ply:Team())
        local bg = Color(tc.r, tc.g, tc.b, 100)
        draw.RoundedBox(8, (h / 2) - (boxSize / 2), (h / 2) - (boxSize / 2), boxSize, boxSize, bg)
    end

    PB_HUD.model = vgui.Create("DModelPanel", PB_HUD.main)
    PB_HUD.model:SetSize(PB_HUD.main:GetTall() * 0.8, PB_HUD.main:GetTall() * 0.8)
    PB_HUD.model:SetPos((PB_HUD.main:GetTall() / 2) - (PB_HUD.model:GetTall() / 2), (PB_HUD.main:GetTall() / 2) - (PB_HUD.model:GetTall() / 2))
    PB_HUD.model:SetModel("")
    function PB_HUD.model:LayoutEntity(Entity) return end

    local modelDistance = (PB_HUD.main:GetTall() - PB_HUD.model:GetTall()) / 2
    local nameText = ply:Nick()
    surface.SetFont("MontserratBold30")
    local nameX, nameY = surface.GetTextSize(nameText)

    PB_HUD.name = vgui.Create("DPanel", PB_HUD.main)
    PB_HUD.name:SetSize(nameX + 20, nameY + 20)
    PB_HUD.name:SetPos(modelDistance + PB_HUD.model:GetWide() + 10, modelDistance + 18)
    PB_HUD.name.Paint = function(self2, w, h)
        nameText = ply:Nick()
        teamText = team.GetName(ply:Team())

        local x, y = self2:LocalToScreen(0, -5)
        draw.SimpleText(nameText, "MontserratBold30", x, y, BOTCHED.FUNC.GetTheme(1))
        draw.SimpleText(nameText, "MontserratBold30", 0, -5, BOTCHED.FUNC.GetTheme(4, 150))
        draw.SimpleText(teamText, "MontserratBold20", 0, 15, team.GetColor(ply:Team()))
    end

    local namePanelX = PB_HUD.name:GetPos()
    local rightTextW, healthX, moneyX
    local function RefreshRightTextW()
        surface.SetFont("MontserratBold25")
        healthX = surface.GetTextSize(math.max(0, ply:Health()))

        surface.SetFont("MontserratBold25")
        moneyX = surface.GetTextSize(math.max(0, ply:GetCurrency(1)))

        rightTextW = math.max(healthX, moneyX)
    end
    RefreshRightTextW()

    local specTarget = ply:GetObserverTarget()
    local progressBarH = 10
    PB_HUD.health = vgui.Create("DPanel", PB_HUD.main)
    PB_HUD.health:SetSize(PB_HUD.main:GetWide() - namePanelX + 20, progressBarH)
    PB_HUD.health:SetPos(namePanelX, PB_HUD.main:GetTall() - modelDistance-PB_HUD.health:GetTall() - 20)
    PB_HUD.health.Paint = function(self2, w, h)
        if (ply:Alive()) then
            surface.SetFont("MontserratBold25")
            local curHealthX = surface.GetTextSize(math.max(0, ply:Health()))

            if (healthX != curHealthX) then
                RefreshRightTextW()
            end

            local progressBarW = w-rightTextW-5
            draw.RoundedBox(progressBarH / 2, 0, 0, progressBarW, progressBarH, BOTCHED.FUNC.GetTheme(1))

            BOTCHED.FUNC.DrawRoundedMask(progressBarH / 2, 0, 0, progressBarW, progressBarH, function()
                surface.SetDrawColor(Color(241, 57, 57))
                surface.DrawRect(0, 0, progressBarW * math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1), progressBarH)
            end)

            local x, y = self2:LocalToScreen(w-(rightTextW / 2), h / 2 - 2)
            draw.SimpleText(math.max(0, ply:Health()), "MontserratBold25", x, y, Color(241, 57, 57), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            if (!IsValid(specTarget)) then return true end
            specText = ply:GetObserverMode() != OBS_MODE_ROAMING and specTarget:GetName() or "Press +jump to spectate"

            local x, y = self2:LocalToScreen(w-(rightTextW / 2), h / 2 - 2)
            draw.SimpleText(specText, "MontserratBold20", x, y, color_white)
        end
    end

    local GAMEMODE = GAMEMODE
    local string = string
    local roundEnds = GetGlobalFloat("RoundEndTime")
    local roundTime = string.ToMinutesSeconds(roundEnds - CurTime())
    local roundString = "Round ends in " .. roundTime
    if ((roundTime <= "00:00" or roundTime > "05:00") and GAMEMODE:GetGameTimeLeft() > 0) then
        roundString = "Round ended! Next map in " .. string.ToMinutesSeconds(GAMEMODE:GetGameTimeLeft())
    elseif ((roundTime <= "00:00" or roundTime > "05:00") and GAMEMODE:GetGameTimeLeft() <= 0) then
        roundString = "Round ended! Mapvote will start soon.."
    end
    local roundStringX = surface.GetTextSize(roundString)

    PB_HUD.round = vgui.Create("DPanel", PB_HUD)
    PB_HUD.round:SetSize(roundStringX * 1.5 + 20, 50)
    PB_HUD.round:SetPos(ScrW() / 2 - BOTCHED.FUNC.ScreenScale(150), ScrH() - 10 - PB_HUD.round:GetTall())
    PB_HUD.round.Paint = function(self2, w, h)
        local roundEndTime = GetGlobalFloat("RoundEndTime")
        local roundRemaining = string.ToMinutesSeconds(roundEndTime - CurTime())
        local currentRound = GetGlobalInt("RoundNumber") or 0
        local timeString = "Round " .. currentRound .. " ends in " .. roundRemaining
        if ((roundRemaining <= "00:00" or roundRemaining > "05:00") and GAMEMODE:GetGameTimeLeft() > 0) then
            timeString = "Round " .. currentRound .. " ended! Next map in " .. string.ToMinutesSeconds(GAMEMODE:GetGameTimeLeft())
        elseif ((roundRemaining <= "00:00" or roundRemaining > "05:00") and GAMEMODE:GetGameTimeLeft() <= 0) then
            timeString = "Round " .. currentRound .. " ended! Mapvote will start soon.."
        end
        local strX = surface.GetTextSize(timeString)

        if (PB_HUD.round:GetSize() != strX * 1.5 + 20) then
            PB_HUD.round:SetSize(strX * 1.5 + 20, 50)
        end

        draw.RoundedBox(20, 0, 0, w, h, BOTCHED.FUNC.GetTheme(1, 200))
        draw.SimpleText(timeString, "MontserratBold30", w / 2, h / 2 - 12, BOTCHED.FUNC.GetTheme(4, 200), TEXT_ALIGN_CENTER)
    end
end

local function createRoundPanel(ply, event)
    local fetchSpecialRound = PB.Config.SpecialRounds[event]
    local eventName, eventDesc, eventMat = fetchSpecialRound.RoundName, fetchSpecialRound.RoundDescription, fetchSpecialRound.RoundMaterial
    local eventStringW = surface.GetTextSize(eventDesc)
    local eventColor = fetchSpecialRound.RoundColor

    local roundMat = Material(eventMat)
    PB_SPECIAL = vgui.Create("DPanel", PB_HUD)
    PB_SPECIAL:SetSize(eventStringW * 1.5, 50)
    PB_SPECIAL:SetPos(ScrW() / 2 - BOTCHED.FUNC.ScreenScale(250), 10)
    PB_SPECIAL.Paint = function(self2, w, h)
        draw.RoundedBox(20, 0, 0, w, h, BOTCHED.FUNC.GetTheme(1, 200))

        local iconSize = 32
        surface.SetMaterial(roundMat)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(12, 10, iconSize, iconSize)

        draw.SimpleText(eventName, "MontserratBold30", w / 2 + iconSize / 2, 7, eventColor, TEXT_ALIGN_CENTER)
        draw.SimpleText(eventDesc, "MontserratBold20", w / 2 + iconSize / 2, h / 2, eventColor, TEXT_ALIGN_CENTER)
    end
end

hook.Add("HUDPaint", "PB.HudPaint", function()
    local ply = LocalPlayer()
    local specTarget = ply:GetObserverTarget()
    local currentEvent = GetGlobalInt("PB.SpecialRound", 0)

    if (IsValid(PB_HUD)) then
        if (ply:GetModel() != PB_HUD.model:GetModel() and !IsValid(specTarget)) then
            PB_HUD.model:SetModel(ply:GetModel())
            local bone = PB_HUD.model.Entity:LookupBone("ValveBiped.Bip01_Head1")
            if (bone) then
                local headpos = PB_HUD.model.Entity:GetBonePosition(bone)
                PB_HUD.model:SetLookAt(headpos)
                PB_HUD.model:SetCamPos(headpos-Vector(-25, 0, 0))
            end
        elseif (!ply:Alive() and IsValid(specTarget) and ply:GetObserverMode() != OBS_MODE_ROAMING and specTarget:GetModel() != PB_HUD.model:GetModel()) then
            specBool = true
            PB_HUD.model:SetModel(specTarget:GetModel())
            local bone = PB_HUD.model.Entity:LookupBone("ValveBiped.Bip01_Head1")
            if (bone) then
                local headpos = PB_HUD.model.Entity:GetBonePosition(bone)
                PB_HUD.model:SetLookAt(headpos)
                PB_HUD.model:SetCamPos(headpos-Vector(-25, 0, 0))
            end
        end

        if (!IsValid(PB_SPECIAL) and currentEvent != 0) then
            createRoundPanel(ply, currentEvent)
        elseif (IsValid(PB_SPECIAL) and currentEvent == 0) then
            PB_SPECIAL:Remove()
        end
    else
        createDermaHUD(ply)
    end
end)