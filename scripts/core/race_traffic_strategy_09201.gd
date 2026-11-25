extends RefCounted
## 039: physical (modular) rejoin forecast separate from sporting rank.
## Uses observed lap times, never hidden future stops or incident RNG.
const Pack=preload("res://scripts/core/race_traffic_pack_09201.gd")
const SLICKS=["Supermacio","Macio","Médio","Duro"]

static func lap_time(car:Dictionary,base:float)->float:
 var last:float=float(car.get("last_lap",0.0))
 return last if last>20.0 and last<500.0 else base

static func window(car:Dictionary,grid:Array,base:float,pit_loss:float,extend:int)->Dictionary:
 var own:float=lap_time(car,base)
 var horizon:float=own*extend+maxf(0.0,pit_loss)
 var exit:float=float(car.progress)+extend
 var rank:int=1
 var ahead:float=999.0
 var behind:float=999.0
 var slow:int=0
 var count:int=0
 var known:int=0
 var samples:int=0
 for other in grid:
  if int(other.id)==int(car.id) or bool(other.get("finished",false)):continue
  samples+=1
  var pace:float=lap_time(other,base)
  if float(other.get("last_lap",0.0))>20.0 and float(other.get("last_lap",0.0))<500.0:known+=1
  var projected:float=float(other.progress)+horizon/maxf(20.0,pace)
  if float(other.get("pit_left",0.0))>0.0:
   if horizon<float(other.pit_left):continue
   projected=float(other.get("pit_to",other.progress))+maxf(0.0,horizon-float(other.pit_left))/maxf(20.0,pace)
  var delta:float=projected-exit
  if delta>=0.0:rank+=1
  var forward:float=fposmod(delta,1.0)*base
  var rear:float=fposmod(-delta,1.0)*base
  ahead=minf(ahead,forward);behind=minf(behind,rear)
  if forward<3.0 or rear<1.0:count+=1
  if forward<5.0 and pace>own+.30:slow+=1
 var score:float=float(count)+1.5*slow
 return {"extend":extend,"position":rank,"ahead_s":ahead,"behind_s":behind,"nearby":count,"slower_ahead":slow,"risk":"ALTO" if score>=3.0 else ("MODERADO" if score>0.0 else "BAIXO"),"score":score,"coverage":float(known)/maxi(1,samples)}

static func report(car:Dictionary,grid:Array,base:float,pit_loss:float,next_lap:int,total_laps:int,staff:Dictionary={})->Dictionary:
 var cases:Array=[]
 for extra in range(3):
  if next_lap+extra>=total_laps:break
  var item:Dictionary=window(car,grid,base,pit_loss,extra)
  item["lap"]=next_lap+extra;cases.append(item)
 var protected:bool=int(car.get("pit_scheduled_lap",0))>0 or bool(car.get("pit_request",false)) or float(car.get("pit_left",0.0))>0.0
 var quality:float=clampf(float(staff.get("skill",50.0))/100.0,0.0,1.0)
 var best:int=0
 for i in range(1,cases.size()):
  if float(cases[i].score)+.5*i<float(cases[best].score)+.5*best:best=i
 var confidence:String="BAIXA"
 if not cases.is_empty() and float(cases[0].coverage)>=.75 and quality>=.65:confidence="MODERADA"
 return {"cases":cases,"recommended_extend":0 if protected else best,"protected":protected,"confidence":confidence,"note":"Projeção de ritmo observado; não prevê futuras paradas ou incidentes."}

static func can_hold(car:Dictionary,proposal:Dictionary,report_data:Dictionary,weather:Dictionary,team_busy:bool,next_lap:int,total:int)->bool:
 var cases:Array=report_data.get("cases",[])
 var stint:int=int(car.get("stops",0))
 return cases.size()>=2 and not bool(report_data.get("protected",true)) and bool(proposal.get("pit_now",false)) and not bool(proposal.get("critical",false)) and not bool(proposal.get("deferred",false)) and not team_busy and not bool(car.get("finished",false)) and not bool(car.get("pitwall49_held",false)) and int(car.get("lap_strategy_adjusted_stint_06496",-999))!=stint and int(car.get("team_pit_adjusted_stint_06497",-999))!=stint and int(car.get("staff_strategy_hold_stint_066910",-999))!=stint and float(car.get("wear",100.0))<58.0 and float(proposal.get("life_laps",0.0))>=3.0 and int(car.get("stint_laps",0))>=4 and str(car.get("tire","")) in SLICKS and str(proposal.get("compound","")) in SLICKS and float(weather.get("wetness_factor",1.0))<.10 and float(proposal.get("forecast_3",1.0))<.10 and float(proposal.get("forecast_6",1.0))<.12 and next_lap+2<total and float(cases[0].coverage)>=.75 and float(cases[0].score)>=3.0 and float(cases[1].score)<=.5

static func radio(car:Dictionary,forecast:Dictionary)->Dictionary:
 var obs:Dictionary=car.get(Pack.KEY,{})
 var lap:int=int(car.get("laps_done",0))
 if obs.is_empty() or lap-int(car.get("driver_radio_last_lap",-99))<2:return {}
 var msg:String=""
 var reply:String=""
 if bool(obs.get("hot",false)) and float(obs.get("gap_s",999.0))<1.3:
  msg="Estou com pneus quentes seguindo este carro."
  reply="Entendido. Procure espaço nas curvas, sem mudar o plano de box."
 elif float(obs.get("congestion_run_s",0.0))>=8.0:
  msg="Estou preso em um trem de DRS." if bool(obs.get("drs_train",false)) else "Estou preso em um grupo de carros."
  if int(forecast.get("recommended_extend",0))>0 and not bool(forecast.get("protected",true)):reply="A projeção sugere avaliar uma janela mais livre; nenhuma ordem foi alterada."
  else:reply="Entendido. Avalie a próxima oportunidade e preserve os pneus."
 elif bool(obs.get("mate",false)) and float(obs.get("gap_s",999.0))<1.3 and float(obs.get("closing",0.0))>0.00002:
  msg="Tenho ritmo para pressionar o companheiro. Podemos avaliar a passagem?"
  reply="Vamos avaliar os tempos; nenhuma ordem de equipe foi emitida."
 elif int(obs.get("blue_behind",0))>0 or bool(obs.get("lapping_ahead",false)):
  msg="Temos tráfego de retardatários."
  reply="Mantenha a faixa segura e aguarde espaço."
 if msg.is_empty():return {}
 return {"lap":lap,"kind":"traffic_09201","message":"RADIO FICTICIO | %s: %s" % [str(car.get("name","Piloto")),msg],"reply":"ENGENHEIRO | %s: %s" % [str(car.get("name","Piloto")),reply]}
