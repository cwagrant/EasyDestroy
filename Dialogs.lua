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
    OnAccept = function(self) EasyDestroy.UI.Filters.SelectAllFilterTypes() end,
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

StaticPopupDialogs["ED_RELOAD_CURRENT_FILTER"] = {
    text = "This requires reloading the current filter. Do you wish to proceed?",
    button1 = "Okay",
    button2 = "Cancel",
    OnAccept = function(self) 
        EasyDestroy.Data.Options.CharacterFavorites = not EasyDestroy.Data.Options.CharacterFavorites 
        EasyDestroy.UI.ReloadCurrentFilter()
    end, 
    OnCancel = function(self, data) data:SetChecked(EasyDestroy.Data.Options.CharacterFavorites) end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}


StaticPopupDialogs["ED_3_0_FEATURE_ALERT"] = {
    text = [[EasyDestroy has been updated!
    
    In version 3.0 you now have the ability to Mill and Prospect items as well as Disenchanting.
    
    Additionally, there is an options window to configure this and other features! Click Okay to be taken to the new Options menu or Cancel to close this message.
    ]],
    button1 = "Okay",
    button2 = "Cancel",
    OnAccept = function(self) 
        InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
        InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
    end,
    OnCancel = function(self)
        EasyDestroy.Data.Alerts = EasyDestroy.Data.Alerts or {}
    end,
    timeout = 60,
    whileDead = false,
    hideOnEscape = false,
    preferredIndex = 3,
}