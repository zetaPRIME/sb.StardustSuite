-- Equipment tech stub
require("/lib/stardust/playerext.lua")

function init()
    init = function() end
    if config.getParameter("active") then
        local ovr = playerext.getTechOverride()
        if not ovr then return nil end -- abort activation if no override
        uninit = nil
        require(ovr)
        local _uninit = uninit or function() end
        uninit = function()
            _uninit()
            -- reassert until released
            if playerext.getTechOverride() then playerext.overrideTech() end
        end
        init()
    end
end

function uninit()
    -- reassert until released
    if playerext.getTechOverride() then playerext.overrideTech() end
end
