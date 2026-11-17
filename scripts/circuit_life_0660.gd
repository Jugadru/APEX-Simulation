extends RefCounted
## Generic circuit campus; deterministic local placement, no sporting RNG.
static func material(color: Color, metal: float=0.0) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=0.78;m.metallic=metal
	return m
static func batch(parent: Node3D, label: String, mesh: Mesh, transforms: Array, mat: Material) -> void:
	if transforms.is_empty():return
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=transforms.size()
	for i in range(transforms.size()):mm.set_instance_transform(i,transforms[i])
	var node:=MultiMeshInstance3D.new();node.name=label;node.multimesh=mm;node.material_override=mat;parent.add_child(node)
static func boxes(parent: Node3D,label: String,transforms: Array,color: Color) -> void:
	var mesh:=BoxMesh.new();mesh.size=Vector3.ONE;batch(parent,label,mesh,transforms,material(color))
static func transform(pos: Vector3,size: Vector3,angle: float=0.0)->Transform3D:
	return Transform3D(Basis(Vector3.UP,angle).scaled(size),pos)
static func install(world) -> void:
	var campus:=Node3D.new();campus.name="CircuitLife0660";world.course_root.add_child(campus)
	var paving:Array=[];var halls:Array=[];var roofs:Array=[];var glass:Array=[];var vehicles:Array=[];var marks:Array=[]
	var centers:Array=world.road_centers
	for i in range(12,centers.size()-1,53):
		var side:Vector3=world.road_normals[i].normalized()
		var location:Vector3=centers[i]+side*48.0
		var safe:=true
		for j in range(centers.size()):
			if location.distance_squared_to(centers[j])<30.0*30.0:safe=false;break
		if not safe:continue
		var angle:=atan2(side.x,side.z)
		var basis:=Basis(Vector3.UP,angle)
		paving.append(transform(location+Vector3.UP*-0.10,Vector3(24,.05,22),angle))
		halls.append(transform(location+basis*Vector3(0,2.1,5),Vector3(16,4.3,7),angle))
		roofs.append(transform(location+basis*Vector3(0,4.32,5),Vector3(17,.22,8),angle))
		glass.append(transform(location+basis*Vector3(0,2.55,1.45),Vector3(14,1.5,.04),angle))
		for k in range(7):
			vehicles.append(transform(location+basis*Vector3(-9+k*2.8,.55,-6),Vector3(1.65,1.1,3.5),angle))
			marks.append(transform(location+basis*Vector3(-10+k*2.8,-.065,-6),Vector3(.08,.015,4.2),angle))
	boxes(campus,"ServiceAprons",paving,Color("#686b65"));boxes(campus,"HospitalityBuildings",halls,Color("#bdc0b7"))
	boxes(campus,"BuildingRoofs",roofs,Color("#424b50"));boxes(campus,"FacadeWindows",glass,Color("#3f6570"))
	boxes(campus,"ParkedVehicles",vehicles,Color("#73808c"));boxes(campus,"ParkingMarkings",marks,Color("#d0d0b8"))

static func pit_details(pit, teams: Array) -> void:
	var parent:=Node3D.new();parent.name="PitDetails0660";pit.add_child(parent)
	# Metadata also allows verification when a headless renderer does not
	# expose GPU-backed MultiMesh instance transforms.
	parent.set_meta("engineer_station_x", pit.GARAGE_FRONT_X - .50)
	var desks:Array=[];var screens:Array=[];var light:Array=[];var trousers:Array=[];var faces:Array=[];var headsets:Array=[]
	var uniforms:Array=[];var frames:Array=[]
	for slot in range(mini(12,teams.size())):
		var z:float=pit._slot_z(slot)
		# Front-facing consoles, door framing and pit-wall engineering station.
		frames.append(transform(Vector3(pit.GARAGE_FRONT_X-.15,2.0,z-1.52),Vector3(.3,3.8,.18)))
		light.append(transform(Vector3(pit.GARAGE_FRONT_X-.25,3.55,z),Vector3(.12,.08,2.6)))
		# 066724: the former X=2.5 placement put the pit engineers on the
		# raceway side of the pit-lane divider. Keep the console entirely on
		# the garage apron, beyond the service bay and facing the pit lane.
		var apron_x:float=pit.GARAGE_FRONT_X-.50
		desks.append(transform(Vector3(apron_x,.70,z),Vector3(.72,.13,2.0)))
		for k in [-.5,.5]:
			screens.append(transform(Vector3(apron_x-.28,1.10,z+k),Vector3(.08,.43,.6)))
			light.append(transform(Vector3(apron_x-.33,1.12,z+k),Vector3(.012,.29,.49)))
			uniforms.append(transform(Vector3(apron_x+.36,.92,z+k),Vector3(.36,.58,.35)))
			faces.append(transform(Vector3(apron_x+.36,1.36,z+k),Vector3(.25,.29,.26)))
			headsets.append(transform(Vector3(apron_x+.36,1.46,z+k),Vector3(.29,.07,.29)))
			for dz in [-.1,.1]:trousers.append(transform(Vector3(apron_x+.36,.35,z+k+dz),Vector3(.16,.56,.15)))
	boxes(parent,"EngineeringDesks",desks,Color("#3a454c"));boxes(parent,"MonitorFrames",screens,Color("#17202a"))
	boxes(parent,"ScreensAndDoorLights",light,Color("#9ec9cb"));boxes(parent,"EngineerUniforms",uniforms,Color("#d6d8d1"))
	boxes(parent,"EngineerTrousers",trousers,Color("#26333b"));boxes(parent,"Faces",faces,Color("#bd967d"))
	boxes(parent,"Headsets",headsets,Color("#161d21"));boxes(parent,"GarageFrames",frames,Color("#c0c5c6"))
