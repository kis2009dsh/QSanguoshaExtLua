module("extensions.DongSH", package.seeall)
extension = sgs.Package("DongSH")

--dongshihao = sgs.General(extension, "dongshihao", "qun" , 3 , true)  
--linruo     = sgs.General(extension, "linruo"    , "god" , 3 , true)

szg        = sgs.General(extension, "szg" , "god" , 3 , true)

dongshihaolinruo = sgs.General(extension, "dongshihaolinruo", "god" , 3 , true)

juejinglua = sgs.CreateTriggerSkill 
{
	name = "juejinglua",
	events = 
	{ 
		sgs.CardsMoveOneTime,
		sgs.EventPhaseChanging
	},
	priority = 2,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event ,player , data)
		local room        = player:getRoom()
		local HandcardNum = player:getHandcardNum()
		
		if( event == sgs.EventPhaseChanging 
		     and data:toPhaseChange().to ~= sgs.Player_Discard) then
			return false
		end
		
		if( event == sgs.EventPhaseChanging 
			 and data:toPhaseChange().to == sgs.Player_Discard) then
			if( HandcardNum > 4 ) then
				room:askForDiscard(player, "juejing" , HandcardNum - 4 , HandcardNum - 4)
			end
			return true 
		end
		local count = 4 - HandcardNum 
		if( count <= 0 ) then return false end
		player:drawCards(count) 
		return false
	end,
}

longhun_pattern = {} -- to control the card pattern
longhunluavs = sgs.CreateViewAsSkill
{
	name = "longhunluavs",
	n = 1,  --if for normal shenzhaoyun , fix it to 998
	
	view_filter = function(self, selected, to_select)
		if #longhun_pattern == 0 then 
			return false -- nothing can do
		elseif #longhun_pattern == 1 then -- this situation for responsing
			if longhun_pattern[1] == "slash" then 
				return to_select:getSuit() == sgs.Card_Diamond
			elseif longhun_pattern[1] == "jink" then 
				return to_select:getSuit() == sgs.Card_Club
			elseif longhun_pattern[1] == "peach" then 
				return to_select:getSuit() == sgs.Card_Heart
			elseif longhun_pattern[1] == "nullification" then 
				return to_select:getSuit() == sgs.Card_Spade
			elseif longhun_pattern[1] == "slash+peach" then 
				return ((to_select:getSuit() == sgs.Card_Heart) 
						or (to_select:getSuit() == sgs.Card_Diamond))
			end
		end
	end,
	
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = cards[1]
		local number = 0
		if #cards == 1 then 
			number = cards[1]:getNumber() 
		end
		if cards[1]:getSuit() == sgs.Card_Diamond then 
			card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_Diamond, number)
		elseif cards[1]:getSuit() == sgs.Card_Club then 
			card = sgs.Sanguosha:cloneCard("jink", sgs.Card_Club, number)
		elseif cards[1]:getSuit() == sgs.Card_Heart then 
			card = sgs.Sanguosha:cloneCard("peach", sgs.Card_Heart, number)
		elseif cards[1]:getSuit() == sgs.Card_Spade then 
			card = sgs.Sanguosha:cloneCard("nullification", sgs.Card_Spade, number)
		end
		card:setSkillName("longhun")
		for v=1, #cards, 1 do card:addSubcard(cards[v]) end
		return card
	end,
	
	enabled_at_play = function(self, player)
		table.remove(longhun_pattern) -- reset the pattern
		local use_slash, use_peach = false, false
		if (player:hasWeapon("Crossbow") or player:canSlashWithoutCrossbow()) then
			use_slash = true
		end
		if player:isWounded() then 
			use_peach = true 
		end
		if use_slash and not use_peach then 
			table.insert(longhun_pattern, "slash")
		elseif not use_slash and use_peach then 
			table.insert(longhun_pattern, "peach")
		elseif use_slash and use_peach then 
			table.insert(longhun_pattern, "slash+peach")
		end
		return #longhun_pattern ~= 0
	end,

	enabled_at_response = function(self, player, pattern)
		table.remove(longhun_pattern) -- reset the pattern
		if pattern == "slash" or pattern == "jink" or pattern == "nullification" then
			table.insert(longhun_pattern, pattern)
		elseif pattern == "peach" or pattern == "peach+analeptic" then -- for special condition
			table.insert(longhun_pattern, "peach")
		end
		return #longhun_pattern ~= 0
	end,
	
	enabled_at_nullification = function(self , player)
		local Hand_Equip_Cards =  sgs.QList2Table(player:getCards("he"))
		for _, card in ipairs(Hand_Equip_Cards) do
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		return false
	end,
}

juexin = sgs.CreateTriggerSkill  -- Alpha
{
	name = "juexin" ,
	events = {sgs.Predamage} ,
	priority  = 2 ,
	frequency = sgs.Skill_NotFrequent ,
	on_trigger = function( self , event , player , data )
		local room         = player:getRoom()
		local damage_data  = data:toDamage()
		local damage_value = damage_data.damage
		local victim       = damage_data.to
		
		if( not room:askForSkillInvoke( player , "juexin" ) ) then return false end
		
		local log = sgs.LogMessage()
        log.type  = "#TriggerSkill"
		log.from  = player
		log.arg   = "juexin"
		room:sendLog(log)
		room:broadcastSkillInvoke("juexin")
		
		room:loseHp( victim , damage_value )
		
		return true
	end ,
}

shenyoulua = sgs.CreateTriggerSkill   -- Alpha
{
	name = "shenyoulua" ,
	events = {sgs.MaxHpChanged } ,
	priority = 2 ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function( self , event , player , data )
		local room     = player:getRoom()
		local curMaxHp = player:getMaxHp()
		if( curMaxHp < 2 ) then
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(curMaxHp + 1))
			return true
		end
		return false
	end,
}

taijilua = sgs.CreateTriggerSkill
{
	name = "taijilua",
	events = 
	{
		sgs.CardResponsed
	},	
	priority = 2 ,
	frequency = sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data) 

		local card = data:toResponsed().m_card	
		
		if card:isKindOf("Jink") then	
		
			local room = player:getRoom() 
			local damaged = data:toDamage() 
			local source = damaged.from	
			local targets = room:getOtherPlayers(player)	

			if not player:isAlive() then 
				return false 
			end	

			local target = room:askForPlayerChosen(player, targets, "taijilua")	
			room:broadcastSkillInvoke("taijilua")	
			
			local useCardStar = sgs.CardUseStruct()

			useCardStar.card = sgs.Sanguosha:cloneCard("fire_slash" , sgs.Card_Heart , 0 )
			useCardStar.card:setSkillName("taijilua")
			useCardStar.from = player
			useCardStar.to:append(target)

			room:useCard( useCardStar )

			room:setEmotion(player, "good")	
			
			return true
		end	
	end,
}

supershuijian=sgs.CreateTriggerSkill{
	name      = "supershuijian",
	frequency = sgs.Skill_Frequent,
	events    =
	{
		sgs.DrawNCards
	},
	on_trigger=function(self,event,player,data)
        local room = player:getRoom()
        if not player:askForSkillInvoke(self:objectName()) then return end
		room:broadcastSkillInvoke(self:objectName())
		local n = player:getEquips():length()
		data:setValue(data:toInt() + (n + 1)/2)
	end,
}

qx = sgs.CreateTriggerSkill
{
	name = "qx",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Start) then	
			room:askForGuanxing(player,room:getNCards(7),false)
		end
	end,
}

yy = sgs.CreateDistanceSkill
{
	name = "yy",
	correct_func = function(self, from, to)
		if to:hasSkill("yy") then
			return 1
		end
	end,
}

LuawangcaiCard = sgs.CreateSkillCard --王才 已实现
{
	name = "LuawangcaiCard",
	target_fixed = true,
	will_throw = false,
	can_jilei = true,
}

luawangcaivs = sgs.CreateViewAsSkill{
	name = "luawangcaivs" ,
	n = 1 ,
	
	view_filter = function(self, selected, to_select)    
			return true
	end,
	
	view_as = function(self, cards)
			if #cards == 1 then 
				return LuawangcaiCard:clone()        
			end
	end,
	
	enabled_at_play = function()
			return false        
	end,
	
	enabled_at_response = function(self, player, pattern)
			return pattern == "luawangcai"       
	end,
}

luawangcai = sgs.CreateTriggerSkill
{
	name = "luawangcai",
	
	frequency = sgs.Skill_NotFrequent,
	
	events = { sgs.AskForRetrial },
	
	view_as_skill = luawangcaivs,
	
	on_trigger = function(self,event,player,data)

		local room = player:getRoom()
		local judgeStruct = data:toJudge()
		
		local card = room:askForCard(player , "." , "@luawangcai_card:" .. judgeStruct.who:objectName() .. ":" .. judgeStruct.card:objectName() .. ":" .. judgeStruct.reason .. ":" .. judgeStruct.card:getEffectiveId() , data )
		
        if card ~= nil then
		
			room:broadcastSkillInvoke(self:objectName())  --音效  	ok
			room:retrial(card, player, judgeStruct , self:objectName(), true)
			
		end
        return false 
    end,
}

szg:addSkill(qx)
szg:addSkill(yy)

--[[
dongshihao:addSkill("jie")
dongshihao:addSkill("mashu")
dongshihao:addSkill(supershuijian)
dongshihao:addSkill(juejinglua)

linruo:addSkill("jizhi")
linruo:addSkill(luawangcai)
linruo:addSkill(longhunluavs)
linruo:addSkill(taijilua)
]]

dongshihaolinruo:addSkill("jie")
dongshihaolinruo:addSkill("mashu")
dongshihaolinruo:addSkill(supershuijian)
dongshihaolinruo:addSkill(juejinglua)

dongshihaolinruo:addSkill("jizhi")
dongshihaolinruo:addSkill(luawangcai)
dongshihaolinruo:addSkill(longhunluavs)
dongshihaolinruo:addSkill(taijilua)

sgs.LoadTranslationTable
{	
	["DongSH"] = "无间道",
	
	["#szg"] = "七星",
	["szg"] = "诸葛亮",
	
	["qx"] = "七星",
	[":qx"] = "回合开始你必须观看牌堆顶的7张牌并排序或置于牌或底。",
	["yy"] = "月影",
	[":yy"] = "当其它角色计算与你的距离时始终+1。",
	["~szg"] = "天命~",
	["designer:szg"] = "我了割草",
	["cv:szg"] = "我了割草",
	["illustrator:szg"] = "我了割草",
	
	--[[
	["dongshihao"] = "神•董诗浩",
	["#dongshihao"] = "一孤侠道",
	]]
	
	["dongshihaolinruo"] = "神•董诗浩•临若" ,
	["#dongshihaolinruo"] = "一孤侠道•百世王道" , 
	
	["supershuijian"]="侠剑",
	["$supershuijian"] = "纵横侠道,莫过于我",
	[":supershuijian"]="摸牌阶段摸牌时，你可以额外摸(X+1)/2张牌，X为你装备区的牌数量。",
	
	["juejinglua"] = "绝境",
	["$juejinglua"] = "龙战于野,其血玄黄",
	[":juejinglua"] = "<b>锁定技,</b>你的手牌永远不少于4",
	
	["~dongshihaolinruo"] = "侠亡于世,非天之罪也，天欲亡我，非战之罪。" ,
		
	--[[
	["linruo"] = "神 临若",
	["#linruo"] = "百世王道",
	]]
	
	["luawangcai"] = "王才",
	["@luawangcai_card"] = "王才",
	["$luawangcai"] = "天下帝王,唯我独尊",
	[":luawangcai"]  ="任意判定牌生效前你可以用你的一张手牌替换之",
	["~luawangcai"]  ="任意判定牌生效前你可以用你的一张手牌替换之",
	["@luawangcai"]  ="请选择一张牌",
	["#luawangcai"]  ="受到 %from 【%arg】技能的影响，%to 被修改了判定",
	["#luawangcaidebug"] = "Debug  %arg" ,
	
	["taijilua"] = "太极",
	["$taijilua"] = "重意不重形,四两拨千斤",
	[":taijilua"] = "当你打出一张闪时,可以视作对任一玩家出一张红桃火杀",

	["longhunluavs"] = "龙魂",
	[":longhunluavs"] = "你可以按下列规则使用（或打出）一张牌：红桃当【桃】，方块当火属性的【杀】，梅花当【闪】，黑桃当【无懈可击】",
	
	--["~linruo"] = "天亡我也，非战之罪也",
	
	["$longhunluavs1"]="金甲映日,驱邪祛秽", -- spade
	["$longhunluavs2"]="腾龙行云,首尾不见", -- club
	["$longhunluavs3"]="潜龙于渊,涉灵愈伤", -- heart
	["$longhunluavs4"]="千里一怒,红莲灿世", -- diamond
	["$juejinglua"] = "哼!" , 

}


