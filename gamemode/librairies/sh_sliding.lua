/*
    Sliding system
*/

/*
    Register sounds that will be used later on
                Impact | Sliding
*/
sound.Add {
    name = "SlidingAbility.ImpactSoft",
    channel = CHAN_BODY,
    level = 75,
    volume = 0.25,
    sound = {
        "physics/body/body_medium_impact_soft1.wav",
        "physics/body/body_medium_impact_soft2.wav",
        "physics/body/body_medium_impact_soft5.wav",
        "physics/body/body_medium_impact_soft6.wav",
        "physics/body/body_medium_impact_soft7.wav",
    },
}

sound.Add {
    name = "SlidingAbility.ScrapeRough",
    channel = CHAN_STATIC,
    level = 70,
    volume = 0.05,
    sound = "physics/body/body_medium_scrape_rough_loop1.wav",
}

/*
    Define all possible acts
*/
local ACT_HL2MP_SIT_CAMERA = "sit_camera"
local ACT_HL2MP_SIT_DUEL = "sit_duel"
local ACT_HL2MP_SIT_PASSIVE = "sit_passive"
local acts = {
    revolver = ACT_HL2MP_SIT_PISTOL,
    pistol = ACT_HL2MP_SIT_PISTOL,
    shotgun = ACT_HL2MP_SIT_SHOTGUN,
    smg = ACT_HL2MP_SIT_SMG1,
    ar2 = ACT_HL2MP_SIT_AR2,
    physgun = ACT_HL2MP_SIT_PHYSGUN,
    grenade = ACT_HL2MP_SIT_GRENADE,
    rpg = ACT_HL2MP_SIT_RPG,
    crossbow = ACT_HL2MP_SIT_CROSSBOW,
    melee = ACT_HL2MP_SIT_MELEE,
    melee2 = ACT_HL2MP_SIT_MELEE2,
    slam = ACT_HL2MP_SIT_SLAM,
    fist = ACT_HL2MP_SIT_FIST,
    normal = ACT_HL2MP_SIT_DUEL,
    camera = ACT_HL2MP_SIT_CAMERA,
    duel = ACT_HL2MP_SIT_DUEL,
    passive = ACT_HL2MP_SIT_PASSIVE,
    magic = ACT_HL2MP_SIT_DUEL,
    knife = ACT_HL2MP_SIT_KNIFE,
}

/*
    Function used to determine if we should manipulate bone angles or not
*/
local function AngleEqualTol(a1, a2, tol)
    tol = tol or 1e-3
    if not (isangle(a1) and isangle(a2)) then return false end
    if math.abs(a1.pitch - a2.pitch) > tol then return false end
    if math.abs(a1.yaw - a2.yaw) > tol then return false end
    if math.abs(a1.roll - a2.roll) > tol then return false end
    return true
end

/*
    Determine current act the model is playing
      Most likely PASSIVE or DUEL for us lol
*/
local function GetSlidingActivity(ply)
    local w, a = ply:GetActiveWeapon(), ACT_HL2MP_SIT_DUEL
    if IsValid(w) then a = acts[string.lower(w:GetHoldType())] or acts[string.lower(w.HoldType or "")] or ACT_HL2MP_SIT_DUEL end
    if isstring(a) then return ply:GetSequenceActivity(ply:LookupSequence(a)) end
    return a
end

/*
    Manipulate bone angles with cache
*/
local BoneAngleCache = SERVER and {} or nil
local function ManipulateBoneAnglesLessTraffic(ent, bone, ang, frac)
    local a = SERVER and ang or ang * frac
    if CLIENT or not (BoneAngleCache[ent] and AngleEqualTol(BoneAngleCache[ent][bone], a, 1)) then
        ent:ManipulateBoneAngles(bone, a)
        if CLIENT then return end
        if not BoneAngleCache[ent] then BoneAngleCache[ent] = {} end
        BoneAngleCache[ent][bone] = a
    end
end

/*
    Determine bone position for our sliding animation
*/
local function ManipulateBones(ply, ent, base, thigh, calf)
    if not IsValid(ent) then return end
    local bthigh = ent:LookupBone "ValveBiped.Bip01_R_Thigh"
    local bcalf = ent:LookupBone "ValveBiped.Bip01_R_Calf"
    local t0 = ply:GetNWFloat "SlidingAbility_SlidingStartTime"
    local timefrac = math.TimeFraction(t0, t0 + 0.2, CurTime())
    timefrac = SERVER and 1 or math.Clamp(timefrac, 0, 1)
    if bthigh or bcalf then ManipulateBoneAnglesLessTraffic(ent, 0, base, timefrac) end
    if bthigh then ManipulateBoneAnglesLessTraffic(ent, bthigh, thigh, timefrac) end
    if bcalf then ManipulateBoneAnglesLessTraffic(ent, bcalf, calf, timefrac) end
    local dp = thigh:IsZero() and Vector() or Vector(12, 0, -18)
    for _, ec in pairs {EnhancedCamera, EnhancedCameraTwo} do
        if ent == ec.entity then
            local w = ply:GetActiveWeapon()
            local seqname = LocalPlayer():GetSequenceName(ec:GetSequence())
            local pose = IsValid(w) and string.lower(w.HoldType or "") or ""
            if pose == "" then pose = seqname:sub((seqname:find "_" or 0) + 1) end
            if pose:find "all" then pose = "normal" end
            if pose == "smg1" then pose = "smg" end
            if pose and pose ~= "" and pose ~= ec.pose then
                ec.pose = pose
                ec:OnPoseChange()
            end

            ent:ManipulateBonePosition(0, dp * timefrac)
        end
    end
end

/*
    Reset animation here + stop sound
*/
local function EndSliding(ply)
    if SERVER then ManipulateBones(ply, ply, Angle(), Angle(), Angle()) end
    ply.SlidingAbility_IsSliding = false
    ply.SlidingAbility_SlidingStartTime = CurTime()
    ply:SetNWBool("SlidingAbility_IsSliding", false)
    ply:SetNWFloat("SlidingAbility_SlidingStartTime", CurTime())
    if SERVER then ply:StopSound "SlidingAbility.ScrapeRough" end
end

/*
    Set the bones accordingly to the data we receive
*/
local function SetSlidingPose(ply, ent, body_tilt)
    ManipulateBones(ply, ent, -Angle(0, 0, body_tilt), Angle(20, 35, 85), Angle(0, 45, 0))
end

/*
    Backtrack datas by WholeCream
*/
local SlidingBacktrack = {}
local PredictedVars = {
    ["SlidingAbility_SlidingCurrentVelocity"] = Vector(),
}

local function GetPredictedVar(ply, name)
    return SERVER and ply[name] or PredictedVars[name]
end

local function SetPredictedVar(ply, name, value)
    if CLIENT then
        PredictedVars[name] = value
    else
        ply[name] = value
    end
end

/*
    One of the main func
*/
hook.Add("SetupMove", "Check sliding", function(ply, mv, cmd)
    // Set velocity based on current speed
    if ply:GetNWFloat "SlidingPreserveWalkSpeed" > 0 then
        local v = GetPredictedVar(ply, "SlidingAbility_SlidingCurrentVelocity") or Vector()
        v.z = mv:GetVelocity().z
        mv:SetVelocity(v)
    end

    // Create & cache the current position as previous one if it doesn't exist
    if not ply.SlidingAbility_SlidingPreviousPosition then
        ply.SlidingAbility_SlidingPreviousPosition = Vector()
        ply.SlidingAbility_SlidingStartTime = 0
        ply.SlidingAbility_IsSliding = false
    end

    ply:SetNWFloat("SlidingPreserveWalkSpeed", -1)

    // End the sliding animation if player doesn't keep crouching
    if IsFirstTimePredicted() and not ply:Crouching() and ply.SlidingAbility_IsSliding then
        EndSliding(ply)
    end

    // Actual calculation of movement
    local CT = CurTime()
    if (ply:Crouching() and ply.SlidingAbility_IsSliding) or (CLIENT and SlidingBacktrack[CT]) then
        local restorevars = {}
        local vpbacktrack
        if CLIENT and not ply:KeyDown(IN_JUMP) then
            if SlidingBacktrack[CT] then
                local data = SlidingBacktrack[CT]
                for k, v in pairs(PredictedVars) do
                    restorevars[k] = v
                    PredictedVars[k] = data[k]
                end
                vpbacktrack = true
            elseif not IsFirstTimePredicted() then
                return
            end
        end

        // Calculate movement
        local v = GetPredictedVar(ply, "SlidingAbility_SlidingCurrentVelocity") or Vector()
        local speed = v:Length()
        local speedref_crouch = ply:GetWalkSpeed() * ply:GetCrouchedWalkSpeed()
        if not vpbacktrack then
            local vdir = v:GetNormalized()
            local forward = mv:GetMoveAngles():Forward()
            local speedref_slide = ply.SlidingAbility_SlidingMaxSpeed
            local speedref_min = math.min(speedref_crouch, speedref_slide)
            local speedref_max = math.max(speedref_crouch, speedref_slide)
            local dp = mv:GetOrigin() - ply.SlidingAbility_SlidingPreviousPosition
            local dp2d = Vector(dp.x, dp.y)
            dp:Normalize()
            dp2d:Normalize()
            local dot = forward:Dot(dp2d)
            local speedref = Lerp(math.max(-dp.z, 0), speedref_min, speedref_max)
            local accel = 5 * engine.TickInterval()
            if speed > speedref then accel = -accel end
            v = LerpVector(0.005, vdir, forward) * (speed + accel)

            SetSlidingPose(ply, ply, math.deg(math.asin(dp.z)) * dot + 42)
            SetPredictedVar(ply, "SlidingAbility_SlidingCurrentVelocity", v)
            ply.SlidingAbility_SlidingCurrentVelocity = v
            ply.SlidingAbility_SlidingPreviousPosition = mv:GetOrigin()
        end

        // Set push velocity
        mv:SetVelocity(GetPredictedVar(ply, "SlidingAbility_SlidingCurrentVelocity"))

        // Effects & ending
        if not vpbacktrack then
            if not ply:OnGround() or mv:KeyPressed(IN_JUMP) or mv:KeyReleased(IN_DUCK) or math.abs(speed - speedref_crouch) < 10 then
                EndSliding(ply)
                if mv:KeyPressed(IN_JUMP) then
                    local t = CurTime() + 0.3
                    ply.SlidingAbility_SlidingStartTime = t
                    ply:SetNWFloat("SlidingAbility_SlidingStartTime", t)
                    ply:SetNWFloat("SlidingPreserveWalkSpeed", ply:GetWalkSpeed())
                    // Cut speed if jumping while sliding
                    local v = ply:GetVelocity()
                    v.x = ply:GetWalkSpeed()
                    v.y = ply:GetWalkSpeed()
                    v.z = ply:GetWalkSpeed()
                    ply:SetVelocity(v)
                end
            end

            local e = EffectData()
            e:SetOrigin(mv:GetOrigin())
            e:SetScale(1.6)
            util.Effect("WheelDust", e)
        end

        // Restore backtrack or record data
        if CLIENT then
            if vpbacktrack then
                for k, v in pairs(restorevars) do
                    PredictedVars[k] = v
                end
                vpbacktrack = nil
            elseif not SlidingBacktrack[CT] then
                if SERVER then
                    SlidingBacktrack[CT] = {}
                    for k, v in pairs(PredictedVars) do
                        SlidingBacktrack[CT][k] = v
                    end
                    local keys = table.GetKeys(SlidingBacktrack)
                    table.sort(keys, function(a, b) return a > b end)
                    for i = 1, #keys do
                        local v = keys[i]
                        if i > 2 then SlidingBacktrack[v] = nil end
                    end
                else
                    SlidingBacktrack[CT] = {}
                    for k, v in pairs(PredictedVars) do
                        SlidingBacktrack[CT][k] = v
                    end
                    local tickint = engine.TickInterval()
                    local ping = LocalPlayer():Ping() / 1000
                    for k, v in pairs(SlidingBacktrack) do
                        if CT - (ping + tickint * 2) > k then
                            SlidingBacktrack[k] = nil
                        end
                    end
                end
            end
        end

        return
    end

    /*
        Initial checks to see if we can do it
    */
    if ply.SlidingAbility_IsSliding then return end
    if not ply:OnGround() then return end
    if not ply:Crouching() then return end
    if not IsFirstTimePredicted() then return end
    if not mv:KeyDown(IN_DUCK) then return end
    if not mv:KeyDown(IN_SPEED) then return end // This disables sliding for some people for some reason -> TO MONITOR
    if not mv:KeyDown(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)) then return end
    if CurTime() < ply.SlidingAbility_SlidingStartTime + 0.6 then return end
    if math.abs(ply:GetWalkSpeed() - ply:GetRunSpeed()) < 25 then return end

    local v = mv:GetVelocity()
    local speed = v:Length()
    local run = ply:GetRunSpeed()
    local crouched = ply:GetWalkSpeed() * ply:GetCrouchedWalkSpeed()
    local threshold = (run + crouched) / 2
    if run > crouched and speed < threshold then return end
    if run < crouched and (speed < run - 1 or speed > threshold) then return end
    local runspeed = math.max(ply:GetVelocity():Length(), speed, run)
    local dir = v:GetNormalized()
    local ping = SERVER and 0 or (ply == LocalPlayer() and ply:Ping() / 1000 or 0)
    ply.SlidingAbility_IsSliding = true
    ply.SlidingAbility_SlidingStartTime = CurTime() - ping
    ply.SlidingAbility_SlidingCurrentVelocity = dir * runspeed
    ply.SlidingAbility_SlidingMaxSpeed = runspeed * 1.2
    ply:SetNWBool("SlidingAbility_IsSliding", true)
    ply:SetNWFloat("SlidingAbility_SlidingStartTime", ply.SlidingAbility_SlidingStartTime)
    ply:SetNWVector("SlidingAbility_SlidingMaxSpeed", ply.SlidingAbility_SlidingMaxSpeed)
    SetPredictedVar(ply, "SlidingAbility_SlidingCurrentVelocity", ply.SlidingAbility_SlidingCurrentVelocity)
    ply:EmitSound "SlidingAbility.ImpactSoft"
    if SERVER then ply:EmitSound "SlidingAbility.ScrapeRough" end
end)

/*
    Do not play footsteps if player is sliding
*/
hook.Add("PlayerFootstep", "Sliding sound", function(ply, pos, foot, sound, volume, filter)
    return ply:GetNWBool "SlidingAbility_IsSliding" or nil
end)

/*
    Return sliding animation to play
*/
hook.Add("CalcMainActivity", "Sliding animation", function(ply, velocity)
    if not ply:GetNWBool "SlidingAbility_IsSliding" then return end
    if GetSlidingActivity(ply) == -1 then return end
    return GetSlidingActivity(ply), -1
end)

/*
    Main animation lol
*/
hook.Add("UpdateAnimation", "Sliding aim pose parameters", function(ply, velocity, maxSeqGroundSpeed)
    if not ply:GetNWBool "SlidingAbility_IsSliding" then
        if ply.SlidingAbility_SlidingReset then
            local l = ply
            if ply == LocalPlayer() then
                if g_LegsVer then l = GetPlayerLegs() end
                if EnhancedCamera then l = EnhancedCamera.entity end
                if EnhancedCameraTwo then l = EnhancedCameraTwo.entity end
            end

            if IsValid(l) then SetSlidingPose(ply, l, 0) end
            if g_LegsVer then ManipulateBones(ply, GetPlayerLegs(), Angle(), Angle(), Angle()) end
            if EnhancedCamera then ManipulateBones(ply, EnhancedCamera.entity, Angle(), Angle(), Angle()) end
            if EnhancedCameraTwo then ManipulateBones(ply, EnhancedCameraTwo.entity, Angle(), Angle(), Angle()) end
            ManipulateBones(ply, ply, Angle(), Angle(), Angle())
            ply.SlidingAbility_SlidingReset = nil
        end

        return
    end

    local pppitch = ply:LookupPoseParameter "aim_pitch"
    local ppyaw = ply:LookupPoseParameter "aim_yaw"
    if pppitch >= 0 and ppyaw >= 0 then
        local b = ply:GetManipulateBoneAngles(0).roll
        local p = ply:GetPoseParameter "aim_pitch" // degrees in server, 0-1 in client
        local y = ply:GetPoseParameter "aim_yaw"
        if CLIENT then
            p = Lerp(p, ply:GetPoseParameterRange(pppitch))
            y = Lerp(y, ply:GetPoseParameterRange(ppyaw))
        end

        p = p - b

        local a = ply:GetSequenceActivity(ply:GetSequence())
        local la = ply:GetSequenceActivity(ply:GetLayerSequence(0))
        if a == ply:GetSequenceActivity(ply:LookupSequence(ACT_HL2MP_SIT_DUEL)) and la ~= ACT_HL2MP_GESTURE_RELOAD_DUEL then
            p = p - 45
            ply:SetPoseParameter("aim_yaw", ply:GetPoseParameterRange(ppyaw))
        elseif a == ply:GetSequenceActivity(ply:LookupSequence(ACT_HL2MP_SIT_CAMERA)) then
            y = y + 20
            ply:SetPoseParameter("aim_yaw", y)
        end

        ply:SetPoseParameter("aim_pitch", p)
    end

    if SERVER then return end

    local l = ply
    if ply == LocalPlayer() then
        if g_LegsVer then l = GetPlayerLegs() end
        if EnhancedCamera then l = EnhancedCamera.entity end
        if EnhancedCameraTwo then l = EnhancedCameraTwo.entity end
        if not IsValid(l) then return end
    end

    local dp = ply:GetPos() - (l.SlidingAbility_SlidingPreviousPosition or ply:GetPos())
    local dp2d = Vector(dp.x, dp.y)
    dp:Normalize()
    dp2d:Normalize()
    local dot = ply:GetForward():Dot(dp2d)
    SetSlidingPose(ply, l, math.deg(math.asin(dp.z)) * dot + 42)
    l.SlidingAbility_SlidingPreviousPosition = ply:GetPos()
    ply.SlidingAbility_SlidingReset = true
end)

/*
    Fix bones issues on respawns
*/
if SERVER then
    /*
        Handle mapchanges
    */
    hook.Add("PlayerInitialSpawn", "Prevent breaking TPS model on changelevel", function(ply, transition)
        // Check if player just logged in or not
        if not transition then return end
        timer.Simple(1, function()
            for i = 0, ply:GetBoneCount() - 1 do
                ply:ManipulateBoneScale(i, Vector(1, 1, 1))
                ply:ManipulateBoneAngles(i, Angle())
                ply:ManipulateBonePosition(i, Vector())
            end
        end)
    end)

    /*
        Handle rounds
    */
    hook.Add("PlayerSpawn", "Prevent breaking TPS model on new round", function(ply)
        // Check if player just logged in or not
        timer.Simple(1, function()
            for i = 0, ply:GetBoneCount() - 1 do
                ply:ManipulateBoneScale(i, Vector(1, 1, 1))
                ply:ManipulateBoneAngles(i, Angle())
                ply:ManipulateBonePosition(i, Vector())
            end
        end)
    end)

    return
end