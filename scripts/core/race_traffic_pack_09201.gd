extends RefCounted
## 039. Frozen physical perception; no RNG, new lateral goal, forced pass or
## hidden rival tyre/setup knowledge. Seconds use observed lap-progress rate.
const Blue=preload("res://scripts/core/race_driver_traffic_0920.gd")
const Merge=preload("res://scripts/core/race_merge_traffic_0669174.gd")
const Thermal=preload("res://scripts/core/race_tyre_thermal.gd")
const ATTACK=["preparing","attacking","duel"]
const KEY="traffic_pack_09201"
const BODY=6.4

static func rate(car:Dictionary, fallback:float)->float:
 var measured:float=float(car.get(KEY,{}).get("rate",0.0))
 if measured>0.0001 and measured<0.1:return measured
 var lap:float=float(car.get("last_lap",0.0))
 return 1.0/lap if lap>20.0 and lap<500.0 else fallback

# Build once from the frozen field; 0 means no observed pace yet.
# The observer-specific fallback is still used exactly as before.
static func rate_frame(grid:Array)->Dictionary:
 var rates:Dictionary={}
 for car in grid:
  if not bool(car.get("finished",false)) and float(car.get("pit_left",0.0))<=0.0:rates[int(car.id)]=rate(car,0.0)
 return rates

static func frame_rate(car:Dictionary,fallback:float,rates:Dictionary)->float:
 var id:int=int(car.id)
 if not rates.has(id):return rate(car,fallback)
 var observed:float=float(rates[id])
 return observed if observed>0.0 else fallback

static func observe(car:Dictionary, grid:Array, metrics:Dictionary, length:float, weather:Dictionary, dt:float, rates:Dictionary={}, gap_output:Variant=null)->Dictionary:
 var own_id:int=int(car.id)
 var own_progress:float=float(car.progress)
 var own_lane:float=float(car.get("race_lane",0.0))
 var own_team:String=str(car.get("team",""))
 var own:Dictionary=metrics[own_id]
 var prior:Dictionary=car.get(KEY,{})
 var fallback:float=1.0/maxf(20.0,float(own.get("decision_pace",own.target)))
 var v:float=frame_rate(car,fallback,rates)
 var seconds_denominator:float=length*v
 var awareness:float=clampf(float(car.get("spatial_awareness",80.0))/100.0,0.0,1.0)
 var soul:Dictionary=car.get("driver_soul",{})
 var focus:float=clampf(float(soul.get("focus",.85)),0.0,1.0)
 var risk:float=clampf(float(car.get("risk_tolerance",55.0))/100.0,0.0,1.0)
 var confidence:float=clampf(float(soul.get("confidence",.55)),0.0,1.0)
 var mental_pressure:float=clampf(float(soul.get("pressure",.15)),0.0,1.0)
 var skill:float=clampf(float(car.get("skill",80.0))/100.0,0.0,1.0)
 var patience:float=clampf(.35*(1.0-risk)+.20*focus+.20*awareness+.15*confidence+.10*(1.0-mental_pressure),0.0,1.0)
 var horizon:float=2.5+1.5*awareness*focus+.8*skill
 var ahead:Array=[]
 var rear_s:float=999.0
 var rear_id:int=-1
 var rear_catch:float=-1.0
 var side:int=0
 var blue_behind:int=0
 var merge_ahead:int=0
 for other in grid:
  if int(other.id)==own_id or bool(other.get("finished",false)):continue
  if float(other.get("pit_left",0.0))>0.0:
   if float(other.pit_left)<=2.0 and other.has("pit_to"):
    var merge_gap:float=fposmod(float(other.pit_to)-own_progress,1.0)/v
    if merge_gap<1.5:merge_ahead+=1
   continue
  var g:float=Merge.relative_gap(own_progress,float(other.progress),length)
  # Optional tick-local sidecar: same exact signed gap, no sporting fields.
  if gap_output is Dictionary:gap_output[int(other.id)]=g
  var seconds:float=g/seconds_denominator
  if absf(g)<BODY+1.0 and absf(float(other.get("race_lane",0.0))-own_lane)>=2.94:side+=1
  if g<0.0:
   if -seconds<rear_s or (-seconds==rear_s and int(other.id)<rear_id):
    rear_s=-seconds;rear_id=int(other.id)
    var rear_closing:float=frame_rate(other,fallback,rates)-v
    rear_catch=-g/(length*rear_closing) if rear_closing>0.000001 else -1.0
   if -g<=38.0 and Blue.lapping(other,car,-g,length):blue_behind+=1
  elif g>0.000001 and seconds<=horizon:
   # Only sorting and group-chain fields are needed for every candidate.
   # The remaining perception belongs to the selected leader alone.
   ahead.append({"id":int(other.id),"gap":g,"gap_s":seconds,"drs":bool(other.get("drs_active",false)) or bool(other.get("drs_eligible",false)),"duel":str(other.get("combat_state","")) in ATTACK,"car":other})
 ahead.sort_custom(func(a,b):return int(a.id)<int(b.id) if float(a.gap)==float(b.gap) else float(a.gap)<float(b.gap))
 var first:Dictionary=ahead[0] if not ahead.is_empty() else {}
 if not first.is_empty():
  var leader_car:Dictionary=first.car
  var same_team:bool=str(leader_car.get("team",""))==own_team
  first["rate"]=frame_rate(leader_car,fallback,rates)
  first["stint_age"]=int(leader_car.get("stint_laps",-1))
  first["compound"]=str(leader_car.get("tire",""))
  first["mate"]=same_team and own_team!=""
  first["lapping"]=float(first.gap)<=38.0 and Blue.lapping(car,leader_car,float(first.gap),length)
  first["pit_approach"]=same_team and bool(leader_car.get("pit_request",false)) and fposmod(float(leader_car.progress),1.0)>.85
 var gap_s:float=float(first.get("gap_s",999.0))
 var leader:int=int(first.get("id",-1))
 var closing:float=v-float(first.get("rate",v))
 var catch_s:float=float(first.get("gap",0.0))/(length*closing) if leader>=0 and closing>0.000001 else -1.0
 var chain:int=1
 var drs_count:int=1 if bool(car.get("drs_active",false)) or bool(car.get("drs_eligible",false)) else 0
 var previous:float=0.0
 var duels:int=0
 for item in ahead:
  if float(item.gap_s)-previous>1.15:break
  previous=float(item.gap_s);chain+=1
  if bool(item.drs):drs_count+=1
  if bool(item.duel):duels+=1
 var wet:float=clampf(float(weather.get("wetness_factor",0.0)),0.0,1.0)
 var train:bool=chain>=3 and drs_count>=2 and wet<.20 and bool(weather.get("drs_allowed",true))
 var same:bool=leader>=0 and leader==int(prior.get("leader",-2))
 var congested:bool=chain>=3 and gap_s<1.3
 var congestion_s:float=float(prior.get("congestion_run_s",0.0))+dt if congested and same else (dt if congested else 0.0)
 var mode:String="FREE_AIR"
 if leader>=0:
  if gap_s<1.3:mode="TRAIN" if train else "FOLLOWING"
  elif gap_s<2.5:mode="ASSESSING"
  elif catch_s>=0.0 and catch_s<=10.0:mode="APPROACHING"
 if mode=="FREE_AIR" and str(prior.get("mode","FREE_AIR")) not in ["FREE_AIR","CLEAR","PIT"]:mode="CLEAR"
 var prepared:float=0.0
 if leader>=0 and float(first.gap)>38.0 and catch_s>=0.0 and catch_s<=10.0 and not bool(first.lapping):
  prepared=minf(3.0,float(prior.get("prepared_s",0.0))+dt) if same else dt
 var tyre_age:int=int(first.get("stint_age",-1))
 var own_age:int=int(car.get("stint_laps",-1))
 var tyre_hint:String="UNKNOWN"
 if tyre_age>=0 and own_age>=0:tyre_hint="FRESH" if tyre_age<=3 and own_age>5 else ("OLDER_STINT" if tyre_age>=own_age+7 else "SIMILAR")
 var high:float=float(Thermal.band(str(car.get("tire","Médio")))[1])
 var hot:bool=float(car.get("tyre_surface_c",high-10.0))>high
 return {"leader":leader,"gap_s":gap_s,"rear_s":rear_s,"rear_id":rear_id,"rear_catch_s":rear_catch,"side_count":side,"group_size":chain,"drs_train":train,"drs_count":drs_count,"front_duels":duels,"catch_s":catch_s,"closing":closing,"mode":mode,"prepared_s":prepared,"patience":patience,"pressure":clampf((1.5-rear_s)/1.5,0.0,1.0),"congestion_run_s":congestion_s,"hot":hot,"leader_tyre_age":tyre_age,"leader_compound":str(first.get("compound","")),"tyre_hint":tyre_hint,"leader_slower_observed":closing>0.00002,"blue_behind":blue_behind,"merge_ahead":merge_ahead,"mate":bool(first.get("mate",false)),"lapping_ahead":bool(first.get("lapping",false)),"pit_approach":bool(first.get("pit_approach",false))}

static func preparation_bonus(car:Dictionary,rival:int,advantage:float)->float:
 var prior:Dictionary=car.get(KEY,{})
 if int(prior.get("leader",-1))!=rival or advantage<=.10:return 0.0
 return clampf(float(prior.get("prepared_s",0.0))*.08,0.0,.24)

static func refine(car:Dictionary,rival:Dictionary,grid:Array,metrics:Dictionary,tactic:Dictionary,obs:Dictionary,gap:float,length:float)->Dictionary:
 if not bool(tactic.get("commit",false)) or gap<=11.5 or str(car.get("combat_state","")) in ATTACK:return tactic
 # Predict sweep only for a fresh move in an actual group. The previous
 # corner and coordination layers retain their vetoes and all safety rules.
 if int(obs.get("merge_ahead",0))>0 or bool(obs.get("pit_approach",false)):
  var wait:Dictionary=tactic.duplicate()
  wait.commit=false;wait.defense=false;wait.blocked=true;wait["pack_reason"]="pit_transition"
  return wait
 if int(obs.get("group_size",1))>=3 and not Blue.swept_clear(car,rival,grid,metrics,float(tactic.attack_goal),length):
  var result:Dictionary=tactic.duplicate()
  result.commit=false;result.defense=false;result.blocked=true;result["pack_reason"]="third_corridor"
  return result
 return tactic

static func blue(fast:Dictionary,slow:Dictionary,grid:Array,metrics:Dictionary,context:Dictionary)->Dictionary:
 var prior:Dictionary=slow.get(KEY,{})
 var previous:int=int(prior.get("yield_to",-1))
 if previous>=0 and previous!=int(fast.id) and float(prior.get("yield_grace",0.0))>0.0 and Blue.lapping(fast,slow,float(context.gap),float(context.length)):
  # Only transfer a real reservation while the prior leader is physically
  # just ahead or another lapping car is following in the same group.
  for item in grid:
   if int(item.id)!=previous or not Blue.active(item):continue
   var g:float=Merge.relative_gap(float(slow.progress),float(item.progress),float(context.length))
   if g<0.0 or g>60.0:break
   var shadow_car:Dictionary=slow.duplicate()
   var mem:Dictionary=slow.get("racecraft_memory",{}).duplicate()
   mem["traffic_yield_to"]=int(fast.id)
   mem["traffic_yield_goal"]=float(prior.get("yield_goal",slow.get("race_lane",0.0)))
   shadow_car["racecraft_memory"]=mem
   var result:Dictionary=Blue.evaluate(fast,shadow_car,grid,metrics,context)
   if bool(result.yield_early):result.reason="group_yield"
   return result
 return Blue.evaluate(fast,slow,grid,metrics,context)

static func group_hold(car:Dictionary,obs:Dictionary,intent:Dictionary,limit:float,narrow:bool)->bool:
 var prior:Dictionary=car.get(KEY,{})
 return int(obs.get("blue_behind",0))>0 and float(prior.get("yield_grace",0.0))>0.0 and int(intent.defending)<0 and str(intent.state) not in ATTACK and not narrow and absf(float(intent.lane))<=limit

static func policy(car:Dictionary,obs:Dictionary,intent:Dictionary,load:float,wet:float,narrow:bool)->Dictionary:
 var result:Dictionary={"mode":str(obs.mode),"lift":0.0,"save_kers":false,"reason":"observe"}
 if str(intent.state) in ATTACK:
  result.mode="COMMIT";return result
 if int(intent.defending)>=0 or narrow or wet>=.65 or float(obs.rear_s)<.75 or (float(obs.get("rear_catch_s",-1.0))>=0.0 and float(obs.get("rear_catch_s",-1.0))<1.0) or str(car.get("pace","Normal"))=="Atacar":return result
 var close:bool=float(obs.gap_s)<1.15
 var patient:bool=float(obs.patience)>=.60
 var prolonged:bool=float(obs.congestion_run_s)>=4.0
 var hot:bool=bool(obs.hot)
 var worn:bool=float(car.get("wear",0.0))>=60.0
 if close and load>=.28 and (hot or (prolonged and patient)):
  result.mode="CLEAN_AIR"
  result.lift=clampf((1.15-float(obs.gap_s))*.045,.006,.025)
  result.reason="longitudinal_gap"
 elif prolonged and patient and (bool(obs.drs_train) or hot or worn):
  result.mode="WAIT"
  result.lift=.008 if close and (hot or worn) else 0.0
  result.save_kers=true
  result.reason="conserve_in_group"
 elif float(obs.prepared_s)>0.0:
  result.mode="PREPARE";result.reason="older_stint_catch" if str(obs.get("tyre_hint",""))=="OLDER_STINT" else "anticipated_catch"
 elif int(obs.get("merge_ahead",0))>0 or bool(obs.get("pit_approach",false)):
  result.mode="ASSESSING";result.reason="pit_transition"
 elif int(obs.front_duels)>0 and close:
  result.mode="ASSESSING";result.reason="front_duel"
 return result

static func settle(car:Dictionary,obs:Dictionary,intent:Dictionary,next:float,dt:float)->Dictionary:
 var old:Dictionary=car.get(KEY,{})
 var out:Dictionary=obs.duplicate()
 var action:Dictionary=intent.get("traffic_policy",{"mode":obs.mode,"lift":0.0,"save_kers":false,"reason":"observe"})
 out.merge(action,true)
 var measured:float=maxf(0.0,next-float(car.progress))/maxf(.00001,dt)
 out["rate"]=lerpf(rate(car,maxf(.0001,measured)),measured,.25)
 out["clear_s"]=float(old.get("clear_s",0.0))+(dt if str(out.mode) in ["FREE_AIR","CLEAR"] else 0.0)
 out["congestion_s"]=float(old.get("congestion_s",0.0))+(dt if int(obs.group_size)>=3 else 0.0)
 var lift_loss:float=dt*(1.0-1.0/(1.0+float(out.lift)))
 var solver_loss:float=minf(dt,maxf(0.0,float(intent.next)-next)*float(intent.pace))
 out["estimated_lift_s"]=float(old.get("estimated_lift_s",0.0))+lift_loss
 out["solver_delay_s"]=float(old.get("solver_delay_s",0.0))+solver_loss
 # Associated local delay, NOT an experimentally established counterfactual.
 out["lapping_traffic_s"]=float(old.get("lapping_traffic_s",0.0))+(dt if bool(obs.get("lapping_ahead",false)) else 0.0)
 out["lapping_delay_est_s"]=float(old.get("lapping_delay_est_s",0.0))+(minf(dt,lift_loss+solver_loss) if bool(obs.get("lapping_ahead",false)) else 0.0)
 var aero:Dictionary=intent.get("aero_wake_032",{})
 out["dirty_air_s"]=float(old.get("dirty_air_s",0.0))+(dt if float(aero.get("dirty_fraction",0.0))>0.00001 else 0.0)
 out["tow_s"]=float(old.get("tow_s",0.0))+(dt if float(aero.get("tow_fraction",0.0))>0.00001 else 0.0)
 out["prior_group_size"]=int(old.get("group_size",1))
 out["cancelled"]=int(old.get("cancelled",0))+(1 if intent.has("pack_reason") and str(old.get("reason",""))!=str(intent.get("pack_reason","")) else 0)
 if intent.has("pack_reason"):out.reason=str(intent.pack_reason)
 out["opportunity"]=int(obs.front_duels)>0 and float(obs.closing)>0.00002
 out["opportunities"]=int(old.get("opportunities",0))+(1 if bool(out.opportunity) and not bool(old.get("opportunity",false)) else 0)
 out["kers_skipped_ticks"]=int(old.get("kers_skipped_ticks",0))+(1 if bool(intent.get("traffic_kers_skipped",false)) else 0)
 out["confirmed_passes"]=int(old.get("confirmed_passes",0))
 out["yield_to"]=int(old.get("yield_to",-1))
 out["yield_goal"]=float(old.get("yield_goal",car.get("race_lane",0.0)))
 out["yield_grace"]=maxf(0.0,float(old.get("yield_grace",0.0))-dt)
 out["group_transfers"]=int(old.get("group_transfers",0))
 out["yield_samples"]=int(old.get("yield_samples",0))
 if intent.has("traffic_yield_to") and int(intent.defending)==int(intent.traffic_yield_to) and str(intent.get("defense_origin",""))=="blue_flag":
  var new_target:int=int(intent.traffic_yield_to)
  if int(out.yield_to)>=0 and int(out.yield_to)!=new_target and float(out.yield_grace)>0.0:out.group_transfers+=1
  out.yield_to=new_target;out.yield_goal=float(intent.defense_line);out.yield_grace=2.0;out.yield_samples+=1
 elif float(out.yield_grace)<=0.0:out.yield_to=-1
 return out

static func pit_reset(car:Dictionary)->Dictionary:
 var state:Dictionary=car.get(KEY,{}).duplicate()
 state["mode"]="PIT";state["leader"]=-1;state["rate"]=0.0;state["lift"]=0.0;state["save_kers"]=false;state["prepared_s"]=0.0;state["congestion_run_s"]=0.0;state["opportunity"]=false;state["yield_to"]=-1;state["yield_grace"]=0.0
 return state

static func conserve_kers(car:Dictionary,player:bool)->bool:
 # Explicit player KERS setting is never modified. AI skips only a burst;
 # per-zone quotas and 400kJ limit stay in RaceKers2012.
 return not player and str(car.get("pace","Normal"))!="Atacar" and str(car.get("combat_state","")) not in ATTACK and int(car.get("race_defending_against",-1))<0 and str(car.get("kers_mode","Equilibrado"))=="Equilibrado" and bool(car.get(KEY,{}).get("save_kers",false))
