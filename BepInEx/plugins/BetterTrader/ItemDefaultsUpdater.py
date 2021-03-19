import sys
import re
import os

def modify_old_default(matchobj):
    newMatch = matchobj[0]
    if matchobj.group("stack") == None:
        newMatch += ": Stack = 1"
    elif matchobj.group("stack").islower():
        newMatch.replace("stack", "Stack")

    if matchobj.group("price") == None:
        newMatch += " Price = 100"
    elif matchobj.group("price").islower():
        newMatch.replace("price", "Price")

    if matchobj.group("sellprice") == None:
        newMatch += " SellPrice = 100"
    elif matchobj.group("sellprice").islower():
        newMatch.replace("sellprice", "SellPrice")

    if matchobj.group("tradeable") == None:
        newMatch += " Tradeable = true"
    elif matchobj.group("tradeable").islower():
        newMatch.replace("tradeable", "Tradeable")

    if matchobj.group("sellable") == None:
        newMatch += " Sellable = true"
    elif matchobj.group("sellable").islower():
        newMatch.replace("sellable", "Sellable")

    if matchobj.group("ignorewaitfordiscovery") == None:
        newMatch += " IgnoreWaitForDiscovery = false"
    elif matchobj.group("ignorewaitfordiscovery").islower():
        newMatch.replace("ignorewaitfordiscovery", "IgnoreWaitForDiscovery")
    return newMatch

def get_modified_old_defaults(oldItemDefaultsContents):
    itemDefaultsLines = []
    for line in oldItemDefaultsContents.splitlines():
        if line != None:
            lineSub = re.sub(itemRe, modify_old_default, line, flags=re.MULTILINE | re.IGNORECASE)
            if re.search(itemRe, lineSub, flags=re.MULTILINE | re.IGNORECASE) != None:
                itemDefaultsLines.append(lineSub)
    return itemDefaultsLines

def get_matching_default(currentUpdatingDefault):
    currentUpdatingDefaultRe = re.match(itemRe, currentUpdatingDefault, flags=re.MULTILINE | re.IGNORECASE)
    if currentUpdatingDefaultRe != None:
        for default in modifiedOldDefaults:
            defaultRe = re.match(itemRe, default, flags=re.MULTILINE | re.IGNORECASE)
            if defaultRe != None and defaultRe.group("name") == currentUpdatingDefaultRe.group("name"):
                currentUpdatingDefault = default
                break
    return currentUpdatingDefault

def update_current_defaults(currentDefaults):
    currentDefaultsLines = currentDefaults.splitlines()
    updatedCurrentDefaultsLines = [get_matching_default(x) for x in currentDefaultsLines]
    return "\n".join(updatedCurrentDefaultsLines)

itemRe = "^(?P<name>[A-z]+)(?::? ?(?:(?P<stack>stack)|(?P<price>price)|(?P<sellprice>sellprice)|(?P<tradeable>tradeable)|(?P<sellable>sellable)|(?P<ignorewaitfordiscovery>ignorewaitfordiscovery)) ?= ?(?:\d*|true|false)){0,6}$"
item_defaultsPath = os.path.join(os.path.dirname(__file__), "item_defaults.cfg")
currentDefaultsStream = open(item_defaultsPath, "r+")
currentDefaultsContents = currentDefaultsStream.read()

oldItemDefaultsStream = open(sys.argv[1])
oldItemDefaultsContents = oldItemDefaultsStream.read()

modifiedOldDefaults = get_modified_old_defaults(oldItemDefaultsContents)
updatedCurrentDefaults = update_current_defaults(currentDefaultsContents)
print(updatedCurrentDefaults)

for i in range(0, 100):
    currentDefaultsStream.seek(0)
    currentDefaultsStream.truncate(0)
currentDefaultsStream.write(updatedCurrentDefaults)
oldItemDefaultsStream.close()
currentDefaultsStream.close()