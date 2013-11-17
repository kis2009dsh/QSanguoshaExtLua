function getTrickIntention(TrickClass, target)
	local Intention = sgs.ai_card_intention[TrickClass]
	if type(Intention) == "number" then
		return Intention 
	elseif type(Intention == "function") then
		if TrickClass == "IronChain" then
			if target:isChained() then
				return -80
			else
				return 80
			end
		end
	end
	if TrickClass == "Collateral" then return 0 end
	if TrickClass == "AmazingGrace" then return -10 end
	if sgs.dynamic_value.damage_card[TrickClass] then 
		return 70
	end
	if sgs.dynamic_value.benefit[TrickClass] then
		return -40
	end
	if target then
		if TrickClass == "Snatch" or TrickClass == "Dismantlement" then
			local judgelist = target:getCards("j")
			if not judgelist or judgelist:isEmpty() then
				local armor = target:getArmor()
				if armor and armor:isKindOf("SilverLion") and target:isWounded() then return 0
				else
					return 80
				end
			end
		end
	end
	return 0
end

sgs.ai_skill_invoke["yi_qianhuan"] = function(self, data)
	local splayer = self.room:findPlayerBySkillName("yi_qianhuan")
	local case = data:toInt()
	if case == 1 then
		return self:isFriend(splayer)
	else
		local use = self.room:getTag("YiQianhuanAI"):toCardUse()
		local target = use.to:first()
		if self:isFriend(target) then
			if  use.card:isKindOf("Slash") and self:isWeak(target) then
				return true
			elseif use.card:isKindOf("TrickCard") and not use.card:isKindOf("Lightning") then
				return getTrickIntention(use.card:getClassName(), target) > 0
			end
		else
			if (use.card:isKindOf("Jink") or use.card:isKindOf("Peach")) and self:isWeak(target) then
				return true
			elseif use.card:isKindOf("Lightning") then
				for _, p in ipairs(self.enemies) do
					if p:hasSkills("guidao|guicai|huanshi|xinzhan") or (p:hasSkill("guanxing") and p:aliveCount() > 3) then
						return true
					end
				end
			elseif use.card:isKindOf("TrickCard") then
				return getTrickIntention(use.card:getClassName(), target) < 0
			end
		end		
	end
end

sgs.ai_skill_askforag["yi_ziliang"] = function(self, card_ids)
	local target = self.room:getTag("YiZiliangAI"):toPlayer()
	if self:isFriend(target) and self:isWeak(target) and target:isKongcheng() and not target:hasSkill("kongcheng") then
		self:sortByUseValue(card_ids)
		return card_ids[1]
	else
		return -1
	end
end

sgs.ai_skill_invoke["yi_tianfu"] = function(self, data)
	return self:isFriend(data:toPlayer())
end

sgs.ai_skill_choice["zhiji"] = function(self, choices, data)
	if self.player:getHp() < self.player:getMaxHp()-1 then return "recover" end
	return "draw"
end

sgs.ai_skill_invoke["yi_yicheng"] = function(self, data)
	local target = data:toPlayer()
	return (self:isFriend(target) and not target:hasSkill("manjuan")) or (self:isEnemy(target) and target:hasSkill("manjuan"))
end

sgs.ai_skill_invoke["yi_shoucheng"] = function(self, data)
	return self:isFriend(data:toPlayer())
end

local function huyuan_validate(self, equip_type, is_handcard)
	local is_SilverLion = false
	if equip_type == "SilverLion" then
		equip_type = "Armor"
		is_SilverLion = true
	end
	local targets
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type ~= "Weapon" then
		if is_SilverLion then
			for _, enemy in ipairs(self.enemies) do
				if not self:hasSkills("bazhen|yizhong", enemy) then continue end
				for _, enemy in ipairs(self.enemies) do
					if enemy:distanceTo(enemy) == 1 and not enemy:isNude() then
						enemy:setFlags("AI_YuanhuToChoose")
						return enemy
					end
				end
			end
		end
		for _, friend in ipairs(targets) do
			local has_equip = false
			for _, equip in sgs.qlist(friend:getEquips()) do
				if equip:isKindOf(equip_type) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				if equip_type == "Armor" then
					if self:hasSkills("bazhen|yizhong", friend) then continue end
					self:sort(self.enemies, "defense")
					for _, enemy in ipairs(self.enemies) do
						if friend:distanceTo(enemy) == 1 and not enemy:isNude() then
							enemy:setFlags("AI_YuanhuToChoose")
							return friend
						end
					end
				end
			end
		end
	else
		for _, friend in ipairs(targets) do
			local has_equip = false
			for _, equip in sgs.qlist(friend:getEquips()) do
				if equip:isKindOf(equip_type) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				self:sort(self.enemies, "defense")
				for _, enemy in ipairs(self.enemies) do
					if friend:distanceTo(enemy) == 1 and not enemy:isNude() then
						enemy:setFlags("AI_YuanhuToChoose")
						return friend
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use["@@yi_huyuan"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasArmorEffect("SilverLion") and huyuan_validate(self, "SilverLion", false) then
		local player = huyuan_validate(self, "SilverLion", false)
		local card_id = self.player:getArmor():getEffectiveId()
		return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
	end
	if self.player:getOffensiveHorse() and huyuan_validate(self, "OffensiveHorse", false) then
		local player = huyuan_validate(self, "OffensiveHorse", false)
		local card_id = self.player:getOffensiveHorse():getEffectiveId()
		return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
	end
	if self.player:getWeapon() and huyuan_validate(self, "Weapon", false) then
		local player = huyuan_validate(self, "Weapon", false)
		local card_id = self.player:getWeapon():getEffectiveId()
		return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
	end
	if self.player:getArmor() and self.player:getLostHp() <= 1 and self.player:getHandcardNum() >= 3
		and huyuan_validate(self, "Armor", false) then
		local player = huyuan_validate(self, "Armor", false)
		local card_id = self.player:getArmor():getEffectiveId()
		return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("DefensiveHorse") and huyuan_validate(self, "DefensiveHorse", true) then
			local player = huyuan_validate(self, "DefensiveHorse", true)
			local card_id = card:getEffectiveId()
			return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("OffensiveHorse") and huyuan_validate(self, "OffensiveHorse", true) then
			local player = huyuan_validate(self, "OffensiveHorse", true)
			local card_id = card:getEffectiveId()
			return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and huyuan_validate(self, "Weapon", true) then
			local player = huyuan_validate(self, "Weapon", true)
			local card_id = card:getEffectiveId()
			return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("SilverLion") and huyuan_validate(self, "SilverLion", true) then
			local player = huyuan_validate(self, "SilverLion", true)
			local card_id = card:getEffectiveId()
			return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
		end
		if card:isKindOf("Armor") and huyuan_validate(self, "Armor", true) then
			local player = huyuan_validate(self, "Armor", true)
			local card_id = card:getEffectiveId()
			return "#yi_huyuan:" .. card_id .. ":->" .. player:objectName()
		end
	end
end

sgs.ai_skill_playerchosen["yi_huyuan"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if p:hasFlag("AI_YuanhuToChoose") then
			p:setFlags("-AI_YuanhuToChoose")
			return p
		end
	end
	return nil
end

sgs.ai_skill_use["@@yi_heyi"] = function(self, prompt)
	local targets = {}
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("YiHeyiTarget") and self:isFriend(p) then
			table.insert(targets, p:objectName())
		end
	end
	if #targets == 0 then return "." end
	
	return "#yi_heyi:.:->" .. table.concat(targets, "+")
end

local YiShangyi_skill = {}
YiShangyi_skill.name = "yi_shangyi"
table.insert(sgs.ai_skills, YiShangyi_skill)
YiShangyi_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#yi_shangyi") and not self.player:isKongcheng() then
		return sgs.Card_Parse("#yi_shangyi:.:")
	end
end

sgs.ai_skill_use_func["#yi_shangyi"] = function(card, use, self)
	local targets = sgs.QList2Table(room:getOtherPlayers(self.player))
	self:sort(targets, "handcard")
	target = targets[1]
	if target then
		local card_str = "#yi_shangyi:.:->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_choice["yi_shangyi"] = function(self, choices, data)
	if self:isEnemy(data:toPlayer()) then
		return "watch"
	end
	return "draw"
end

sgs.ai_skill_invoke["yi_niaoxiang"] = function(self, data)
	return self:isEnemy(data:toPlayer())
end

sgs.ai_skill_discard["yi_zhendu"] = function(self, discard_num, min_num, optional, include_equip)
	local target = self.room:getTag("YiZhenduAI"):toPlayer()
	if self.player:getHandcardNum() > 1 and (self:isFriend(target) and self:needToLoseHp(target, self.player)) or (self:isEnemy(target) and self:isWeak()) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]:getEffectiveId()
	end
	return {}
end

