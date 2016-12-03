-------------------------------------------------------------------------------
--
--		HUD Reducer
--		
--		Author: 	Telperion
--		Date: 		2016-11-27
--
-------------------------------------------------------------------------------

local playerExpected = {false, false};
for pn = 1,2 do
	if GAMESTATE:IsHumanPlayer("PlayerNumber_P"..pn) then
		playerExpected[pn] = true;
	end
end
local anyOf = function(a) local r = false; for _,r in pairs(a) do r = r or v; end return r; end
local hamburgerHelper = Def.Quad {
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-SCREEN_WIDTH,-SCREEN_HEIGHT);
	end,
	OnCommand = function(self)
		Trace("HUD Reducer: Go!")
		local hamburger = SCREENMAN:GetTopScreen();
		
		if hamburger:GetScreenType() == "ScreenType_Gameplay" then
			for p,v in pairs(hamburger:GetChild("Underlay"):GetChildren()) do
				Trace("hamburger children: "..p);
			end
		end
				
		local playersFound = 0;
		for pn,_ in ipairs(playerExpected) do
			Trace(pn.." is human!");
			pv = hamburger:GetChild("PlayerP"..pn);
			if pv then
				hamburger:GetChild("ScoreP"..pn):visible(false);
				pv:GetChild("Combo"):visible(false):hibernate(1573);
				
				-- SL-specific underlay usage!
				hamburger:GetChild("Underlay"):GetChild("P"..pn.."Score"):visible(false);
				hamburger:GetChild("Underlay"):GetChild("DangerP" ..  pn):visible(false):hibernate(1573);				
				
				playerExpected[pn] = false;
			end
		end
		
		Trace("HUD Reducer: Done!")
		self:hibernate(1573);
	end
}

return hamburgerHelper;
-------------------------------------------------------------------------------