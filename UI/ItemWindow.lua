EasyDestroy.UI.ItemWindowFrame = EasyDestroyItems
EasyDestroy.UI.ItemWindow = EasyDestroyItemsFrame

local ItemWindow = EasyDestroy.UI.ItemWindow
ItemWindow.name = "EasyDestroy.UI.ItemWindow"


local initialized = false

local function Update(UpdateItemList, cb)

    -- Update the Item Window (Item List)

	if ItemWindow:IsVisible(ItemWindow.name, Update) then 

		EasyDestroy.Debug("ItemWindow.Update")

		EasyDestroy.UI.ItemWindow.UpdateItemList = UpdateItemList or false
		EasyDestroy.UI.ItemWindow:ScrollUpdate(cb)
		EasyDestroy.UI.ItemCounter:SetText(EasyDestroy.UI.ItemWindow.ItemCount ..  " Item(s) Found")

	end

end

function ItemWindow:RegisterScript(frame, scriptType)

	-- Register a frame's script handler to additionally run the ItemWindow.Update
	-- Should be used by buttons/fields that will update a filter

	if frame:HasScript(scriptType) then
		frame:HookScript(scriptType, ItemWindow.OnCriteriaUpdate)
	else
		error("RegisterScript requires a valid scriptType", 2)
	end

end

function ItemWindow.__init()

    if initialized then return end 

    EasyDestroy.RegisterCallback(ItemWindow, "UpdateItemWindow", Update)
	EasyDestroy.RegisterCallback(ItemWindow, "UpdateInventoryDelayed", Update)
	EasyDestroy.RegisterCallback(ItemWindow, "UpdateBlacklist", Update)
	EasyDestroy.RegisterCallback(ItemWindow, "UpdateCriteria", Update)
	-- EasyDestroy.CallbackHandler:RegisterCallback("")
    
    initialized = true

end


-- ###########################################
-- UI Event Handlers
-- ###########################################

function ItemWindow.OnCriteriaUpdate()

	-- If our filter was updated, we'll need to tell the system to update.
EasyDestroy.Events:Call("UpdateItemWindow")
	

	EasyDestroy.FilterChanged = true

end