--Addon settings
EasyDestroy = EasyDestroy
local EDFramePool = {}
local FP_UID = 1
local ED_SearchInProgress = false

--[[ TODO 
disable button while looting
reenable button after looting

the plan
 [x] Item Filter (similar to the easyscrap addon)
 [x] Save Filter
 [x] List items in the scrollframe
 [x] Each time an item in the frame is disenchanted, remove it from the frame and clean frame positions
 [x] Click "Disenchant" button to disenchant items in filter
 [x] Make it so that the Disenchant button can be a macro you can spam
 [x] Rewrite the function for finding items to disenchant to use the filters and instead of running on each click it will instead
	run once, create a list of items based on bag/slot position and when item is disenchanted it is removed from this list.

- Item Filters todo
	It works, just need to make it use the fields on the frame
	Once the fields work, need to add the ability to save
	a filter for future use. Then need a drop down for
	filters. Will need some sort of delete button
	for deleting existing buttons.
	Clear button to clear the filter fields (including drop
	down field).
 
- Cleanup todo
	Need to separate the base frame and event registration/handling
	from the rest of the helper functions.
	
	May separate functions by what area they work for.
	
	Cleanup/refactor code.
	
- Updating filters
	Want to turn allow combining multiple filters together.
	E.g. Could have 1 "filter" that combines disenchanting blue tidespray bracers and epic LW bracers.
	So it would be FilterGroups that have filters inside them and all items that match at least 1 of the filters would be included.
	Might be a bit excessive? Still need to do a drop down and allow saving a filter.

- Idea - Filter 2.0
Opens new window
Allows for multiple entries, user can search for an item and add it to the filter.
E.g.
 filter.items = {item1, item2, item3} 
 filter export
 filter import
 
Allow for blacklist and whitelist. Whitelist > Blacklist
E.g.
	filter.blacklist.quality = {3, 4} --don't show rare or epic items
	filter.whitelist.items = {epicitem, rareitem} --but show these
	
And/Or Functionality?
E.g.
	filter.blacklist.filter1.items = {item}
	filter.blacklist.filter1.
 
]]--
SLASH_OPENUI1 = "/edestroy";
SLASH_OPENUI2 = "/ed";
function SlashCmdList.OPENUI(msg)
	if msg == "list" then
		for key, item in ipairs(EasyDestroy.ItemPool) do
			print(string.format("%i,%i,%i,%s", key, item.info.bag, item.info.slot, C_Item.GetItemNameByID(item.info.itemlink)))
		end
	else
		if EasyDestroyFrame:IsVisible() then
			EasyDestroyFrame:Hide()
		else
			EasyDestroyFrame:Show()
		end
	end
end

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
	EasyDestroyFrameScrollFrame:SetScrollChild(EasyDestroyFrameScrollChild);
	EasyDestroyFrameScrollParent:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize=16,
		tile=true, 
		tileEdge=false, 
		insets={left=4, right=4, top=4, bottom=4}
	})
	EasyDestroyFrameScrollParent:SetBackdropColor(0,0,0,0.5)
	
	EasyDestroy.ItemPool = {}
	
	--[[ Filter View Area ]]--
	UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)
	EasyDestroyFilterName.label:SetText("Filter Name:")
	EasyDestroyNameSearch.label:SetText("Item Name:")
	EasyDestroyItemID.label:SetText("Item ID:")
	EasyDestroyItemID.input:SetNumeric(true)
	EasyDestroyRarityCommon.label:SetText("|c11ffffff" .. "Common" .. "|r")
	EasyDestroyRarityRare.label:SetText("|c110070dd" .. "Rare" .. "|r")
	EasyDestroyRarityUncommon.label:SetText("|c111eff00" .. "Uncommon" .. "|r")
	EasyDestroyRarityEpic.label:SetText("|c11a335ee" .. "Epic" .. "|r")
		
	--[[ Test Button for debugging various information ]]--
	EasyDestroy.EasyDestroyTest = CreateFrame("Button", "EDTest", EasyDestroyFrame, "UIPanelButtonTemplate")
	EasyDestroy.EasyDestroyTest:SetSize(80, 22)
	EasyDestroy.EasyDestroyTest:SetPoint("BOTTOMLEFT", EasyDestroyFrame, "TOPLEFT", 0, 4)
	EasyDestroy.EasyDestroyTest:SetText("Test")
	EasyDestroy.EasyDestroyTest:SetScript("OnClick", function(self)
		print("SizeOfFramePool", #EDFramePool['EasyDestroyItemTemplate'] or 0)
		print("SizeOfItemPool", #EasyDestroy.ItemPool or 0)
		print("CommonCheckbox", EasyDestroyRarityCommon:GetChecked())
		print("UncommonCheckbox", EasyDestroyRarityUncommon:GetChecked())
		print("RareCheckbox", EasyDestroyRarityRare:GetChecked())
		print("EpicCheckbox", EasyDestroyRarityEpic:GetChecked())
		print("Filter")
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
	info.text, info.value, info.checked, info.func = "New Filter...", 0, false, EasyDestroy_DropDownSelect
	UIDropDownMenu_AddButton(info)
	
	for fid, filter in pairs(EasyDestroy.Data.Filters) do
		info.text, info.value, info.checked, info.func = filter.properties.name, fid, false, EasyDestroy_DropDownSelect
		UIDropDownMenu_AddButton(info)
	end
end

function EasyDestroy:CreateItemFrame(parent, itemLink)
	local frame = EasyDestroy:GetFrameFromPool("EasyDestroyItemFrame"..FP_UID, parent, "EasyDestroyItemTemplate")
	FP_UID = FP_UID + 1
	frame.Icon:SetTexture(GetItemIcon(itemLink))
	frame.Item:SetText(GetItemInfo(itemLink))
	frame.Item.itemLink = itemLink
	
	return frame
end

function EasyDestroy:GetFrameFromPool(name, parent, template)
	local pool
	if template then
		if not EDFramePool[template] then
			EDFramePool[template] = {}
		end
		pool = EDFramePool[template]
	else
		pool = EDFramePool
	end
	
	for _, frame in ipairs(pool) do
		if frame.inuse == false then
			frame.inuse = true
			frame:SetParent(parent)
			frame:Show();
			return frame
		end
	end
	
	local frame
	frame = CreateFrame("FRAME", name, parent, template)
	frame.inuse = true
	tinsert(pool, frame)
	return frame

end

--[[
want to have filters that users create similar to Easy Scrap.

filters = {
	Armor Type = Cloth, Leather, Mail, Plate
	Bags = Backpack, Bags 1-4
	Bind Type = BOE, BOP
	Equipment Set = true/false
	Item Level = Min, Max
	Item Name = string
	Item Quality = Common, Uncommon, Rare, Epic
	Item Slot = Equip slots
	Item Type = Armor, Weapon, Trade Good
	Sell Price = Min, Max
	Item ID = integer to lookup
	Transmog = (have or not, true/false)
	Weapon Type = Axe, Sword, Bow, etc.
	}
	
]] 

function EasyDestroy:FindItemsToDestroy(filter)
	-- item = {keyinteger, bag, slot, itemlink}
	local matchfound = nil
	local items = {}
	local itemkey = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do
			item = {};
			item.link = select(7, GetContainerItemInfo(bag, slot));
			if item.link then 
				item.name, _, item.quality, item.level, _, item._type, item._subtype, item.stack, item.slot, item.icon, item.price, item.type, item.subtype = GetItemInfo(item.link);
				item.eqset = EasyDestroy.ItemInEquipmentSet(bag, slot);
				item.mog = EasyDestroy.HaveTransmog(item.link);
				item.id = GetContainerItemID(bag, slot);
				
				if not item.name then -- Because unlike Jim Croce, Mythic Keystones do not, in fact, have a name.
					item.name = "NO_NAME_ITEM"
				end
				
				
				for k, v in pairs(filter) do
					if k == "quality" then 
						if not tContains(v, item[k]) then
							matchfound = false
							break
						end
					elseif k == "name" then
						if not string.find(string.lower(item[k]), string.lower(v)) then
							matchfound = false
							break
						end
					elseif v ~= item[k] then
						matchfound = false
						break
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
				
				if matchfound and typematch then
					tinsert(items, {itemkey=itemkey, bag=bag, slot=slot, itemlink=item.link})
					itemkey = itemkey + 1
				end
			end
		end
	end
	return items
end

function EasyDestroy:ItemInFilter(item, filter)
	if filter.multifilter then
		
	end
end

function EasyDestroy.ItemInEquipmentSet(bag, slot)
	local sets = C_EquipmentSet.GetEquipmentSetIDs();
	
	for _, setid in pairs(sets) do
		local items = C_EquipmentSet.GetItemLocations(setid)
		if items then
			for _, locid in pairs(items) do
				equipped, bank, bags, void, slotnum, bagnum = EquipmentManager_UnpackLocation(locid);
				if bagnum==bag and slotnum==slot then
					return true
				end
			end
		end
	end
	return false
end

function EasyDestroy.HaveTransmog(itemlink)
	local appearance = C_TransmogCollection.GetItemInfo(itemlink);
	if apperance then 
		local sources = C_TransmogCollection.GetAppearanceSources(appearance);
		if sources then
			for k, v in pairs(sources) do
				if v.isCollected then
					return true
				end
			end
		end
	end
	return false
end

function EasyDestroy:DisenchantItem()
	-- Made more sense that you would want to see which item is being destroyed next, rather than going in reverse. This will destroy Item1 in the list.
	local key = 1 --#EasyDestroy.ItemPool
	local frame = EasyDestroy.ItemPool[key]
	local bag, slot = frame.info.bag, frame.info.slot
		
		if EasyDestroy.Debug then
		print('Disenchanting...')
		print(key, bag, slot)
	end
	
	if(GetContainerItemInfo(bag, slot) ~= nil) then
		print(format("Disenchanting item at (bag, slot): %d %d", bag, slot))
		EasyDestroyButton:SetAttribute("type1", "macro")
		EasyDestroyButton:SetAttribute("macrotext", format("/cast Disenchant\n/use %d %d", bag, slot))
	end	
	EasyDestroyButton:Disable()
	
	--Note: Used 2 second timer because that seemed to be the best
	--way to make sure that everything that needed to happen has
	--happened.
	-- As an alternative could maybe bind this to events for LOOT_OPENED and LOOT_CLOSED which might work pretty well.
	-- That would be a decent way to make sure the user couldn't click disenchant when loot is pending.
	local _, _, _, castTime, _, _ = GetSpellInfo(13262)
	castTime = castTime/1000 --convert to seconds
	C_Timer.After(castTime+2, function() 
		EasyDestroyButton:Enable() 
		end
	)
end

function EasyDestroy.ClearItem(key)
	frame = EasyDestroy.ItemPool[key]
	frame:Hide()
	frame.inuse = false
	table.remove(EasyDestroy.ItemPool, key)
end

function EasyDestroy:ClearItems()
	--[[ TODO, figure out why the ItemPool appears to be resetting
	in the middle of loading. It makes it so that the framepool
	has to be completely reset rather than just the itempool
	]]--
	for key, frame in ipairs(EasyDestroy.ItemPool) do
		print(string.format("Delete key %i from ItemPool", key))
		EasyDestroy.ClearItem(key)
	end
	
	if EDFramePool['EasyDestroyItemTemplate'] then
		for key,frame in ipairs(EDFramePool['EasyDestroyItemTemplate']) do
			frame:Hide()
			frame.inuse = false
		end
	end
end

function EasyDestroy:PopulateSearch(filterObject)	
	if EasyDestroy.Debug then
		print("Populating...")
	end
	local anchor, counter
	local filter = filterObject["filter"] or EasyDestroy.EmptyFilter
	
	counter = 1
	for _, info in ipairs(EasyDestroy:FindItemsToDestroy(filter)) do
		local frame = EasyDestroy:CreateItemFrame(EasyDestroyFrameScrollChild, info.itemlink)
		if anchor then
			frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
			frame:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
		else
			frame:SetPoint("TOPLEFT", EasyDestroyFrameScrollChild)
			frame:SetPoint("TOPRIGHT", EasyDestroyFrameScrollChild, 0, 0)
		end
		frame:SetHeight(24)
		local r,g,b = GetItemQualityColor(C_Item.GetItemQualityByID(info.itemlink))
		frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",})
		frame:SetBackdropColor(r,g,b, 0.5)
		frame.info = info
		tinsert(EasyDestroy.ItemPool, frame)
		anchor = frame
		counter = counter+1
	end
	
	EasyDestroyFrameScrollChild:SetHeight((counter*20)+5) -- For some reason even though height is set to 24, if i multiply by 24 I get a lot of extra space
end

function EasyDestroy:GenerateFilter()
	local filterObj = {}
	filterObj.properties = {}
	filterObj.filter = {}
	local filter_name = EasyDestroyFilterName.input:GetText()
	local entry_id = EasyDestroyItemID.input:GetNumber()
	local entry_name = strtrim(EasyDestroyNameSearch.input:GetText())
	
	if not filter_name or filter_name == "" then 
		filter_name = "Filter" .. tostring(EasyDestroy.FilterCount + 1)
	end
		
	filterObj.properties.name = filter_name
	filterObj.properties.favorite = false
	
	if entry_id > 0 then filterObj.filter.id = entry_id end
	if entry_name ~= "" then filterObj.filter.name = entry_name end
	
	if(EasyDestroyRarityCommon:GetChecked() or EasyDestroyRarityUncommon:GetChecked() or EasyDestroyRarityRare:GetChecked() or EasyDestroyRarityEpic:GetChecked()) then
		filterObj.filter.quality = {}
		if EasyDestroyRarityCommon:GetChecked() then tinsert(filterObj.filter.quality, Enum.ItemQuality.Common) end
		if EasyDestroyRarityUncommon:GetChecked() then tinsert(filterObj.filter.quality, Enum.ItemQuality.Uncommon) end
		if EasyDestroyRarityRare:GetChecked() then tinsert(filterObj.filter.quality, Enum.ItemQuality.Rare) end
		if EasyDestroyRarityEpic:GetChecked() then tinsert(filterObj.filter.quality, Enum.ItemQuality.Epic) end
	end
	
	return filterObj
end

function EasyDestroy_SaveFilter()
	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	EasyDestroy.FilterCount = 0
	
	for _, v in pairs(EasyDestroy.Data.Filters) do
		EasyDestroy.FilterCount = EasyDestroy.FilterCount + 1
	end
	
	if FilterID == 0 then
		FilterID = "FilterID" .. EasyDestroy.FilterCount + 1
	end
	EasyDestroy:Debug("Saving Filter", FilterID)
	EasyDestroy.Data.Filters[FilterID] = EasyDestroy:GenerateFilter()
end

function EasyDestroy_DeleteFilter()
	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	EasyDestroy:Debug("Deleting Filter", FilterID)
	
	EasyDestroy.Data.Filters[FilterID] = nil
end

function EasyDestroy_ClearFilterFrame()
	EasyDestroyFilterName.input:SetText("")
	EasyDestroyItemID.input:SetText("")
	EasyDestroyNameSearch.input:SetText("")
	local quality = {EasyDestroyRarityCommon, EasyDestroyRarityUncommon, EasyDestroyRarityRare, EasyDestroyRarityEpic}
	for _, v in ipairs(quality) do
		v:SetChecked(false)
	end
end

function EasyDestroy_LoadFilter(fid)
	EasyDestroy:Debug("Loading Filter", fid)
	local filter = EasyDestroy.Data.Filters[fid]
	EasyDestroyFilterName.input:SetText(filter.properties.name)
	EasyDestroyItemID.input:SetText(filter.filter.id or "")
	EasyDestroyNameSearch.input:SetText(filter.filter.name or "")
	
	local quality = {EasyDestroyRarityCommon, EasyDestroyRarityUncommon, EasyDestroyRarityRare, EasyDestroyRarityEpic}
	for _, v in ipairs(quality) do
		v:SetChecked(false)
	end
	if tContains(filter.filter.quality or {}, Enum.ItemQuality.Common) then EasyDestroyRarityCommon:SetChecked(true) end
	if tContains(filter.filter.quality or {}, Enum.ItemQuality.Uncommon) then EasyDestroyRarityUncommon:SetChecked(true) end
	if tContains(filter.filter.quality or {}, Enum.ItemQuality.Rare) then EasyDestroyRarityRare:SetChecked(true) end
	if tContains(filter.filter.quality or {}, Enum.ItemQuality.Epic) then EasyDestroyRarityEpic:SetChecked(true) end

	--Set the drop down box to show the currently selected filter

end

    
