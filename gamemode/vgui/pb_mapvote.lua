surface.CreateFont("PB_VoteFont", {
    font = "Trebuchet MS",
    size = 19,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("PB_VoteFontCountdown", {
    font = "Tahoma",
    size = 32,
    weight = 700,
    antialias = true,
    shadow = true
})

surface.CreateFont("PB_VoteFontButton",
{    font = "Marlett",
    size = 13,
    weight = 0,
    symbol = true,
})

local PANEL = {}

function PANEL:Init()
    self:ParentToHUD()

    self.Canvas = vgui.Create("Panel", self)
    self.Canvas:MakePopup()
    self.Canvas:SetKeyboardInputEnabled(false)

    self.countDown = vgui.Create("DLabel", self.Canvas)
    self.countDown:SetTextColor(color_white)
    self.countDown:SetFont("PB_VoteFontCountdown")
    self.countDown:SetText("")
    self.countDown:SetPos(0, 14)

    self.mapList = vgui.Create("DPanelList", self.Canvas)
    self.mapList:SetPaintBackground(false)
    self.mapList:SetSpacing(4)
    self.mapList:SetPadding(4)
    self.mapList:EnableHorizontal(true)
    self.mapList:EnableVerticalScrollbar()

    self.closeButton = vgui.Create("DButton", self.Canvas)
    self.closeButton:SetText("")

    self.closeButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowCloseButton", panel, w, h)
    end

    self.closeButton.DoClick = function()
        print("MapVote has started...")
        self:SetVisible(false)
    end

    self.maximButton = vgui.Create("DButton", self.Canvas)
    self.maximButton:SetText("")
    self.maximButton:SetDisabled(true)

    self.maximButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowMaximizeButton", panel, w, h)
    end

    self.minimButton = vgui.Create("DButton", self.Canvas)
    self.minimButton:SetText("")
    self.minimButton:SetDisabled(true)

    self.minimButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowMinimizeButton", panel, w, h)
    end

    self.Voters = {}
end

function PANEL:PerformLayout()
    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    local extra = math.Clamp(300, 0, ScrW() - 640)
    self.Canvas:StretchToParent(0, 0, 0, 0)
    self.Canvas:SetWide(640 + extra)
    self.Canvas:SetTall(640)
    self.Canvas:SetPos(0, 0)
    self.Canvas:CenterHorizontal()
    self.Canvas:SetZPos(0)

    self.mapList:StretchToParent(0, 90, 0, 0)

    local buttonPos = 640 + extra - 31 * 3

    self.closeButton:SetPos(buttonPos - 31 * 0, 4)
    self.closeButton:SetSize(31, 31)
    self.closeButton:SetVisible(true)

    self.maximButton:SetPos(buttonPos - 31 * 1, 4)
    self.maximButton:SetSize(31, 31)
    self.maximButton:SetVisible(true)

    self.minimButton:SetPos(buttonPos - 31 * 2, 4)
    self.minimButton:SetSize(31, 31)
    self.minimButton:SetVisible(true)
end

local star_mat = Material("icon16/star.png")

function PANEL:AddVoter(voter)
    for k, v in pairs(self.Voters) do
        if (v.Player and v.Player == voter) then
            return false
        end
    end


    local icon_container = vgui.Create("Panel", self.mapList:GetCanvas())
    local icon = vgui.Create("AvatarImage", icon_container)
    icon:SetSize(16, 16)
    icon:SetZPos(1000)
    icon:SetTooltip(voter:Name())
    icon_container.Player = voter
    icon_container:SetTooltip(voter:Name())
    icon:SetPlayer(voter, 16)

    if MapVote.HasExtraVotePower(voter) then
        icon_container:SetSize(40, 20)
        icon:SetPos(21, 2)
        icon_container.img = star_mat
    else
        icon_container:SetSize(20, 20)
        icon:SetPos(2, 2)
    end

    icon_container.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(255, 0, 0, 80))

        if (icon_container.img) then
            surface.SetMaterial(icon_container.img)
            surface.SetDrawColor(Color(255, 255, 255))
            surface.DrawTexturedRect(2, 2, 16, 16)
        end
    end

    table.insert(self.Voters, icon_container)
end

function PANEL:Think()
    for k, v in pairs(self.mapList:GetItems()) do
        v.NumVotes = 0
    end

    for k, v in pairs(self.Voters) do
        if (not IsValid(v.Player)) then
            v:Remove()
        else
            if (not MapVote.Votes[v.Player:SteamID()]) then
                v:Remove()
            else
                local bar = self:GetMapButton(MapVote.Votes[v.Player:SteamID()])

                if (MapVote.HasExtraVotePower(v.Player)) then
                    bar.NumVotes = bar.NumVotes + 2
                else
                    bar.NumVotes = bar.NumVotes + 1
                end

                if (IsValid(bar)) then
                    local NewPos = Vector((bar.x + bar:GetWide()) - 21 * bar.NumVotes - 2, bar.y + (bar:GetTall() * 0.5 - 10), 0)

                    if (not v.CurPos or v.CurPos ~= NewPos) then
                        v:MoveTo(NewPos.x, NewPos.y, 0.3)
                        v.CurPos = NewPos
                    end
                end
            end
        end
    end

    local timeLeft = math.Round(math.Clamp(MapVote.EndTime - CurTime(), 0, math.huge))

    self.countDown:SetText(tostring(timeLeft or 0) .. " seconds")
    self.countDown:SizeToContents()
    self.countDown:CenterHorizontal()
end

function PANEL:SetMaps(maps)
    self.mapList:Clear()

    for k, v in RandomPairs(maps) do
        local button = vgui.Create("DButton", self.mapList)
        button.ID = k
        button:SetText(v)

        button.DoClick = function()
            net.Start("PB.MapvoteUpdate")
                net.WriteUInt(MapVote.UPDATE_VOTE, 3)
                net.WriteUInt(button.ID, 32)
            net.SendToServer()
        end

        do
            local Paint = button.Paint
            button.Paint = function(s, w, h)
                local col = Color(255, 255, 255, 10)

                if (button.bgColor) then
                    col = button.bgColor
                end

                draw.RoundedBox(4, 0, 0, w, h, col)
                Paint(s, w, h)
            end
        end

        button:SetTextColor(color_white)
        button:SetContentAlignment(4)
        button:SetTextInset(8, 0)
        button:SetFont("PB_VoteFont")

        local extra = math.Clamp(300, 0, ScrW() - 640)

        button:SetPaintBackground(false)
        button:SetTall(24)
        button:SetWide(285 + (extra / 2))
        button.NumVotes = 0

        self.mapList:AddItem(button)
    end
end

function PANEL:GetMapButton(id)
    for k, v in pairs(self.mapList:GetItems()) do
        if (v.ID == id) then return v end
    end

    return false
end

function PANEL:Paint()
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

function PANEL:Flash(id)
    self:SetVisible(true)

    local bar = self:GetMapButton(id)

    if (IsValid(bar)) then
        timer.Simple(0.0, function() bar.bgColor = Color(0, 255, 255) surface.PlaySound("hl1/fvox/blip.wav") end)
        timer.Simple(0.2, function() bar.bgColor = nil end)
        timer.Simple(0.4, function() bar.bgColor = Color(0, 255, 255) surface.PlaySound("hl1/fvox/blip.wav") end)
        timer.Simple(0.6, function() bar.bgColor = nil end)
        timer.Simple(0.8, function() bar.bgColor = Color(0, 255, 255) surface.PlaySound("hl1/fvox/blip.wav") end)
        timer.Simple(1.0, function() bar.bgColor = Color(100, 100, 100) end)
    end
end

derma.DefineControl("PB_Votescreen", "", PANEL, "DPanel")