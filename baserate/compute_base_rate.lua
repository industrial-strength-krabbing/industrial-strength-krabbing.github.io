assert(loadfile("code/tabloader.lua"))()
assert(loadfile("code/dbtools.lua"))()


itemsDB = loadTabFile("computed.csv", false, "\t")

f = assert(io.open("baserate.txt", "w"))

local itemsByCategory = { }

local prevRow = nil
for _,row in ipairs(itemsDB.rows) do
	local item = { }
	item.name = assert(row.item)
	item.baseRate = assert(row["BASE RATE"])
	item.maxRuns = assert(row.copyRuns)
	item.outputsPerRun = assert(row.outputsPerRun)
	item.category = assert(row.category)

	local categoryTable = itemsByCategory[row.category]
	if categoryTable == nil then
		categoryTable = { }
		itemsByCategory[row.category] = categoryTable
	end
	categoryTable[row.item] = item
end

local sortedCategories = { }

for k in pairs(itemsByCategory) do
	sortedCategories[#sortedCategories+1] = k
end

table.sort(sortedCategories)

for _,catName in ipairs(sortedCategories) do
	local cat = itemsByCategory[catName]

	local sortedItems = { }
	for k in pairs(cat) do
		sortedItems[#sortedItems+1] = k
	end

	f:write("\tnew Divider(\""..catName.."\"),\n")

	table.sort(sortedItems)

	for _,itemName in ipairs(sortedItems) do
		local item = cat[itemName]
		f:write("\tnew BlueprintItem(\""..item.name.."\", "..item.baseRate..", "..item.maxRuns..", "..item.outputsPerRun..", \""..item.category.."\"),\n")
	end
end

f:close()
