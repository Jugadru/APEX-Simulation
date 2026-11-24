extends RefCounted
## Confirm physical passes after clearance; ranking itself stays instantaneous.
## Pending pairs are stored only in revision 030 cars, thus checkpoints carry
## their state. No new RNG, no rank/progress/pace mutation.
const LENGTH := 6.4
const WIDTH := 2.95
const CONFIRM_SECONDS := 1.0
static func active(c:Dictionary)->bool:
 return not bool(c.get("finished",false)) and float(c.get("pit_left",0.0))<=0.0
static func observe(old_order:Array,now:Array,length:float,dt:float)->Dictionary:
 var old:Dictionary={};var live:Dictionary={};var counts:Dictionary={}
 for c in old_order:old[c.id]=c
 for c in now:live[c.id]=c
 for a in now:
  var pending:Dictionary=(a.get("pass_confirmation_pairs",{}) as Dictionary).duplicate()
  if not active(a) or not old.has(a.id) or not active(old[a.id]):
   if a.has("pass_confirmation_pairs"):a.erase("pass_confirmation_pairs")
   continue
  var before:Dictionary=old[a.id]
  for b in now:
   if b.id==a.id:continue
   if not active(b) or not old.has(b.id) or not active(old[b.id]):
    pending.erase(b.id);continue
   var prev:float=(float(before.progress)-float(old[b.id].progress))*length
   var gap:float=(float(a.progress)-float(b.progress))*length
   if gap<=0.0:
    pending.erase(b.id);continue
   if prev<=0.0 and absf(prev)<=LENGTH*2.0 and absf(float(a.race_lane)-float(b.race_lane))>=WIDTH-0.01:
    pending[b.id]=0.0
   if pending.has(b.id):
    if gap>=LENGTH:
     pending[b.id]=float(pending[b.id])+dt
     if float(pending[b.id])>=CONFIRM_SECONDS-0.000001:
      counts[a.id]=int(counts.get(a.id,0))+1
      pending.erase(b.id)
    else:pending[b.id]=0.0
  if pending.is_empty():a.erase("pass_confirmation_pairs")
  else:a["pass_confirmation_pairs"]=pending
 return counts
