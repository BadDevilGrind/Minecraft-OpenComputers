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
  
  if handles.canFly() == false then
    print("Warning, unable to lift off due to subsystem damage")
    return("WARNING: Subsystem damage prevents flight.")
  end
  
  if tFuel <= 0.5 then
    print("Warning, fuel at less than 50%, refuel as soon as possible")
  elseif tFuel <= 0.25 then
    print("Warning, fuel at less than 25%, unable to commence automatic flight sequence")
    return "WARNING: Fuel too low for automatic flight"
  end
  if waypointID ~= nil then
    local wpX, wpY, wpZ, wpDim, wpName = handles.getWaypoint(tonumber(waypointID))
    handles.setTardisDestination(wpX,wpY,wpZ,wpDim) 
  end
  
  handles.startFlight()
  return "INFO: Command received."
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
  return "INFO: Command received."
end

function setY(y)
  local prevX, prevY, prevZ, prevDim = handles.getTardisDestination()
  handles.setTardisDestination(prevX, tonumber(y), prevZ, prevDim)
  return "INFO: Command received."
end

function setZ(z)
  local prevX, prevY, prevZ, prevDim = handles.getTardisDestination()
  handles.setTardisDestination(prevX, prevY, tonumber(z), prevDim)
  return "INFO: Command received."
end

function setDim(dim)
  local prevX, prevY, prevZ, prevDim = handles.getTardisDestination()
  handles.setTardisDestination(prevX, prevY, prevZ, tonumber(dim))
  return "INFO: Command received."
end

function emergency()
  local prevX, prevY, prevZ = handles.getTardisPos()
  local prevDim = handles.getDimension()
  print("Commencing emergency protocol")
  print("Flying to waypoint ID 0")
  fly(0)
  
  while handles.isInFlight() do
    term.write("Flight Time: "..handles.getTravelTime())
    os.sleep(1)
    term.clearLine()
  end  
  
  print("Arrived at waypoint ID 0")
  print("Commencing refueling and repairing")
  handles.setFueling(true)
  handles.setRepairing(true)
  
  while handles.getFuel() ~= 1.0 and handles.getHull() ~= 1.0 do
    term.write("Repairing and refueling.)
    os.sleep(1)
    term.clearLine()
  end
  
  print("TARDIS refueled and repaired")  
  handles.setTardisDestination(prevX, prevY, prevZ, prevDim)
  
  os.sleep(1)
  
  fly()
  return "INFO: TARDIS returning."
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
    os.sleep(1)
    term.clearLine()
  end 
   
  printScreen()
  
  local input = ""
  local modemMessage = false
  local response = ""
  --Check if message is not nil
  if message ~= nil  then
    input = message
    modemMessage = true
  else
    input = term.read()    
  end  


  cmd = stringsplit(input)
  
  if cmd[1] == "fly" then
    response = fly()
  elseif cmd[1] == "setX" then
    print("Setting X to "..cmd[2])
    response = setX(cmd[2])
  elseif cmd[1] == "setY" then
    print("Setting Y to "..cmd[2])
    response = setY(cmd[2])
  elseif cmd[1] == "setZ" then
    print("Setting Z to "..cmd[2])
    response = setZ(cmd[2])
  elseif cmd[1] == "setDim" then
    response = setDim(cmd[2])
  elseif cmd[1] == "refuel" then
    handles.setFueling(true)
    reponse = "INFO: Command received."
  elseif cmd[1] == "waypoint" then
    reponse = fly(cmd[2])
  elseif cmd[1] == "sos" then
    response = emergency()
  else
    print("Invalid CMD")
    reponse = "Invalid CMD")
    os.sleep(1)  
  end
  
  if modemMessage then
    local tunnel = component.proxy(port)
    print(port)
    os.sleep(30)
    tunnel.send(response)
  end
  
  main()
end

print("Stopping listener")
event.ignore("modem_message", main)
print("Starting listener")
event.listen("modem_message", main)

main()
