@tool
extends EditorScript
#939 1796
var width = 1800.0
var height = 350.0
var swidth = 640.0
var sheight = 360.0
var horizontal 
# set the number of screens we are making
var screens = 3
# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var filename = "res://godottd/calibration/template.json"
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		print("Failed to read calibration file '"+filename+"'!")
		
	var json = JSON.new()
	json.parse(file.get_as_text())
	var data = json.data
	file.close()
	
	var ratio = width/height
	var x=0
	var y =0
	if ratio < 1:
		ratio = height/width
		x = 1.0
		y=ratio
		horizontal = false
		
	else:
		x = ratio
		y =1.0
		horizontal = true
	# take half of the components
	var size = [x,y]

	# start with screen on our left, what's in the template file anyways	
	var center_vec = Vector3(0,0,0)
	# bottom right and top left
	var BR: Vector3 = center_vec + Vector3(x/2,-y/2,-x/2)
	var TL: Vector3 = center_vec + Vector3(-x/2,y/2,-x/2)
	var centerBR = BR
	var centerTL = TL
	#print(BR,TL)
	# fill out the template 
	var entry = data["walls"][0]
	var wall_template  = entry.duplicate(true)
	#print(data)
	
	var normal_vec = Vector3(0,0,1)
	data["walls"] = []
	#print(data)
	#print(entry)
	entry["size"] = size
	print("size is ",size)
	# set entry projector id in the middle to be half of the total number of projectors
	# then we will decrease as we fill in ones to the left
	# then we will increase from this as we go right
	var middle_projector_id =  floor(screens/2)
	entry["clients"][0]["projectors"][0]["id"] = middle_projector_id
	
	entry["bounds"]["bottom_right"] = [BR.x,BR.y,BR.z]
	entry["bounds"]["top_left"]	 = [TL.x,TL.y,TL.z]
	print([BR.x,BR.y,BR.z])
	print( [TL.x,TL.y,TL.z])
	
	entry["clients"][0]["projectors"][0]["resolution"] = [width,height]
	entry["normal"] = [normal_vec.x,normal_vec.y,normal_vec.z]
	data["walls"].push_back(entry)
	
	#print(normal_vec)
	# rotate clockwise
	var angle = deg_to_rad(90)
	var lhs_screens = floor(screens/2)
	for i in range(lhs_screens):
		entry = wall_template.duplicate(true)
		# rotate the wall vector also
		normal_vec = normal_vec.rotated(Vector3(0,1,0),angle)
		# TODO why does preventing this from being -0 keep the scene from being shown upsidown?
		normal_vec.z =0
		BR = BR.rotated(Vector3(0,1,0),angle)	
		TL = TL.rotated(Vector3(0,1,0),angle)
		entry["normal"] = [normal_vec.x,normal_vec.y,normal_vec.z]
		entry["size"] = size
		entry["bounds"]["bottom_right"] = [BR.x,BR.y,BR.z]
		entry["bounds"]["top_left"]	 = [TL.x,TL.y,TL.z]
		entry["clients"][0]["projectors"][0]["resolution"] = [width,height]
		# must subtract by non zero numbers from the middle projector id
		entry["clients"][0]["projectors"][0]["id"] = middle_projector_id -(i+1)
		data["walls"].push_back(entry)
	var rhs_screens = floor(screens/2)
	angle=-angle
	# reset the normal, TL and BR
	normal_vec= Vector3(0,0,1)
	TL = centerTL
	BR = centerBR
	for i in range(rhs_screens):
		entry = wall_template.duplicate(true)
		# rotate the wall vector also
		normal_vec = normal_vec.rotated(Vector3(0,1,0),angle)
		normal_vec.z =0

		BR = BR.rotated(Vector3(0,1,0),angle)	
		TL = TL.rotated(Vector3(0,1,0),angle)
		entry["normal"] = [normal_vec.x,normal_vec.y,normal_vec.z]
		entry["size"] = size
		entry["bounds"]["bottom_right"] = [BR.x,BR.y,BR.z]
		entry["bounds"]["top_left"]	 = [TL.x,TL.y,TL.z]
		entry["clients"][0]["projectors"][0]["resolution"] = [width,height]
		# must add by non zero numbers from the middle projector id
		entry["clients"][0]["projectors"][0]["id"] = middle_projector_id +(i+1)
		data["walls"].push_back(entry)
	#print(data)
	# write ou tthe result
	var ofile = FileAccess.open("res://godottd/calibration/auto_filled.json",FileAccess.WRITE)
	ofile.store_string(JSON.stringify(data))
	ofile.close()
	#for i in range(rhs_screens):
	# update the custom run arguments
	var config_options = ConfigFile.new()
	config_options.load("res://.godot/editor/project_metadata.cfg")
	print(config_options.get_value("debug_options","run_instances_config"))
	# update the number of instances we will make , the +1 is because we need a server in the mix
	config_options.set_value("debug_options","run_instance_count",float(screens +1))
	var instance_config = config_options.get_value("debug_options","run_instances_config")
	# get one copy of the launch dict that we can modify in loop
	var instance_template = instance_config[0].duplicate(true)
	# reset the instance_config
	instance_config =[]
	print("template",instance_template)
	# always make sure there's a server process in there 
	var server_config = instance_template.duplicate(true)
	server_config["arguments"] = "0 320 -1 %d %d 0" % [swidth,sheight]
	instance_config.push_back(server_config)
	
	# now iter over the remaining screens and make a launch instance for each of them
	# assume we are listing from far left to right passing through the middle
	var xanchor = 0
	var yanchor =0
	for i in range(screens):
		server_config = instance_template.duplicate(true)
		# here we are just placing them horizontally, if we needed to have things shift down by a certain amount in y, we could wrap on the i value
		server_config["arguments"] = "%d %d %d %d %d 0" % [xanchor, yanchor+height*i,i, width,height]
		instance_config.push_back(server_config)
	
	config_options.set_value("debug_options","run_instances_config",instance_config)
	config_options.save("res://.godot/editor/project_metadata.cfg")
	# then we will do the ones that go the right from there
	pass
