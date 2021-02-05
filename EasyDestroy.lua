--Addon settings
EasyDestroy = EasyDestroy

local separatorInfo = {
	owner = EasyDestroyDropDown;
	hasArrow = false;
	dist = 0;
	isTitle = true;
	isUninteractable = true;
	notCheckable = true;
	iconOnly = true;
	icon = "Interface\\Common\\UI-TooltipDivider-Transparent";
	tCoordLeft = 0;
	tCoordRight = 1;
	tCoordTop = 0;
	tCoordBottom = 1;
	tSizeX = 0;
	tSizeY = 8;
	tFitDropDownSizeX = true;
	iconInfo = {
		tCoordLeft = 0,
		tCoordRight = 1,
		tCoordTop = 0,
		tCoordBottom = 1,
		tSizeX = 0,
		tSizeY = 8,
		tFitDropDownSizeX = true
	},
};

function EasyDestroy:Initialize()
	--[[ Title Bar ]]--
	EasyDestroyFrame.Title:SetFontObject("GameFontHighlight");
	EasyDestroyFrame.Title:SetText("Easy Destroy");		
	
	--[[ Frame Movement Information ]]--
	EasyDestroyFrame.TitleBar:EnableMouse(true)
	EasyDestroyFrame.TitleBar:SetScript("OnMouseDown", function(self, button)
	  if button == "LeftButton" and not EasyDestroyFrame.isMoving then
	   EasyDestroyFrame:StartMoving();
	   EasyDestroyFrame.isMoving = true;
	  end
	end)
	EasyDestroyFrame.TitleBar:SetScript("OnMouseUp", function(self, button)
	  if button == "LeftButton" and EasyDestroyFrame.isMoving then
	   EasyDestroyFrame:StopMovingOrSizing();
	   EasyDestroyFrame.isMoving = false;
	  end
	end)
	EasyDestroyFrame.TitleBar:SetScript("OnHide", function(self)
	  if ( EasyDestroyFrame.isMoving ) then
	   EasyDestroyFrame:StopMovingOrSizing();
	   EasyDestroyFrame.isMoving = false;
	  end
	end)
	
	--[[ Item View Scrolling Area ]]--
	EasyDestroyItems:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize=16,
		tile=true, 
		tileEdge=false, 
		insets={left=4, right=4, top=4, bottom=4}
	})
	EasyDestroyItems:SetBackdropColor(0,0,0,0.5)
		
	EasyDestroyFrameSearchTypes.Search.label:SetText("Searches")
	EasyDestroyFrameSearchTypes.Search:SetChecked(true)
	EasyDestroyFrameSearchTypes.Blacklist.label:SetText("Blacklists")

	--[[ Filter View Area ]]--
	UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)
		
	--[[ Test Button for debugging various information ]]--
	EasyDestroy.EasyDestroyTest = CreateFrame("Button", "EDTest", EasyDestroyFrame, "UIPanelButtonTemplate")
	EasyDestroy.EasyDestroyTest:SetSize(80, 22)
	EasyDestroy.EasyDestroyTest:SetPoint("BOTTOMLEFT", EasyDestroyFrame, "TOPLEFT", 0, 4)
	EasyDestroy.EasyDestroyTest:SetText("Test")
	EasyDestroy.EasyDestroyTest:SetScript("OnClick", function(self)
		print("CountItemsFound", #EasyDestroy:FindItemsToDestroy(EasyDestroy.CurrentFilter) or 0)
		print("Filter", UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown))
		pprint(EasyDestroy.CurrentFilter)
	end)
	
	if EasyDestroy.DebugActive then
		EasyDestroy.EasyDestroyTest:Show()
	else
		EasyDestroy.EasyDestroyTest:Hide()
	end

end


function EasyDestroy_InitDropDown()
	local info = UIDropDownMenu_CreateInfo()
	local favoriteID = nil
	info.text, info.value, info.checked, info.func, info.owner = "New Filter...", 0, false, EasyDestroy_DropDownSelect, EasyDestroyDropDown
	UIDropDownMenu_AddButton(info)
	local hasSeparator = false
	local includeSearches, includeBlacklists = EasyDestroy:IncludeSearches(), EasyDestroy:IncludeBlacklists()

	-- This monstrosity sorts by type=type and name<name or type<type
	-- e.g. if types match, sort by name, otherwise sort by type
	if EasyDestroy.Data.Filters then
		for fid, filter in EasyDestroy.spairs(EasyDestroy.Data.Filters, function(t, a, b) return (t[a].properties.type == t[b].properties.type and t[a].properties.name:lower() < t[b].properties.name:lower()) or t[a].properties.type < t[b].properties.type end) do
			info.text, info.value, info.checked, info.func, info.owner = filter.properties.name, fid, false, EasyDestroy_DropDownSelect, EasyDestroyDropDown

			if EasyDestroy.DebugActive then
				info.text = filter.properties.name .. " | " .. fid
			end
			if filter.properties.type == ED_FILTER_TYPE_SEARCH and includeSearches then
				UIDropDownMenu_AddButton(info)
				if filter.properties.favorite == true then
					favoriteID = info.value
				end
			elseif filter.properties.type == ED_FILTER_TYPE_BLACKLIST and includeBlacklists then
				if not hasSeparator and includeSearches then
					UIDropDownMenu_AddButton(separatorInfo)
					hasSeparator = true
				end
				UIDropDownMenu_AddButton(info)
			end
		end
	end
end

function EasyDestroySearchTypes_OnClick()
	EasyDestroy_InitDropDown()
	local favoriteID = nil
	for fid, filter in pairs(EasyDestroy.Data.Filters) do
		if filter.properties.favorite == true then
			favoriteID = fid
		end
	end

	if not(EasyDestroy:IncludeSearches()) and not(EasyDestroy:IncludeBlacklists()) then
		UIDropDownMenu_SetText(EasyDestroyDropDown, 'You must select at least one type of filter.')
	elseif EasyDestroy:IncludeSearches() and favoriteID then
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, favoriteID)
		EasyDestroy_LoadFilter(favoriteID)
		EasyDestroy_Refresh()
	else
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
	end
end

function EasyDestroy_UpdateItemFrame(frame, item)
	frame.Icon:SetTexture(GetItemIcon(item.itemlink))
	frame.Item:SetText(GetItemInfo(item.itemlink))
	frame.Item.itemLink = item.itemlink
	local ilvl = select(1, GetDetailedItemLevelInfo(item.itemlink))
	if ilvl then
		frame.ItemLevel:SetText("(" .. ilvl .. ")")
	else
		frame.ItemLevel:SetText("")
	end
	
	return frame
end

function EasyDestroy:FindItemsToDestroy(filter)
	-- item = {keyinteger, bag, slot, itemlink}
	local matchfound = nil
	local items = {}
	local itemkey = 0
	local filterRegistry = EasyDestroyFilters.Registry
	
	for bag = 0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do
			matchfound = nil
			local item = {};
			item.link = select(7, GetContainerItemInfo(bag, slot));
			if item.link then 
				item.name, _, item.quality, item.level, _, item._type, item._subtype, item.stack, item.slot, item.icon, item.price, item.type, item.subtype = GetItemInfo(item.link);
				item.mog = EasyDestroyFilters:HaveTransmog(item.link);
				item.id = GetContainerItemID(bag, slot);
				item.bindtype = select(14, GetItemInfo(item.link))

				if not item.name then -- Because unlike Jim Croce, Mythic Keystones do not, in fact, have a name.
					item.name = "Blizzard Didn't Name This Item"
				end

				for k, v in pairs(filterRegistry) do
					if v.GetItemInfo ~= nil and type(v.GetItemInfo) == 'function' then 
						item[k] = v:GetItemInfo(item.link, bag, slot)
					end
				end
				
				
				for k, v in pairs(filter.filter) do
					if not filterRegistry[k] then
						print("Unsupported filter: " .. k)
					else
						if not filterRegistry[k]:Check(v, item) then
							matchfound = false
							break
						end
					end
					matchfound = true
				end
				
				--[[ Filter out types/subtypes that don't matter for the current action ]]--
				local typematch = false
				if matchfound then
					for k, v in ipairs(EasyDestroy.DestroyFilters[EasyDestroy.DestroyAction]) do
						if v.itype == item.type then
							if not v.stype then
								typematch = true
							elseif v.stype == item.subtype then
								typematch = true
							end
						end
					end
				end

				-- [[ PLACEHOLDER: BLACKLIST LOGIC ]]
				-- if there was a match so far, then lets check it against blacklists
				-- if the filter we are looking at is a blacklist, then lets ignore this
				-- so that we can see what items would be caught by the blacklist filter we are creating
				if matchfound and filter.properties.type ~= ED_FILTER_TYPE_BLACKLIST then 
					for fid, blacklist in pairs(EasyDestroy.Data.Filters) do
						if blacklist.properties.type == ED_FILTER_TYPE_BLACKLIST then 
							for k, v in pairs(blacklist.filter) do
								if not filterRegistry[k] then
									printed("Unsupported filter: " .. k)
								else
									if filterRegistry[k]:Check(v, item) then
										matchfound = false
										break
									end
								end
							end
						end
						-- we found a match in the blacklist, so disregard this item and quit searching additional blacklists
						if not matchfound then break end
					end
				end
				
				-- can't typically disenchant cosmetic items. This filters them out (hopefully)
				-- Not sure about cosmetic weapons...
				if item.type==LE_ITEM_CLASS_ARMOR and item.subtype == LE_ITEM_ARMOR_COSMETIC then
					matchfound = false
				end
				
				if matchfound and typematch then
					tinsert(items, {itemkey=itemkey, bag=bag, slot=slot, itemlink=item.link})
					itemkey = itemkey + 1
				end
			end
		end
	end
	return items
end

function EasyDestroy:DisenchantItem()

	if not EasyDestroyFrame:IsVisible() then
		EasyDestroyFrame:Show()
		return
	end

	local iteminfo = EasyDestroyItemsFrameItem1.info or nil
	local bag, slot
	
	if iteminfo ~= nil then
		bag, slot = iteminfo.bag, iteminfo.slot	
	end
	
	if not IsSpellKnown(13262) then
		print ("You must have disenchanting to disenchant this item.")
		return
	elseif not IsUsableSpell(13262) then
		print("You cannot disenchant that item right now.")
		return
	elseif #GetLootInfo() > 0 then
		if not EasyDestroy.WarnedLootOpen then
			print("Unable to disenchant while loot window is open.")
			EasyDestroy.WarnedLootOpen = true
			-- lets only warn people every so often, don't want to fill their chat logs if they spam click.
			C_Timer.After(30, function()
				EasyDestroy.WarnedLootOpen = false
			end
			)
		end
		return
	elseif IsCurrentSpell(13262) then
		-- fail quietly as they are already casting
		return
	elseif iteminfo == nil then
		return
	end

	local spellname = GetSpellInfo(13262)
		
	if(GetContainerItemInfo(bag, slot) ~= nil)then
		EasyDestroy.Debug(format("Disenchanting item at (bag, slot): %d %d", bag, slot))
		EasyDestroyButton:SetAttribute("type1", "macro")
		EasyDestroyButton:SetAttribute("macrotext", format("/cast %s\n/use %d %d", spellname, bag, slot))
	end	
	-- Disable the button while we process the item being destroyed.
	-- We'll reenable it when we update the item scroll frame via a
	-- callback
	EasyDestroyButton:Disable()
end

function EasyDestroyItemsScrollBar_Update(callbackFunction)
	local filter = EasyDestroy.CurrentFilter
	local itemList = EasyDestroy:FindItemsToDestroy(filter)
	FauxScrollFrame_Update(EasyDestroyItemsFrameScrollFrame, #itemList, 8, 24)
	
	if #itemList > 8 then
		EasyDestroyItems:SetPoint("TOPRIGHT", EasyDestroyFrameDialogBG, "TOPRIGHT",  -28, 0)
	else
		EasyDestroyItems:SetPoint("TOPRIGHT", EasyDestroyFrameDialogBG, "TOPRIGHT", -4, 0)
	end
	
	local offset = FauxScrollFrame_GetOffset(EasyDestroyItemsFrameScrollFrame)
	for i=1, 8, 1 do
		local index = offset+i
		local frame = _G['EasyDestroyItemsFrameItem'..i]
		if index <= #itemList then
			local item = itemList[index]
			EasyDestroy_UpdateItemFrame(frame, item)
			local r,g,b = GetItemQualityColor(C_Item.GetItemQualityByID(item.itemlink))
			frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",})
			frame:SetBackdropColor(r,g,b, 0.5)
			frame.info = item
			frame:Show()
		else
			frame:Hide()
			frame.info = nil
		end
	end

	if callbackFunction ~= nil and type(callbackFunction) == "function" then
		callbackFunction()
	end
	EasyDestroy.Debug("Completed Scroll Frame Update")
end

function EasyDestroy_ToggleFilters()
	if EasyDestroyFilters:IsVisible() then
		EasyDestroyFilters:Hide()
		EasyDestroy_OpenFilters:SetText("Show Filters")
	else
		EasyDestroyFilters:Show()
		EasyDestroy_OpenFilters:SetText("Hide Filters")
	end
end

function EasyDestroy:IncludeBlacklists()
	return EasyDestroyFrameSearchTypes.Blacklist:GetChecked()
end

function EasyDestroy:IncludeSearches()
	return EasyDestroyFrameSearchTypes.Search:GetChecked()
end

function EasyDestroy:SelectAllFilterTypes()
	EasyDestroyFrameSearchTypes.Blacklist:SetChecked(true)
	EasyDestroyFrameSearchTypes.Search:SetChecked(true)
end

-- Function of the window drop down, moved from Main.
function EasyDestroy_DropDownSelect(self, arg1, arg2, checked)
	EasyDestroy.Debug("SetSelectedValue", self.value)
	EasyDestroy.FilterSaveWarned = false
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, self.value)
	if self.value == 0 then
		EasyDestroy_ClearFilterFrame()
		EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
	else
		EasyDestroy_LoadFilter(self.value)
		EasyDestroy.CurrentFilter = EasyDestroy.Data.Filters[self.value]
		EasyDestroy.CurrentFilter.fid = self.value
	end
	EasyDestroy_Refresh()
end