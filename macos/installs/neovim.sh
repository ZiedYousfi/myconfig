# neovim
if [[ -x "$(command -v nvim)" ]]; then
  echo "nvim est déjà là, prêt à éditer ~✨"
else
  echo "nvim manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install neovim
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer nvim automatiquement…"
  fi
fi

rm -rf "$XDG_CONFIG_HOME/nvim"
git clone https://github.com/LazyVim/starter $XDG_CONFIG_HOME/nvim
rm -rf "$XDG_CONFIG_HOME/nvim/.git"

touch "$XDG_CONFIG_HOME/nvim/lua/plugins/avante.lua"
cat >"$XDG_CONFIG_HOME/nvim/lua/plugins/avante.lua" <<EOF
return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    opts = {
      provider = "copilot",
      providers = {
        copilot = {
          model = "gpt-5-mini",
          -- optionally:
          -- temperature = 0.2,
          -- max_tokens = 2048,
          -- system_prompt = "..."
        },
        -- you can add others later, e.g.:
        -- openai = { model = "gpt-4o-mini" },
      },
    },
    build = "make BUILD_FROM_SOURCE=true",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-mini/mini.pick",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua", -- needed for providers='copilot'
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
EOF

touch "$XDG_CONFIG_HOME/nvim/lua/plugins/auto-save.lua"
cat >"$XDG_CONFIG_HOME/nvim/lua/plugins/auto-save.lua" <<EOF
return {
  "Pocco81/auto-save.nvim",
  lazy = false,
  opts = {
    debounce_delay = 500,
    execution_message = {
      message = function()
        return ""
      end,
    },
  },
  keys = {
    { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
  },
}
EOF

touch "$XDG_CONFIG_HOME/nvim/lua/plugins/colorscheme.lua"
cat >"$XDG_CONFIG_HOME/nvim/lua/plugins/colorscheme.lua" <<EOF
return {
  { "thesimonho/kanagawa-paper.nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
    },
  },
}
EOF
