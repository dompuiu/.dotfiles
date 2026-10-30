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
  run({ "notification", "show", "nvim: " .. msg, "--position", "top-right" })
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

-- tuios runs herdr plugins through a herdr-compatible CLI of its own. It
-- ignores --direction on `plugin pane open`, and on `pane split` as soon as
-- --cwd or --env is passed. So split the rightmost pane plain, label it like
-- herdr does, then cd and exec nvim in its shell.
local function in_tuios()
  return os.getenv("TUIOS_PLUGIN_ID") or os.getenv("TUIOS_SOCKET") or herdr:find("tuios", 1, true)
end

local function rightmost(pane_id)
  local layout = decode(run({ "pane", "layout", "--pane", pane_id }).stdout)
  local best, best_edge, best_h
  for _, p in ipairs(layout and layout.result and layout.result.layout and layout.result.layout.panes or {}) do
    if p.rect then
      local edge, h = p.rect.x + p.rect.width, p.rect.height
      if not best or edge > best_edge or (edge == best_edge and h > best_h) then
        best, best_edge, best_h = p.pane_id, edge, h
      end
    end
  end
  return best
end

local function quote(s)
  if vim.fn.has("win32") == 1 then return "'" .. s:gsub("'", "''") .. "'" end
  return vim.fn.shellescape(s)
end

if in_tuios() and focused then
  local target = rightmost(focused.pane_id) or focused.pane_id
  local split = decode(run({ "pane", "split", "--pane", target, "--direction", "right", "--focus" }).stdout)
  local id = split and split.result and split.result.pane and split.result.pane.pane_id
  if id then
    run({ "pane", "rename", id, "nvim" })
    local cmd = vim.fn.has("win32") == 1
        and ("Set-Location -LiteralPath " .. quote(cwd) .. "; nvim; exit")
        or ("builtin cd -- " .. quote(cwd) .. " && exec nvim")
    os.exit(run({ "pane", "run", id, cmd }).code)
  end
end

local open = run({
  "plugin", "pane", "open",
  "--plugin", "nvim", "--entrypoint", "nvim",
  "--placement", "split", "--direction", "right", "--focus",
  "--cwd", cwd,
})
if open.code ~= 0 then
  notify("failed to open pane: " .. vim.trim(open.stderr or ""))
end
os.exit(open.code)
