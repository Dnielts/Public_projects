-- Function to roll a D20 and apply modifiers
function rollD20(modifiers)
    local roll = math.random(1, 20) -- Roll the D20
    local total = roll

    -- Apply modifiers
    for _, modifier in ipairs(modifiers) do
        total = total + modifier
    end

    return roll, total
end

-- Example usage
math.randomseed(os.time()) -- Seed the random number generator

local modifiers = {2, -1, 3} -- Example modifiers (+2, -1, +3)
local roll, total = rollD20(modifiers)

print("D20 Roll: " .. roll)
print("Total with modifiers: " .. total)

