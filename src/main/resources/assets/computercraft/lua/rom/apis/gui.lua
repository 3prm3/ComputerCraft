local component = require("component")
local colors = require("colors")

local objects = {}
local API = {}

local gpu = component.gpu
local w,h = gpu.getResolution()

function clearScreen()
    gpu.setForeground(colors.white,true)
    gpu.setBackground(colors.black,true)
    gpu.fill(1,1,w,h," ")
end

function clamp(n,min,max) return math.min(math.max(n, min), max) end

function newButton(ID,label,x,y,width,height,func,params,oncolor,offcolor,toggle)
    local table = {}
    table["type"] = "button"
    table["label"] = label
    table["x"] = x
    table["y"] = y
    table["width"] = width
    table["height"] = height
    table["active"] = false
    table["func"] = func
    table["params"] = params
    table["oncolor"] = oncolor
    table["offcolor"] = offcolor
    table["toggle"] = toggle
    objects[ID] = table
end

function newLabel(ID,label,x,y,width,height,color)
    local table = {}
    table["type"] = "label"
    table["label"] = label
    table["x"] = x
    table["y"] = y
    table["width"] = width
    table["height"] = height
    table["color"] = color
    objects[ID] = table
end
    
function newBar(ID,x,y,width,height,color1,color2,value)
    local table = {}
    table["type"] = "bar"
    table["x"] = x
    table["y"] = y
    table["width"] = width
    table["height"] = height
    table["color1"] = color1 --Left color
    table["color2"] = color2 --Right color
    table["value"] = value
    objects[ID] = table
end

function removeObject(ID)
    objects[ID] = {}
end

function clearAllObjects()
    clearScreen()
    objects = {}
end

function draw(ID)
    data = objects[ID]
    local objtype = data["type"]
    local label = data["label"]
    local x = data["x"]
    local y = data["y"]
    local width = data["width"]
    local height = data["height"]
    if objtype == "button" then
        local drawColor = 0x000000
        if data["active"] == true then
            drawColor = data["oncolor"]
        else
            drawColor = data["offcolor"]
        end
        gpu.setBackground(drawColor,false)
        gpu.fill(x,y,width,height," ")
        gpu.set((x+width/2)-string.len(label)/2,y+height/2,label)
        gpu.setBackground(colors.black,true)
    elseif objtype == "label" then
        gpu.setBackground(data["color"],false)
        gpu.fill(x,y,width,height," ")
        gpu.set((x+width/2)-string.len(label)/2,y+height/2,label)
        gpu.setBackground(colors.black,true)
    elseif objtype == "bar" then
        gpu.setBackground(data["color2"],false)
        gpu.fill(x,y,width,height," ")
        local amount = math.floor((width/100)*data["value"])
        gpu.setBackground(data["color1"],false)
        gpu.fill(x,y,amount,height," ")
        gpu.setBackground(colors.black,true)
    end
end

function toggleButton(ID)
    local objtype = objects[ID]["type"]
    if not objtype == "button" then return end
    objects[ID]["active"] = not objects[ID]["active"]
    draw(ID)
end

function flashButton(ID)
    local objtype = objects[ID]["type"]
    if not objtype == "button" then return end
    API.toggleButton(ID)
    os.sleep(0.15)
    toggleButton(ID)
end

function getButtonState(ID)
    local objtype = objects[ID]["type"]
    if not objtype == "button" then return end
    return objects[ID]["active"]
end

function getButtonClicked(x,y)
    for ID,data in pairs(objects) do
        local xmax = data["x"]+data["width"]-1
        local ymax = data["y"]+data["height"]-1
        if data["type"] == "button" then
            if x >= data["x"] and x <= xmax then
                if y >= data["y"] and y <= ymax then
                    return ID
                end
            end
        end
    end
    return nil
end

function activateButton(ID)
    local objtype = objects[ID]["type"]
    if not objtype == "button" then return end
    objects[ID]["func"](objects[ID]["params"])
end

function updateAll()
    clearScreen()
    for ID,data in pairs(objects) do
        draw(ID)
    end
end

function processClick(x,y)
    local ID = getButtonClicked(x,y)
    if not ID then return end
    local objtype = objects[ID]["type"]
    if not objtype == "button" then return end
    if not ID == false then
        if objects[ID]["toggle"] == true then
            toggleButton(ID)
            activateButton(ID)
        else
            flashButton(ID)
            activateButton(ID)
        end
    end
end

function setBarValue(ID,value)
    local objtype = objects[ID]["type"]
    if not objtype == "bar" then return end
    objects[ID]["value"] = clamp(value,0,100)
    draw(ID)
end

function setLabelText(ID,label)
    local objtype = objects[ID]["type"]
    if not objtype == "label" or not objtype == "button" then return end
    if not label then label = " " end
    objects[ID]["label"] = label
    draw(ID)
end
function setBarColor(ID,color1,color2)
    local objtype = objects[ID]["type"]
    if not objtype == "bar" then return end
    objects[ID]["color1"] = color1
    objects[ID]["color2"] = color2
    draw(ID)
end
function setLabelColor(ID,color)
    local objtype = objects[ID]["type"]
    if not objtype == "label" then return end
    objects[ID]["color"] = color
    draw(ID)
end
function setButtonColor(ID,color1,color2)
    local objtype = objects[ID]["type"]
    if not objtype == "button" then return end
    objects[ID][ "color1" ] = color1
    objects[ID][ "color2" ] = color2
    draw(ID)
end
