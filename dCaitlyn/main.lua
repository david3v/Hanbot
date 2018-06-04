local version = tonumber(io.open(hanbot.luapath .. '/dCaitlyn/version', 'r'):read('*a'))


local updater = module.load("dCaitlyn", "updater")
--Auto update dCaitlyn
updater.davidev_update("dCaitlyn", version, hanbot.luapath)


local avada_lib = module.lib("avada_lib")
if not avada_lib then
	console.set_color(12)
	print("You need to have Avada Lib in your community_libs folder to run 'dCaitlyn'!")
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


local QCastTime = 0
local WCastTime = 0

--spell
local spellQ = {
	speed = 2200, range = 1250, delay = 0.625, width = 90, boundingRadiusMod = 0
}

local spellW = {
	speed = math.huge, range = 800, delay = 0.25, radius = 75, boundingRadiusMod = 0 
}

local spellE = {
	speed = 1500, range = 750, delay = 0.25, width = 60, boundingRadiusMod = 0, collision = {minion = true, wall = true }
}

local rRange = { 2000, 2500, 3000 }

--spell

local Harass, None

local Spells = { ["katarinar"] = true,["drain"] = true,["consume"] = true,["absolutezero"] = true, ["staticfield"] = true,["reapthewhirlwind"] = true,["jinxw"] = true,["jinxr"] = true,["shenstandunited"] = true,["threshe"] = true,["threshrpenta"] = true,["threshq"] = true,["meditate"] = true,["caitlynpiltoverpeacemaker"] = true, ["volibearqattack"] = true,
["cassiopeiapetrifyinggaze"] = true,["ezrealtrueshotbarrage"] = true,["galioidolofdurand"] = true,["luxmalicecannon"] = true, ["missfortunebullettime"] = true,["infiniteduress"] = true,["alzaharnethergrasp"] = true,["lucianq"] = true,["velkozr"] = true,["rocketgrabmissile"] = true
 }
--menu

local menu = menu("davidevCaitlyn", "dCaitlyn")
menu:menu("q", "Q Config")
menu.q:boolean("autoQ2","Auto Q",true)
menu.q:boolean("autoQ","Reduce Q",true)
menu.q:boolean("Qaoe","Q aoe",true)
menu.q:boolean("Qslow","Q slow",true)
menu:menu("w", "W Config")
menu.w:boolean("comboW", "Auto W on combo", false)
menu.w:boolean("autoW", "Auto W on hard CC", true)
menu.w:boolean("telE", "Auto W teleport, zhonya and other object", true)
menu.w:boolean("Wspell", "W on special spell detection", true)
menu.w:menu("wgap", "W Gap Closer")
menu.w.wgap:dropdown("WmodeGC", "Gap Closer position mode", 1, { "Dash end position", "My hero position" })
menu.w.wgap:menu("castEnemy", "Cast on enemy: ")
local enemies = common.GetEnemyHeroes()
for i, enemy in ipairs(enemies) do
	menu.w.wgap.castEnemy:boolean("WGCchampion"..enemy.charName, enemy.charName, true)
end
menu:menu("e", "E Config")
menu.e:boolean("autoE", "Auto E", true)
menu.e:boolean("Ehitchance", "Auto E dash target", true)
menu.e:boolean("harrasEQ", "TRY E + Q", true)
menu.e:boolean("EQks", "Ks E + Q + AA", true)
menu.e:keybind("useE", "Dash E HotKeySmartcast", "T", nil)
menu.e:menu("egap", "E Gap Closer")
menu.e.egap:dropdown("EmodeGC", "Gap Closer position mode", 3, { "Dash end position", "Cursor position", "Enemy position" })
menu.e.egap:menu("castEnemy", "Cast on enemy: ")
local enemies = common.GetEnemyHeroes()
for i, enemy in ipairs(enemies) do
	menu.e.egap.castEnemy:boolean("EGCchampion"..enemy.charName, enemy.charName, true)
end
menu:menu("r", "R Config")
menu.r:boolean("autoR", "Auto R KS", true)
menu.r:slider("UltRange", "Dont R if Enemies in Range", 1100, 0, 3000, 1)
menu.r:boolean("EnemyToBlockR","Dont R if an Enemy Can Block",true)
menu.r:keybind("useR", "Semi-maanual cast R key", "R", nil)
menu.r:boolean("Rturrent", "Don't R under enemy turret", true)
menu:boolean("harassHybrid", "Spell-harass only in hybrid mode", false)
menu:boolean("manaDisable", "Disable mana manager in combo", false)

--menu
local TargetSelectionR = function(res, obj, dist)
	if dist < rRange[player:spellSlot(3).level] then
		res.obj = obj
		return true
	end
end

local GetTargetR = function()
	return TS.get_result(TargetSelectionR).obj
end

local TargetSelection = function(res, obj, dist)
	if dist < spellQ.range then
		res.obj = obj
		return true
	end
end

local GetTarget = function()
	return TS.get_result(TargetSelection).obj
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


local function SetMana()
	if (menu.manaDisable:get() and orb.menu.combat.key:get()) or common.GetPercentHealth() < 20 then
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

local function OnSpell(spell)
	if spell and spell.owner == player and (spell.name == "CaitlynPiltoverPeacemaker" or spell.name == "CaitlynEntrapment") then
		QCastTime = game.time
	end

	if spell and spell.owner == player and spell.name == "CaitlynYordleTrap" then
		WCastTime = game.time
	end

	if player:spellSlot(1).state == 0 and menu.w.Wspell:get() and spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY and common.IsValidTarget(spell.owner) and player.pos:dist(spell.owner.pos) < spellW.range then 
		
		local ss = Spells[string.lower(spell.name)]
		if ss then
			player:castSpell("pos", 1, spell.owner.pos)
		end
	end	
	
end

local function bonusRange()
	return 720 + player.boundingRadius
end

local function GetRealDistance(target)
	return player.path.serverPos:dist(target.pos) + player.boundingRadius + target.boundingRadius
end

local function GetRealRange(target)
	return 680 + player.boundingRadius + target.boundingRadius
end

local function  IsInRange(source, target, range)
	return source.path.serverPos2D:distSqr(target.pos2D) < range * range
end

local function  IsInRangeVec(sourceVec, targetVec, range)
	return sourceVec:distSqr(targetVec) < range * range
end

local function IsInAutoAttackRange(target, source)
	source = source or player
	return 	IsInRange(source,target, common.GetAARange(target)) and IsInRangeVec(common.GetPredictedPos(source, network.latency ), common.GetPredictedPos(target, network.latency ), common.GetAARange(target)) 
end

local function UnderTurret(pos)
	local p = pos or player.pos
	if common.is_under_tower(p) then
		return true
	else 
		return false
	end	
end

local function CastIfItWillHit(minHit)
local valid = {}
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) then
		local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
		if dist <= (spellQ.range * spellQ.range) then
			valid[#valid + 1] = enemy
		end
		end
	end

local max_count, cast_pos = 0, nil
	for i = 1, #valid do
		local enemy_a = valid[i]
		local current_pos = player.path.serverPos + ((enemy_a.path.serverPos - player.path.serverPos):norm() * (enemy_a.path.serverPos:dist(player.path.serverPos) + spellQ.range))
		local hit_count = 1
		for j = 1, #valid do
			if j ~= i then
				local enemy_b = valid[j]
				local point = mathf.closest_vec_line(enemy_b.path.serverPos, player.path.serverPos, current_pos)
				if point and point:dist(enemy_b.path.serverPos) < (spellQ.width / 2 + enemy_b.boundingRadius) then
				hit_count = hit_count + 1
				end
			end
		end
		if not cast_pos or hit_count > max_count then
		cast_pos, max_count = current_pos, hit_count
		end
		if cast_pos and max_count >= minHit then				
			print("aoe")
			player:castSpell("pos", 0, cast_pos)
			orb.core.set_server_pause()
			break
		  end
	end
	
end

local function Gapcloser()	
	if player.mana > RMANA + WMANA then
		for i = 0, objManager.enemies_n - 1 do
			local dasher = objManager.enemies[i]
			if dasher.type == TYPE_HERO and dasher.team == TEAM_ENEMY then
				if player:spellSlot(2).state == 0 and dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and
				player.pos:dist(dasher.path.point[1]) < spellE.range and menu.e.egap.castEnemy["EGCchampion" .. dasher.charName]:get() then
					if menu.e.egap.EmodeGC:get() == 1 then
						player:castSpell("pos", 2, dasher.path.point2D[1])
					elseif menu.e.egap.EmodeGC:get() == 2 then
						player:castSpell("pos", 2, game.mousePos)
					else
						player:castSpell("pos", 2, dasher.path.serverPos)
					end
				elseif player:spellSlot(1).state == 0 and dasher and common.IsValidTarget(dasher) and dasher.path.isActive and dasher.path.isDashing and
				player.pos:dist(dasher.path.point[1]) < spellW.range and menu.w.wgap.castEnemy["WGCchampion" .. dasher.charName]:get() then
					if menu.w.wgap.WmodeGC:get() == 1 then
						player:castSpell("pos", 1, dasher.path.point2D[1])
					else
						player:castSpell("pos", 1, player.path.serverPos)
					end
				end
			end
		end
	end
end

local function LogicQ()
	local t = GetTarget()
	if t and common.IsValidTarget(t) then
		if GetRealDistance(t) > bonusRange() + 80 and not IsInAutoAttackRange(t) and dmglib.GetSpellDamage(0,t) * 0.67 > common.GetShieldedHealth("AD", t) and #common.GetEnemyHeroesInRange(400) == 0 then
			local pos = preds.linear.get_prediction(spellQ, t)
			if pos and pos.startPos:dist(pos.endPos) <= spellQ.range then
				player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
			end
		elseif orb.menu.combat.key:get() and player.mana > RMANA + QMANA + EMANA + 10 and #common.GetEnemyHeroesInRange(bonusRange() + 100 + t.boundingRadius) == 0 and not menu.q.autoQ:get() then
			local pos = preds.linear.get_prediction(spellQ, t)
			if pos and pos.startPos:dist(pos.endPos) <= spellQ.range then
				player:castSpell("pos", 0, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
			end
		end
		if (orb.menu.combat.key:get() or Harass) and player.mana > RMANA + QMANA and #common.GetEnemyHeroesInRange(400) == 0 then
			local enemies = common.GetEnemyHeroes()
			for i, enemy in ipairs(enemies) do
				if common.IsValidTarget(enemy) and IsInRange(player,enemy,spellQ.range) and ( not common.CanPlayerMove(enemy) or enemy.buff["caitlynyordletrapinternal"] ) then
					player:castSpell("pos", 0, enemy.path.serverPos)				
				end
			end
			if #common.GetEnemyHeroesInRange(bonusRange()) == 0 and not UnderTurret() then
				if common.HasBuffType(t,10) and menu.q.Qslow:get() then
					player:castSpell("pos", 0, t.path.serverPos)
				end
				if menu.q.Qaoe:get() then
					CastIfItWillHit(2)			
				end
			end
		end
	end
end

local function kek(hero)
	return hero.buff["rocketgrab2"] or hero.buff["ThreshQ"] or (hero.moveSpeed >= 50 and not common.HasBuffType(hero, 5)
	and not common.HasBuffType(hero, 21) and not common.HasBuffType(hero, 11) and not common.HasBuffType(hero, 29) and not hero.buff["Recall"] and not common.HasBuffType(hero, 30) and not common.HasBuffType(hero, 22) and not common.HasBuffType(hero, 8) and not common.HasBuffType(hero, 24))
end

local function kek2(player, hero)
	local vector = player.path.point[player.path.count]
	local result
	if vector == player.pos then
		result = false
	else
		vector2 = hero.path.point[hero.path.count]
		if vector2 == hero.pos then
			result = false
		else
			local p = vector - player.pos
			local p2 = vector2 - hero.pos
			local aci = (p2-p):norm()
			local num = mathf.angle_between(p,p2,aci)
			result = num < 20
		end
	end
	return result
end

local function LogicW()
	if player.mana > RMANA + WMANA then
		if menu.w.autoW:get() then
			local enemies = common.GetEnemyHeroes()
			for i, enemy in ipairs(enemies) do
				if common.IsValidTarget(enemy) and IsInRange(player,enemy,spellW.range) and not enemy.buff["caitlynyordletrapdebuff"] and not kek(enemy) and game.time - WCastTime > 2  then
					player:castSpell("pos", 1, enemy.path.serverPos)			
				end
			end
		end
		if menu.w.telE:get() then
			local trapPos			
			local enemies = common.GetEnemyHeroes()
			for i, enemy in ipairs(enemies) do		
				if common.IsValidTarget(enemy) and enemy.pos:dist(player.path.serverPos) < spellW.range and (enemy.buff["zhonyasringshield"] or enemy.buff["BardRStasis"] or common.HasBuffType(enemy, 17) )  then
					trapPos = enemy.pos		
				end
			end

			objManager.loop(function(obj)
				if obj and obj.pos:dist(player.pos) < spellW.range then
					name = string.lower(obj.name)			
					if name:find("gatemarker_red.troy") or name:find("global_ss_teleport_target_red.troy") or name:find("r_indicator_red.troy") then
						trapPos = obj.pos
					end
				end
			end)
			if trapPos then
				player:castSpell("pos", 1, trapPos)
			end	
		end		

		if orb.menu.combat.key:get() and menu.w.comboW:get() and player:spellSlot(1).stacks > 1 then
			local enemies = common.GetEnemyHeroes()
			for i, enemy in ipairs(enemies) do		
				if common.IsValidTarget(enemy) and IsInRange(player,enemy,spellW.range - 100) then
					if common.HasBuffType(enemy, 10) then
						local pos = preds.circular.get_prediction(spellW, enemy)
						if pos and pos.startPos:dist(pos.endPos) <= spellW.range then
							player:castSpell("pos", 1, vec3(pos.endPos.x, enemy.pos.y, pos.endPos.y))
						end
					end
					if kek2(player,enemy) then
						local pos = preds.circular.get_prediction(spellW, enemy)
						if pos and pos.startPos:dist(pos.endPos) <= spellW.range then
							player:castSpell("pos", 1, vec3(pos.endPos.x, enemy.pos.y, pos.endPos.y))
						end
					end
				end
			end
		end

	end
end

local function Extend(source,target,range)
	return	source + range * (target - source):norm()
end

local function LogicE()
	if menu.e.autoE:get() then
		local t = GetTargetE()
		if t and common.IsValidTarget(t) then
			local positionT = player.path.serverPos - (t.pos - player.path.serverPos)
			if #common.GetEnemyHeroesInRange(700, Extend(player.pos, positionT, 400)) < 2 then
				local eDmg = dmglib.GetSpellDamage(2, t)
				local qDmg = dmglib.GetSpellDamage(0, t) * 0.67
				if menu.e.EQks:get() and qDmg + eDmg + common.CalculateAADamage(t) > t.health and player.mana > EMANA + QMANA then
					local pos = preds.linear.get_prediction(spellE, t)
					if pos and not preds.collision.get_prediction(spellE, pos, t) and pos.startPos:dist(pos.endPos) <= spellE.range then
						player:castSpell("pos", 2, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
					end
				elseif (Harass or orb.menu.combat.key:get()) and menu.e.harrasEQ:get() and player.mana > EMANA + QMANA + RMANA then
					local pos = preds.linear.get_prediction(spellE, t)
					if pos and not preds.collision.get_prediction(spellE, pos, t) and pos.startPos:dist(pos.endPos) <= spellE.range then
						player:castSpell("pos", 2, vec3(pos.endPos.x, t.pos.y, pos.endPos.y))
					end
				end
			end

			if player.mana > RMANA + EMANA then
				if menu.e.Ehitchance:get() and t.path.isActive and t.path.isDashing then
					local pred_pos = preds.core.lerp(t.path, network.latency + spellE.delay, t.path.dashSpeed)
					if pred_pos and pred_pos:dist(player.path.serverPos2D) > common.GetAARange() and pred_pos:dist(player.path.serverPos2D) <= spellE.range then
						player:castSpell("pos", 2, vec3(pred_pos.x, t.y, pred_pos.y))
					end
				end
				if player.health < player.maxHealth * 0.3 then
					if GetRealDistance(t) < 500 then
						player:castSpell("pos", 2, t.pos)
					end
					if #common.GetEnemyHeroesInRange(250) > 0 then
						player:castSpell("pos", 2, t.pos)
					end
				end
			end

		end
	end

	if menu.e.useE:get() then
		local position = player.path.serverPos - (game.mousePos - player.path.serverPos)
		player:castSpell("pos", 2, position)
	end
end

local function ValidUlt(target)
	local result
	if ( common.HasBuffType(target, 16) or common.HasBuffType(target, 15) ) or common.HasBuffType(target, 17)  or common.HasBuffType(target, 4) or not common.IsValidTarget(target) or target.buff["JudicatorIntervention"] or target.buff["UndyingRage"] 
	or target.buff["ChronoRevive"] or target.buff["ChronoShift"] or target.buff["lissandrarself"] or target.buff["KindredRNoDeathBuff"] or target.buff["malzaharpassiveshield"] or target.buff["BansheesVeil"] or target.buff["SivirShield"]
	or target.buff["ShroudofDarkness"] or target.buff["BlackShield"] or target.buff["zhonyasringshield"] or target.buff["fioraw"] then
		result = false
	else
		result = true
	end
	return result
end

local function LogicR()
	if (not UnderTurret() or not menu.r.Rturrent:get()) and #common.GetEnemyHeroesInRange(700) == 0 then
		local enemies = common.GetEnemyHeroes()
		for i, enemy in ipairs(enemies) do	
			local flDistance = (enemy.pos - player.pos):len()
			if common.IsValidTarget(enemy) and flDistance < rRange[player:spellSlot(3).level] and flDistance > menu.r.UltRange:get() and #common.GetEnemyHeroesInRange(menu.r.UltRange:get()) == 0 and ValidUlt(enemy) then
				if dmglib.GetSpellDamage(3, enemy) * 0.1 > common.GetShieldedHealth("AD", enemy) then
					local count,objs = common.CountObjectsNearPos(enemy.pos, 550, enemies, common.IsValidTarget)
					if menu.r.EnemyToBlockR:get() and count > 1 then
						return
					end
					
					player:castSpell("obj", 3, enemy)
					break
				end
			end
		end
	end
end

local function OnTick()
	if player.isRecalling or player.isDead then 
		return
	end
	
	if menu.r.useR:get() then
		local target = GetTargetR()
		if target and common.IsValidTarget(target) then
			player:castSpell("obj", 3, target)
		end
	end
	
	if menu.harassHybrid:get() then
		Harass = orb.menu.hybrid.key:get()
	else
		Harass = orb.menu.hybrid.key:get() or orb.menu.lane_clear.key:get() or  orb.menu.last_hit.key:get()
	end

	SetMana()

	Gapcloser()

	if player:spellSlot(2).state == 0 then			
		LogicE()
	end	

	local orbT = orb.combat.target
	if(orbT and orbT.type == TYPE_HERO) then		
		if common.CalculateAADamage(orbT) * 2 > orbT.health then return end
	end
	if player:spellSlot(1).state == 0 then	
		LogicW()
	end
	if player:spellSlot(0).state == 0 and menu.q.autoQ2:get() then
		LogicQ()
	end
	if player:spellSlot(3).state == 0 and menu.r.autoR:get() and game.time - QCastTime > 2 then
		LogicR()
	end


end

cb.add(cb.draw, function()
if updater.update then
graphics.draw_text_2D("dCaitlyn is updated. Press Reload or 2x F9", 28, 100 , 50, graphics.argb(255, 255, 153, 51))
end
end)
cb.add(cb.spell, OnSpell)
cb.add(cb.tick, OnTick)