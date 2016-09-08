require "/lib/stardust/itemutil.lua"

tooltip = {}
do
  local clr = {}
  clr.weaponType = "^#7f7fff;"
  clr.label = "^white;"
  clr.ability = clr.weaponType
  
  local function buildAbility(item, conf, abl, label)
    if not abl then return "" end
    local dps = abl.baseDps or 0
    local ftime = abl.fireTime or 1
    local spd = 1.0 / ftime
    return table.concat({ "\n", 
      clr.label, label, ": ", clr.ability, abl.name or "ERR", "\n",
      string.format("%.1f", dps), "dps ",
      string.format("(%.1f/hit x %.1f/s)", dps * ftime, spd)
    })
  end
  
  function tooltip.weaponInfo(item, conf)
    if not conf then conf = root.itemConfig(item) end
    return table.concat({
      --"\n\n",
      clr.weaponType, conf.config.shortdescription, " ", "^#7fff7f;", "(lv.", string.format("%d)\n", conf.parameters.level or 1),
      buildAbility(item, conf, conf.config.primaryAbility, "Primary"),
      buildAbility(item, conf, conf.config.altAbility, "Secondary"), "\na1\na2\na3\na4\na5\na6\na7\na8\na9\na10"
    })
  end
end

-- TODO
-- add proper color to ability details, fix leveled dps, omit dps if 0
-- EXPAND TERMINAL TOOLTIP AREA (skips from a1 at bottom to a6 at top from a single scroll click!?) (21px/2)/line
-- hmm. maybe just have it extendable
