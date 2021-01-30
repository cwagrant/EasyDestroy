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

	-- Thought, instead make things comma separate-able? Or how do I handle filters in both an and and or state.
	-- Might be easier to allow the creation of "Combo Filters" where a person creates multiple filters and then
	-- is able to combine them together (will act as OR statements)

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
		
	--[[ Filter View Area ]]--
	UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)
		
	--[[ Test Button for debugging various information ]]--
	EasyDestroy.EasyDestroyTest = CreateFrame("Button", "EDTest", EasyDestroyFrame, "UIPanelButtonTemplate")
	EasyDestroy.EasyDestroyTest:SetSize(80, 22)
	EasyDestroy.EasyDestroyTest:SetPoint("BOTTOMLEFT", EasyDestroyFrame, "TOPLEFT", 0, 4)
	EasyDestroy.EasyDestroyTest:SetText("Test")
	EasyDestroy.EasyDestroyTest:SetScript("OnClick", function(self)
		print("CountItemsFound", #EasyDestroy:FindItemsToDestroy(EasyDestroy.CurrentFilter['filter']) or 0)
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
	info.text, info.value, info.checked, info.func, info.owner = "New Filter...", 0, false, EasyDestroy_DropDownSelect, EasyDestroyDropDown
	UIDropDownMenu_AddButton(info)
	
	if EasyDestroy.Data.Filters then
		for fid, filter in EasyDestroy.spairs(EasyDestroy.Data.Filters, function(t, a, b) return t[a].properties.name < t[b].properties.name end) do
			info.text, info.value, info.checked, info.func, info.owner = filter.properties.name, fid, false, EasyDestroy_DropDownSelect, EasyDestroyDropDown
			UIDropDownMenu_AddButton(info)
		end
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
	for bag = 0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do
			matchfound = nil
			local item = {};
			item.link = select(7, GetContainerItemInfo(bag, slot));
			if item.link then 
				item.name, _, item.quality, item.level, _, item._type, item._subtype, item.stack, item.slot, item.icon, item.price, item.type, item.subtype = GetItemInfo(item.link);
				--item.eqset = EasyDestroy.ItemInEquipmentSet(bag, slot);
				item.mog = EasyDestroy.HaveTransmog(item.link);
				item.id = GetContainerItemID(bag, slot);
				item.bindtype = select(14, GetItemInfo(item.link))

				--item.level = GetDetailedItemLevelInfo(item.link)
				if not item.name then -- Because unlike Jim Croce, Mythic Keystones do not, in fact, have a name.
					item.name = "NO_NAME_ITEM"
				end

				for k, v in pairs(EasyDestroyFilters.Registry) do
					if v.getiteminfo and type(v.getiteminfo) == 'function' then 
						item[k] = v.getiteminfo(item.link, bag, slot)
					end
				end
				
				
				for k, v in pairs(filter) do
					if not EasyDestroyFilters.Registry[k] then
						print("Unsupported filter:" .. k)
					else
						if not EasyDestroyFilters.Registry[k]:Check(v, item) then
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
				
				-- can't typically disenchant cosmetic items. This filters them out (hopefully)
				-- Not sure about cosmetic weapons...
				if item.type==LE_ITEM_CLASS_ARMOR and item.stype == LE_ITEM_ARMOR_COSMETIC then
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
	local filter = EasyDestroy.CurrentFilter["filter"]
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

