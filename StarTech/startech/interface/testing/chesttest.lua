items = {}
function init()
    --world.sendEntityMessage(pane.containerEntityId(), "onOpen")
    --sb.logInfo(dump(widget.getData("itemGrid")))
    
    --local items = {}
    for i = 1, 64 do
        local itm = "scrollArea.itemList." .. widget.addListItem("scrollArea.itemList")
        items[i] = itm
        local x = (i % 8)
        local y = (i - x) / 8
        --widget.setPosition(itm .. "." .. "itemName", {x*16, y*16})
        widget.setText(itm .. "." .. "itemName", "" .. i)
        sb.logInfo(itm)
    end
    sb.logInfo(dump(widget.getData("scrollArea.itemList")))
    sb.logInfo(dump(console))
end

function update()
    for i = 1, #items do
        local btn = items[i] .. ".btn"
        if widget.getChecked(btn) then
            widget.setChecked(btn, false)
            world.sendEntityMessage(pane.containerEntityId(), "onOpen", "onion #" .. i)
        end
    end
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function onGridDerp(...)
    for k,v in pairs({...}) do
        sb.logInfo("key: " .. k)
        sb.logInfo("val: " .. v)
    end
    --sb.logInfo("test: " .. dump(widget.itemGridItems("itemGrid")))
    
    return 1
    --return widget.itemGridItems("itemGrid")
    --return true--false--true
end

function onGridDerpRight()
    return false
end

function ccall(...)
    sb.logInfo("is it here?")
end
