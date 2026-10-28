-- Open nvim in a right split at the focused pane's cwd, or focus the nvim
-- pane already in this tab. Never closes it: only :q does, so unsaved
-- buffers can't be lost from the keybinding.
local herdr = os.getenv("HERDR_BIN_PATH") or "herdr"

local function run(args)
  local ok, res = pcall(function()
    return vim.system(vim.list_extend({ herdr }, args), { text = true }):wait()
  end)
  if not ok then return { code = 1, stdout = "", stderr = tostring(res) } end
  return res
end

local function notify(msg)
  run({ "notification", "show", "herdr-nvim: " .. msg, "--position", "top-right" })
end

local function decode(s)
  if not s or s == "" then return nil end
  local ok, v = pcall(vim.json.decode, s, { luanil = { object = true, array = true } })
  return ok and v or nil
end

local function is_dir(p)
  return type(p) == "string" and p ~= "" and vim.fn.isdirectory(p) == 1
end

local panes = {}
local res = run({ "pane", "list" })
local list = res.code == 0 and decode(res.stdout)
if list and list.result and type(list.result.panes) == "table" then
  panes = list.result.panes
end

local focused
for _, p in ipairs(panes) do
  if p.focused then focused = p break end
end

if focused then
  for _, p in ipairs(panes) do
    if p.label == "nvim" and p.tab_id == focused.tab_id and p.pane_id then
      if p.pane_id == focused.pane_id then os.exit(0) end
      if run({ "plugin", "pane", "focus", p.pane_id }).code == 0 then os.exit(0) end
      run({ "pane", "zoom", p.pane_id, "--on" })
      os.exit(run({ "pane", "zoom", p.pane_id, "--off" }).code)
    end
  end
end

local cwd
local ctx = decode(os.getenv("HERDR_PLUGIN_CONTEXT_JSON"))
for _, c in ipairs({
  ctx and ctx.focused_pane_cwd,
  focused and focused.foreground_cwd,
  focused and focused.cwd,
  ctx and ctx.workspace_cwd,
  ctx and ctx.cwd,
}) do
  if is_dir(c) then cwd = c break end
end
cwd = cwd or vim.uv.os_homedir()

local open = run({
  "plugin", "pane", "open",
  "--plugin", "herdr-nvim", "--entrypoint", "nvim",
  "--placement", "split", "--direction", "right", "--focus",
  "--cwd", cwd,
})
if open.code ~= 0 then
  notify("failed to open pane: " .. vim.trim(open.stderr or ""))
end
os.exit(open.code)
