PB = PB or {}
PB.Config = PB.Config or {}

if (PB.Config.NotificationEnabled) then
    util.AddNetworkString("PB.Notify")
end

util.AddNetworkString("PB.StartRound")
util.AddNetworkString("PB.OnRoundStart")
util.AddNetworkString("PB.OnRoundEnd")

if (PB.Config.TauntsEnabled) then
    util.AddNetworkString("PB.Taunts")
    util.AddNetworkString("PB.HandleTauntCommand")

    hook.Add("PlayerSay", "PB.TauntsCommandFilter", function(ply, msg)
        if (!IsValid(ply) or !table.HasValue(PB.Config.TauntsCommands, string.lower(msg))) then return end

        if (ply:GetPData("PB.TauntsDisabled") == nil) then
            ply:SetPData("PB.TauntsDisabled", "true")
            ply:ConCommand("stopsound")
            net.Start("PB.HandleTauntCommand")
                net.WriteBool(true)
            net.Send(ply)
        else
            ply:RemovePData("PB.TauntsDisabled")
            net.Start("PB.HandleTauntCommand")
                net.WriteBool(false)
            net.Send(ply)
        end

        ply:Notify(ply:GetPData("PB.TauntsDisabled") == nil and "Taunts are now enabled!" or "Taunts are now disabled!", 0, 5)
        return ""
    end)
end

if (PB.Config.ProtectionEnabled) then
    hook.Add("PlayerInitialSpawn", "PB.ProtectionChecks", function(ply, bool)
        timer.Simple(1.5, function()
            if (!IsValid(ply) or !ply:IsPlayer() or ply:IsBot() or table.HasValue(ply:SteamID()) or table.HasValue(ply:SteamID64()) or bool) then return end

            if (PB.Config.ProtectionEnabledVpn) then
                local playerAddress = ""

                for k,v in ipairs(string.ToTable(ply:IPAddress())) do
                    if (v == ":") then break end
                    playerAddress = playerAddress .. v
                end

                http.Fetch("https://proxycheck.io/v2/" .. playerAddress .. "?vpn=1", function(res)
                    res = res and util.JSONToTable(res)

                    if (res[playerAddress] and res[playerAddress].proxy == "yes") then
                        ply:Punish(PB.Config.ProtectSanctionType, "It's forbidden to use a VPN on this server!", PB.Config.ProtectSanctionLength)
                    end
                end)
            end

            if (PB.Config.ProtectionEnabledAlts) then
                local finalSid64 = ply:OwnerSteamID64() != ply:SteamID64() and ply:OwnerSteamID64() or ply:SteamID64()

                local function IsBanned(sid64)
                    local sid32 = util.SteamIDFrom64(sid)

                    if sAdmin and sAdmin.isBanned then
                        return sAdmin.isBanned(sid64)
                    elseif sam and sam.player and sam.player.is_banned then
                        return sam.player.is_banned(sid32, callback)
                    elseif ulx and ULib and ULib.bans then
                        return tobool(ULib.bans[sid32])
                    elseif xAdmin and xAdmin.Admin and xAdmin.Admin.Bans then
                        local data = xAdmin.Admin.Bans[sid64]
                        local endtime = data.StartTime + (data.Length * 60)

                        return data and (tonumber(endtime) <= os.time()) or false
                    end
                end

                local altBanned = IsBanned(finalSid64)

                if (altBanned) then
                    ply:Punish(PB.Config.ProtectSanctionType, "We detected a banned alt account!", PB.Config.ProtectSanctionLength)
                end
            end
        end)
    end)
end