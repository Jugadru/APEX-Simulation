extends SceneTree
const C=preload("res://scripts/core/race_tactical_coordination_091712.gd")
var failures:Array[String]=[]
var checks:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);printerr("COORDINATION_FAIL ",label)
func intent(lane:float,goal:float,state:String="clear",rival:int=-1)->Dictionary:
 return {"lane":lane,"goal":goal,"committed_goal":goal,"state":state,"defender_id":rival,"defending":-1,"defense_line":lane,"defense_event":false,"pace":100.0,"event":"attack" if state in C.ATTACK else "","side":"left","margin":0.0}
func run():
 var driver={"race_lane":.6,"race_defending_against":2,"race_defense_line":0.0,"combat_state":"attacking","racecraft_memory":{"attack_target":7,"attack_side":"left"}}
 check(C.side_locked(driver,7),"active side lock")
 check(not C.side_locked(driver,8),"new target not locked")
 driver.combat_state="closing"
 check(not C.side_locked(driver,7),"stale lock released after abort")
 check(C.defense_goal(driver,2,25,.8,2.95)==0.0,"zero is a valid prior defensive line")
 check(C.defense_goal(driver,2,8,-.8,2.95)==.6,"no late defensive move")
 check(C.defense_goal(driver,3,25,.8,2.95)==.8,"new early defense")
 var order=[{"id":0},{"id":1},{"id":2}]
 var intents={0:intent(0,0),1:intent(0,-2.95,"preparing",0),2:intent(0,-2.95,"preparing",1)}
 intents[1].goal=0.0
 intents[1].defending=2
 intents[1]["defense_origin"]="attack"
 var reverse:Dictionary=intents.duplicate(true)
 C.resolve(order,intents)
 C.resolve([order[2],order[0],order[1]],reverse)
 check(intents==reverse,"reconciliation order independent")
 check(intents[1].state=="preparing" and intents[1].goal==-2.95,"front attack not overwritten by rear defense")
 check(intents[2].state=="closing" and intents[2].event=="" and intents[2].defender_id==-1,"conflicting rear attack cancelled without phantom event")
 check(is_equal_approx(float(intents[2].pace),99.78) and is_equal_approx(float(intents[1].pace),99.92),"paired cost refunded")
 var clear={0:intent(0,0),1:intent(0,-2.95,"preparing",0),2:intent(0,2.95,"preparing",1)}
 C.resolve(order,clear)
 check(clear[1].state=="preparing" and clear[2].state=="preparing","compatible chain survives")
 var blue={0:intent(0,0),1:intent(0,0,"preparing",0)}
 blue[0].defending=1;blue[0]["defense_origin"]="blue_flag"
 C.resolve(order.slice(0,2),blue)
 check(blue[0].defending==1,"blue flag remains intact")
 print("COORDINATION_REPORT ",JSON.stringify({"checks":checks,"failures":failures}))
 if failures.is_empty():print("COORDINATION_091712_PASS")
 quit(0 if failures.is_empty() else 1)
