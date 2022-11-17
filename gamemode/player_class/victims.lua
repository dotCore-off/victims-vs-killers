// DO NOT TOUCH AS IT WOULD BREAK THE GAMEMODE
PB = PB or {}
PB.Config = PB.Config or {}

local CLASS = {}

CLASS.DisplayName			= "Victims"						// The name that will be displayed for this class
CLASS.WalkSpeed 			= PB.Config.VictimsSpeedWalk	// The walk speed | Default : 250
CLASS.CrouchedWalkSpeed 	= 0.2							// Speed when walking while crouching | Default : 0.2
CLASS.RunSpeed				= PB.Config.VictimsSpeedRun		// The run speed | Default : 290
CLASS.DuckSpeed				= 0.2							// Speed when ducking | Default : 0.2
CLASS.JumpPower				= PB.Config.VictimsJumpPower	// The jump power | Default : 260
CLASS.PlayerModel			= istable(PB.Config.VictimsModel) and table.Random(PB.Config.VictimsModel) or PB.Config.VictimsModel
CLASS.DrawTeamRing			= true
CLASS.DrawViewModel			= true
CLASS.CanUseFlashlight      = true
CLASS.MaxHealth				= PB.Config.VictimsHealthMax 	// Maximum health lol
CLASS.StartHealth			= PB.Config.VictimsHealth
CLASS.StartArmor			= PB.Config.VictimsArmor
CLASS.RespawnTime           = 0
CLASS.DropWeaponOnDie		= false
CLASS.TeammateNoCollide 	= true 							// Can teammates walk through them
CLASS.AvoidPlayers			= false 						// Automatically avoid players that were no colliding
CLASS.Selectable			= false 						// When false, this disables all the team checking
CLASS.FullRotation			= false 						// Allow the players model to rotate upwards, etc etc

// This will be executed for each Victim spawn
function CLASS:OnSpawn(pl)
	// Few initializations
	pl.last_taunt_time = 0
	pl:SetCustomCollisionCheck(true)
	pl:SetCollisionGroup(8)
	pl:SetRenderMode(0)
	pl:UnSpectate()
	pl:SetMaxSpeed(700)
	pl.pastPos = nil
	pl:ResetHull()
end

// Code to execute on death
function CLASS:OnDeath(pl, attacker, dmginfo)
	// EXAMPLE: Change crewmate skin when dying
	if (pl:GetModel() == "models/amongus/player/player.mdl") then
		pl:SetModel("models/amongus/player/corpse.mdl")
	end

	local att = dmginfo:GetAttacker()
	if (IsValid(att) and att:IsPlayer() and att:Team() == TEAM_KILLER) then
		att:GiveMoney(PB.Config.KillerRewardsKill and PB.Config.KillerRewardsKill or 0)
		hook.Run("PB.NewKill", att, pl)
	end
end

// Code executed every tick - this is an example (drown damages)
function CLASS:Tick(pl)
	if (!IsValid(pl) or !pl:Alive()) then return end

	pl.WaterCooldownDmg = pl.WaterCooldownDmg or CurTime()

	if (game.GetMap() == "ttt_rooftops_2016_v1" and pl.WaterCooldownDmg <= CurTime()) then
		local plWaterDeepness = pl:WaterLevel()
		if (plWaterDeepness == 0) then return end

		local d = DamageInfo()
		d:SetDamage(5)
		d:SetDamageType(DMG_DROWN)

		pl:TakeDamageInfo(d)

		pl.WaterCooldownDmg = CurTime() + 1
	end
end

// Do not draw player except if in third person
function CLASS:ShouldDrawLocalPlayer(pl)
	return false
end

// Register the CLASS
player_class.Register("Victims", CLASS)