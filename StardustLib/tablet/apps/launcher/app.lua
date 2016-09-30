

do
  _ENV = __app -- (REQUIRED) take on the environment given (can't sandbox from outside)
  import "ui"
  
  local app = {}
  
  function uiUpdate()
    gfx.drawRect({14, 97, 32, 32}, {math.ceil(255 * status.resourcePercentage("energy")), 0, 0})
    gfx.drawRect({2, 2, 32, 32}, {255, 0, 255})
    
    local pxt = ""
    for k,v in pairs(input.keyState()) do
      pxt = pxt .. k .. " "
    end
    gfx.drawText("scancodes: " .. (pxt or ""), {0, 0})
    --gfx.drawText("abcdefghijklmnopqrstuvwxyz\nABCDEFTHIJKLMNOPQRSTUVWXYZ\n|| | " .. input.mousePos()[1], {0, 8})
    --gfx.drawText("All your base are belong to StarTech.", {0, 16})
    --gfx.drawText("You have no chance to banana, I am a", {0, 24})
    --gfx.drawText("deciduous molten crabcake from Morp.", {0, 32})
    
    --gfx.drawText("All your base are belong to StarTech. This is\na pickled banana, testing for newlines\nlike it were none o' ya bizness.", {80, 16}, nil, {centered=true})
    --testificate()
    --gfx.drawText(dump(__modlayer), {0, 64}, nil)
    banana()
    testificate()
    
    --gfx.drawText("cumberbund", {0, 0})
    --gfx.drawText("blemble", {0, 7})
    --gfx.drawText("apricot", {0, 14})
  end
  
  function banana()
    gfx.drawText("All your base are belong to StarTech. This is\na pickled banana, testing for newlines\nlike it were none o' ya bizness.\n\nHalter tops and singalongs are the very\nbeing of important sausage. If\nthere were none other, then there'd\nindubitably be a mayonnaise.", {80, 16}, nil, {centered=true})
  end
  
  --__app = app
end
