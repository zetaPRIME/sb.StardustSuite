-- active skills module for Aetheri skill tree

local slotNum = {
  skillSlot1 = 1,
  skillSlot2 = 2,
  skillSlot3 = 3,
  skillSlot4 = 4,
}

local essSlots = { "beamaxe", "wiretool", "painttool", "inspectiontool" }

skillDrawer = { }

function refreshSkillSlots()
  for slot, num in pairs(slotNum) do
    widget.setItemSlotItem(slot, playerext.getEquip(essSlots[num]))
  end
end

function commitSkillSlots()
  -- save into property immediately
  local pd = status.statusProperty("aetheri:skillTreeData", { })
  pd.selectedSkills = playerData.selectedSkills
  status.setStatusProperty("aetheri:skillTreeData", pd)
  for slot, num in pairs(slotNum) do
    local skill = playerData.selectedSkills[num]
    playerext.setEquip(essSlots[num], { name = "aetheri:skill." .. skill, count = 1 })
  end
  refreshSkillSlots()
end

function skillDrawer.setSkill(slotNum, skill)
  playerData.selectedSkills[slotNum] = skill
  commitSkillSlots()
  skillDrawer.close()
  pane.playSound(sounds.selectSkill)
end

local skillList = "skillDrawer.s.l"

local skillDrawerOpen = false
local skillSlotSelected = -1
function skillDrawer.open(slot)
  widget.clearListItems(skillList)
  skillSlotSelected = slotNum[slot]
  for _, skill in pairs(activeSkills) do
    if true or committedSkillsUnlocked[skill] then
      local sn = slotNum[slot]
      widget.registerMemberCallback(skillList, "slotClick", function() drawer.setSkill(sn, skill) end)
      local s = skillList .. "." .. widget.addListItem(skillList) .. ".s"
      widget.setItemSlotItem(s, { name = "aetheri:skill." .. skill, count = 1})
    end
  end
  widget.setPosition("skillHighlight", vec2.sub(widget.getPosition(slot), {1, 1}))
  widget.setPosition("skillDrawer", {480 - 90/2, 540 - 180})
  skillDrawerOpen = true
end

function skillDrawer.close()
  widget.setPosition("skillHighlight", {99999, 99999})
  widget.setPosition("skillDrawer", {99999, 99999})
  --widget.clearListItems(skillList)
  skillDrawerOpen = false
  skillSlotSelected = -1
end

function onSkillSlotClick(slot)
  local sn = slotNum[slot]
  if sn == skillSlotSelected then
    skillDrawer.close()
    pane.playSound(sounds.closeSkillDrawer)
  else
    skillDrawer.open(slot)
    pane.playSound(sounds.openSkillDrawer)
  end
end

function onSkillSlotRClick(slot)
  --closeSkillDrawer()
end
