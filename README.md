Originally this was a relatively simple addon I made to make it easier to mass disenchant items using a filter to set which items will be destroyed.  This was mostly to help with handling variations of items during shuffles (blue vs green bracers, for example). Suggestions would be helpful for future features. 

Can be found at https://github.com/cwagrant/EasyDestroy

### Known Issues:
	- (v3.2.0)
		- The EasyDestroy Macro does not currently work. You have to manually click the "Destroy" button. This appears to likely be based on changes to the /click command by Blizzard and I may not be able to re-enable the feature. Time will tell.
		- Does not show or work for prospecting or milling Dragonflight ores and herbs.

 
### Commands: 

/easydestroy will open/close the window. Aliases are /ed and /edestroy.

The following arguments are also available

    reposition - resets the position of the window to the center of the screen

    reset - re-enables the Destroy button in the event it gets stuck

    cf - enable/disable character favorites

    macro - creates a macro for you

    options - opens the options menu

Current filtering capabilities:

    Item Name
    Item ID
    Item Level (ilvl, not equip level)
    Item Quality
    Ignore Items in Equipment Sets (Only supports Blizzard Equipment Sets)
    Ignore Items that are BoE based on Quality. (E.g. If you check the box for Uncommon quality items, then green BoE items will not show up in the list).
    Item Count 
    Item Type (Gear, Herbs, Ore)

 

If other filtering criteria are desired, feel free to drop a comment requesting as much and I will try to incorporate it.

### Interface:
**Item Window**

The first time you open EasyDestroy one of the first things you should see is an empty Item Window. The item window is a scrollable list of all the items in your bag that meet the criteria of your current filter. While Armor and Weapons will show up individually with the Item Level showing on the right hand side of the window, Herbs and Ore will show up as the name of the item followed by how many you currently have in your bag. Note: If an Herb or Ore show up in the Item Window then EasyDestroy will restack all of that item in your bag. If you have less than 5 of an herb or ore in total it will not show up in the Item Window.

The Item Window also has a right click "context" menu that allows you directly add an item to the Item Blacklist or to a temporary Session Blacklist. The Session Blacklist is reset when you log out, reload UI, or exit the game. More information on blacklists is below.

**Filters**

Beneath the Item Window are two checkboxes and a drop down menu. By default only "Searches" will be checked when you open the window. A Search (a.k.a. a whitelist) is what allows you to find items to destroy, whether these items be equipment, herbs, or ores. The drop down menu will allow you to select from filters you save, including both Whitelist filters and Blacklist filters. Only the type(s) you have checked will show in the drop down. If you have Searches selected, you'll see only your saved Searches. If you have both selected, you'll see all of them separated by a line, with Blacklists below the line and Searches above the line.

**Configuration -  Show/Hide Configurator Button**
The configuration area is where you create and modify filters.

    Filter Name (text field) - Filters can be given a name - but a default name will be generated when you save a filter if you haven't chosen to given it a name. 
    Favorite (star icon checkbox) - This lets you set your current filter as your favorite. Favorites can be either account wide or character specific. You can turn on character-specific favorites with the command noted above or in the options window.
    Blacklist (checkbox) - By default every filter is a Search. You can modify a filter to be a blacklist by clicking the "Blacklist" checkbox beneath the Filter Name. NOTE: All blacklists are universally applied. If something is caught by ANY blacklist it will not show up in ANY Search regardless of what you put in the Search filter.
    Filter Criteria (dropdown) - You can select which criteria your filter will use by selecting from this drop down menu. As you select your criteria and fill in the required information the Item Window will dynamically update showing you what items are "caught" in your current filter.
    Save Filter As (button) - This button will let you save your current filter with a new name. This can be useful if you want to tweak one filter without losing how you currently have it set up.
    New, Delete, and Save Filter (buttons) - These are self explanatory but do note that Delete and New filter will clear the configuration area when clicked. If you've modified a filter but don't want to overwrite the original, us Save Filter As to save your changes to a new filter.

**Destroy**
The Destroy button will attempt to destroy the first item that shows up in the Item Window. That is to say it will only ever try to destroy the item you see at the top of the Item Window. It will try automatically Disenchant, Mill, or Prospect the item depending on which is the correct method. If you have the option on for Auto-Blacklist Non-Destroyables then if the spell fails to destroy the item it will automatically add it to the Item Blacklist.

**Item Blacklist**
"We've had one blacklist yes, but what about second blacklist?" - Pippin, probably.
While Filter Blacklists let you be as specific or generic as you want, the Item Blacklist is a way to specifically blacklist a particular item. For example, using a Filter Blacklist you could potentially blacklist all [Epic] "purple" items from showing up in any of your Searches, whereas the Item Blacklist you would instead have to specify each individual item you wanted to exclude.

**Item Count**
The Item Count counts how many items currently show up in your search. When dealing with Herbs and Ore this instead is a count of how many types of Herbs and/or Ores are currently found. E.g. 5 Item(s) Found when looking at Herbs means that there are 5 different types of herbs in your filter e.g. [Death Blossom], [Fel Lotus], [Felweed], [Golden Sansam], and [Anchor Weed]. Not the actual count of how many of those are in your bags.

**Other Information**
EasyDestroy supports the use of AddOnSkins if it is installed. Please note that I did the configuration myself and so it may not necessarily live up to the standards of the author of AddOnSkins. IF YOU HAVE ISSUES WITH AddOnSkins SUPPORT FOR THIS ADDON YOU SHOULD SUBMIT THOSE ISSUES TO ME. 

EasyDestroy interfaces with addons that support LibDataBroker to provide a Data Text for launching the addon. This also provides a mini-map icon. Either of these can be left clicked to open EasyDestroy or right clicked to open the Options.

**Options**
-     Character Favorites - Enables/Disables the use of character specific favorites.
-     Auto-Blacklist Non-Destroyables - This will automatically add items to the Item Blacklist if they cannot be destroyed (typically, this would mean they cannot be Disenchanted).
-     Allow Disenchanting - This will allow Armor and Weapons to be included in your filters.
-     Allow Milling - This will allow Herbs to be included in your filters.
-     Allow Prospecting - This will allow Ores to be included in your filters.

### Note:

I realized after creating this that there's already another addon from years back that had the same name - this is not the same addon nor does it necessarily have the same functionality.  I'm sorry for any confusion.
