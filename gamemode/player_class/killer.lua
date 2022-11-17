// DO NOT TOUCH AS IT WOULD BREAK THE GAMEMODE
PB = PB or {}
PB.Config = PB.Config or {}

local CLASS = {}

CLASS.DisplayName			= "Killer"						// The name that will be displayed for this class
CLASS.WalkSpeed 			= PB.Config.KillerSpeedWalk			// The walk speed | Default : 250
CLASS.CrouchedWalkSpeed 	= 0.2 							// Speed when walking while crouching | Default : 0.2
CLASS.RunSpeed				= PB.Config.KillerSpeedRun			// The run speed | Default : 305
CLASS.DuckSpeed				= 0.2							// Speed when ducking | Default : 0.2
CLASS.JumpPower				= PB.Config.KillerJumpPower		// The jump power | Default : 260
CLASS.PlayerModel			= istable(PB.Config.KillerModel) and table.Random(PB.Config.KillerModel	) or PB.Config.KillerModel
CLASS.DrawTeamRing			= true
CLASS.DrawViewModel			= true
CLASS.CanUseFlashlight      = true
CLASS.MaxHealth				= PB.Config.KillerHealth 				// Maximum health lol
CLASS.StartHealth			= PB.Config.KillerHealthMax
CLASS.StartArmor			= PB.Config.KillerArmor
CLASS.RespawnTime           = 0
CLASS.DropWeaponOnDie		= false
CLASS.TeammateNoCollide 	= true							// Can teammates walk through them
CLASS.AvoidPlayers			= false 						// Automatically avoid players that were no colliding
CLASS.Selectable			= false 						// When false, this disables all the team checking
CLASS.FullRotation			= false 						// Allow the players model to rotate upwards, etc etc

// Function - Unlock a player
function UnlockPlayer(ply)
	// Test if the given entity is valid
	if !IsValid(ply) then return end

	// Unlock
	ply:SetRenderMode(0)
	ply:SetColor(ply.ModelColor)
	ply:UnLock()
	ply.KillerCanCatch = true
end

// Function - Lock a player
function LockPlayer(ply, time)
	// Test if the given entity is valid
	if !IsValid(ply) then return end

	// Lock
	ply:Lock()
	ply.KillerCanCatch = false

	// Makes player a bit transparent so that others understand he's locked
	ply:SetRenderMode(1)
	ply:SetColor(Color(255, 255, 255, 80))

	// Notice player that he's locked
	ply:Notify("You're a Killer ! You will be unlocked in approximately " .. math.Round(time) .. " seconds.", 0, 8)
end

// This will be executed for each Killer spawn
function CLASS:OnSpawn(pl)
	// Basic thingies
	// Apply a few methods & bind some datas
	local unlockTime = 20
	local isInfected = GetGlobalInt("PB.SpecialRound", 0)
	pl:UnSpectate()
	pl:SetCustomCollisionCheck(true)
	pl:SetCollisionGroup(8)
	pl.last_taunt_time = nil
	pl.hasKillerEquipped = pl:GetNWBool("PB.HasKillerEquipped", false)
	pl.killerModel = pl:GetNWString("PB.GetKiller")
	pl:SetMaxSpeed(700)
	pl:ResetHull()

	// Here, we determine dynamically Killer's locktime
	// It depends of current progress in round, infected mode & more
	if ((CurTime() - GetGlobalFloat("RoundStartTime", 0)) > 20 and isInfected == 1) then
		unlockTime = 10
	elseif ((CurTime() - GetGlobalFloat("RoundStartTime", 0)) > 20 and isInfected != 1) then
		unlockTime = 5
	else
		unlockTime = 20
	end

	// Timed functions
	timer.Simple(1, function () LockPlayer(pl, unlockTime) end)
	timer.Simple(unlockTime, function () UnlockPlayer(pl) end)
end

// Runned every tick
function CLASS:Tick(pl)
	// Test if the given entity is valid
	if !IsValid(pl) or !pl:Alive() then return end

	// TODO: SWITCH OF PLACE
	// Force model to Killer one
	if (pl.hasKillerEquipped and pl:GetModel() != pl.killerModel) then
		pl:SetModel(pl.killerModel)
		pl:SetupHands()
		hook.Run("Small.SkinsChanged", pl)
	elseif (!pl.hasKillerEquipped and pl:GetModel() != CLASS.PlayerModel) then
		pl:SetModel(CLASS.PlayerModel)
		pl:SetupHands()
		hook.Run("Small.SkinsChanged", pl)
	end

	// Kill system
	if (PB.IsKillerReleased and GetGlobalFloat("RoundEndTime") and pl.KillerCanCatch) then
		// Find all entities in Killer hitbox
		local toKill = ents.FindInBox(pl:GetPos() + Vector(-PB.Config.KillerHitbox, -PB.Config.KillerHitbox, -PB.Config.KillerHitbox), pl:GetPos() + Vector(PB.Config.KillerHitbox, PB.Config.KillerHitbox, PB.Config.KillerHitbox))
		for k, v in pairs(toKill) do
			// Only kill alive Victims and nothing else
			// We use continue statement to avoid having issues
			if (!IsValid(v) or !v:IsPlayer() or pl == v or !v:Alive() or v:Team() != TEAM_VICTIMS or v:HasGodMode()) then continue end

			// Kills Victim & rewards Killer
			v:Kill()
			pl:AddFrags(1)
			pl:GiveMoney(PB.Config.KillerRewardsKill and PB.Config.KillerRewardsKill or 0)

			hook.Run("PB.NewKill", pl, v)
		end
	end
end

// Should we draw local player
function CLASS:ShouldDrawLocalPlayer(pl)
	return false
end

player_class.Register("Killer", CLASS)