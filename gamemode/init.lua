// Load needed files
if (SERVER) then
	include("sh_config.lua")
	include("shared.lua")
	include("sh_functions.lua")
	include("sv_network.lua")

	AddCSLuaFile("sh_config.lua")
	AddCSLuaFile("shared.lua")
	AddCSLuaFile("sh_functions.lua")
	AddCSLuaFile("cl_init.lua")
	AddCSLuaFile("client/cl_hud.lua")
	AddCSLuaFile("vgui/pb_popup_base.lua")
	AddCSLuaFile("vgui/pb_popup_help.lua")
else
	include("sh_config.lua")
	include("sh_functions.lua")
	include("cl_init")
	include("client/cl_hud")
end

// DO NOT TOUCH 
PB = PB or {}
PB.Config = PB.Config or {}
PB.PickedTbl = {}

// Include enabled librairies
if (PB.Config.TauntsEnabled) then
	include("librairies/sv_taunt.lua")
elseif (PB.Config.SlidingEnabled) then
	include("sh_sliding.lua")
	AddCSLuaFile("sh_sliding.lua")
elseif (PB.Config.EnableHelpMenu) then
	resource.AddWorkshop("2551039439")
elseif (PB.Config.MapvoteEnabled) then
	include("librairies/sh_mapvote.lua")
	AddCSLuaFile("librairies/sh_mapvote.lua")
end

// Localize stuff we'll use or use often
local isBig = PB.Config.BigMaps[game.GetMap()] or false
local table, hook, math, timer = table, hook, math, timer

// Function - Pick a bear randomly among Victims
function PickBear(amount)
	// Test the amount given & create a fallback var
	// We do that so that we're sure at least one Killer get picked
	if (amount == nil) then amount = 1 end

	// Fetch all available Victims & store into a table
	local team = team
	local table = table
	local victs = team.GetPlayers(TEAM_VICTIMS)

	// Our loop var
	local i = 0
	local tempTab = {}

	// Pick a certain amount of bears
	while (i < amount) do
		// Pïck randomly a player
		local pickedPlayer = table.Random(victs)

		// Handle first round cases
		if (!table.IsEmpty(PB.PickedTbl) and table.Count(player.GetAll()) > 1) then
			// Re-pick a new player till it's someone that never got picked lol
			while (table.HasValue(PB.PickedTbl, pickedPlayer)) do
				pickedPlayer = table.Random(victs)
			end
		end

		// Test if the picked player is valid
		if (IsValid(pickedPlayer)) then
			// Change team
			pickedPlayer:SetTeam(TEAM_KILLER)

			// Edit picked players table to insert newly picked player & remove the old one
			table.insert(tempTab, pickedPlayer)
		end

		// Increment (unsure if I can use i++ lol)
		i = i + 1
	end

	// Verify if the table is empty or not, if it's isn't, empty it as verifications are done
	if (!table.IsEmpty(PB.PickedTbl)) then
		table.Empty(PB.PickedTbl)
	end

	// Merge both tables to get a new row of picked players
	table.Add(PB.PickedTbl, tempTab)
end

// TODO: Logic elsewhere
// Function - Pick a random event to trigger from a table
function PickEvents(forced)
	if (isnumber(forced) and forced != 0) then
		SetGlobalInt("PB.SpecialRound", forced)
		SetGlobalInt("PB.ForcedRound", 0)
		return
	end

	for k, v in ipairs(PB.Config.SpecialRounds) do
		if (table.IsEmpty(v) or !isnumber(v.Rarity)) then continue end
		local luck = math.random(10)

		if (luck > v.Rarity * 10) then
			SetGlobalInt("PB.SpecialRound", k)
			break
		end
	end
end

// Function - Pre round start (before OnRoundStart)
function GM:OnPreRoundStart(num)
	game.CleanUpMap(false, {"env_fire", "entityflame", "_firesmoke"})

	// Remove unwanted entities on round start
	if (#PB.Config.ForbiddenEntities > 0) then
		local forbiddenEntities = {}

		for k,v in ipairs(PB.Config.ForbiddenEntities) do
			table.Add(ents.FindByClass(v), forbiddenEntities)
		end

		for k,v in ipairs(forbiddenEntities) do
			v:Remove()
		end
	end

	// Run map modification function if it exists
	if (PB.Config.MapsModification[game.GetMap()]) then
		PB.Config.MapsModification[game.GetMap()].runFunc()
	end

	// Add all potential players into a table
	local newVictims = table.Add(team.GetPlayers(TEAM_KILLER), team.GetPlayers(TEAM_UNASSIGNED))

	// Loop through players and add to requested team
	for k,v in ipairs(newVictims) do
		if !IsValid(v) then return end
		v:SetTeam(v:GetInfoNum("PB_Spectate", 0) == 1 and TEAM_SPEC or TEAM_VICTIMS)
	end

	// Dynamically decide the amount of future Killers depending of map & player count
	local killerAmount = 1
	local totalPlayer = table.Count(player.GetAll()) - table.Count(team.GetPlayers(TEAM_SPEC))
	local requiredTier = PB.Config.KillerTier or 10

	// If the map is big, we divide the tier in half
	if (isBig) then requiredTier = 7 end

	// Determine the amount of Killers based on different tiers
	if (totalPlayer >= requiredTier * 2 and totalPlayer < requiredTier * 3) then
		killerAmount = 2
	elseif (totalPlayer >= requiredTier * 3) then
		killerAmount = 3
	end

	// Special rounds handler
	SetGlobalInt("PB.SpecialRound", 0)
	PickEvents(GetGlobalInt("PB.ForcedRound", 0))

	// Pick Killers depending of above determined amount
	PickBear(killerAmount)

	// Some utilities
	UTIL_FreezeAllPlayers()
	UTIL_StripAllPlayers()
	UTIL_SpawnAllPlayers()

	// Reset bool
	PB.IsKillerReleased = false

	// Start round sound
	if (timer.Exists("PB.SendStartNotif")) then timer.Remove("PB.SendStartNotif") end
	timer.Create("PB.SendStartNotif", GetGlobalInt("PB.SpecialRound", 0) != 0 and 1 or 20, 1, function()
		net.Start("PB.StartRound")
		net.Broadcast()
	end)

	// Run special round specific functions
	if (GetGlobalInt("PB.SpecialRound", 0) != 0) then
		PB.Config.SpecialRounds[GetGlobalInt("PB.SpecialRound")].HookOverrides()
	end

	// Some hooks calls & config
	hook.Call("OnPreRoundStart", nil, num)
	BroadcastLua("hook.Call( [[OnPreRoundStart]], nil, " .. num .. ")")
end

// Function - On round start (after OnPreRoundStart)
function GM:OnRoundStart(num)
	// Run a few utilities
	UTIL_UnFreezeAllPlayers()
	UTIL_FixJoiningConnectingPlayers()

	// Call some hooks for gamemode's shits
	// We broadcast to everyone + send round's number
	hook.Call("OnRoundStart", nil, num)

	net.Start("PB.OnRoundStart")
		net.WriteInt(num, 5)
	net.Broadcast()

	// We determine the unlock time
	local unlockTime = math.Clamp(PB.Config.KillerUnlockTime - (CurTime() - GetGlobalFloat("RoundStartTime", 0)), 0, PB.Config.KillerUnlockTime) + 2

	// Create a timer
	timer.Simple(unlockTime, function()
		// On timer's ends, broadcast that Killers must be unlocked / released
		PB.IsKillerReleased = true
	end)
end

// Function - On round end
function GM:OnRoundEnd(num)
	// Destroy the var
	PB.IsKillerReleased = nil

	// Broadcast to everyone that the round has ended
	hook.Call( "OnRoundEnd", nil, num )
	net.Start("PB.OnRoundEnd")
		net.WriteInt(num, 5)
	net.Broadcast()
end

// Function - Has the round limit been reached ?
function GM:HasReachedRoundLimit(num)
	// Check if we reached round limit
	if (num > PB.Config.MaxRounds) then
		// Broadcast that we reached it + vote map
		hook.Run("GamemodeMaxRoundReached")
		PB.Config.EndMapFunction()
	end

	// Else, return false
	return false
end

// Function - Victims win + reward them
function GM:RoundTimerEnd()
	// Test if we're in an ongoing round or not
	if !GAMEMODE:InRound() then return end

	// Announce round results
	GAMEMODE:RoundEndWithResult(-1, "Time's Up ! - Victims Wins")

	// Count the amount of Victims
	local victims = table.Count(team.GetPlayers(TEAM_VICTIMS))

	// Loop through Victims and for each dead one, decrement above var
	for k,v in ipairs(team.GetPlayers(TEAM_VICTIMS)) do
		if (!v:Alive()) then
			victims = victims - 1
		end
	end

	// Reward players based on alive players
	if (table.Count(player.GetAll()) > 4) then
		for k,v in ipairs(team.GetPlayers(TEAM_VICTIMS)) do
			// Only reward if player is still alive at the end of the round
			if (v:Alive()) then
				v:GiveMoney(PB.Config.VictimsRewardsWin and PB.Config.VictimsRewardsWin or 0)
			end
		end
	end
end

// Function - Check who's alive in each teams and if there's only one team remaining
function GM:CheckPlayerDeathRoundEnd()
	if !GAMEMODE:InRound() then return end
	local getTeams = GAMEMODE:GetTeamAliveCounts()

	if (table.Count(getTeams) == 0) then
		// Announce round results
		GAMEMODE:RoundEndWithResult(TEAM_KILLER, "Draw ? - No, Killer Wins !")

		// Reward Killers
		if (PB.Config.KillerRewardsWin and #player.GetAll() > PB.Config.KillerRewardsPlayers) then
			for k,v in ipairs(team.GetPlayers(TEAM_KILLER)) do
				v:GiveMoney(PB.Config.KillerRewardsWin)
				v:Notify("You killed all Victims ! Got " .. PB.Config.KillerRewardsWin ..   " " .. PB.Config.RewardsCurrency .. " for this slaughter.", 0, 8)
			end
		end

		return
	elseif (table.Count(getTeams) == 1) then
		if (next(getTeams) == TEAM_VICTIMS) then
			// Announce round results
			GAMEMODE:RoundEndWithResult(TeamID, "No remaining Killer - Victims Wins !")

			// Reward Victims
			if (PB.Config.VictimsRewardsWin and #player.GetAll() > PB.Config.VictimsRewardsPlayers) then
				for k,v in ipairs(team.GetPlayers(TEAM_VICTIMS)) do
					// Only reward if player is still alive at the end of the round
					if (v:Alive()) then
						v:GiveMoney(PB.Config.VictimsRewardsWin)
					end
				end
			end
		else
			// Announce round results
			GAMEMODE:RoundEndWithResult(TeamID, "No survivor... - Killer Wins !")

			// Reward Killers
			if (PB.Config.KillerRewardsWin and #player.GetAll() > PB.Config.KillerRewardsPlayers) then
				for k,v in ipairs(team.GetPlayers(TEAM_KILLER)) do
					v:GiveMoney(PB.Config.KillerRewardsWin)
					v:Notify("All Victims are dead! Got " .. PB.Config.KillerRewardsWin ..   " " .. PB.Config.RewardsCurrency .. " for this slaughter.", 0, 8)
				end
			end
		end
	end
end

// Function - Called after OnPlayerDeath
function GM:PostPlayerDeath(ply)
	// Force player into an observation mode
	ply:Spectate(OBS_MODE_DEATHCAM)

	// Populate player's death
	ply:OnDeath()
	hook.Call("PostPlayerDeath")
end

// Function - Make sure that spawnpoint is correct
function GM:IsSpawnpointSuitable(ply, spawnpointent, bMakeSuitable)
	// Get position
	local Pos = spawnpointent:GetPos()

	// Overriding default function so people will not get killed on spawn
	local Ents = ents.FindInBox(Pos + Vector(-16, -16, 0), Pos + Vector(16, 16, 72))

	// In case player can't play -> ignore
	if (ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED) then return true end

	// Will represent the total amount of blockers
	local Blockers = 0

	// Loop through all found entities
	for k,v in ipairs(Ents) do
		if (IsValid(v) and v:GetClass() == "player" and v:Alive()) then
			Blockers = Blockers + 1
		end
	end

	// If something blocks -> spawnpoint isn't suitable & we end
	if (Blockers > 0) then return false end

	// Else, consider it as a good spawnpoint
	return true
end

// Function - Prevent players from entering vehicles
function GM:CanPlayerEnterVehicle(ply, vehicle, seat)
	if !IsValid(ply) then return end

	return false
end

// Func - Prevent Spectators from picking up weapons
function GM:PlayerCanPickupWeapon(ply)
	if !IsValid(ply) then return end
	if (ply:Team() != TEAM_VICTIMS and ply:Team() != TEAM_KILLER) then
		return false
	else
		return true
	end
end

// Func - Prevent Flashlight spam
if (PB.Config.PreventFlashlightSpam) then
	function GM:PlayerSwitchFlashlight(ply, enabled)
		ply.flashCooldown = ply.flashCooldown or 0

		if (CurTime() >= ply.flashCooldown) then
			ply.flashCooldown = CurTime() + 0.5
			return true
		else
			return false
		end
	end
end

// Hook - Nerf Bhop by capping the max speed players can reach
if (PB.Config.BhopProtection) then
	hook.Add("OnPlayerHitGround", "NerfBhop", function(ply, inWater, onFloater, speed)
		if (!inWater) then
			// Get player's current velocity
			local plyVelocity = ply:GetVelocity()
			local speedTier = PB.Config.BhopSpeed

			// Apply a few test based on determined limits
			if (plyVelocity.x > speedTier or plyVelocity.x < -speedTier or plyVelocity.y > speedTier or plyVelocity.y < -speedTier) then
				local suppressor = 1 + (50 / 100)
				ply:SetVelocity(Vector(-(plyVelocity.x / suppressor), -(plyVelocity.y / suppressor), 0))
			end
		end
	end)
end

// Hook - Remove all collisions + force field effect
if (PB.Config.PreventCollisions) then
	hook.Add("ShouldCollide", "NoCollisionsBetweenPlayersServer", function(ent1, ent2)
		if (ent1:IsPlayer() and ent2:IsPlayer()) then return false end
	end)
end

// Hook - Prevent spectators from interacting w/ world
hook.Add("PlayerSpawn", "FixSpectators", function(ply)
	if (ply:Team() != TEAM_KILLER and ply:Team() != TEAM_VICTIMS) then
		ply:KillSilent()
	end
end)

// Add current played map to FastDL - prevent having a huge collection for plys to download
resource.AddWorkshop(table.KeyFromValue(PB.Config.AvailableMaps, game.GetMap()))

// A few GMOD related optimizations
hook.Remove("PlayerTick", "TickWidgets")
widgets.PlayerTick = function() end
timer.Remove("CheckHookTimes")
