require "/lib/stardust/itemutil.lua"

tooltip = {}
do
  local clr = {}
  clr.weaponType = "^#bf7fff;"
  clr.label = "^white;"
  clr.ability = "^#7f7fff;"
  clr.dpsBase = "^#7f7f7f;"
  clr.dps = "^white;"
  clr.dpsDmg = "^#ff7f7f;"
  clr.dpsSpd = "^#7fff7f;"
  
  local function buildAbility(item, conf, abl, label)
    if not abl then return "" end
    local dps = (abl.baseDps or 0) * (conf.config.damageLevelMultiplier or 1)
    local ftime = abl.fireTime or 1
    local spd = 1.0 / ftime
    local ls = {table.concat({ "\n", 
      clr.label, label, ": ", clr.ability, abl.name or "(normal)"
    })}
    if dps > 0 then ls[#ls+1] = table.concat({ "\n",
      clr.dpsBase, " > ",
      clr.dps, string.format("%.1f", dps), clr.dpsBase, "dps (",
      clr.dpsDmg, string.format("%.1f", dps * ftime),
      clr.dpsBase, "/hit x ", clr.dpsSpd, string.format("%.1f", spd), clr.dpsBase, "/s)"
    }) end
    return table.concat(ls)
  end
  
  function tooltip.weaponInfo(item, conf, prefix)
    if not conf then conf = root.itemConfig(item) end
    return table.concat({
      prefix or "",
      clr.weaponType, conf.config.shortdescription or "Unknown Weapon Type", " ", "^#7fff7f;", "(lv.", string.format("%d)\n", conf.parameters.level or 1),
      buildAbility(item, conf, conf.config.primaryAbility, "Primary"),
      buildAbility(item, conf, conf.config.altAbility, "Secondary")--, "\na1\na2\na3\na4\na5\na6\na7\na8\na9\na10"
    })
  end
end

-- TODO
-- add proper color to ability details (DONE), fix leveled dps (DONE), omit dps if 0 (DONE)
-- DONE - EXPAND TERMINAL TOOLTIP AREA (skips from a1 at bottom to a6 at top from a single scroll click!?) (21px/2)/line
-- hmm. maybe just have it extendable (done)
-- fix the nameless abilities - probably patch broadswordcombo etc. to have names
