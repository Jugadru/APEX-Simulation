extends RefCounted
## 040: independent deterministic error hazard and positive-speed recovery.
## All coefficients are fictional gameplay calibration, not measured FIA data.
const Thermal=preload("res://scripts/core/race_tyre_thermal.gd")
const Setup=preload("res://scripts/core/race_weather_setup_15.gd")
const KEY="driver_error_0921"
const TYPES=["MISSED_APEX","POOR_TRACTION","LOCK_UP","OVERSTEER","RUNNING_WIDE","SPIN"]
const SPECS={
 "MISSED_APEX":[.1,.5,.12,"Erro de trajetória"],
 "POOR_TRACTION":[.2,.8,.20,"Perda de tração"],
 "LOCK_UP":[.3,1.5,.28,"Travamento"],
 "OVERSTEER":[.4,1.8,.33,"Sobresterço"],
 "RUNNING_WIDE":[.8,3.5,.42,"Escapada"],
 "SPIN":[3.0,12.0,.55,"Rodada"]
}
# Counter-based random draws: no access to RaceEngine.rng.state.
# Arithmetic stays in signed 64-bit range; stable across replay seek.
static func sample(seed:int,id:int,tick:int,channel:int)->float:
 var x:int=posmod(seed,4294967296)
 x=(x ^ ((id*73856093)&0xffffffff) ^ ((tick*19349663)&0xffffffff) ^ ((channel*83492791)&0xffffffff))&0xffffffff
 # Two integer avalanche rounds: adjacent ticks/channels do not form
 # an affine sequence. Multiplication remains below signed 64-bit range.
 x=((x^(x>>16))*0x45d9f3b)&0xffffffff
 x=((x^(x>>16))*0x45d9f3b)&0xffffffff
 x=(x^(x>>16))&0xffffffff
 return float(x)/4294967296.0

# Optional read-only setup evaluation from the same frozen car/weather.
# An empty argument preserves independent/legacy callers exactly.
static func context(car:Dictionary,metrics:Dictionary,weather:Dictionary,dt:float,shared_setup:Dictionary={})->Dictionary:
 var old:Dictionary=car.get(KEY,{})
 var soul:Dictionary=car.get("driver_soul",{})
 var traffic:Dictionary=car.get("traffic_pack_09201",{})
 var wet:float=clampf(float(weather.get("wetness_factor",0.0)),0,1)
 var load:float=clampf(float(metrics.get("line_load",0.0)),0,1)
 var ahead:float=clampf(float(metrics.get("ahead_load",load)),0,1)
 var phase:String="STRAIGHT"
 if maxf(load,ahead)>=.28:phase="ENTRY" if ahead>load+.08 else ("EXIT" if load>ahead+.08 else "APEX")
 var skill:float=clampf(float(car.get("skill",80))/100.0,0,1)
 var awareness:float=clampf(float(car.get("spatial_awareness",80))/100.0,0,1)
 var consistency:float=clampf(float(car.get("consistency",float(car.get("skill",80))))/100.0,0,1)
 var wet_skill:float=clampf(float(car.get("rain_skill",float(car.get("skill",80))))/100.0,0,1)
 var risk:float=clampf(float(car.get("risk_tolerance",55))/100.0,0,1)
 var focus:float=clampf(float(soul.get("focus",.85)),0,1)
 var confidence:float=clampf(float(soul.get("confidence",.55)),0,1)
 var rear:float=clampf((1.6-float(traffic.get("rear_s",999.0)))/1.6,0,1)
 var battle:float=1.0 if str(car.get("combat_state","")) in ["duel","defending","attacking"] else 0.0
 var pressure_target:float=clampf(.62*rear+.18*battle+.20*float(soul.get("pressure",.15)),0,1)
 var pressure:float=lerpf(float(old.get("pressure",0.0)),pressure_target,1.0-exp(-maxf(dt,0.0)/3.5))
 var band:Array=Thermal.band(str(car.get("tire","Médio")))
 var temp:float=float(car.get("tyre_surface_c",(float(band[0])+float(band[1]))*.5))
 var thermal:float=clampf(maxf(float(band[0])-temp,temp-float(band[1]))/35.0,0,1)
 var wear:float=clampf(float(car.get("wear",0.0))/100.0,0,1)
 var mismatch:float=wet if str(car.get("tire","Médio")) not in ["Intermediário","Chuva"] else maxf(0.0,.25-wet)
 var grip:float=clampf(1.0-float(weather.get("grip_factor",1.0)),0,1)
 var setup_cost:float=0.0
 if phase!="STRAIGHT":
  var setup:Dictionary=Setup.evaluate(car.get("race_setup_15",{}),weather) if shared_setup.is_empty() else shared_setup
  setup_cost=clampf((float(setup.brake_s)+float(setup.mechanical_s)+float(setup.aero_corner_s))/.55,-1,1)
 var pace:float=1.65 if str(car.get("pace","Normal"))=="Atacar" else (.55 if str(car.get("pace","Normal"))=="Conservar" else 1.0)
 var hazard:float=.00032*pace*(.65+.75*risk+.65*(1.0-consistency)+.50*(1.0-focus)+.25*(1.0-confidence)+1.2*pressure+1.4*wear*wear+thermal+1.5*grip+1.8*wet*(1.0-wet_skill)+3.2*mismatch+.45*setup_cost)
 hazard=clampf(hazard,0.0,.0045) if phase!="STRAIGHT" else 0.0
 return {"phase":phase,"load":load,"ahead_load":ahead,"wet":wet,"skill":skill,"awareness":awareness,"consistency":consistency,"wet_skill":wet_skill,"risk":risk,"focus":focus,"confidence":confidence,"pressure":pressure,"thermal":thermal,"wear":wear,"mismatch":mismatch,"setup_cost":setup_cost,"hazard":hazard}

static func classify(ctx:Dictionary,u:float)->String:
 var phase:String=str(ctx.phase)
 var wet:float=float(ctx.wet)
 var weights:Array=[3.4,2.8 if phase=="EXIT" else .5,2.8 if phase=="ENTRY" else .35,1.8 if phase=="EXIT" else .65,.75+.7*float(ctx.pressure),.025+.12*wet+.10*float(ctx.mismatch)]
 weights[0]*=1.0+.5*float(ctx.pressure)
 weights[1]*=1.0+wet+float(ctx.mismatch)
 weights[2]*=1.0+float(ctx.thermal)+float(ctx.wear)
 weights[3]*=1.0+wet
 var sum:float=0.0
 for weight in weights:sum+=float(weight)
 var pick:float=clampf(u,0,.999999)*sum
 for i in range(weights.size()):
  pick-=float(weights[i])
  if pick<0:return TYPES[i]
 return "SPIN"

static func begin(state:Dictionary,kind:String,ctx:Dictionary,u:float)->Dictionary:
 var out:Dictionary=state.duplicate(true)
 var spec:Array=SPECS[kind]
 var quality:float=clampf(.45*float(ctx.skill)+.25*float(ctx.awareness)+.15*float(ctx.focus)+.15*float(ctx.wet_skill),0,1)
 var loss:float=lerpf(float(spec[0]),float(spec[1]),clampf(.65*u+.20*float(ctx.wet)+.15*(1.0-quality),0,1))
 # Piecewise linear speed loss: one-quarter plateau, then linear recovery.
 # Integral = .625 * peak * duration, exactly the requested nominal loss.
 var peak:float=float(spec[2])
 var duration:float=loss/(.625*peak)
 out.merge({"mode":"ERROR","kind":kind,"elapsed":0.0,"duration":duration,"peak":peak,"planned_loss":loss,"event_loss":0.0,"rebuild_left":5.0+5.0*(1.0-quality)+3.0*float(ctx.wet),"rebuild_duration":5.0+5.0*(1.0-quality)+3.0*float(ctx.wet),"radio_announced":false,"cooldown":maxf(8.0,12.0-4.0*float(ctx.risk)),"confidence_hit":minf(.12,.015+loss*.012),"count":int(state.get("count",0))+1,"started":true,"completed":false,"interrupted":false},true)
 var counts:Dictionary=state.get("counts",{}).duplicate()
 counts[kind]=int(counts.get(kind,0))+1;out["counts"]=counts
 return out

static func integral(t:float,duration:float,peak:float)->float:
 var x:float=clampf(t,0.0,duration)
 var plateau:float=duration*.25
 if x<=plateau:return peak*x
 var r:float=x-plateau
 return peak*(plateau+r-r*r/(2.0*maxf(.00001,duration-plateau)))

static func advance(car:Dictionary,metrics:Dictionary,weather:Dictionary,dt:float,seed:int,tick:int,clock:float,shared_setup:Dictionary={})->Dictionary:
 var out:Dictionary=car.get(KEY,{}).duplicate(true)
 out["started"]=false;out["completed"]=false;out["interrupted"]=false
 var ctx:Dictionary=context(car,metrics,weather,dt,shared_setup)
 out["pressure"]=ctx.pressure;out["hazard"]=ctx.hazard;out["phase"]=ctx.phase
 out["mode"]=str(out.get("mode","NORMAL"))
 out["speed_fraction"]=1.0;out["suppress_attack"]=false;out["confidence_delta"]=0.0
 if str(out.mode)=="NORMAL":
  out["cooldown"]=maxf(0.0,float(out.get("cooldown",0.0))-dt)
  if clock>=24.0 and float(car.get("progress",0.0))>=0.0 and float(out.cooldown)<=0.0 and not bool(car.get("pit_request",false)) and float(car.get("combat_hesitation_s",0.0))<=0.0 and float(ctx.hazard)>0.0 and sample(seed,int(car.id),tick,1)<1.0-exp(-float(ctx.hazard)*dt):
   out=begin(out,classify(ctx,sample(seed,int(car.id),tick,2)),ctx,sample(seed,int(car.id),tick,3))
   out["confidence_delta"]=-float(out.confidence_hit)
 if str(out.mode) in ["ERROR","CONTROL","RECOVERY"]:
  var elapsed:float=float(out.elapsed)
  var duration:float=float(out.duration)
  var end:float=minf(duration,elapsed+dt)
  var loss:float=integral(end,duration,float(out.peak))-integral(elapsed,duration,float(out.peak))
  out["speed_fraction"]=clampf(1.0-loss/maxf(dt,.00001),.45,1.0)
  out["suppress_attack"]=elapsed<duration*.55
  out["elapsed"]=end
  out["event_loss"]=float(out.event_loss)+loss
  out["total_loss"]=float(out.get("total_loss",0.0))+loss
  out["mode"]="ERROR" if bool(out.started) else ("CONTROL" if end<duration*.25 else "RECOVERY")
  if end>=duration:out.mode="REBUILD";out.completed=true
 elif str(out.mode)=="REBUILD":
  var rebuild_step:float=minf(dt,float(out.rebuild_left))
  out["confidence_delta"]=float(out.confidence_hit)*.45*rebuild_step/maxf(.00001,float(out.rebuild_duration))
  out["rebuild_left"]=maxf(0.0,float(out.rebuild_left)-dt)
  if float(out.rebuild_left)<=0:out.mode="NORMAL"
 return out

static func pit_reset(car:Dictionary)->Dictionary:
 var out:Dictionary=car.get(KEY,{}).duplicate(true)
 if str(out.get("mode","NORMAL")) in ["ERROR","CONTROL","RECOVERY"]:
  out["interrupted_count"]=int(out.get("interrupted_count",0))+1;out["interrupted"]=true
 out["mode"]="NORMAL";out["speed_fraction"]=1.0;out["suppress_attack"]=false;out["started"]=false;out["completed"]=false;out["pressure"]=0.0;out["hazard"]=0.0;out["cooldown"]=8.0
 return out

static func apply_soul(car:Dictionary,state:Dictionary)->void:
 var change:float=float(state.get("confidence_delta",0.0))
 if absf(change)<.000000001:return
 var soul:Dictionary=car.get("driver_soul",{}).duplicate(true)
 if soul.is_empty():return
 soul["confidence"]=clampf(float(soul.get("confidence",.55))+change,.20,.90)
 soul["focus"]=clampf(float(soul.get("focus",.85))+(change*.4),.35,1.0)
 car["driver_soul"]=soul

static func label(kind:String)->String:
 return str(SPECS.get(kind,[0,0,0,"Erro"])[3])

static func radio(state:Dictionary)->String:
 match str(state.get("kind","")):
  "LOCK_UP":return "Travei os pneus na entrada. Preciso recuperar o ritmo."
  "MISSED_APEX":return "Errei o ponto da curva."
  "POOR_TRACTION":return "Perdi tração na saída."
  "OVERSTEER":return "Precisei corrigir a traseira."
  "RUNNING_WIDE":return "Errei a trajetória e perdi tempo."
  "SPIN":return "Perdi o controle. Estou recuperando o carro."
 return "Cometi um erro. Estou recuperando o ritmo."
