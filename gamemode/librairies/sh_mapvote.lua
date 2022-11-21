PB = PB or {}
PB.Config = PB.Config or {}

if (CLIENT) then
    PB_Mapvote_Endtime = 0
    PB_Mapvote_Panel = false

    net.Receive("PB.MapvoteStart", function()
        PB_Mapvote_CurrentMaps = {}
        PB_Mapvote_Allow = true
        PB_Mapvote_Votes = {}

        local amt = net.ReadUInt(32)

        for i = 1, amt do
            local map = net.ReadString()
            PB_Mapvote_CurrentMaps[#PB_Mapvote_CurrentMaps + 1] = map
        end

        MapVote.EndTime = CurTime() + net.ReadUInt(32)

        if (IsValid(PB_Mapvote_Panel)) then
            PB_Mapvote_Panel:Remove()
        end

        PB_Mapvote_Panel = vgui.Create("PB_Votescreen")
        PB_Mapvote_Panel:SetMaps(PB_Mapvote_CurrentMaps)
    end)

    net.Receive("PB.MapvoteUpdate", function()
        local update_type = net.ReadUInt(3)

        if (update_type == MapVote.UPDATE_VOTE) then
            local ply = net.ReadEntity()

            if (IsValid(ply)) then
                local map_id = net.ReadUInt(32)
                PB_Mapvote_Votes[ply:SteamID()] = map_id

                if (IsValid(PB_Mapvote_Panel)) then
                    PB_Mapvote_Panel:AddVoter(ply)
                end
            end
        elseif (update_type == MapVote.UPDATE_WIN) then
            if (IsValid(PB_Mapvote_Panel)) then
                PB_Mapvote_Panel:Flash(net.ReadUInt(32))
            end
        end
    end)

    net.Receive("PB.MapvoteCancel", function()
        if IsValid(PB_Mapvote_Panel) then
            PB_Mapvote_Panel:Remove()
        end
    end)

    net.Receive("PB.RtvDelay", function()
        chat.AddText("[Mapvote] The vote has been rocked, map vote will begin on round end")
    end)
end

if (SERVER) then
    util.AddNetworkString("PB.MapvoteStart")
    util.AddNetworkString("PB.MapvoteUpdate")
    util.AddNetworkString("PB.MapvoteCancel")
    util.AddNetworkString("PB.RtvDelay")

    PB_Mapvote_Continued = false

    net.Receive("PB.MapvoteUpdate", function(len, ply)
        if (PB_Mapvote_Allow and IsValid(ply)) then
            local update_type = net.ReadUInt(3)

            if (update_type == MapVote.UPDATE_VOTE) then
                local map_id = net.ReadUInt(32)

                if (PB_Mapvote_CurrentMaps[map_id]) then
                    PB_Mapvote_Votes[ply:SteamID()] = map_id

                    net.Start("PB.MapvoteUpdate")
                        net.WriteUInt(MapVote.UPDATE_VOTE, 3)
                        net.WriteEntity(ply)
                        net.WriteUInt(map_id, 32)
                    net.Broadcast()
                end
            end
        end
    end)

    if (file.Exists("mapvote/recentmaps.txt", "DATA")) then
        recentmaps = util.JSONToTable(file.Read("mapvote/recentmaps.txt", "DATA"))
    else
        recentmaps = {}
    end

    function CoolDownDoStuff()
        cooldownnum = 3

        if (#recentmaps == cooldownnum) then
            table.remove(recentmaps)
        end

        local curmap = game.GetMap():lower() .. ".bsp"

        if (!table.HasValue(recentmaps, curmap)) then
            table.insert(recentmaps, 1, curmap)
        end

        file.Write("mapvote/recentmaps.txt", util.TableToJSON(recentmaps))
    end

    function PB_MapvoteStart()
        current, cooldown = game.GetMap(), true
        length = PB.Config.MapvoteLength or 28
        limit = PB.Config.MapvoteLimit or 24
        prefix = PB.Config.MapvotePrefixs or { "pb", "zs", "ph", "ttt" }

        local is_expression, adminMod = false, (PB.Config.MapvoteAdminmod or "ulx")
        local mapGlobal = ((adminMod == "sam" and sam.get_global("Maps")) or (adminMod == "ulx" and ulx.votemaps) or false)

        if (!prefix) then
            local info = file.Read(GAMEMODE.Folder .. "/" .. GAMEMODE.FolderName .. ".txt", "GAME")

            if (info) then
                info = util.KeyValuesToTable(info)
                prefix = info.maps
            else
                error("MapVote Prefix can not be loaded from gamemode")
            end

            is_expression = true
        else
            if (prefix and type(prefix) != "table") then
                prefix = { prefix }
            end
        end

        local maps = {}

        if (mapGlobal != false) then
            for _, map in pairs(mapGlobal) do
                table.insert(maps, map .. ".bsp")
            end
        else
            maps = file.Find("maps/*.bsp", "GAME")
        end

        local vote_maps = {}

        local amt = 0

        for k, map in RandomPairs(maps) do
            if (!current and game.GetMap():lower() .. ".bsp" == map) then continue end
            if (cooldown and table.HasValue(recentmaps, map)) then continue end
            if (string.StartWith(map, "cs_") or string.StartWith(map, "de_")) then continue end
            if (istable(PB.Config.MapvoteBlacklisted) and table.HasValue(PB.Config.MapvoteBlacklisted, map..".bsp")) then continue end

            if (is_expression) then
                if (string.find(map, prefix)) then
                    vote_maps[#vote_maps + 1] = map:sub(1, -5)
                    amt = amt + 1
                end
            else
                for _, v in pairs(prefix) do
                    if (string.find(map, "^" .. v)) then
                        vote_maps[#vote_maps + 1] = map:sub(1, -5)
                        amt = amt + 1
                        break
                    end
                end
            end

            if (limit and amt >= limit) then break end
        end

        net.Start("PB.MapvoteStart")
            net.WriteUInt(#vote_maps, 32)

            for i = 1, #vote_maps do
                net.WriteString(vote_maps[i])
            end

            net.WriteUInt(length, 32)
        net.Broadcast()

        PB_Mapvote_Allow = true
        PB_Mapvote_CurrentMaps = vote_maps
        PB_Mapvote_Votes = {}

        timer.Create("PB.MapVote", length, 1, function()
            PB_Mapvote_Allow = false
            local map_results = {}

            for k, v in pairs(PB_Mapvote_Votes) do
                if (!map_results[v]) then
                    map_results[v] = 0
                end

                for k2, v2 in pairs(player.GetAll()) do
                    if (v2:SteamID() == k) then
                        map_results[v] = map_results[v] + 1
                    end
                end
            end

            CoolDownDoStuff()

            local winner = table.GetWinningKey(map_results) or 1

            net.Start("PB.MapvoteUpdate")
                net.WriteUInt(MapVote.UPDATE_WIN, 3)
                net.WriteUInt(winner, 32)
            net.Broadcast()

            local map = PB_Mapvote_CurrentMaps[winner]

            timer.Simple(4, function()
                hook.Run("MapVoteChange", map)
                RunConsoleCommand("changelevel", map)
            end)
        end)
    end

    hook.Add("Shutdown", "PB.RemoveRecentMaps", function()
        if (file.Exists("mapvote/recentmaps.txt", "DATA")) then
            file.Delete("mapvote/recentmaps.txt")
        end
    end)

    function PB_MapvoteCancel()
        if (PB_Mapvote_Allow) then
            PB_Mapvote_Allow = false

            net.Start("PB.MapvoteCancel")
            net.Broadcast()

            timer.Remove("RAM_MapVote")
        end
    end

    /*
        RTV SYSTEM
    */
    PB_TotalVotes, PB_PlayerCount = 0, 2
    PB_ActualWait = CurTime() + (PB.Config.MapvoteRtvWait or 120)

    function PB_RTVShouldChange()
        return PB_TotalVotes >= math.Round(#player.GetAll() * 0.66)
    end

    function PB_RTVRemoveVote()
        PB_TotalVotes = math.Clamp(PB_TotalVotes - 1, 0, math.huge)
    end

    function PB_RTVStart()
        PrintMessage(HUD_PRINTTALK, "[Mapvote] Vote has been rocked, mapvote will start soon!")
        timer.Simple(4, function()
            PB_MapvoteStart()
        end)
    end

    function PB_RTVAddVote(ply)
        if (PB_RTVCanVote(ply)) then
            PB_TotalVotes = PB_TotalVotes + 1
            ply.PBRTV = true
            PrintMessage(HUD_PRINTTALK, "[Mapvote] " .. ply:Nick() .. " has voted to rock the map! (" .. PB_TotalVotes .. "/" .. math.Round(#player.GetAll() * 0.66) .. ")")

            if (PB_RTVShouldChange()) then
                PB_RTVStart()
            end
        end
    end

    hook.Add("PlayerDisconnected", "PB.RemoveRtv", function(ply)
        if (ply.PBRTV) then
            PB_RTVRemoveVote()
        end

        timer.Simple(0.1, function()
            if (PB_RTVShouldChange()) then
                PB_RTVStart()
            end
        end)
    end)

    function PB_RTVCanVote(ply)
        local plyCount = #player.GetAll()

        if (PB_ActualWait >= CurTime()) then
            return false, "[Mapvote] You must wait a bit before voting!"
        end

        if (GetGlobalBool("In_Voting")) then
            return false, "[Mapvote] There's already a vote in progress!"
        end

        if (ply.PBRTV) then
            return false, "[Mapvote] You have already voted to rock the vote!"
        end

        if (plyCount < PB_PlayerCount) then
            return false, "[Mapvote] You need more players before you can rock the vote!"
        end

        return true
    end

    function PB_RTVStartVote(ply)
        local can, err = PB_RTVCanVote(ply)

        if (!can) then
            ply:PrintMessage(HUD_PRINTTALK, err)
            return
        end

        PB_RTVAddVote(ply)
    end

    concommand.Add("pb_rtv", PB_RTVStartVote)

    hook.Add("PlayerSay", "PB.RtvHandler", function(ply, text)
        if (table.HasValue(PB.Config.MapvoteRtvCommands, string.lower(text))) then
            PB_RTVStartVote(ply)
            return ""
        end
    end)
end