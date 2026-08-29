-- Keybind registry: records every keybind as it is registered, keyed by its
-- chord, so personal overrides can fetch the keybind object Omarchy created
-- for a chord and toggle it (keybind:set_enabled) rather than unbinding it and
-- restating its action. Must be required before default.hypr.omarchy.
--
-- Look up with hl.find_keybind("SUPER + W").

local function normalize(keys)
  local tokens = {}
  for token in keys:upper():gmatch("[^%s+]+") do
    table.insert(tokens, token)
  end
  table.sort(tokens)
  return table.concat(tokens, "+")
end

-- Reset on every config load so the registry never holds keybinds from a
-- previous generation of the config.
hl.keybind_registry = {}

if not hl.keybind_registry_installed then
  hl.keybind_registry_installed = true

  local bind, unbind = hl.bind, hl.unbind

  hl.bind = function(keys, dispatcher, opts)
    local keybind = bind(keys, dispatcher, opts)
    hl.keybind_registry[normalize(keys)] = keybind
    return keybind
  end

  hl.unbind = function(keys, ...)
    hl.keybind_registry[normalize(keys)] = nil
    return unbind(keys, ...)
  end

  hl.find_keybind = function(keys)
    return hl.keybind_registry[normalize(keys)]
  end
end
