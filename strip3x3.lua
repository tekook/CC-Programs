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
local distanceTorches = 8
local bagStart = 4
local bagEnd = 16
local cX = 0
local cY = 0
local tX = 0
local tY = 0
local unwantedItems = {["minecraft:cobblestone"] = true}
local hasStartingChest = false

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

local function lookForStartingChest()
    turtle.turnRight()
    turtle.turnRight()
    local success, item = turtle.inspect()
    if success and string.match(item.name, "chest") then
        hasStartingChest = true
    else
        hasStartingChest = false
    end
    turtle.turnLeft()
    turtle.turnLeft()
end

local function safeDig(shutdown)
    turtle.dig()
    local i = 0
    while turtle.inspect() do
        turtle.dig()
        i = i + 1
        if i > 20 then
            if shutdown == true then
                print("[safeDig] Shutdown!")
                os.shutdown()
            end
            return false
        end
    end
    return true
end



local function dig3x3()
    turtle.dig()
    local i = 0
    while not turtle.forward() do
        turtle.dig()
        i = i + 1
        if i > 20 then
            print("cannot move forward!")
            os.shutdown()
        end
    end
    turtle.turnLeft()
    safeDig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.digUp()
    turtle.up()
    turtle.dig()
    turtle.turnRight()
    turtle.turnRight()
    safeDig()
    turtle.down()
    turtle.dig()
    turtle.down()
    turtle.dig()
    turtle.turnLeft()
end

local function move(blocks)
    if blocks > 0 then
        for i = 0, (blocks-1) do
            local failsave = 0
            while not turtle.forward() do
                turtle.dig()
                failsave = failsave + 1
                if failsave > 20 then
                    print("cannot move forward - failsave")
                    os.shutdown()
                end
            end
        end
    else
        for i = (blocks+1), 0 do
            turtle.back()
        end
    end
end

local function moveX(blocks)
    move(blocks)
    cX = cX + blocks
end

local function moveY(blocks)
    move(blocks)
    cY = cY + blocks
end

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
    if cX ~= 0 and cX % distanceTorches == 0 then
        turtle.select(slotTorches)
        turtle.up()
        turtle.turnLeft()
        local i = 0
        while turtle.inspect() do
            if not turtle.dig() then break end
            i = i + 1
            if i > 20 then
                print("Cannot break block to place torch")
                return false
            end
        end
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

local function dumpToStartIfNeeded()
    if turtle.getItemCount(bagEnd) > 0 then
        local tempX = cX
        print("moving " .. cX .. " back to chest")
        moveX(cX * -1)
        turtle.turnRight()
        turtle.turnRight()
        for slot = bagStart, bagEnd do
            turtle.select(slot)
            sleep(0.6)
            turtle.drop()
        end
        turtle.turnRight()
        turtle.turnRight()
        print("moving " .. tempX .. " back to point")
        moveX(tempX)
        return true
    end
    return false
end

local function dropUnwantedItems()
    local item
    for slot = bagStart, bagEnd do
        turtle.select(slot)
        item = turtle.getItemDetail()
        if item ~= nil then
            if unwantedItems[item.name] then
                turtle.drop()
            end
        end
    end
end


local function tunnelLoop()
    while cX ~= tX do
        fuelTurtleIfNeeded()
        dig3x3()
        cX = cX + 1
        if hasStartingChest then
            dumpToStartIfNeeded()
        else
            placeChestIfNeeded()
        end
        placeTorchIfNeeded()
        dropUnwantedItems()
        turtle.select(bagStart - 1)
    end
    print("I reached my target. YEY.")
end

local function main()
    print("Checking items...")
    refreshItemCount()
    while checkItemsNotOk() do
        print("Some items were not correct - will retry in 5 seconds")
        refreshItemCount()
        sleep(5)
    end
    print("How long should I dig?")
    tX = tonumber(read())
    print("Okay, I will dig for " .. tX .. " blocks")
    lookForStartingChest()
    if hasStartingChest then
        print("There is a chest behind me, I will use it.")
    else
        print("There is no chest behind me, I will place chests along the way.")
    end
    tunnelLoop()
end

main()
