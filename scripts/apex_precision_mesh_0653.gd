extends RefCounted
## Original parametric meshes. Explicit outward normals, shared indexed vertices.
static func surface(parent: Node3D, label: String, vertices: PackedVector3Array, normals: PackedVector3Array, uv: PackedVector2Array, indices: PackedInt32Array, material: Material) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = material
	parent.add_child(part)
	return part

static func sample(sections: Array[Vector4], t: float) -> Vector4:
	var coordinate := clampf(t,0.0,1.0)*float(sections.size()-1)
	var i := mini(int(coordinate),sections.size()-2)
	var u := coordinate-float(i)
	var a := sections[maxi(0,i-1)]
	var b := sections[i]
	var c := sections[i+1]
	var d := sections[mini(sections.size()-1,i+2)]
	var v := 0.5*((b*2.0)+(-a+c)*u+(a*2.0-b*5.0+c*4.0-d)*u*u+(-a+b*3.0-c*3.0+d)*u*u*u)
	# Longitudinal coordinate remains monotonic even at a sharp tip.
	v.x = lerpf(b.x,c.x,u)
	v.y = maxf(0.004,v.y)
	v.w = maxf(v.z+0.006,v.w)
	return v

static func loft(parent: Node3D, label: String, sections: Array[Vector4], material: Material, offset: Vector3 = Vector3.ZERO, exponent: float = 0.75) -> MeshInstance3D:
	var rings := (sections.size()-1)*5+1
	var radial := 32
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(rings):
		var p := sample(sections,float(i)/float(rings-1))
		for j in range(radial):
			var angle := TAU*float(j)/radial
			var x := signf(sin(angle))*pow(absf(sin(angle)),exponent)*p.y
			var y := signf(cos(angle))*pow(absf(cos(angle)),exponent)*(p.w-p.z)*0.5+(p.w+p.z)*0.5
			verts.append(Vector3(x,y,p.x)+offset)
			uv.append(Vector2(float(j)/radial,float(i)/float(rings-1)))
	for i in range(rings):
		for j in range(radial):
			var along := verts[mini(i+1,rings-1)*radial+j]-verts[maxi(0,i-1)*radial+j]
			var around := verts[i*radial+(j+1)%radial]-verts[i*radial+(j+radial-1)%radial]
			normals.append(along.cross(around).normalized())
			if i < rings-1:
				var a := i*radial+j
				var b := i*radial+(j+1)%radial
				indices.append_array(PackedInt32Array([a,b,a+radial,b,b+radial,a+radial]))
	# Close the end rings without pulling side normals towards the cap.
	for end in [0,rings-1]:
		var center := Vector3.ZERO
		for j in range(radial): center += verts[end*radial+j]
		center /= radial
		var normal := Vector3(0,0,-1 if end == 0 else 1)
		for j in range(radial):
			var start := verts.size()
			for point in [center,verts[end*radial+j],verts[end*radial+(j+1)%radial]]:
				verts.append(point)
				normals.append(normal)
				uv.append(Vector2.ZERO)
			indices.append_array(PackedInt32Array([start,start+1,start+2]))
	return surface(parent,label,verts,normals,uv,indices,material)

static func tire(parent: Node3D, width: float, material: Material) -> MeshInstance3D:
	var h := width*0.5
	var profile: Array[Vector2] = [Vector2(-h,0.215),Vector2(-h-0.008,0.275),Vector2(-h*0.92,0.335),Vector2(-h*0.64,0.365),Vector2(0,0.37),Vector2(h*0.64,0.365),Vector2(h*0.92,0.335),Vector2(h+0.008,0.275),Vector2(h,0.215),Vector2(h*0.65,0.202),Vector2(-h*0.65,0.202)]
	var segments := 48
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(profile.size()):
		var slope := profile[(i+1)%profile.size()]-profile[(i+profile.size()-1)%profile.size()]
		for j in range(segments):
			var a := TAU*float(j)/segments
			verts.append(Vector3(profile[i].x,cos(a)*profile[i].y,sin(a)*profile[i].y))
			normals.append(Vector3(-slope.y,cos(a)*slope.x,sin(a)*slope.x).normalized())
			uv.append(Vector2(float(i)/profile.size(),float(j)/segments))
			var next := (i+1)%profile.size()
			var b := i*segments+j
			var c := i*segments+(j+1)%segments
			var d := next*segments+j
			var e := next*segments+(j+1)%segments
			indices.append_array(PackedInt32Array([b,c,d,c,e,d]))
	return surface(parent,"RoundedSlick",verts,normals,uv,indices,material)

static func foil(parent: Node3D, label: String, span: float, chord: float, thickness: float, at: Vector3, material: Material) -> MeshInstance3D:
	var profiles: Array[Vector4] = [Vector4(-span*0.5,chord*0.34,-thickness*0.3,thickness*0.3),Vector4(-span*0.43,chord*0.5,-thickness*0.5,thickness*0.5),Vector4(span*0.43,chord*0.5,-thickness*0.5,thickness*0.5),Vector4(span*0.5,chord*0.34,-thickness*0.3,thickness*0.3)]
	var mesh := loft(parent,label,profiles,material,Vector3.ZERO,0.8)
	mesh.rotation.y = PI*0.5
	mesh.position = at
	return mesh

static func cockpit_rim(parent: Node3D, material: Material) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for j in range(64):
		var a := TAU*float(j)/64.0
		for i in range(8):
			var b := TAU*float(i)/8.0
			verts.append(Vector3(sin(a)*(0.37+cos(b)*0.045),0.88+sin(b)*0.04,cos(a)*(0.55+cos(b)*0.045)-0.13))
			normals.append(Vector3(sin(a)*cos(b),sin(b),cos(a)*cos(b)).normalized())
			uv.append(Vector2(float(j)/64.0,float(i)/8.0))
			var n := (j+1)%64
			var k := (i+1)%8
			indices.append_array(PackedInt32Array([j*8+i,j*8+k,n*8+i,j*8+k,n*8+k,n*8+i]))
	return surface(parent,"OpenCockpitCoaming",verts,normals,uv,indices,material)
