-- Open a program in a right split (or tab) at the focused pane's cwd. What
-- happens to a pane with the same label already in this tab depends on mode.
-- Usage: open.lua <entrypoint> <label> <focus|toggle|reopen|new> <split|tab> <cmd> [args...]
local herdr = os.getenv("HERDR_BIN_PATH") or "herdr"
local entrypoint, label, mode, placement = arg[1], arg[2], arg[3], arg[4]
local cmd = { unpack(arg, 5) }

local function run(args)
  local ok, res = pcall(function()
    return vim.system(vim.list_extend({ herdr }, args), { text = true }):wait()
  end)
  if not ok then return { code = 1, stdout = "", stderr = tostring(res) } end
  return res
end

local function notify(msg)
  run({ "notification", "show", label .. ": " .. msg, "--position", "top-right" })
end

if not (entrypoint and label and mode and placement and cmd[1]) then
  io.stderr:write("usage: open.lua <entrypoint> <label> <focus|toggle|reopen|new> <split|tab> <cmd> [args...]\n")
  os.exit(2)
end

-- A mise-managed program may be on this launcher's PATH (inherited from an
-- activated shell) but not on the PATH herdr spawns panes with (Windows), so
-- PATH can't be trusted for it: run it through the "-mise" pane variant.
-- Anything else (brew, winget, cargo, ...) is run directly.
local has_mise_variant = entrypoint == "tuicr" or entrypoint == "tuicr-worktree"
local in_mise = has_mise_variant and pcall(function()
  assert(vim.system({ "mise", "which", cmd[1] }, { text = true }):wait().code == 0)
end)
if in_mise then
  entrypoint = entrypoint .. "-mise"
  cmd = vim.list_extend({ "mise", "exec", "--" }, cmd)
elseif vim.fn.executable(cmd[1]) == 0 then
  notify(cmd[1] .. " not found on PATH or in mise")
  os.exit(1)
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

if focused and mode ~= "new" then
  for _, p in ipairs(panes) do
    if p.label == label and p.tab_id == focused.tab_id and p.pane_id then
      if mode == "reopen" then
        run({ "pane", "close", p.pane_id })
      elseif p.pane_id == focused.pane_id then
        if mode == "toggle" then os.exit(run({ "pane", "close", p.pane_id }).code) end
        os.exit(0)
      else
        if run({ "plugin", "pane", "focus", p.pane_id }).code == 0 then os.exit(0) end
        run({ "pane", "zoom", p.pane_id, "--on" })
        os.exit(run({ "pane", "zoom", p.pane_id, "--off" }).code)
      end
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
-- herdr does, then cd and exec the program in its shell.
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

local win = vim.fn.has("win32") == 1

local function quote(s)
  if win then return "'" .. s:gsub("'", "''") .. "'" end
  return vim.fn.shellescape(s)
end

if placement == "split" and in_tuios() and focused then
  local target = rightmost(focused.pane_id) or focused.pane_id
  local split = decode(run({ "pane", "split", "--pane", target, "--direction", "right", "--focus" }).stdout)
  local id = split and split.result and split.result.pane and split.result.pane.pane_id
  if id then
    run({ "pane", "rename", id, label })
    local line = table.concat(vim.tbl_map(quote, cmd), " ")
    local shell_cmd = win
        and ("Set-Location -LiteralPath " .. quote(cwd) .. "; & " .. line .. "; exit")
        or ("builtin cd -- " .. quote(cwd) .. " && exec " .. line)
    os.exit(run({ "pane", "run", id, shell_cmd }).code)
  end
end

local open_args = {
  "plugin", "pane", "open",
  "--plugin", "panes", "--entrypoint", entrypoint,
  "--placement", placement, "--focus",
  "--cwd", cwd,
}
if placement == "split" then vim.list_extend(open_args, { "--direction", "right" }) end

local open = run(open_args)
if open.code ~= 0 then
  notify("failed to open pane: " .. vim.trim(open.stderr or ""))
  os.exit(open.code)
end

-- --focus updates server focus but does not navigate attached clients.
-- Explicit `tab focus` does, so pull the new tab id from the open response.
if placement == "tab" then
  local r = decode(open.stdout)
  r = r and r.result or {}
  local p = r.plugin_pane or r
  local tab_id = (p.pane and p.pane.tab_id) or p.tab_id or (r.tab and r.tab.tab_id)
  if not tab_id then
    local pane_id = (p.pane and p.pane.pane_id) or p.pane_id
    local got = pane_id and decode(run({ "pane", "get", pane_id }).stdout)
    tab_id = got and got.result and got.result.pane and got.result.pane.tab_id
  end
  if tab_id then run({ "tab", "focus", tab_id }) end
end
os.exit(0)
