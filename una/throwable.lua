local Card = require("una.card")
local Throwable = {}
local throwableRender = models:newPart("una.throwableRender", "World")

local projectiles = {}
---@param card Card
---@param vel Vector3?
---@param rvel Vector3?
function Throwable.new(card,vel,rvel)
   vel = vel or vec(math.random() * 0.4 - 0.2, math.random() * 0.5 + 0.2, math.random() * 0.4 - 0.2)
   rvel = rvel or vec(math.random()-0.5,math.random()-0.5,math.random()-0.5)*45
   card.PRESSED:clear()
   card.CARD_HOVER:clear()
   card:setOwner("") -- disable clicking
   local pos = card.pos + Card.ROOT_MODEL:getPos() / 16
   local mat = matrices.rotation4(card.rot)
   table.insert(projectiles,{
      card = card,
      pos = pos,
      lpos = pos:copy(),
      vel = vel,
      rvel = rvel,
      mat = mat,
      lmat = mat:copy(),
      lifetime = math.random(100, 160),
      scale = card.scale,
   })
end

local Physics = {
   margin = 0.01,
   force_solid = {
      "minecraft:soul_sand",
      "minecraft:mud",
      "minecraft:chest",
      "minecraft:ender_chest",
      "minecraft:powder_snow",
      "minecraft:honey_block",
   },
   gravity = vectors.vec3(0,-0.02,0),
   friction = 0.7,
}

local function collision(pos,vel,axis)
   local block, brpos = world.getBlockState(pos), pos % 1
   local bpos = pos - brpos
   local collided = false
   local force_solid = false
   for _, namespace in pairs(Physics.force_solid) do
      if namespace == block.id then
         force_solid = true
      end
   end
   local coll = {}
   if force_solid then
      coll = {{vectors.vec3(0,0,0),vectors.vec3(1,1,1)}}
   else
      coll = block:getCollisionShape()
   end
   for key, AABB in pairs(coll) do
      if AABB[1].x <= brpos.x and AABB[1].y <= brpos.y and AABB[1].z <= brpos.z
      and AABB[2].x >= brpos.x and AABB[2].y >= brpos.y and AABB[2].z >= brpos.z then
         collided = true
         if axis == 1 then
            if math.sign(vel) < 0 then
               brpos.x = AABB[2].x + Physics.margin else brpos.x = AABB[1].x - Physics.margin
            end
         elseif axis == 2 then
            if math.sign(vel) < 0 then
               brpos.y = AABB[2].y + Physics.margin else brpos.y = AABB[1].y - Physics.margin
            end
         elseif axis == 3 then
            if math.sign(vel) < 0 then
               brpos.z = AABB[2].z + Physics.margin else brpos.z = AABB[1].z - Physics.margin
            end
         end
      end
   end
   if collided then
      return bpos[axis]+brpos[axis]
   end
end


events.TICK:register(function ()
   for i, p in pairs(projectiles) do
      p.lpos = p.pos:copy()
      do
         p.pos.y = p.pos.y + p.vel.y
         p.vel.y = p.vel.y + Physics.gravity.y
         local result = collision(p.pos,p.vel.y,2)
         if result then
            p.pos.y = result
            p.vel:mul(Physics.friction,0,Physics.friction)
            p.rvel = vectors.vec3(0,p.rvel.y*0.7,0)
            local rot = math.pi*0.5-math.atan2(p.mat.c3.z,p.mat.c3.x)
            p.mat = matrices.mat4():rotateY(math.deg(rot))
         end
      end
      do
         p.pos.x = p.pos.x + p.vel.x
         p.vel.x = p.vel.x + Physics.gravity.x
         local result = collision(p.pos,p.vel.x,1)
         if result then
            p.pos.x = result
            p.vel:mul(0,Physics.friction,Physics.friction)
         end
      end
      do
         p.pos.z = p.pos.z + p.vel.z
         p.vel.z = p.vel.z + Physics.gravity.z
         local result = collision(p.pos,p.vel.z,3)
         if result then
            p.pos.z = result
            p.vel:mul(Physics.friction,Physics.friction,0)
         end
      end
      local locvel = (p.vel:augmented() * p.mat).xyz
      p.vel = p.vel - p.mat.c2.xyz * locvel.y * 0.2
      p.lmat = p.mat:copy()
      p.mat:rotate(p.rvel)

      p.lifetime = p.lifetime - 1
      if p.lifetime <= 0 then
         projectiles[i] = nil
         p.card:free()
      end
   end
end)

throwableRender.midRender = function(delta)
   local rootOffset = Card.ROOT_MODEL:getPos() / 16
   for _, p in pairs(projectiles) do
      local offset = math.lerp(p.lpos,p.pos,delta) - rootOffset
      p.mat:translate(offset)
      p.lmat:translate(offset)
      p.card.matrix = math.lerp(p.lmat, p.mat, delta)
      p.card:matrixUnfold()
      local scale = 1 - math.min((p.lifetime - delta) / 10, 1)
      scale = 1 - scale ^ 3
      p.card:setScale(scale * p.scale)
      p.mat:translate(-offset)
      p.lmat:translate(-offset)
   end
end

return Throwable