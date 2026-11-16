extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Stint = preload("res://scripts/core/race_stint_optimizer.gd")
func _initialize():call_deferred("run")
func run():
    var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track:Dictionary={}
    for t in data.tracks:
        if str(t.code)=="ITA": track=t.duplicate(true)
    var e=Race.new(data.teams,"Ferrari",660,{},track,{})
    e.configure_weather("Seco")
    var cases:Array=[]
    var begin:int=Time.get_ticks_usec()
    for car in e.cars:
        var output:Dictionary=Stint.optimize(car,e.lap_count,e.available_pit_compounds(),e.tyre_specs,e.pit_loss)
        cases.append({"id":car.id,"result":output})
    var delta:int=Time.get_ticks_usec()-begin
    var result:Dictionary={"ms_total_24":float(delta)/1000.0,"cases":cases}
    var path:String=OS.get_environment("APEX_RESULT_PATH")
    if path != "":
        var f=FileAccess.open(path,FileAccess.WRITE)
        f.store_string(JSON.stringify(result,"  "))
        f.close()
    print("STINT_BENCH ",JSON.stringify({"ms_total_24":result.ms_total_24,"count":cases.size(),"first":cases[0]}))
    quit(0)
