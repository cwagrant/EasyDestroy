EasyDestroy.API.Destroy = {}

local _API = EasyDestroy.API.Destroy
_API.name = "EasyDestroy.API.Destroy"

function _API.GetDestroyActionForItem(item)

    if item then 
        if item.classID == LE_ITEM_CLASS_ARMOR or item.classID == LE_ITEM_CLASS_WEAPON then
            return EasyDestroy.Enum.Actions.Disenchant
        elseif item.classID == LE_ITEM_CLASS_TRADEGOODS and item.subclassID == 7 then
            return EasyDestroy.Enum.Actions.Prospect
        elseif item.classID == LE_ITEM_CLASS_TRADEGOODS and item.subclassID == 9 then
            return EasyDestroy.Enum.Actions.Mill
        end
    end

    return nil

end

function _API.DestroyItem(item)

	EasyDestroy.Debug("EasyDestroy.API.DestroyItem", item.itemLink)

	local action = EasyDestroy.API.GetDestroyActionForItem(item)

	if action then

		local ActionDict = EasyDestroy.Dict.Actions[action]
		local spellname = GetSpellInfo(ActionDict.spellID)

		local bag, slot = EasyDestroy.API.FindTradegoodInBags(item)

		EasyDestroyButton:SetAttribute("*type1", "macro")
		EasyDestroyButton:SetAttribute("macrotext", string.format(EasyDestroy.Dict.Strings.DestroyMacro, spellname, bag, slot))

	end

end