--[[
    Tunneling in 3x3 with torches and chests.
]]

-- Variables
local slotFuel1 = 1
local countFuel = 0
local slotChests = 2
local countChests = 0
local slotTorches = 3
local countTorches = 0
local distanceTorches = 9
local bagStart = 4
local bagEnd = 16
local cX = 0
local cY = 0
local tX = 0
local tY = 0
local unwantedItems = {["minecraft:cobblestone"] = true}

-- Methods
local function refreshItemCount()
    countFuel = turtle.getItemCount(slotFuel1)
    countChests = turtle.getItemCount(slotChests)
    countTorches = turtle.getItemCount(slotTorches)
end

--[[
    Checks if all items are the correct ones.
    Returns 
]]
local function checkItemsNotOk()
    local err = false
    local item
    refreshItemCount()
    if countFuel == 0 then
        print("No fuel detected in slot " .. slotFuel1)
        err = true
    end
    if countChests == 0 then
        print("No chests detected in slot " .. slotChests)
        err = true
    else
        item = turtle.getItemDetail(slotChests)
        if not string.match(item.name, "chest") then
            print("Item in slot " .. slotChests .. " does not match *chest*")
            err = true
        end
    end
    if countTorches == 0 then
        print("No torches detected in slot " .. slotTorches)
        err = true
    else
        item = turtle.getItemDetail(slotTorches)
        if not item.name == "minecraft:torch" then
            print("Item in slot " .. slotTorches .. " is not a torch!")
            err = true
        end
    end
    return err
end



local function dig3x3()
    turtle.dig()
    turtle.forward()
    turtle.turnLeft()
    turtle.dig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.turnRight()
    turtle.turnRight()
    turtle.dig()
    turtle.down()
    turtle.dig()
    turtle.down()
    turtle.dig()
    turtle.turnLeft()
end


local function moveX(blocks) {
    if blocks > 0 then
        for i = 0, blocks do
            turtle.forward()
        end
    else
        for i = blocks, 0 do
            turtle.backward()
        end
    end
    cX = cX + blocks
}

local function moveY(blocks) {
    if blocks > 0 then
        turtle.turnRight()
        for i = 0, blocks do
            turtle.forward()
        end
    else
        turtle.turnLeft()
        turtle.turnLeft()
        for i = blocks, 0 do
            turtle.backward()
        end
    end
    cY = cY + blocks
}

local function fuelTurtleIfNeeded()
    while turtle.getFuelLevel() < 120 do
        if countFuel > 0 then
            turtle.select(slotFuel1)
            turtle.refuel(1)
            refreshItemCount()
        else
            print("We are out of fuel")
            os.shutdown()
        end
    end
end

local function placeTorchIfNeeded()
    if cX % distanceTorches then
        turtle.select(slotTorches)
        turtle.up()
        turtle.turnLeft()
        turtle.place()
        turtle.down()
        turtle.turnRight()
        return true
    end
    return false
end

local function placeChestIfNeeded()
    if turtle.getItemCount(bagEnd) > 0 then
        if countChests > 0 then
            turtle.select(slotChests)
            turtle.digDown()
            turtle.placeDown()
            for slot = bagStart, bagEnd do
                turtle.select(slot)
                sleep(0.6)
                turtle.dropDown()
            end
            return true
        else
            print("We are out of chests")
            os.shutdown()
        end
    end
    return false
end

local function dropUnwantedItems()
    local item
    for slot = bagStart, bagEnd do
        turtle.select(slot)
        item = turtle.getItemDetail()
        if unwantedItems[item.name] then
            turtle.drop()
        end
    end
end


local function tunnelLoop()
    while not cX == tX do
        fuelTurtleIfNeeded()
        dig3x3()
        placeChestIfNeeded()
        placeTorchIfNeeded()
        dropUnwantedItems()
        moveX(1)
    end
end

local function main()
    print("Checking items...")
    refreshItemCount()
    while not checkItemsOk() do
        print("Some items were not correct - will retry in 5 seconds")
        refreshItemCount()
        sleep(5)
    end
    print("Everything is fine.")
    print("Tunnel lenght? ")
    tX = tonumber(read())
    print("Will dig for " .. tX .. " blocks")
    tunnelLoop()
end

main()
