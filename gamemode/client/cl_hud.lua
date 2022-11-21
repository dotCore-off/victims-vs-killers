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
    PB_HUD.main:SetSize(ScrW() * 0.15, 105)
    PB_HUD.main:SetPos(10, ScrH() - 10 - PB_HUD.main:GetTall())
    PB_HUD.main.Paint = function(self2, w, h)
        draw.RoundedBox(8, 0, 0, w, h, BOTCHED.FUNC.GetTheme(1))

        local boxSize = PB_HUD.model:GetTall()
        local tp = ply:Alive() and ply:Team() or (IsValid(ply:GetObserverTarget()) and ply:GetObserverTarget():Team())
        local tc = team.GetColor(tp)
        local bg = IsColor(tc) and Color(tc.r, tc.g, tc.b, 100) or Color(212, 209, 209, 100)
        draw.RoundedBox(8, (h / 2) - (boxSize / 2), (h / 2) - (boxSize / 2), boxSize, boxSize, bg)
    end

    PB_HUD.model = vgui.Create("DModelPanel", PB_HUD.main)
    PB_HUD.model:SetSize(PB_HUD.main:GetTall() * 0.8, PB_HUD.main:GetTall() * 0.8)
    PB_HUD.model:SetPos((PB_HUD.main:GetTall() / 2) - (PB_HUD.model:GetTall() / 2), (PB_HUD.main:GetTall() / 2) - (PB_HUD.model:GetTall() / 2))
    PB_HUD.model:SetModel("")
    function PB_HUD.model:LayoutEntity(Entity) return end

    local modelDistance = (PB_HUD.main:GetTall() - PB_HUD.model:GetTall()) / 2
    local nameX, nameY = surface.GetTextSize(ply:Nick())

    PB_HUD.name = vgui.Create("DPanel", PB_HUD.main)
    PB_HUD.name:SetSize(ScrW() * 0.12, nameY + 20)
    PB_HUD.name:SetPos(modelDistance + PB_HUD.model:GetWide() + 10, modelDistance + 18)
    PB_HUD.name.Paint = function(self2, w, h)
        team = team
        local spectating = ply:GetObserverTarget()
        if (ply:Alive() or !IsValid(spectating)) then
            draw.SimpleText(ply:Nick(), "MontserratBold30", 0, -5, BOTCHED.FUNC.GetTheme(4))
            draw.SimpleText(team.GetName(ply:Team()), "MontserratMedium23", 1, 15, team.GetColor(ply:Team()))
        elseif (!ply:Alive() and IsValid(spectating)) then
            draw.SimpleText("POV: " .. spectating:Nick(), "MontserratBold30", 0, -5, BOTCHED.FUNC.GetTheme(4))
            draw.SimpleText("Team: " .. team.GetName(spectating:Team()), "MontserratMedium23", 1, 15, team.GetColor(spectating:Team()))
        end
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

    local progressBarH = 10
    PB_HUD.health = vgui.Create("DPanel", PB_HUD.main)
    PB_HUD.health:SetSize(PB_HUD.main:GetWide() / 1.5, progressBarH)
    PB_HUD.health:SetPos(namePanelX, PB_HUD.main:GetTall() - modelDistance-PB_HUD.health:GetTall() - 20)
    PB_HUD.health.Paint = function(self2, w, h)
        surface.SetFont("MontserratBold25")
        local curHealthX = surface.GetTextSize(math.max(0, ply:Health()))

        if (healthX != curHealthX) then
            RefreshRightTextW()
        end

        local progressBarW = w-rightTextW-5
        if (ply:Alive() or IsValid(ply:GetObserverTarget())) then
            draw.RoundedBox(progressBarH / 2, 0, 0, progressBarW, progressBarH, BOTCHED.FUNC.GetTheme(2))
        end

        BOTCHED.FUNC.DrawRoundedMask(progressBarH / 2, 0, 0, progressBarW, progressBarH, function()
            surface.SetDrawColor(Color(241, 57, 57))
            if (ply:Alive()) then
                surface.DrawRect(0, 0, progressBarW * math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1), progressBarH)
            elseif (!ply:Alive() and IsValid(ply:GetObserverTarget())) then
                surface.DrawRect(0, 0, progressBarW * math.Clamp(ply:GetObserverTarget():Health() / ply:GetObserverTarget():GetMaxHealth(), 0, 1), progressBarH)
            end
        end)
    end

    local fadedClr, evenMoreFaded = Color(255, 255, 255, 150), Color(255, 255, 255, 25)
    PB_HUD.timebox = vgui.Create("DPanel", PB_HUD)
    PB_HUD.timebox:SetSize(ScrW() * 0.15, 105)
    PB_HUD.timebox:SetPos(ScrW() - 10 - PB_HUD.timebox:GetWide(), ScrH() - 10 - PB_HUD.timebox:GetTall())
    PB_HUD.timebox.Paint = function(self2, w, h)
        GAMEMODE = GAMEMODE
        string = string
        draw.RoundedBox(8, 0, 0, w, h, BOTCHED.FUNC.GetTheme(1))

        surface.SetDrawColor(fadedClr)
        draw.NoTexture()
        surface.DrawLine(10, 10, w-10, h-10)


        local roundEndTime = GetGlobalFloat("RoundEndTime")
        local roundRemaining = string.ToMinutesSeconds(roundEndTime - CurTime())
        local currentRound = GetGlobalInt("RoundNumber") or 0
        local timeString = "Remaining time: " .. roundRemaining
        if ((roundRemaining <= "00:00" or roundRemaining > "05:00") and GAMEMODE:GetGameTimeLeft() > 0) then
            timeString = "Mapvote starts in " .. string.ToMinutesSeconds(GAMEMODE:GetGameTimeLeft())
        elseif ((roundRemaining <= "00:00" or roundRemaining > "05:00") and GAMEMODE:GetGameTimeLeft() <= 0) then
            timeString = "Mapvote will start soon..."
        end

        draw.SimpleText("Round " .. currentRound .. " / " .. PB.Config.MaxRounds, "MontserratBold30", 65, h-40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(timeString, "MontserratMedium20", 85, h-20, fadedClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText("Playing on " .. game.GetMap(), "MontserratMedium20", w-90, 15, fadedClr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ply:SteamID64(), "MontserratMedium17", w-58, 35, evenMoreFaded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function createRoundPanel(ply, event)
    local fetchSpecialRound = PB.Config.SpecialRounds[event]
    local eventName, eventDesc, eventMat = fetchSpecialRound.RoundName, fetchSpecialRound.RoundDescription, fetchSpecialRound.RoundMaterial
    local eventColor = fetchSpecialRound.RoundColor

    local roundMat = Material(eventMat)
    local firstPart = {
        { x = 0, y = 10 },
        { x = 75, y = 10 },
        { x = 40, y = 60 },
        { x = 0, y = 60 },
    }
    local secondPart = {
        { x = 75, y = 10 },
        { x = 75 + 417 * 0.7, y = 10 },
        { x = 75 + 417 * 0.7, y = 60 },
        { x = 40, y = 60 },
    }

    PB_SPECIAL = vgui.Create("DPanel", PB_HUD)
    PB_SPECIAL:SetSize(75 + 417 * 0.7, 70)
    PB_SPECIAL:SetPos(ScrW() / 2 - (PB_SPECIAL:GetWide() / 2), 10)
    PB_SPECIAL.Paint = function(self2, w, h)
        surface.SetDrawColor(BOTCHED.FUNC.GetTheme(1))
        draw.NoTexture()
        surface.DrawPoly(firstPart)

        surface.SetDrawColor(BOTCHED.FUNC.GetTheme(2))
        draw.NoTexture()
        surface.DrawPoly(secondPart)

        surface.SetDrawColor(eventColor)
        draw.NoTexture()
        surface.DrawOutlinedRect(0, 10, self2:GetWide(), 50, 1)

        local iconSize = 32
        surface.SetMaterial(roundMat)
        surface.SetDrawColor(color_white)
        surface.DrawTexturedRect(10, 18, iconSize, iconSize)

        draw.SimpleText(eventName, "MontserratBold30", w / 2 + iconSize / 2, 15, eventColor, TEXT_ALIGN_CENTER)
        draw.SimpleText(eventDesc, "MontserratBold20", w / 2 + iconSize / 2, h / 2 + 2, eventColor, TEXT_ALIGN_CENTER)

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
