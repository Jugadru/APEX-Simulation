extends SceneTree
const Pack=preload("res://scripts/core/race_traffic_pack_09201.gd")
const Strategy=preload("res://scripts/core/race_traffic_strategy_09201.gd")
const Space=preload("res://scripts/core/race_space_0655.gd")
const Kers=preload("res://scripts/core/race_kers_2012.gd")
const Thermal=preload("res://scripts/core/race_tyre_thermal.gd")
const Race=preload("res://scripts/race_engine.gd")
var checks:int=0
var failures:Array[String]=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("TRAFFIC_MEGA_FAIL ",label)
func car(id:int,p:float,lane:float=0.0)->Dictionary:
 return {"id":id,"name":"P%d"%id,"team":"T%d"%id,"progress":p,"race_lane":lane,"finished":false,"pit_left":0.0,"skill":85,"spatial_awareness":95,"risk_tolerance":25,"driver_soul":{"focus":.95},"combat_state":"closing","attack_charge":2.0,"combat_target_id":-1,"wear":65.0,"tire":"Médio","pace":"Normal","last_lap":100.0,"tyre_surface_c":115.0,"drs_eligible":true,"kers_mode":"Equilibrado"}
func metric(pace:float,load:float=0.0)->Dictionary:
 return {"target":pace,"decision_pace":pace,"line_load":load,"ahead_load":load,"line_ratio":0.0}
func run():
 var own=car(1,.20);var a=car(2,.21);var b=car(3,.22);var c=car(4,.23);var rear=car(5,.18)
 var grid=[own,a,b,c,rear]
 var metrics={1:metric(100,.5),2:metric(100,.5),3:metric(100,.5),4:metric(100,.5),5:metric(100,.5)}
 var weather={"wetness_factor":0.0,"drs_allowed":true}
 var snapshot=var_to_bytes([grid,metrics,weather])
 var obs=Pack.observe(own,grid,metrics,1000,weather,.2)
 check(obs.group_size==4 and obs.drs_train and obs.rear_s>1.0,"physical group and actual DRS flags")
 check(var_to_bytes([grid,metrics,weather])==snapshot,"frozen input")
 check(Pack.observe(own,[rear,c,b,a,own],metrics,1000,weather,.2)==obs,"order independent")
 check(not Pack.observe(own,grid,metrics,1000,{"wetness_factor":.8,"drs_allowed":false},.2).drs_train,"wet DRS train not armed")
 var fast=car(6,.1);fast.last_lap=80.0
 var slow=car(7,.145);slow.last_lap=130.0
 var approach=Pack.observe(fast,[fast,slow],{6:metric(80),7:metric(130)},1000,weather,.2)
 check(approach.catch_s>0 and approach.catch_s<10 and approach.prepared_s>0,"anticipation beyond tactical range")
 fast[Pack.KEY]=approach
 check(Pack.preparation_bonus(fast,7,1.0)>0 and Pack.preparation_bonus(fast,8,1.0)==0,"preparation target bound")
 var merging=car(8,.19);merging.pit_left=1.0;merging["pit_to"]=.211
 var merging_obs=Pack.observe(own,[own,merging],metrics,1000,weather,.2)
 check(merging_obs.merge_ahead==1 and merging_obs.group_size==1,"pit exit forecast not active neighbor")
 var intent={"state":"closing","defending":-1,"lane":0.0,"next":.202,"pace":100.0}
 var policy=Pack.policy(own,obs,intent,.5,0,false)
 check(policy.mode=="CLEAN_AIR" and policy.lift>0 and policy.lift<=.025,"hot follower longitudinal lift")
 check(Pack.policy(own,obs,intent,.5,.8,false).lift==0.0,"wet conservative no extra lift")
 check(Pack.policy(own,obs,intent,.5,0,true).lift==0.0,"narrow priority")
 var attacking=intent.duplicate();attacking.state="duel"
 check(Pack.policy(own,obs,attacking,.5,0,false).mode=="COMMIT","attack preserved")
 var wait_obs=obs.duplicate();wait_obs.congestion_run_s=5.0
 var wait=Pack.policy(own,wait_obs,intent,0,0,false)
 check(wait.mode=="WAIT" and wait.save_kers,"patient train conserves")
 own[Pack.KEY]=wait
 check(Pack.conserve_kers(own,false) and not Pack.conserve_kers(own,true),"AI only KERS conservation")
 own.kers_mode="Atacar"
 check(not Pack.conserve_kers(own,false),"explicit mode preserved")
 own.kers_mode="Equilibrado"
 own.erase(Pack.KEY)
 var risk_car=own.duplicate(true);risk_car.risk_tolerance=95
 var risk_obs=Pack.observe(risk_car,grid,metrics,1000,weather,.2);risk_obs.congestion_run_s=5.0
 check(not Pack.policy(risk_car,risk_obs,intent,0,0,false).save_kers,"personality changes decision")
 var third=car(9,.188,-1.5)
 var tactic={"commit":true,"defense":true,"attack_goal":-2.95}
 var early=car(10,.20)
 var front=car(11,.215)
 var tm={9:metric(50),10:metric(100),11:metric(100)}
 check(not Pack.refine(early,front,[early,front,third],tm,tactic,{"group_size":3},15,1000).commit,"third corridor forecast veto")
 early.combat_state="duel"
 check(Pack.refine(early,front,[early,front,third],tm,tactic,{"group_size":3},15,1000)==tactic,"established duel untouched")
 early.combat_state="closing"
 check(Pack.refine(early,front,[early,front],tm,tactic,{"group_size":1,"merge_ahead":1},15,1000).pack_reason=="pit_transition","pit exit delays fresh commitment")
 var back=car(12,.4,-1.0);var previous=car(13,1.405);var next_fast=car(14,1.38)
 back[Pack.KEY]={"yield_to":13,"yield_goal":-1.25,"yield_grace":2.0}
 var context={"gap":20.0,"length":1000.0,"limit":2.95,"wet":0.0,"load":0.0,"ahead_load":0.0,"narrowing":false,"busy":false,"advantage":10.0,"passing_lane":-2.95}
 var blue=Pack.blue(next_fast,back,[previous,next_fast,back],{12:metric(100),13:metric(90),14:metric(90)},context)
 check(blue.yield_early and blue.reason=="group_yield" and blue.yield_lane<0,"group maintains side across leaders")
 var group_obs=Pack.observe(back,[previous,next_fast,back],{12:metric(100)},1000,weather,.2)
 check(Pack.group_hold(back,group_obs,intent,2.95,false),"hold between leaders")
 check(not Pack.group_hold(back,group_obs,intent,2.95,true),"no group hold on narrowing")
 var pit=Pack.pit_reset(back);check(pit.yield_grace==0 and pit.mode=="PIT","pit clears stale reservation")
 var forecast_car=car(15,2.0);forecast_car.last_lap=90.0
 var rival=car(16,.78);rival.last_lap=100.0
 var window=Strategy.window(forecast_car,[forecast_car,rival],100,25,0)
 check(window.position==1 and window.slower_ahead==1,"physical lapped traffic separate from rank")
 var report=Strategy.report(forecast_car,[forecast_car,rival],100,25,21,53,{"skill":85})
 check(report.cases.size()==3 and report.cases[2].lap==23,"now plus one plus two")
 forecast_car["pit_scheduled_lap"]=21
 check(Strategy.report(forecast_car,[forecast_car,rival],100,25,21,53).protected,"manual protected")
 var proposal={"pit_now":true,"critical":false,"life_laps":4.0,"compound":"Médio","forecast_3":0.0,"forecast_6":0.0}
 var fake_report={"protected":false,"cases":[{"score":4.0,"coverage":1.0},{"score":0.0,"coverage":1.0}]}
 forecast_car.wear=40;forecast_car["stint_laps"]=8
 check(not Strategy.can_hold(forecast_car,proposal,{"protected":true,"cases":fake_report.cases},weather,false,21,53),"manual no auto extension")
 check(not Strategy.can_hold(forecast_car,proposal,fake_report,weather,false,21,53),"manual independent hard gate")
 forecast_car.pit_scheduled_lap=0
 check(Strategy.can_hold(forecast_car,proposal,fake_report,weather,false,21,53),"bounded safe auto extension")
 check(not Strategy.can_hold(forecast_car,proposal,fake_report,{"wetness_factor":.8},false,21,53),"wet no extension")
 check(not Strategy.can_hold(forecast_car,proposal,fake_report,weather,true,21,53),"team busy no extension")
 var radio_car=car(18,.2);radio_car["laps_done"]=8;radio_car[Pack.KEY]=wait_obs
 var msg=Strategy.radio(radio_car,report)
 check(not msg.is_empty() and msg.kind=="traffic_09201","radio grounded")
 radio_car["driver_radio_last_lap"]=7
 check(Strategy.radio(radio_car,report).is_empty(),"radio cooldown")
 var normal=own.duplicate(true);var cooling=own.duplicate(true)
 check(float(Thermal.advance(cooling,weather,{},1,100,.025).tyre_surface_c)<float(Thermal.advance(normal,weather,{},1,100).tyre_surface_c),"real thermal tradeoff")
 var track={"race_width_m":8.8,"lap_km":5.0,"overtake_zones":[[0.0,1.0]]}
 var shape={"length":1000.0}
 # Native 24-car field: pack plus detached runners. Same frozen grid A/B.
 var field:Array=[own,a,b,c,rear];var full_metrics:Dictionary=metrics.duplicate(true)
 for id in range(20,39):
  field.append(car(id,.35+float(id-20)*.03));full_metrics[id]=metric(100,.5)
 var baseline=Space.plan(field,full_metrics,.2,track,shape,weather,true,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,true,true,false)
 var result=Space.plan(field,full_metrics,.2,track,shape,weather,true,false,true,false,40.0,true,true,true,true,true,true,true,true,true,true,true,true,true)
 check(result.size()==24 and baseline.size()==24,"24-car active field")
 check(result[1].states[Pack.KEY].mode=="CLEAN_AIR","native clean-air decision")
 check(result[1].progress<baseline[1].progress,"actual longitudinal effect vs 038")
 check(not baseline[1].states.has(Pack.KEY),"038 checkpoint unchanged")
 var modes:Dictionary={};var overlaps:int=0;var stops:int=0
 for tick in range(120):
  var plan=Space.plan(field,full_metrics,.2,track,shape,weather,true,false,true,false,40.0+tick*.2,true,true,true,true,true,true,true,true,true,true,true,true,true)
  for item in field:
   var state:Dictionary=plan[item.id]
   check(float(state.progress)>=float(item.progress),"no reverse")
   if float(state.progress)<=float(item.progress)+1e-8:stops+=1
   item.progress=state.progress;item.merge(state.states,true)
   var mode:String=str(item[Pack.KEY].mode);modes[mode]=int(modes.get(mode,0))+1
  for i in range(field.size()):
   for j in range(i+1,field.size()):
    var g:float=absf(fposmod(float(field[i].progress)-float(field[j].progress)+.5,1.0)-.5)*1000.0
    if g<6.39999 and absf(float(field[i].race_lane)-float(field[j].race_lane))<2.94999:overlaps+=1
 check(overlaps==0 and stops==0,"native pack no collision or immobilization")
 check(int(modes.get("CLEAN_AIR",0))>0,"native clean air exercised")
 # Real RaceEngine, not a substitute for the controlled Space fixture.
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
 var race=Race.new(data.teams,"Ferrari",42,{},data.tracks[0],{})
 race.configure_weather("Seco");race.running=true;race.clock=40.0
 var ai:Dictionary={}
 for index in range(race.cars.size()):
  var item:Dictionary=race.cars[index]
  item.progress=3.04+index*.038;item.laps_done=3;item.last_lap=100.0
  if ai.is_empty() and str(item.team)!="Ferrari" and bool(item.get("kers_equipped",false)):ai=item
 check(not ai.is_empty(),"native AI KERS participant")
 if not ai.is_empty():
  ai.progress=3.15;ai.kers_mode="Equilibrado";Kers.reset_lap(ai);ai[Pack.KEY]={"save_kers":true,"mode":"WAIT","rate":.01}
  var energy:float=float(ai.kers_remaining_kj)
  check(Kers.should_deploy(ai,float(ai.progress),1.0,race.track),"native burst eligible")
  var manual:Dictionary=race.player_cars()[0]
  manual["pit_control_mode"]="Manual";manual["pit_scheduled_lap"]=21
  race._request_ai_pit(manual)
  check(int(manual.pit_scheduled_lap)==21 and not bool(manual.pit_request),"native manual BOX V21 retained")
  race.step(.2)
  check(ai.has(Pack.KEY) and int(ai[Pack.KEY].get("kers_skipped_ticks",0))==1 and is_equal_approx(float(ai.kers_remaining_kj),energy),"native KERS energy preserved")
  check(int(manual.pit_scheduled_lap)==21,"BOX V21 survives real step")
  var advice:Dictionary=race.get_engineer_advice(int(manual.id))
  check(advice.has("traffic_window_09201") and advice.traffic_window_09201.protected,"live strategy exposed and protected")
  var sampled:bool=false
  if race.telemetry!=null:
   for item in race.telemetry.position_history:
    if item.has("traffic_mode"):sampled=true;break
  check(sampled,"live telemetry traffic fields")
 print("TRAFFIC_MEGA_REPORT ",JSON.stringify({"checks":checks,"failures":failures,"modes":modes,"overlaps":overlaps,"stops":stops}))
 if failures.is_empty():print("TRAFFIC_MEGA_09201_PASS")
 quit(0 if failures.is_empty() else 1)
