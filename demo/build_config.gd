@tool
extends EditorScript

var width = 640
var height = 300
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
	var BR: Vector3 = center_vec + Vector3(x/2,-y/2,0)
	var TL: Vector3 = center_vec + Vector3(-x/2,y/2,0)
	var centerBR = BR
	var centerTL = TL
	print(BR,TL)
	# fill out the template 
	var entry = data["walls"][0]
	var wall_template  = entry.duplicate(true)
	#print(data)
	
	var normal_vec = Vector3(0,0,1)
	data["walls"] = []
	#print(data)
	#print(entry)
	entry["size"] = size
	# set entry projector id in the middle to be half of the total number of projectors
	# then we will decrease as we fill in ones to the left
	# then we will increase from this as we go right
	var middle_projector_id =  floor(screens/2)
	entry["clients"][0]["projectors"][0]["id"] = middle_projector_id
	
	entry["bounds"]["bottom_right"] = [BR.x,BR.y,BR.z]
	entry["bounds"]["top_left"]	 = [TL.x,TL.y,TL.z]
	entry["clients"][0]["projectors"][0]["resolution"] = [width,height]
	entry["normal"] = [normal_vec.x,normal_vec.y,normal_vec.z]
	data["walls"].push_back(entry)
	
	print(normal_vec)
	# rotate clockwise
	var angle = deg_to_rad(90)
	var lhs_screens = floor(screens/2)
	for i in range(lhs_screens):
		entry = wall_template.duplicate(true)
		# rotate the wall vector also
		normal_vec = normal_vec.rotated(Vector3(0,1,0),angle)
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
	print(data)
	# write ou tthe result
	var ofile = FileAccess.open("res://godottd/calibration/auto_filled.json",FileAccess.WRITE)
	ofile.store_string(JSON.stringify(data))
	ofile.close()
	#for i in range(rhs_screens):
		
	# then we will do the ones that go the right from there
	pass
