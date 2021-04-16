-- [ --------------------------------------------------------------------- ] --
-- [ RedNetChat - A public chat program for ComputerCraft                  ] --
-- [ Created by gpgautier (ign gpgauier), 2012                             ] --
-- [ Licence: Creative Commons Attribution-ShareAlike 3.0 Unported License ] --
-- [ ComputerCraft version: 1.3 and up                                     ] --
-- [ Posted to:                                                            ] --
-- [ GitHub: https://github.com/gpgautier/RedNetChat                       ] --
-- [ Pastebin: http://pastebin.com/JDU4wJxX                                ] --
-- [ --------------------------------------------------------------------- ] --

local VERSION = "0.6"
local MODEM = nil
local NICKNAME = nil
local ACTIVE = false
local BUFFER = {}
local POINTER = 0
local ONLINE = {}
local ISONLINE = false
local ID = os.computerID()
local LAST_MSG_TARGET = nil
local CHANNEL = 1
local SCROLL_POINTER = POINTER
local WIDTH, HEIGHT = term.getSize()
local LINES = HEIGHT - 6
local START_LINE = 5
local OPERATOR = "ChatSYS"

-- [ --------------------------------------------------------------------- ] --

-- Split a string
function split(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    if str ~= nil then
       local fpat = "(.-)" .. pat
       local last_end = 1
       local s, e, cap = str:find(fpat, 1)
       while s do
          if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
          end
          last_end = e+1
          s, e, cap = str:find(fpat, last_end)
       end
       if last_end <= #str then
          cap = str:sub(last_end)
          table.insert(t, cap)
       end
    else
        print("##ERROR failed to split ["..str.."] by:"..pat)
    end
    return t
end

-- Log a message to file
function log(message)
  local file = io.open("rednetchat.log", "a")
  file:write("\n" .. message)
  file:close()
end

-- Application entry
function main()
  term.clear()
  term.setCursorPos(1, 1)

  if not setPeripherals() then
    print("[FATAL ERROR] Not able to setup peripherals.")
    return false
  end
 
  welcome()
end

-- Set the attached peripherals. Opens rednet modem and warps monitor
function setPeripherals()
  local i, side

  for i, side in pairs(rs.getSides()) do
    if peripheral.isPresent(side) then
      if peripheral.getType(side) == "modem" then
        MODEM = side
        if not rednet.isOpen(side) then
          rednet.open(MODEM)
        end
      end
    end
  end
 
  -- Exit with a fatal error when modem not found
  if MODEM == nil then
    print("[FATAL ERROR] No modem was detected. Plase attach a modem on any side.")
    return false
  end

  return true
end

-- Start the welcome screen
function welcome()
  local x, y
  term.clear()
  writeHeader()

  print("")
  print("")
  print("Enter a nickname and press [enter].")
  print("")
  term.write("Nickname: ")
 
  x, y = term.getCursorPos()

  while NICKNAME == nil or NICKNAME == "" do
    term.setCursorPos(x, y)
    NICKNAME = read()
    execute("/online")
    appendBuffer("[" .. OPERATOR .. "]: Type /help for a list of commands")
  end
 
  start()
end

-- Writes the screen header
function writeHeader()
  local col

  term.setCursorPos(1, 1)
  term.write("RedNet Chat " .. VERSION .. "")
  term.setCursorPos(1, 2)

  for col = 1, WIDTH do
    term.write("-")
  end
end

-- Writes the list of online users
function writeOnlineList()
  local i, v, count, x, y, col

  count = 0

  x, y = term.getCursorPos()
 
  term.setCursorPos(1, HEIGHT - 1)

  for col = 1, WIDTH do
    term.write("-")
  end
 
  term.setCursorPos(1, HEIGHT)
  term.clearLine()
  term.write("Online: ")

  for i, v in pairs(ONLINE) do
    if count == 0 then
      term.write(i)
    else
      term.write(", " .. i)
    end

    count = count + 1
  end

  if count == 0 then
    term.write("Nobody online in channel " .. CHANNEL)
  end

  term.setCursorPos(x, y)
end

-- Start the chat
function start()
  term.clear()
  writeHeader()
  writeOnlineList()

  ACTIVE = true

  showBuffer()
 
  parallel.waitForAll(input, watchEvents)
end

-- Stop the application
function stop()
  ACTIVE = false
end

-- Reset the application
function reset()
  execute("/offline")

  if rednet.isOpen(MODEM) then
    rednet.close(MODEM)
  end

  sleep(1.5)
  os.reboot()
end

-- Watch all input to provide possible shortcuts (for example usernames)
function watchEvents()
  local type, param, param2, param3, i, v
 
  while ACTIVE do
    type, param, param2, param3 = os.pullEvent()

    if type == "key" then
      local _repeat = 0
      if param == 200 then -- up
        scroll(-1)
      elseif param == 208 then -- down
        scroll(1)
      elseif param == 201 then -- pageup
        _repeat = 12
        repeat
        scroll(-1)
        _repeat = _repeat - 1
        until _repeat < 1
      elseif param == 209 then -- pagedown
        _repeat = 12
        repeat
        scroll(1)
        _repeat = _repeat - 1
        until _repeat < 1
      --else
      --  appendBuffer(tostring(param))
      end
    elseif type == "mouse_scroll" then
      if param == -1 then
        scroll(-1)
      else
        scroll(1)
      end
    elseif type == "rednet_message" then
      receive(param2)
    end
  end
end

-- Scroll through the chat
function scroll(amount)
  SCROLL_POINTER = SCROLL_POINTER + amount
  showBuffer()
end

-- Handle input from the prompt
function input()
  local message, col

  term.setCursorPos(1, 4)
 
  for col = 1, WIDTH do
    term.write("-")
  end

  while ACTIVE do
    term.setCursorPos(1, 3)
    term.clearLine()
    term.write("[" .. CHANNEL .. "] > ")

    message = read()

    if message ~= nil and message ~= "" then
      execute(message, "local")
    end
  end
end

-- Send a message
function send(message, target)
  local request, serialized, x, encrypted

  request = {protocol = "rnc", nickname = NICKNAME, sender = ID, target = target, channel = CHANNEL, message = message}
  serialized = textutils.serialize(request)

  encrypted = ""
  for x = 1, #serialized do
    encrypted = encrypted .. string.char(serialized:byte(x) + 1)
  end

  if request.target ~= nil then    
    rednet.send(request.target, encrypted)
  else
    rednet.broadcast(encrypted)
  end
end

-- Recieve a message
function receive(message)
  local request, decrypted, x

  if message ~= nil and message ~= "" then

    decrypted = ""
    for x = 1, #message do
      decrypted = decrypted .. string.char(message:byte(x) - 1)
    end

    request = textutils.unserialize(decrypted)

    if request.protocol == "rnc" and request.channel == CHANNEL then
      if request.nickname ~= nil and request.nickname ~= "" then
        execute(request, "remote")
      end
    end
  end
end

-- Execute a command or add a chat message
function execute(message, source)
  local command, splitCommand, nickname, id, body, onlineUser
 
  if message.nickname ~= nil then
    executeRemote(message)
    return
  end

  if message:sub(0, 1) == "/" then
      command = message:sub(2)

      if command == "quit"
          or command == "reset"
          or command == "restart"
          or command == "reboot"
          or command == "stop"
        then
          appendBuffer("[" .. OPERATOR .. "]: Stopping application")
          reset()
      elseif command == "online" then
        if not ISONLINE then
          send("/online")
          putOnline()
          appendBuffer("[" .. OPERATOR .. "]: You are now online")
          ISONLINE = true
        else
          appendBuffer("[" .. OPERATOR .. "]: You are already online")
        end
      elseif command == "offline" then
        if ISONLINE then
          send("/offline")
          takeOffline()
          appendBuffer("[" .. OPERATOR .. "]: You are now offline")
          ISONLINE = false
        else
          appendBuffer("[" .. OPERATOR .. "]: You are already offline")
        end
      elseif command:sub(0, 5) == "nick " then
        takeOffline()
        NICKNAME = command:sub(6)
        putOnline()
        appendBuffer("[" .. OPERATOR .. "]: Your nickname has been changed")
      elseif command:sub(0, 5) == "slap " then
        appendBuffer(command:sub(6) .. " was slapped by " .. NICKNAME)
      elseif command:sub(0, 4) == "msg " then
        splitCommand = split(command:sub(5), "%s")

        onlineUser = false

        for nickname, id in pairs(ONLINE) do
          if nickname == splitCommand[1] then
            body = command:sub(5 + splitCommand[1]:len() + 1)
            send(body, id)
            appendBuffer(NICKNAME .. " > " .. nickname .. ": " .. body)
            onlineUser = true
            LAST_MSG_TARGET = nickname
          end
        end

        if not onlineUser then
            appendBuffer("[" .. OPERATOR .. "]: User " .. splitCommand[1] .. " is not online")
        end
      elseif command:sub(0, 2) == "r " then
        if LAST_MSG_TARGET ~= nil then
          execute("/msg " .. LAST_MSG_TARGET .. " " .. command:sub(3), "local")
        else
          appendBuffer("[" .. OPERATOR .. "]: No valid user for message")
        end
      elseif command:sub(0, 5) == "join " then
        if CHANNEL ~= tonumber(command:sub(6)) then
          execute("/offline")
          CHANNEL = tonumber(command:sub(6))
          execute("/online")
          appendBuffer("[" .. OPERATOR .. "]: Joined channel " .. CHANNEL)
        else
          appendBuffer("[" .. OPERATOR .. "]: Already in channel " .. CHANNEL)
        end
      elseif command == "help" then
        appendBuffer("[" .. OPERATOR .. "] Commands:")
        appendBuffer("/quit : Exit the chat")
        appendBuffer("/msg <nickname> <message> : Send a private message")
        appendBuffer("/r <message> : Reply to a private message")
        appendBuffer("/join <channel> : Switch channel")
      else
        appendBuffer("[" .. OPERATOR .. "]: Unknown command")
      end
     
      return
  end
  if ONLINE[NICKNAME] = os.computerID() then
    appendBuffer(NICKNAME .. ": " .. message)
    send(message)
  else
    appendBuffer( "You must be online to send a message" )
  end
end

--
function putOnline(nickname, id)
  if nickname == nil or id == nil then
    nickname = NICKNAME
    id = ID
  end

  ONLINE[nickname] = id

  writeOnlineList()
end

--
function takeOffline(nickname, id)
  if nickname == nil or id == nil then
    nickname = NICKNAME
    id = ID
  end

  ONLINE[nickname] = nil
  writeOnlineList()
  if nickname ~= NICKNAME then
    appendBuffer( "You are offline. Others will see that you are offline." )
  end
end


--
function executeRemote(request)
  local command

  if request.message:sub(0, 1) == "/" then
    command = request.message:sub(2)

    if command == "online" then
      putOnline(request.nickname, request.sender)
      appendBuffer("[" .. OPERATOR .. "]: " .. request.nickname .. " is now online")
      send("/metoo")
    elseif command == "offline" then
      takeOffline(request.nickname, request.sender)
      appendBuffer("[" .. OPERATOR .. "]: " .. request.nickname .. " is now offline")
    elseif command == "metoo" then
      putOnline(request.nickname, request.sender)
    end
    return
  end

  if request.target ~= nil then
    appendBuffer(request.nickname .. " > " .. NICKNAME .. ": " .. request.message)
    LAST_MSG_TARGET = request.nickname
  else
    appendBuffer(request.nickname .. ": " .. request.message)
  end
end

--
function appendBuffer(message)
  local length

  length = message:len()

  if length > WIDTH then
    table.insert(BUFFER, message:sub(1, WIDTH))
    POINTER = POINTER + 1
    appendBuffer(message:sub(WIDTH + 1))
  else
    table.insert(BUFFER, message)
    POINTER = POINTER + 1
  end

  SCROLL_POINTER = POINTER

  showBuffer()
end

--
function showBuffer()
  local i, line, bufferPointer, x, y, pointer

  pointer = SCROLL_POINTER
 
  if pointer == 0 then
    return
  elseif SCROLL_POINTER > POINTER then
    SCROLL_POINTER = POINTER
    pointer = POINTER
  elseif POINTER < LINES + 1 then
    SCROLL_POINTER = POINTER
    pointer = POINTER
  elseif POINTER > LINES and SCROLL_POINTER < LINES then
    SCROLL_POINTER = LINES
    pointer = SCROLL_POINTER
  end

  x, y = term.getCursorPos()
 
  line = START_LINE

  bufferPointer = -(LINES - 1 - pointer)
 
  for i = bufferPointer, bufferPointer + (LINES - 1) do
    term.setCursorPos(1, line)
    term.clearLine()
   
    if BUFFER[i] ~= nil then
      term.write(tostring(BUFFER[i]))
    end
   
    line = line + 1
  end

  term.setCursorPos(x, y)
end

-- Fire up the application
main()
