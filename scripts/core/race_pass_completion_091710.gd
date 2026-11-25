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
 var old:Dictionary={};var counts:Dictionary={}
 for c in old_order:old[c.id]=c
 # Cache frozen scalar inputs once, in the original grid order. Only
 # pass_confirmation_pairs is mutated during this observation.
 var size:int=now.size()
 var ids:Array=[]
 var eligible:=PackedByteArray()
 var previous:=PackedFloat64Array()
 var current:=PackedFloat64Array()
 var lanes:=PackedFloat64Array()
 eligible.resize(size);previous.resize(size);current.resize(size);lanes.resize(size)
 for i in range(size):
  var c:Dictionary=now[i]
  var id=c.id
  ids.append(id)
  if not active(c) or not old.has(id) or not active(old[id]):continue
  eligible[i]=1
  previous[i]=float(old[id].progress)
  current[i]=float(c.progress)
  lanes[i]=float(c.race_lane)
 for i in range(size):
  var a:Dictionary=now[i]
  var aid=ids[i]
  if eligible[i]==0:
   if a.has("pass_confirmation_pairs"):a.erase("pass_confirmation_pairs")
   continue
  var pending:Dictionary=(a.get("pass_confirmation_pairs",{}) as Dictionary).duplicate()
  var before:float=previous[i]
  var progress:float=current[i]
  var lane:float=lanes[i]
  for j in range(size):
   var bid=ids[j]
   if bid==aid:continue
   if eligible[j]==0:
    pending.erase(bid);continue
   var prev:float=(before-previous[j])*length
   var can_start:bool=prev<=0.0 and absf(prev)<=LENGTH*2.0
   var has_pending:bool=pending.has(bid)
   # A pair outside the original crossing window cannot create a
   # confirmation. Existing pending pairs still follow every old rule.
   if not has_pending and not can_start:continue
   var gap:float=(progress-current[j])*length
   if gap<=0.0:
    pending.erase(bid);continue
   if can_start and absf(lane-lanes[j])>=WIDTH-0.01:
    pending[bid]=0.0
    has_pending=true
   if has_pending:
    if gap>=LENGTH:
     pending[bid]=float(pending[bid])+dt
     if float(pending[bid])>=CONFIRM_SECONDS-0.000001:
      counts[aid]=int(counts.get(aid,0))+1
      pending.erase(bid)
    else:pending[bid]=0.0
  if pending.is_empty():a.erase("pass_confirmation_pairs")
  else:a["pass_confirmation_pairs"]=pending
 return counts
