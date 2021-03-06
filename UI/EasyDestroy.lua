--[[ Main "Always Shown" UI Buttons]]
EasyDestroyFrame.Buttons = {}

EasyDestroyFrame.Buttons.DestroyButton = EasyDestroyButton
EasyDestroyFrame.ToggleConfigurator = EasyDestroy_ToggleConfigurator
EasyDestroyFrame.ShowItemBlacklist = EasyDestroy_OpenBlacklist

--[[ Font Strings ]]
EasyDestroy.UI.ItemCounter = EasyDestroyFrame_FoundItemsCount

--[[ TODO: init and core frame setup should go below as well as functions that touch on everything (loadfilter, deletefilter, toggle configurator ) 
basically anything that doesn't have a "clean" spot will probably end up here. ]]

local protected = {}
local initialized = false

function EasyDestroyFrame.__init()

    if initialized then return end

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

	EasyDestroySelectedFilters:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize=8,
		tile=true, 
		tileEdge=false, 
		insets={left=4, right=4, top=4, bottom=4}
	})

	EasyDestroyItems:SetBackdropColor(0,0,0,0.5)
	EasyDestroySelectedFilters:SetBackdropColor(0,0,0,0.5)
		
	EasyDestroyFrameSearchTypes.Search:SetLabel("Searches")
	EasyDestroyFrameSearchTypes.Search:SetChecked(true)
	EasyDestroyFrameSearchTypes.Blacklist:SetLabel("Blacklists")

	--[[ Filter View Area ]]--
	UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)

	EasyDestroy.ContextMenu = CreateFrame("Frame", "EDTestFrame", EasyDestroyFrame, "UIDropDownMenuTemplate")
	
	EasyDestroyItemsFrame.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        EasyDestroyItemsFrame:OnVerticalScroll(offset)
    end)

	EasyDestroy.UI.Filters.FilterName:SetLabel("Filter Name:")
	EasyDestroy.UI.Filters.SetFavoriteChecked(false)
	EasyDestroy.UI.Filters.FilterType:SetLabel("Blacklist")
	UIDropDownMenu_SetWidth(EasyDestroyFilterTypes, EasyDestroyFilterSettings:GetWidth()-50)

	EasyDestroyFilterSettings.FilterName:SetLabel("Filter Name:")
	EasyDestroyFilterSettings.Favorite:SetChecked(false);		
	EasyDestroyFilterSettings.Blacklist:SetLabel("Blacklist")

    EasyDestroyFrame:SetScript("OnShow", protected.RegisterEvents)
    EasyDestroyFrame:SetScript("OnHide", protected.UnregisterEvents)

    EasyDestroyButton:SetScript("PreClick", protected.DestroyPreClick)
    EasyDestroyButton:SetScript("PostClick", function(self)
	EasyDestroyButton:SetAttribute("macrotext", "")	
	EasyDestroy.ButtonWasClicked = true

	EasyDestroy.RegisterCallback(EasyDestroyButton, "ED_INVENTORY_UPDATED_DELAYED", function(self) self:Enable() end )

end)

end

function EasyDestroyFrame.LoadUserFavorite()

	-- Loads the user's current favorite if available

	local fav = EasyDestroy.Favorites.GetFavorite()
	if fav ~= nil then
		UIDropDownMenu_SetSelectedValue(EasyDestroy.UI.Filters.FilterDropDown, fav)
		EasyDestroy.UI.Filters.LoadFilter(fav)
	
	else
		UIDropDownMenu_SetSelectedValue(EasyDestroy.UI.Filters.FilterDropDown, 0)
	end
end

-- ###########################################
-- UI Event Handlers
-- ###########################################

function protected.RegisterEvents()

	-- re-register events 

	EasyDestroyFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	EasyDestroyFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	-- lets refresh things now that we're opening the window
	EasyDestroy.Events:Call("ED_INVENTORY_UPDATED")
		:Call("ED_RESTACK_ITEMS")
		:Call("ED_FILTER_LOADED")

end

function protected.UnregisterEvents()

	-- un-register events.

	EasyDestroyFrame:UnregisterEvent("BAG_UPDATE_DELAYED")
	EasyDestroyFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

end

function protected.DestroyPreClick(self)

	-- The actual process for destroying an item.

	if not EasyDestroyFrame:IsVisible() then
		EasyDestroyFrame:Show()
		return
	end

	local iteminfo = EasyDestroyItemsFrameItem1.item or nil
	local bag, slot
	
	if iteminfo ~= nil then
		bag, slot = iteminfo.bag, iteminfo.slot	
	else
		return 
	end

	local action = EasyDestroy.Destroy.GetDestroyActionForItem(iteminfo)
	local actionDict = EasyDestroy.Dict.Actions[action]
	local spellName = GetSpellInfo(actionDict.spellID)
	
	if not IsSpellKnown(actionDict.spellID) then
		print ("EasyDestroy: You must have " .. GetSpellLink(actionDict.spellID) .. " to destroy this item.")
		return
	elseif EasyDestroyFilterSettings.Blacklist:GetChecked() then
		StaticPopup_Show("ED_CANT_DISENCHANT_BLACKLIST")
		return
	elseif not IsUsableSpell(actionDict.spellID) then
		print("EasyDestroy: You cannot destroy that item right now.")
		return
	elseif #GetLootInfo() > 0 then
		if not EasyDestroy.Warnings.LootOpen then
			print("EasyDestroy: Unable to destroy while loot window is open.")
				EasyDestroy.Warnings.LootOpen = true
			-- lets only warn people every so often, don't want to fill their chat logs if they spam click.
			C_Timer.After(30, function()
				EasyDestroy.Warnings.LootOpen = false
			end
			)
		end
		return
	elseif IsCurrentSpell(actionDict.spellID) then
		-- fail quietly as they are already casting
		return
	elseif iteminfo == nil then
		return
	end

	EasyDestroy.Destroy.DestroyItem(iteminfo)

end
