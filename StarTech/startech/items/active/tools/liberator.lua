function init()
  if storage.consumed then
    item.consume(1)
    return
  end
  storage.consumed = false

  message.setHandler("startech:consumeLiberator", function()
    storage.consumed = true
    item.consume(1)
  end)
end

function activate(fireMode, shiftHeld)
  world.spawnStagehand(entity.position(), "startech:liberator", { owner = entity.id() })
end

function uninit()
  if storage.consumed and item.count() > 0 then
    item.consume(1)
  end
end
