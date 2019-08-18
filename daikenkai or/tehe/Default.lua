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

tehe_beat_start = 4
tehe_beat_cross = 12
tehe_beat_end = 14
tehe_distance_px = SCREEN_HEIGHT * 1.1

tehe_rotations = 3
tehe_past_receptor = 0.1
tehe_notes = {}

local offset_parabola = function(t, w)
	local A = 1 + 2*w + math.sqrt(4*(w + w*w))
	local v = math.sqrt((1 + w)/A)
	return A*(t - v)*(t - v) - w
end
local offset_parabola_outline = function(t, w)
	local A = 1 + 2*w + math.sqrt(4*(w + w*w))
	local v = math.sqrt((1 + w)/A)
	return 2*A*(1 - v)*t
end

local tehe_update_function = function()
	local status, errmsg = pcall( function() -- begin pcall()
		for idx,act in ipairs(tehe_notes) do
			local ps 	= GAMESTATE:GetPlayerState('PlayerNumber_P'..idx)
			local pp 	= SCREENMAN:GetTopScreen():GetChild('PlayerP'..idx)
			local pops 	= ps:GetPlayerOptions("ModsLevel_Song")

			local sp 	= ps:GetSongPosition()
			local beat 	= sp:GetSongBeat()
			local BPS 	= sp:GetCurBPS()
			local mrate	= GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate()
			local scl_m = 1.0 - 0.5*pops:Mini()

			-- Trace("!!! who is "..idx)

			local scroll_type 		= "x"
			local scroll_speed 		= 1
			local xmod 	= pops:XMod()
			local mmod 	= pops:MMod()
			local cmod	= pops:CMod()
			if xmod then
				scroll_speed = xmod
			end
			if mmod then
				scroll_speed = mmod / (BPS * 60)
			end
			if cmod then
				scroll_speed = cmod / (BPS * 60)
			end
			Trace("$$$ scroll_speed = "..scroll_speed)

			local tehe_distance = tehe_distance_px / (scroll_speed * 64 * scl_m)

			if (beat >= tehe_beat_start and beat < tehe_beat_cross) then
				local tw 		= (beat - tehe_beat_start) / (tehe_beat_cross - tehe_beat_start)
				local fake_beat = offset_parabola(tw, tehe_past_receptor) * tehe_distance + tehe_beat_start
				local y_off = ArrowEffects.GetYOffset(ps, 3, fake_beat) - ArrowEffects.GetYOffset(ps, 3, tehe_beat_start)	-- SPECIFICALLY the up arrow.
				local scl_w = 1.0 --ArrowEffects.GetZoom(ps, y_off, 3)	-- why is the order of parameters different!!
				local pos_x = ArrowEffects.GetXPos(ps, 3, y_off) * scl_w * scl_m + pp:GetX()
				local pos_y = ArrowEffects.GetYPos(ps, 3, y_off) * scl_w * scl_m + pp:GetY()
				local pos_z = ArrowEffects.GetZPos(ps, 3, y_off) * scl_w * scl_m + pp:GetZ()
				local rot_w = 360 * tehe_rotations * (1 - tw)*(1 - tw)

				Trace("!!! approach "..idx.." @ "..fake_beat.." -> "..y_off.." ("..pos_x..", "..pos_y..", "..pos_z..") x "..scl_m)

				act:visible(true)
				act:diffusealpha(1 - math.pow(1 - tw, 6.0))
				act:xy(pos_x, pos_y)
				act:z(pos_z)
				act:rotationx(rot_w * 0.7)
				act:rotationy(rot_w * 0.8)
				act:rotationz(rot_w)
				act:zoom(scl_w * scl_m)
			elseif (beat >= tehe_beat_cross and beat < tehe_beat_end) then
				local tw 		= (beat - tehe_beat_cross) / (tehe_beat_cross - tehe_beat_start)
				local tw_alpha 	= (beat - tehe_beat_cross) / (tehe_beat_end - tehe_beat_cross)
				local fake_beat = offset_parabola_outline(tw, tehe_past_receptor) * tehe_distance + tehe_beat_cross
				local y_off = ArrowEffects.GetYOffset(ps, 3, fake_beat) - ArrowEffects.GetYOffset(ps, 3, tehe_beat_cross)	-- SPECIFICALLY the up arrow.
				local scl_w = 1.0 --ArrowEffects.GetZoom(ps, y_off, 3)	-- why is the order of parameters different!!
				local pos_x = ArrowEffects.GetXPos(ps, 3, y_off) * scl_w * scl_m + pp:GetX()
				local pos_y = ArrowEffects.GetYPos(ps, 3, y_off) * scl_w * scl_m + pp:GetY()
				local pos_z = ArrowEffects.GetZPos(ps, 3, y_off) * scl_w * scl_m + pp:GetZ()

				Trace("!!! reproach "..idx.." @ "..fake_beat.." -> "..y_off.." ("..pos_x..", "..pos_y..", "..pos_z..") x "..scl_m)

				act:visible(true)
				act:diffusealpha(1-tw_alpha*tw_alpha)
				act:xy(pos_x, pos_y)
				act:z(pos_z)
				act:rotationx(0)
				act:rotationy(0)
				act:rotationz(0)
				act:zoom(scl_w * scl_m)
			else
				--Trace ("!!! haha bye")
				act:visible(false)
			end
		end
	end -- end pcall()
	)
	if status then
		--Trace('### YAY TELP DID NOT MAKE A FUCKY WUCKY')
	else
		Trace('### OOPS TELP HAS MADE A FUCKO BOINGO (in update function)')
		Trace('### '..errmsg)
	end
end

for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
	pn = tonumber(string.match(pe, "[0-9]+"));
	
	pops = GAMESTATE:GetPlayerState(pe):GetPlayerOptions("ModsLevel_Song");
	noteskinName = pops:NoteSkin();
	
	tehe[#tehe+1] = NOTESKIN:LoadActorForNoteSkin("Down", "Tap Note", noteskinName)..{
		Name="TeheP"..pn,
		InitCommand=function(self)
			self:baserotationz(180)
		end,
		OnCommand=function(self)
			local i = tonumber(string.match(self:GetName(), "([0-9]+)"))
			tehe_notes[i] = self
		end,
	}
end

tehe[#tehe+1] = Def.ActorFrame {
	Name="Update",
	InitCommand=function(self)	
		Trace("### im alive")
		self:SetUpdateFunction(tehe_update_function)
	end,

	Def.ActorFrame {
		InitCommand = function(self)
			self:sleep(69420)
		end
	}
}

return tehe
