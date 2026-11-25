extends RefCounted
## Frozen observations; no opponent goal is read. State is checkpointed per car.
const ATTACK := ["preparing","attacking","duel"]
static func decide(car:Dictionary, intent:Dictionary, leader:Dictionary, gap:float, own:float, limit:float, load:float, ahead_load:float, wet:float, dt:float, allow_draft:bool=true)->Dictionary:
 var prior:Dictionary=car.get("racecraft_memory",{})
 var lane:float=float(car.get("race_lane",0.0))
 var target:int=int(leader.get("id",-1))
 var observed:float=float(leader.get("race_lane",0.0))
 var same:bool=target>=0 and target==int(prior.get("target",-2))
 var stable:float=float(prior.get("stable",0.0))+dt if same and absf(observed-float(prior.get("observed",observed)))<=0.045 else 0.0
 var timer:float=maxf(0.0,float(prior.get("timer",0.0))-dt)
 var mode: String="CRUISE"
 var aim:float=own
 var prev_mode:String=str(prior.get("mode","CRUISE"))
 var committed:bool=str(intent.state) in ATTACK
 var defense:bool=int(intent.defending)>=0
 if committed:
  mode="PREPARE" if str(intent.state)=="preparing" else ("SIDE_BY_SIDE" if str(intent.state)=="duel" else "ATTACK")
  aim=float(intent.goal)
 elif defense:
  mode="DEFEND";aim=float(intent.goal)
 elif target>=0 and gap<=38.0:
  mode="FOLLOW"
  # Wake acquisition is small, stable, and anchored to our own line.
  if allow_draft and gap>=7.4 and gap<=30.0 and load<0.12 and ahead_load<0.16 and wet<0.65 and stable>=1.4 and absf(observed-own)<=0.95:
   mode="DRAFT";aim=clampf(observed,own-0.45,own+0.45)
  if gap<7.4 and absf(lane-observed)>=2.94:
   mode="SIDE_BY_SIDE";aim=lane
 elif absf(lane-own)>0.25:
  mode="RETURN"
 if prior.has("attack_target") and prev_mode in ["ATTACK","PREPARE","SIDE_BY_SIDE"] and not committed and not defense and mode!="SIDE_BY_SIDE":
  mode="ABORT";timer=1.2
 if prev_mode=="COMPLETE" and timer>0.0 and not committed and not defense:
  mode="COMPLETE";aim=own
 elif prev_mode=="COMPLETE" and not committed and not defense:
  mode="RETURN";aim=own
 if prev_mode=="ABORT" and timer>0.0 and not committed and not defense:
  mode="ABORT";aim=own
 if mode=="DRAFT" and prev_mode=="DRAFT" and same and timer>0.0:
  aim=clampf(float(prior.get("aim",aim)),own-0.45,own+0.45)
 elif mode=="DRAFT":timer=2.0
 if mode=="FOLLOW" and prev_mode=="DRAFT":timer=1.2
 if mode=="DRAFT" and prev_mode=="FOLLOW" and float(prior.get("timer",0.0))>0.0:
  mode="FOLLOW";aim=own
 var awareness:float=clampf(float(car.get("spatial_awareness",80.0))/100.0,0.0,1.0)
 var rate:float=(1.8 if committed or defense else 1.05+0.35*awareness)*(1.0-0.20*wet)
 var accel:float=2.4 if committed or defense else 1.4+0.5*awareness
 var error:float=clampf(aim,-limit,limit)-lane
 var velocity:float=move_toward(float(prior.get("velocity",0.0)),clampf(error/maxf(dt,0.45),-rate,rate),accel*dt)
 velocity=clampf(velocity,-rate,rate)
 var step:float=clampf(velocity*dt,minf(0.0,error),maxf(0.0,error))
 return {"mode":mode,"target":target,"observed":observed,"stable":minf(stable,10.0),"timer":timer,"aim":clampf(aim,-limit,limit),"velocity":velocity,"wanted":lane+step}
static func longitudinal(pace:float,gap:float,separation:float,load:float,wet:float)->float:
 if gap<6.4 or gap>30.0 or separation>0.8:return pace
 var wake:float=(1.0-gap/38.0)*(1.0-separation/0.8)
 var buffer:float=0.55*wet*clampf((10.5-gap)/4.1,0.0,1.0)*(1.0-separation/0.8)
 if load<0.22:return pace+buffer-0.75*wake*(1.0-load/0.22)*(1.0-0.85*wet)
 return pace+buffer+0.45*wake*clampf((load-0.22)/0.58,0.0,1.0)*(1.0-0.60*wet)
