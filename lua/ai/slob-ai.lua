--[[
	AI For Slob's oltest Package ^_^    By.RaraSLG
]]
--AI For Fentian
local testing = false
function testWord(ai, word)
	if testing then
		local w = word or "ok"
		ai.player:speak(w)
	end
end
sgs.ai_skill_playerchosen["fentian"] = function(self, targets)
	local enemies = {}
	local friends = {}
	for _, p in sgs.qlist(targets) do
		if not self:isFriend(p) then 
			testWord(self, "1")
			table.insert(enemies, p)
		else
			testWord(self, "2")
			table.insert(friends, p)
		end
	end
	if not #enemies ~= 0 then
		self:sort(enemies, "threat")
		for _, p in ipairs(enemies) do
			testWord(self, "3")
			if not (p:hasSkills("xiaoji|xuanfeng|nosxuanfeng") and p:isKongcheng()) and p:hasEquip() and not (p:getEquips():length() == 1 and p:hasEquipSkill("SilverLion") and self:isWeak(p)) then
				return p
			end
		end
		return enemies[1]
	else
		for _, p in ipairs(friends) do
			testWord(self, "4")
			if p:hasSkills("xiaoji|xuanfeng|nosxuanfeng") and p:hasEquip() then
				return p
			end
		end
	end
	return targets[1]
end

sgs.ai_cardChosen_intention["fentian"] = function(from, to, card_id)
	local card = sgs.Sanguosha:getCard(card_id)
	local intention = 0
	if (to:hasSkills("kongcheng|lianying|zhiji") and to:getHandcardNum() == 1) or to:hasSkills("tuntian+zaoxian") then
		intention = -20
	elseif to:hasSkills("xiaoji|xuanfeng|nosxuanfeng") and to:hasEquiped(card) then
		intention = -30
	elseif card:isKindOf("SilverLion") and to:hasEquip(card) and self:isWeak(to) then
		intention = -40
	elseif to:handCards():contains(card_id) and to:hasEquip() and not to:hasSkills("xiaoji|xuanfeng|nosxuanfeng") and not (to:hasEquipSkill("SilverLion") and self:isWeak(to)) then
		intention = -10
	else
		intention = 80
	end
	sgs.updateIntention(from, to, intention)
end
--I think it's not necessary to make special decision table for fentian cardchosen...

sgs.ai_chaofeng.hanba = 3


local xintan_skill = {}
xintan_skill.name = "xintan"
table.insert(sgs.ai_skills, xintan_skill)
xintan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPile("fentianpile"):length() > 1 and not self.player:hasUsed("#xintancard") then
		local can_use = false
		if self:isWeak() then can_use = true end
		if not #self.enemies == 0 then
			for _, p in ipairs(self.enemies) do
				if self:isWeak(p) then
					can_use = true
					break
				end
			end
		end
		if can_use then
			return sgs.Card_Parse("#xintancard:.:")
		end
	end
end

sgs.ai_skill_use_func["#xintancard"] = function(card, use, self)
	local target = nil
	self:sort(self.enemies, "value")
	for _, p in ipairs(self.enemies) do
		if self:isWeak(p) then
			target = p 
			break
		end
	end
	if not target then target = self.enemies[1] end
	--local pile = self.player:getPile("fentianpile")
	--local card_str = "#xintancard:"..pile:at(0).."+"..pile:at(1)..":->"..target:objectName()
	local card_str = "#xintancard:.:->"..target:objectName()
	local acard = sgs.Card_Parse(card_str)
	assert(acard)
	use.card = acard
	if use.to then
		use.to:append(target)
	end
end

sgs.ai_skill_askforag["xintan"] = function(self, card_ids)
	testWord(self, "<font color=\"red\">17</font>")
	return card_ids[1]
end

sgs.ai_card_intention.xintancard = function(self, card, from, tos)
	testWord(self, "<font color=\"red\">16</font>")
	sgs.updateIntention(from, tos[1], 50)
end


local zhoufuvs_skill = {}
zhoufuvs_skill.name = "zhoufu"
table.insert(sgs.ai_skills, zhoufuvs_skill)
zhoufuvs_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#zhoufucard") then return end
	local will_use = false
	local Indulgence = false
	local SupplyShortage = false
	if self:getOverflow() > 0 and #self.friends_noself ~= 0then
		will_use = true
		testWord(self, "<font color=\"red\">1</font>")
	end
	for _, p in ipairs(self.enemies) do
		tricks = p:getJudgingArea()
		if tricks:length() == 0 then continue end
		for _, trick in sgs.qlist(tricks) do
			if trick:isKindOf("Indulgence") then
				testWord(self, "<font color=\"red\">2</font>")
				Indulgence = true
				break
			end
			if trick:isKindOf("SupplyShortage") then
				testWord(self, "<font color=\"red\">3</font>")
				SupplyShortage = true
				break
			end
		end
		if Indulgence or SupplyShortage then break end
	end
	if Indulgence or SupplyShortage then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if c:getSuitString() == "spade" or c:getSuitString() == "diamond" then
				testWord(self, "<font color=\"red\">4</font>")
				will_use = true
				break
			elseif c:getSuitString() == "club" and Indulgence then
				testWord(self, "<font color=\"red\">5</font>")
				will_use = true
				break
			elseif c:getSuitString() == "heart" and SupplyShortage then
				testWord(self, "<font color=\"red\">6</font>")
				will_use = true
				break
			end
		end
	end
	if will_use then
		testWord(self, "<font color=\"red\">7</font>")
		return sgs.Card_Parse("#zhoufucard:.:")
	end
end

sgs.ai_skill_use_func["#zhoufucard"] = function(card, use, self)
	local target = nil
	local card = nil
	local tricks = nil
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	self:sort(self.friends_noself, "value")
	for _, p in ipairs(self.friends_noself) do
		if not p:getPile("zhoufupile"):isEmpty() then continue end
		tricks = p:getJudgingArea()
		if tricks:length() == 0 then continue end
		for _, trick in sgs.qlist(tricks) do
			if trick:isKindOf("Indulgence") then
				for _,c in ipairs(cards) do
					if c:getSuitString() == "heart" then
						testWord(self, "<font color=\"red\">8</font>")
						target = p
						card = c
						break
					end
				end
				if target and card then break end
			elseif trick:isKindOf("SupplyShortage") then
				for _,c in ipairs(cards) do
					if c:getSuitString() == "club" then
						testWord(self, "<font color=\"red\">9</font>")
						target = p
						card = c
						break
					end
				end
				if target and card then break end
			end
			if target and card then break end
		end
	end
	if not target then
		self:sort(self.enemies, "value")
		for _, p in ipairs(self.enemies) do
			if not p:getPile("zhoufupile"):isEmpty() then continue end
			tricks = p:getJudgingArea()
			if tricks:length() == 0 then continue end
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Indulgence") then
					for _,c in ipairs(cards) do
						if c:getSuitString() ~= "heart" then
							testWord(self, "<font color=\"red\">10</font>")
							target = p
							card = c
							break
						end
					end
					if target and card then break end
				elseif trick:isKindOf("SupplyShortage") then
					for _,c in ipairs(cards) do
						if c:getSuitString() ~= "club" then
							testWord(self, "<font color=\"red\">11</font>")
							target = p
							card = c
							break
						end
					end
					if target and card then break end
				elseif trick:isKindOf("Lightning") then
					for _,c in ipairs(cards) do
						if c:getSuitString() == "spade" and c:getNumber() >= 2 and c:getNumber() <= 9 then
							testWord(self, "<font color=\"red\">12</font>")
							target = p
							card = c
							break
						end
					end
					if target and card then break end
				end
				if target and card then break end
			end
		end
	end
	if not target and self:getOverflow() > 0 and self:hasFriends("friend") then
		for _, p in ipairs(self.friends_noself) do
			if not p:getPile("zhoufupile"):isEmpty() then continue end
			tricks = p:getJudgingArea()
			if tricks:length() == 0 then continue end
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					testWord(self, "<font color=\"red\">13</font>")
					for _,c in ipairs(cards) do
						if c:getSuitString() == "spade" and c:getNumber() >= 2 and c:getNumber() <= 9 then continue end
						target = p
						card = c
						break
					end
					if target and card then break end
				end
			end
			if target and card then break end
		end
	end
	if not target then
		for _, p in ipairs(self.friends_noself) do
			if not p:getPile("zhoufupile"):isEmpty() then continue end
			target = p
			break
		end
	end
	if not card then card = cards[1] end
	if not target then return end
	local card_str = "#zhoufucard:"..card:getId()..":->"..target:objectName()
	local acard = sgs.Card_Parse(card_str)
	assert(acard)
	use.card = acard
	if use.to then
		testWord(self, "<font color=\"red\">14</font>")
		use.to:append(target)
	end
end

sgs.ai_card_intention.zhoufucard = function(self, card, from, tos)
	local to = tos[1]
	if to:getJudgingArea():isEmpty() then
		testWord(self, "<font color=\"red\">15</font>")
		sgs.updateIntention(from, to, -50)
	end
end

sgs.ai_skill_invoke["yingbing"] = true

sgs.ai_chaofeng.zhangbao = 4