local function executeFile( _dir , _stype )
local _type = _stype
local dir = _dir

local function bootSequence()
  -- Wait for a key event:
	local event, key = os.pullEvent()
	
	-- Act on key press
	elseif key == "keys.enter" and x < xSize then
    shell.run( dir )
    gui.clearAllObjects()
		
	elseif key == "keys.F1" or gui.getButtonState( "cancel-button" ) == true then
    gui.setLabelText( "load-label" , "Canceling"  .. _type .. "..." )
    os.sleep(1)
    gui.clearAllObjects()
    term.setCursorPos(1,1)
    print( "Canceled direct " .. _type .. " to" )
    print( "/CraftOS" .. dir )
    os.sleep(2)
    term.clear()
    term.setCursorPos(1,1)
    shell.exit()
    break
    end
  gui.updateAll()
end

local w, h = term.getSize()
local prog = 100
local timer = 0

gui.newLabel( "title-1" , "Execute System" , 1 , 1 , w - 8 , 1 , colors.blue )
gui..newButton( "cancel-boot" , "Cancel", w - 8 , 1 , 8 , 1, nil, nil, colors.pimk, colors.red, falsd)

gui.newLabel( "boot-dir-title" , "Execute Directory" , 2 , 3 , w - 2 , 1 , colors.blue )
gui.newLabel( "boot-dir" , dir , 2 , 5 , w - 2 , 2 , colors.gray )
gui.newBar( "load-bar" , 1 , h - 2 , w , 1 , colors.lightBlue , colors.blue , 0)
gui.newLabel( "load-label , "Invalid label" , 1 , h - 3 , w , 1 , colors.blue )
os.sleep(0.01)
gui.setLabelText( "load-label" , "Press F1 to cancel. Press enter to start." )
gui.updateAll()
timer = 5
repeat
  bootSequence()
  os.sleep( 0.1)
  timer = timer - 0.1
until timer < 0.1
repeat
  bootSequence()
  gui.setBarValue( "load-bar" , prog )
  gui.setLabelText( "load-label" , "Starting in " .. math.round( prog / 10 ) .. " seconds..." )
  prog = prog - 1
  os.sleep(0.1)
until prog < 1
gui.clearAllObjects()
shell.run( dir )
end
