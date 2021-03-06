local AS = nil

if not IsAddOnLoaded("AddOnSkins") then return end

if AddOnSkins then
    AS = unpack(AddOnSkins)
end

function AS:EasyDestroy(event, addon)
    --[[ Major Frames ]]
    AS:SkinFrame(EasyDestroyFrame)
    AS:SkinFrame(EasyDestroyItems)
    AS:SkinFrame(EasyDestroySelectedFilters)

    --[[ Buttons ]]
    AS:SkinButton(EasyDestroyFilters_New)
    AS:SkinButton(EasyDestroyFilters_Delete)
    AS:SkinButton(EasyDestroyFilters_NewFromFilter)
    AS:SkinButton(EasyDestroyFilters_Save)
    AS:SkinButton(EasyDestroyButton)
    AS:SkinButton(EasyDestroy_ToggleConfigurator)
    AS:SkinButton(EasyDestroy_OpenBlacklist)

    --[[ Scroll Bars ]]
    AS:SkinScrollBar(EasyDestroySelectedFiltersScrollScrollBar)
    AS:SkinScrollBar(EasyDestroyItemsFrameScrollFrameScrollBar)

    --[[ Dropdowns ]]
    AS:SkinDropDownBox(EasyDestroyDropDown)
    AS:SkinDropDownBox(EasyDestroyFilterTypes)

    EasyDestroyFrame:HookScript("OnUpdate", function()
        --[[ Easy way to reskin these in filters and whatnot]]
        if EasyDestroy.UpdateSkin then 

            --[[ Editboxes ]]
            for i, frame in ipairs(EasyDestroy.FrameRegistry.EditBox) do
                AS:SkinEditBox(frame)
            end

            --[[ CheckButtons ]]
            for i, frame in ipairs(EasyDestroy.FrameRegistry.CheckButton) do
                AS:SkinCheckBox(frame)
            end
            EasyDestroy.UpdateSkin = false
        end
    end)

    --[[ Cleanup ]]
    AS:SkinCloseButton(EasyDestroyFrameClose)
    AS:StripTextures(EasyDestroyFrame.Title)
end

AS:RegisterSkin('EasyDestroy', AS.EasyDestroy)