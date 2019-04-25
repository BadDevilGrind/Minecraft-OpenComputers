--This is the central program that needs to be run on a computer connected to the tardisinterface from the Handles mod.
--In order to use the sister program, TardOSRemote, you must create a pair of linked cards and insert one in this computer and one on the receiving end.

local event = require("event")
local component = require("component")
local os = require("os")
local term = require("term")

handles = component.tardisinterface

tFuel =handles.getFuel()
tDestX, tDestY, tDestZ, tDestDim = handles.getTardisDestination()
tPosX, tPosY, tPosZ = handles.getTardisPos()

tCanFly = handles.canFly()
tHull = handles.getHull()

function fly(waypointID)
  print("Commencing flight")
  if tFuel <= 0.5 then
    print("Warning, fuel at less than 50%, refuel as soon as possible")
  elseif tFuel <= 0.25 then
    print("Warning, fuel at less than 25%, unable to commence automatic flight sequence")
	os.sleep(2)
    return
  end
  if waypointID ~= nil then
    local wpX, wpY, wpZ, wpDim, wpName = handles.getWaypoint(tonumber(waypointID))
    print(tostring(wpX))
    handles.setTardisDestination(wpX,wpY,wpZ,wpDim) 
  end
  
  handles.startFlight()
  os.sleep(1)  
end

function updateStats()
  tFuel =handles.getFuel()
  tDestX, tDestY, tDestZ, tDestDim = handles.getTardisDestination()
  tCanFly = handles.canFly()
  tHull = handles.getHull()
  tPosX, tPosY, tPosZ = handles.getTardisPos()
end

function setX(x)
  local prevX, prevY, prevZ, prevDim = handles.getTardisDestination()
  handles.setTardisDestination(tonumber(x), prevY, prevZ, prevDim)
end

function setY(y)
  local prevX, prevY, prevZ, prevDim = handles.getTardisDestination()
  handles.setTardisDestination(prevX, tonumber(y), prevZ, prevDim)
end

function setZ(z)
  local prevX, prevY, prevZ, prevDim = handles.getTardisDestination()
  handles.setTardisDestination(prevX, prevY, tonumber(z), prevDim)
end

function setDim(dim)
  local prevX, prevY, prevZ, prevDim = handles.getTardisDestination()
  handles.setTardisDestination(prevX, prevY, prevZ, tonumber(dim))
end

function printScreen()
  term.clear()
  local fuelPercentage = tFuel * 100
  local hullPercentage = tHull * 100
  print("--------------------------TardOS  v0.0.1--------------------------")
  print("Fuel: "..fuelPercentage.."%")
  print("Position: X: "..tPosX.." Y: "..tPosY.." Z: "..tPosZ.." Dim: "..handles.getDimensionName(handles.getDimension()).."("..handles.getDimension()..")")
  print("Destination: X: "..tDestX.." Y: "..tDestY.." Z: "..tDestZ.." Dim: "..handles.getDimensionName(tDestDim).."("..tDestDim..")")
  print("Flight Status: "..tostring(tCanFly))
  print("Hull: "..hullPercentage.."%")
  print("------------------------------------------------------------------")
  print()
end


function stringsplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

function main(eventName, from, port, var1, var2, message)
  updateStats()
    
  if handles.isInFlight() then
    printScreen()
  end

  while handles.isInFlight() do
    term.write("Flight Time: "..handles.getTravelTime())
    os.sleep(0.5)
    term.clearLine()
  end 
   
  printScreen()
  
  local input = ""
  --Check if message is not nil
  if message ~= nil  then
    input = message
  else
    input = term.read()    
  end  


  cmd = stringsplit(input)
  
  if cmd[1] == "fly" then
    fly()
  elseif cmd[1] == "setX" then
    print("Setting X to "..cmd[2])
    setX(cmd[2])
  elseif cmd[1] == "setY" then
    print("Setting Y to "..cmd[2])
    setY(cmd[2])
  elseif cmd[1] == "setZ" then
    print("Setting Z to "..cmd[2])
    setZ(cmd[2])
  elseif cmd[1] == "setDim" then
    setDim(cmd[2])
  elseif cmd[1] == "refuel" then
    handles.setFueling(true)
  elseif cmd[1] == "waypoint" then
    fly(cmd[2])
  else
    print("Invalid CMD")
    os.sleep(1)  
  end
  main()
end

print("Starting TardOS")
print("Stopping listener")
event.ignore("modem_message", main)
print("Starting listener")
event.listen("modem_message", main)

main()
