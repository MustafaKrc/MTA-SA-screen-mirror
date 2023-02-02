-- SCREEN INVERT
local w, h = guiGetScreenSize() 

screenSrc = dxCreateScreenSource(w, h) 
addEventHandler( "onClientPreRender", root, function() 
    dxUpdateScreenSource( screenSrc ) 
    dxDrawImage( w, 0, -w, h,screenSrc ) 
end) 

--KEY INVERT

local keys = { 
	"vehicle_right", "vehicle_left", 
	"vehicle_look_right", "vehicle_look_left",
	"special_control_right", "special_control_left",
	"left", "right",
};

function invertedKeys(key, state)
	local s,e = key:find("right") and key:find("right") or key:find("left");
	local dir = key:sub( s, e );
	local newkey = key:gsub( dir, (dir == "right" and "left" or "right"));
	local enabledControl = ( state == "down" and true or false )
	setControlState( newkey, enabledControl );
end


--MOUSE INVERT X AXIS

--My implementation

local rotX, rotY, camDist = 0,0,10
local tickCount = 0
local start,regular_tick = getTickCount(),0
local viewAngle = math.pi / 48
local up_coef = 1
function updateCameraRotation()
	tickCount = tickCount + 1

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then
        return
    end

	
    local camPos = getPositionFromElementOffset(vehicle, 0, -10, 0)
    local camTargetX, camTargetY, camTargetZ = getElementPosition(vehicle)


	if tickCount < 54 then --54  mouse controlled camera
		local cameraAngleX = rotX
		local cameraAngleY = rotY

		local freeModeAngleZ = math.sin(cameraAngleY)
		local freeModeAngleY = math.cos(cameraAngleY) * math.cos(cameraAngleX)
		local freeModeAngleX = math.cos(cameraAngleY) * math.sin(cameraAngleX)
		
		camPos.x = camTargetX + freeModeAngleX * camDist
		camPos.y = camTargetY + freeModeAngleY * camDist
		camPos.z = camTargetZ + freeModeAngleZ * camDist
		setCameraMatrix(camPos.x, camPos.y, camPos.z, camTargetX, camTargetY, camTargetZ)
		start = getTickCount()
	else -- camera without movement

        if tickCount < 108 then --54 * 2 -- stationary camera
            local cameraAngleX = rotX
            local cameraAngleY = rotY
    
            local freeModeAngleZ = math.sin(cameraAngleY)
            local freeModeAngleY = math.cos(cameraAngleY) * math.cos(cameraAngleX)
            local freeModeAngleX = math.cos(cameraAngleY) * math.sin(cameraAngleX)
            
            camPos.x = camTargetX + freeModeAngleX * camDist
            camPos.y = camTargetY + freeModeAngleY * camDist
            camPos.z = camTargetZ + freeModeAngleZ * camDist
            setCameraMatrix(camPos.x, camPos.y, camPos.z, camTargetX, camTargetY, camTargetZ)
            start = getTickCount()
        else -- following camera

		vX, vY, vZ = getElementVelocity(getPedOccupiedVehicle(localPlayer))
		local magnitude = math.sqrt(vX*vX + vY*vY + vZ*vZ)

		camPos.x = camTargetX - vX * camDist / magnitude
		camPos.y = camTargetY - vY * camDist / magnitude
		camPos.z = camTargetZ - vZ * camDist / magnitude
		--rotY = math.atan2(math.sqrt((camPos.x-camTargetX)*(camPos.x-camTargetX)+(camPos.y-camTargetY)*(camPos.y-camTargetY)),camTargetZ-camPos.z) - math.pi/2 -- - vZ / (720 * magnitude/ math.pi)  --+ viewAngle
		--rotX = math.atan2(camPos.x - camTargetX,camPos.y - camTargetY)
		--setCameraMatrix(camPos.x, camPos.y, camPos.z, camTargetX, camTargetY, camTargetZ)
		local arrivalX = math.atan2(-1*vX,-1*vY)
		local arrivalY = math.atan(-1*(vZ-0.1)/magnitude) - (vZ-0.1) / (10*up_coef*magnitude/math.pi)

		local cameraAngleX,cameraAngleY = interpolateCam(rotX,rotY,arrivalX,arrivalY)

		local freeModeAngleZ = math.sin(cameraAngleY)
		local freeModeAngleY = math.cos(cameraAngleY) * math.cos(cameraAngleX)
		local freeModeAngleX = math.cos(cameraAngleY) * math.sin(cameraAngleX)
		camPos.x = camTargetX + freeModeAngleX * camDist
		camPos.y = camTargetY + freeModeAngleY * camDist
		camPos.z = camTargetZ + freeModeAngleZ * camDist

		setCameraMatrix(camPos.x, camPos.y, camPos.z, camTargetX, camTargetY, camTargetZ)

		--local intervalX,intervalY,intervalZ = interpolateCam(dx,dy,dz,camPos.x,camPos.y,camPos.z)
		--setCameraMatrix(intervalX, intervalY, intervalZ, camTargetX, camTargetY, camTargetZ)
			
		rotY = math.atan2(math.sqrt((camPos.x-camTargetX)*(camPos.x-camTargetX)+(camPos.y-camTargetY)*(camPos.y-camTargetY)),camTargetZ-camPos.z) - math.pi/2 - vZ / (720 * magnitude/ math.pi)  --+ viewAngle
		rotX = math.atan2(camPos.x - camTargetX,camPos.y - camTargetY)
		local PI = math.pi
		if rotX > PI then
			rotX = rotX - 2 * PI
		elseif rotX < -PI then
			rotX = rotX + 2 * PI
		end
			
		if rotY > PI then
			rotY = rotY - 2 * PI
		elseif rotY < -PI then
			rotY = rotY + 2 * PI
		end
        
        end

	end

end

addEventHandler("onClientRender", root, updateCameraRotation)

function interpolateCam(rotX,rotY, targetX,targetY)
    local now = getTickCount()
    local endTime = start + 3000
    local elapsedTime = now - start
    local duration = endTime - start
    local progress = elapsedTime / duration

    local x,y = interpolateBetween ( rotX,rotY,0, targetX,targetY,0, progress, "InQuad")
	if progress >= 0.9 then
		tickCount = 54
	end
    return x,y
end

local mouseFrameDelay = 0
local mouseSensitivity = 0.1

function freecamMouse(cX,cY,aX,aY)

    --ignore mouse movement if the cursor or MTA window is on
    --and do not resume it until at least 5 frames after it is toggled off
    --(prevents cursor mousemove data from reaching this handler)
	tickCount = 0
    if isCursorShowing() or isMTAWindowActive() then
        mouseFrameDelay = 5
        return
    elseif mouseFrameDelay > 0 then
        mouseFrameDelay = mouseFrameDelay - 1
        return
    end

    -- how far have we moved the mouse from the screen center?
    local width, height = guiGetScreenSize()
    aX = aX - width / 2 
    aY = aY - height / 2
    
    
    rotX = rotX + aX * mouseSensitivity * 0.01745
    rotY = rotY + aY * mouseSensitivity * 0.01745
    
    local PI = math.pi
    if rotX > PI then
        rotX = rotX - 2 * PI
    elseif rotX < -PI then
        rotX = rotX + 2 * PI
    end
    
    if rotY > PI then
        rotY = rotY - 2 * PI
    elseif rotY < -PI then
        rotY = rotY + 2 * PI
    end

    -- limit the camera to stop it going too far up or down - PI/2 is the limit, but we can't let it quite reach that or it will lock up
    -- and strafeing will break entirely as the camera loses any concept of what is 'up'
    if rotY < -PI / 2.05 then
       rotY = -PI / 2.05
    elseif rotY > PI / 2.05 then
        rotY = PI / 2.05
    end
	tickCount = 0

end


addEventHandler("onClientCursorMove",root, freecamMouse)

function getPositionFromElementOffset(element,offX,offY,offZ)
        
    local m = getElementMatrix (element)  -- Get the matrix
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]  -- Apply transform
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
    
    return {x=x, y=y, z=z}
end

local isUpPressed = false
function addRotY() --doesnt work when going uphills

	if isUpPressed then
		up_coef = 1
		isUpPressed = false
	else
		up_coef = 0.3
		isUpPressed = true
	end
end

bindKey("arrow_u","both",addRotY)

--[[


--https://forum.multitheftauto.com/topic/68807-new-camera-mode/#comment-641049

local rotX, rotY, rotSpeed, rotRadius, smoothWave, lastKey, visible = 0, 0, 3, 10, 0, "l", false 
  
local function render3DCamera( ) 
    local rotSpeed = rotSpeed / 10000 
     
    if ( getKeyState( "arrow_l" ) ) then 
        rotX = ( rotX - rotSpeed < 0 and rotX - rotSpeed + 360 or rotX - rotSpeed ) 
        smoothWave, lastKey = 3, "l" 
    elseif ( getKeyState( "arrow_r" ) ) then 
        rotX = ( rotX + rotSpeed > 360 and rotX + rotSpeed - 360 or rotX + rotSpeed ) 
        smoothWave, lastKey = 3, "r" 
    elseif ( not getKeyState( "arrow_l" ) ) and ( not getKeyState( "arrow_r" ) ) then 
        if ( smoothWave > 0 ) then 
            smoothWave = smoothWave - 0.07 
            local smoothWave = smoothWave / 10000 
             
            if ( lastKey == "l" ) then 
                rotX = ( rotX - smoothWave < 0 and rotX - smoothWave + 360 or rotX - smoothWave ) 
            elseif ( lastKey == "r" ) then 
                rotX = ( rotX + smoothWave > 360 and rotX + smoothWave - 360 or rotX + smoothWave ) 
            end 
        elseif ( smoothWave < 0 ) then 
            smoothWave = 0 
        end 
    end 
    local vehicle = getPedOccupiedVehicle(localPlayer)
    local x, y, z = getElementPosition( vehicle ) 
    local cx, cy, cz = getCameraMatrix( ) 
    local _cx, _cy, _cz = cx, cy, cz 
     
    if ( getKeyState( "arrow_u" ) ) then 
        _rotY = ( rotY - rotSpeed > 0 and rotY - rotSpeed or rotY ) 
        if ( isLineOfSightClear( x, y, z, _cx, _cy, math.cos( math.deg( _rotY ) ) * rotRadius + z - 0.5 ) ) then 
            rotY = ( rotY - rotSpeed > 0 and rotY - rotSpeed or rotY ) 
            smoothWave, lastKey = 3, "u" 
        end 
    elseif ( getKeyState( "arrow_d" ) ) then 
        _rotY = ( rotY + rotSpeed < 130 and rotY + rotSpeed or rotY ) 
        if ( isLineOfSightClear( x, y, z, _cx, _cy, math.cos( math.deg( _rotY ) ) * rotRadius + z - 0.5 ) ) then 
            rotY = ( rotY + rotSpeed < 130 and rotY + rotSpeed or rotY ) 
            smoothWave, lastKey = 3, "d" 
        end 
    elseif ( not getKeyState( "arrow_u" ) ) and ( not getKeyState( "arrow_d" ) ) then 
        if ( smoothWave > 0 ) then 
            smoothWave = smoothWave - 0.07 
            local smoothWave = smoothWave / 20000 
             
            if ( lastKey == "u" ) then 
                rotY = ( rotY - smoothWave > 0 and rotY - smoothWave or rotY ) 
            elseif ( lastKey == "d" ) then 
                rotY = ( rotY + smoothWave < 130 and rotY + smoothWave or rotY ) 
            end 
        elseif ( smoothWave < 0 ) then 
            smoothWave = 0 
        end 
    end 
     
    _cx = math.cos( math.deg( rotX ) ) * rotRadius + x 
    _cy = math.sin( math.deg( rotX ) ) * rotRadius + y 
    _cz = math.cos( math.deg( rotY ) ) * rotRadius + z 
     
    setCameraMatrix( _cx, _cy, _cz, x, y, z ) 
end 
  
function initialize3DCamera( ) 
    visible = not visible 
    local fn = visible and addEventHandler or removeEventHandler 
    fn("onClientPreRender", root, render3DCamera) 
    fn("onClientCursorMove", root, mouse) 
    if not visible then 
        setCameraTarget(localPlayer) 
    end 
end 
--addEventHandler("onClientPreRender", root, render3DCamera) 
--addEventHandler("onClientCursorMove", root, mouse) 

addEventHandler("onClientResourceStart", root, initialize3DCamera) 

function mouse(cX,cY,aX,aY) 
    if isCursorShowing() or isMTAWindowActive() then return end 
    local sX, sY = guiGetScreenSize() 
    aX = aX - sX/2  
    aY = aY - sY/2 
     
    rotX = rotX + aX * 0.005 * 0.01745 -- -aX ....
    rotY = rotY + aY * 0.005 * 0.01745 
	
	
  
    local pRotX, pRotY, pRotZ = getElementRotation(localPlayer) 
    pRotZ = math.rad(pRotZ) 
     
    if rotX > 3.14 then 
        rotX = rotX - 6.28 
    elseif rotX < -3.14 then 
        rotX = rotX + 6.28 
    end 
	
     
    if rotY > 3.14 then 
        rotY = rotY - 6.28 
    elseif rotY < -3.14 then 
        rotY = rotY + 6.28 
    end 
     
    if isPedInVehicle(localPlayer) then 
        if rotY < -3.14 / 4 then 
            rotY = -3.14 / 4 
        elseif rotY > -3.14/15 then 
            rotY = -3.14/15 
        end 
    else 
        if rotY < -3.14 / 4 then 
            rotY = -3.14 / 4 
        elseif rotY > 3.14 / 2.1 then 
            rotY = 3.14 / 2.1 
        end 
    end 
end 

]]--