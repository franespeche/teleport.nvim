# 🌌 Teleport.nvim
_Easily jump to any character_ 

![teleport_demo](https://github.com/user-attachments/assets/6294df45-c2b3-4490-8884-f1ac8c9abeb8)


# TL;DR:
By pressing `t` + `character`, all the matching characters from the cursor's position till the last visible line will be highlighted with a `teleport character`, meaning that pressing this new character will jump to that position.

Same applies for `T` (backwards).

# Example
Lets say your cursor is here `_`, and you press `tc` to highlight all the `c` characters starting from this line. 
You could then easily jump to any highlighted character by pressing the highlighted key.
Same thing could be accomplished backwards by pressing `T{char}`.
(pressing `qq` will turn the highlights off)

# Usage:
1. In this v0, you'll just need to install the plugin and then call the setup function. Currently the keymaps are set to `t`, `T` and `qq` by default

```lua
require("teleport"):setup()

-- Keymaps --
vim.keymap.set("n", "t", ":Teleport forwards<cr>", { noremap = true })
vim.keymap.set("n", "T", ":Teleport backwards<cr>", { noremap = true })
vim.keymap.set("n", "qq", ":TeleportExit<cr>", { noremap = true })
```

---

# Whats next:
- Support custom mappings
- Change highlights colors dynamically
- Currently there are 55 possible highlights, meaning that jumping to a character that appears more than 55 times will not be possible unless you come closer to it.
  Will work on this to support infinite highlights
- If there's only one occurence, we could jump straight to it
