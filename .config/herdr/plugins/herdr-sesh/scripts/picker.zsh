#!/usr/bin/env zsh
# Overlay pane: fzf over open workspaces, saved sessions and zoxide dirs,
# then focus the match or create a workspace for it. Esc closes the overlay
# and herdr restores the previous pane.
source "${0:A:h}/lib.zsh"
need jq fzf

# Colors (Catppuccin-ish ANSI) and Nerd Font icons.
e=$'\e'
c_reset="${e}[0m" c_dim="${e}[2m" c_herdr="${e}[1;35m" c_zox="${e}[1;32m" c_ses="${e}[1;33m"
c_ok="${e}[32m" c_work="${e}[33m" c_block="${e}[31m" c_tree="${e}[90m"
i_ws='󰆍' i_tree='↳' i_dir='' i_ses=''

home_short() { print -r -- "${1/#$HOME/~}"; }
# Pad/truncate to a fixed display width.
fit() { local s="$1" w="$2"; (( ${#s} > w )) && s="${s[1,w-1]}…"; print -rn -- "${(r:$w:)s}"; }

status_icon() {
  case "$1" in
    idle|done) print -rn -- "${c_ok}✓${c_reset}" ;;
    working)   print -rn -- "${c_work}●${c_reset}" ;;
    blocked)   print -rn -- "${c_block}!${c_reset}" ;;
    *)         print -rn -- ' ' ;;
  esac
}

typeset -A ws_by_label ws_label ws_cwd
typeset -a lines ws_rows seen_dirs
current=''

while IFS=$'\t' read -r id label focused cwd agent linked repo; do
  [[ -n "$id" ]] || continue
  ws_by_label[$label]="$id"; ws_label[$id]="$label"; ws_cwd[$id]="$cwd"
  [[ "$focused" == true ]] && current="$id"
  [[ -n "$cwd" ]] && seen_dirs+=("${cwd:A}")
  ws_rows+=("$id"$'\t'"$label"$'\t'"$cwd"$'\t'"$agent"$'\t'"$linked"$'\t'"$repo")
done < <(list_workspaces)

# Group linked worktrees right after their parent repo workspace.
typeset -a grouped
typeset -A placed
for row in "${ws_rows[@]}"; do
  f=("${(@ps:\t:)row}")
  [[ "${f[5]}" == true ]] && continue
  grouped+=("$row"); placed[${f[1]}]=1
  [[ -n "${f[6]}" ]] || continue
  for r2 in "${ws_rows[@]}"; do
    g=("${(@ps:\t:)r2}")
    [[ "${g[5]}" == true && "${g[6]}" == "${f[6]}" && -z "${placed[${g[1]}]+x}" ]] || continue
    grouped+=("$r2"); placed[${g[1]}]=1
  done
done
for row in "${ws_rows[@]}"; do
  f=("${(@ps:\t:)row}")
  [[ -n "${placed[${f[1]}]+x}" ]] || grouped+=("$row")
done
ws_rows=("${grouped[@]}")

hist="$(history_file)"
prev=''
if [[ -r "$hist" ]]; then
  while read -r h; do
    [[ -n "$h" && "$h" != "$current" && -n "${ws_cwd[$h]+x}" ]] && { prev="$h"; break; }
  done < "$hist"
fi

# Rows are grouped: parent repo, then its linked worktrees.
n=${#ws_rows}
for (( k = 1; k <= n; k++ )); do
  IFS=$'\t' read -r id label cwd agent linked _repo <<< "${ws_rows[k]}"
  if [[ "$linked" == true ]]; then
    next_linked=false
    (( k < n )) && [[ "${${(@ps:\t:)ws_rows[k+1]}[5]}" == true ]] && next_linked=true
    branch=$([[ $next_linked == true ]] && print '├─' || print '└─')
    icon="$i_tree" name="${c_tree}${branch}${c_reset} $(fit "$label" 26)"
  else
    icon="$i_ws" name="$(fit "$label" 29)"
  fi
  [[ "$id" == "$current" ]] && name="${e}[1m${name}${c_reset}"
  lines+=("ws"$'\t'"$id"$'\t'"$cwd"$'\t'"$(status_icon "$agent") ${c_herdr}${icon} herdr ${c_reset}  ${name}  ${c_dim}$(home_short "$cwd")${c_reset}")
done

# Saved sessions: "name | path | startup command"
sessions_file="$(config_dir)/sessions"
if [[ -r "$sessions_file" ]]; then
  while IFS= read -r raw; do
    [[ "$raw" =~ '^[[:space:]]*(#|$)' ]] && continue
    parts=("${(@s:|:)raw}")
    name="${${parts[1]## #}%% #}"
    spath="$(expand_path "${${parts[2]:-}## #}")"; spath="${spath%% #}"
    [[ -n "$name" ]] || continue
    [[ -n "${ws_by_label[$name]+x}" ]] && continue
    lines+=("session"$'\t'"$name"$'\t'"$spath"$'\t'"  ${c_ses}${i_ses} sesh  ${c_reset}  $(fit "$name" 29)  ${c_dim}$(home_short "$spath")${c_reset}")
  done < "$sessions_file"
fi

# zoxide dirs not already open.
if (( $+commands[zoxide] )); then
  while IFS= read -r dir; do
    [[ -n "$dir" && -d "$dir" ]] || continue
    (( ${seen_dirs[(Ie)${dir:A}]} )) && continue
    lines+=("dir"$'\t'"$dir"$'\t'"$dir"$'\t'"  ${c_zox}${i_dir} zoxide${c_reset}  $(fit "${dir:t}" 29)  ${c_dim}$(home_short "$dir")${c_reset}")
  done < <(zoxide query -l 2>/dev/null)
fi

(( ${#lines} )) || { print 'nothing to pick'; sleep 1; exit 0; }

if (( $+commands[eza] )); then
  preview='eza -la --color=always --icons --group-directories-first --no-user --time-style=relative {3} 2>/dev/null'
else
  preview='ls -la {3} 2>/dev/null'
fi

footer="enter select · ctrl+j/k move · ctrl+/ preview · esc back"
[[ -n "$prev" ]] && footer+="   ${c_herdr}last:${c_reset} ${ws_label[$prev]}"

choice="$(print -rl -- "${lines[@]}" | fzf \
  --delimiter=$'\t' --with-nth=4 --ansi --no-sort --layout=reverse \
  --border=rounded --border-label=" ${c_herdr}Sesh Picker${c_reset} " --border-label-pos=3 \
  --header="${c_herdr}herdr / sesh${c_reset}   ${c_dim}${#ws_rows} workspaces${c_reset}" --header-border=bottom \
  --footer="$footer" --footer-border=top \
  --prompt="Sesh> " --pointer='▌' --marker='+' --gutter=' ' \
  --info=inline-right --ghost='Filter workspaces' \
  --list-label=" ${c_herdr}WORKSPACES${c_reset} " \
  --color='prompt:magenta:bold,pointer:magenta,hl:yellow,hl+:yellow:bold,label:magenta,border:bright-black' \
  --bind='ctrl-j:down,ctrl-k:up,ctrl-/:toggle-preview' \
  --preview="$preview" --preview-label=' PREVIEW ' --preview-window='right,40%,border-left')" || exit 0
[[ -n "$choice" ]] || exit 0

kind="${choice%%$'\t'*}"; rest="${choice#*$'\t'}"
key="${rest%%$'\t'*}"; rest="${rest#*$'\t'}"
target="${rest%%$'\t'*}"

create_ws() {
  local dir="$1" label="$2" startup="${3:-}" out ws_id pane_id
  [[ -d "$dir" ]] || { toast "no such directory: $dir"; exit 1; }
  out="$("$herdr_bin" workspace create --cwd "$dir" --label "$label" 2>&1)" || { toast "create failed: $out"; exit 1; }
  ws_id="$(jq -r '.result.workspace.workspace_id // empty' <<< "$out")"
  pane_id="$(jq -r '.result.root_pane.pane_id // empty' <<< "$out")"
  [[ -n "$startup" && -n "$pane_id" ]] && "$herdr_bin" pane run "$pane_id" "$startup" >/dev/null
  [[ -n "$ws_id" ]] && focus_workspace "$ws_id"
}

case "$kind" in
  ws) focus_workspace "$key" ;;
  dir) create_ws "$target" "${target:t}" ;;
  session)
    while IFS= read -r raw; do
      parts=("${(@s:|:)raw}")
      [[ "${${parts[1]## #}%% #}" == "$key" ]] || continue
      startup="${(j:|:)parts[3,-1]}"
      startup="${${startup## #}%% #}"
      create_ws "$target" "$key" "$startup"
      break
    done < "$sessions_file"
    ;;
esac
