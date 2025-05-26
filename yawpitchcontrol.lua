-- === Create Big Cannons Trajectory Tool ===

local shellVelocities = {
  standard_shell = 40,
  explosive_shell = 38,
  shrapnel_shell = 35,
  smoke_shell = 30,
  fluid_shell = 25,
  drop_mortar_shell = 20
}

-- Helper functions
local function degToRad(deg)
  return deg * math.pi / 180
end

local function radToDeg(rad)
  return rad * 180 / math.pi
end

local function getVelocity(shellType, charges)
  local base = shellVelocities[shellType]
  if not base then error("Unknown shell type: " .. shellType) end
  return base * charges
end

-- Calculate the true muzzle position by applying barrel offset
local function applyBarrelOffset(x0, y0, z0, pitch, yaw, length)
  local pitchRad = degToRad(pitch)
  local yawRad = degToRad(yaw)
  local dx = math.cos(pitchRad) * math.sin(yawRad)
  local dy = math.sin(pitchRad)
  local dz = math.cos(pitchRad) * math.cos(yawRad)
  local x = x0 + dx * length
  local y = y0 + dy * length
  local z = z0 + dz * length
  return x, y, z
end

-- Predict impact based on pitch/yaw
local function predictImpact(x0, y0, z0, pitch, yaw, velocity, barrelLength)
  local muzzleX, muzzleY, muzzleZ = applyBarrelOffset(x0, y0, z0, pitch, yaw, barrelLength)
  local g = -0.05
  local pitchRad = degToRad(pitch)
  local yawRad = degToRad(yaw)
  local vx = velocity * math.cos(pitchRad) * math.sin(yawRad)
  local vy = velocity * math.sin(pitchRad)
  local vz = velocity * math.cos(pitchRad) * math.cos(yawRad)

  local a = 0.5 * g
  local b = vy
  local c = muzzleY

  local discriminant = b^2 - 4 * a * c
  if discriminant < 0 then return nil end

  local sqrtDisc = math.sqrt(discriminant)
  local t = (-b - sqrtDisc) / (2 * a)
  if t < 0 then t = (-b + sqrtDisc) / (2 * a) end

  local x = muzzleX + vx * t
  local z = muzzleZ + vz * t
  return math.floor(x + 0.5), 0, math.floor(z + 0.5)
end

-- Calculate aiming angles from cannon to target
local function getAimAngles(x0, y0, z0, xt, yt, zt, velocity, barrelLength)
  local dx = xt - x0
  local dy = yt - y0
  local dz = zt - z0

  local horizontalDistance = math.sqrt(dx^2 + dz^2)
  local yaw = radToDeg(math.atan2(dx, dz))

  -- Adjust starting position based on yaw and pitch guess (horizontal only)
  local yawRad = degToRad(yaw)
  local muzzleX = x0 + math.sin(yawRad) * barrelLength
  local muzzleZ = z0 + math.cos(yawRad) * barrelLength
  local muzzleY = y0

  local dX = xt - muzzleX
  local dZ = zt - muzzleZ
  local dY = yt - muzzleY
  local dH = math.sqrt(dX^2 + dZ^2)

  local v = velocity
  local g = 0.05

  local part = v^4 - g * (g * dH^2 + 2 * dY * v^2)
  if part < 0 then return yaw, nil, nil end

  local sqrtPart = math.sqrt(part)
  local angle1 = math.atan((v^2 + sqrtPart) / (g * dH))
  local angle2 = math.atan((v^2 - sqrtPart) / (g * dH))

  return yaw, radToDeg(angle2), radToDeg(angle1)
end

-- Prompt helper
local function prompt(msg)
  print(msg)
  return read()
end

-- Main logic
local function main()
  print("=== Create Big Cannons Trajectory Tool ===")
  print("1 = Predict Impact from Pitch/Yaw")
  print("2 = Calculate Pitch/Yaw to Target")
  local mode = prompt("Choose mode (1 or 2):")

  if mode == "1" then
    local x0 = tonumber(prompt("Cannon base X:"))
    local y0 = tonumber(prompt("Cannon base Y:"))
    local z0 = tonumber(prompt("Cannon base Z:"))
    local pitch = tonumber(prompt("Pitch angle (°):"))
    local yaw = tonumber(prompt("Yaw angle (°):"))
    local barrelLength = tonumber(prompt("Barrel length (blocks):"))
    local shell = prompt("Shell type:")
    local charges = tonumber(prompt("Powder charges:"))
    local velocity = getVelocity(shell, charges)
    local x, y, z = predictImpact(x0, y0, z0, pitch, yaw, velocity, barrelLength)
    if x then
      print(string.format("Predicted impact at: X=%.0f, Z=%.0f", x, z))
    else
      print("No impact: shell will not hit ground.")
    end
  elseif mode == "2" then
    local x0 = tonumber(prompt("Cannon base X:"))
    local y0 = tonumber(prompt("Cannon base Y:"))
    local z0 = tonumber(prompt("Cannon base Z:"))
    local xt = tonumber(prompt("Target X:"))
    local yt = tonumber(prompt("Target Y:"))
    local zt = tonumber(prompt("Target Z:"))
    local barrelLength = tonumber(prompt("Barrel length (blocks):"))
    local shell = prompt("Shell type:")
    local charges = tonumber(prompt("Powder charges:"))
    local velocity = getVelocity(shell, charges)
    local yaw, pitch1, pitch2 = getAimAngles(x0, y0, z0, xt, yt, zt, velocity, barrelLength)
    print(string.format("Yaw: %.2f°", yaw))
    if pitch1 then
      print(string.format("Low pitch: %.2f°, High pitch: %.2f°", pitch1, pitch2))
    else
      print("Target is out of range.")
    end
  else
    print("Invalid mode.")
  end
end

main()
