// DO NOT TOUCH AS IT WOULD BREAK THE GAMEMODE
PB = PB or {}
PB.Config = PB.Config or {}

/*
    GAMEMODE CONFIG
*/

// List of played maps to add it to FastDL upon player connection
// ["WORKSHOPID"] = "mapname",
PB.Config.AvailableMaps = {
    ["1389067371"] = "gm_lasertag_arena",
    ["467212563"] = "gm_parallax",
    ["1266205606"] = "gm_bricolage",
    ["238575181"] = "ttt_kakariko_v4a",
    ["212055526"] = "ttt_minecraftcity_v3",
    ["211806547"] = "ttt_titanic",
    ["131667838"] = "ttt_community_bowling_v5a",
    ["137891506"] = "ttt_plaza_b7",
    ["1616801468"] = "ttt_aztec_shrine",
    ["1733063788"] = "ttt_pwp_v4",
    ["1388481216"] = "ttt_poolparty",
    ["1829884863"] = "ttt_alstoybarn",
    ["844793292"] = "ttt_minecraft_snowden",
    ["2307987701"] = "ttt_upstate",
    ["1504381346"] = "ttt_bestbuy",
    ["1299035924"] = "ttt_oldruins",
    ["834151426"] = "zs_terminal",
    ["2161204077"] = "pedo_hollywood_v6",
    ["320963369"] = "ttt_college",
    ["867635838"] = "ttt_grovestreet_a13",
    ["1774005060"] = "pvb_lunar_b3a",
    ["1219185412"] = "ttt_pelicantown",
    ["1506830124"] = "mu_springbreak",
    ["320213706"] = "zs_snowy_castle",
    ["1348699712"] = "zm_neko_athletic_park_v2",
    ["163322799"] = "ttt_parkhouse",
    ["645191518"] = "zs_krusty_krab_large_v5",
    ["534491717"] = "ttt_rooftops_2016",
    ["268821209"] = "ttt_swimming_pool",
    ["1981014120"] = "gm_rayman2_fairyglade_a6",
    ["1109772674"] = "gm_defocus",
    ["856415402"] = "gm_triphouse",
    ["183797802"] = "ttt_island_2013",
    ["1394984542"] = "ttt_thematrix"
}

// List of maps considered as "big" (more killers, etc..)
PB.Config.BigMaps = {
    ["gm_bricolage"] = true,
    ["gm_dissonance"] = true,
    ["ttt_parkhouse"] = true,
    ["ttt_plaza_b7"] = true,
    ["ttt_titanic"] = true,
    ["zs_terminal"] = true,
    ["ttt_terrortown"] = true
}

// Function to run when we reach end of the map / round limit
PB.Config.EndMapFunction = function()

end

// List of entity classes to remove on new round
PB.Config.ForbiddenEntities = {
    "weapon_*",
    "ttt_*",
    "item_*",
    "func_buyzone",
    "func_bomb_target",
    "game_text",
    "env_beam"
}

// List of groups considered as VIP
PB.Config.GroupSponsor = {
    "owner",
    "superadmin",
    "admin",
    "head_staff",
    "sponsor_staff",
    "sponsor_tstaff",
    "sponsor_veteran",
    "sponsor_user"
}

// List of groups considered as staff
PB.Config.GroupStaff = {
    "owner",
    "superadmin",
    "admin",
    "head_staff",
    "sponsor_staff",
    "staff",
    "sponsor_tstaff",
    "tstaff"
}

// Functions that run on a beginning of a new round on specific maps
PB.Config.MapsModification = {
    ["ttt_oldruins"] = {
        runFunc = function()
            // Localize function as we'll use it often lol
            local function KillPlayer(ent, data)
                local ply = data["HitEntity"]
                if !IsValid(ply) then return end

                if ply:IsPlayer() and ply:Alive() then
                    ply:Kill()
                    ply:Notify("[AFS] This spot is forbidden, don't go there !", 1, 8)
                end
            end

            // Create an invisible death "floor"
            local smallMountain = ents.Create("prop_physics")
            if (!IsValid(smallMountain)) then return end
            smallMountain:SetNoDraw(true)
            smallMountain:SetModel("models/hunter/plates/plate8x8.mdl")
            smallMountain:SetPos(Vector(-307.981781, -1959.435791, -1115.958008))
            smallMountain:SetAngles(Angle(0, 0, 0))
            smallMountain:SetRenderMode(RENDERMODE_NONE)
            smallMountain:Spawn()
            smallMountain:GetPhysicsObject()
            local phys = smallMountain:GetPhysicsObject()
            if (IsValid(phys)) then
                phys:EnableMotion(false)
            end
            smallMountain:AddCallback("PhysicsCollide", KillPlayer)

            // Create an invisible death "floor"
            local anotherMountain = ents.Create("prop_physics")
            if (!IsValid(anotherMountain)) then return end
            anotherMountain:SetNoDraw(true)
            anotherMountain:SetModel("models/hunter/plates/plate8x8.mdl")
            anotherMountain:SetPos(Vector(2074.367188, -1340.756958, -853.288330))
            anotherMountain:SetAngles(Angle(0, 0, 0))
            anotherMountain:SetRenderMode(RENDERMODE_NONE)
            anotherMountain:Spawn()
            anotherMountain:GetPhysicsObject()
            local phys2 = anotherMountain:GetPhysicsObject()
            if (IsValid(phys2)) then
                phys2:EnableMotion(false)
            end
            anotherMountain:AddCallback("PhysicsCollide", KillPlayer)

            // Create an invisible death "floor"
            local bridgeMountain = ents.Create("prop_physics")
            if (!IsValid(bridgeMountain)) then return end
            bridgeMountain:SetNoDraw(true)
            bridgeMountain:SetModel("models/hunter/plates/plate8x8.mdl")
            bridgeMountain:SetPos(Vector(-907.920593, -1300.765869, -1170.658813))
            bridgeMountain:SetAngles(Angle(0, 0, 0))
            bridgeMountain:SetRenderMode(RENDERMODE_NONE)
            bridgeMountain:Spawn()
            bridgeMountain:GetPhysicsObject()
            local phys3 = bridgeMountain:GetPhysicsObject()
            if (IsValid(phys3)) then
                phys3:EnableMotion(false)
            end
            bridgeMountain:AddCallback("PhysicsCollide", KillPlayer)

            // Create an invisible death "floor"
            local bridgeMountain2 = ents.Create("prop_physics")
            if (!IsValid(bridgeMountain2)) then return end
            bridgeMountain2:SetNoDraw(true)
            bridgeMountain2:SetModel("models/hunter/plates/plate8x8.mdl")
            bridgeMountain2:SetPos(Vector(-868.909912, -500.976501, -1030.017029))
            bridgeMountain2:SetAngles(Angle(0, 0, 0))
            bridgeMountain2:SetRenderMode(RENDERMODE_NONE)
            bridgeMountain2:Spawn()
            bridgeMountain2:GetPhysicsObject()
            local phys4 = bridgeMountain2:GetPhysicsObject()
            if (IsValid(phys4)) then
                phys4:EnableMotion(false)
            end
            bridgeMountain2:AddCallback("PhysicsCollide", KillPlayer)

            // Create an invisible floor to extend bridge
            local bridgeExt = ents.Create("prop_physics")
            if (!IsValid(bridgeExt)) then return end
            bridgeExt:SetNoDraw(true)
            bridgeExt:SetModel("models/hunter/plates/plate8x8.mdl")
            bridgeExt:SetPos(Vector(-1521.869385, -833.986938, -1113.529785))
            bridgeExt:SetAngles(Angle(0, 0, 0))
            bridgeExt:SetRenderMode(RENDERMODE_NONE)
            bridgeExt:Spawn()
            bridgeExt:GetPhysicsObject()
            local phys5 = bridgeExt:GetPhysicsObject()
            if (IsValid(phys5)) then
                phys5:EnableMotion(false)
            end
            bridgeExt:AddCallback("PhysicsCollide", KillPlayer)
        end
    },
    ["ttt_minecraft_snowden"] = {
        runFunc = function()
            // Create an invisible wall
            local cube = ents.Create("prop_physics")
            if (!IsValid(cube)) then return end
            cube:SetNoDraw(true)
            cube:SetModel("models/hunter/plates/plate2x2.mdl")
            cube:SetPos(Vector(2701.504150, 2272.550781, 497.057739))
            cube:SetAngles(Angle(90, 90, 0))
            cube:SetRenderMode(RENDERMODE_NONE)
            cube:Spawn()
            cube:GetPhysicsObject()
            local phys = cube:GetPhysicsObject()
            if (IsValid(phys)) then
                phys:EnableMotion(false)
            end
        end
    },
    ["ttt_bestbuy"] = {
        runFunc = function()
            // Create an invisible floor 
            local dumpster = ents.Create("prop_physics")
            if (!IsValid(dumpster)) then return end
            dumpster:SetNoDraw(true)
            dumpster:SetModel("models/hunter/plates/plate3x3.mdl")
            dumpster:SetPos(Vector(2030.764160, 340.619537, 120.646133))
            dumpster:SetAngles(Angle(0, 0, 0))
            dumpster:SetRenderMode(RENDERMODE_NONE)
            dumpster:Spawn()
            dumpster:GetPhysicsObject()
            local phys = dumpster:GetPhysicsObject()
            if (IsValid(phys)) then
                phys:EnableMotion(false)
            end
        end
    },
    ["zs_krusty_krab_large_v5"] = {
        runFunc = function()
            local planks = ents.GetMapCreatedEntity(1704)
            if (!IsValid(planks)) then return end
            planks:Remove()
        end
    },
    ["de_deathcookin"] = {
        runFunc = function()
            local barrier = ents.GetMapCreatedEntity(1300)
            if (!IsValid(barrier)) then return end
            barrier:Remove()
        end
    },
    ["zm_neko_athletic_park_v2"] = {
        runFunc = function()
            local floorDoor1 = ents.GetMapCreatedEntity(1733)
            local floorDoor2 = ents.GetMapCreatedEntity(1734)
            if (!IsValid(floorDoor1) and !IsValid(floorDoor2)) then return end
            floorDoor1:Remove()
            floorDoor2:Remove()
        end
    },
}

// How long should last a map? (in minutes)
PB.Config.MaxLength = 30

// How much rounds should we play?
PB.Config.MaxRounds = 10

// How much should last a round? (in seconds)
PB.Config.MaxRoundLength = 300

// Should we enable gamemode notifications?
PB.Config.NotificationEnabled = true

// Should we grant rewards on various gamemode events? - false to disable
PB.Config.RewardsCurrency = "coins"

// Currency functions
PB.Config.RewardsCurrencies = {
    ["pointshop"] = {
        // Test
    },
    ["coins"] = {
        addFunction = function(ply, amount)
            ply:AddCoins(amount)
        end,
        getFunction = function(ply)
            ply:GetCurrency(1)
        end
    },
}

// What should be the rewards multiplier for sponsors?
PB.Config.RewardsMultiplier = 2

// Content to mount if a specific player joins
// eg: reserved skin / item
PB.Config.SpecialContent = {
    // Perm
    ["656834283"] = "76561197985998497",
    ["1591574368"] = "76561198294325410",
    ["269895154"] = "76561198807431155",
    ["437652050"] = "76561198190105523",
    ["2870862125"] = "76561198121655385",
    ["2843463371"] = "76561198121655385",
    ["1761527522"] = "76561198121655385",
    ["675349732"] = "76561199122127032",
    ["2497983661"] = "76561199122127032",
    ["2464984437"] = "76561198150715506",
    ["656834283"] = "76561197985998497",
    ["1575356459"] = "76561198055226585",
    ["1557958941"] = "76561198856553497",
    ["269895154"] = "76561198807431155",
    ["1843708002"] = "76561198042931043",
    ["1510010810"] = "76561198877269660",
    ["1304710505"] = "76561198856553497",
}

/*
    GAMEPLAY CONFIG
*/

// Should we prevent Bunny Hop?
PB.Config.BhopProtection = true

// What should be the max speed before player get stopped?
PB.Config.BhopSpeed = 700

// Should we draw halos around Killers?
// NOTE: use this https://github.com/Facepunch/garrysmod/pull/1590/files for better performance
PB.Config.HalosEnabled = true

// What should be the color of drawn halos?
PB.Config.HalosColor = Color(255, 0, 0)

// Should we prevent collisions between players of the same team?
PB.Config.PreventCollisions = true

// Should we prevent flashlight spam?
PB.Config.PreventFlashlightSpam = true

// Should we prevent suspicious account from connecting?
PB.Config.ProtectionEnabledAlts = true

// Should we prevent VPNs from connecting?
PB.Config.ProtectionEnabledVpn = false

// What should be the sanction to give? - 1 = kick / 2 = ban
PB.Config.ProtectSanctionType = 1

// What should be the ban duration? - configure if above is set to 2
PB.Config.ProtectSanctionLength = 0

// List of people to ignore through protection - SID64 / SID
PB.Config.ProtectionWhitelist = {
    "",
}

// Should we enable Sliding mechanic?
PB.Config.SlidingEnabled = false

// Commands to disable taunts
PB.Config.TauntsCommands = {
    "!taunt",
    "!disabletaunt",
}

// Should we enable Taunts mechanic?
PB.Config.TauntsEnabled = true

// Path to all taunt files
PB.Config.TauntsPath = "sound/pb/taunts/*.mp3"

// Remove sound/ & trailing dir at the end
PB.Config.TauntsShortPath = "pb/taunts/"

// Should we enable rewards for taunts?
PB.Config.TauntsRewardsEnabled = true

// Should rewards be based on length of the played taunt? - 30 sec = 30 points
// true to base on length or a static number
// YOU MUST USE THIS TO HAVE AN ACCURATE LENGTH: https://github.com/yobson1/glua-soundduration
PB.Config.TauntsRewardsLength = true


/*
    KILLERS CONFIG
*/

// Default armor when spawning - default: 0
PB.Config.KillerArmor = 0

// Default health and max reachable one - default: 100
PB.Config.KillerHealth = 100
PB.Config.KillerHealthMax = 100

// Hitbox of the killer - default: 32 (hammer unit)
PB.Config.KillerHitbox = 32

// What should be the jump power? - default: 260
PB.Config.KillerJumpPower = 260

// What should be the default skin of Killers? - can be a table of models
PB.Config.KillerModel = "models/player/pbear/pbear.mdl"

// How much should a Killer earn per kill? - false to disable
PB.Config.KillerRewardsKill = 5

// How much players should be online to give Killer win rewards? - prevents offline grind
PB.Config.KillerRewardsPlayers = 4

// How much should a Killer earn per round win? - false to disable
PB.Config.KillerRewardsWin = 100

// What should be the normal speed? - default: 250
PB.Config.KillerSpeedWalk = 250

// What should be the run speed? - default: 305
PB.Config.KillerSpeedRun = 305

// Amount of Victims per Killer - default: 10
PB.Config.KillerTier = 10

// Delay before a Killer is unlocked? - default: 18
PB.Config.KillerUnlockTime = 18


/*
    VICTIMS CONFIG
*/

// Default armor when spawning - default: 0
PB.Config.VictimsArmor = 0

// Default health and max reachable one - default: 100
PB.Config.VictimsHealth = 100
PB.Config.VictimsHealthMax = 100

// What should be the jump power? - default: 260
PB.Config.VictimsJumpPower = 260

// What should be the default skin of Victims? - can be a table of models
PB.Config.VictimsModel = "models/player/meeseeks/meeseeks.mdl"

// How much players should be online to give Victims win rewards? - prevents offline grind
PB.Config.VictimsRewardsPlayers = 4

// How much should a Victim earn per round win? - false to disable
PB.Config.VictimsRewardsWin = 10

// What should be the normal speed? - default: 250
PB.Config.VictimsSpeedWalk = 250

// What should be the run speed? - default: 290
PB.Config.VictimsSpeedRun = 290


/*
    EVENTS CONFIG
*/

// Should we enable Special rounds?
PB.Config.SpecialRoundsEnabled = true

// List of existing special rounds
PB.Config.SpecialRounds = {
    /* EXAMPLE
    [uniquenumber] = {
        RoundMaterial = "path.png",             // Used by UI - Round logo
        RoundName = "Cool round",               // Round name
        RoundDescription = "So cool!!",         // Used by UI - Round description
        RoundColor = Color(255, 0, 0),        // Used by UI - Round color
        RoundNotif = "Good luck!",              // Sent at the beginning of round
        RoundSound = "path.mp3",                // Sound to play at the beginning
        Rarity = 0.6,                           // Occurence odd - 0.6 = 40% of being picked
        WIP
    }
    */
    [1] = {
        RoundMaterial = "logo/zombie.png",
        RoundName = "Infected",
        RoundDescription = "Victims become Killers when killed",
        RoundColor = Color(50, 200, 50),
        RoundNotif = "This is an infected round, good luck !",
        RoundSound = "pb/infected_round.mp3",
        Rarity = 0.8,
        RewardVictimMultiplier = 1.5,
        RewardKillerMultiplier = 0.5,
        HookOverrides = function()
            hook.Add("PB.NewKill", "PB.InfectedNewKill", function(pl, vic)
                if (!IsValid(vic)) then return end

                if (vic:IsOnGround()) then
                    vic.pastPos = vic:GetPos()
                end

                vic:SetTeam(TEAM_KILLER)
                vic:Spawn()
                vic:Notify("You got infected !", 1, 5)
            end)

            hook.Add("PlayerSpawn", "PB.InfectedSpawn", function(ply)
                if (!IsValid(ply) or ply:Team() != TEAM_KILLER) then return end

                local tbl = {
                    "pb/zombie_1.mp3",
                    "pb/zombie_2.mp3",
                    "pb/zombie_3.mp3",
                    "pb/zombie_4.mp3",
                    "pb/zombie_5.mp3"
                }
                ply:EmitSound(tbl[math.random(1, #tbl)], 300, 100, 0.3)

                if (ply.pastPos) then
                    ply:SetPos(ply.pastPos)
                    ply.pastPos = nil
                end
            end)

            hook.Add("OnRoundEnd", "PB.InfectedHandler", function()
                hook.Remove("PlayerSpawn", "PB.InfectedSpawn")
                hook.Remove("PB.NewKill", "PB.InfectedNewKill")
            end)
        end,
    },
    [2] = {
        //test
    },
}