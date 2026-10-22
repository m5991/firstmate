#!/bin/bash
W=$1
eval "$(sed -n '/^shell_quote()/,/^}/p;/^effort_flag_for_harness()/,/^}/p' "$W/bin/fm-spawn.sh")"
P=$(mktemp -d)
cd "$P"
for m in "" gemini-3.8-flash gemini-3.8-flash-low gemini-3.8-flash-medium gemini-3.8-flash-high claude-sonnet-4-6 claude-opus-4-6-thinking gpt-oss-120b-medium; do
 for e in low medium high xhigh max; do
  flag=$(effort_flag_for_harness agy "$e" "$m")
  margs=(); [ -n "$m" ] && margs=(--model "$m")
  out=$(timeout 90 agy -p "Reply PONG" "${margs[@]}" --effort "$e" --output-format json </dev/null 2>&1)
  if printf '%s' "$out" | grep -q '"status": *"ERROR"\|conflicts with\|not supported\|has no "' ; then real=REJECT; else real=ACCEPT; fi
  why=$(printf '%s' "$out" | grep -o 'conflicts with[^"]*\|--effort is not supported[^"]*\|has no "[^)]*)' | head -1)
  [ -n "$flag" ] && fm=EMIT || fm=OMIT
  ok=MATCH; { [ $fm = EMIT ] && [ $real = REJECT ]; } && ok=BUG_EMITS_REJECTED; { [ $fm = OMIT ] && [ $real = ACCEPT ]; } && ok=conservative_omit
  printf '%-26s %-7s fm-spawn=%-5s agy=%-7s %-18s %s\n' "${m:-<default>}" "$e" "$fm" "$real" "$ok" "$why"
 done
done
rm -rf "$P"
