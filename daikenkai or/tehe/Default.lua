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

tehe_beat_start = 216
tehe_beat_cross = 223
tehe_beat_end = 225
tehe_distance_px = SCREEN_HEIGHT * 1.1

tehe_rotations = 3
tehe_past_receptor = 0.1
tehe_notes = {}

tehe_error = false

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

local lane_permute = function(pops, l)
	-- Which lane is the desired arrow in?
	-- Account for Left, Right, and Mirror.
	-- Otherwise I honestly don't give heck. You are on your lonesome binch. Tohoku Evolved up in this jawn
	local lanes = {1, 2, 3, 4}

	if pops:Mirror() 	then lanes = {lanes[4], lanes[3], lanes[2], lanes[1]} end
	if pops:Left()		then lanes = {lanes[2], lanes[4], lanes[1], lanes[3]} end
	if pops:Right() 	then lanes = {lanes[3], lanes[1], lanes[4], lanes[2]} end

	return lanes[l]
end
local lane_rotation = {90, 0, 180, 270}

local calc_xmod = function(pops, BPS)
	-- Convert tehe approach distance into (approximate) beats by using the scroll speed.
	-- Any boost-style mods will heckify this up
	local xmod 	= pops:XMod()
	local mmod 	= pops:MMod()
	local cmod	= pops:CMod()
	if mmod then
		return mmod / (BPS * 60)
	end
	if xmod then
		return xmod
	end
	if cmod then
		return cmod / (BPS * 60)
	end
end

local tehe_update_function = function()
	local status, errmsg = pcall( function() -- begin pcall()
		for idx,act in pairs(tehe_notes) do
			local ps 	= GAMESTATE:GetPlayerState('PlayerNumber_P'..idx)
			local pp 	= SCREENMAN:GetTopScreen():GetChild('PlayerP'..idx)
			local pops 	= ps:GetPlayerOptions("ModsLevel_Song")

			local sp 	= ps:GetSongPosition()
			local beat 	= sp:GetSongBeat()
			local BPS 	= sp:GetCurBPS()
			local mrate	= GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate()
			local scl_m = 1.0 - 0.5*pops:Mini()		-- Scaling of notes due to application of Mini
			local lperm = lane_permute(pops, 3)		-- Where does the "up arrow" land?

			local scl_w = 1.0
			-- local scl_w = ArrowEffects.GetZoom(ps, y_off, 3)
			-- why is the order of parameters different!!
			-- (currently don't care because no application of Tiny to account for)

			local scroll_speed = calc_xmod(pops, BPS)
			local tehe_distance = tehe_distance_px / (scroll_speed * mrate * 64 * scl_m)
			--Trace("$$$ P"..idx.."'s scroll_speed = "..scroll_speed)

			if (beat >= tehe_beat_start and beat < tehe_beat_cross) then
				-- Parabolic approach phase:
				--		Swing up to and past the receptors before making contact
				--		Start with high rotation and un-rotate as it goes 
				--		Fade in really quickly
				local tw 		= (beat - tehe_beat_start) / (tehe_beat_cross - tehe_beat_start)
				local fake_beat = offset_parabola(tw, tehe_past_receptor) * tehe_distance + tehe_beat_start
				local y_off = ArrowEffects.GetYOffset(ps, lperm, fake_beat) - ArrowEffects.GetYOffset(ps, lperm, tehe_beat_start)
				local pos_x = ArrowEffects.GetXPos(ps, lperm, y_off) * scl_w * scl_m + pp:GetX()
				local pos_y = ArrowEffects.GetYPos(ps, lperm, y_off) * scl_w * scl_m + pp:GetY()
				local pos_z = ArrowEffects.GetZPos(ps, lperm, y_off) * scl_w * scl_m + pp:GetZ()
				local rot_w = 360 * tehe_rotations * (1 - tw)*(1 - tw)

				--Trace("!!! approach "..idx.." @ "..fake_beat.." -> "..y_off.." ("..pos_x..", "..pos_y..", "..pos_z..") x "..scl_m)

				act:visible(true)
				act:diffusealpha(1 - math.pow(1 - tw, 6.0))
				act:xy(pos_x, pos_y)
				act:z(pos_z)
				act:baserotationz(lane_rotation[lperm])
				act:rotationx(rot_w * 0.7)
				act:rotationy(rot_w * 0.8)
				act:rotationz(rot_w)
				act:zoom(scl_w * scl_m)
			elseif (beat >= tehe_beat_cross and beat < tehe_beat_end) then
				-- Linear fadeout phase:
				--		Leave the receptor in reverse with the same speed as the end of the parabola
				--		Don't rotate
				--		Fade out slowly
				local tw 		= (beat - tehe_beat_cross) / (tehe_beat_cross - tehe_beat_start)
				local tw_alpha 	= (beat - tehe_beat_cross) / (tehe_beat_end - tehe_beat_cross)
				local fake_beat = offset_parabola_outline(tw, tehe_past_receptor) * tehe_distance + tehe_beat_cross
				local y_off = ArrowEffects.GetYOffset(ps, lperm, fake_beat) - ArrowEffects.GetYOffset(ps, lperm, tehe_beat_cross)
				local pos_x = ArrowEffects.GetXPos(ps, lperm, y_off) * scl_w * scl_m + pp:GetX()
				local pos_y = ArrowEffects.GetYPos(ps, lperm, y_off) * scl_w * scl_m + pp:GetY()
				local pos_z = ArrowEffects.GetZPos(ps, lperm, y_off) * scl_w * scl_m + pp:GetZ()

				--Trace("!!! reproach "..idx.." @ "..fake_beat.." -> "..y_off.." ("..pos_x..", "..pos_y..", "..pos_z..") x "..scl_m)

				act:visible(true)
				act:diffusealpha(1-tw_alpha*tw_alpha)
				act:xy(pos_x, pos_y)
				act:z(pos_z)
				act:baserotationz(lane_rotation[lperm])
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
		if not tehe_error then
			Trace('### OOPS TELP HAS MADE A FUCKO BOINGO (in update function)')
			Trace('### '..errmsg)
		end
	end
end

for _,pe in pairs(GAMESTATE:GetEnabledPlayers()) do
	pn = tonumber(string.match(pe, "[0-9]+"));
	
	pops = GAMESTATE:GetPlayerState(pe):GetPlayerOptions("ModsLevel_Song");
	noteskinName = pops:NoteSkin();
	
	tehe[#tehe+1] = NOTESKIN:LoadActorForNoteSkin("Down", "Tap Note", noteskinName)..{
		Name="TeheP"..pn,
		InitCommand=function(self)
		end,
		OnCommand=function(self)
			local i = tonumber(string.match(self:GetName(), "([0-9]+)"))

			-- Only create a tehe if the player is on SH or SX.
			local diff = GAMESTATE:GetCurrentSteps(i-1):GetDifficulty()
			local stype = GAMESTATE:GetCurrentSteps(i-1):GetStepsType()
			if stype == 'StepsType_Dance_Single' and (diff == 'Difficulty_Challenge' or diff == 'Difficulty_Hard') then
				tehe_notes[i] = self
			else
				self:visible(false)
			end
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
