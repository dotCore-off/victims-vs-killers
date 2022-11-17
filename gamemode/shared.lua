// DO NOT TOUCH AS IT WOULD BREAK THE GAMEMODE
PB = PB or {}
PB.Config = PB.Config or {}

GM.Name 	= "Pedobear"
GM.Author 	= "dotCore"
GM.Email 	= ""
GM.Website 	= ""
GM.Help		= ""

GM.Data = {}

DeriveGamemode("fretta13")
IncludePlayerClasses()							// Automatically includes files in "gamemode/player_class"

GM.TeamBased = true								// Team based game or a Free For All game?
GM.AllowAutoTeam = true
GM.AllowSpectating = true
GM.SecondsBetweenTeamSwitches = 0
GM.GameLength = PB.Config.MaxLength	or 30		// How long last the entire game
GM.RoundLimit = PB.Config.MaxRounds or 10		// Maximum amount of rounds to be played in round based games
GM.VotingDelay = 5								// Delay between end of game, and vote. if you want to display any extra screens before the vote pops up

GM.NoPlayerSuicide = true
GM.NoPlayerDamage = false
GM.NoPlayerSelfDamage = false					// Allow players to hurt themselves?
GM.NoPlayerTeamDamage = true					// Allow team-members to hurt each other?
GM.NoPlayerPlayerDamage = false 				// Allow players to hurt each other?
GM.NoNonPlayerPlayerDamage = false 				// Allow damage from non players (physics, fire etc)
GM.NoPlayerFootsteps = false					// When true, all players have silent footsteps
GM.PlayerCanNoClip = false						// When true, players can use noclip without sv_cheats
GM.TakeFragOnSuicide = false					// -1 frag on suicide

GM.MaximumDeathLength = 0						// Player will respawn if death length > this (can be 0 to disable)
GM.MinimumDeathLength = 0						// Player has to be dead for at least this long
GM.AutomaticTeamBalance = false     			// Teams will be periodically balanced 
GM.ForceJoinBalancedTeams = false				// Players wont be allowed to join a team if it has more players than another team
GM.RealisticFallDamage = false

GM.NoAutomaticSpawning = true					// Players don spawn automatically when they die, some other system spawns them
GM.RoundBased = true							// Round based, like CS
GM.RoundLength = PB.Config.MaxRoundLength		// Round length, in seconds
GM.RoundPreStartTime = 0						// Preperation time before a round starts
GM.RoundPostLength = 5							// How long last the end of a round (in seconds)
GM.RoundEndsWhenOneTeamAlive = true				// CS Style rules

GM.EnableFreezeCam = false						// TF2 Style Freezecam
GM.DeathLingerTime = 5							// How long to show the freeze cam (in seconds)

GM.SelectModel = false              			// Can players use the playermodel picker in the F1 menu?
GM.SelectColor = false							// Can players modify the colour of their name? (ie.. no teams)

GM.PlayerRingSize = 0              				// How big are the colored rings under the players feet (if they are enabled) ?
GM.HudSkin = "SimpleSkin"

GM.ValidSpectatorModes = { OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING }
GM.ValidSpectatorEntities = { "player" }		// Entities we can spectate
GM.CanOnlySpectateOwnTeam = true				// Can players only spectate members of their own team ?


// Teams
TEAM_VICTIMS = 1
TEAM_KILLER = 2

TEAM_SPEC = TEAM_SPECTATOR // Shortening TEAM_SPECTATOR to TEAM_SPEC (you also can use full TEAM_SPECTATOR, if you want)


function GM:CreateTeams()
	// Setup name + Color
	team.SetUp(1, "Victims", Color(52, 152, 219), true)
	// Setup class
	team.SetClass(1, { "Victims" })
	// Setup spawnpoints
	team.SetSpawnPoint(1, { "info_player_deathmatch", "info_player_combine", "info_player_rebel", "info_player_counterterrorist", "info_player_terrorist", "info_player_axis", "info_player_allies", "gmod_player_start", "info_player_teamspawn", "info_player_human", "info_player_redeemed", "aoc_spawnpoint", "diprip_start_team_blue", "info_player_blue", "dys_spawn_point", "info_player_coop", "info_player_human", "info_player_knight", "info_player_pirate", "info_player_viking", "info_spawnpoint", "ins_spawnpoint" })

	team.SetUp(2, "Killer", Color(231, 76, 60), false )
	team.SetClass(2, { "Killer" })
	team.SetSpawnPoint(2, { "info_player_deathmatch", "info_player_combine", "info_player_rebel", "info_player_counterterrorist", "info_player_terrorist", "info_player_axis", "info_player_allies", "gmod_player_start", "info_player_teamspawn", "info_player_human", "info_player_redeemed", "aoc_spawnpoint", "diprip_start_team_blue", "info_player_blue", "dys_spawn_point", "info_player_coop", "info_player_human", "info_player_knight", "info_player_pirate", "info_player_viking", "info_spawnpoint", "ins_spawnpoint" })

	team.SetUp(TEAM_SPEC, "Spectators", Color( 200, 200, 200 ), true)
end