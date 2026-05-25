local wezterm = require("wezterm")
local is_windows = wezterm.target_triple:find("windows") ~= nil
local path_separator = package.config:sub(1, 1)
local user_config_dir = wezterm.home_dir .. path_separator .. ".config" .. path_separator .. "wezterm"
local theme_dir = is_windows and user_config_dir or (wezterm.config_dir or user_config_dir)
local themes = dofile(theme_dir .. path_separator .. "themes.lua")
local config = wezterm.config_builder()

-- ============================================
-- Color Scheme Definitions
-- WezTerm builtin theme を土台にしつつ、必要な差分だけ上書きする
-- 既定は Ubuntu。必要なら WEZTERM_COLOR_SCHEME で切り替え可能
-- ============================================
local builtin_schemes = wezterm.get_builtin_color_schemes()
local scheme_names = themes.scheme_names
local scheme_palette_overrides = themes.scheme_palette_overrides
local fallback_scheme_palettes = themes.fallback_scheme_palettes
local default_scheme_name = themes.default_scheme_name
local persisted_scheme_path = wezterm.home_dir .. "/.wezterm-color-scheme"

local function read_persisted_scheme()
	local file = io.open(persisted_scheme_path, "r")
	if not file then
		return nil
	end

	local scheme_name = file:read("*l")
	file:close()
	return scheme_name
end

local function persist_scheme(scheme_name)
	local file, err = io.open(persisted_scheme_path, "w")
	if not file then
		wezterm.log_error("failed to persist color scheme: " .. tostring(err))
		return
	end

	file:write(scheme_name, "\n")
	file:close()
end

local function merge_tables(base, overrides)
	local merged = {}
	for key, value in pairs(base) do
		merged[key] = value
	end
	if overrides then
		for key, value in pairs(overrides) do
			merged[key] = value
		end
	end
	return merged
end

local function first_non_nil(...)
	local values = { ... }
	for _, value in ipairs(values) do
		if value ~= nil then
			return value
		end
	end
	return nil
end

local function builtin_scheme_to_palette(scheme)
	local ansi = scheme.ansi or {}
	local brights = scheme.brights or {}
	return {
		background = scheme.background,
		foreground = scheme.foreground,
		cursorColor = first_non_nil(scheme.cursor_bg, scheme.cursor_border, scheme.cursor_fg, scheme.foreground),
		selectionBackground = first_non_nil(scheme.selection_bg, scheme.background),
		black = ansi[1],
		red = ansi[2],
		green = ansi[3],
		yellow = ansi[4],
		blue = ansi[5],
		purple = ansi[6],
		cyan = ansi[7],
		white = first_non_nil(ansi[8], scheme.foreground),
		brightBlack = first_non_nil(brights[1], ansi[1]),
		brightRed = first_non_nil(brights[2], ansi[2]),
		brightGreen = first_non_nil(brights[3], ansi[3]),
		brightYellow = first_non_nil(brights[4], ansi[4]),
		brightBlue = first_non_nil(brights[5], ansi[5]),
		brightPurple = first_non_nil(brights[6], ansi[6]),
		brightCyan = first_non_nil(brights[7], ansi[7]),
		brightWhite = first_non_nil(brights[8], ansi[8], scheme.foreground),
	}
end

local function resolve_scheme_palette(name)
	local builtin_scheme = builtin_schemes[name]
	if builtin_scheme then
		return merge_tables(builtin_scheme_to_palette(builtin_scheme), scheme_palette_overrides[name])
	end

	local fallback_palette = fallback_scheme_palettes[name]
	if fallback_palette then
		wezterm.log_info("using fallback color scheme: " .. name)
		return merge_tables(fallback_palette, scheme_palette_overrides[name])
	end

	wezterm.log_warn("color scheme not found in builtin or fallback palettes: " .. name)
	return nil
end

local function load_scheme_palettes(names)
	local palettes = {}
	for _, name in ipairs(names) do
		local palette = resolve_scheme_palette(name)
		if palette then
			palettes[name] = palette
		end
	end
	return palettes
end

local scheme_palettes = load_scheme_palettes(scheme_names)

local active_scheme_name = os.getenv("WEZTERM_COLOR_SCHEME") or read_persisted_scheme() or default_scheme_name
if not scheme_palettes[active_scheme_name] then
	active_scheme_name = default_scheme_name
end
local active_scheme = scheme_palettes[active_scheme_name]

local function hex_to_rgba(hex, alpha)
	local r = tonumber(hex:sub(2, 3), 16)
	local g = tonumber(hex:sub(4, 5), 16)
	local b = tonumber(hex:sub(6, 7), 16)
	return string.format("rgba(%d, %d, %d, %.2f)", r, g, b, alpha)
end

local function palette_to_wezterm_scheme(scheme)
	return {
		background = scheme.background,
		foreground = scheme.foreground,
		cursor_bg = scheme.cursorColor,
		cursor_fg = scheme.background,
		cursor_border = scheme.cursorColor,
		selection_bg = scheme.selectionBackground,
		selection_fg = scheme.white,
		ansi = {
			scheme.black,
			scheme.red,
			scheme.green,
			scheme.yellow,
			scheme.blue,
			scheme.purple,
			scheme.cyan,
			scheme.white,
		},
		brights = {
			scheme.brightBlack,
			scheme.brightRed,
			scheme.brightGreen,
			scheme.brightYellow,
			scheme.brightBlue,
			scheme.brightPurple,
			scheme.brightCyan,
			scheme.brightWhite,
		},
	}
end

local function build_wezterm_schemes(schemes)
	local wezterm_schemes = {}
	for name, scheme in pairs(schemes) do
		wezterm_schemes[name] = palette_to_wezterm_scheme(scheme)
	end
	return wezterm_schemes
end

local function build_theme_overrides(scheme)
	return {
		tab_bar = {
			background = hex_to_rgba(scheme.background, 0.90),
			active_tab = {
				bg_color = scheme.purple,
				fg_color = scheme.white,
				intensity = "Bold",
			},
			inactive_tab = {
				bg_color = scheme.brightBlack,
				fg_color = scheme.foreground,
			},
			inactive_tab_hover = {
				bg_color = scheme.brightBlue,
				fg_color = scheme.white,
			},
			new_tab = {
				bg_color = scheme.background,
				fg_color = scheme.blue,
			},
			new_tab_hover = {
				bg_color = scheme.blue,
				fg_color = scheme.background,
			},
		},
		-- ホローカーソルに近い見た目を維持しつつ、色だけテーマに追従させる
		cursor_bg = hex_to_rgba(scheme.cursorColor, 0.00),
		cursor_fg = scheme.foreground,
		cursor_border = scheme.cursorColor,
		selection_bg = hex_to_rgba(scheme.selectionBackground, 0.55),
		selection_fg = "none",
	}
end

local function build_window_frame(scheme)
	return {
		font = wezterm.font({ family = "CaskaydiaMono Nerd Font", weight = "Bold" }),
		font_size = 12.0,
		active_titlebar_bg = scheme.background,
		inactive_titlebar_bg = scheme.brightBlack,
	}
end

local function apply_color_scheme(window, scheme_name)
	local scheme = scheme_palettes[scheme_name]
	if not scheme then
		return
	end

	persist_scheme(scheme_name)
	window:set_config_overrides({
		color_scheme = scheme_name,
		colors = build_theme_overrides(scheme),
		window_frame = build_window_frame(scheme),
	})
end

local function get_effective_scheme_name(window)
	local overrides = window:get_config_overrides() or {}
	return overrides.color_scheme or active_scheme_name
end

local function show_color_scheme_selector(window, pane)
	local current_scheme_name = get_effective_scheme_name(window)
	local choices = {}
	for _, name in ipairs(scheme_names) do
		if scheme_palettes[name] then
			table.insert(choices, {
				id = name,
				label = (name == current_scheme_name) and ("* " .. name) or ("  " .. name),
			})
		end
	end
	table.sort(choices, function(a, b)
		return a.label < b.label
	end)

	window:perform_action(
		wezterm.action.InputSelector({
			action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
				local selected = id or label
				if selected then
					apply_color_scheme(inner_window, selected)
				end
			end),
			title = "Select WezTerm Color Scheme",
			description = "Windows Terminal 由来のテーマから選択",
			fuzzy = true,
			choices = choices,
		}),
		pane
	)
end

local function basename(value)
	return (value or ""):gsub("(.*[/\\])(.*)", "%2")
end

local function tab_title(tab_info)
	local title = tab_info.tab_title
	if title and #title > 0 then
		return title
	end
	return tab_info.active_pane and tab_info.active_pane.title or "shell"
end

local function tab_has_unseen_output(tab_info)
	for _, pane in ipairs(tab_info.panes or {}) do
		if pane.has_unseen_output then
			return true
		end
	end
	return false
end

local function tab_icon(tab_info)
	local pane = tab_info.active_pane or {}
	local process_name = basename(pane.foreground_process_name):lower()
	local title = tab_title(tab_info):lower()
	local domain_name = pane.domain_name or ""

	-- 1. プロセス名やタイトルからアイコンを決定（優先）
	if process_name:find("vim") or title:find("vim") or process_name:find("nvim") or title:find("nvim") then
		return wezterm.nerdfonts.custom_vim or ""
	end
	if process_name:find("git") or title:find("git") then
		return wezterm.nerdfonts.dev_git or ""
	end
	if process_name:find("docker") or title:find("docker") then
		return wezterm.nerdfonts.md_docker or "󰡨"
	end
	if process_name:find("node") or title:find("node") or process_name:find("npm") or title:find("npm") then
		return wezterm.nerdfonts.md_language_typescript or "󰛦"
	end
	if process_name:find("python") or title:find("python") then
		return wezterm.nerdfonts.dev_python or ""
	end
	if process_name:find("ssh") or title:find("ssh") then
		return wezterm.nerdfonts.md_server_network or "󰒋"
	end
	if process_name:find("nu") or title:find("nu") then
		return wezterm.nerdfonts.cod_terminal or ""
	end
	if process_name:find("zsh") or process_name:find("bash") or title:find("zsh") or title:find("bash") then
		return wezterm.nerdfonts.dev_terminal or ""
	end

	-- 2. ドメイン名によるフォールバック（WSLなどはここ）
	if domain_name:find("WSL") then
		return wezterm.nerdfonts.cod_terminal_linux or ""
	end
	return wezterm.nerdfonts.md_console or "󰞷"
end

local function format_tab_title(tab, hover, max_width)
	local title = tab_title(tab)
	local icon = tab_icon(tab)
	local background = active_scheme.brightBlack
	local foreground = active_scheme.foreground

	if tab.is_active then
		background = active_scheme.purple
		foreground = active_scheme.white
	elseif tab_has_unseen_output(tab) then
		background = active_scheme.yellow
		foreground = active_scheme.black
	elseif hover then
		background = active_scheme.blue
		foreground = active_scheme.background
	elseif tab.is_last_active then
		background = active_scheme.green
		foreground = active_scheme.white
	end

	local content_width = math.max(1, max_width - 5)
	title = wezterm.truncate_right(title, content_width)

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
		{ Text = " " .. icon .. " " .. title .. " " },
	}
end

-- 直前コマンドの Output をコピーモードで選択（範囲を見てから Ctrl+Shift+C 等でコピー）
-- 一発クリップボードは使わない。シェル連携（OSC 133）必須。
-- https://wezterm.org/shell-integration.html
-- ActivateCopyMode の直後に同一 Multiple 内で CopyMode だけを送るとオーバーレイ未初期化で効かないことがあるため、
-- call_after で1ティック遅らせる。CopyMode 子は既定キー表と同じ { CopyMode = ... } 形で渡す。
wezterm.on("select-last-output-in-copy-mode", function(window, pane)
	window:perform_action(wezterm.action.ActivateCopyMode, pane)
	wezterm.time.call_after(0.02, function()
		local p = window:active_pane()
		if not p then
			return
		end
		window:perform_action(
			wezterm.action.Multiple({
				{ CopyMode = "MoveToScrollbackBottom" },
				{ CopyMode = { MoveBackwardZoneOfType = "Output" } },
				{ CopyMode = { SetSelectionMode = "SemanticZone" } },
			}),
			p
		)
	end)
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	return format_tab_title(tab, hover, max_width)
end)

wezterm.on("select-color-scheme", function(window, pane)
	show_color_scheme_selector(window, pane)
end)

wezterm.on("augment-command-palette", function(window, pane)
	return {
		{
			brief = "Select color scheme",
			icon = "md_palette",
			action = wezterm.action_callback(function()
				show_color_scheme_selector(window, pane)
			end),
		},
		{
			brief = "Select last command output in copy mode (needs shell integration)",
			icon = "md_select_all",
			action = wezterm.action.EmitEvent("select-last-output-in-copy-mode"),
		},
	}
end)

-- ============================================
-- Domain Settings
-- ============================================
if is_windows then
	config.default_domain = "WSL:Ubuntu-24.04"
end

-- ============================================
-- Appearance - Window
-- ============================================
-- ウィンドウの透過度（0.0 〜 1.0、小さいほど透明）
config.window_background_opacity = 0.85

if is_windows then
	-- Windows向けのぼかし効果（"Acrylic"=強, "Mica"=弱, "Disable"=なし）
	config.win32_system_backdrop = "Disable"
end

-- 注: config.background を設定すると window_background_opacity が無効になるため、
-- グラデーションや backdrop は使用せず、シンプルな透過のみを使用

config.color_schemes = build_wezterm_schemes(scheme_palettes)
config.color_scheme = active_scheme_name

-- カーソルのカスタマイズ（透明な四角形 = ホローカーソル）
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.force_reverse_video_cursor = false

-- ============================================
-- Font Settings
-- （Windows Terminal: dot_win/windows_terminal.settings.json.tmpl の WSL 系と同じ
--  face / size=13。WT に cell 拡縮指定が無いので line_height・cell_width は 1.0 基準）
-- ============================================
config.font = wezterm.font_with_fallback({
	{
		family = "CaskaydiaMono Nerd Font",
		-- Nerd Fonts の CaskaydiaMono は Regular/Bold/Italic 等のみで Medium フェイスが無いことが多い
		weight = "Regular",
		harfbuzz_features = { "calt=1", "clig=1", "liga=1" }, -- リガチャ有効
	},
	{ family = "Noto Sans Mono CJK JP" }, -- 日本語フォールバック
	{ family = "Symbols Nerd Font Mono" }, -- アイコン用（不足グリフの補完）
})
config.font_size = 13.0
config.line_height = 1.0
config.cell_width = 1.0

-- ============================================
-- Tab Bar
-- ============================================
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false -- タブバーを常に表示（ドラッグで移動するため）
config.tab_bar_at_bottom = false
config.tab_max_width = 32

config.colors = build_theme_overrides(active_scheme)

-- ============================================
-- Window Frame & Padding
-- ============================================
config.window_frame = {
	font = wezterm.font({ family = "CaskaydiaMono Nerd Font", weight = "Bold" }),
	font_size = 12.0, -- 本文 13 に対し従来 10/11 の比率を維持
	active_titlebar_bg = active_scheme.background,
	inactive_titlebar_bg = active_scheme.brightBlack,
}

config.window_padding = {
	left = 15,
	right = 15,
	top = 10,
	bottom = 10,
}

-- ウィンドウ装飾（ミニマル：タブバーにボタン統合、タブバーをドラッグで移動可能）
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"

-- ============================================
-- Performance & Usability
-- ============================================
-- スムーズなスクロール
config.enable_scroll_bar = true
config.scrollback_lines = 10000

-- Shiftキーを押しながらスクロールでtmuxのマウス報告をバイパス
-- （tmux使用中もWeztermのスクロールバックを使用可能）
config.bypass_mouse_reporting_modifiers = "SHIFT"

-- アニメーション
config.animation_fps = 60
config.max_fps = 120

-- ベル音を無効化（視覚的なベルのみ）
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	target = "CursorColor",
}

-- ============================================
-- Key Bindings (便利なショートカット)
-- ============================================
config.keys = {
	-- Shift+Enter で改行入力（Cursor CLI / Claude Code 用）
	{ key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
	-- Ctrl+Shift+C/V でコピー/ペースト
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
	-- Ctrl+Shift+T で新しいタブ
	{ key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	-- Ctrl+Shift+W でタブを閉じる
	{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	-- Ctrl+Shift+S でテーマセレクタを開く
	{ key = "s", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent("select-color-scheme") },
	-- Ctrl+Shift+O: コピーモードで直前 Output を選択（確認してから Ctrl+Shift+C 等でコピー）
	{ key = "o", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent("select-last-output-in-copy-mode") },
	-- Alt+左右 でタブ移動
	{ key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
	-- Ctrl+Shift+| で垂直分割
	{ key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- Ctrl+Shift+_ で水平分割
	{ key = "_", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- フォントサイズ調整
	{ key = "+", mods = "CTRL|SHIFT", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
}

-- ============================================
-- Mouse Bindings
-- ============================================
config.mouse_bindings = {
	-- 右クリックでペースト
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
	-- Ctrl+クリックでURLを開く
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
	-- tmux等でマウススクロールを有効化（代替スクリーンモード対応）
	-- alt_screen = false: 代替スクリーンモードでない時のみ適用
	{
		event = { Down = { streak = 1, button = { WheelUp = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByCurrentEventWheelDelta,
		alt_screen = false,
	},
	{
		event = { Down = { streak = 1, button = { WheelDown = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByCurrentEventWheelDelta,
		alt_screen = false,
	},
}

-- ============================================
-- Initial Window Size
-- ============================================
config.initial_cols = 140
config.initial_rows = 25

return config
