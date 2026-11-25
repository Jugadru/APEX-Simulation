extends SceneTree
const Traffic=preload("res://scripts/core/race_driver_traffic_0920.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
var checks:int=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("TRAFFIC_0920_FAIL ",label)
func car(id:int,p:float,lane:float=0.0)->Dictionary:
 return {"id":id,"progress":p,"race_lane":lane,"finished":false,"pit_left":0.0,"skill":85,"spatial_awareness":85,"risk_tolerance":70,"combat_state":"closing","attack_charge":2.0,"combat_target_id":-1}
func run():
 var fast=car(1,1.350)
 var slow=car(2,.370)
 var grid=[fast,slow]
 var metrics={1:{"target":85.0,"decision_pace":85.0,"line_load":0.0,"ahead_load":0.0,"line_ratio":0.0},2:{"target":95.0,"decision_pace":95.0,"line_load":0.0,"ahead_load":0.0,"line_ratio":0.0}}
 var ctx={"gap":20.0,"length":1000.0,"limit":2.95,"wet":0.0,"load":0.0,"ahead_load":0.0,"narrowing":false,"busy":false,"advantage":10.0,"passing_lane":2.95}
 var before=var_to_bytes([grid,metrics,ctx])
 var first=Traffic.evaluate(fast,slow,grid,metrics,ctx)
 check(first.lapping and first.yield_early and first.yield_lane<0.0,"early legal yield opposite attacker")
 check(var_to_bytes([grid,metrics,ctx])==before,"no input mutation")
 check(Traffic.evaluate(fast,slow,grid,metrics,ctx)==first,"deterministic")
 check(Traffic.lapping(car(1,1.99),car(2,.01),20,1000),"line wrap")
 check(Traffic.lapping(car(1,1.94),car(2,1.0),30,500),"short circuit true lap")
 check(not Traffic.lapping(car(1,.35),car(2,.37),20,1000),"same lap no blue flag")
 check(not Traffic.lapping(fast,slow,19,1000),"inconsistent gap rejected")
 check(not Traffic.lapping(slow,fast,20,1000),"not inverted")
 var absent=slow.duplicate();absent.pit_left=1.0
 check(not Traffic.lapping(fast,absent,20,1000),"pit excluded")
 absent.pit_left=0.0;absent.finished=true
 check(not Traffic.lapping(fast,absent,20,1000),"finished excluded")
 var blocked=ctx.duplicate();blocked.narrowing=true
 check(not Traffic.evaluate(fast,slow,grid,metrics,blocked).yield_early,"narrowing veto")
 blocked=ctx.duplicate();blocked.load=.5
 check(not Traffic.evaluate(fast,slow,grid,metrics,blocked).yield_early,"no fresh yield in loaded corner")
 blocked=ctx.duplicate();blocked.advantage=0.0
 check(not Traffic.evaluate(fast,slow,grid,metrics,blocked).yield_early,"not closing")
 blocked=ctx.duplicate();blocked.busy=true
 check(not Traffic.evaluate(fast,slow,grid,metrics,blocked).yield_early,"reserved intent respected")
 var duelling=slow.duplicate();duelling.combat_state="duel"
 check(not Traffic.evaluate(fast,duelling,grid,metrics,ctx).yield_early,"own established battle protected")
 var close=car(1,1.355)
 var dry=ctx.duplicate();dry.gap=15.0
 check(Traffic.evaluate(close,slow,[close,slow],metrics,dry).yield_early,"dry safe window")
 dry.wet=1.0
 check(not Traffic.evaluate(close,slow,[close,slow],metrics,dry).yield_early,"wet larger margin")
 var third=car(3,.375,-1.5)
 check(Traffic.evaluate(fast,slow,[fast,slow,third],metrics,ctx).reason=="third_car_corridor","occupied third corridor")
 var approaching=car(3,.357,-1.5)
 var projected_metrics=metrics.duplicate(true);projected_metrics[3]={"target":45.0}
 check(not Traffic.swept_clear(slow,fast,[fast,slow,approaching],projected_metrics,-1.25,1000),"third car forecast")
 third.pit_left=5.0
 check(Traffic.evaluate(fast,slow,[fast,slow,third],metrics,ctx).yield_early,"pit car not physical obstruction")
 var locked=slow.duplicate(true);locked.race_lane=-.5;locked["racecraft_memory"]={"traffic_yield_to":1,"traffic_yield_goal":-1.25}
 var opposite=ctx.duplicate();opposite.passing_lane=-2.95
 check(Traffic.evaluate(fast,locked,[fast,locked],metrics,opposite).yield_lane==-1.25,"locked choice not reversed by passing side")
 var late=car(1,1.364)
 var late_ctx=ctx.duplicate();late_ctx.gap=6.0
 check(Traffic.evaluate(late,locked,[late,locked],metrics,late_ctx).yield_lane==-.5,"late locked yield holds actual lane")
 check(not Traffic.evaluate(late,slow,[late,slow],metrics,late_ctx).yield_early,"no late fresh move")
 var track={"race_width_m":8.8,"lap_km":5.0,"overtake_zones":[[0.0,1.0]]}
 var shape={"length":1000.0}
 var native=Space.plan(grid,metrics,.2,track,shape,{},true,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,true,true)
 check(native[2].states.racecraft_memory.get("traffic_yield_to",-1)==1,"native yield reservation")
 check(absf(float(native[2].states.race_lane))>0.0,"native physical movement")
 check(native[1].progress>=fast.progress and native[2].progress>=slow.progress,"no reverse or teleport")
 check(native==Space.plan(grid.duplicate(true),metrics.duplicate(true),.2,track,shape,{},true,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,true,true),"native deterministic")
 var same=car(1,.350)
 var same_grid=[same,slow]
 var old=Space.plan(same_grid,metrics,.2,track,shape,{},true,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,true,false)
 var new=Space.plan(same_grid,metrics,.2,track,shape,{},true,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,true,true)
 check(old==new,"same-lap sporting behavior unchanged")
 # Deliberately seeded lapped traffic with 24 active cars, not an ordinary
 # short GP that may never exercise a blue flag. Iterate frozen snapshots.
 var field:Array=[fast.duplicate(true),slow.duplicate(true)]
 var full_metrics:Dictionary=metrics.duplicate(true)
 for id in range(3,25):
  field.append(car(id,.42+float(id-3)*.023))
  full_metrics[id]={"target":95.0,"decision_pace":95.0,"line_load":0.0,"ahead_load":0.0,"line_ratio":0.0}
 var yields:int=0
 var overlaps:int=0
 for tick in range(100):
  var plan=Space.plan(field,full_metrics,.2,track,shape,{},true,false,true,false,40.0+tick*.2,true,true,true,true,true,true,true,true,true,true,true,true)
  check(plan.size()==24,"all cars active tick "+str(tick))
  for item in field:
   var state:Dictionary=plan[item.id]
   check(float(state.progress)>=float(item.progress),"no reverse")
   item.progress=state.progress
   item.merge(state.states,true)
   if item.get("racecraft_memory",{}).has("traffic_yield_to"):yields+=1
  for i in range(field.size()):
   for j in range(i+1,field.size()):
    var gap:float=absf(fposmod(float(field[i].progress)-float(field[j].progress)+.5,1.0)-.5)*1000.0
    if gap<6.39999 and absf(float(field[i].race_lane)-float(field[j].race_lane))<2.94999:overlaps+=1
 check(yields>0,"24-car fixture actually exercises yield")
 check(overlaps==0,"24-car lapped traffic no overlaps")
 print("TRAFFIC_0920_REPORT ",JSON.stringify({"checks":checks,"failures":failures,"yield_samples":yields,"overlap_samples":overlaps}))
 if failures.is_empty():print("DRIVER_TRAFFIC_0920_PASS")
 quit(0 if failures.is_empty() else 1)
