local version = tonumber(io.open(hanbot.luapath .. '/dAnivia/version', 'r'):read('*a'))


local updater = module.load("dAnivia", "updater")
--Auto update dAnivia
updater.davidev_update("dAnivia", version, hanbot.luapath)


local avada_lib = module.lib("avada_lib")
if not avada_lib then
	console.set_color(12)
	print("You need to have Avada Lib in your community_libs folder to run 'dAnivia'!")
	print("You can find it here:")
	console.set_color(11)
	print("https://git.soontm.net/avada/avada_lib/archive/master.zip")
	console.set_color(15)
	return
end

local preds = module.internal("pred")
local TS = module.internal("TS")
local orb = module.internal("orb")

local common = avada_lib.common
local dmglib = avada_lib.damageLib

local QMissile, RMissile
local QMANA , WMANA , EMANA , RMANA = 0

--spell
local spellQ = {
	range = 1075,
	delay = 0.25,
	speed = 850,
	width = 125,
	boundingRadiusMod = 0
}

local spellW = {
	range = 1000,
	delay = 0.6,
	width = 1,
	speed = math.huge,
	boundingRadiusMod = 0
}

local spellE = {
	range = 650,
	speed = 1600
}
local spellR = {
	range = 750,
	delay = 0.5,
	speed = math.huge,
	width = 200,
	boundingRadiusMod = 0
}
--spell


local menu = menu("davidevAnivia", "dAnivia")
menu:menu("q", "Q Settings")
menu.q:boolean("autoQ", "Auto Q", true)
menu.q:boolean("AGCQ", "Q gapcloser", false)
menu.q:boolean("harassQ", "Harass Q", true)
menu:menu("w", "W Settings")
menu.w:boolean("autoW", "Auto W", true)
menu.w:boolean("AGCW", "AntiGapcloser W", false)
menu:menu("e", "E Settings")
menu.e:boolean("autoE", "Auto E", true)
menu:menu("r", "R Settings")
menu.r:boolean("autoR", "Auto R", true)
menu:menu("harass", "Harass")
local enemies = common.GetEnemyHeroes()
for i = 1, #enemies do
	local hero = enemies[i]
	menu.harass:boolean("harass" .. hero.charName, hero.charName, true)
end
menu:menu("farm", "Farm")
menu.farm:boolean("spellFarm", "Active", true)
menu.farm:slider("LCminions", "Lane clear minimum minions", 2,0,10,1)
menu.farm:slider("Mana", "LaneClear Mana", 50,0,100,1)
menu.farm:boolean("farmE", "Lane Clear E", false)
menu.farm:boolean("farmR", "Lane Clear R", false)
menu.farm:boolean("jungleQ", "Jungle Clear Q", true)
menu.farm:boolean("jungleW", "Jungle Clear W", true)
menu.farm:boolean("jungleE", "Jungle Clear E", true)
menu.farm:boolean("jungleR", "Jungle Clear R", true)
menu:boolean("harassHybrid", "Spell-harass only in hybrid mode", false)
menu:boolean("AACombo", "Disable AA if can use E", true)
menu:boolean("manaDisable", "Disable mana manager in combo", false)



TS.load_to_menu(menu)
local TargetSelection = function(res, obj, dist)
	if dist < spellQ.range then
		res.obj = obj
		return true
	end
end

local GetTargetQ = function()
	return TS.get_result(TargetSelection).obj
end

local TargetSelectionR = function(res, obj, dist)
	if dist < spellR.range + 400 then
		res.obj = obj
		return true
	end
end

local GetTargetR = function()
	return TS.get_result(TargetSelectionR).obj
end

local TargetSelectionE = function(res, obj, dist)
	if dist < spellE.range then
		res.obj = obj
		return true
	end
end

local GetTargetE = function()
	return TS.get_result(TargetSelectionE).obj
end

local TargetSelectionW = function(res, obj, dist)
	if dist < spellW.range then
		res.obj = obj
		return true
	end
end

local GetTargetW = function()
	return TS.get_result(TargetSelectionW).obj
end

local Harass
local None

local function CreateObj(obj)
	if obj == nil then return end
	
		if obj and obj.name and obj.type then		
        if obj.name == "Anivia_Base_Q_AOE_Mis" then
            QMissile = obj
        end
        if obj.name == "Anivia_Base_R_AOE_Green" then
            RMissile = obj
        end

	end
end

local function DeleteObj(obj)
	if obj == nil then return end

		if obj and obj.name and obj.type then
        if obj.name == "Anivia_Base_Q_AOE_Mis" then
            QMissile = nil
        end
        if obj.name == "Anivia_Base_R_AOE_Green" then
            RMissile = nil
        end
	end
end
-- Returns buff.obj if @target has @buffname
function GetBuff(target, buffname)
  local bname = string.lower(buffname)
  if target.buff[bname] then
    return target.buff[bname]
  end
  return false
end

local function SetMana()
	if (menu.manaDisable:get() and orb.menu.combat:get()) or common.GetPercentHealth() < 20 then
		QMANA = 0
		WMANA = 0
		EMANA = 0
		RMANA = 0
		return
	end
	
	QMANA = player.manaCost0
	WMANA = player.manaCost1
    EMANA = player.manaCost2
	
	if player:spellSlot(3).state ~= 0 then
	--print(QMANA - player.parRegenRate * player:spellSlot(0).cooldown)
		RMANA = QMANA - player.parRegenRate * player:spellSlot(0).cooldown
	else
		RMANA = player.manaCost3
	end

end

local function UnderTurret(pos,Addrange)
	local p = pos or player.pos
	if common.is_under_tower(p) then
		return true
	else 
		return false
	end
	
end

local function LogicQ()
	local t = GetTargetQ()
	
	if common.IsValidTarget(t) then
		if orb.menu.combat:get() and player.mana > EMANA + QMANA - 10 then
			local pos = preds.linear.get_prediction(spellQ, t)
			if pos then
				local poss = vec3(pos.endPos.x, t.pos.y, pos.endPos.y)
				player:castSpell("pos", 0, poss)
			end
		elseif Harass and menu.q.harassQ:get() and menu.harass["harass"..t.charName]:get() and player.mana > RMANA + EMANA + QMANA + WMANA and not UnderTurret() then			
			local pos2 = preds.linear.get_prediction(spellQ, t)
			if pos2 then
				local poss2 = vec3(pos2.endPos.x, t.pos.y, pos2.endPos.y)
				player:castSpell("pos", 0, poss2)
			end
		else
			local qDmg = dmglib.GetSpellDamage(0,t)
			local eDmg = dmglib.GetSpellDamage(2,t)
			if qDmg > common.GetShieldedHealth("AP", t) then
				local pos22 = preds.linear.get_prediction(spellQ, t)
				if pos22 then
					local poss22 = vec3(pos22.endPos.x, t.pos.y, pos22.endPos.y)
					player:castSpell("pos", 0, poss22)
				end
			elseif qDmg + eDmg > common.GetShieldedHealth("AP", t) and player.mana > QMANA + EMANA then
				local pos222 = preds.linear.get_prediction(spellQ, t)
				if pos222 then
					local poss2222 = vec3(pos222.endPos.x, t.pos.y, pos222.endPos.y)
					player:castSpell("pos", 0, poss2222)
				end
			end			
		end
		if not None and player.mana > RMANA + EMANA then
			for i = 0, objManager.enemies_n - 1 do
				local enemy = objManager.enemies[i]
				if common.IsValidTarget(enemy) and enemy.pos:dist(player.pos) <= spellQ.range and not common.CanPlayerMove(enemy) then
					player:castSpell("pos", 0 , vec3(enemy.pos.x,player.pos.y,enemy.pos.y))
				end
			end
		end
	end
end

local function count_minions_in_range(pos, range)
	local enemies_in_range = {}
	for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
		local enemy = objManager.minions[TEAM_ENEMY][i]
		if pos:dist(enemy.pos) < range and common.IsValidTarget(enemy) then
			enemies_in_range[#enemies_in_range + 1] = enemy
		end
	end
	return enemies_in_range
end

local function LogicR()
	if RMissile == nil then
		local t = GetTargetR()
		if(common.IsValidTarget(t) and t.type == TYPE_HERO and player.pos:dist(t.pos) < spellR.range) then
			if dmglib.GetSpellDamage(3,t) > common.GetShieldedHealth("AP", t) then
				player:castSpell("obj", 3, t)
			elseif player.mana > RMANA + EMANA and dmglib.GetSpellDamage(2,t) * 2 + dmglib.GetSpellDamage(3,t) > common.GetShieldedHealth("AP", t) then
				player:castSpell("obj", 3, t)
			end
			if player.mana > RMANA + EMANA + QMANA + WMANA and orb.menu.combat:get() then
				player:castSpell("obj", 3, t)
			end
		end
		if orb.menu.lane_clear:get() and menu.farm.spellFarm:get() and menu.farm.farmR:get() and common.GetPercentMana() > menu.farm.Mana:get() then
			local enemyMinionsR = common.GetMinionsInRange(spellR.range, TEAM_ENEMY)
			for i, minion in pairs(enemyMinionsR) do
				if minion and minion.path.count == 0 and not minion.isDead and common.IsValidTarget(minion) then
						local minionPos = vec3(minion.x, minion.y, minion.z)
						if minionPos then
							if
								#count_minions_in_range(minionPos, spellR.width) >= menu.farm.LCminions:get()
							 then
								local seg = preds.circular.get_prediction(spellR, minion)
								if seg and seg.startPos:dist(seg.endPos) < spellR.range then
									player:castSpell("pos", 3, vec3(seg.endPos.x, minionPos.y, seg.endPos.y))
								end
							end
						end
					end
			end
		end
	else
		if orb.menu.lane_clear:get() and menu.farm.spellFarm:get() and menu.farm.farmR:get() then
			local allMinions = #common.GetMinionsInRange(spellR.width, TEAM_ENEMY, RMissile.pos)
			local mobs = #common.GetMinionsInRange(spellR.width, TEAM_NEUTRAL, RMissile.pos)
			if mobs > 0 then
				if not menu.farm.jungleR:get() then
					player:castSpell("self", 3)
				end
			elseif allMinions > 0 then
				if allMinions < 2 or common.GetPercentMana() < menu.farm.Mana:get() then
					player:castSpell("self", 3)
				elseif common.GetPercentMana() < menu.farm.Mana:get()  then
					player:castSpell("self", 3)
				end
			else
				player:castSpell("self", 3)
			end			
		elseif not None and (#common.GetEnemyHeroesInRange(470, RMissile.pos) == 0 or player.mana < EMANA + QMANA) then
			player:castSpell("self", 3)
		end
	end
end

local function farmE()
	if orb.menu.lane_clear:get() and common.GetPercentMana() > menu.farm.Mana:get() and menu.farm.spellFarm:get() and menu.farm.farmE:get() and not orb.core.can_attack() then
		local enemyMinionsE = common.GetMinionsInRange(spellE.range, TEAM_ENEMY)
		for i, minion in pairs(enemyMinionsE) do
			if minion.health > common.CalculateAADamage(minion) and common.IsValidTarget(minion) then
				local eDMG = dmglib.GetSpellDamage(2, minion) * 2
				if minion.health < eDMG and GetBuff(minion, "chilled") then
					player:castSpell("obj", 2, minion)
				end
			end
		end
	end
end

local function LogicE()
	local t = GetTargetE()
	if common.IsValidTarget(t) and t.type == TYPE_HERO and player.pos:dist(t.pos) < spellE.range) then
		local qCd = player:spellSlot(0).cooldown
		local eCd = player:spellSlot(2).cooldown
		local rCd = player:spellSlot(3).cooldown
		
		local eDmg = dmglib.GetSpellDamage(2,t)
		
		if eDmg > common.GetShieldedHealth("AP", t) then
			player:castSpell("obj", 2, t)			
		end
		
		if GetBuff(t,"chilled") or qCd > eCd - 1 and rCd > eCd - 1 then
			if eDmg * 3 > common.GetShieldedHealth("AP", t) then
				player:castSpell("obj", 2, t)
			elseif orb.menu.combat:get() and (GetBuff(t,"chilled") or player.mana > RMANA + EMANA) then
				player:castSpell("obj", 2, t)
			elseif Harass and player.mana > RMANA + EMANA + QMANA + WMANA and menu.harass["harass"..t.charName]:get() and UnderTurret() and QMissile == nil then
				player:castSpell("obj", 2, t)
			end
		elseif orb.menu.combat:get() and player:spellSlot(3).state == 0 and player.mana  > RMANA + EMANA  and QMissile == nil then
			player:castSpell("obj", 3, t)
		end
	end
	farmE()
end

local function UseW(target)

	local qDmg = dmglib.GetSpellDamage(0,target)
	local eDmg = dmglib.GetSpellDamage(2,target)
	local rDmg = dmglib.GetSpellDamage(3,target)
	if qDmg + eDmg + rDmg >= common.GetShieldedHealth("AP", target) - (5 * target.healthRegenRate) then
		return true
	end
	if RMissile ~= nil and target.pos:dist(RMissile.pos) >= 300 then
		return true
	end
	
	return false
end

local function LogicW()
	if orb.menu.combat:get() and player.mana > RMANA + EMANA + WMANA then
		local t = GetTargetW()
		
		if t == nil then return end
		if t.type == TYPE_HERO then
		if player.pos:dist(t.pos) <= spellW.range and UseW(t) then
			local pos22 = preds.linear.get_prediction(spellW, t)
				if pos22 then
					local poss22 = vec3(pos22.endPos.x, t.y, pos22.endPos.y)
					player:castSpell("pos", 1, poss22)
				end
			
		end
		end
	end
end

local function Extend(source, target, range)
	return source + range * (target - source):norm()
end


--Credit : Korn1s
local function Gapcloser()	
	for i = 0, objManager.enemies_n - 1 do
		local dasher = objManager.enemies[i]
		if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then
			if
				player:spellSlot(0).state == 0  and menu.q.AGCQ:get() and dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and
					player.pos:dist(dasher.path.point[1]) < spellQ.range
			 then
				if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
					
						player:castSpell("pos", 0, dasher.path.point2D[1])
					
				end
			elseif player:spellSlot(1).state == 0  and menu.w.AGCW:get() and dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and
					player.pos:dist(dasher.path.point[1]) < spellW.range
			 then
				if player.pos2D:dist(dasher.path.point2D[1]) < player.pos2D:dist(dasher.path.point2D[0]) then
					
						player:castSpell("pos", 1, Extend(player.pos2D,dasher.path.point2D[1],50))					
				end
			end
		end
	end	
end

local function Jungle()
	if orb.menu.lane_clear:get() then
		local mobs = common.GetMinionsInRange(spellR.range, TEAM_NEUTRAL)
		if #mobs > 0 then
			local mob = mobs[1] 
			if player:spellSlot(0).state == 0 and menu.farm.jungleQ:get() then
				if QMissile ~= nil then 
					if QMissile.pos:dist(mob.pos) < 230 then
						player:castSpell("self", 0)
					end
				else 
					player:castSpell("pos", 0, mob.pos)
				end
				return
			end
			if  player:spellSlot(3).state == 0 and menu.farm.jungleR:get() and RMissile == nil then
				player:castSpell("pos", 3, mob.pos)
				return
			end
			if player:spellSlot(2).state == 0 and menu.farm.jungleE:get() and GetBuff(mob, "chilled") then
				player:castSpell("obj", 2, mob)
				return
			end
			--print(Extend(mob.pos, player.pos, 100))
			if player:spellSlot(1).state == 0 and menu.farm.jungleW:get() then
				player:castSpell("pos", 1, Extend(mob.pos, player.pos, 100))
				return
			end
		end
	end
end

local function OnTick()
	if orb.menu.combat:get() and menu.AACombo:get() then
		if player:spellSlot(2).state == 0 then
			orb.core.set_server_pause_attack()
		else
			orb.core.set_pause_attack(0)
		end		
	else
		orb.core.set_pause_attack(0)
	end
	
	Gapcloser()

	None = not ( orb.menu.combat:get() or orb.menu.hybrid:get() or orb.menu.lane_clear:get() or  orb.menu.last_hit:get() )
	
	if menu.harassHybrid:get() then
		Harass = orb.menu.hybrid:get()
	else
		Harass = orb.menu.hybrid:get() or orb.menu.lane_clear:get() or  orb.menu.last_hit:get()
	end
	
	
	
	if player:spellSlot(0).state == 0 and QMissile ~= nil and #common.GetEnemyHeroesInRange(230, QMissile.pos) > 0 then
		player:castSpell("self", 0)
	end
	
	SetMana()
	
	if player:spellSlot(3).state == 0 and menu.r.autoR:get() then
		LogicR()
	end
	
	if player:spellSlot(1).state == 0 and menu.w.autoW:get() then
		LogicW()
	end
	
	if player:spellSlot(0).state == 0 and QMissile == nil and menu.q.autoQ:get() then
		LogicQ()
	end
	
	if player:spellSlot(2).state == 0 and menu.e.autoE:get() then
		LogicE()		
	end
	
	Jungle()	
	
end

cb.add(cb.draw, function()
if updater.update then
graphics.draw_text_2D("dAnivia is updated. Press Reload or 2x F9", 28, 100 , 50, graphics.argb(255, 255, 153, 51))
end
end)
cb.add(cb.tick, OnTick)
cb.add(cb.createobj, CreateObj)
cb.add(cb.deleteobj, DeleteObj)