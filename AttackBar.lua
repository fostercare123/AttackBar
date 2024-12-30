AB_extraAttacks	= 0;
AB_MH_start		= 0.000;
AB_MH_landsAt		= 0.000;
AB_OH_start		= 0.000;
AB_OH_landsAt		= 0.000;
AB_MH_speed		= nil;
AB_OH_speed		= nil;
AB_Standing		= true;

RL_PATTERN_INCOMING_MELEE_PARRY = ".* attacks. You parry.";
RL_PATTERN_INCOMING_SPECIALATTACK_PARRY = "(.*)'s (.*) [wai]+s parried.";

-- cast spell by name hook
preAB_csbn = CastSpellByName
function AB_csbn(pass, onSelf)
	preAB_csbn(pass, onSelf)
	AB_spelldir(pass)
end
CastSpellByName = AB_csbn

-- use action hook
preAB_useAction = UseAction
function AB_useAction(p1,p2,p3)
	preAB_useAction(p1,p2,p3)
    local a,b = IsUsableAction(p1)
    if a then
    	if UnitCanAttack("player","target" )then
    		if IsActionInRange(p1) == 1 then
				AB_Tooltip:ClearLines()
				AB_Tooltip:SetAction(p1)
		    	local spellname = AB_TooltipTextLeft1:GetText()
		    	if spellname then AB_spelldir(spellname) end
	    	end
    	end
    end
end
UseAction = AB_useAction

-- castspell hook
preAB_casspl = CastSpell
function AB_casspl(p1,p2)
	preAB_casspl(p1,p2)
	local spell = GetSpellName(p1,p2)
	AB_spelldir(spell)
end
CastSpell = AB_casspl

function AB_loaded()
	SlashCmdList["AB"] = AB_chat;
	SLASH_AB1 = "/ab";
	if (AB == nil) then AB={} end
	if AB.range == nil then
		AB.range=true
	end
	if AB.melee == nil then
		AB.melee=true
	end
	if AB.timer == nil then
		AB.timer=true
	end
	AB_Mhr:SetPoint("LEFT",AB_Frame,"TOPLEFT",6,-13)
	AB_MhrText:SetJustifyH("Left")
end

function AB_chat(msg)
	msg = strlower(msg)
	if msg == "reset" then
		AB_reset()
	elseif msg=="lock" then
		AB_Frame:Hide()
	elseif msg=="unlock" then
		AB_Frame:Show()
	elseif msg=="range" then
		AB.range= not(AB.range)
		DEFAULT_CHAT_FRAME:AddMessage('range is'.. AB_Boo(AB.range));
	elseif msg=="melee" then
		AB.melee = not(AB.melee)
		DEFAULT_CHAT_FRAME:AddMessage('melee is'.. AB_Boo(AB.melee));
	elseif msg=="timer" then
		AB.timer = not(AB.timer)
		DEFAULT_CHAT_FRAME:AddMessage('timer is'.. AB_Boo(AB.timer));
	else
		DEFAULT_CHAT_FRAME:AddMessage('Use any of these commands:');
		DEFAULT_CHAT_FRAME:AddMessage('unlock - Unlocks the anchor.');		
		DEFAULT_CHAT_FRAME:AddMessage('lock - Locks the anchor.');
		DEFAULT_CHAT_FRAME:AddMessage('melee - Toggle the melee bar.');
		DEFAULT_CHAT_FRAME:AddMessage('range - Toggle the ranged bar.');
		DEFAULT_CHAT_FRAME:AddMessage('reset - Resets addon. Wait 5 seconds before attacking.');
	end
end

function AB_reset()
	onid=0
	offid=0
	AB_MH_landsAt = 0.0
	AB_OH_landsAt = 0.0
	AB_MH_start = 0.0
	AB_OH_start = 0.0
	AB_extraAttacks = 0
end

function AB_event(event)
	if (event == "CHAT_MSG_SPELL_SELF_BUFF" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS") and AB.melee == true then
		if ( string.find( arg1, "You gain 1 extra attack" ) ) then
			AB_extraAttacks = 1;
		elseif ( string.find( arg1, "Fury of Forgewright" ) ) then
			AB_extraAttacks = 2;
		end
		-- In case we GAINED a speed-affecting aura
		if (oldMHSpeed == nil) then return end
		local oldMHSpeed = AB_MH_speed
		local oldOHSpeed = AB_OH_speed
		AB_MH_speed, AB_OH_speed = UnitAttackSpeed("player");
		if (oldMHSpeed ~= AB_MH_speed) then
			AB_currentTime = GetTime();
			local timeLeftMH = (AB_MH_landsAt - AB_currentTime) / (oldMHSpeed / AB_MH_speed)
			AB_MH_landsAt = AB_currentTime + timeLeftMH;
			AB_UpdateMHSwingBar(AB_currentTime,"Main-hand",0,0,1);
			if (AB_OH_speed ~= nil) then
				local timeLeftOH = (AB_OH_landsAt - AB_currentTime) / (oldOHSpeed / AB_OH_speed)
				AB_OH_landsAt = AB_currentTime + timeLeftOH;
			end
		end
	elseif (event == "CHAT_MSG_SPELL_AURA_GONE_SELF" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE") and AB.melee == true then
		-- In case we lost a speed-affecting aura or gained a speed-affecting debuff
		if (oldMHSpeed == nil) then return end
		local oldMHSpeed = AB_MH_speed
		local oldOHSpeed = AB_OH_speed
		AB_MH_speed, AB_OH_speed = UnitAttackSpeed("player");
		if (oldMHSpeed ~= AB_MH_speed) then
			AB_currentTime = GetTime();
			local timeLeftMH = (AB_MH_landsAt - AB_currentTime) / (oldMHSpeed / AB_MH_speed)
			AB_MH_landsAt = AB_currentTime + timeLeftMH;
			AB_UpdateMHSwingBar(AB_currentTime,"Main-hand",0,0,1);
			if (AB_OH_speed ~= nil) then
				local timeLeftOH = (AB_OH_landsAt - AB_currentTime) / (oldOHSpeed / AB_OH_speed)
				AB_OH_landsAt = AB_currentTime + timeLeftOH;
			end
		end
	elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES" or event == "CHAT_MSG_COMBAT_SELF_HITS") and AB.melee == true then
		AB_currentTime = GetTime();
		AB_MH_speed, AB_OH_speed = UnitAttackSpeed("player");
		if (AB_currentTime >= AB_MH_landsAt + 0.3) then AB_MH_landsAt = 0 end
		if (AB_currentTime >= AB_OH_landsAt + 0.3) then AB_OH_landsAt = 0 end
		if (AB_MH_landsAt == 0) then AB_MH_landsAt = AB_currentTime; end
		if (AB_OH_landsAt == 0) then AB_OH_landsAt = AB_currentTime; end
		if (AB_OH_speed == nil) then AB_OH_landsAt = AB_currentTime + 1000000; end
		if (AB_extraAttacks > 0 or AB_MH_landsAt <= AB_OH_landsAt) then	-- This attack is a main-hand attack
			-- Print("MH "..AB_currentTime.." ("..AB_MH_landsAt.." | "..AB_OH_landsAt..")");
			if (AB_extraAttacks > 0) then AB_extraAttacks = AB_extraAttacks - 1; end
			AB_MH_start = AB_currentTime;
			AB_MH_landsAt = AB_MH_start + AB_MH_speed;
			if (AB_OH_landsAt < AB_currentTime + 0.2) then
				AB_OH_landsAt = AB_currentTime + 0.2;
			end
			AB_UpdateMHSwingBar(AB_currentTime,"MH",0,0,1)
		else	-- This attack is an off-hand attack
			-- Print("OH "..AB_currentTime.." ("..AB_MH_landsAt.." | "..AB_OH_landsAt..")");
			AB_OH_start = AB_currentTime;
			AB_OH_landsAt = AB_OH_start + AB_OH_speed;
			if (AB_MH_landsAt < AB_currentTime + 0.2) then
				AB_MH_landsAt = AB_currentTime + 0.2;
			end
		end
	elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" or event == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE") then
		AB_Standing = true;
		if ( string.find( arg1, RL_PATTERN_INCOMING_MELEE_PARRY ) or string.find( arg1, RL_PATTERN_INCOMING_SPECIALATTACK_PARRY ) ) then	-- Player parried an attack or a special attack
			AB_currentTime = GetTime();
			-- AB_MH_speed, AB_OH_speed = UnitAttackSpeed("player");
			AB_MH_swingTimeLeft = AB_MH_landsAt - AB_currentTime;
			AB_OH_swingTimeLeft = AB_OH_landsAt - AB_currentTime;
			if (AB_MH_swingTimeLeft <= AB_OH_swingTimeLeft) then
				if (AB_MH_swingTimeLeft / (AB_MH_landsAt - AB_MH_start) > 0.6) then
					AB_MH_landsAt = AB_MH_landsAt - (AB_MH_landsAt - AB_MH_start) * 0.4;
				elseif (AB_MH_swingTimeLeft / (AB_MH_landsAt - AB_MH_start) >= 0.2) then
					AB_MH_landsAt = (AB_MH_landsAt - AB_MH_start) * 0.2;
				end
			else
				if (AB_OH_swingTimeLeft / (AB_OH_landsAt - AB_OH_start) > 0.6) then
					AB_OH_landsAt = AB_OH_landsAt - (AB_OH_landsAt - AB_OH_start) * 0.4;
				elseif (AB_OH_swingTimeLeft / (AB_OH_landsAt - AB_OH_start) >= 0.2) then
					AB_OH_landsAt = (AB_OH_landsAt - AB_OH_start) * 0.2;
				end
			end
			AB_UpdateMHSwingBar(AB_currentTime,"Main-hand",0,0,1)
		end
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		AB_spellhit(arg1)
	elseif event == "PLAYER_LEAVE_COMBAT" then
		AB_reset()
	elseif event == "VARIABLES_LOADED" then
		AB_loaded()
	end
end

function AB_spellhit(arg1)
	a,b,spell=string.find (arg1, "Your (.+) hits")
	if not spell then 	a,b,spell=string.find (arg1, "Your (.+) crits") end
	if not spell then 	a,b,spell=string.find (arg1, "Your (.+) is") end
	if not spell then	a,b,spell=string.find (arg1, "Your (.+) misses") end
		
	rs,rhd,rld = UnitRangedDamage("player");
	rhd,rld = rhd-math.mod(rhd,1),rld-math.mod(rld,1)
	if spell == "Auto Shot" and AB.range == true then
		trs=rs
		rs = rs-math.mod(rs,0.01)
		AB_MH_start = GetTime()
		AB_MH_landsAt = GetTime() + trs
		AB_UpdateMHSwingBar(AB_MH_start,"Auto Shot["..rs.."s]("..rhd.."-"..rld..")",0,1,0)
	elseif spell == "Shoot" and AB.range==true then
		trs=rs
		rs = rs-math.mod(rs,0.01)
		AB_MH_start = GetTime()
		AB_MH_landsAt = GetTime() + trs
		AB_UpdateMHSwingBar(AB_MH_start,"Wand",.7,.1,1)
	elseif (spell == "Raptor Strike" or spell == "Heroic Strike" or	spell == "Maul" or spell == "Cleave" or spell == "Slam") and AB.melee==true then
		hd,ld,ohd,lhd = UnitDamage("player")
		hd,ld= hd-math.mod(hd,1),ld-math.mod(ld,1)
		AB_currentTime = GetTime()
		AB_MH_speed, AB_OH_speed = UnitAttackSpeed("player");
		if (AB_currentTime >= AB_MH_landsAt + 0.3) then AB_MH_landsAt = 0 end
		if (AB_currentTime >= AB_OH_landsAt + 0.3) then AB_OH_landsAt = 0 end
		if (AB_MH_landsAt == 0) then AB_MH_landsAt = AB_currentTime; end
		if (AB_OH_landsAt == 0) then AB_OH_landsAt = AB_currentTime; end
		if (AB_OH_speed == nil) then AB_OH_landsAt = AB_currentTime + 1000000; end
		AB_MH_start = AB_currentTime;
		AB_MH_landsAt = AB_MH_start + AB_MH_speed;
		if (AB_OH_landsAt < AB_currentTime + 0.2) then
			AB_OH_landsAt = AB_currentTime + 0.2;
		end
		-- Print(AB_currentTime.." | "..AB_MH_landsAt.." | "..AB_OH_landsAt)
		AB_UpdateMHSwingBar(AB_currentTime,"Main-hand",0,0,1);
	end
end

function AB_spelldir(spellname)
	if AB.range then
		local a,b,sparse = string.find (spellname, "(.+)%(")
		if sparse then spellname = sparse end
		rs,rhd,rld = UnitRangedDamage("player");
		rhd,rld = rhd-math.mod(rhd,1),rld-math.mod(rld,1);
		if spellname == "Throw" then
			trs=rs
			rs = rs-math.mod(rs,0.01)
			AB_MH_start = GetTime() - 1
			AB_MH_landsAt = GetTime() + trs
			AB_UpdateMHSwingBar(AB_MH_start,"Thrown["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Shoot" then
			rs =UnitRangedDamage("player")
			trs=rs
			rs = rs-math.mod(rs,0.01)
			AB_MH_start = GetTime() - 1
			AB_MH_landsAt = GetTime() + trs
			AB_UpdateMHSwingBar(AB_MH_start,"Wand["..(rs).."s]("..rhd.."-"..rld..")",.5,0,1)
		elseif spellname == "Shoot Bow" then
			trs = rs
			rs = rs-math.mod(rs,0.01)
			AB_MH_start = GetTime() - 1
			AB_MH_landsAt = GetTime() + trs
			AB_UpdateMHSwingBar(AB_MH_start,"Bow["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Shoot Gun" then
			trs = rs
			rs = rs-math.mod(rs,0.01)
			AB_MH_start = GetTime() - 1
			AB_MH_landsAt = GetTime() + trs
			AB_UpdateMHSwingBar(AB_MH_start,"Gun["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Shoot Crossbow" then
			trs=rs
			rs = rs-math.mod(rs,0.01)
			AB_MH_start = GetTime() - 1
			AB_MH_landsAt = GetTime() + trs
			AB_UpdateMHSwingBar(AB_MH_start,"X-Bow["..(rs).."s]("..rhd.."-"..rld..")",1,.5,0)
		elseif spellname == "Aimed Shot" then
			trs=rs
			rs = rs-math.mod(rs,0.01)
			AB_MH_start = GetTime() - 1
			AB_MH_landsAt = GetTime() + trs
			AB_UpdateMHSwingBar(AB_MH_start,"Aiming["..(3).."s]",1,.1,.1) 
		end
	end
end

function AB_UpdateBar()
	local ttime = GetTime()
	local left = 0.00
	tSpark=getglobal(this:GetName().. "Spark")
	tText=getglobal(this:GetName().. "Tmr")
	if AB.timer==true then
		left = (this.et-GetTime()) - (math.mod((this.et-GetTime()),.1))
		local text = left
		if (this.spd ~= nil) then text = text.." / "..(math.floor(this.spd*10)/10.0) end
		tText:SetText(""..text.."")
		tText:Show()
	else
		tText:Hide()
	end
	this:SetValue(ttime)
	tSpark:SetPoint("CENTER", this, "LEFT", (ttime-this.st)/(this.et-this.st)*195, 2);
	if ttime>=this.et then 
		this:Hide() 
		tSpark:SetPoint("CENTER", this, "LEFT",195, 2);
	end
end

function AB_UpdateMHSwingBar(currentTime,text,r,g,b)
	AB_Mhr:Hide()
	AB_Mhr.txt = text
	AB_Mhr.st = AB_MH_start
	AB_Mhr.et = AB_MH_landsAt
	AB_Mhr:SetStatusBarColor(0.4,1.0,1.0)
	AB_MhrText:SetText(text)
	AB_Mhr:SetMinMaxValues(AB_Mhr.st,AB_Mhr.et)
	AB_Mhr:SetValue(currentTime)
	AB_Mhr:Show()
end

function AB_Boo(inpt)
	if inpt == true then return " ON" else return " OFF" end
end