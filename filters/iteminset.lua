local filter = EasyDestroyFilterCriteria:New("Ignore Items in Equipment Sets", "eqset", 20)

function filter:Initialize()
    self.frame = self.frame or CreateFrame("Frame", "EDFilterItemInSet", self.parent)
    self.checkbox = filter.checkbox or CreateFrame("CheckButton", "EDFilterItemInSetCheck", self.frame, "EasyDestroyCheckboxTemplate")
    self.checkbox:SetPoint("LEFT")
    self.checkbox:SetLabel(filter.name)
    self.checkbox:SetScript("OnClick", EasyDestroy_Refresh)
    
    self.frame:Hide()

    self.scripts.OnClick = { self.checkbox, }
end

function filter:GetItemInfo(itemlink, bag, slot)
	local sets = C_EquipmentSet.GetEquipmentSetIDs();
	
	for _, setid in pairs(sets) do
		local items = C_EquipmentSet.GetItemLocations(setid)
		if items then
			for _, locid in pairs(items) do
				local equipped, bank, bags, void, slotnum, bagnum = EquipmentManager_UnpackLocation(locid);
				if bagnum==bag and slotnum==slot then
					return true
				end
			end
		end
	end
	return false
end

function filter:Check(excludeset, item)
    local inset = item.eqset
    if excludeset and inset then 
        return false
    else
        return true
    end

end

function filter:Blacklist(excludeset, item)
    local inset = item.eqset
    if excludeset and inset then
        return true
    else
        return false
    end
end


function filter:GetValues()
    if self.frame then
        if self.checkbox:GetChecked() then
            return true
        else
            return false
        end
    end
    return nil
end

function filter:SetValues(values)
    if self.frame then
        if values == "" then
            self.checkbox:SetChecked(false)
        else
            self.checkbox:SetChecked(values)
        end
    end
end

function filter:Clear()
    if self.frame then
        self.checkbox:SetChecked(false)
    end
end

EasyDestroy:RegisterCriterion(filter)