// Include needed files
include("sh_config.lua")
include("shared.lua")
include("client/cl_hud.lua")
for k, v in pairs(file.Find("pb/gamemode/vgui/*.lua", "LUA")) do
	include("vgui/" .. v)
end

// DO NOT TOUCH AS IT WOULD BREAK THE GAMEMODE
PB = PB or {}
PB.Config = PB.Config or {}

// Create a console variable to store Spectator status of a player
CreateClientConVar("PB_Spectate", "0", true, true)

// Timer - Garry's mod clientside optimization
timer.Simple(5, function()
	// We don't use "widgets" (entity interaction using mouse), and they are very expensive, so we remove them
	hook.Remove("PlayerTick", "TickWidgets")
	widgets.PlayerTick = function() end
	widgets.RenderMe = function() end
	hook.Remove("PostDrawEffects", "RenderWidgets")

	// Haven't found any documentation on this, but this increases perfomance and don't affecting gameplay
	timer.Remove("CheckHookTimes")

	// Removing default GMOD post-processing - very expensive too
	hook.Remove("RenderScreenspaceEffects", "RenderColorModify")
	hook.Remove("RenderScreenspaceEffects", "RenderBloom")
	hook.Remove("RenderScreenspaceEffects", "RenderToyTown")
	hook.Remove("RenderScreenspaceEffects", "RenderTexturize")
	hook.Remove("RenderScreenspaceEffects", "RenderSunbeams")
	hook.Remove("RenderScreenspaceEffects", "RenderSobel")
	hook.Remove("RenderScreenspaceEffects", "RenderSharpen")
	hook.Remove("RenderScreenspaceEffects", "RenderMaterialOverlay")
	hook.Remove("RenderScreenspaceEffects", "RenderMotionBlur")
	hook.Remove("RenderScene", "RenderStereoscopy")
	hook.Remove("RenderScene", "RenderSuperDoF")
	hook.Remove("GUIMousePressed", "SuperDOFMouseDown")
	hook.Remove("GUIMouseReleased", "SuperDOFMouseUp")
	hook.Remove("PreventScreenClicks", "SuperDOFPreventClicks")
	hook.Remove("PostRender", "RenderFrameBlend")
	hook.Remove("PreRender", "PreRenderFrameBlend")
	hook.Remove("Think", "DOFThink")
	hook.Remove("RenderScreenspaceEffects", "RenderBokeh")
	hook.Remove("NeedsDepthPass", "NeedsDepthPass_Bokeh")
end)

// Function - Override all GM menus lol
function GM:InitPostEntity()
	// Return nothing 
end

// Function - Handle team changes notifications
function GM:TeamChangeNotification(ply, oldteam, newteam)
	// In case player is valid
	if IsValid(ply) then
		local team = team

		// Print to chat (... joined ...)
		if newteam == TEAM_SPEC then
			chat.AddText( team.GetColor(oldteam), ply:Nick(), color_white, " joined Spectators" )
		elseif newteam == TEAM_VICTIMS then
			chat.AddText( team.GetColor(oldteam), ply:Nick(), color_white, " joined ", team.GetColor(newteam), team.GetName(newteam) )
		end

		// Handle team changes - Prevent Killers from changing of team
		if ply == LocalPlayer() and newteam == TEAM_SPEC and oldteam == TEAM_VICTIMS then
			RunConsoleCommand("PB_Spectate", "1")
		elseif ply == LocalPlayer() and oldteam == TEAM_KILLER then
			notification.AddLegacy("It's forbidden to change of teams while being a Killer !", 1, 7)
		elseif ply == LocalPlayer() and oldteam != TEAM_KILLER and newteam == TEAM_VICTIMS then
			RunConsoleCommand("PB_Spectate", "0")
		end
	end
end

// Function - Draw help menu
function ShowHelp()
	if (!IsValid(PB_HELPMENU)) then
		PB_HELPMENU = vgui.Create("pb_popup_help")
	else
		PB_HELPMENU:Remove()
	end
end

// Hook - Handles F1
hook.Add("PlayerButtonDown", "PB.HelpMenu", function( ply, button )
	// Prevent unintended closing when spamming button
	ply.HelpCooldown = ply.HelpCooldown or 0

	// F1 by default
	if (IsValid(ply) and button == 92 and ply.HelpCooldown <= CurTime()) then
		ply.HelpCooldown = CurTime() + 0.5
		ShowHelp()
	end
end)

// Hook - Handle round start
hook.Add("OnRoundStart", "RoundStartUI", function(ply)
	if !IsValid(LocalPlayer()) then return end
	ply = LocalPlayer()

	// Fade screen effect for Killers
	timer.Simple(1, function()
	    if (ply:Team() == TEAM_KILLER) then
		    ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 1.2, 16)
	    end
	end)

	if (#PB.Config.SpecialContent > 0) then
		local getMounted = ply:GetNWBool("PB.SpecialContentMounted", false)

		if (getMounted != true) then
			local table = table
			local requiredContentTbl = {}

			for k, v in ipairs(player.GetAll()) do
				table.Add(requiredContentTbl, table.KeysFromValue(PB.Config.SpecialContent, v:SteamID64()))
			end

			if (#requiredContentTbl > 0) then
				for _, id in ipairs(requiredContentTbl) do
					steamworks.DownloadUGC(id, function(path)
						game.MountGMA(path)
					end)
				end

				ply:SetNWBool("PB.SpecialContentMounted", true)
			end
		end
	end
end)

// Hook - Handle special content mounting
hook.Add("PlayerInitialSpawn", "PB.MountSpecialContent", function(ply, transition)
	timer.Simple(5, function()
		LocalPlayer():SetPData("PB.SpecialContentMounted", false)
	end)
end)

// Hook - Paint a red halo around Killers
if (PB.Config.HalosEnabled) then
	hook.Add("PreDrawHalos", "PB.KillerHalos", function()
		// Fill a table of targets
		local targets = {}
		for k, v in ipairs(team.GetPlayers(TEAM_KILLER)) do
			if (v != LocalPlayer() and v:Alive() and !v:IsDormant()) then
				table.insert(targets, v)
			end
		end

		// Draw halo on all killers
		if (#targets > 0) then
			if (outline) then
				outline.Add(targets, PB.Config.HalosColor or Color(255, 0, 0), OUTLINE_MODE_VISIBLE)
			else
				halo.Add(targets,  PB.Config.HalosColor or Color(255, 0, 0))
			end
		end
	end)
end

// Hook - Fix collisions clientside
if (PB.Config.PreventCollisions) then
	hook.Add("ShouldCollide", "NoCollisionsBetweenPlayersClient", function(ent1, ent2)
		if (ent1:IsPlayer() and ent2:IsPlayer()) then return false end
	end)
end

// Net - Handle Start Round thingies
net.Receive("PB.StartRound", function(len, ply)
	local eventType = GetGlobalInt("PB.SpecialRound", 0)
	local notifSound, notifMsg = eventType != 0 and PB.Config.SpecialRounds[eventType].RoundSound or "ui/buttonclick.wav", eventType != 0 and PB.Config.SpecialRounds[eventType].RoundNotif or "Killers have been unlocked, good luck !"

	notification.AddLegacy(notifMsg, 0, 10)
	LocalPlayer():EmitSound(notifSound)
end)

net.Receive("PB.OnRoundStart", function(len, ply)
	local getRoundNum = net.ReadInt(5)
	hook.Call("OnRoundStart", nil, getRoundNum)
end)

net.Receive("PB.OnRoundEnd", function(len, ply)
	local getRoundNum = net.ReadInt(5)
	hook.Call("OnRoundEnd", nil, getRoundNum)
end)

// Net - Handle notifications
net.Receive("PB.Notify", function(len, ply)
	// Get networked values
	local msg = net.ReadString()
	local notifType = net.ReadInt(8)
	local time = net.ReadInt(8)

	// Basic checks
	if (isstring(msg) and isnumber(notifType) and isnumber(time)) then
		notification.AddLegacy(msg, notifType, time)
	end
end)

// Net - Handle sounds for taunts
if (PB.Config.TauntsEnabled) then
	net.Receive("PB.Taunts", function(len, ply)
		// Useful vars
		if !IsValid(LocalPlayer()) then return end

		local taunt = net.ReadString()
		local owner = net.ReadEntity()

		// If player didn't disable taunts, play it
		if (IsValid(owner) and LocalPlayer():GetPData("PB.TauntsDisabled") == nil) then
			owner:EmitSound(taunt, 40)
		end
	end)

	net.Receive("PB.HandleTauntCommand", function(len, ply)
		// Useful vars
		local fetchResult = net.ReadBool()

		// Save clientside
		if (fetchResult) then
			LocalPlayer():SetPData("PB.TauntsDisabled", "true")
		else
			LocalPlayer():RemovePData("PB.TauntsDisabled")
		end
	end)
end