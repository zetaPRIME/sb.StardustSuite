-- upgraded version of chain.lua from vanilla

require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  
  local pRot = animationConfig.animationParameter("playerRotation") or 0
  self.chains = animationConfig.animationParameter("chains") or {}
  for _, chain in pairs(self.chains) do
    local continue = false
    if chain.targetEntityId then
      if world.entityExists(chain.targetEntityId) then
        chain.endPosition = world.entityPosition(chain.targetEntityId)
      end
    end
    if chain.sourcePart then
      local beamSource = animationConfig.partPoint(chain.sourcePart, "beamSource")
      if beamSource then
        chain.startPosition = vec2.add(entity.position(), beamSource)
      else
        continue = true
      end
    end
    if chain.endPart then
      local beamEnd = animationConfig.partPoint(chain.endPart, "beamEnd")
      if beamEnd then
        chain.endPosition = vec2.add(entity.position(), beamEnd)
      else
        continue = true
      end
    end
    
    if not continue and (not chain.targetEntityId or world.entityExists(chain.targetEntityId)) then
      -- sb.logInfo("Building drawables for chain %s", chain)
      local startPosition = chain.startPosition or vec2.add(activeItemAnimation.ownerPosition(), vec2.rotate(activeItemAnimation.handPosition(chain.startOffset), pRot))
      local endPosition = chain.endPosition or vec2.add(activeItemAnimation.ownerPosition(), activeItemAnimation.handPosition(chain.endOffset))
      
      if chain.maxLength then
        endPosition = vec2.add(startPosition, vec2.mul(vec2.norm(world.distance(endPosition, startPosition)), chain.maxLength))
      end
      
      if chain.testCollision then
        local angle = vec2.angle(world.distance(endPosition, startPosition))
         -- lines starting on tile boundaries will collide with the tile
         -- work around this by starting the collision check a small distance along the line from the actual start position
        local collisionStart = vec2.add(startPosition, vec2.withAngle(angle, 0.01))
        local collision = world.lineTileCollisionPoint(startPosition, endPosition)
        if collision then
          local collidePosition, normal = collision[1], collision[2]
          if chain.bounces and chain.bounces > 0 then
            local length = world.magnitude(endPosition, startPosition) - world.magnitude(collidePosition, startPosition)
            local newChain = copy(chain)
            newChain.sourcePart, newChain.endPart, newChain.targetEntityId = nil, nil, nil
            newChain.startPosition = collidePosition
            newChain.endPosition = vec2.add(collidePosition, vec2.mul(vec2.withAngle(angle, length), normal[1] == 0 and {1, -1} or {-1, 1}))
            newChain.bounces = chain.bounces - 1
            table.insert(self.chains, newChain)
          end
          
          endPosition = collidePosition
        end
      end
      
      local chainVec = world.distance(endPosition, startPosition)
      local chainDirection = chainVec[1] < 0 and -1 or 1
      local chainLength = vec2.mag(chainVec)
      
      local arcAngle = 0
      if chain.arcRadius then
        arcAngle = chainDirection * 2 * math.asin(chainLength / (2 * chain.arcRadius))
        chainLength = chainDirection * arcAngle * chain.arcRadius
      end

      local segmentCount = math.floor(((chainLength + (chain.overdrawLength or 0)) / chain.segmentSize) + 0.5)
      if segmentCount > 0 then
        local chainStartAngle = vec2.angle(chainVec) - arcAngle / 2
        if chainVec[1] < 0 then chainStartAngle = math.pi - chainStartAngle end
        
        local segmentOffset = vec2.mul(vec2.norm(chainVec), chain.segmentSize)
        segmentOffset = vec2.rotate(segmentOffset, -arcAngle / 2)
        local currentBaseOffset = vec2.add(startPosition, vec2.mul(segmentOffset, 0.5))
        local lastDrawnSegment = chain.drawPercentage and math.ceil(segmentCount * chain.drawPercentage) or segmentCount
        for i = 1, lastDrawnSegment do
          local baseOffset = {0, 0}
          local image = chain.segmentImage
          if i == 1 and chain.startSegmentImage then
            image = chain.startSegmentImage
            if chain.startSegmentOffset then
              baseOffset = vec2.add(baseOffset, chain.startSegmentOffset)
            end
          elseif i == lastDrawnSegment and chain.endSegmentImage then
            image = chain.endSegmentImage
          end
          
          local scale = chain.baseScale or {1.0, 1.0}
          if type(scale) ~= "table" then scale = {scale, scale} end
          -- taper applies evenly from full size at the start to (1.0 - chain.taper) size at the end
          if chain.taper then
            local taperFactor = 1 - ((i - 1) / lastDrawnSegment) * chain.taper
            --image = image .. "?scale=1.0=" .. util.round(taperFactor, 1)
            scale[2] = scale[2] * taperFactor
          end
          
          local scaleFactor = 8.0
          --image = image .. "?scalebicubic=" .. (scale[1] * scaleFactor) .. "=" .. (scale[2] * scaleFactor)
          image = string.format("%s?scalebilinear=%f2=%f2", image, scale[1] * scaleFactor, scale[2] * scaleFactor)
          
          -- per-segment offsets (jitter, waveform, etc)
          local thisOffset = {0, 0}
          if chain.jitter then
            thisOffset = vec2.add(thisOffset, {0, (math.random() - 0.5) * chain.jitter})
          end
          if chain.waveform then
            local angle = ((i * chain.segmentSize) - (os.clock() * (chain.waveform.movement or 0))) / (chain.waveform.frequency / math.pi)
            local sineVal = math.sin(angle) * chain.waveform.amplitude * 0.5
            thisOffset = vec2.add(thisOffset, {0, sineVal})
          end
          
          
          local segmentAngle = chainStartAngle + (i - 1) * chainDirection * (arcAngle / segmentCount)
          thisOffset = vec2.rotate(thisOffset, chainVec[1] >= 0 and segmentAngle or -segmentAngle)
          
          if chainVec[1] < 0 then baseOffset[1] = baseOffset[1] * -1.0 end
          thisOffset = vec2.add(thisOffset, vec2.rotate(baseOffset, chainVec[1] >= 0 and segmentAngle or -segmentAngle))
          
          local drawable = {
            image = image,
            centered = true,
            mirrored = chainVec[1] < 0,
            rotation = segmentAngle,
            position = vec2.add(currentBaseOffset, thisOffset),
            scale = 1.0/scaleFactor,
            fullbright = chain.fullbright or false
          }
          
          localAnimator.addDrawable(drawable, chain.renderLayer)
          
          if chain.segmentLight then
            local color = chain.segmentLight.color or chain.segmentLight
            color = {color[1] * 255, color[2] * 255, color[3] * 255}
            local light = {
              position = drawable.position,
              color = color,
              --pointLight = true
              -- todo: the rest of the light params
            }
            localAnimator.addLightSource(light)
          end
          
          segmentOffset = vec2.rotate(segmentOffset, arcAngle / segmentCount)
          currentBaseOffset = vec2.add(currentBaseOffset, segmentOffset)
        end
      end
    end
  end
end
