--[[ Main Window ]]
EasyDestroy.UI.ItemWindowFrame = EasyDestroyItems
EasyDestroy.UI.ItemWindow = EasyDestroyItemsFrame
EasyDestroy.UI.FilterDropDown = EasyDestroyDropDown
EasyDestroy.UI.FilterDropDown.SearchesCheckbutton = EasyDestroyFrameSearch.Types.Search
EasyDestroy.UI.FilterDropDown.BlacklistsCheckbutton = EasyDestroyFrameSearch.Types.Blacklist

--[[ Configurator Fields ]]
EasyDestroy.UI.FilterName = EasyDestroyFilterSettings.FilterName
EasyDestroy.UI.Favorite = EasyDestroyFilterSettings.Favorite
EasyDestroy.UI.FilterType = EasyDestroyFilterSettings.Blacklist
EasyDestroy.UI.CriteriaDropdown = EasyDestroyFilterTypes
EasyDestroy.UI.CriteriaWindow = EasyDestroySelectedFilters

--[[ Configurator/Filter Buttons]]
EasyDestroy.UI.Buttons = {}
EasyDestroy.UI.Buttons.NewFilter = EasyDestroyFilters_New
EasyDestroy.UI.Buttons.NewFilterFromCurrent = EasyDestroyFilters_NewFromFilter
EasyDestroy.UI.Buttons.DeleteFilter = EasyDestroyFilters_Delete
EasyDestroy.UI.Buttons.SaveFilter = EasyDestroyFilters_Save

--[[ Main "Always Shown" UI Buttons]]
EasyDestroy.UI.Buttons.DestroyButton = EasyDestroyButton
EasyDestroy.UI.Buttons.ToggleConfigurator = EasyDestroy_ToggleConfigurator
EasyDestroy.UI.Buttons.ShowItemBlacklist = EasyDestroy_OpenBlacklist

--[[ Font Strings ]]
EasyDestroy.UI.ItemCounter = EasyDestroyFrame_FoundItemsCount

--[[ TODO: init and core frame setup should go below as well as functions that touch on everything (loadfilter, deletefilter, toggle configurator ) 
basically anything that doesn't have a "clean" spot will probably end up here. ]]