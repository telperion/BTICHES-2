-------------------------------------------------------------------------------
--
--		Special Content to Exercise the Player's Earthbending Technique
--		
--		Author: 	Telperion
--		Date: 		2016-11-25
--
-------------------------------------------------------------------------------

local sw = SCREEN_WIDTH;
local sh = SCREEN_HEIGHT;
local bpm = 170;
local ofs = -2.040;
local plr = {nil, nil};
local curmessage = 1;
local fgcurcommand = 0;
local checked = false;
local screen;
local nextbeat = 0;
local DEG_TO_RAD = math.pi / 180.0;



local theBoys = Def.ActorFrame {
	InitCommand = function(self)
		self:fov(70)
			:vanishpoint(sw/2, sh/4)			
			:SetDrawByZPosition(true);
	end,
	OnCommand = function(self)
		plr[1] = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		plr[2] = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
		SCREENMAN:GetTopScreen():SetDrawByZPosition(true);
		self:sleep(1000);
	end
};



-------------------------------------------------------------------------------
--
-- 		Some graphical doods 'n' dads 'n' doodads.
--
-------------------------------------------------------------------------------
nattoBG = Def.ActorFrame {
	Name = "nattoBG",
	InitCommand = function(self)
		self:aux(0);
	end,
	OnCommand = function(self)
--		self:diffusealpha(0.1);			-- DEBUG ONLY
	end,
	QuakeCommand = function(self)
		-- Aux represents magnitude
		local magnitude = self:getaux();
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				starlet:vibrate():effectmagnitude(starlet:getaux() * magnitude / 10, 0, 0);
			end
		end
	end,
	StableCommand = function(self)		
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				starlet:stopeffect();
			end
		end
	end,
	
	PullCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				local myIndex = starlet:getaux();
				local sideSign = (myIndex % 2 == 1) and 1 or -1;
				starlet:decelerate(tweenTime)
					   :xy(sw * (0.5 + sideSign * myIndex * myIndex * 0.003), 
						   sh * (0.5 + myIndex * 0.005));
			end
		end
	end,
	PushCommand = function(self)
		-- Aux represents tween time
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				starlet:decelerate(tweenTime)
					   :Center();
			end
		end
	end,
	DropCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				local myIndex = starlet:getaux();
				local myDropTime = {1, 1, 1, 1, 2, 2, 2, 2, 3, 3};
				starlet:accelerate(tweenTime * myDropTime[myIndex])
					   :y(sh * (0.5 + myIndex * 0.01));
			end
		end
	end,
	ResetCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				starlet:decelerate(tweenTime)
					   :xy(sw/2,sh/2);
			end
		end
	end,	
	PlungeCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				local myIndex = starlet:getaux();
				starlet:accelerate(tweenTime)
					   :y(sh * (1.5 + myIndex * 1.0));
			end
		end
	end,
	BabaCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				local myIndex = starlet:getaux();
				local myAppearTime = {1, 1, 1, 1, 1, 1, 0, 0, 0, 0};
				starlet:sleep(tweenTime * myAppearTime[myIndex])
					   :y(sh/2);
			end
		end
	end,
	HaltCommand = function(self)
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				starlet:stoptweening();
			end
		end
	end,
	
	
	EnterCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoLayer") then
				local myIndex = starlet:getaux();
				local myDebut = (1.1 - myIndex * 0.1);
				starlet:accelerate(tweenTime * myDebut)
					   :diffusealpha(1.0);
			elseif string.find(moniker, "nattoFader") then
				local myIndex = starlet:getaux();
				local myDebut = (1.1 - myIndex * 0.1);
				starlet:decelerate(tweenTime * myDebut)
					   :diffusealpha(0.10);
			elseif string.find(moniker, "nattoCloudy") then
				starlet:linear(tweenTime)
					   :diffusealpha(1.0);
			elseif string.find(moniker, "nattoNight") then
				starlet:sleep(tweenTime)
					   :diffusealpha(1.0);
			end
		end
	end,
	
	LightenCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoFader") then
				starlet:linear(tweenTime)
					   :diffuse(0.0, 0.5, 1.0, 0.10);
			end
		end
	end,
	DarkenCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoFader") then
				starlet:linear(tweenTime)
					   :diffuse(0.1, 0.1, 0.3, 0.10);
			end
		end
	end,	
	NightCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoFader") then
				starlet:linear(tweenTime)
					   :diffusealpha(0.20);
			elseif string.find(moniker, "nattoCloudy") then
				starlet:linear(tweenTime/2)
					   :diffuse(0.8, 0.5, 0.2, 0.8)
					   :linear(tweenTime/2)
					   :diffuse(0.0, 0.0, 0.0, 0.0);
			end
		end
	end,
	DayCommand = function(self)
		local BPS = GAMESTATE:GetSongBPS();	
		local tweenTime = self:getaux() / BPS;
		for moniker,starlet in pairs(self:GetChildren()) do
			if string.find(moniker, "nattoFader") then
				starlet:linear(tweenTime)
					   :diffuse(0.0, 0.5, 1.0, 0.10);
			elseif string.find(moniker, "nattoCloudy") then
				starlet:linear(tweenTime/2)
					   :diffuse(0.8, 0.3, 0.0, 0.8)
					   :linear(tweenTime/2)
					   :diffuse(1.0, 1.0, 1.0, 1.0);
			end
		end
	end,
};

nattoNightSky = Def.Sprite {
	Name = "nattoNight",
	Texture = "nightsky.png",
	InitCommand = function(self)
		self:Center()
			:SetWidth(sw)
			:SetHeight(sh);
	end,
	OnCommand = function(self)
		self:diffusealpha(0.0);
	end,
}
table.insert(nattoBG, nattoNightSky);

nattoCloudySky = Def.Sprite {
	Name = "nattoCloudy",
	Texture = "cloudysky.png",
	InitCommand = function(self)
		self:Center()
			:SetWidth(sw)
			:SetHeight(sh);
	end,
	OnCommand = function(self)
		self:diffusealpha(0.0);
	end,
}
table.insert(nattoBG, nattoCloudySky);

local nattoLayers = {};
for i = 1,10 do
	nattoLayers[#nattoLayers+1] = Def.Sprite {
		Name = "nattoLayer"..i,
		Texture = "natto-"..i..".png",
		InitCommand = function(self)
			local myIndex = tonumber(string.match(self:GetName(), "[0-9]+"));
			self:Center()
				:SetWidth(sw)
				:SetHeight(sh)
				:aux(myIndex)
				:draworder(myIndex / 100);
		end,
		OnCommand = function(self)
			self:diffusealpha(0.0);
		end,
	}
end

local nattoQuads = {};
for i = 1,10 do
	nattoQuads[#nattoQuads+1] = Def.Quad {
		Name = "nattoFader"..i,
		InitCommand = function(self)
			local myIndex = tonumber(string.match(self:GetName(), "[0-9]+"));
			self:Center()
				:SetWidth(sw)
				:SetHeight(sh)
				:aux(myIndex)
				:draworder(myIndex / 100)
				:diffuse(0.0, 0.5, 1.0, 0.00);
		end
	}
end
for i = 1,10 do
	table.insert(nattoBG, nattoQuads[i]);
	table.insert(nattoBG, nattoLayers[i]);
end

table.insert(theBoys, nattoBG);



--
--		Proxy up the players.
--
local DefaultProxyP1 = Def.ActorFrame {
	Name = "DefaultProxyP1",
	Def.ActorProxy {					
		Name = "Proxy",
		BeginCommand=function(self)
			local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
			if McCoy then self:SetTarget(McCoy); else self:hibernate(1573); end
		end,
		OnCommand=function(self)
			local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
			if McCoy then self:xy(-McCoy:GetX(), -McCoy:GetY()); end
		end
	},
	InitCommand = function(self)
	end,
	OnCommand = function(self)
		local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP1');
		if McCoy then self:xy(McCoy:GetX(), McCoy:GetY()); end
	end,
}
table.insert(theBoys, DefaultProxyP1);

local DefaultProxyP2 = Def.ActorFrame {
	Name = "DefaultProxyP2",
	Def.ActorProxy {					
		Name = "Proxy",
		BeginCommand=function(self)
			local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
			if McCoy then self:SetTarget(McCoy); else self:hibernate(1573); end
		end,
		OnCommand=function(self)
			local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
			if McCoy then self:xy(-McCoy:GetX(), -McCoy:GetY()); end
		end
	},
	InitCommand = function(self)
	end,
	OnCommand = function(self)
		local McCoy = SCREENMAN:GetTopScreen():GetChild('PlayerP2');
		if McCoy then self:xy(McCoy:GetX(), McCoy:GetY()); end
	end,
}
table.insert(theBoys, DefaultProxyP2);




-------------------------------------------------------------------------------
--
-- 		This is where the shit will be happening.
--
local BTIUtil_Scale = function(t, inLower, inUpper, outLower, outUpper)
	local ti = (t - inLower) / (inUpper - inLower);
	return outLower + ti * (outUpper - outLower);
end


local nattoBGDirections = {
	-- Beat number, then message to send, then optionally the argument to the command	
	{  0,	"Enter",	 32},
	
	{ 63,	"Drop",		  1},
	{ 64,	"Darken",	 64},
	{ 66,	"Reset",	  1},
	{ 67,	"Drop",		  1},
	{ 70,	"Reset",	  1},
	{ 71,	"Drop",		  1},
	{ 74,	"Reset",	  1},
	{ 75,	"Drop",		  1},
	{ 78,	"Reset",	  1},
	{ 79,	"Drop",		  1},
	{ 82,	"Reset",	  1},
	{ 83,	"Drop",		  1},
	{ 86,	"Reset",	  1},
	{ 87,	"Drop",		  1},
	{ 90,	"Reset",	  1},
	{ 91,	"Drop",		  1},
	{ 94,	"Reset",	  1},
	
	{ 96,	"Pull",		 32},
	{ 97,	"Quake",	  5},
	{103,	"Halt", 	nil},
	{103,	"Stable",	nil},
	{104,	"Pull",		 32},
	{105,	"Quake",	  7},
	{111,	"Halt",		nil},
	{111,	"Stable",	nil},
	{112,	"Pull",		 16},
	{113,	"Quake",	 10},
	{124,	"Stable",	nil},
	
	{138,	"Halt",		nil},
	{138,	"Push",		 10},
	{138,	"Quake",	 15},
	{143,	"Stable",	nil},
	{143,	"Halt",		nil},
	{143,	"Pull",		  1},
	
	{170,	"Halt",		nil},
	{170,	"Push",		 10},
	{170,	"Quake",	 15},
	{175,	"Stable",	nil},
	{175,	"Halt",		nil},
	{175,	"Pull",		  1},
	
	{192,	"Plunge",	  2},
	{194,	"Baba",		0.5},
	{196,	"Plunge",	  2},
	{198,	"Pull",		0.1},
	
	{200,	"Plunge",	 16},
	{202,	"Halt",		nil},
	{202,	"Pull",		  2},	
	{204,	"Plunge",	 16},
	{206,	"Halt",		nil},
	{206,	"Pull",		  2},
	
	{208,	"Plunge",	 16},
	{210,	"Halt",		nil},
	{210,	"Pull",		  2},	
	{212,	"Plunge",	 16},
	{214,	"Halt",		nil},
	{214,	"Pull",		  2},
	{216,	"Plunge",	 16},
	{218,	"Halt",		nil},
	{218,	"Pull",		  2},
	{220,	"Plunge",	 16},
	{220,	"Halt",		nil},
	{222,	"Push",		  4},
	
	{222,	"Night",	 32},
	
	
	{288,	"Plunge",	  2},
	{290,	"Baba",		0.5},
	{292,	"Plunge",	  2},
	{294,	"Push",		0.1},
	
	{296,	"Plunge",	 16},
	{298,	"Halt",		nil},
	{298,	"Push",		  2},	
	{300,	"Plunge",	 16},
	{302,	"Halt",		nil},
	{302,	"Push",		  2},
	
	{304,	"Plunge",	 16},
	{306,	"Halt",		nil},
	{306,	"Push",		  2},	
	{308,	"Plunge",	 16},
	{310,	"Halt",		nil},
	{310,	"Push",		  2},
	{312,	"Plunge",	 16},
	{314,	"Halt",		nil},
	{314,	"Push",		  2},
	{316,	"Plunge",	 16},
	{318,	"Halt",		nil},
	{318,	"Push",		 18},
	
	{336,	"Pull",		 32},
	{337,	"Quake",	  5},
	{343,	"Halt", 	nil},
	{343,	"Stable",	nil},
	{344,	"Pull",		 32},
	{345,	"Quake",	  7},
	{351,	"Halt",		nil},
	{351,	"Stable",	nil},
	{352,	"Pull",		 16},
	{353,	"Quake",	 10},
	{364,	"Stable",	nil},
	
	{378,	"Halt",		nil},
	{378,	"Push",		 10},
	{378,	"Quake",	 15},
	{383,	"Stable",	nil},
	{383,	"Halt",		nil},
	{383,	"Pull",		  1},
	
	{410,	"Halt",		nil},
	{410,	"Plunge",	 16},
	{410,	"Quake",	 15},
	{415,	"Stable",	nil},
	{415,	"Halt",		nil},
	{415,	"Pull",		  1},
	
	{432,	"Push",		 64},
	{432,	"Day",		 64},
};
local nattoBGIndex = 0;

local nattoProxyEffects = {
	-- proxyEffect[1]: beat number
	-- proxyEffect[2]: mod name (applied as element function of Actor, with a couple exceptions)
	-- proxyEffect[3]: mod strength
	-- proxyEffect[4]: mod length (in beats)
	-- proxyEffect[5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
	--
	-- stag = column-based "skewing", where +1.0 staggers the columns by one arrow height, left highest
	--
--	{ 32.0, "skewx",	 1.0,	 4.0,	3},
--	{ 39.0, "skewx",	 0.0,	 1.0,	3},
--	{ 40.0, "skewx",	-1.0,	 4.0,	3},
--	{ 47.0, "skewx",	 0.0,	 1.0,	3},
--	{ 48.0, "skewy",	 1.0,	 4.0,	3},
--	{ 48.0, "stag",		-1.0,	 4.0,	3},
--	{ 55.0, "skewy",	 0.0,	 1.0,	3},
--	{ 55.0, "stag",		 0.0,	 1.0,	3},
--	{ 56.0, "skewy",	-1.0,	 4.0,	3},
--	{ 56.0, "stag",		 1.0,	 4.0,	3},
--	{ 63.0, "skewy",	 0.0,	 1.0,	3},
--	{ 63.0, "stag",		 0.0,	 1.0,	3},
	
	
	{ 97.0, "addx",		 sw/12,	 6.0,	1},
	{ 97.0, "addx",		-sw/12,	 6.0,	2},
	{ 97.0, "vibrate",	 5.0,	 6.0,	3},
	{103.0, "vibrate",	 0.0,	 1.0,	3},
	{105.0, "addx",		 sw/12,	 6.0,	1},
	{105.0, "addx",		-sw/12,	 6.0,	2},
	{105.0, "vibrate",	 7.0,	 6.0,	3},
	{111.0, "vibrate",	 0.0,	 1.0,	3},
	{112.0, "addx",		 sw/12,	12.0,	1},
	{112.0, "addx",		-sw/12,	12.0,	2},
	{112.0, "vibrate",	10.0,	 6.0,	3},
	{124.0, "vibrate",	 0.0,	 1.0,	3},
	
	
	{129.0, "skewx",	 0.6,	 1.0,	3},
	{130.0, "skewx",	-0.6,	 1.0,	3},
	{131.0, "skewx",	 0.0,	 1.0,	3},
	{132.0, "skewx",	-0.6,	 0.5,	3},
	{132.5, "skewx",	 0.6,	 0.5,	3},
	{133.0, "skewx",	 0.0,	 0.5,	3},
	{133.0, "vibrate",	 5.0,	 1.0,	3},
	{134.0, "vibrate",	 0.0,	 1.0,	3},
	
	{134.00,"stag",		 0.1,	 0.01,	3},
	{134.00,"addy",		  16,	 0.01,	3},
	{134.25,"stag",		 0.2,	 0.01,	3},
	{134.25,"addy",		  16,	 0.01,	3},
	{134.50,"stag",		 0.3,	 0.01,	3},
	{134.50,"addy",		  16,	 0.01,	3},
	{134.75,"stag",		 0.4,	 0.01,	3},
	{134.75,"addy",		  16,	 0.01,	3},
	{135.00,"stag",		 0.5,	 0.01,	3},
	{135.00,"addy",		  16,	 0.01,	3},
	{135.25,"stag",		 0.375,	 0.01,	3},
	{135.25,"addy",		 -20,	 0.01,	3},
	{135.50,"stag",		 0.25,	 0.01,	3},
	{135.50,"addy",		 -20,	 0.01,	3},
	{135.75,"stag",		 0.125,	 0.01,	3},
	{135.75,"addy",		 -20,	 0.01,	3},
	{136.00,"stag",		 0.0,	 0.01,	3},
	{136.00,"addy",		 -20,	 0.01,	3},
	
	{138.0, "vibrate",	 3.0,	 1.0,	3},
	{139.0, "vibrate",	 5.0,	 1.0,	3},
	{140.0, "vibrate",	 8.0,	 1.0,	3},
	{141.0, "vibrate",	11.0,	 1.0,	3},
	{142.0, "vibrate",	15.0,	 1.0,	3},
	{143.0, "vibrate",	 0.0,	 1.0,	3},
	
	{144.0, "addx",		 sw/24,	 1.0,	1},
	{144.0, "addx",		-sw/24,	 1.0,	2},
	{145.0, "addx",		-sw/24,	 1.0,	1},
	{145.0, "addx",		 sw/24,	 1.0,	2},	
	{146.0, "skewy",	-1.0,	 1.0,	3},
	{147.0, "skewy",	 0.0,	 4.0,	3, 'linear'},
	
	
	{161.0, "skewx",	-0.6,	 1.0,	3},
	{162.0, "skewx",	 0.6,	 1.0,	3},
	{163.0, "skewx",	 0.0,	 1.0,	3},
	{164.0, "skewx",	 0.6,	 0.5,	3},
	{164.5, "skewx",	-0.6,	 0.5,	3},
	{165.0, "skewx",	 0.0,	 0.5,	3},
	{165.0, "vibrate",	 5.0,	 1.0,	3},
	{166.0, "vibrate",	 0.0,	 1.0,	3},
	
	{166.00,"stag",		-0.125,	 0.01,	3},
	{166.00,"addy",		  20,	 0.01,	3},
	{166.25,"stag",		-0.25,	 0.01,	3},
	{166.25,"addy",		  20,	 0.01,	3},
	--166.50 not in this iteration
	{166.75,"stag",		-0.375,	 0.01,	3},
	{166.75,"addy",		  20,	 0.01,	3},
	{167.00,"stag",		-0.5,	 0.01,	3},
	{167.00,"addy",		  20,	 0.01,	3},
	{167.25,"stag",		-0.375,	 0.01,	3},
	{167.25,"addy",		 -20,	 0.01,	3},
	{167.50,"stag",		-0.25,	 0.01,	3},
	{167.50,"addy",		 -20,	 0.01,	3},
	{167.75,"stag",		-0.125,	 0.01,	3},
	{167.75,"addy",		 -20,	 0.01,	3},
	{168.00,"stag",		-0.0,	 0.01,	3},
	{168.00,"addy",		 -20,	 0.01,	3},
	
	{170.0, "vibrate",	 3.0,	 1.0,	3},
	{171.0, "vibrate",	 5.0,	 1.0,	3},
	{172.0, "vibrate",	 8.0,	 1.0,	3},
	{173.0, "vibrate",	11.0,	 1.0,	3},
	{174.0, "vibrate",	15.0,	 1.0,	3},
	{175.0, "vibrate",	 0.0,	 1.0,	3},
	
	{176.0, "addx",		-sw/24,	 1.0,	1},
	{176.0, "addx",		 sw/24,	 1.0,	2},
	{177.0, "addx",		 sw/24,	 1.0,	1},
	{177.0, "addx",		-sw/24,	 1.0,	2},	
	{178.0, "skewy",	 1.0,	 1.0,	3},
	{179.0, "skewy",	 0.0,	 4.0,	3, 'linear'},
	
	{192.0, "addy",		 sh,	 0.5,	1},
	{192.5, "addy",		-sh,	 1.5,	1},
	{196.0, "addy",		 sh,	 0.5,	2},
	{196.5, "addy",		-sh,	 1.5,	2},
	
	{288.0, "addy",		 sh,	 0.5,	1},
	{288.5, "addy",		-sh,	 1.5,	1},
	{292.0, "addy",		 sh,	 0.5,	2},
	{292.5, "addy",		-sh,	 1.5,	2},	
	{296.0, "addy",		 sh,	 0.5,	1},
	{296.5, "addy",		-sh,	 1.5,	1},
	{300.0, "addy",		 sh,	 0.5,	2},
	{300.5, "addy",		-sh,	 1.5,	2},
	{302.0, "addx",		 sw/24,	 0.01,	1},
	{302.0, "addx",		-sw/24,	 0.01,	2},
	{302.5, "addy",		 sh/24,	 0.01,	3},
	{303.0, "addx",		-sw/24,	 0.5,	1},
	{303.0, "addx",		 sw/24,	 0.5,	2},
	{303.5, "addy",		-sh/24,	 0.5,	3},
	
	
--	{319.95,"zoomx",	 0.0,	 0.05,	1},
--	{320.0, "zoomx",	 0.0,	 2.0,	2, 'accelerate'},
--	{320.0, "zoomx",	 1.0,	 2.0,	1, 'decelerate'},
--	{322.0, "zoomx",	 1.0,	 2.0,	2, 'accelerate'},
--	{322.0, "zoomx",	 0.0,	 2.0,	1, 'decelerate'},
--	{324.0, "zoomx",	 0.0,	 2.0,	2, 'accelerate'},
--	{324.0, "zoomx",	 1.0,	 2.0,	1, 'decelerate'},
--	{326.0, "zoomx",	 1.0,	 2.0,	2, 'accelerate'},
--	{326.0, "zoomx",	 0.0,	 2.0,	1, 'decelerate'},
--	{328.0, "zoomx",	 0.0,	 2.0,	2, 'accelerate'},
--	{328.0, "zoomx",	 1.0,	 2.0,	1, 'decelerate'},
--	{330.0, "zoomx",	 1.0,	 2.0,	2, 'accelerate'},
--	{330.0, "zoomx",	 0.0,	 2.0,	1, 'decelerate'},
--	{332.0, "zoomx",	 0.0,	 2.0,	2, 'accelerate'},
--	{332.0, "zoomx",	 1.0,	 2.0,	1, 'decelerate'},
--	{334.0, "zoomx",	 1.0,	 2.0,	2, 'accelerate'},
	
	
	{337.0, "vibrate",	 5.0,	 6.0,	3},
	{343.0, "vibrate",	 0.0,	 1.0,	3},
	{345.0, "vibrate",	 7.0,	 6.0,	3},
	{351.0, "vibrate",	 0.0,	 1.0,	3},
	{352.0, "vibrate",	10.0,	 6.0,	3},
	{364.0, "vibrate",	 0.0,	 1.0,	3},
	
	
	{369.0, "skewx",	 1.0,	 1.0,	3},
	{370.0, "skewx",	-1.0,	 0.5,	3},
	{370.5, "skewx",	-0.2,	 0.5,	3},
	{371.0, "skewx",	-0.8,	 0.5,	3},
	{371.5, "skewx",	 0.0,	 0.5,	3},
	{372.0, "skewx",	-0.6,	 0.5,	3},
	{372.5, "skewx",	 0.2,	 0.5,	3},
	{373.0, "skewx",	-0.4,	 0.5,	3},
	{373.5, "skewx",	 0.0,	 0.5,	3},
	
	{374.0, "stag",		-0.25,	 0.01,	3},
	{374.0, "addy",		  32,	 0.01,	3},
	{374.5, "stag",		-0.5,	 0.01,	3},
	{374.5, "addy",		  32,	 0.01,	3},
	{375.0, "stag",		-0.75,	 0.01,	3},
	{375.0, "addy",		  32,	 0.01,	3},
	{375.5, "stag",		-1.0,	 0.01,	3},
	{375.5, "addy",		  32,	 0.01,	3},
	{376.0, "stag",		 0.0,	 0.01,	3},
	{376.0, "addy",		-128,	 0.01,	3},
	
	{378.0, "vibrate",	 3.0,	 1.0,	3},
	{379.0, "vibrate",	 5.0,	 1.0,	3},
	{380.0, "vibrate",	 8.0,	 1.0,	3},
	{381.0, "vibrate",	11.0,	 1.0,	3},
	{382.0, "vibrate",	15.0,	 1.0,	3},
	{383.0, "vibrate",	 0.0,	 1.0,	3},
	
	{383.0, "addx",		 sw/24,	 1.0,	1},
	{383.0, "addx",		-sw/24,	 1.0,	2},
	{384.0, "addx",		-sw/24,	 1.0,	1},
	{384.0, "addx",		 sw/24,	 1.0,	2},	
	{385.0, "skewy",	-1.0,	 1.0,	3},
	{386.0, "skewy",	 0.0,	 5.0,	3, 'linear'},
	
	
	{401.0, "skewx",	-1.0,	 1.0,	3},
	{402.0, "skewx",	 1.0,	 1.0,	3},
	{403.0, "skewx",	 0.0,	 1.0,	3},
	{404.0, "skewx",	 1.0,	 0.5,	3},
	{404.5, "skewx",	-1.0,	 0.5,	3},
	{405.0, "skewx",	 0.0,	 0.5,	3},
	{405.0, "vibrate",	 5.0,	 1.0,	3},
	{406.0, "vibrate",	 0.0,	 1.0,	3},
	
	{406.00,"stag",		 0.2,	 0.01,	3},
	{406.00,"addy",		  32,	 0.01,	3},
	{406.25,"stag",		 0.4,	 0.01,	3},
	{406.25,"addy",		  32,	 0.01,	3},
	--166.50 not in this iteration
	{406.75,"stag",		 0.6,	 0.01,	3},
	{406.75,"addy",		  32,	 0.01,	3},
	{407.00,"stag",		 0.8,	 0.01,	3},
	{407.00,"addy",		  32,	 0.01,	3},
	{407.25,"stag",		 0.6,	 0.01,	3},
	{407.25,"addy",		 -32,	 0.01,	3},
	{407.50,"stag",		 0.4,	 0.01,	3},
	{407.50,"addy",		 -32,	 0.01,	3},
	{407.75,"stag",		 0.2,	 0.01,	3},
	{407.75,"addy",		 -32,	 0.01,	3},
	{408.00,"stag",		 0.0,	 0.01,	3},
	{408.00,"addy",		 -32,	 0.01,	3},
	
	{410.0, "rotationz",	360.0,	 5.0,	3, 'smooth'},
	
	{416.0, "addx",		-sw/24,	 1.0,	1},
	{416.0, "addx",		 sw/24,	 1.0,	2},
	{417.0, "addx",		 sw/24,	 1.0,	1},
	{417.0, "addx",		-sw/24,	 1.0,	2},	
	{418.0, "skewy",	 1.0,	 1.0,	3},
	{419.0, "skewy",	 0.0,	 4.0,	3, 'linear'},
};
local nattoEffectIndex = 0;

local nattoRememberX = {0, 0};

local nattoGfxHQ = Def.Quad {
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-sw,-sh)
			:visible(false);
	end,
	OnCommand = function(self)
		self:queuecommand("Update");
	end,
	UpdateCommand = function(self)
		-- Most things are determined by beat, believe it or not.		
		local overtime = GAMESTATE:GetSongBeat();
		
		-- TODO: this assumes the effect applies over a constant BPM section!!
		local BPS = GAMESTATE:GetSongBPS();	
		
		-- Who's interesting today?
		if overtime >=   0.0 and fgcurcommand ==  0 then
			for i,v in ipairs(plr) do
				if v then
					v:visible(false):decelerate(16.0 / BPS):y(sh/2 - 30):z(0);
					
					pp = self:GetParent():GetChild("DefaultProxyP"..i);
					pp:effectclock("beat");
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		
		-- Exception for the rotationy section
		
		if overtime >= 319.0 and fgcurcommand ==  1 then
			for i,v in ipairs(plr) do
				if v then
					pp = self:GetParent():GetChild("DefaultProxyP"..i);
					nattoRememberX[i] = pp:GetX();
				end
			end
			
			fgcurcommand = fgcurcommand + 1;
		end
		if overtime >= 320.0 and fgcurcommand ==  2 then
			for i,v in ipairs(plr) do
				if v then
					pp = self:GetParent():GetChild("DefaultProxyP"..i);
					if overtime >= 336.0 then
						pp:x(nattoRememberX[i])
						  :zoomx(1.0);
					else
						local param = math.fmod(overtime*0.25 + i*0.5 + 0.5, 1);
						-- if i == 1 then Trace("rotation faker! "..overtime..":\t"..param); end
						pp:x( nattoRememberX[i] - 128 * math.cos(math.pi * param) )
						  :zoomx( math.sin(math.pi * param) );
						
					end
				end
			end
			
			if overtime >= 336.0 then
				fgcurcommand = fgcurcommand + 1;
			end
		end
					
		-- Control the BG on its own terms.
		while true do
			if nattoBGIndex < #nattoBGDirections then
				local nattoBGHandle = self:GetParent():GetChild("nattoBG");
				local nattoBGInfo = nattoBGDirections[nattoBGIndex+1];				
				if overtime >= nattoBGInfo[1] then			
					local funcExec = nattoBGInfo[2];
					local funcArg  = nattoBGInfo[3];
					if funcArg then
						nattoBGHandle:aux(funcArg)
									 :playcommand(funcExec);
					else
						nattoBGHandle:playcommand(funcExec);
					end
														
					nattoBGIndex = nattoBGIndex + 1;
				else
					break;
				end
			else
				break;
			end
		end
		
		-- Apply skews and staggers.
		while true do
			if nattoEffectIndex < #nattoProxyEffects then
				local proxyEffect = nattoProxyEffects[nattoEffectIndex+1];				
				if overtime >= proxyEffect[1] then			
					local effFunc 		= proxyEffect[2];
					local effArg  		= proxyEffect[3];
					local effBeats		= proxyEffect[4];
					local effPlayers	= proxyEffect[5];
					local effTweenHint	= proxyEffect[6];
					
					for pn = 1,2 do
						if effPlayers == 3 or effPlayers == pn then
							pv = SCREENMAN:GetTopScreen():GetChild("PlayerP"..pn);
							pp = self:GetParent():GetChild("DefaultProxyP"..pn);
							if pv then
							
								if effFunc == "stag" then
									pca = pv:GetChild("NoteField"):GetColumnActors();
									for colIndex = 1,4 do
										pca[colIndex]:decelerate(effBeats / BPS)
													 :y(64 * effArg * (colIndex - 2.5));
									end
								else
									if effFunc == "vibrate" then
										if effArg <= 0.01 then
											pp:stopeffect();
										else
											pp[effFunc](pp);
											pp:effectmagnitude(effArg, effArg, 0);
										end
									else
										if effTweenHint then
											pp[effTweenHint](pp, effBeats / BPS);
										else
											pp:decelerate(effBeats / BPS);
										end
										pp[effFunc](pp, effArg);
									end
								end
							end
						end
					end		
														
					nattoEffectIndex = nattoEffectIndex + 1;
				else
					break;
				end
			else
				break;
			end
		end
		
		
		-- Wait a bit and then update again!
		self:queuecommand("WaitABit");
	end,
	WaitABitCommand = function(self)
		self:sleep(0.02);
		self:queuecommand("Update");
	end
}
table.insert(theBoys, nattoGfxHQ);


-------------------------------------------------------------------------------
--
--		Manage arrow mods for the whole song here.
--
local cspd = 2.8;
local cspdA = cspd * 0.9;
local cspdB = cspd * 0.7;
local cspdC = cspd * 1.3;
local modsTable = {
	-- [1]: beat start
	-- [2]: mod type
	-- [3]: mod strength (out of unity),
	-- [4]: mod approach (in beats to complete)
	-- [5]: player application (1 = P1, 2 = P2, 3 = both, 0 = neither)
		
		{   0.0,	"ScrollSpeed",	 cspd,    2.0,	3}, 
		
		{  32.0,	"ScrollSpeed",	cspdA,   32.0,	3}, 
		
	--for i in range(32, 64, 2):
	--	print('\t\t[  {:03.1f},\t"Boost",\t\t  {:0.2f},\t  2.0,\t3],'.format(i, (1 - (i%2) * 2) * (i-32) / 64))
		{  32.0,	"Boost",		  0.00,	  2.0,	3},
		{  34.0,	"Boost",		 -0.03,	  2.0,	3},
		{  36.0,	"Boost",		  0.06,	  2.0,	3},
		{  38.0,	"Boost",		 -0.09,	  2.0,	3},
		{  40.0,	"Boost",		  0.12,	  2.0,	3},
		{  42.0,	"Boost",		 -0.16,	  2.0,	3},
		{  44.0,	"Boost",		  0.19,	  2.0,	3},
		{  46.0,	"Boost",		 -0.22,	  2.0,	3},
		{  48.0,	"Boost",		  0.25,	  2.0,	3},
		{  50.0,	"Boost",		 -0.28,	  2.0,	3},
		{  52.0,	"Boost",		  0.31,	  2.0,	3},
		{  54.0,	"Boost",		 -0.34,	  2.0,	3},
		{  56.0,	"Boost",		  0.38,	  2.0,	3},
		{  58.0,	"Boost",		 -0.41,	  2.0,	3},
		{  60.0,	"Boost",		  0.44,	  2.0,	3},
		{  62.0,	"Boost",		 -0.47,	  2.0,	3},
		{  64.0,	"Boost",		  0.50,	  2.0,	3},
		{  66.0,	"Boost",		 -0.50,	  2.0,	3},
		{  68.0,	"Boost",		  0.50,	  2.0,	3},
		{  70.0,	"Boost",		 -0.50,	  2.0,	3},
		{  72.0,	"Boost",		  0.50,	  2.0,	3},
		{  74.0,	"Boost",		 -0.50,	  2.0,	3},
		{  76.0,	"Boost",		  0.50,	  2.0,	3},
		{  78.0,	"Boost",		 -0.50,	  2.0,	3},
		{  80.0,	"Boost",		  0.50,	  2.0,	3},
		{  82.0,	"Boost",		 -0.50,	  2.0,	3},
		{  84.0,	"Boost",		  0.50,	  2.0,	3},
		{  86.0,	"Boost",		 -0.50,	  2.0,	3},
		{  88.0,	"Boost",		  0.50,	  2.0,	3},
		{  90.0,	"Boost",		 -0.50,	  2.0,	3},
		{  92.0,	"Boost",		  0.50,	  2.0,	3},
		
		{  94.0,	"ScrollSpeed",	cspdB,    2.0,	3}, 
		{  94.0,	"Boost",		  1.0,	  2.0,	3},
		{  94.0,	"Drunk",		  1.0,	  2.0,	3},
		{  94.0,	"Tornado",		  0.5,	  2.0,	3},
		
		{  96.0,	"Dark",			  0.8,   32.0,	3}, 
		
		{ 120.0,	"Drunk",		  0.0,	  4.0,	3},
		{ 120.0,	"Tornado",		  0.0,	  4.0,	3},
		
		
		{ 138.0,	"Tilt",			  1.5,	  5.0,	1},
		{ 138.0,	"Tilt",			  1.8,	  5.0,	2},
		{ 138.0,	"Boost",		  1.5,	  5.0,	3},
		{ 143.0,	"Boost",		  1.0,	  1.0,	3},
		{ 143.0,	"Tilt",			 -0.4,	  0.5,	1},
		{ 143.0,	"Tilt",			 -0.5,	  0.5,	2},
		{ 143.5,	"Tilt",			  0.0,	  0.5,	3},
		
		{ 152.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 152.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 154.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 154.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 156.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 156.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 157.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 157.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 157.75,	"Drunk",		  0.8,	  0.01,	3},
		{ 157.8,	"Drunk",		  0.0,	  0.7,	3},
		{ 158.5,	"Drunk",		 -0.8,	  0.01,	3},
		{ 158.55,	"Drunk",		  0.0,	  0.4,	3},
		{ 159.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 159.05,	"Tipsy",		  0.0,	  0.9,	3},
		
				
		{ 170.0,	"Tilt",			 -1.8,	  5.0,	1},
		{ 170.0,	"Tilt",			 -1.5,	  5.0,	2},
		{ 170.0,	"Boost",		  1.5,	  5.0,	3},
		{ 175.0,	"Boost",		  1.0,	  1.0,	3},
		{ 175.0,	"Tilt",			  0.5,	  0.5,	1},
		{ 175.0,	"Tilt",			  0.4,	  0.5,	2},
		{ 175.5,	"Tilt",			  0.0,	  0.5,	3},
		
		{ 184.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 184.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 186.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 186.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 188.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 188.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 189.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 189.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 189.75,	"Drunk",		  0.8,	  0.01,	3},
		{ 189.8,	"Drunk",		  0.0,	  0.7,	3},
		{ 190.5,	"Drunk",		 -0.8,	  0.01,	3},
		{ 190.55,	"Drunk",		  0.0,	  0.4,	3},
		{ 191.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 191.05,	"Tipsy",		  0.0,	  0.9,	3},
		
		
		{ 192.0,	"Mini",			  0.5,	  0.01,	1},
		{ 192.0,	"Stealth",		  1.0,	  0.01,	2},
		{ 194.0,	"Mini",			  0.0,	  3.0,	1},
		{ 194.0,	"Stealth",		  0.0,	  3.0,	2},
		{ 196.0,	"Mini",			  0.5,	  0.01,	2},
		{ 196.0,	"Stealth",		  1.0,	  0.01,	1},
		{ 198.0,	"Mini",			  0.0,	  3.0,	2},
		{ 198.0,	"Stealth",		  0.0,	  3.0,	1},
		{ 198.0,	"Dizzy",		  2.0,	  0.25,	3},
		{ 198.25,	"Dizzy",		  0.0,	  1.75,	3},
		
		{ 208.0,	"Wave",			  0.8,	 24.0,	3},
		{ 208.0,	"Flip",			  0.35,	 24.0,	3},
		{ 208.0,	"Dark",			  1.0,	 24.0,	3},
		
		{ 224.0,	"Wave",			  0.0,	 24.0,	3},
		{ 224.0,	"Flip",			  0.0,	 24.0,	3},
		
		{ 272.0,	"Stealth",		  1.0,	  1.0,	1},		
		{ 276.0,	"Mini",			  1.5,	  1.0,	1},			
		{ 280.0,	"Dark",			  0.5,	  8.0,	2},	
		{ 280.0,	"Mini",			  0.0,	  8.0,	1},	
		{ 280.0,	"Stealth",		  0.8,	  7.0,	1},
		{ 280.0,	"Flip",			 -8.0,	  0.01,	2},
		{ 287.0,	"Stealth",		  0.0,	  1.0,	1},
		{ 287.0,	"Invert",		 -8.0,	  0.01,	2},
		{ 287.5,	"Invert",		 24.0,	  0.01,	2},
		{ 288.0,	"Invert",		  0.0,	  0.01,	2},
		{ 288.0,	"Flip",			  0.0,	  0.01,	2},
		{ 288.0,	"Dark",			  0.5,	  0.01,	1},
		
		
		{ 288.0,	"Mini",			  0.5,	  0.01,	1},
		{ 288.0,	"Stealth",		  1.0,	  0.01,	2},
		{ 290.0,	"Mini",			  0.0,	  3.0,	1},
		{ 290.0,	"Stealth",		  0.0,	  3.0,	2},
		{ 292.0,	"Mini",			  0.5,	  0.01,	2},
		{ 292.0,	"Stealth",		  1.0,	  0.01,	1},
		{ 294.0,	"Mini",			  0.0,	  3.0,	2},
		{ 294.0,	"Stealth",		  0.0,	  3.0,	1},
		{ 294.0,	"Flip",			 -0.25,	  0.25,	3},
		{ 294.25,	"Flip",			  0.0,	  1.75,	3},
		{ 296.0,	"Mini",			  0.5,	  0.01,	1},
		{ 296.0,	"Stealth",		  1.0,	  0.01,	2},
		{ 298.0,	"Mini",			  0.0,	  3.0,	1},
		{ 298.0,	"Stealth",		  0.0,	  3.0,	2},
		{ 300.0,	"Mini",			  0.5,	  0.01,	2},
		{ 300.0,	"Stealth",		  0.8,	  0.01,	1},
		{ 302.0,	"Mini",			  0.0,	  3.0,	2},
		{ 302.0,	"Stealth",		  0.0,	  3.0,	1},
		{ 303.0,	"Flip",			 -0.25,	  0.01,	3},
		{ 303.1,	"Flip",			  0.0,	  0.75,	3},
		
		{ 304.0,	"Wave",			  0.8,	 24.0,	3},
		{ 304.0,	"Flip",			  0.35,	 24.0,	3},
		{ 304.0,	"Dark",			  1.0,	 24.0,	3},
		
		{ 320.0,	"Wave",			  0.0,	 16.0,	3},
		{ 320.0,	"Flip",			  0.0,	 16.0,	3},
		{ 320.0,	"Dark",			  0.8,	 16.0,	3},
		
		
		{ 334.0,	"ScrollSpeed",	cspdB,    2.0,	3}, 
		{ 334.0,	"Boost",		  1.0,	  2.0,	3},
		{ 334.0,	"Drunk",		  1.0,	  2.0,	3},
		{ 334.0,	"Tornado",		  0.5,	  2.0,	3},
		
		{ 336.0,	"Dark",			  0.8,   32.0,	3}, 
		
		{ 360.0,	"Drunk",		  0.0,	  4.0,	3},
		{ 360.0,	"Tornado",		  0.0,	  4.0,	3},
		
		
		{ 378.0,	"Tilt",			  1.5,	  5.0,	1},
		{ 378.0,	"Tilt",			  1.8,	  5.0,	2},
		{ 378.0,	"Boost",		  1.5,	  5.0,	3},
		{ 383.0,	"Boost",		  1.0,	  1.0,	3},
		{ 383.0,	"Tilt",			 -0.4,	  0.5,	1},
		{ 383.0,	"Tilt",			 -0.5,	  0.5,	2},
		{ 383.5,	"Tilt",			  0.0,	  0.5,	3},
		
		{ 392.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 392.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 394.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 394.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 396.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 396.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 397.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 397.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 397.75,	"Drunk",		  0.8,	  0.01,	3},
		{ 397.8,	"Drunk",		  0.0,	  0.7,	3},
		{ 398.5,	"Drunk",		 -0.8,	  0.01,	3},
		{ 398.55,	"Drunk",		  0.0,	  0.4,	3},
		{ 399.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 399.05,	"Tipsy",		  0.0,	  0.9,	3},
		
				
--		{ 410.0,	"Tilt",			 -1.8,	  5.0,	1},
--		{ 410.0,	"Tilt",			 -1.5,	  5.0,	2},
--		{ 410.0,	"Boost",		  1.5,	  5.0,	3},
--		{ 415.0,	"Boost",		  1.0,	  1.0,	3},
--		{ 415.0,	"Tilt",			  0.5,	  0.5,	1},
--		{ 415.0,	"Tilt",			  0.4,	  0.5,	2},
--		{ 415.5,	"Tilt",			  0.0,	  0.5,	3},
		
		{ 424.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 424.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 426.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 426.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 428.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 428.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 429.0,	"Tipsy",		 -0.8,	  0.01,	3},
		{ 429.05,	"Tipsy",		  0.0,	  0.9,	3},
		{ 429.75,	"Drunk",		  0.8,	  0.01,	3},
		{ 429.8,	"Drunk",		  0.0,	  0.7,	3},
		{ 430.5,	"Drunk",		 -0.8,	  0.01,	3},
		{ 430.55,	"Drunk",		  0.0,	  0.4,	3},
		{ 431.0,	"Tipsy",		  0.8,	  0.01,	3},
		{ 431.05,	"Tipsy",		  0.0,	  0.9,	3},
		
		
		{ 432.0,	"Flip",			  0.25,	  2.0,	3},
		{ 432.0,	"Invert",		  0.25,	  2.0,	3},
		{ 436.0,	"Flip",			  0.0,	  2.0,	3},
		{ 436.0,	"Invert",		  0.0,	  2.0,	3},
		{ 438.5,	"Confusion",	 -0.001,  0.25,	3},
		{ 438.75,	"Confusion",	  0.002,  0.25,	3},
		{ 439.0,	"Confusion",	  0.0,	  0.5,	3},
		{ 442.0,	"Tilt",			 -0.9,	  5.0,	1},
		{ 442.0,	"Tilt",			 -0.8,	  5.0,	2},
		{ 442.0,	"Boost",		  1.2,	  5.0,	3},
		{ 447.0,	"Boost",		  1.0,	  1.0,	3},
		{ 447.0,	"Tilt",			  0.3,	  0.5,	1},
		{ 447.0,	"Tilt",			  0.2,	  0.5,	2},
		{ 447.5,	"Tilt",			  0.0,	  0.5,	3},
		{ 448.0,	"Flip",			  0.25,	  2.0,	3},
		{ 448.0,	"Invert",		 -0.75,	  2.0,	3},
		{ 450.0,	"Flip",			  0.0,	  0.5,	3},
		{ 450.0,	"Invert",		  0.0,	  0.5,	3},
		{ 452.0,	"Flip",			 -0.25,	  1.0,	3},
		{ 452.0,	"Invert",		  0.75,	  1.0,	3},
		{ 453.0,	"Flip",			  0.0,	  1.0,	3},
		{ 453.0,	"Invert",		  0.0,	  1.0,	3},
		{ 456.0,	"Flip",			  0.25,	  2.0,	3},
		{ 456.0,	"Invert",		  0.25,	  2.0,	3},
		{ 458.0,	"Flip",			  0.0,	  2.0,	3},
		{ 458.0,	"Invert",		  0.0,	  2.0,	3},
		
		{ 464.0,	"Dark",			  1.0,	 32.0,	3},	
		{ 464.0,	"Stealth",		  1.0,	 32.0,	3},	
		{ 464.0,	"ScrollSpeed",	cspdC,   32.0,	3}, 
		{ 464.0,	"Boost",		 -1.0,	 32.0,	3},
		
		{ 464.0,	"Flip",			  0.25,	  2.0,	3},
		{ 464.0,	"Invert",		 -0.25,	  2.0,	3},
		{ 468.0,	"Flip",			  0.0,	  2.0,	3},
		{ 468.0,	"Invert",		  0.0,	  2.0,	3},
		{ 470.5,	"Confusion",	  0.001,  0.25,	3},
		{ 470.75,	"Confusion",	 -0.002,  0.25,	3},
		{ 471.0,	"Confusion",	  0.0,	  0.5,	3},
		{ 474.0,	"Tilt",			  0.9,	  5.0,	1},
		{ 474.0,	"Tilt",			  0.8,	  5.0,	2},
--		{ 474.0,	"Boost",		  1.2,	  5.0,	3},
--		{ 479.0,	"Boost",		  1.0,	  1.0,	3},
		{ 479.0,	"Tilt",			 -0.3,	  0.5,	1},
		{ 479.0,	"Tilt",			 -0.2,	  0.5,	2},
		{ 479.5,	"Tilt",			  0.0,	  0.5,	3},
		{ 480.0,	"Flip",			  0.25,	  2.0,	3},
		{ 480.0,	"Invert",		 -0.75,	  2.0,	3},
		{ 482.0,	"Flip",			  0.0,	  0.5,	3},
		{ 482.0,	"Invert",		  0.0,	  0.5,	3},
		{ 484.0,	"Flip",			  0.5,	  1.0,	3},
		{ 484.0,	"Invert",		 -1.5,	  1.0,	3},
		{ 485.0,	"Flip",			  0.0,	  1.0,	3},
		{ 485.0,	"Invert",		  0.0,	  1.0,	3},
		{ 488.0,	"Flip",			  0.25,	  2.0,	3},
		{ 488.0,	"Invert",		 -0.25,	  2.0,	3},
		{ 490.0,	"Flip",			  0.0,	  2.0,	3},
		{ 490.0,	"Invert",		  0.0,	  2.0,	3},

	};
local modsLaunched = 0;
local modsWait = 0;
local modsLeadBy = 0.03;
	
local mods = {
	["LifeSetting"] =	"ENUM", 
	["DrainSetting"] =	"ENUM", 
--	["BatteryLives"] =	"INT", 
	["TimeSpacing"] =	"FLOAT", 
	["MaxScrollBPM"] =	"FLOAT", 
	["ScrollSpeed"] =	"FLOAT", 
	["ScrollBPM"] =		"FLOAT", 
	["Boost"] =			"FLOAT", 
	["Brake"] =			"FLOAT", 
	["Wave"] =			"FLOAT", 
	["Expand"] =		"FLOAT", 
	["Boomerang"] =		"FLOAT", 
	["Drunk"] =			"FLOAT", 
	["Dizzy"] =			"FLOAT", 
	["Confusion"] =		"FLOAT", 	-- yuck
	["Mini"] =			"FLOAT", 
	["Tiny"] =			"FLOAT", 
	["Flip"] =			"FLOAT", 
	["Invert"] =		"FLOAT", 
	["Tornado"] =		"FLOAT", 
	["Tipsy"] =			"FLOAT", 
	["Bumpy"] =			"FLOAT", 
	["Beat"] =			"FLOAT", 
	["Xmode"] =			"FLOAT", 
	["Twirl"] =			"FLOAT", 
	["Roll"] =			"FLOAT", 
	["Hidden"] =		"FLOAT", 
	["HiddenOffset"] =	"FLOAT", 
	["Sudden"] =		"FLOAT", 
	["SuddenOffset"] =	"FLOAT", 
	["Stealth"] =		"FLOAT", 
	["Blink"] =			"FLOAT", 
	["RandomVanish"] =	"FLOAT", 
	["Reverse"] =		"FLOAT", 
	["Split"] =			"FLOAT", 
	["Alternate"] =		"FLOAT", 
	["Cross"] =			"FLOAT", 
	["Centered"] =		"FLOAT", 
	["Dark"] =			"FLOAT", 
	["Blind"] =			"FLOAT", 
	["Cover"] =			"FLOAT", 
	["RandAttack"] =	"FLOAT", 
	["NoAttack"] =		"FLOAT", 
	["PlayerAutoPlay"] ="FLOAT", 
	["Skew"] =			"FLOAT", 
	["Tilt"] =			"FLOAT", 
	["Passmark"] =		"FLOAT", 
	["RandomSpeed"] =	"FLOAT", 
	["TurnNone"] =		"BOOL", 
	["Mirror"] =		"BOOL", 
	["Backwards"] =		"BOOL", 
	["Left"] =			"BOOL", 
	["Right"] =			"BOOL", 
	["Shuffle"] =		"BOOL", 
	["SoftShuffle"] =	"BOOL", 
	["SuperShuffle"] =	"BOOL", 
	["NoHolds"] =		"BOOL", 
	["NoRolls"] =		"BOOL", 
	["NoMines"] =		"BOOL", 
	["Little"] =		"BOOL", 
	["Wide"] =			"BOOL", 
	["Big"] =			"BOOL", 
	["Quick"] =			"BOOL", 
	["BMRize"] =		"BOOL", 
	["Skippy"] =		"BOOL", 
	["Mines"] =			"BOOL", 
	["AttackMines"] =	"BOOL", 
	["Echo"] =			"BOOL", 
	["Stomp"] =			"BOOL", 
	["Planted"] =		"BOOL", 
	["Floored"] =		"BOOL", 
	["Twister"] =		"BOOL", 
	["HoldRolls"] =		"BOOL", 
	["NoJumps"] =		"BOOL", 
	["NoHands"] =		"BOOL", 
	["NoLifts"] =		"BOOL", 
	["NoFakes"] =		"BOOL", 
	["NoQuads"] =		"BOOL", 
	["NoStretch"] =		"BOOL", 
	["MuteOnError"] =	"BOOL", 
	["FailSetting"] =	"ENUM", 
	["MinTNSToHideNotes"] =	"ENUM"
}
local clearAllMods = function(playerNum, justTrace)
	local currValue;
	local currApproach;
	
	playerNum = playerNum or 1
	justTrace = justTrace or false
	
	if playerNum < 1 or playerNum > 2 then do Trace("In clearAllMods: Player number "..playerNum.." is invalid!"); return end end
	pops = GAMESTATE:GetPlayerState("PlayerNumber_P"..playerNum):GetPlayerOptions("ModsLevel_Song");
	if pops then
		for modName,modType in pairs(mods) do
			currValue,currApproach = pops[modName](pops);
			-- Trace("In clearAllMods: P"..playerNum.." has mod "..modName.." set to "..tostring(currValue));
			
			if not justTrace then
				if modType == "FLOAT" then
					if modName == "ScrollBPM" then
						pops[modName](pops, 200);
					elseif modName == "ScrollSpeed" then
						pops[modName](pops, 1);
					else
						pops[modName](pops, 0);
					end
				elseif modType == "BOOL" then
					pops[modName](pops, false);
				elseif modType == "INT" then
					if modName == "BatteryLives" then
						pops[modName](pops, 4);
					else
						pops[modName](pops, 0);
					end
				else -- if modType == "ENUM" then
				end
			end
		end
	else
		Trace("In clearAllMods: Player options for "..playerNum.." are not initialized!");
	end
end

local enjoyModsHQ = Def.Quad {
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-sw,-sh)
			:visible(false);
	end,
	OnCommand = function(self)
		self:queuecommand("Update");
		clearAllMods(1);
		clearAllMods(2);
	end,
	UpdateCommand = function(self)
		-- Most things are determined by beat, believe it or not.		
		local overtime = GAMESTATE:GetSongBeat();
		
		if modsLaunched >= #modsTable then
			Trace('>>> enjoyModsHQ: Hibernated!!');
			self:hibernate(600);
			do return end
		else
			while modsLaunched < #modsTable do
				-- Trace('>>> enjoyModsHQ: ' .. modsLaunched);
				-- Check the next line of the mods table.
				nextMod = modsTable[modsLaunched + 1];
				
				if overtime + modsLeadBy >= nextMod[1] then
					-- TODO: this assumes the effect applies over a constant BPM section!!
					local BPS = GAMESTATE:GetSongBPS();
					Trace('>>> enjoyModsHQ: ' .. modsLaunched .. ' @ time = ' .. overtime);
					
					for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
						pn = tonumber(string.match(pe, "[0-9]+"));
						if (nextMod[5] == pn or nextMod[5] == 3) then
							pops = GAMESTATE:GetPlayerState(pe):GetPlayerOptions("ModsLevel_Song");
							
							-- Calculate approach (in units of the value per second):
							-- a = (value final - value initial) * (beats per second) / (beats for transition + ``machine epsilon``)
							-- Has to be done individually for each player, just in case they're coming from different initial values :(
							opVal, opApproach = pops[ nextMod[2] ]( pops );
							if opApproach == 0 then -- SOMEONE FUCKED UP AND IT WASN'T ME.
								newApproach = BPS;
							else
								newApproach = math.abs(nextMod[3] - opVal) * BPS / (nextMod[4] + 0.001);
							end
												pops[ nextMod[2] ]( pops, nextMod[3], newApproach );
							Trace('>>> enjoyModsHQ: ' .. opVal      .. ' @ rate = ' .. opApproach  .. ' for ' .. pe);
							Trace('>>> enjoyModsHQ: ' .. nextMod[3] .. ' @ rate = ' .. newApproach .. ' for ' .. pe .. ' [New!]');
						end
					end
					
					modsLaunched = modsLaunched + 1;
				else
					-- Trace('>>> enjoyModsHQ: ' .. overtime .. ' < ' .. nextMod[1]);
					break;
				end
			end
		end		
		
		-- Wait a bit and then update again!
		self:queuecommand('WaitABit');
	end,
	WaitABitCommand = function(self)
		self:sleep(0.01);
		self:queuecommand('Update');
	end
}
table.insert(theBoys, enjoyModsHQ);

-------------------------------------------------------------------------------
--
--		Everybody wants to hide the Lay's.
--
noteskinSet = nil;
local hamburgerHelper = Def.Quad {
	InitCommand = function(self)
		self:SetHeight(6)
			:SetWidth(6)
			:xy(-sw,-sh)
			:visible(false);
	end,
	OnCommand = function(self)
		local hamburger = SCREENMAN:GetTopScreen();
		
		if hamburger:GetScreenType() == "ScreenType_Gameplay" then
			hamburger:GetChild("Overlay" ):decelerate(1.0):diffusealpha(0.0);
			hamburger:GetChild("Underlay"):decelerate(1.0):diffusealpha(0.0);
		end
				
		local playersFound = 0;
		local hadToSetNoteskin = false;
		for pn = 1,2 do
			if not noteskinSet then				
				pops = GAMESTATE:GetPlayerState("PlayerNumber_P"..pn):GetPlayerOptions("ModsLevel_Preferred");
				if pops then 
					prevNS, didItWork = pops:NoteSkin("cyber");
					Trace (pn .. ": " .. prevNS .. " > " .. tostring(didItWork) .. "!!");
					if prevNS ~= "cyber" then
						hadToSetNoteskin = true;
					end
				end
			end
			
			pv = hamburger:GetChild("PlayerP"..pn);
			if pv then
				pv:GetChild("Combo"):hibernate(1573);
				playersFound = playersFound + pn;
			end
			
			pops = GAMESTATE:GetPlayerState("PlayerNumber_P"..pn):GetPlayerOptions("ModsLevel_Song");
			pops:FailSetting('FailType_Off');
		end
				
--		noteskinSet = true;
--		if hadToSetNoteskin then
--			SCREENMAN:SetNewScreen("ScreenGameplay"):StartTransitioningScreen("SM_GoToNextScreen");
--		end
		
		if playersFound == 3 then
			Trace("#### hibernate!");
			self:hibernate(6000);
		else
			-- Wait a bit and then update again!
			self:queuecommand('WaitABit');
		end
	end,	
	WaitABitCommand = function(self)
		self:sleep(0.02);
		self:queuecommand('Update');
	end
}
table.insert(theBoys, hamburgerHelper);
-------------------------------------------------------------------------------




return theBoys;

