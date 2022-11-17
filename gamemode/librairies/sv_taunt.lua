// DO NOT TOUCH AS IT WOULD BREAK THE GAMEMODE
PB = PB or {}
PB.Config = PB.Config or {}

// Create a table with all available taunts
local PBTaunts = file.Find(PB.Config.TauntsPath, "GAME")

// Called when player presses [F3]
function GM:ShowSpare1(pl)
	// Test if the given entity is valid
	if !IsValid(pl) then return end

	/*
		NOTIFICATIONS
	*/
	if (pl:Team() != TEAM_VICTIMS) then
		pl:Notify("You must be a Victim to taunt !", 1, 5)
	elseif (pl:Team() == TEAM_VICTIMS and !pl:Alive()) then
		pl:Notify("You must be alive to taunt !", 1, 5)
	elseif (pl:Team() == TEAM_VICTIMS and pl:Alive() and pl.last_taunt_time > CurTime()) then
		pl:Notify("You'll be able to taunt in " .. math.Round(pl.last_taunt_time - CurTime()) .. " seconds !", 1, 5)
	end


	/*
		Verifications : 
			- Round is ongoing
			- Player is a Victim
			- Player is alive
			- No taunt cooldown
	*/
	if (GAMEMODE:InRound() and pl:Alive() and pl:Team() == TEAM_VICTIMS and pl.last_taunt_time <= CurTime()) then
		PlayTaunt(pl)
	end
end

//  Play a taunt function
// We externalized it to allow different calls
function PlayTaunt(pl)
	// Test if the given entity is valid
	if !IsValid(pl) then return end

	// Pick a random taunt in the created table above
	local rnd = table.Random(PBTaunts)
	local pickedTaunt = PB.Config.TauntsShortPath .. rnd

	// Emit with the player as the origin of it
	net.Start("PB.Taunts")
		net.WriteString(pickedTaunt)
		net.WriteEntity(pl)
	net.Broadcast()

	// Length stuff
	// This will require a file to override default gmod sound duration function
	// Since it's inaccurate / doesn't work on Linux based systems and will return weird lengths
	local length = NewSoundDuration and NewSoundDuration("sound/pedo/taunts/" .. rnd) or 30

	// Reward player
	if (PB.Config.TauntsRewardsEnabled) then
		pl:GiveMoney(PB.Config.TauntsRewardsLength and math.Round(length) or PB.Config.TauntsRewardsLength)
	end

	// Hook - Used for challenges
	// PLAYER / DURATION / TAUNT FILE
	hook.Run("PB.Taunted", pl, math.Round(length), rnd)

	// Setup cooldown
	pl.last_taunt_time = CurTime() + (length >= 100 and 30 or length)
end