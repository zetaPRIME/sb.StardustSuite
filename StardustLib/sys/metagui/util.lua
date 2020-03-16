--

local mg = metagui

mg.keys = { -- dict of keycodes
  backspace = 0, del = 69,
  tab = 1, enter = 3,
  home = 92, ["end"] = 93, pgUp = 94, pgDn = 95,
  up = 87, down = 88, left = 90, right = 89,
}

local keychar = {
  [3] = {'\n', '\n'},
  [5] = {' ', ' '},
  [42] = {'`', '~'},
  [17] = {'-', '_'},
  [33] = {'=', '+'},
  [37] = {'[', '{'},
  [39] = {']', '}'},
  [38] = {'\\', '|'},
  [31] = {';', ':'},
  [11] = {'\'', '"'},
  [16] = {',', '<'},
  [18] = {'.', '>'},
  [19] = {'/', '?'},
}

local numKey = ")!@#$%^&*("

function mg.keyToChar(k, shift)
  if keychar[k] then return keychar[k][shift and 2 or 1]
  elseif k >= 20 and k <= 29 then -- numbers
    if not shift then return string.char(string.byte '0' + k - 20) end
    local i = k - 19
    return numKey:sub(i, i)
  elseif k >= 43 and k <= 68 then -- alphabet
    local ch = string.char(string.byte 'a' + k - 43)
    return shift and ch:upper() or ch
  end
end
