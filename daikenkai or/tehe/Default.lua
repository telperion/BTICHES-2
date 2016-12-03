-------------------------------------------------------------------------------
--
--		tehe
--		
--		Author: 	Telperion
--		Date: 		2016-12-02
--
-------------------------------------------------------------------------------

local BPS = GAMESTATE:GetSongBPS();	
local isUsingReverse = {false, false};
local reverseMult = {false, false};

local tehe = Def.ActorFrame {
	OnCommand = function(self)
		self:sleep(1000);
	end
};

for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
	pn = tonumber(string.match(pe, "[0-9]+"));
	
	pops = GAMESTATE:GetPlayerState(pe):GetPlayerOptions("ModsLevel_Song");
	noteskinName = pops:NoteSkin();
	
	tehe[#tehe+1] = NOTESKIN:LoadActorForNoteSkin("Down", "Tap Note", noteskinName)..{
		Name="TeheP"..pn,
		InitCommand=function(self)				
		end,
		OnCommand=function(self)
			self:aux( tonumber(string.match(self:GetName(), "([0-9]+)")) );
			local i = self:getaux();
			pv = SCREENMAN:GetTopScreen():GetChild('PlayerP'..i);
			pops = GAMESTATE:GetPlayerState("PlayerNumber_P"..i):GetPlayerOptions("ModsLevel_Song");
			isUsingReverse[i] = (pops:Reverse() > 0.5);
			reverseMult[i] = isUsingReverse[i] and -1 or 1;
			self:visible(true)
				:baserotationz(180)
				:xy(pv:GetX() + 32 * (1 - pops:Mini()/2), SCREEN_CENTER_Y + reverseMult[i] * (SCREEN_CENTER_Y + 64))
				:queuecommand("Here");
		end,
		HereCommand=function(self)
			pv = SCREENMAN:GetTopScreen():GetChild('PlayerP'..self:getaux());
			self:bounceend(7.0 * (60/122))
				:rotationx(360)
				:rotationy(360)
				:rotationz(360)
				:y(pv:GetY() - 128 * reverseMult[self:getaux()])
				:queuecommand("Gone");			
		end,
		GoneCommand=function(self)
			self:decelerate(1.0 * (60/122))
				:addy(128 * reverseMult[self:getaux()])
				:diffusealpha(0.0);
		end,
	}
end

return tehe
