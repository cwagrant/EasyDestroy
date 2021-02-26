--[[

    StaticPopupDialogs used by various areas of the AddOn.
    
]]

StaticPopupDialogs["ED_CANT_DISENCHANT_BLACKLIST"] = {
	text = "You cannot disenchant items on the blacklist.|n|nYou are currently viewing or editing a blacklist filter.",
	button1 = "Okay",
	timeout = 30,
	whileDead = false,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["ED_CONFIRM_DELETE_FILTER"] = {
    text = "Are you sure you wish to delete filter %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = EasyDestroy.Handlers.DeleteFilterOnClick,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_CONFIRM_NEW_FAVORITE"] = {
    text = "You already have a favorite filter. Do you want to make this your new favorite filter?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self) EasyDestroy.Handlers.SaveFilterOnClick(true) end,
    OnCancel = function(self) EasyDestroyFilterSettings.Favorite:SetChecked(false) end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_CONFIRM_NEW_CHARACTER_FAVORITE"] = {
    text = "You already have a favorite filter. Do you want to make this your new favorite filter?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self) EasyDestroy.CharacterData.FavoriteID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown) end,
    OnCancel = function(self) EasyDestroyFilterSettings.Favorite:SetChecked(false) end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_BLACKLIST_NO_FAVORITE"] = {
    text = "You cannot set a blacklist as a favorite. If you continue, this filter will be no longer be favorited. |n|n|cFFFF0000This applies to all characters that have this filter as a favorite.",
    button1 = "Okay",
    button2 = "Cancel",
    OnAccept = function(self) 
        EasyDestroyFilterSettings.Favorite:SetChecked(false)
        EasyDestroyFilterSettings.Favorite:Disable()
        EasyDestroy.Favorites.UnsetFavorite()
    end,
    OnCancel = function(self)
        EasyDestroyFilterSettings.Blacklist:SetChecked(false)
    end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_SHOW_ALL_FILTERS"] = {
    text = "You do not currently have both Searches and Blacklists checked. |nChecking this box will cause both Searches and Blacklists to show under the Filter selection. Do you wish to continue?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self) EasyDestroy:SelectAllFilterTypes() end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ED_FILTER_UNIQUE_NAME"] = {
    text = "Filters require a unique name. %s is already used.|n|n|cFFFF0000Your filter has NOT been saved.|r",
    button1 = "Okay",
    -- OnAccept = function(self) return end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}