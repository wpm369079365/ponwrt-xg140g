#!/bin/bash
TOKEN=$(cat ~/.workbuddy_ghtoken)
RUN=44687839442
REPO=wpm369079365/ponwrt-xg140g
for i in $(seq 1 120); do
  J=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$REPO/actions/runs/$RUN/jobs")
  CONC=$(echo "$J" | python3 -c "import json,sys; d=json.load(sys.stdin); print((d.get('jobs') or [{}])[0].get('conclusion') or '')" 2>/dev/null)
  STEP=$(echo "$J" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for j in d.get('jobs',[]):
    c=[s['name'] for s in j['steps'] if s['status']=='in_progress']
    print(c[0] if c else '-')
" 2>/dev/null)
  if [ -n "$CONC" ]; then
    echo "=== DONE: $CONC (after ~$((i)) min) ==="
    curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$REPO/actions/runs/$RUN/jobs" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for j in d.get('jobs',[]):
    for s in j.get('steps',[]):
        if s.get('conclusion') not in ('success','skipped',None): print('FAILED STEP:', s['name'], '->', s['conclusion'])
"
    echo "=== releases ==="
    curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$REPO/releases?per_page=3" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for r in d: print(r['tag_name'], '|', [a['name'] for a in r.get('assets',[])])
"
    exit 0
  fi
  echo "[$i] step: $STEP"
  sleep 60
done
echo "TIMEOUT still running"
