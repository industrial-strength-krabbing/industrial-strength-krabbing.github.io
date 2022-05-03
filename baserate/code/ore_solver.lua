local function defaultZero(input)
	return input or 0
end

local ores = {
	Arkonor = { 0, 3200, 1200, 0, 0, 0, 120 },
	Bistot = { 0, 3200, 1200, 0, 0, 160, 0 },
	Crokite = { 0, 800, 2000, 0, 800, 0, 0 },
	["Dark Ochre"] = { 0, 0, 1360, 1200, 320, 0, 0 },
	Gneiss = { 0, 2000, 1500, 800, 0, 0, 0 },
	Hedbergite = { 0, 450, 0, 0, 120, 0, 0 },
	Hemorphite = { 0, 0, 0, 240, 90, 0, 0 },
	Jaspet = { 0, 0, 150, 0, 50, 0, 0 },
	Kernite = { 0, 0, 60, 120, 0, 0, 0 },
	Omber = { 0, 90, 0, 75, 0, 0, 0 },
	Plagioclase = { 175, 0, 70, 0, 0, 0, 0 },
	Pyroxeres = { 0, 90, 30, 0, 0, 0, 0 },
	Scordite = { 150, 90, 0, 0, 0, 0, 0 },
	Spodumain = { 48000, 0, 0, 1000, 160, 80, 40 },
	Veldspar = { 400, 0, 0, 0, 0, 0, 0 },
}

local mineralNames = { "Tritanium", "Pyerite", "Mexallon", "Isogen", "Nocxium", "Zydrine", "Megacyte" }
local numMinerals = #mineralNames
local mineralToIndex = { }
local oreTypesList = { }

for i=1,numMinerals do
	mineralToIndex[mineralNames[i]] = i
end

for oreName in pairs(ores) do
	oreTypesList[#oreTypesList + 1] = oreName
end

table.sort(oreTypesList)

function transferOre(cookbook, formula, oreType, quantity)
	for i=1,numMinerals do
		formula[i] = formula[i] - ores[oreType][i] * quantity
	end
	cookbook[oreType] = (cookbook[oreType] or 0) + quantity
end

function transferOreForMineral(cookbook, formula, oreType, mineralType)
	local quantity = (formula[mineralToIndex[mineralType]] / ores[oreType][mineralToIndex[mineralType]])
	if quantity > 0 then
		transferOre(cookbook, formula, oreType, quantity)
	end
end

function greedyOreMatch(formula, oreType)
	local quantityRequired = 0
	local ore = ores[oreType]
	for i=1,numMinerals do
		local oreQuantity = ore[i]
		local formulaQuantity = formula[i]
		if oreQuantity ~= 0 and formulaQuantity > 0 then
			local neededForThisMineral = formulaQuantity / oreQuantity

			if neededForThisMineral > quantityRequired then
				quantityRequired = neededForThisMineral
			end
		end
	end

	local waste = 0
	for i=1,numMinerals do
		local sunk = formula[i] - ore[i] * quantityRequired
		if sunk < 0 then
			waste = waste - sunk
		end
	end

	print("For "..oreType..": "..quantityRequired.." required, "..waste.." wasted")
	return quantityRequired, waste
end

function normalizeOre(ore, formula, prices)
	local maxBeforeWasteHit = nil
	local vector = { }
	local magnitudeSq = 0
	for i=1,numMinerals do
		local mineralQuantityInOre = ore[i]
		local mineralValue = mineralQuantityInOre * prices[i]
		vector[i] = mineralValue
		magnitudeSq = magnitudeSq + mineralValue * mineralValue
	end

	local magnitude = math.sqrt(magnitudeSq)
	for i=1,numMinerals do
		vector[i] = vector[i] / magnitude
	end

	for i=1,numMinerals do
		local fmins = formula[i]
		local vmins = vector[i]
		if fmins > 0 and vmins > 0 then
			local wasteIntersection = fmins / vmins
			if maxBeforeWasteHit == nil or maxBeforeWasteHit > wasteIntersection then
				maxBeforeWasteHit = wasteIntersection
				print("Intersection: "..wasteIntersection.." = "..fmins.."/"..vmins)
			end
		end
	end

	local normalizedOre =
	{
		vector = vector,
		maxBeforeWasteHit = maxBeforeWasteHit,
		magnitude = magnitude,
	}

	return normalizedOre
end

function dotProduct(v1, v2)
	local vlen = #v1
	assert(#v2 == vlen)

	local total = 0
	for i=1,vlen do
		total = total + v1[i] * v2[i]
	end
	return total
end

function strVector(v)
	local result = "{ "
	for i=1,#v do
		if i ~= 1 then
			result = result..", "
		end
		result = result..v[i]
	end
	result = result.." }"
	return result
end

function resolveOreFormula(inputs, priceTable)
	local formula = { }
	local prices = { }
	
	for i=1,numMinerals do
		formula[i] = defaultZero(inputs[mineralNames[i]])
		prices[i] = defaultZero(priceTable[mineralNames[i]])
	end

	local cookbook = { }

	-- De-facto sole sources:
	--transferOreForMineral(cookbook, formula, "Arkonor", "Megacyte")
	--transferOreForMineral(cookbook, formula, "Bistot", "Zydrine")

	-- Remaining: Tritanium, Pyerite, Mexallon, Isogen, Nocxium
	-- We ignore tritanium because veldspar is pure tritanium

	for i=1,2 do
		print("Pass ------------------------------------------")
		print("Remaining minerals: "..strVector(formula))
		local formulaRemainingVector = { }
		for i=1,numMinerals do
			local mineralsRemaining = formula[i]
			if mineralsRemaining <= 0 then
				formulaRemainingVector[i] = 0
			else
				formulaRemainingVector[i] = formula[i] * prices[i]
			end
		end

		print("Remaining value: "..strVector(formulaRemainingVector))

		local normalizedOres = { }
		for oreName,ore in pairs(ores) do
			print("Normalizing "..oreName)
			normalizedOres[oreName] = normalizeOre(ore, formulaRemainingVector, prices)
		end

		local bestOre = nil
		local bestAlignment = nil
		for _,oreName in ipairs(oreTypesList) do
			local normOre = normalizedOres[oreName]
			local alignment = dotProduct(normOre.vector, formulaRemainingVector)

			if bestAlignment == nil or bestAlignment < alignment then
				bestAlignment = alignment
				bestOre = oreName
			end
			print("Alignment for "..oreName.." is "..alignment)
		end
		print("Best ore is "..bestOre)

		local bestNOre = normalizedOres[bestOre]

		print("Vector for formula is "..strVector(formulaRemainingVector))
		for _,oreName in ipairs(oreTypesList) do
			print("Vector for "..oreName.." is "..strVector(normalizedOres[oreName].vector))
			print("Waste transition point for "..oreName.." is "..normalizedOres[oreName].maxBeforeWasteHit)
		end

		-- Figure out the earliest point where this would intersect with another one
		local transitionLimit = bestNOre.maxBeforeWasteHit
		for _,otherOreName in ipairs(oreTypesList) do
			if otherOreName ~= bestOre then
				local axis = bestNOre.vector
				local otherAxis = normalizedOres[otherOreName].vector
				local denominator = dotProduct(axis, axis) - dotProduct(axis, otherAxis)
				print("Denominator of "..otherOreName.." is "..denominator)
				if denominator ~= 0 then
					local numerator = dotProduct(formulaRemainingVector, axis) - dotProduct(formulaRemainingVector, otherAxis)
					local intersection = numerator / denominator
					print("Intersection is "..intersection)
					if numerator > 0 then
						if transitionLimit == nil or intersection < transitionLimit then
							transitionLimit = intersection
							print("Hit transition limit with "..otherOreName)
						end
					end
				end
			end
		end

		local oreUnits = transitionLimit / bestNOre.magnitude
		print("Adding "..oreUnits.." of ore")
		transferOre(cookbook, formula, bestOre, oreUnits)
	end

	transferOreForMineral(cookbook, formula, "Veldspar", "Tritanium")
end

local priceTable =
{
	Tritanium = 5,
	Pyerite = 21.38,
	Mexallon = 104.9,
	Isogen = 43.78,
	Nocxium = 1568,
	Zydrine = 966.8,
	Megacyte = 594
}

--[[
local inputs =
{
	Tritanium = 2800000,
	Pyerite = 1000000,
	Mexallon = 180000,
	Isogen = 20000,
	Nocxium = 8000,
	Zydrine = 2000,
	Megacyte = 400,
}
]]--

local inputs =
{
	Tritanium = 0,
	Pyerite = 800,
	Mexallon = 3200,
	Isogen = 0,
	Nocxium = 1120,
	Zydrine = 160,
	Megacyte = 0,
}

resolveOreFormula(inputs, priceTable)
