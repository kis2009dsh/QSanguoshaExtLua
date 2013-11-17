--[[ DSH Begin]]

local longhunluavs_skill={}
longhunluavs_skill.name="longhunluavs"

table.insert(sgs.ai_skills, longhunluavs_skill)

longhunluavs_skill.getTurnUseCard = function(self)

	local cards = sgs.QList2Table(self.player:getCards("he"))

	self:sortByLongHunUseValue(cards,true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() then
			return sgs.Card_Parse(("fire_slash:longhun[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		end
	end
end

sgs.ai_view_as.longhunluavs = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()

	if card:getSuit() == sgs.Card_Diamond then
		return ("fire_slash:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Club then
		return ("jink:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Heart then
		return ("peach:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Spade then
		return ("nullification:longhun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.longhunluavs_suit_value = {
	heart = 7,
	spade = 5,
	club = 5,
}

sgs.ai_suit_priority.longhunluavs= "diamond|club|spade|heart"

function sgs.ai_cardneed.longhunluavs(to, card, self)
	if to:getCards("he"):length() <= 2 then return true end
	return card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade
end

sgs.ai_skill_playerchosen.taijilua = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_cardask["@luawangcai_card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("h")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local card_id = self:getLongHunRetrialCardId(cards, judge)
	
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			self:sortByLongHunUseValue(cards,true)
			if self:getLongHunUseValue(judge.card) >= self:getLongHunUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getLongHunUseValue(judge.card) >= self:getLongHunUseValue(sgs.Sanguosha:getCard(card_id)) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end
	
	return "."
end

sgs.ai_skill_discard.juejinglua = function(self, discard_num, min_num, optional, include_equip)
	self:assignKeep(self:assignKeepNum(), true)
	if optional then 
		return {} 
	end
	local flag = "h"
	local equips = self.player:getEquips()
	-- if include_equip and not (equips:isEmpty() or self.player:isJilei(equips:first())) then flag = flag .. "e" end
	local cards = self.player:getCards(flag)
	local to_discard = {}
	cards = sgs.QList2Table(cards)
	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if self:hasSkills(sgs.lose_equip_skill) then 
			return 5
		else 
			return 0 
		end
		return 0
	end
	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then return aux_func(a) < aux_func(b) end
		return self:getLongHunKeepValue(a) < self:getLongHunKeepValue(b)
	end

	table.sort(cards, compare_func)
	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num -1
	end
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) then 
			table.insert(to_discard, card:getId()) 
		end
		if (self.player:hasSkill("qinyin") and #to_discard >= least) or #to_discard >= discard_num then 
			break 
		end
	end
	return to_discard
end

--[[ DSH End]]