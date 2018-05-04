local version = 1.0

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

--spell
local spellQ = {
	range = 1250,
	delay = 0.625,
	speed = 2200,
	width = 90,
	boundingRadiusMod = 0,
	collision = { hero = false, minion = false }
}

local spellW = {
	range = 800
}

local spellE = {
	range = 750,
	delay = 0.125,
	speed = 1600,
	width = 90,
	boundingRadiusMod = 0,
	collision = { hero = true, minion = true }
}

local rRange = { 2000, 2500, 3000 }

--spell

local ComboTrap = false
local UseNet = false
local UseNetCombo = false
local LastTrapTime = os.clock()

local ComboTrap  = false
local UseNet = false
local UseNetCombo = false 
local LastTrapTime = 0
local ComboTarget = nil



--menu

local menu = menu("davidevCaitlyn", "dCaitlyn")
menu:menu("combo", "Combo")
menu.combo:boolean("QInCombo","Use Q in Combo",true)
menu.combo:boolean("SafeQKS","Safe Q KS",true)
menu.combo:slider("ShortQDisableLevel", "Disable Short-Q after level", 11, 0, 18, 1)
menu.combo:boolean("WAfterE","Use W in Burst Combo",true)
menu.combo:dropdown("TrapEnemyCast", "Use W on Enemy AA/Spellcast", 1, { "Exact Position", "Vector Extension", "Turn Off" })
menu.combo:boolean("TrapImmobileCombo","Use W on Immobile Enemies",true)
menu.combo:slider("EBeforeLevel", "Disable Long-E After Level", 18, 0, 18, 1)
menu.combo:boolean("EWhenClose","Use E on Gapcloser/Close Enemy",true)
menu.combo:keybind("SemiManualEMenuKey", "E Semi-Manual Key",  "G", nil)
menu.combo:boolean("RInCombo","Use R in Combo",true)
menu.combo:keybind("SemiManualRMenuKey", "R Semi-Manual Key",  "T", nil)
menu.combo:slider("UltRange", "Dont R if Enemies in Range", 1100, 0, 3000, 1)
menu.combo:boolean("EnemyToBlockR","Dont R if an Enemy Can Block",false)

menu:menu("harass", "Harass")
menu.harass:boolean("SafeQHarass", "Use Q Smart Harass", true)
menu.harass:slider("SafeQHarassMana", "Q Harass Above Mana Percent", 60 , 0 , 100, 1)
menu.harass:dropdown("TrapEnemyCastHarass", "Use W on Enemy AA/Spellcast", 1, { "Exact Position", "Vector Extension", "Turn Off" })

menu:menu("extra", "Extra Settings")
menu.extra:slider("WDelay", "Minimum Delay Between Traps (W)", 2, 0, 15, 1)

--menu
TS.load_to_menu(menu)
local TargetSelection = function(res, obj, dist)
	if dist < spellQ.range then
		res.obj = obj
		return true
	end
end

local GetTarget = function()
	return TS.get_result(TargetSelection).obj
end

local TargetSelectionR = function(res, obj, dist)
	if dist < rRange[player:spellSlot(3).level] then
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

local function GetAllyHeroesInRange(range, pos)
  local pos = pos or player
  local count = 0
  local allies = common.GetAllyHeroes()
  for i = 1, #allies do
    local hero = allies[i]
    if common.IsValidTarget(hero) and hero.pos:distSqr(pos) < range * range then
      count = count + 1
    end
  end
  return count
end

local function GetEnemyHeroesInRange(range, pos)
  local pos = pos or player
  local count = 0
  local enemies = common.GetEnemyHeroes()
  for i = 1, #enemies do
    local hero = enemies[i]
    if common.IsValidTarget(hero) and hero.pos:distSqr(pos) < range * range then
      count = count + 1
    end
  end
  return count
end



local function Combo()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		local flDistance = (enemy.pos - player.pos):len()
		
		if enemy == nil then return end
		if common.IsValidTarget(enemy) then
			if player:spellSlot(0).level > 0 and menu.combo["SafeQKS"]:get() and flDistance > 675 and GetEnemyHeroesInRange(650,player.pos) == 0 and (dmglib.GetSpellDamage(0,enemy) - enemy.healthRegenRate) > common.GetShieldedHealth("AD", enemy)
				then
				local pos = preds.linear.get_prediction(spellQ, enemy)
				if pos then
						local poss = vec3(pos.endPos.x, mousePos.y, pos.endPos.y)
						player:castSpell("pos", 0, poss)
					end
			end
			if player:spellSlot(3).level > 0 and menu.combo["RInCombo"]:get() and flDistance < rRange[player:spellSlot(3).level] and flDistance > menu.combo["UltRange"]:get() and (dmglib.GetSpellDamage(3,enemy) - enemy.healthRegenRate) > common.GetShieldedHealth("AD", enemy) and GetEnemyHeroesInRange(menu.combo["UltRange"]:get(),player.pos) == 0
			then
				if menu.combo["EnemyToBlockR"]:get() and GetAllyHeroesInRange(550,enemy.pos) > 0 then
				    return
				end
				player:castSpell("obj", 3, enemy)
				
			end
			if player:spellSlot(1).level > 0 and  menu.combo["TrapImmobileCombo"]:get() and flDistance < spellW.range and (common.HasBuffType(enemy, 11) or common.HasBuffType(enemy, 5) or common.HasBuffType(enemy, 24) or common.HasBuffType(enemy, 29) ) then
				if os.clock() - LastTrapTime > menu.extra["WDelay"]:get() then
					player:castSpell("obj", 1, enemy)
					LastTrapTime = os.clock()
					return
				end
			end
			if player:spellSlot(2).level > 0 and menu.combo["EWhenClose"]:get() and flDistance < 300 then
				local pos2 = preds.linear.get_prediction(spellE, enemy)
				if pos2 then
					local ppos = vec3(pos2.endPos.x, mousePos.y, pos2.endPos.y)
					player:castSpell("pos", 2, ppos)
					ComboTarget = enemy
					UseNetCombo = true
				end
				
			end
		end

	end
end

local function OnSpell(spell)
	if orb.menu.combat:get() and menu.combo["TrapEnemyCast"]:get() < 3 and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO and common.IsValidTarget(spell.owner) then
		if os.clock() - LastTrapTime > menu.extra["WDelay"]:get() then
			if menu.combo["TrapEnemyCast"]:get() == 1 then
				player:castSpell("obj", 1, spell.owner)
				LastTrapTime = os.clock()
				return
			else
				local EndPosition = player.pos + (spell.owner.pos - player.pos):norm() * ((spell.owner.pos - player.pos):len() + 50);
				player:castSpell("pos", 1, EndPosition)
				LastTrapTime = os.clock()
				return
			end
		end
	end
	
	if orb.menu.hybrid:get() and menu.harass["TrapEnemyCastHarass"]:get() < 3 and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO and common.IsValidTarget(spell.owner) then
		if os.clock() - LastTrapTime > menu.extra["WDelay"]:get() then
			if menu.harass["TrapEnemyCastHarass"]:get() == 1 then
				player:castSpell("obj", 1, spell.owner)
				LastTrapTime = os.clock()
				return
			else
				local EndPosition = player.pos + (spell.owner.pos - player.pos):norm() * ((spell.owner.pos - player.pos):len() + 50);
				player:castSpell("pos", 1, EndPosition)
				LastTrapTime = os.clock()
				return
			end
		end
	end
	
	if orb.menu.lane_clear:get() and spell.owner.team == TEAM_ENEMY and spell.owner.type == TYPE_HERO and common.IsValidTarget(spell.owner) then
		if menu.harass["SafeQHarass"]:get() and common.GetPercentMana(player) > menu.harass["SafeQHarassMana"]:get() and GetEnemyHeroesInRange(800, player) == 0 then
			local pos31 = preds.linear.get_prediction(spellQ, spell.owner)
			if pos31 then
				local posss = vec3(pos31.endPos.x, mousePos.y, pos31.endPos.y)
				player:castSpell("pos", 0, posss)
			end
		end
	end
	
	if spell and menu.combo["QInCombo"]:get() and spell.name == "CaitlynHeadshotMissile" and spell.target.type == TYPE_HERO and common.IsValidTarget(spell.target) then
		local flDistance = (spell.target.pos - player.pos):len();
		if flDistance < spellQ.range then
			if flDistance > 650 or player.levelRef < menu.combo["ShortQDisableLevel"]:get() then
				local target = GetTarget()
				
				if target == nil then return end
				
				local pos = preds.linear.get_prediction(spellQ, target)
				if pos then
					local poss = vec3(pos.endPos.x, mousePos.y, pos.endPos.y)
					player:castSpell("pos", 0, poss)
				end
			end
		end
	end
	
	if spell and menu.combo["WAfterE"]:get() and spell.name == "CaitlynEntrapment" then
		if ComboTarget ~= nil and common.IsValidTarget(ComboTarget) then
			local EstimatedEnemyPos = common.GetPredictedPos(ComboTarget, 0.5)
			if EstimatedEnemyPos then
				player:castSpell("pos", 1, EstimatedEnemyPos)
				return
			end
		end
	end
end
	

local function OnTick()
    if orb.menu.combat:get()
	then
		Combo()
	end
	
	if menu.combo["SemiManualRMenuKey"]:get() then
		local target = GetTargetR()
		
		if target == nil then return end
		
		player:castSpell("obj", 3, target)		
	end
	
	if menu.combo["SemiManualEMenuKey"]:get() then
		local target = GetTargetE()
		
		if target == nil then return end
		
		local pos2 = preds.linear.get_prediction(spellE, target)
		if pos2 then
			local ppos = vec3(pos2.endPos.x, mousePos.y, pos2.endPos.y)
			player:castSpell("pos", 2, ppos)
			ComboTarget = target
			UseNetCombo = true
		end	
	end
end

cb.add(cb.spell, OnSpell)
cb.add(cb.tick, OnTick)
orb.combat.register_f_after_attack(function()
	if orb.combat.target == nil then return end
	
	local target = orb.combat.target
	local pos2 = preds.linear.get_prediction(spellE, target)
					
	if orb.menu.combat:get() and target.type == TYPE_HERO and common.IsValidTarget(target) then
		if player.levelRef <= menu.combo.EBeforeLevel:get() and pos2 then
			local ppos = vec3(pos2.endPos.x, mousePos.y, pos2.endPos.y)
			player:castSpell("pos", 2, ppos)
			UseNetCombo = true
            ComboTarget = target
			return
		end
	end
end
)