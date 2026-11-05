EasyDestroy.Destroy = {}

EasyDestroy.Destroy.name = "EasyDestroy.Destroy"

function EasyDestroy.Destroy.GetDestroyActionForItem(item)

    if item then 
        if item.classID == Enum.ItemClass.Armor or item.classID == Enum.ItemClass.Weapon then
            return EasyDestroy.Enum.Actions.Disenchant
        elseif item.classID == Enum.ItemClass.Tradegoods and item.subclassID == 7 then
            return EasyDestroy.Enum.Actions.Prospect
        elseif item.classID == Enum.ItemClass.Tradegoods and item.subclassID == 9 then
            return EasyDestroy.Enum.Actions.Mill
        end
    end

    return nil

end

function EasyDestroy.Destroy.DestroyItem(item)

	local action = EasyDestroy.Destroy.GetDestroyActionForItem(item)
	EasyDestroy.Debug("Destroy Action", action)

	if action then

		local ActionDict = EasyDestroy.Dict.Actions[action]
		local spellname = C_Spell.GetSpellName(ActionDict.spellID)

		local bag, slot = EasyDestroy.Inventory.FindTradegoodInBags(item)
		
		EasyDestroy.Debug(spellname, bag, slot)

		-- No usable item (e.g. the last one is still being destroyed). Don't set a spell, otherwise
		-- it gets cast with no target and the player is left with a targeting cursor.
		if not bag or not slot then return end

		-- Cast directly on the bag slot rather than via macrotext. A macro can't run while another is
		-- already running, so macrotext silently fails when the button is used from /click in a macro.
		EasyDestroyButton:SetAttribute("*type1", "spell")
		EasyDestroyButton:SetAttribute("spell", spellname)
		EasyDestroyButton:SetAttribute("target-bag", bag)
		EasyDestroyButton:SetAttribute("target-slot", slot)

	end

end