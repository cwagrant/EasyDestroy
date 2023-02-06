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
		local spellname = GetSpellInfo(ActionDict.spellID)

		local bag, slot = EasyDestroy.Inventory.FindTradegoodInBags(item)
		
		EasyDestroy.Debug(spellname, bag, slot)

		EasyDestroyButton:SetAttribute("*type1", "macro")
		EasyDestroyButton:SetAttribute("macrotext", string.format(EasyDestroy.Dict.Strings.DestroyMacro, spellname, bag, slot))
		
		EasyDestroy.Debug(EasyDestroyButton:GetAttribute("macrotext"))

	end

end