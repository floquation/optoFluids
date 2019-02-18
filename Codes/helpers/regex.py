#! /usr/bin/env python3

import re

########
## Convenient regex generators
####

def group(inner,store=True):
	if ( store ) :
		return r"("+inner+")"
	else :
		return r"(?:"+inner+")"

def optional(expr):
	return group(expr, False)+"?"

def either(expr1, expr2):
	return group( group(expr1, False) + "|" + group(expr2, False) , False)

def withinSpaces(expr):
	return "\s*" + expr + "\s*"

def compile(expr):
    return re.compile(expr)

floatRE=r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"
floatRE=either(floatRE,r"[-+]?[0-9]+\.?[0-9]*(?:[eE][-+]?[0-9]+)?") # "0." and "1." are also numbers, but the original floatRE could not recognise them. This is important, because Python writes floats in that manner by default when it does not need any following zeroes.
intRE=r"[0-9]+"
#floatREx3 = "(?m)^\s*("+floatRE+")\s+("+floatRE+")\s+("+floatRE+")\s*$" # Matches exactly three floats, space-separated
floatREx3 = group(floatRE)+"\s+"+group(floatRE)+"\s+"+group(floatRE) # Matches exactly three floats, space-separated


########
## Frequently used regex checks
####

def countMatchingItems(itemList, regObj):
	return len( getMatchingItems(itemList,regObj) )

def getMatch(item, regObj):
	return regObj.match(item)

def doesItemMatch(item, regObj):
	result = regObj.match(item)
	if result:
		return True
	return False

def getMatchingGroups(item, regObj):
	result = regObj.match(item)
	if result:
		return result.groups()
	return None

def getMatchingItems(itemList, regObj):
	returnList=[]
	for item in itemList:
		result = regObj.match(item)
		if result:
			returnList.append(item)
	return returnList

def getMatchingItemsAndGroups(itemList, regObj):
	returnList=[]
	for item in itemList:
		result = regObj.match(item)
		if result:
			returnList.append( (item,) + result.groups() )
	return returnList

# Convert a list of tuples to a single-valued list:
def untupleList(tupleList, index=0):
	out=[]
	for item in tupleList:
		out.append(item[index])
	return out





# EOF
