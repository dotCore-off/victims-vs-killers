PB = PB or {}
PB.Config = PB.Config or {}

// Let's go lol
local PLAYER = FindMetaTable("Player")

/*
	Test if the given player is a sponsor
	Yes = return true | No = return false
*/
function PLAYER:IsSponsor()
	// Basic checks
	if (!IsValid(self) or table.IsEmpty(PB.Config.GroupSponsor)) then return end

	// Test & return
	if (table.HasValue(PB.Config.GroupSponsor, self:GetUserGroup())) then
		return true
	else
		return false
	end
end

/*
	Test if the given player is a staff
	Yes = return true | No = return false
*/
function PLAYER:IsStaff()
	// Test if the given player is valid
	if (!IsValid(self) or table.IsEmpty(PB.Config.GroupStaff)) then return end

	// Test & return
	if (table.HasValue(PB.Config.GroupStaff, self:GetUserGroup())) then
		return true
	else
		return false
	end
end

/*
	With this, we can send a notification to a player
			@Params: string, int, int
*/
function PLAYER:Notify(msg, notifType, time)
	// Basic checks
	if (!IsValid(self) or !PB.Config.NotificationEnabled or !isstring(msg) or #msg <= 0) then return end

	// Allows us to notify from both clientside & serverside
	if (SERVER) then
		net.Start("PB.Notify")
			net.WriteString(msg)
			net.WriteInt(notifType or 1, 8)
			net.WriteInt(time, 8)
		net.Send(self)
	elseif (CLIENT) then
		notification.AddLegacy(msg, notifType, time)
	end
end

/*
	Quickly punish a player using compatible admin mod
			@Params: int, string, int
			@type: 1 = Kick, 2 = Ban
*/
function PLAYER:Punish(type, msg, duration)
	if (type == 1) then
		self:Kick(msg)
	elseif (type == 2) then
		local sid = self:SteamID()
		duration = duration or 0

		if (sAdmin) then
			RunConsoleCommand("sa", "banid", self:SteamID64(), duration, msg)
		elseif (ULib) then
			ULib.ban(self, duration, msg)
		elseif (sam) then
			RunConsoleCommand("sam", "banid", sid, duration, msg)
		elseif (xAdmin) then
			if (xAdmin.Config) then
				if (xAdmin.Config.MajorVersion == 1) then
					RunConsoleCommand("xadmin_ban", sid, duration, msg)
				else
					RunConsoleCommand("xadmin", "ban", sid, duration, msg)
				end
			end
		elseif (SERVERGUARD) then
			RunConsoleCommand("serverguard", "ban", sid, duration, msg)
		else
			self:Ban(duration, true)
		end
	end
end

/*
	Give rewards to a player using configured currency
					@Param: int
*/
function PLAYER:GiveMoney(amount)
	if (!IsValid(self) or !self:IsPlayer() or !PB.Config.RewardsCurrency or !PB.Config.RewardsCurrencies[PB.Config.RewardsCurrency] or amount <= 0) then return end

	local finalAmount = self:IsSponsor() and amount * (PB.Config.RewardsMultiplier or 1) or amount

	PB.Config.RewardsCurrencies[PB.Config.RewardsCurrency].addFunction(self, finalAmount)
	self:Notify("You received " .. finalAmount .. " " .. PB.Config.RewardsCurrency .. " !", 0, 5)
end