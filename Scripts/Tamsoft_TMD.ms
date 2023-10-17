-- Tamsoft TMD PC/Vita/PS3 model importer by Random Talking Bush.
-- Works with Hyperdimension Neptunia PP, U, MegaTagmension Blanc, Senran Kagura: Shinovi/Estival Versus and Natsurio High School.
-- Updated April 4th, 2017:
-- Fixed models with over 65535 vertex points not importing.
-- Fixed models with three UV mapping layers not importing correctly.
-- Updated April 1st, 2017:
-- Added support for Senran Kagura: Estival Versus (both Vita and PC versions).
-- Changed bone numbers to bone checksums instead.
-- Added a ton of replacement bone names to replace the checksums, don't expect hair bones (especially SK's) to be named correctly. It'll default to checksums if it's unlisted or if "BoneRename" below is set to 0.
-- Optimized polygon group importing a bit so things will load a bit faster.
-- Fixed rigging being broken in one way or another for newer 3DS Max versions.

BoneRename = 1

fn convertTo32 input16 = (
	inputAsInt = input16
	sign = bit.get inputAsInt 16
	exponent = (bit.shift (bit.and inputAsInt (bit.hexasint "7C00")) -10) as integer - 16
	fraction = bit.and inputAsInt (bit.hexasint "03FF")
	if sign==true then sign = 1 else sign = 0
	exponentF = exponent + 127
	--Output 32 bit integer representing a 32 bit float
	outputAsFloat = bit.or (bit.or (bit.shift fraction 13) (bit.shift exponentF 23)) (bit.shift sign 31)
	--Output Check	
	return bit.intasfloat outputasfloat
)

fn floatSwap2 f = 
(
	i = bit.floatAsInt f
	h = bit.intashex i
	while h.count < 8 do h = "0" + h
	
	s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
	bit.intAsFloat (bit.hexasint s)
)

fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)

fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)

fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
)

fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)

rollout TamsoftImporter "Tamsoft TMD model importer" width:390 height:165
(
	button btnImport "Import Model" pos:[8,8] width:375 height:40

	label lblGame "Game:" pos:[8,50] width:30 height:15
	radiobuttons tglGame labels:#("Default","Senran Kagura: EV (PC)","SK: EV (Vita)") pos:[45,50]
	label lblNote "(Use Default if you're not importing from Senran Kagura: Estival Versus.)" pos:[8,65] width:350 height:15
	label lblDisclaimer "This script was written by Random Talking Bush, if you use it, please remember to give me thanks for this. If something doesn't work right, please contact me on The VG Resource (Random Talking Bush), Twitter, Tumblr or Steam (RandomTBush) and let me know, and I'll try to fix it." pos:[8,85] width:375 height:80
	label lblUpdate "(Updated 04/04/2017)" pos:[8,145] width:375 height:15
	checkbox tglColorDisable "Disable vertex colours?" pos:[250,145] width:150 height:15 tooltip: "If you'd rather not import the vertex colouring, enable this." checked: true

	on btnImport pressed do(
	fname = getOpenFileName \ 
	caption:"Tamsoft TMD0 file" \
	types:"Tamsoft model files (*.TMD)|*.TMD" \
	historyCategory:"NeptuniaU"

	if fname != undefined do(
	f = fopen fname "rb"
	clearlistener()
	st = timestamp() --get start time in milliseconds

	BoneHash_array = #()
	BoneParent_array = #()
	BonePos_array = #()
	BoneArray = #()
	PolyGroupAmount_array = #()
	PolyGroupAdd_array = #()
	RigIDCount_array = #()
	RigIDStart_array = #()
	RigBone_array = #()
	Face_array = #()
	Face_array2 = #()
	Vert_array = #()
	Normal_array = #()
	UV_array = #()
	UV2_array = #()
	UV3_array = #()
	Color_array = #()
	Alpha_array = #()
	W1_array = #()
	B1_array = #()
	Weight_array = #()

	struct Bone_Info_Struct
	(
		Bone1, Bone2, Bone3, Bone4
	)
	struct ActualBoneInfo_Struct
	(
		Bone1, Bone2, Bone3, Bone4
	)
	struct Weight_Info_Struct
	(
		Weight1, Weight2, Weight3, Weight4
	)
	struct weight_data
	(
		boneids, weights
	)

	local GameType = tglGame.state
	local colordisable = tglColorDisable.checked
	fseek f 0x00 #seek_set

	CommandsStart = #()
	PolyGroupStart = #()
	FaceStart = #()
	VertexStart = #()
	RigStart = #()
	RigBStart = #()
	BoneStart = #()
	BoneHierarchyStart = #()

	CommandsCount = #()
	PolyGroupCount = #()
	FaceCount = #()
	VertexCount = #()
	RigCount = #()
	RigBCount = #()
	BoneCount = #()
	BoneHierarchyCount = #()

	TMD0 = readlong f #unsigned

	if TMD0 == 0x30646D74 or TMD0 == 0x76646D74 do(
	Unknown1 = readshort f #unsigned
	VertFormat = readbyte f #unsigned
	VertFormat2 = readbyte f #unsigned
	-- print ("Vertex Format: 0x"+((bit.intAsHex(VertFormat))as string) + " " + ((bit.intAsHex(VertFormat2))as string))

	Unknown3 = readshort f #unsigned
	Unknown4 = readshort f #unsigned
	Unknown5 = readshort f #unsigned
	Unknown6 = readshort f #unsigned

	BoundMinX = readfloat f
	BoundMinY = readfloat f
	BoundMinZ = readfloat f
	BoundMaxX = readfloat f
	BoundMaxY = readfloat f
	BoundMaxZ = readfloat f

	if GameType == 1 do(
	UnknownStart1 = readlong f #unsigned
	UnknownCount1 = readlong f #unsigned

	CommandsStart = readlong f #unsigned
	CommandsCount = readlong f #unsigned
	UnknownStart2 = readlong f #unsigned
	UnknownCount2 = readlong f #unsigned

	RigStart = readlong f #unsigned
	RigCount = readlong f #unsigned
	ShaderStart = readlong f #unsigned
	ShaderCount = readlong f #unsigned

	PolyGroupStart = readlong f #unsigned
	PolyGroupCount = readlong f #unsigned
	FaceStart = readlong f #unsigned
	FaceCount = readlong f #unsigned

	VertexCount = readlong f #unsigned
	VertexStart = readlong f #unsigned
	if TMD0 != 0x76646D74 do(
	UnknownOff1 = readlong f #unsigned
	UnknownOff2 = readlong f #unsigned

	UnknownOff3 = readlong f #unsigned
	UnknownOff4 = readlong f #unsigned
	UnknownOff5 = readlong f #unsigned
	UnknownOff6 = readlong f #unsigned

	UnknownOff7 = readlong f #unsigned
	)
	BoneStart = readlong f #unsigned
	BoneCount = readlong f #unsigned
	BoneHierarchyStart = readlong f #unsigned

	BoneHierarchyCount = readlong f #unsigned
	TexInfoStart = readlong f #unsigned
	TexInfoCount = readlong f #unsigned
	if TMD0 != 0x76646D74 do(
	Blank = readlong f #unsigned
	)

	fseek f RigStart #seek_set
	-- print ("Rig Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + RigCount as string)
	for g = 1 to RigCount do(
			RigIDCount = readlong f
			for h = 1 to 32 do(
			RigBone = readlong f + 1
			if h <= RigIDCount then
				append RigBone_array RigBone
			else
				append RigBone_array undefined
			)
	)
	-- print ("Rig End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f PolyGroupStart #seek_set
	-- print ("PolyGroup Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + PolyGroupCount as string)
	for g = 1 to PolyGroupCount do(
	PolyGroupAmount = readshort f #unsigned
	PolyGroupUnknown = readshort f #unsigned
	PolyGroupAdd = readlong f #unsigned
	append PolyGroupAmount_array PolyGroupAmount
	append PolyGroupAdd_array PolyGroupAdd
	)
	-- print ("PolyGroup End: 0x"+((bit.intAsHex(ftell f))as string))

	)

	if GameType > 1 do(
	Unknown1Start = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	Blank = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	Blank = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	CommandsStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	Unknown2Start = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	Unknown3Start = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	Unknown4Start = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	Blank = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	PolyGroupStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	FaceStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	Unknown5Start = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	Blank = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	Unknown6Start = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	VertexStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	Blank = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	Blank = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)

	Unknown1Count = readlong f #unsigned
	Blank = readlong f #unsigned
	Blank = readlong f #unsigned
	CommandsCount = readlong f #unsigned
	Unknown2Count = readlong f #unsigned
	Unknown3Count = readlong f #unsigned
	Unknown4Count = readlong f #unsigned
	Blank = readlong f #unsigned
	PolyGroupCount = readlong f #unsigned
	FaceCount = readlong f #unsigned
	Unknown5Count = readlong f #unsigned
	Blank = readlong f #unsigned
	Unknown6Count = readlong f #unsigned
	VertexCount = readlong f #unsigned

	RigStart = 0
	RigBStart = 0
	BoneStart = 0
	BoneHierarchyStart = 0
	RigCount = 0
	RigBCount = 0
	BoneCount = 0
	BoneHierarchyCount = 0

	if VertFormat2 != 0x10 and VertFormat2 != 0x50 do(
	RigStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	RigBStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	BoneStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	BoneHierarchyStart = readlong f #unsigned
	if GameType == 2 do(Padding64Bit = readlong f #unsigned)
	RigCount = readlong f #unsigned
	RigBCount = readlong f #unsigned
	BoneCount = readlong f #unsigned
	BoneHierarchyCount = readlong f #unsigned
	)

	fseek f RigStart #seek_set
	-- print ("Rig Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + RigCount as string)
	for g = 1 to RigCount do(
			RigIDCount = readlong f #unsigned
			if GameType == 2 do(Padding64Bit = readlong f #unsigned)
			RigIDAdd = readlong f #unsigned
			if GameType == 2 do(Padding64Bit = readlong f #unsigned)
			RigRet = (ftell f)

			fseek f RigBStart #seek_set
			fseek f RigIDAdd #seek_cur

			for h = 1 to 32 do(
			RigBone = (readbyte f #unsigned) + 1
			if h <= RigIDCount then
				append RigBone_array RigBone
			else
				append RigBone_array undefined
			)
			fseek f RigRet #seek_set
	)
	-- print ("Rig End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f PolyGroupStart #seek_set
	-- print ("PolyGroup Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + PolyGroupCount as string)
	for g = 1 to PolyGroupCount do(
	PolyGroupAmount = readlong f #unsigned
	if GameType == 2 do(PolyGroupUnknown = readlong f #unsigned)
	PolyGroupAdd = readlong f #unsigned
	if GameType == 2 do(Blank = readlong f #unsigned)
	append PolyGroupAmount_array PolyGroupAmount
	append PolyGroupAdd_array PolyGroupAdd
	)
	-- print ("PolyGroup End: 0x"+((bit.intAsHex(ftell f))as string))

	)

	fseek f VertexStart #seek_set
	-- print ("Vertex Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertexCount as string)
	for g = 1 to VertexCount do(
	if VertFormat == 0x61 and VertFormat2 == 0x00 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = 1
	weight2 = 0
	weight3 = 0
	weight4 = 0
	bone1 = 1
	bone2 = 1
	bone3 = 1
	bone4 = 1
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = 0
	tv = 0
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0x65 and VertFormat2 == 0x00 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = 1
	weight2 = 0
	weight3 = 0
	weight4 = 0
	bone1 = 1
	bone2 = 1
	bone3 = 1
	bone4 = 1
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0x65 and VertFormat2 == 0x05 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = 1
	weight2 = 0
	weight3 = 0
	weight4 = 0
	bone1 = 1
	bone2 = 1
	bone3 = 1
	bone4 = 1
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0x65 and VertFormat2 == 0x0D do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xC7 and VertFormat2 == 0x05 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = 1
	weight2 = 0
	weight3 = 0
	weight4 = 0
	bone1 = 1
	bone2 = 1
	bone3 = 1
	bone4 = 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [255,255,255]
	append Alpha_array 255
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xC7 and VertFormat2 == 0x0D do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [255,255,255]
	append Alpha_array 255
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xCF and VertFormat2 == 0x0D do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	tu2 = readshort f as float / 1024
	tv2 = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [255,255,255]
	append Alpha_array 255
	append UV_array [tu,tv,0]
	append UV2_array [tu2,tv2,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xE7 and VertFormat2 == 0x00 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = 1
	weight2 = 0
	weight3 = 0
	weight4 = 0
	bone1 = 1
	bone2 = 1
	bone3 = 1
	bone4 = 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xE7 and VertFormat2 == 0x08 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xE7 and VertFormat2 == 0x0D do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xEF and VertFormat2 == 0x08 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	tu2 = readshort f as float / 1024
	tv2 = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append UV2_array [tu2,tv2,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)

	-- Estival Versus formats:
	if VertFormat == 0x97 and VertFormat2 == 0x10 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = 1
	weight2 = 0
	weight3 = 0
	weight4 = 0
	bone1 = 1
	bone2 = 1
	bone3 = 1
	bone4 = 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0x97 and VertFormat2 == 0x34 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0x97 and VertFormat2 == 0x74 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xB7 and VertFormat2 == 0x34 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	tu2 = readshort f as float / 1024
	tv2 = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append UV2_array [tu2,tv2,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0x9F and VertFormat2 == 0x50 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = 1
	weight2 = 0
	weight3 = 0
	weight4 = 0
	bone1 = 1
	bone2 = 1
	bone3 = 1
	bone4 = 1	
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	nx2 = readbyte f
	ny2 = readbyte f
	nz2 = readbyte f
	nq2 = readbyte f
	nx3 = readbyte f
	ny3 = readbyte f
	nz3 = readbyte f
	nq3 = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0x9F and VertFormat2 == 0x74 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	nx2 = readbyte f
	ny2 = readbyte f
	nz2 = readbyte f
	nq2 = readbyte f
	nx3 = readbyte f
	ny3 = readbyte f
	nz3 = readbyte f
	nq3 = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xBF and VertFormat2 == 0x74 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	nx2 = readbyte f
	ny2 = readbyte f
	nz2 = readbyte f
	nq2 = readbyte f
	nx3 = readbyte f
	ny3 = readbyte f
	nz3 = readbyte f
	nq3 = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	tu2 = readshort f as float / 1024
	tv2 = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append UV2_array [tu2,tv2,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xBF and VertFormat2 == 0x7C do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	nx2 = readbyte f
	ny2 = readbyte f
	nz2 = readbyte f
	nq2 = readbyte f
	nx3 = readbyte f
	ny3 = readbyte f
	nz3 = readbyte f
	nq3 = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	tu2 = readshort f as float / 1024
	tv2 = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append UV2_array [tu2,tv2,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	if VertFormat == 0xFF and VertFormat2 == 0x74 do(
	vx = Readfloat f
	vy = Readfloat f
	vz = Readfloat f
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
	nq = readbyte f
	nx2 = readbyte f
	ny2 = readbyte f
	nz2 = readbyte f
	nq2 = readbyte f
	nx3 = readbyte f
	ny3 = readbyte f
	nz3 = readbyte f
	nq3 = readbyte f
	colorb = readbyte f #unsigned
	colorg = readbyte f #unsigned
	colorr = readbyte f #unsigned
	colora = (readbyte f #unsigned) as float / 255	
	tu = readshort f as float / 1024
	tv = ((readshort f as float / 1024) * -1) + 1
	tu2 = readshort f as float / 1024
	tv2 = ((readshort f as float / 1024) * -1) + 1
	tu3 = readshort f as float / 1024
	tv3 = ((readshort f as float / 1024) * -1) + 1
	append Vert_array [vx,vy,vz]
	append Color_array [colorr,colorg,colorb]
	append Alpha_array colora
	append UV_array [tu,tv,0]
	append UV2_array [tu2,tv2,0]
	append UV3_array [tu3,tv3,0]
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	)
	-- print ("Vertex End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f FaceStart #seek_set
	-- print ("Face Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + FaceCount as string)
	for g = 1 to FaceCount do(
	if VertFormat2 == 0x7C then(
	f1 = Readlong f #unsigned + 1
	f2 = Readlong f #unsigned + 1
	f3 = Readlong f #unsigned + 1
	append Face_array [(f1),(f2),(f3)]
	) else if VertFormat2 != 0x7C do(
	f1 = Readshort f #unsigned + 1
	f2 = Readshort f #unsigned + 1
	f3 = Readshort f #unsigned + 1
	append Face_array [(f1),(f2),(f3)]
	)
	)
	-- print ("Face End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f BoneHierarchyStart #seek_set
	-- print ("Bone Hierarchy Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + BoneHierarchyCount as string)
	for b = 1 to BoneHierarchyCount do(
	BoneHash = bit.intAsHex(readlong f #unsigned)
	BoneHX = readfloat f
	BoneHY = readfloat f
	BoneHZ = readfloat f
	BoneParent = readlong f
	BoneH0 = readlong f #unsigned
	append BoneHash_array BoneHash
	append BoneParent_array BoneParent
	append BonePos_array [BoneHX,BoneHY,BoneHZ]
	)
	-- print ("Bone Hierarchy End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f BoneStart #seek_set
	-- print ("Bone Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + BoneCount as string)
	for b = 1 to BoneCount do(
	BoneName = ("Bone " + BoneHash_array[b] as string)

	case of (
		-- I spent way too much time on this.
		(BoneHash_array[b] == "99dc9c9c"):(BoneName = "Point")
		(BoneHash_array[b] == "3e91886e"):(BoneName = "Point 2")
		(BoneHash_array[b] == "b8d2b110"):(BoneName = "Point 3")
		(BoneHash_array[b] == "d0c5e164"):(BoneName = "Root")
		(BoneHash_array[b] == "d8a80b17"):(BoneName = "Spine 1")
		(BoneHash_array[b] == "b558fee4"):(BoneName = "Spine 2")
		(BoneHash_array[b] == "f9a068c5"):(BoneName = "Spine 3")
		(BoneHash_array[b] == "ca6ca12d"):(BoneName = "Left Chest") -- Nep
		(BoneHash_array[b] == "6dee1790"):(BoneName = "Left Chest") -- SK
		(BoneHash_array[b] == "1ae92706"):(BoneName = "Left Chest 2")
		(BoneHash_array[b] == "30639c4e"):(BoneName = "Right Chest") -- Nep
		(BoneHash_array[b] == "7b5699ea"):(BoneName = "Right Chest") -- SK
		(BoneHash_array[b] == "c51a97c"):(BoneName = "Right Chest 2")
		(BoneHash_array[b] == "8e379e18"):(BoneName = "Neck")
		(BoneHash_array[b] == "9d5bed7"):(BoneName = "Head")

		(BoneHash_array[b] == "88904661"):(BoneName = "Left Clavicle")
		(BoneHash_array[b] == "503c29f6"):(BoneName = "Left Upper Arm")
		(BoneHash_array[b] == "b08d4b96"):(BoneName = "Left Upper Arm Twist")
		(BoneHash_array[b] == "c78a7b00"):(BoneName = "Left Upper Arm Twist B")
		(BoneHash_array[b] == "f05f6360"):(BoneName = "Left Forearm")
		(BoneHash_array[b] == "bce1f26a"):(BoneName = "Left Forearm Twist")
		(BoneHash_array[b] == "40c29f3b"):(BoneName = "Left Hand")
		(BoneHash_array[b] == "cbe6c2fc"):(BoneName = "Left Wrist")
		(BoneHash_array[b] == "865e6a91"):(BoneName = "Left Finger Thumb 1")
		(BoneHash_array[b] == "f1595a07"):(BoneName = "Left Finger Thumb 2")
		(BoneHash_array[b] == "68500bbd"):(BoneName = "Left Finger Thumb 3")
		(BoneHash_array[b] == "949ac9bd"):(BoneName = "Left Finger Index Metacarpal")
		(BoneHash_array[b] == "8418d4c8"):(BoneName = "Left Finger Index 1")
		(BoneHash_array[b] == "f31fe45e"):(BoneName = "Left Finger Index 2")
		(BoneHash_array[b] == "6a16b5e4"):(BoneName = "Left Finger Index 3")
		(BoneHash_array[b] == "85dabeff"):(BoneName = "Left Finger Middle 1")
		(BoneHash_array[b] == "f2dd8e69"):(BoneName = "Left Finger Middle 2")
		(BoneHash_array[b] == "6bd4dfd3"):(BoneName = "Left Finger Middle 3")
		(BoneHash_array[b] == "e39df92b"):(BoneName = "Left Finger Ring Metacarpal")
		(BoneHash_array[b] == "8095a87a"):(BoneName = "Left Finger Ring 1")
		(BoneHash_array[b] == "f79298ec"):(BoneName = "Left Finger Ring 2")
		(BoneHash_array[b] == "6e9bc956"):(BoneName = "Left Finger Ring 3")
		(BoneHash_array[b] == "8157c24d"):(BoneName = "Left Finger Pinky 1")
		(BoneHash_array[b] == "f650f2db"):(BoneName = "Left Finger Pinky 2")
		(BoneHash_array[b] == "6f59a361"):(BoneName = "Left Finger Pinky 3")
		(BoneHash_array[b] == "f5c19111"):(BoneName = "Left Weapon")
		(BoneHash_array[b] == "729f7b02"):(BoneName = "Right Clavicle")
		(BoneHash_array[b] == "aa331495"):(BoneName = "Right Upper Arm")
		(BoneHash_array[b] == "8951287d"):(BoneName = "Right Upper Arm Twist")
		(BoneHash_array[b] == "fe5618eb"):(BoneName = "Right Upper Arm Twist B")
		(BoneHash_array[b] == "a505e03"):(BoneName = "Right Forearm")
		(BoneHash_array[b] == "853d9181"):(BoneName = "Right Forearm Twist")
		(BoneHash_array[b] == "bacda258"):(BoneName = "Right Hand")
		(BoneHash_array[b] == "f23aa117"):(BoneName = "Right Wrist")
		(BoneHash_array[b] == "598e4372"):(BoneName = "Right Finger Thumb 1")
		(BoneHash_array[b] == "2e8973e4"):(BoneName = "Right Finger Thumb 2")
		(BoneHash_array[b] == "b780225e"):(BoneName = "Right Finger Thumb 3")
		(BoneHash_array[b] == "ad46aa56"):(BoneName = "Right Finger Index Metacarpal")
		(BoneHash_array[b] == "5bc8fd2b"):(BoneName = "Right Finger Index 1")
		(BoneHash_array[b] == "2ccfcdbd"):(BoneName = "Right Finger Index 2")
		(BoneHash_array[b] == "b5c69c07"):(BoneName = "Right Finger Index 3")
		(BoneHash_array[b] == "5a0a971c"):(BoneName = "Right Finger Middle 1")
		(BoneHash_array[b] == "2d0da78a"):(BoneName = "Right Finger Middle 2")
		(BoneHash_array[b] == "b404f630"):(BoneName = "Right Finger Middle 3")
		(BoneHash_array[b] == "da419ac0"):(BoneName = "Right Finger Ring Metacarpal")
		(BoneHash_array[b] == "5f458199"):(BoneName = "Right Finger Ring 1")
		(BoneHash_array[b] == "2842b10f"):(BoneName = "Right Finger Ring 2")
		(BoneHash_array[b] == "b14be0b5"):(BoneName = "Right Finger Ring 3")
		(BoneHash_array[b] == "5e87ebae"):(BoneName = "Right Finger Pinky 1")
		(BoneHash_array[b] == "2980db38"):(BoneName = "Right Finger Pinky 2")
		(BoneHash_array[b] == "b0898a82"):(BoneName = "Right Finger Pinky 3")
		(BoneHash_array[b] == "fceac72"):(BoneName = "Right Weapon")

		(BoneHash_array[b] == "90101230"):(BoneName = "Left Leg")
		(BoneHash_array[b] == "494a5b02"):(BoneName = "Left Leg Twist")
		(BoneHash_array[b] == "92c59772"):(BoneName = "Left Knee")
		(BoneHash_array[b] == "b28c6a72"):(BoneName = "Left Knee Twist")
		(BoneHash_array[b] == "49df5cf9"):(BoneName = "Left Foot")
		(BoneHash_array[b] == "aba26bc1"):(BoneName = "Left Toes")
		(BoneHash_array[b] == "6a1f2f53"):(BoneName = "Right Leg")
		(BoneHash_array[b] == "709638e9"):(BoneName = "Right Leg Twist")
		(BoneHash_array[b] == "68caaa11"):(BoneName = "Right Knee")
		(BoneHash_array[b] == "8b500999"):(BoneName = "Right Knee Twist")
		(BoneHash_array[b] == "b3d0619a"):(BoneName = "Right Foot")
		(BoneHash_array[b] == "51ad56a2"):(BoneName = "Right Toes")

		(BoneHash_array[b] == "a090f968"):(BoneName = "Face Root") -- HDNU/PP
		(BoneHash_array[b] == "f00f589c"):(BoneName = "Face Root") -- SK
		(BoneHash_array[b] == "c64183ae"):(BoneName = "Hair Root") -- HDNU/PP
		(BoneHash_array[b] == "32d12952"):(BoneName = "Hair Center") -- HDNPP
		(BoneHash_array[b] == "826eee63"):(BoneName = "Hair Root") -- SK

		-- Hair (Neptunia U/Megatag, is probably incorrect)

		(BoneHash_array[b] == "355432ed"):(BoneName = "Hair Front Right 1")
		(BoneHash_array[b] == "4253027b"):(BoneName = "Hair Front Right 2")
		(BoneHash_array[b] == "db5a53c1"):(BoneName = "Hair Front Right 3")
		(BoneHash_array[b] == "37128cb4"):(BoneName = "Hair Front Center 1")
		(BoneHash_array[b] == "4015bc22"):(BoneName = "Hair Front Center 2")
		(BoneHash_array[b] == "36d0e683"):(BoneName = "Hair Front Left 1")
		(BoneHash_array[b] == "41d7d615"):(BoneName = "Hair Front Left 2")
		(BoneHash_array[b] == "d8de87af"):(BoneName = "Hair Front Left 3")
		(BoneHash_array[b] == "19b6b065"):(BoneName = "Hair Right Front 1")
		(BoneHash_array[b] == "6eb180f3"):(BoneName = "Hair Right Front 2")
		(BoneHash_array[b] == "f7b8d149"):(BoneName = "Hair Right Front 3")
		(BoneHash_array[b] == "c8d1f425"):(BoneName = "Hair Right Center 1")
		(BoneHash_array[b] == "bfd6c4b3"):(BoneName = "Hair Right Center 2")
		(BoneHash_array[b] == "26df9509"):(BoneName = "Hair Right Center 3")
		(BoneHash_array[b] == "67da8d43"):(BoneName = "Hair Right Center B 1")
		(BoneHash_array[b] == "10ddbdd5"):(BoneName = "Hair Right Center B 2")
		(BoneHash_array[b] == "d2ea63c0"):(BoneName = "Hair Right Back 1")
		(BoneHash_array[b] == "a5ed5356"):(BoneName = "Hair Right Back 2")
		(BoneHash_array[b] == "a97090c9"):(BoneName = "Hair Left Front 1")
		(BoneHash_array[b] == "de77a05f"):(BoneName = "Hair Left Front 2")
		(BoneHash_array[b] == "477ef1e5"):(BoneName = "Hair Left Front 3")
		(BoneHash_array[b] == "7817d489"):(BoneName = "Hair Left Center 1")
		(BoneHash_array[b] == "f10e41f"):(BoneName = "Hair Left Center 2")
		(BoneHash_array[b] == "9619b5a5"):(BoneName = "Hair Left Center 3")
		(BoneHash_array[b] == "b80aa4a0"):(BoneName = "Hair Left Center B 1")
		(BoneHash_array[b] == "cf0d9436"):(BoneName = "Hair Left Center B 2")
		(BoneHash_array[b] == "622c436c"):(BoneName = "Hair Left Back 1")
		(BoneHash_array[b] == "152b73fa"):(BoneName = "Hair Left Back 2")
		(BoneHash_array[b] == "17c13ed6"):(BoneName = "Hair Back Left 1")
		(BoneHash_array[b] == "60c60e40"):(BoneName = "Hair Back Left 2")
		(BoneHash_array[b] == "f9cf5ffa"):(BoneName = "Hair Back Left 3")
		(BoneHash_array[b] == "1587808f"):(BoneName = "Hair Back Center 1")
		(BoneHash_array[b] == "6280b019"):(BoneName = "Hair Back Center 2")
		(BoneHash_array[b] == "fb89e1a3"):(BoneName = "Hair Back Center 3")
		(BoneHash_array[b] == "1445eab8"):(BoneName = "Hair Back Right 1")
		(BoneHash_array[b] == "6342da2e"):(BoneName = "Hair Back Right 2")
		(BoneHash_array[b] == "fa4b8b94"):(BoneName = "Hair Back Right 3")
		(BoneHash_array[b] == "42569ae7"):(BoneName = "Hair Cowlick 1") -- White Heart
		(BoneHash_array[b] == "3551aa71"):(BoneName = "Hair Cowlick 2")
		(BoneHash_array[b] == "398db251"):(BoneName = "Hair Right Pigtail 1") -- Noire/Uni/Purple Heart
		(BoneHash_array[b] == "4e8a82c7"):(BoneName = "Hair Right Pigtail 2")
		(BoneHash_array[b] == "d783d37d"):(BoneName = "Hair Right Pigtail 3")
		(BoneHash_array[b] == "a084e3eb"):(BoneName = "Hair Right Pigtail 4")
		(BoneHash_array[b] == "894b92fd"):(BoneName = "Hair Left Pigtail 1")
		(BoneHash_array[b] == "fe4ca26b"):(BoneName = "Hair Left Pigtail 2")
		(BoneHash_array[b] == "6745f3d1"):(BoneName = "Hair Left Pigtail 3")
		(BoneHash_array[b] == "1042c347"):(BoneName = "Hair Left Pigtail 4")
		(BoneHash_array[b] == "e7d7790f"):(BoneName = "Hair Ponytail 1") -- Green Heart
		(BoneHash_array[b] == "90d04999"):(BoneName = "Hair Ponytail 2")
		(BoneHash_array[b] == "9d91823"):(BoneName = "Hair Ponytail 3")
		(BoneHash_array[b] == "7ede28b5"):(BoneName = "Hair Ponytail 4")
		(BoneHash_array[b] == "1fa99948"):(BoneName = "Hair Back Center B 1") -- Vert
		(BoneHash_array[b] == "68aea9de"):(BoneName = "Hair Back Center B 2")
		(BoneHash_array[b] == "bdcb188b"):(BoneName = "Hair Left Back B 1") -- Nepgear
		(BoneHash_array[b] == "cacc281d"):(BoneName = "Hair Left Back B 2")
		(BoneHash_array[b] == "53c579a7"):(BoneName = "Hair Left Back B 3")
		(BoneHash_array[b] == "bf8da6d2"):(BoneName = "Hair Right Back B 1")
		(BoneHash_array[b] == "c88a9644"):(BoneName = "Hair Right Back B 2")
		(BoneHash_array[b] == "5183c7fe"):(BoneName = "Hair Right Back B 3")
		(BoneHash_array[b] == "a994025"):(BoneName = "Hair Cowlick 1") -- Famitsu
		(BoneHash_array[b] == "7d9e70b3"):(BoneName = "Hair Cowlick 2")
		(BoneHash_array[b] == "e4972109"):(BoneName = "Hair Cowlick 3")
		(BoneHash_array[b] == "e769ecc5"):(BoneName = "Hair Back Left B 1") -- Yellow Heart
		(BoneHash_array[b] == "906edc53"):(BoneName = "Hair Back Left B 2")
		(BoneHash_array[b] == "9678de9"):(BoneName = "Hair Back Left B 3")
		(BoneHash_array[b] == "e4ed38ab"):(BoneName = "Hair Back Right B 1")
		(BoneHash_array[b] == "93ea083d"):(BoneName = "Hair Back Right B 2")
		(BoneHash_array[b] == "ae35987"):(BoneName = "Hair Back Right B 3")
		(BoneHash_array[b] == "63e399db"):(BoneName = "Hair Right Cowlick 1")
		(BoneHash_array[b] == "14e4a94d"):(BoneName = "Hair Right Cowlick 2")
		(BoneHash_array[b] == "d325b977"):(BoneName = "Hair Left Cowlick 1")
		(BoneHash_array[b] == "a42289e1"):(BoneName = "Hair Left Cowlick 2")
		(BoneHash_array[b] == "32858e29"):(BoneName = "Hair Left Ponytail Root") -- Tamsoft
		(BoneHash_array[b] == "7b214a20"):(BoneName = "Hair Left Ponytail A 1")
		(BoneHash_array[b] == "c267ab6"):(BoneName = "Hair Left Ponytail A 2")
		(BoneHash_array[b] == "952f2b0c"):(BoneName = "Hair Left Ponytail A 3")
		(BoneHash_array[b] == "6994e5ce"):(BoneName = "Hair Left Ponytail B 1")
		(BoneHash_array[b] == "1e93d558"):(BoneName = "Hair Left Ponytail B 2")
		(BoneHash_array[b] == "879a84e2"):(BoneName = "Hair Left Ponytail B 3")
		(BoneHash_array[b] == "233fa91d"):(BoneName = "Hair Back 1") -- Next-Gen Mech
		(BoneHash_array[b] == "5438998b"):(BoneName = "Hair Back 2")

		-- Hair (Neptunia PP)

		(BoneHash_array[b] == "6e66bb80"):(BoneName = "Hair Front 1")
		(BoneHash_array[b] == "19618b16"):(BoneName = "Hair Front 2")
		(BoneHash_array[b] == "8068daac"):(BoneName = "Hair Front 3")
		(BoneHash_array[b] == "d6dadce5"):(BoneName = "Hair Front B 1")
		(BoneHash_array[b] == "a1ddec73"):(BoneName = "Hair Front B 2")
		(BoneHash_array[b] == "38d4bdc9"):(BoneName = "Hair Front B 3")
		(BoneHash_array[b] == "c46f730b"):(BoneName = "Hair Front C 1")
		(BoneHash_array[b] == "b368439d"):(BoneName = "Hair Front C 2")
		(BoneHash_array[b] == "2a611227"):(BoneName = "Hair Front C 3")
		(BoneHash_array[b] == "cf67ebb8"):(BoneName = "Hair Right Root")
		(BoneHash_array[b] == "fb068ac2"):(BoneName = "Hair Right Front 1")
		(BoneHash_array[b] == "8c01ba54"):(BoneName = "Hair Right Front 2")
		(BoneHash_array[b] == "1508ebee"):(BoneName = "Hair Right Front 3")
		(BoneHash_array[b] == "620fdb78"):(BoneName = "Hair Right Front 4")
		(BoneHash_array[b] == "fc6b4edb"):(BoneName = "Hair Right Front 5")
		(BoneHash_array[b] == "43baeda7"):(BoneName = "Hair Right Center 1")
		(BoneHash_array[b] == "34bddd31"):(BoneName = "Hair Right Center 2")
		(BoneHash_array[b] == "adb48c8b"):(BoneName = "Hair Right Center 3")
		(BoneHash_array[b] == "dab3bc1d"):(BoneName = "Hair Right Center 4")
		(BoneHash_array[b] == "44d729be"):(BoneName = "Hair Right Center 5")
		(BoneHash_array[b] == "33d01928"):(BoneName = "Hair Right Center 6")
		(BoneHash_array[b] == "aad94892"):(BoneName = "Hair Right Center 7")
		(BoneHash_array[b] == "510f4249"):(BoneName = "Hair Right Back 1")
		(BoneHash_array[b] == "260872df"):(BoneName = "Hair Right Back 2")
		(BoneHash_array[b] == "bf012365"):(BoneName = "Hair Right Back 3")
		(BoneHash_array[b] == "c80613f3"):(BoneName = "Hair Right Back 4")
		(BoneHash_array[b] == "56628650"):(BoneName = "Hair Right Back 5")
		(BoneHash_array[b] == "2165b6c6"):(BoneName = "Hair Right Back 6")
		(BoneHash_array[b] == "ab65725b"):(BoneName = "Hair Left Root")
		(BoneHash_array[b] == "24d6a321"):(BoneName = "Hair Left Front 1")
		(BoneHash_array[b] == "53d193b7"):(BoneName = "Hair Left Front 2")
		(BoneHash_array[b] == "cad8c20d"):(BoneName = "Hair Left Front 3")
		(BoneHash_array[b] == "bddff29b"):(BoneName = "Hair Left Front 4")
		(BoneHash_array[b] == "23bb6738"):(BoneName = "Hair Left Front 5")
		(BoneHash_array[b] == "9c6ac444"):(BoneName = "Hair Left Center 1")
		(BoneHash_array[b] == "eb6df4d2"):(BoneName = "Hair Left Center 2")
		(BoneHash_array[b] == "7264a568"):(BoneName = "Hair Left Center 3")
		(BoneHash_array[b] == "56395fe"):(BoneName = "Hair Left Center 4")
		(BoneHash_array[b] == "9b07005d"):(BoneName = "Hair Left Center 5")
		(BoneHash_array[b] == "ec0030cb"):(BoneName = "Hair Left Center 6")
		(BoneHash_array[b] == "75096171"):(BoneName = "Hair Left Center 7")
		(BoneHash_array[b] == "8edf6baa"):(BoneName = "Hair Left Back 1")
		(BoneHash_array[b] == "f9d85b3c"):(BoneName = "Hair Left Back 2")
		(BoneHash_array[b] == "60d10a86"):(BoneName = "Hair Left Back 3")
		(BoneHash_array[b] == "17d63a10"):(BoneName = "Hair Left Back 4")
		(BoneHash_array[b] == "89b2afb3"):(BoneName = "Hair Left Back 5")
		(BoneHash_array[b] == "feb59f25"):(BoneName = "Hair Left Back 6")
		(BoneHash_array[b] == "b93026e5"):(BoneName = "Hair Right Pigtail 1") -- Noire/Uni/Purple Heart
		(BoneHash_array[b] == "ce371673"):(BoneName = "Hair Right Pigtail 2")
		(BoneHash_array[b] == "573e47c9"):(BoneName = "Hair Right Pigtail 3")
		(BoneHash_array[b] == "2039775f"):(BoneName = "Hair Right Pigtail 4")
		(BoneHash_array[b] == "be5de2fc"):(BoneName = "Hair Right Pigtail 5")
		(BoneHash_array[b] == "c95ad26a"):(BoneName = "Hair Right Pigtail 6")
		(BoneHash_array[b] == "505383d0"):(BoneName = "Hair Right Pigtail 7")
		(BoneHash_array[b] == "66e00f06"):(BoneName = "Hair Left Pigtail 1")
		(BoneHash_array[b] == "11e73f90"):(BoneName = "Hair Left Pigtail 2")
		(BoneHash_array[b] == "88ee6e2a"):(BoneName = "Hair Left Pigtail 3")
		(BoneHash_array[b] == "ffe95ebc"):(BoneName = "Hair Left Pigtail 4")
		(BoneHash_array[b] == "618dcb1f"):(BoneName = "Hair Left Pigtail 5")
		(BoneHash_array[b] == "168afb89"):(BoneName = "Hair Left Pigtail 6")
		(BoneHash_array[b] == "8f83aa33"):(BoneName = "Hair Left Pigtail 7")
		(BoneHash_array[b] == "63a7a9c9"):(BoneName = "Hair Ponytail Root") -- Green Heart
		(BoneHash_array[b] == "9be61d40"):(BoneName = "Hair Back A 1")
		(BoneHash_array[b] == "ece12dd6"):(BoneName = "Hair Back A 2")
		(BoneHash_array[b] == "75e87c6c"):(BoneName = "Hair Back A 3")
		(BoneHash_array[b] == "2ef4cfa"):(BoneName = "Hair Back A 4")
		(BoneHash_array[b] == "9c8bd959"):(BoneName = "Hair Back A 5")
		(BoneHash_array[b] == "eb8ce9cf"):(BoneName = "Hair Back A 6")
		(BoneHash_array[b] == "7285b875"):(BoneName = "Hair Back A 7")
		(BoneHash_array[b] == "235a7a25"):(BoneName = "Hair Back B 1")
		(BoneHash_array[b] == "545d4ab3"):(BoneName = "Hair Back B 2")
		(BoneHash_array[b] == "cd541b09"):(BoneName = "Hair Back B 3")
		(BoneHash_array[b] == "ba532b9f"):(BoneName = "Hair Back B 4")
		(BoneHash_array[b] == "2437be3c"):(BoneName = "Hair Back B 5")
		(BoneHash_array[b] == "53308eaa"):(BoneName = "Hair Back B 6")
		(BoneHash_array[b] == "ca39df10"):(BoneName = "Hair Back B 7")
		(BoneHash_array[b] == "bd3eef86"):(BoneName = "Hair Back B 8")
		(BoneHash_array[b] == "2d81f217"):(BoneName = "Hair Back B 9")
		(BoneHash_array[b] == "5a86c281"):(BoneName = "Hair Back B 10")
		(BoneHash_array[b] == "3a414b64"):(BoneName = "Hair Back B 11")
		(BoneHash_array[b] == "31efd5cb"):(BoneName = "Hair Back C 1")
		(BoneHash_array[b] == "46e8e55d"):(BoneName = "Hair Back C 2")
		(BoneHash_array[b] == "dfe1b4e7"):(BoneName = "Hair Back C 3")
		(BoneHash_array[b] == "a8e68471"):(BoneName = "Hair Back C 4")
		(BoneHash_array[b] == "368211d2"):(BoneName = "Hair Back C 5")
		(BoneHash_array[b] == "41852144"):(BoneName = "Hair Back C 6")
		(BoneHash_array[b] == "d88c70fe"):(BoneName = "Hair Back C 7")
		(BoneHash_array[b] == "af8b4068"):(BoneName = "Hair Back C 8")
		(BoneHash_array[b] == "3f345df9"):(BoneName = "Hair Back C 9")
		(BoneHash_array[b] == "8953b2ae"):(BoneName = "Hair Back D 1")
		(BoneHash_array[b] == "fe548238"):(BoneName = "Hair Back D 2")
		(BoneHash_array[b] == "675dd382"):(BoneName = "Hair Back D 3")
		(BoneHash_array[b] == "105ae314"):(BoneName = "Hair Back D 4")
		(BoneHash_array[b] == "8e3e76b7"):(BoneName = "Hair Back D 5")
		(BoneHash_array[b] == "f9394621"):(BoneName = "Hair Back D 6")
		(BoneHash_array[b] == "6030179b"):(BoneName = "Hair Back D 7")
		(BoneHash_array[b] == "14848a17"):(BoneName = "Hair Back E 1")
		(BoneHash_array[b] == "6383ba81"):(BoneName = "Hair Back E 2")
		(BoneHash_array[b] == "fa8aeb3b"):(BoneName = "Hair Back E 3")
		(BoneHash_array[b] == "8d8ddbad"):(BoneName = "Hair Back E 4")
		(BoneHash_array[b] == "13e94e0e"):(BoneName = "Hair Back E 5")
		(BoneHash_array[b] == "64ee7e98"):(BoneName = "Hair Back E 6")
		(BoneHash_array[b] == "fde72f22"):(BoneName = "Hair Back E 7")

		(BoneHash_array[b] == "1006e82d"):(BoneName = "Skirt Left Front 1")
		(BoneHash_array[b] == "6701d8bb"):(BoneName = "Skirt Left Front 2")
		(BoneHash_array[b] == "fe088901"):(BoneName = "Skirt Left Front 3")
		(BoneHash_array[b] == "12405674"):(BoneName = "Skirt Left 1")
		(BoneHash_array[b] == "654766e2"):(BoneName = "Skirt Left 2")
		(BoneHash_array[b] == "fc4e3758"):(BoneName = "Skirt Left 3")
		(BoneHash_array[b] == "13823c43"):(BoneName = "Skirt Left Back 1")
		(BoneHash_array[b] == "64850cd5"):(BoneName = "Skirt Left Back 2")
		(BoneHash_array[b] == "fd8c5d6f"):(BoneName = "Skirt Left Back 3")
		(BoneHash_array[b] == "8a8b6df9"):(BoneName = "Skirt Left Back 4")
		(BoneHash_array[b] == "cfd6c1ce"):(BoneName = "Skirt Right Front 1")
		(BoneHash_array[b] == "b8d1f158"):(BoneName = "Skirt Right Front 2")
		(BoneHash_array[b] == "21d8a0e2"):(BoneName = "Skirt Right Front 3")
		(BoneHash_array[b] == "56df9074"):(BoneName = "Skirt Right Front 4")
		(BoneHash_array[b] == "cd907f97"):(BoneName = "Skirt Right 1")
		(BoneHash_array[b] == "ba974f01"):(BoneName = "Skirt Right 2")
		(BoneHash_array[b] == "239e1ebb"):(BoneName = "Skirt Right 3")
		(BoneHash_array[b] == "54992e2d"):(BoneName = "Skirt Right 4")
		(BoneHash_array[b] == "cc5215a0"):(BoneName = "Skirt Right Back 1")
		(BoneHash_array[b] == "bb552536"):(BoneName = "Skirt Right Back 2")
		(BoneHash_array[b] == "225c748c"):(BoneName = "Skirt Right Back 3")
		(BoneHash_array[b] == "555b441a"):(BoneName = "Skirt Right Back 4")
		(BoneHash_array[b] == "5ab6f08c"):(BoneName = "Skirt Front 1")
		(BoneHash_array[b] == "2db1c01a"):(BoneName = "Skirt Front 2")
		(BoneHash_array[b] == "b4b891a0"):(BoneName = "Skirt Front 3")

		(BoneHash_array[b] == "bfdd0e55"):(BoneName = "Hair Ribbon Center")
		(BoneHash_array[b] == "f9dbe845"):(BoneName = "Hair Ribbon Left")
		(BoneHash_array[b] == "3d4d526"):(BoneName = "Hair Ribbon Right")
		(BoneHash_array[b] == "3281d74b"):(BoneName = "Ribbon Left")
		(BoneHash_array[b] == "c88eea28"):(BoneName = "Ribbon Right")
		(BoneHash_array[b] == "b46f3e39"):(BoneName = "Skirt Ribbon Left 1")
		(BoneHash_array[b] == "c3680eaf"):(BoneName = "Skirt Ribbon Left 2")
		(BoneHash_array[b] == "eaa77fb9"):(BoneName = "Skirt Ribbon Left 3")
		(BoneHash_array[b] == "4a91e95"):(BoneName = "Skirt Ribbon Right 1")
		(BoneHash_array[b] == "73ae2e03"):(BoneName = "Skirt Ribbon Right 2")
		(BoneHash_array[b] == "5a615f15"):(BoneName = "Skirt Ribbon Right 3")
		(BoneHash_array[b] == "7f299341"):(BoneName = "Right Foot Ribbon")
		(BoneHash_array[b] == "d13a37aa"):(BoneName = "Skirt Ribbon Left Back 1")
		(BoneHash_array[b] == "a63d073c"):(BoneName = "Skirt Ribbon Left Back 2")
		(BoneHash_array[b] == "5e58a0fd"):(BoneName = "Skirt Ribbon Left Front 1")
		(BoneHash_array[b] == "295f906b"):(BoneName = "Skirt Ribbon Left Front 2")
		(BoneHash_array[b] == "e8e65441"):(BoneName = "Skirt Ribbon Right Back 1")
		(BoneHash_array[b] == "9fe164d7"):(BoneName = "Skirt Ribbon Right Back 2")
		(BoneHash_array[b] == "6784c316"):(BoneName = "Skirt Ribbon Right Front 1")
		(BoneHash_array[b] == "1083f380"):(BoneName = "Skirt Ribbon Right Front 2")
		(BoneHash_array[b] == "713300b3"):(BoneName = "Head Ribbon Left")
		(BoneHash_array[b] == "8b3c3dd0"):(BoneName = "Head Ribbon Right")
		(BoneHash_array[b] == "404c111d"):(BoneName = "Left Knee Ribbon")
		(BoneHash_array[b] == "ba432c7e"):(BoneName = "Right Knee Ribbon")
		(BoneHash_array[b] == "69837e32"):(BoneName = "Skirt Bow Root")
		(BoneHash_array[b] == "2680fa41"):(BoneName = "Skirt Bow Left")
		(BoneHash_array[b] == "dc8fc722"):(BoneName = "Skirt Bow Right")
		(BoneHash_array[b] == "1c3a7e2e"):(BoneName = "Tail Ribbon Right")
		(BoneHash_array[b] == "e635434d"):(BoneName = "Tail Ribbon Left")

		(BoneHash_array[b] == "f94d4009"):(BoneName = "Jacket Left 1") -- Uzume
		(BoneHash_array[b] == "8e4a709f"):(BoneName = "Jacket Left 2")
		(BoneHash_array[b] == "17432125"):(BoneName = "Jacket Left 3")
		(BoneHash_array[b] == "649a78b0"):(BoneName = "Jacket Left Back 1")
		(BoneHash_array[b] == "139d4826"):(BoneName = "Jacket Left Back 2")
		(BoneHash_array[b] == "8a94199c"):(BoneName = "Jacket Left Back 3")
		(BoneHash_array[b] == "ce93b03b"):(BoneName = "Jacket Right 1")
		(BoneHash_array[b] == "b99480ad"):(BoneName = "Jacket Right 2")
		(BoneHash_array[b] == "209dd117"):(BoneName = "Jacket Right 3")
		(BoneHash_array[b] == "dc261fd5"):(BoneName = "Jacket Right Back 1")
		(BoneHash_array[b] == "ab212f43"):(BoneName = "Jacket Right Back 2")
		(BoneHash_array[b] == "32287ef9"):(BoneName = "Jacket Right Back 3")
		(BoneHash_array[b] == "b3c9cceb"):(BoneName = "Jacket Collar Left")
		(BoneHash_array[b] == "49c6f188"):(BoneName = "Jacket Collar Right")
		(BoneHash_array[b] == "92fef64f"):(BoneName = "Head Equip Front String 1") -- Tamsoft
		(BoneHash_array[b] == "e5f9c6d9"):(BoneName = "Head Equip Front String 2")
		(BoneHash_array[b] == "7a5bc6b5"):(BoneName = "Head Equip Back String 1")
		(BoneHash_array[b] == "d5cf623"):(BoneName = "Head Equip Back String 2")
		(BoneHash_array[b] == "294ac975"):(BoneName = "Shirt Bunny")
		(BoneHash_array[b] == "49346455"):(BoneName = "Shirt String Right 1")
		(BoneHash_array[b] == "3e3354c3"):(BoneName = "Shirt String Right 2")
		(BoneHash_array[b] == "f9f244f9"):(BoneName = "Shirt String Left 1")
		(BoneHash_array[b] == "8ef5746f"):(BoneName = "Shirt String Left 2")
		(BoneHash_array[b] == "657a9e82"):(BoneName = "Shirt Right Front 1")
		(BoneHash_array[b] == "127dae14"):(BoneName = "Shirt Right Front 2")
		(BoneHash_array[b] == "77cf316c"):(BoneName = "Shirt Right 1")
		(BoneHash_array[b] == "c801fa"):(BoneName = "Shirt Right 2")
		(BoneHash_array[b] == "cf735609"):(BoneName = "Shirt Right Back 1")
		(BoneHash_array[b] == "b874669f"):(BoneName = "Shirt Right Back 2")
		(BoneHash_array[b] == "52a46eb0"):(BoneName = "Shirt Left Back 1")
		(BoneHash_array[b] == "25a35e26"):(BoneName = "Shirt Left Back 2")
		(BoneHash_array[b] == "ea1809d5"):(BoneName = "Shirt Left 1")
		(BoneHash_array[b] == "9d1f3943"):(BoneName = "Shirt Left 2")
		(BoneHash_array[b] == "f8ada63b"):(BoneName = "Shirt Left Front 1")
		(BoneHash_array[b] == "8faa96ad"):(BoneName = "Shirt Left Front 2")
		(BoneHash_array[b] == "5b11d03e"):(BoneName = "Skirt Bow Right")
		(BoneHash_array[b] == "a11eed5d"):(BoneName = "Skirt Bow Left")

		(BoneHash_array[b] == "3b9f40c7"):(BoneName = "Coat Left Front 1")
		(BoneHash_array[b] == "4c987051"):(BoneName = "Coat Left Front 2")
		(BoneHash_array[b] == "d59121eb"):(BoneName = "Coat Left Front 3")
		(BoneHash_array[b] == "292aef29"):(BoneName = "Coat Left 1")
		(BoneHash_array[b] == "5e2ddfbf"):(BoneName = "Coat Left 2")
		(BoneHash_array[b] == "c7248e05"):(BoneName = "Coat Left 3")
		(BoneHash_array[b] == "9196884c"):(BoneName = "Coat Left Back 1")
		(BoneHash_array[b] == "e691b8da"):(BoneName = "Coat Left Back 2")
		(BoneHash_array[b] == "7f98e960"):(BoneName = "Coat Left Back 3")
		(BoneHash_array[b] == "a648787e"):(BoneName = "Coat Right Front 1")
		(BoneHash_array[b] == "d14f48e8"):(BoneName = "Coat Right Front 2")
		(BoneHash_array[b] == "48461952"):(BoneName = "Coat Right Front 3")
		(BoneHash_array[b] == "b4fdd790"):(BoneName = "Coat Right 1")
		(BoneHash_array[b] == "c3fae706"):(BoneName = "Coat Right 2")
		(BoneHash_array[b] == "5af3b6bc"):(BoneName = "Coat Right 3")
		(BoneHash_array[b] == "c41b0f5"):(BoneName = "Coat Right Back 1")
		(BoneHash_array[b] == "7b468063"):(BoneName = "Coat Right Back 2")
		(BoneHash_array[b] == "e24fd1d9"):(BoneName = "Coat Right Back 3")
		(BoneHash_array[b] == "548ad1c2"):(BoneName = "Neckerchief Root")
		(BoneHash_array[b] == "b9203337"):(BoneName = "Neckerchief Left")
		(BoneHash_array[b] == "8047826c"):(BoneName = "Neckerchief Right")
		(BoneHash_array[b] == "351f7e62"):(BoneName = "Necktie 1")
		(BoneHash_array[b] == "42184ef4"):(BoneName = "Necktie 2")
		(BoneHash_array[b] == "db111f4e"):(BoneName = "Necktie 3")
		(BoneHash_array[b] == "90a446f5"):(BoneName = "Pouch 1")
		(BoneHash_array[b] == "e7a37663"):(BoneName = "Pouch 2")
		(BoneHash_array[b] == "1c8fe0c1"):(BoneName = "Bag 1")
		(BoneHash_array[b] == "6b88d057"):(BoneName = "Bag 2")
		(BoneHash_array[b] == "7c43df66"):(BoneName = "Belt Root")
		(BoneHash_array[b] == "30d53095"):(BoneName = "Belt Left Front")
		(BoneHash_array[b] == "32938ecc"):(BoneName = "Belt Left")
		(BoneHash_array[b] == "3351e4fb"):(BoneName = "Belt Left Back")
		(BoneHash_array[b] == "ef051976"):(BoneName = "Belt Right Front")
		(BoneHash_array[b] == "ed43a72f"):(BoneName = "Belt Right")
		(BoneHash_array[b] == "ec81cd18"):(BoneName = "Belt Right Back")

		(BoneHash_array[b] == "557147f4"):(BoneName = "Left Arm Equip")
		(BoneHash_array[b] == "75f3a96d"):(BoneName = "Left Hand Equip")
		(BoneHash_array[b] == "af7e7a97"):(BoneName = "Right Arm Equip")
		(BoneHash_array[b] == "8ffc940e"):(BoneName = "Right Hand Equip")
		(BoneHash_array[b] == "b545ecbb"):(BoneName = "Left Wing Equip")
		(BoneHash_array[b] == "4f4ad1d8"):(BoneName = "Right Wing Equip")
		(BoneHash_array[b] == "e9f599a9"):(BoneName = "Left Hip Equip 1")
		(BoneHash_array[b] == "9ef2a93f"):(BoneName = "Left Hip Equip 2")
		(BoneHash_array[b] == "7fbf885"):(BoneName = "Left Hip Equip 3")
		(BoneHash_array[b] == "5453b269"):(BoneName = "Left Knee Equip")
		(BoneHash_array[b] == "ac1b4d7a"):(BoneName = "Left Foot Equip")
		(BoneHash_array[b] == "511181fc"):(BoneName = "Left Toes Equip")
		(BoneHash_array[b] == "5933b905"):(BoneName = "Right Hip Equip 1")
		(BoneHash_array[b] == "2e348993"):(BoneName = "Right Hip Equip 2")
		(BoneHash_array[b] == "b73dd829"):(BoneName = "Right Hip Equip 3")
		(BoneHash_array[b] == "ae5c8f0a"):(BoneName = "Right Knee Equip")
		(BoneHash_array[b] == "56147019"):(BoneName = "Right Foot Equip")
		(BoneHash_array[b] == "ab1ebc9f"):(BoneName = "Right Toes Equip")
		(BoneHash_array[b] == "8041359f"):(BoneName = "Tail Equip 1")
		(BoneHash_array[b] == "f7460509"):(BoneName = "Tail Equip 2")

		(BoneHash_array[b] == "91341e80"):(BoneName = "String Left 1") -- Neptune
		(BoneHash_array[b] == "e6332e16"):(BoneName = "String Left 2")
		(BoneHash_array[b] == "7f3a7fac"):(BoneName = "String Left 3")
		(BoneHash_array[b] == "83d4f3a"):(BoneName = "String Left 4")
		(BoneHash_array[b] == "21f23e2c"):(BoneName = "String Right 1")
		(BoneHash_array[b] == "56f50eba"):(BoneName = "String Right 2")
		(BoneHash_array[b] == "cffc5f00"):(BoneName = "String Right 3")
		(BoneHash_array[b] == "b8fb6f96"):(BoneName = "String Right 4")
		(BoneHash_array[b] == "a0b9cf85"):(BoneName = "Zipper")
		(BoneHash_array[b] == "baa31a7b"):(BoneName = "Necktie 1")
		(BoneHash_array[b] == "cda42aed"):(BoneName = "Necktie 2")
		(BoneHash_array[b] == "54ad7b57"):(BoneName = "Necktie 3")
		(BoneHash_array[b] == "6dbc75d7"):(BoneName = "Coat Left 1") -- Blanc
		(BoneHash_array[b] == "2f634dcc"):(BoneName = "Coat Left 2")
		(BoneHash_array[b] == "57b614a7"):(BoneName = "Coat Center 1")
		(BoneHash_array[b] == "cfbc3aff"):(BoneName = "Coat Center 2")
		(BoneHash_array[b] == "5460163c"):(BoneName = "Coat Right 1")
		(BoneHash_array[b] == "9fa56d60"):(BoneName = "Coat Right 2")
		(BoneHash_array[b] == "49e8ee89"):(BoneName = "Neckerchief Left 1") -- Nepgear
		(BoneHash_array[b] == "23574e1e"):(BoneName = "Neckerchief Left 2")
		(BoneHash_array[b] == "54507e88"):(BoneName = "Neckerchief Left 3")
		(BoneHash_array[b] == "cd592f32"):(BoneName = "Neckerchief Left 4")
		(BoneHash_array[b] == "70348d62"):(BoneName = "Neckerchief Right 1")
		(BoneHash_array[b] == "93916eb2"):(BoneName = "Neckerchief Right 2")
		(BoneHash_array[b] == "e4965e24"):(BoneName = "Neckerchief Right 3")
		(BoneHash_array[b] == "7d9f0f9e"):(BoneName = "Neckerchief Right 4")
		(BoneHash_array[b] == "933bb3d5"):(BoneName = "Pouch 1") -- Uni
		(BoneHash_array[b] == "e43c8343"):(BoneName = "Pouch 2")
		(BoneHash_array[b] == "8a356153"):(BoneName = "Ribbon Root")
		(BoneHash_array[b] == "9da89a8e"):(BoneName = "Ribbon Left 1") -- Noire/Uni/School outfits
		(BoneHash_array[b] == "eaafaa18"):(BoneName = "Ribbon Left 2")
		(BoneHash_array[b] == "4278b36d"):(BoneName = "Ribbon Right 1")
		(BoneHash_array[b] == "357f83fb"):(BoneName = "Ribbon Right 2")
		(BoneHash_array[b] == "2514fdeb"):(BoneName = "Ribbon B Left 1")
		(BoneHash_array[b] == "5213cd7d"):(BoneName = "Ribbon B Left 2")
		(BoneHash_array[b] == "cb1a9cc7"):(BoneName = "Ribbon B Left 3")
		(BoneHash_array[b] == "fac4d408"):(BoneName = "Ribbon B Right 1")
		(BoneHash_array[b] == "8dc3e49e"):(BoneName = "Ribbon B Right 2")
		(BoneHash_array[b] == "14cab524"):(BoneName = "Ribbon B Right 3")
		(BoneHash_array[b] == "f238cf43"):(BoneName = "Bonbon Left 1") -- Ram/Rom/Compa
		(BoneHash_array[b] == "853fffd5"):(BoneName = "Bonbon Left 2")
		(BoneHash_array[b] == "1c36ae6f"):(BoneName = "Bonbon Left 3")
		(BoneHash_array[b] == "42feefef"):(BoneName = "Bonbon Right 1")
		(BoneHash_array[b] == "35f9df79"):(BoneName = "Bonbon Right 2")
		(BoneHash_array[b] == "acf08ec3"):(BoneName = "Bonbon Right 3")

		(BoneHash_array[b] == "862ca2b0"):(BoneName = "Spine 1") -- Monsters
		(BoneHash_array[b] == "f12b9226"):(BoneName = "Spine 2")
		(BoneHash_array[b] == "6822c39c"):(BoneName = "Chest")
		(BoneHash_array[b] == "6d2022ac"):(BoneName = "Left Leg")
		(BoneHash_array[b] == "1a27123a"):(BoneName = "Left Knee")
		(BoneHash_array[b] == "832e4380"):(BoneName = "Left Foot")
		(BoneHash_array[b] == "dde60200"):(BoneName = "Right Leg")
		(BoneHash_array[b] == "aae13296"):(BoneName = "Right Knee")
		(BoneHash_array[b] == "33e8632c"):(BoneName = "Right Foot")
		(BoneHash_array[b] == "f5c7b65b"):(BoneName = "Left Arm")
		(BoneHash_array[b] == "82c086cd"):(BoneName = "Left Forearm")
		(BoneHash_array[b] == "db6789e7"):(BoneName = "Left Fingers")
		(BoneHash_array[b] == "450196f7"):(BoneName = "Right Arm")
		(BoneHash_array[b] == "3206a661"):(BoneName = "Right Forearm")
		(BoneHash_array[b] == "2168b484"):(BoneName = "Right Fingers")
		(BoneHash_array[b] == "b2d9d870"):(BoneName = "Down") -- Dogoo
		(BoneHash_array[b] == "7b951f17"):(BoneName = "Up 1")
		(BoneHash_array[b] == "e29c4ead"):(BoneName = "Up 2")
		(BoneHash_array[b] == "307b9e0d"):(BoneName = "Up") -- Clyde
		(BoneHash_array[b] == "7d55df24"):(BoneName = "Petals") -- Sunflowery
		(BoneHash_array[b] == "9c0d96a2"):(BoneName = "Spine") -- Plum-met
		(BoneHash_array[b] == "900724fa"):(BoneName = "Mouth") -- Terits
		(BoneHash_array[b] == "f6e9d433"):(BoneName = "Top Box")
		(BoneHash_array[b] == "92827cf3"):(BoneName = "Left Box")
		(BoneHash_array[b] == "9c59f4c1"):(BoneName = "Bottom Box")
		(BoneHash_array[b] == "688d4190"):(BoneName = "Right Box")
		(BoneHash_array[b] == "9efc9804"):(BoneName = "Body") -- Dogoo Man
		(BoneHash_array[b] == "e9fba892"):(BoneName = "Top")
		(BoneHash_array[b] == "9bb101cd"):(BoneName = "Lips Top")
		(BoneHash_array[b] == "ffdaa90d"):(BoneName = "Lips Bottom")
		(BoneHash_array[b] == "95972306"):(BoneName = "Cheeks")
		(BoneHash_array[b] == "96b88107"):(BoneName = "Drips Left")
		(BoneHash_array[b] == "e1bfb191"):(BoneName = "Drips Center")
		(BoneHash_array[b] == "6cb7bc64"):(BoneName = "Drips Right")
		(BoneHash_array[b] == "c7eb5506"):(BoneName = "Glasses") -- Super Otaku
		(BoneHash_array[b] == "70ee6dca"):(BoneName = "Game")
		(BoneHash_array[b] == "86b6731b"):(BoneName = "Belly")
		(BoneHash_array[b] == "d58ba515"):(BoneName = "Mouth") -- Real Gamer
		(BoneHash_array[b] == "e88dad0"):(BoneName = "Mouth 1") -- GK
		(BoneHash_array[b] == "1d7f422f"):(BoneName = "Mouth 2")
		(BoneHash_array[b] == "2b69a85a"):(BoneName = "Left Hair")
		(BoneHash_array[b] == "3dd12620"):(BoneName = "Right Hair")
		(BoneHash_array[b] == "d53b8ebc"):(BoneName = "Left Ear") -- Cutekitty
		(BoneHash_array[b] == "65fdae10"):(BoneName = "Right Ear")
		(BoneHash_array[b] == "8074daed"):(BoneName = "Left Wing")
		(BoneHash_array[b] == "7a7be78e"):(BoneName = "Right Wing")
		(BoneHash_array[b] == "d211fc16"):(BoneName = "Tail")
		(BoneHash_array[b] == "ea4b9f7b"):(BoneName = "Left Hand 1") -- Penguin
		(BoneHash_array[b] == "9d4cafed"):(BoneName = "Left Hand 2")
		(BoneHash_array[b] == "5a8dbfd7"):(BoneName = "Right Hand 1")
		(BoneHash_array[b] == "2d8a8f41"):(BoneName = "Right Hand 2")
		(BoneHash_array[b] == "e6250f0a"):(BoneName = "Bag")
		(BoneHash_array[b] == "c776499b"):(BoneName = "Left Ear 1") -- Pumpkimon
		(BoneHash_array[b] == "b071790d"):(BoneName = "Left Ear 2")
		(BoneHash_array[b] == "f097ae08"):(BoneName = "Right Ear 1")
		(BoneHash_array[b] == "87909e9e"):(BoneName = "Right Ear 2")
		(BoneHash_array[b] == "515db306"):(BoneName = "Object")
		(BoneHash_array[b] == "ff0d10d6"):(BoneName = "Right Arm") -- Sicko Shadow
		(BoneHash_array[b] == "4fcb307a"):(BoneName = "Left Arm")
		(BoneHash_array[b] == "88d7e704"):(BoneName = "Legs Right")
		(BoneHash_array[b] == "67a971d8"):(BoneName = "Legs Left")
		(BoneHash_array[b] == "d7b0c655"):(BoneName = "Body Right")
		(BoneHash_array[b] == "ee6ca5be"):(BoneName = "Body Left")
		(BoneHash_array[b] == "abeb3b7b"):(BoneName = "Face Right")
		(BoneHash_array[b] == "92375890"):(BoneName = "Face Left")
		(BoneHash_array[b] == "32b606de"):(BoneName = "Mouth")
		(BoneHash_array[b] == "45b13648"):(BoneName = "Right Eye")
		(BoneHash_array[b] == "dcb867f2"):(BoneName = "Left Eye")
		(BoneHash_array[b] == "7e68323f"):(BoneName = "Hair Right")
		(BoneHash_array[b] == "96f02a9"):(BoneName = "Hair Center")
		(BoneHash_array[b] == "90665313"):(BoneName = "Hair Left")
		(BoneHash_array[b] == "4098a29d"):(BoneName = "Fiddle Stick")
		(BoneHash_array[b] == "379f920b"):(BoneName = "Fiddle")
		(BoneHash_array[b] == "92e73f85"):(BoneName = "Window Back") -- VN Window
		(BoneHash_array[b] == "55878718"):(BoneName = "Window Message")
		(BoneHash_array[b] == "2ebae430"):(BoneName = "Top") -- Pal Shell
		(BoneHash_array[b] == "9041063d"):(BoneName = "Bottom")
		(BoneHash_array[b] == "5d1d09b9"):(BoneName = "Hair Right Pigtail") -- Alraune
		(BoneHash_array[b] == "b5a7b5aa"):(BoneName = "Hair Right Side")
		(BoneHash_array[b] == "a71234da"):(BoneName = "Hair Left Pigtail")
		(BoneHash_array[b] == "4fa888c9"):(BoneName = "Hair Left Side")
		(BoneHash_array[b] == "8f3b82b6"):(BoneName = "Leaf 3")
		(BoneHash_array[b] == "7534bfd5"):(BoneName = "Leaf 1")
		(BoneHash_array[b] == "928c92d2"):(BoneName = "Leaf 2")
		(BoneHash_array[b] == "44ed0ad2"):(BoneName = "Liquid") -- Bit/M-3
		(BoneHash_array[b] == "cb748cf1"):(BoneName = "Ball")
		(BoneHash_array[b] == "e3de7881"):(BoneName = "Top")
		(BoneHash_array[b] == "8f7fe0fa"):(BoneName = "Eye")
		(BoneHash_array[b] == "832d94dc"):(BoneName = "Ring Right") -- Dolem
		(BoneHash_array[b] == "7922a9bf"):(BoneName = "Ring Left")
		(BoneHash_array[b] == "9e9a84b8"):(BoneName = "Ring Back")
		(BoneHash_array[b] == "4a120fe"):(BoneName = "Left Arm Cylinder")
		(BoneHash_array[b] == "feae1d9d"):(BoneName = "Right Arm Cylinder")
		(BoneHash_array[b] == "6585241c"):(BoneName = "Tail 1") -- Whale/Nep PP cowlicks/SK:EV Mirai
		(BoneHash_array[b] == "1282148a"):(BoneName = "Tail 2")
		(BoneHash_array[b] == "8b8b4530"):(BoneName = "Tail 3")
		(BoneHash_array[b] == "fc8c75a6"):(BoneName = "Tail 4")
		(BoneHash_array[b] == "62e8e005"):(BoneName = "Tail 5")
		(BoneHash_array[b] == "15efd093"):(BoneName = "Tail 6")
		(BoneHash_array[b] == "8ce68129"):(BoneName = "Tail 7")
		(BoneHash_array[b] == "fbe1b1bf"):(BoneName = "Tail 8")
		(BoneHash_array[b] == "9d818be4"):(BoneName = "Tail Right Fin Front 1")
		(BoneHash_array[b] == "ea86bb72"):(BoneName = "Tail Right Fin Front 2")
		(BoneHash_array[b] == "4251a207"):(BoneName = "Tail Left Fin Front 1")
		(BoneHash_array[b] == "35569291"):(BoneName = "Tail Left Fin Front 2")
		(BoneHash_array[b] == "12e31cb3"):(BoneName = "Tail Right Fin Rear 1")
		(BoneHash_array[b] == "65e42c25"):(BoneName = "Tail Right Fin Rear 2")
		(BoneHash_array[b] == "cd333550"):(BoneName = "Tail Left Fin Rear 1")
		(BoneHash_array[b] == "ba3405c6"):(BoneName = "Tail Left Fin Rear 2")
		(BoneHash_array[b] == "4ee27839"):(BoneName = "Right Horn 1")
		(BoneHash_array[b] == "39e548af"):(BoneName = "Right Horn 2")
		(BoneHash_array[b] == "a0ec1915"):(BoneName = "Right Horn 3")
		(BoneHash_array[b] == "d7eb2983"):(BoneName = "Right Horn 4")
		(BoneHash_array[b] == "fe245895"):(BoneName = "Left Horn 1")
		(BoneHash_array[b] == "89236803"):(BoneName = "Left Horn 2")
		(BoneHash_array[b] == "102a39b9"):(BoneName = "Left Horn 3")
		(BoneHash_array[b] == "672d092f"):(BoneName = "Left Horn 4")
		(BoneHash_array[b] == "ac892574"):(BoneName = "Right Fin 1")
		(BoneHash_array[b] == "db8e15e2"):(BoneName = "Right Fin 2")
		(BoneHash_array[b] == "42874458"):(BoneName = "Right Fin 3")
		(BoneHash_array[b] == "1c4f05d8"):(BoneName = "Left Fin 1")
		(BoneHash_array[b] == "6b48354e"):(BoneName = "Left Flipper 2")
		(BoneHash_array[b] == "f24164f4"):(BoneName = "Left Fin 3")
		(BoneHash_array[b] == "7ac7ff4d"):(BoneName = "Right Shoulder Pad") -- Killachine
		(BoneHash_array[b] == "80c8c22e"):(BoneName = "Left Shoulder Pad")
		(BoneHash_array[b] == "9a6f4179"):(BoneName = "Right Leg")
		(BoneHash_array[b] == "737b16e1"):(BoneName = "Right Knee")
		(BoneHash_array[b] == "613051c5"):(BoneName = "Right Foot")
		(BoneHash_array[b] == "78c6dea9"):(BoneName = "Right Knee Pad")
		(BoneHash_array[b] == "2aa961d5"):(BoneName = "Left Leg")
		(BoneHash_array[b] == "c3bd364d"):(BoneName = "Left Knee")
		(BoneHash_array[b] == "d1f67169"):(BoneName = "Left Foot")
		(BoneHash_array[b] == "82c9e3ca"):(BoneName = "Left Knee Pad")
		(BoneHash_array[b] == "8300efd9"):(BoneName = "Right Undercloth")
		(BoneHash_array[b] == "790fd2ba"):(BoneName = "Left Undercloth")
		(BoneHash_array[b] == "12163d57"):(BoneName = "Back Undercloth")
		(BoneHash_array[b] == "4db85d16"):(BoneName = "Right Tail")
		(BoneHash_array[b] == "b7b76075"):(BoneName = "Left Tail")
		(BoneHash_array[b] == "6434e0fa"):(BoneName = "Hat") -- Action Machine
		(BoneHash_array[b] == "ed2129ad"):(BoneName = "Left Cheek")
		(BoneHash_array[b] == "172e14ce"):(BoneName = "Right Cheek")
		(BoneHash_array[b] == "ed2129ad"):(BoneName = "Hair Left") -- King Pac
		(BoneHash_array[b] == "172e14ce"):(BoneName = "Hair Right")
		(BoneHash_array[b] == "1cc47ea5"):(BoneName = "Tail 1")
		(BoneHash_array[b] == "6bc34e33"):(BoneName = "Tail 2")
		(BoneHash_array[b] == "f2ca1f89"):(BoneName = "Tail 3")
		(BoneHash_array[b] == "85cd2f1f"):(BoneName = "Tail 4")
		(BoneHash_array[b] == "1ba9babc"):(BoneName = "Tail 5")
		(BoneHash_array[b] == "6cae8a2a"):(BoneName = "Tail 6")
		(BoneHash_array[b] == "96703295"):(BoneName = "Tail B")
		(BoneHash_array[b] == "c03ae8bf"):(BoneName = "Right Hip Equip 4") -- Next-Gen Mech
		(BoneHash_array[b] == "5e5e7d1c"):(BoneName = "Right Hip Equip 5")
		(BoneHash_array[b] == "29594d8a"):(BoneName = "Right Hip Equip 6")
		(BoneHash_array[b] == "6ebc519d"):(BoneName = "Right Wing A Root")
		(BoneHash_array[b] == "19bb610b"):(BoneName = "Right Wing A Top")
		(BoneHash_array[b] == "80b230b1"):(BoneName = "Right Wing A Top B")
		(BoneHash_array[b] == "f7b50027"):(BoneName = "Right Wing A Bottom")
		(BoneHash_array[b] == "69d19584"):(BoneName = "Right Wing A Bottom B")
		(BoneHash_array[b] == "de7a7131"):(BoneName = "Left Wing A Root")
		(BoneHash_array[b] == "a97d41a7"):(BoneName = "Left Wing A Top")
		(BoneHash_array[b] == "3074101d"):(BoneName = "Left Wing A Top B")
		(BoneHash_array[b] == "4773208b"):(BoneName = "Left Wing A Bottom")
		(BoneHash_array[b] == "d917b528"):(BoneName = "Left Wing A Bottom B")
		(BoneHash_array[b] == "5b20f5b7"):(BoneName = "Right Wing B")
		(BoneHash_array[b] == "2c27c521"):(BoneName = "Right Wing C")
		(BoneHash_array[b] == "b52e949b"):(BoneName = "Right Wing D")
		(BoneHash_array[b] == "ebe6d51b"):(BoneName = "Left Wing B")
		(BoneHash_array[b] == "9ce1e58d"):(BoneName = "Left Wing C")
		(BoneHash_array[b] == "5e8b437"):(BoneName = "Left Wing D")
		(BoneHash_array[b] == "9ced7b5f"):(BoneName = "Right Arm B")
		(BoneHash_array[b] == "ebea4bc9"):(BoneName = "Right Forearm B")
		(BoneHash_array[b] == "72e31a73"):(BoneName = "Right Thumb B 1")
		(BoneHash_array[b] == "5e42ae5"):(BoneName = "Right Thumb B 2")
		(BoneHash_array[b] == "9b80bf46"):(BoneName = "Right Index B 1")
		(BoneHash_array[b] == "ec878fd0"):(BoneName = "Right Index B 2")
		(BoneHash_array[b] == "758ede6a"):(BoneName = "Right Middle B 1")
		(BoneHash_array[b] == "289eefc"):(BoneName = "Right Middle B 2")
		(BoneHash_array[b] == "9236f36d"):(BoneName = "Right Ring B 1")
		(BoneHash_array[b] == "e531c3fb"):(BoneName = "Right Ring B 2")
		(BoneHash_array[b] == "2c2b5bf3"):(BoneName = "Left Arm B")
		(BoneHash_array[b] == "5b2c6b65"):(BoneName = "Left Forearm B")
		(BoneHash_array[b] == "c2253adf"):(BoneName = "Left Thumb B 1")
		(BoneHash_array[b] == "b5220a49"):(BoneName = "Left Thumb B 2")
		(BoneHash_array[b] == "2b469fea"):(BoneName = "Left Index B 1")
		(BoneHash_array[b] == "5c41af7c"):(BoneName = "Left Index B 2")
		(BoneHash_array[b] == "c548fec6"):(BoneName = "Left Middle B 1")
		(BoneHash_array[b] == "b24fce50"):(BoneName = "Left Middle B 2")
		(BoneHash_array[b] == "22f0d3c1"):(BoneName = "Left Ring B 1")
		(BoneHash_array[b] == "55f7e357"):(BoneName = "Left Ring B 2")
		(BoneHash_array[b] == "256b915e"):(BoneName = "Hair A")
		(BoneHash_array[b] == "22065547"):(BoneName = "Hair B")
		(BoneHash_array[b] == "ef64eacf"):(BoneName = "Beak Top")
		(BoneHash_array[b] == "85d4ca3d"):(BoneName = "Beak Bottom")
		(BoneHash_array[b] == "635dad8d"):(BoneName = "Right Weapon")
		(BoneHash_array[b] == "995290ee"):(BoneName = "Left Weapon")
		(BoneHash_array[b] == "80658537"):(BoneName = "Right Fan")
		(BoneHash_array[b] == "7a6ab854"):(BoneName = "Left Fan")
		(BoneHash_array[b] == "1b772e52"):(BoneName = "Right Weapon B")
		(BoneHash_array[b] == "8df6768b"):(BoneName = "Left Arm VMU")
		(BoneHash_array[b] == "3750803"):(BoneName = "Left Wing A")
		(BoneHash_array[b] == "133b65a"):(BoneName = "Left Wing B")
		(BoneHash_array[b] == "dca521e0"):(BoneName = "Right Wing A")
		(BoneHash_array[b] == "dee39fb9"):(BoneName = "Right Wing B")
		(BoneHash_array[b] == "fe00c993"):(BoneName = "Jaw")
		(BoneHash_array[b] == "c5abcd04"):(BoneName = "Core")
		(BoneHash_array[b] == "7adfce47"):(BoneName = "Right Eyelid Top")
		(BoneHash_array[b] == "3de0903e"):(BoneName = "Right Eyelid Bottom")
		(BoneHash_array[b] == "80d0f324"):(BoneName = "Left Eyelid Top")
		(BoneHash_array[b] == "c7efad5d"):(BoneName = "Left Eyelid Bottom")
		(BoneHash_array[b] == "e8b82ae1"):(BoneName = "Right Pauldron")
		(BoneHash_array[b] == "96f798cb"):(BoneName = "Right Pauldron Cloth Front")
		(BoneHash_array[b] == "94b12692"):(BoneName = "Right Pauldron Cloth Back")
		(BoneHash_array[b] == "27d666f3"):(BoneName = "Right Pauldron Cloth 1")
		(BoneHash_array[b] == "50d15665"):(BoneName = "Right Pauldron Cloth 2")
		(BoneHash_array[b] == "c9d807df"):(BoneName = "Right Pauldron Cloth 3")
		(BoneHash_array[b] == "bedf3749"):(BoneName = "Right Pauldron Cloth 4")
		(BoneHash_array[b] == "20bba2ea"):(BoneName = "Right Pauldron Cloth 5")
		(BoneHash_array[b] == "12b71782"):(BoneName = "Left Pauldron")
		(BoneHash_array[b] == "4927b128"):(BoneName = "Left Pauldron Cloth Front")
		(BoneHash_array[b] == "4b610f71"):(BoneName = "Left Pauldron Cloth Back")
		(BoneHash_array[b] == "9710465f"):(BoneName = "Left Pauldron Cloth 1")
		(BoneHash_array[b] == "e01776c9"):(BoneName = "Left Pauldron Cloth 2")
		(BoneHash_array[b] == "791e2773"):(BoneName = "Left Pauldron Cloth 3")
		(BoneHash_array[b] == "e1917e5"):(BoneName = "Left Pauldron Cloth 4")
		(BoneHash_array[b] == "907d8246"):(BoneName = "Left Pauldron Cloth 5")
		(BoneHash_array[b] == "794c95c1"):(BoneName = "Robe A 1")
		(BoneHash_array[b] == "e4ba557"):(BoneName = "Robe A 2")
		(BoneHash_array[b] == "9742f4ed"):(BoneName = "Robe A 3")
		(BoneHash_array[b] == "e045c47b"):(BoneName = "Robe A 4")
		(BoneHash_array[b] == "7e2151d8"):(BoneName = "Robe A 5")
		(BoneHash_array[b] == "6bf93a2f"):(BoneName = "Robe B 1")
		(BoneHash_array[b] == "1cfe0ab9"):(BoneName = "Robe B 2")
		(BoneHash_array[b] == "85f75b03"):(BoneName = "Robe B 3")
		(BoneHash_array[b] == "f2f06b95"):(BoneName = "Robe B 4")
		(BoneHash_array[b] == "6c94fe36"):(BoneName = "Robe B 5")
		(BoneHash_array[b] == "d3455d4a"):(BoneName = "Robe C 1")
		(BoneHash_array[b] == "a4426ddc"):(BoneName = "Robe C 2")
		(BoneHash_array[b] == "3d4b3c66"):(BoneName = "Robe C 3")
		(BoneHash_array[b] == "4a4c0cf0"):(BoneName = "Robe C 4")
		(BoneHash_array[b] == "d4289953"):(BoneName = "Robe C 5")
		(BoneHash_array[b] == "4e9265f3"):(BoneName = "Robe D 1")
		(BoneHash_array[b] == "39955565"):(BoneName = "Robe D 2")
		(BoneHash_array[b] == "a09c04df"):(BoneName = "Robe D 3")
		(BoneHash_array[b] == "d79b3449"):(BoneName = "Robe D 4")
		(BoneHash_array[b] == "49ffa1ea"):(BoneName = "Robe D 5")
		(BoneHash_array[b] == "f62e0296"):(BoneName = "Robe E 1")
		(BoneHash_array[b] == "81293200"):(BoneName = "Robe E 2")
		(BoneHash_array[b] == "182063ba"):(BoneName = "Robe E 3")
		(BoneHash_array[b] == "6f27532c"):(BoneName = "Robe E 4")
		(BoneHash_array[b] == "f143c68f"):(BoneName = "Robe E 5")
		(BoneHash_array[b] == "e49bad78"):(BoneName = "Robe F 1")
		(BoneHash_array[b] == "939c9dee"):(BoneName = "Robe F 2")
		(BoneHash_array[b] == "a95cc54"):(BoneName = "Robe F 3")
		(BoneHash_array[b] == "7d92fcc2"):(BoneName = "Robe F 4")
		(BoneHash_array[b] == "e3f66961"):(BoneName = "Robe F 5")
		(BoneHash_array[b] == "5c27ca1d"):(BoneName = "Robe G 1")
		(BoneHash_array[b] == "2b20fa8b"):(BoneName = "Robe G 2")
		(BoneHash_array[b] == "b229ab31"):(BoneName = "Robe G 3")
		(BoneHash_array[b] == "c52e9ba7"):(BoneName = "Robe G 4")
		(BoneHash_array[b] == "5b4a0e04"):(BoneName = "Robe G 5")
		(BoneHash_array[b] == "444da4b"):(BoneName = "Robe H 1")
		(BoneHash_array[b] == "7343eadd"):(BoneName = "Robe H 2")
		(BoneHash_array[b] == "ea4abb67"):(BoneName = "Robe H 3")
		(BoneHash_array[b] == "9d4d8bf1"):(BoneName = "Robe H 4")
		(BoneHash_array[b] == "3291e52"):(BoneName = "Robe H 5")
		(BoneHash_array[b] == "bcf8bd2e"):(BoneName = "Robe I 1")
		(BoneHash_array[b] == "cbff8db8"):(BoneName = "Robe I 2")
		(BoneHash_array[b] == "52f6dc02"):(BoneName = "Robe I 3")
		(BoneHash_array[b] == "25f1ec94"):(BoneName = "Robe I 4")
		(BoneHash_array[b] == "bb957937"):(BoneName = "Robe I 5")
		(BoneHash_array[b] == "7ca79929"):(BoneName = "Robe J 1")
		(BoneHash_array[b] == "ba0a9bf"):(BoneName = "Robe J 2")
		(BoneHash_array[b] == "92a9f805"):(BoneName = "Robe J 3")
		(BoneHash_array[b] == "e5aec893"):(BoneName = "Robe J 4")
		(BoneHash_array[b] == "7bca5d30"):(BoneName = "Robe J 5")
		(BoneHash_array[b] == "6e1236c7"):(BoneName = "Robe K 1")
		(BoneHash_array[b] == "19150651"):(BoneName = "Robe K 2")
		(BoneHash_array[b] == "801c57eb"):(BoneName = "Robe K 3")
		(BoneHash_array[b] == "f71b677d"):(BoneName = "Robe K 4")
		(BoneHash_array[b] == "697ff2de"):(BoneName = "Robe K 5")
		(BoneHash_array[b] == "d6ae51a2"):(BoneName = "Robe L 1")
		(BoneHash_array[b] == "a1a96134"):(BoneName = "Robe L 2")
		(BoneHash_array[b] == "38a0308e"):(BoneName = "Robe L 3")
		(BoneHash_array[b] == "4fa70018"):(BoneName = "Robe L 4")
		(BoneHash_array[b] == "d1c395bb"):(BoneName = "Robe L 5")
		(BoneHash_array[b] == "57a28b67"):(BoneName = "Robe Under Front Left 1")
		(BoneHash_array[b] == "20a5bbf1"):(BoneName = "Robe Under Front Left 2")
		(BoneHash_array[b] == "b9acea4b"):(BoneName = "Robe Under Front Left 3")
		(BoneHash_array[b] == "45172489"):(BoneName = "Robe Under Left 1")
		(BoneHash_array[b] == "3210141f"):(BoneName = "Robe Under Left 2")
		(BoneHash_array[b] == "ab1945a5"):(BoneName = "Robe Under Left 3")
		(BoneHash_array[b] == "fdab43ec"):(BoneName = "Robe Under Back 1")
		(BoneHash_array[b] == "8aac737a"):(BoneName = "Robe Under Back 2")
		(BoneHash_array[b] == "13a522c0"):(BoneName = "Robe Under Back 3")
		(BoneHash_array[b] == "607c7b55"):(BoneName = "Robe Under Right 1")
		(BoneHash_array[b] == "177b4bc3"):(BoneName = "Robe Under Right 2")
		(BoneHash_array[b] == "8e721a79"):(BoneName = "Robe Under Right 3")
		(BoneHash_array[b] == "d8c01c30"):(BoneName = "Robe Under Front Right 1")
		(BoneHash_array[b] == "afc72ca6"):(BoneName = "Robe Under Front Right 2")
		(BoneHash_array[b] == "36ce7d1c"):(BoneName = "Robe Under Front Right 3")
		(BoneHash_array[b] == "919587f7"):(BoneName = "Mane Bottom")
		(BoneHash_array[b] == "58a55abd"):(BoneName = "Mane Right")
		(BoneHash_array[b] == "a2aa67de"):(BoneName = "Mane Left")
		(BoneHash_array[b] == "12f9055"):(BoneName = "Mane Top")
		(BoneHash_array[b] == "86cdb09a"):(BoneName = "Mane Back A")
		(BoneHash_array[b] == "65fee60f"):(BoneName = "Mane Back B")
		(BoneHash_array[b] == "f10d2ec6"):(BoneName = "Mane Back C")
		(BoneHash_array[b] == "6e999b55"):(BoneName = "Right Front Claws")
		(BoneHash_array[b] == "9496a636"):(BoneName = "Left Front Claws")
		(BoneHash_array[b] == "ff502844"):(BoneName = "Right Back Claws")
		(BoneHash_array[b] == "55f1527"):(BoneName = "Left Back Claws")
		(BoneHash_array[b] == "618a1576"):(BoneName = "Right Arm Guard")
		(BoneHash_array[b] == "b5cb2aa9"):(BoneName = "Left Arm Guard")
		(BoneHash_array[b] == "66e7d16f"):(BoneName = "Right Leg Guard")
		(BoneHash_array[b] == "b2a6eeb0"):(BoneName = "Left Leg Guard")
		(BoneHash_array[b] == "55cd90aa"):(BoneName = "Right Arm Armor")
		(BoneHash_array[b] == "afc2adc9"):(BoneName = "Left Arm Armor")
		(BoneHash_array[b] == "6d04beeb"):(BoneName = "Right Leg Armor")
		(BoneHash_array[b] == "970b8388"):(BoneName = "Left Leg Armor")
		(BoneHash_array[b] == "eadd8592"):(BoneName = "Neck 1")
		(BoneHash_array[b] == "9ddab504"):(BoneName = "Neck 2")
		(BoneHash_array[b] == "4d3e4be"):(BoneName = "Neck 3")
		(BoneHash_array[b] == "73d4d428"):(BoneName = "Neck 4")
		(BoneHash_array[b] == "777bac08"):(BoneName = "Right Wing 1")
		(BoneHash_array[b] == "7c9c9e"):(BoneName = "Right Wing 2")
		(BoneHash_array[b] == "9975cd24"):(BoneName = "Right Wing 3")
		(BoneHash_array[b] == "ee72fdb2"):(BoneName = "Right Wing 4")
		(BoneHash_array[b] == "70166811"):(BoneName = "Right Wing 5")
		(BoneHash_array[b] == "7115887"):(BoneName = "Right Wing 6")
		(BoneHash_array[b] == "8c11e955"):(BoneName = "Right Wing 2B")
		(BoneHash_array[b] == "61c32272"):(BoneName = "Left Wing 1")
		(BoneHash_array[b] == "16c412e4"):(BoneName = "Left Wing 2")
		(BoneHash_array[b] == "8fcd435e"):(BoneName = "Left Wing 3")
		(BoneHash_array[b] == "f8ca73c8"):(BoneName = "Left Wing 4")
		(BoneHash_array[b] == "66aee66b"):(BoneName = "Left Wing 5")
		(BoneHash_array[b] == "11a9d6fd"):(BoneName = "Left Wing 6")
		(BoneHash_array[b] == "53c1c0b6"):(BoneName = "Left Wing 2B")
		(BoneHash_array[b] == "5883a8e0"):(BoneName = "Beak Top")
		(BoneHash_array[b] == "32338812"):(BoneName = "Beak Bottom")
		(BoneHash_array[b] == "6ab9a3b7"):(BoneName = "Shuriken Root")
		(BoneHash_array[b] == "be30ec24"):(BoneName = "Shuriken Top")
		(BoneHash_array[b] == "52e585c9"):(BoneName = "Shuriken Top Tip")
		(BoneHash_array[b] == "5090196b"):(BoneName = "Shuriken Top Base")
		(BoneHash_array[b] == "65db276"):(BoneName = "Shuriken Bottom")
		(BoneHash_array[b] == "f4928e7d"):(BoneName = "Shuriken Bottom Tip")
		(BoneHash_array[b] == "6df030db"):(BoneName = "Shuriken Bottom Base")
		(BoneHash_array[b] == "562e86b7"):(BoneName = "Shuriken Right")
		(BoneHash_array[b] == "c57a94e0"):(BoneName = "Shuriken Right Tip")
		(BoneHash_array[b] == "2a504a0b"):(BoneName = "Shuriken Right Base")
		(BoneHash_array[b] == "ade3d1e3"):(BoneName = "Shuriken Left")
		(BoneHash_array[b] == "630d9f54"):(BoneName = "Shuriken Left Tip")
		(BoneHash_array[b] == "173063bb"):(BoneName = "Shuriken Left Base")
		(BoneHash_array[b] == "42b267d8"):(BoneName = "Hair Left Twintail 1") -- Dark HDDs
		(BoneHash_array[b] == "35b5574e"):(BoneName = "Hair Left Twintail 2")
		(BoneHash_array[b] == "acbc06f4"):(BoneName = "Hair Left Twintail 3")
		(BoneHash_array[b] == "dbbb3662"):(BoneName = "Hair Left Twintail 4")
		(BoneHash_array[b] == "45dfa3c1"):(BoneName = "Hair Left Twintail 5")
		(BoneHash_array[b] == "540ae9a2"):(BoneName = "Hair Right Twintail 1")
		(BoneHash_array[b] == "230dd934"):(BoneName = "Hair Right Twintail 2")
		(BoneHash_array[b] == "ba04888e"):(BoneName = "Hair Right Twintail 3")
		(BoneHash_array[b] == "cd03b818"):(BoneName = "Hair Right Twintail 4")
		(BoneHash_array[b] == "53672dbb"):(BoneName = "Hair Right Twintail 5")
		(BoneHash_array[b] == "c09935db"):(BoneName = "Right Shoulder Wing")
		(BoneHash_array[b] == "3a9608b8"):(BoneName = "Left Shoulder Wing")
		(BoneHash_array[b] == "32ba6e5f"):(BoneName = "Effect 1")

		-- Neptunia PP

		(BoneHash_array[b] == "f71e8cfe"):(BoneName = "Skirt A 1")
		(BoneHash_array[b] == "8019bc68"):(BoneName = "Skirt A 2")
		(BoneHash_array[b] == "1910edd2"):(BoneName = "Skirt A 3")
		(BoneHash_array[b] == "6e17dd44"):(BoneName = "Skirt A 4")
		(BoneHash_array[b] == "f07348e7"):(BoneName = "Skirt A 5")
		(BoneHash_array[b] == "87747871"):(BoneName = "Skirt A 6")
		(BoneHash_array[b] == "1e7d29cb"):(BoneName = "Skirt A 7")
		(BoneHash_array[b] == "697a195d"):(BoneName = "Skirt A 8")
		(BoneHash_array[b] == "f9c504cc"):(BoneName = "Skirt A 9")

		(BoneHash_array[b] == "e5ab2310"):(BoneName = "Skirt B 1")
		(BoneHash_array[b] == "92ac1386"):(BoneName = "Skirt B 2")
		(BoneHash_array[b] == "ba5423c"):(BoneName = "Skirt B 3")
		(BoneHash_array[b] == "7ca272aa"):(BoneName = "Skirt B 4")
		(BoneHash_array[b] == "e2c6e709"):(BoneName = "Skirt B 5")
		(BoneHash_array[b] == "95c1d79f"):(BoneName = "Skirt B 6")
		(BoneHash_array[b] == "cc88625"):(BoneName = "Skirt B 7")
		(BoneHash_array[b] == "7bcfb6b3"):(BoneName = "Skirt B 8")
		(BoneHash_array[b] == "eb70ab22"):(BoneName = "Skirt B 9")

		(BoneHash_array[b] == "5d174475"):(BoneName = "Skirt C 1")
		(BoneHash_array[b] == "2a1074e3"):(BoneName = "Skirt C 2")
		(BoneHash_array[b] == "b3192559"):(BoneName = "Skirt C 3")
		(BoneHash_array[b] == "c41e15cf"):(BoneName = "Skirt C 4")
		(BoneHash_array[b] == "5a7a806c"):(BoneName = "Skirt C 5")
		(BoneHash_array[b] == "2d7db0fa"):(BoneName = "Skirt C 6")
		(BoneHash_array[b] == "b474e140"):(BoneName = "Skirt C 7")
		(BoneHash_array[b] == "c373d1d6"):(BoneName = "Skirt C 8")
		(BoneHash_array[b] == "53cccc47"):(BoneName = "Skirt C 9")

		(BoneHash_array[b] == "c0c07ccc"):(BoneName = "Skirt D 1")
		(BoneHash_array[b] == "b7c74c5a"):(BoneName = "Skirt D 2")
		(BoneHash_array[b] == "2ece1de0"):(BoneName = "Skirt D 3")
		(BoneHash_array[b] == "59c92d76"):(BoneName = "Skirt D 4")
		(BoneHash_array[b] == "c7adb8d5"):(BoneName = "Skirt D 5")
		(BoneHash_array[b] == "b0aa8843"):(BoneName = "Skirt D 6")
		(BoneHash_array[b] == "29a3d9f9"):(BoneName = "Skirt D 7")
		(BoneHash_array[b] == "5ea4e96f"):(BoneName = "Skirt D 8")
		(BoneHash_array[b] == "ce1bf4fe"):(BoneName = "Skirt D 9")

		(BoneHash_array[b] == "787c1ba9"):(BoneName = "Skirt E 1")
		(BoneHash_array[b] == "f7b2b3f"):(BoneName = "Skirt E 2")
		(BoneHash_array[b] == "96727a85"):(BoneName = "Skirt E 3")
		(BoneHash_array[b] == "e1754a13"):(BoneName = "Skirt E 4")
		(BoneHash_array[b] == "7f11dfb0"):(BoneName = "Skirt E 5")
		(BoneHash_array[b] == "816ef26"):(BoneName = "Skirt E 6")
		(BoneHash_array[b] == "911fbe9c"):(BoneName = "Skirt E 7")
		(BoneHash_array[b] == "e6188e0a"):(BoneName = "Skirt E 8")
		(BoneHash_array[b] == "76a7939b"):(BoneName = "Skirt E 9")

		(BoneHash_array[b] == "6ac9b447"):(BoneName = "Skirt F 1")
		(BoneHash_array[b] == "1dce84d1"):(BoneName = "Skirt F 2")
		(BoneHash_array[b] == "84c7d56b"):(BoneName = "Skirt F 3")
		(BoneHash_array[b] == "f3c0e5fd"):(BoneName = "Skirt F 4")
		(BoneHash_array[b] == "6da4705e"):(BoneName = "Skirt F 5")
		(BoneHash_array[b] == "1aa340c8"):(BoneName = "Skirt F 6")
		(BoneHash_array[b] == "83aa1172"):(BoneName = "Skirt F 7")
		(BoneHash_array[b] == "f4ad21e4"):(BoneName = "Skirt F 8")
		(BoneHash_array[b] == "64123c75"):(BoneName = "Skirt F 9")

		(BoneHash_array[b] == "d275d322"):(BoneName = "Skirt G 1")
		(BoneHash_array[b] == "a572e3b4"):(BoneName = "Skirt G 2")
		(BoneHash_array[b] == "3c7bb20e"):(BoneName = "Skirt G 3")
		(BoneHash_array[b] == "4b7c8298"):(BoneName = "Skirt G 4")
		(BoneHash_array[b] == "d518173b"):(BoneName = "Skirt G 5")
		(BoneHash_array[b] == "a21f27ad"):(BoneName = "Skirt G 6")
		(BoneHash_array[b] == "3b167617"):(BoneName = "Skirt G 7")
		(BoneHash_array[b] == "4c114681"):(BoneName = "Skirt G 8")
		(BoneHash_array[b] == "dcae5b10"):(BoneName = "Skirt G 9")

		(BoneHash_array[b] == "8a16c374"):(BoneName = "Skirt H 1")
		(BoneHash_array[b] == "fd11f3e2"):(BoneName = "Skirt H 2")
		(BoneHash_array[b] == "6418a258"):(BoneName = "Skirt H 3")
		(BoneHash_array[b] == "131f92ce"):(BoneName = "Skirt H 4")
		(BoneHash_array[b] == "8d7b076d"):(BoneName = "Skirt H 5")
		(BoneHash_array[b] == "fa7c37fb"):(BoneName = "Skirt H 6")
		(BoneHash_array[b] == "63756641"):(BoneName = "Skirt H 7")
		(BoneHash_array[b] == "147256d7"):(BoneName = "Skirt H 8")
		(BoneHash_array[b] == "84cd4b46"):(BoneName = "Skirt H 9")

		(BoneHash_array[b] == "32aaa411"):(BoneName = "Skirt I 1")
		(BoneHash_array[b] == "45ad9487"):(BoneName = "Skirt I 2")
		(BoneHash_array[b] == "dca4c53d"):(BoneName = "Skirt I 3")
		(BoneHash_array[b] == "aba3f5ab"):(BoneName = "Skirt I 4")
		(BoneHash_array[b] == "35c76008"):(BoneName = "Skirt I 5")
		(BoneHash_array[b] == "42c0509e"):(BoneName = "Skirt I 6")
		(BoneHash_array[b] == "dbc90124"):(BoneName = "Skirt I 7")
		(BoneHash_array[b] == "acce31b2"):(BoneName = "Skirt I 8")
		(BoneHash_array[b] == "3c712c23"):(BoneName = "Skirt I 9")

		(BoneHash_array[b] == "201f0bff"):(BoneName = "Skirt J 1")
		(BoneHash_array[b] == "57183b69"):(BoneName = "Skirt J 2")
		(BoneHash_array[b] == "ce116ad3"):(BoneName = "Skirt J 3")
		(BoneHash_array[b] == "b9165a45"):(BoneName = "Skirt J 4")
		(BoneHash_array[b] == "2772cfe6"):(BoneName = "Skirt J 5")
		(BoneHash_array[b] == "5075ff70"):(BoneName = "Skirt J 6")
		(BoneHash_array[b] == "c97caeca"):(BoneName = "Skirt J 7")
		(BoneHash_array[b] == "be7b9e5c"):(BoneName = "Skirt J 8")
		(BoneHash_array[b] == "2ec483cd"):(BoneName = "Skirt J 9")

		(BoneHash_array[b] == "98a36c9a"):(BoneName = "Skirt K 1")
		(BoneHash_array[b] == "efa45c0c"):(BoneName = "Skirt K 2")
		(BoneHash_array[b] == "76ad0db6"):(BoneName = "Skirt K 3")
		(BoneHash_array[b] == "1aa3d20"):(BoneName = "Skirt K 4")
		(BoneHash_array[b] == "9fcea883"):(BoneName = "Skirt K 5")
		(BoneHash_array[b] == "e8c99815"):(BoneName = "Skirt K 6")
		(BoneHash_array[b] == "71c0c9af"):(BoneName = "Skirt K 7")
		(BoneHash_array[b] == "6c7f939"):(BoneName = "Skirt K 8")
		(BoneHash_array[b] == "9678e4a8"):(BoneName = "Skirt K 9")

		(BoneHash_array[b] == "5745423"):(BoneName = "Skirt L 1")
		(BoneHash_array[b] == "727364b5"):(BoneName = "Skirt L 2")
		(BoneHash_array[b] == "eb7a350f"):(BoneName = "Skirt L 3")
		(BoneHash_array[b] == "9c7d0599"):(BoneName = "Skirt L 4")
		(BoneHash_array[b] == "219903a"):(BoneName = "Skirt L 5")
		(BoneHash_array[b] == "751ea0ac"):(BoneName = "Skirt L 6")
		(BoneHash_array[b] == "ec17f116"):(BoneName = "Skirt L 7")
		(BoneHash_array[b] == "9b10c180"):(BoneName = "Skirt L 8")
		(BoneHash_array[b] == "bafdc11"):(BoneName = "Skirt L 9")

		(BoneHash_array[b] == "bdc83346"):(BoneName = "Skirt M 1")
		(BoneHash_array[b] == "cacf03d0"):(BoneName = "Skirt M 2")
		(BoneHash_array[b] == "53c6526a"):(BoneName = "Skirt M 3")
		(BoneHash_array[b] == "24c162fc"):(BoneName = "Skirt M 4")
		(BoneHash_array[b] == "baa5f75f"):(BoneName = "Skirt M 5")
		(BoneHash_array[b] == "cda2c7c9"):(BoneName = "Skirt M 6")
		(BoneHash_array[b] == "54ab9673"):(BoneName = "Skirt M 7")
		(BoneHash_array[b] == "23aca6e5"):(BoneName = "Skirt M 8")

		(BoneHash_array[b] == "af7d9ca8"):(BoneName = "Skirt N 1")
		(BoneHash_array[b] == "d87aac3e"):(BoneName = "Skirt N 2")
		(BoneHash_array[b] == "4173fd84"):(BoneName = "Skirt N 3")
		(BoneHash_array[b] == "3674cd12"):(BoneName = "Skirt N 4")
		(BoneHash_array[b] == "a81058b1"):(BoneName = "Skirt N 5")
		(BoneHash_array[b] == "df176827"):(BoneName = "Skirt N 6")
		(BoneHash_array[b] == "461e399d"):(BoneName = "Skirt N 7")
		(BoneHash_array[b] == "3119090b"):(BoneName = "Skirt N 8")
		(BoneHash_array[b] == "a1a6149a"):(BoneName = "Skirt N 9")

		-- Senran Kagura

		(BoneHash_array[b] == "795fe0d3"):(BoneName = "Right Eye")
		(BoneHash_array[b] == "34576996"):(BoneName = "Right Pupil")
		(BoneHash_array[b] == "b3fa0aa1"):(BoneName = "Right Eye Glint")
		(BoneHash_array[b] == "8350ddb0"):(BoneName = "Left Eye")
		(BoneHash_array[b] == "ce5854f5"):(BoneName = "Left Pupil")
		(BoneHash_array[b] == "33c2a0d"):(BoneName = "Left Eye Glint")
		(BoneHash_array[b] == "2eda2498"):(BoneName = "Nose")
		(BoneHash_array[b] == "4e6bc76b"):(BoneName = "Cheeks")

		(BoneHash_array[b] == "396cf7fd"):(BoneName = "Mouth Something")
		(BoneHash_array[b] == "2522c9da"):(BoneName = "Mouth Root")
		(BoneHash_array[b] == "8b500227"):(BoneName = "Lip Top Right")
		(BoneHash_array[b] == "fc5732b1"):(BoneName = "Lip Top Middle Right")
		(BoneHash_array[b] == "655e630b"):(BoneName = "Lip Top Middle")
		(BoneHash_array[b] == "1259539d"):(BoneName = "Lip Top Middle Left")
		(BoneHash_array[b] == "8c3dc63e"):(BoneName = "Lip Top Left")
		(BoneHash_array[b] == "c77036e6"):(BoneName = "Lip Bottom Right")
		(BoneHash_array[b] == "b0770670"):(BoneName = "Lip Bottom Middle Right")
		(BoneHash_array[b] == "297e57ca"):(BoneName = "Lip Bottom Middle")
		(BoneHash_array[b] == "5e79675c"):(BoneName = "Lip Bottom Middle Left")
		(BoneHash_array[b] == "c01df2ff"):(BoneName = "Lip Bottom Left")
		(BoneHash_array[b] == "97feb3cb"):(BoneName = "Lip Corner Right")
		(BoneHash_array[b] == "81463db1"):(BoneName = "Lip Corner Left")
		(BoneHash_array[b] == "f5814ed6"):(BoneName = "Jaw")
		(BoneHash_array[b] == "514cf8c0"):(BoneName = "Jaw 2")
		(BoneHash_array[b] == "b7be8b1c"):(BoneName = "Chin")
		(BoneHash_array[b] == "c0b9bb8a"):(BoneName = "Chin 2")
		(BoneHash_array[b] == "65ea9993"):(BoneName = "Tongue 1")
		(BoneHash_array[b] == "12eda905"):(BoneName = "Tongue 2")
		(BoneHash_array[b] == "8be4f8bf"):(BoneName = "Tongue 3")
		(BoneHash_array[b] == "fce3c829"):(BoneName = "Tongue 4")
		(BoneHash_array[b] == "62875d8a"):(BoneName = "Tongue 5")
		(BoneHash_array[b] == "67053086"):(BoneName = "Teeth Top Root")
		(BoneHash_array[b] == "10020010"):(BoneName = "Teeth Top")
		(BoneHash_array[b] == "b8bb069b"):(BoneName = "Teeth Bottom Root")
		(BoneHash_array[b] == "cfbc360d"):(BoneName = "Teeth Bottom")

		(BoneHash_array[b] == "d143f3fa"):(BoneName = "Right Eyelid Inner")
		(BoneHash_array[b] == "a644c36c"):(BoneName = "Right Eyelid Top 1")
		(BoneHash_array[b] == "3f4d92d6"):(BoneName = "Right Eyelid Top 2")
		(BoneHash_array[b] == "484aa240"):(BoneName = "Right Eyelid Top 3")
		(BoneHash_array[b] == "d62e37e3"):(BoneName = "Right Eyelid Top 4")
		(BoneHash_array[b] == "a1290775"):(BoneName = "Right Eyelid Top 5")
		(BoneHash_array[b] == "382056cf"):(BoneName = "Right Eyelid Top 6")
		(BoneHash_array[b] == "4f276659"):(BoneName = "Right Eyelid Top 7")
		(BoneHash_array[b] == "df987bc8"):(BoneName = "Right Eyelid Top 8")
		(BoneHash_array[b] == "a89f4b5e"):(BoneName = "Right Eyelid Top 9")
		(BoneHash_array[b] == "c858c2bb"):(BoneName = "Right Eyelid Top 10")
		(BoneHash_array[b] == "1d413b49"):(BoneName = "Right Eyelid Lower 1")
		(BoneHash_array[b] == "6a460bdf"):(BoneName = "Right Eyelid Lower 2")
		(BoneHash_array[b] == "f34f5a65"):(BoneName = "Right Eyelid Lower 3")
		(BoneHash_array[b] == "84486af3"):(BoneName = "Right Eyelid Lower 4")
		(BoneHash_array[b] == "c7fb7d80"):(BoneName = "Left Eyelid Inner")
		(BoneHash_array[b] == "b0fc4d16"):(BoneName = "Left Eyelid Top 1")
		(BoneHash_array[b] == "29f51cac"):(BoneName = "Left Eyelid Top 2")
		(BoneHash_array[b] == "5ef22c3a"):(BoneName = "Left Eyelid Top 3")
		(BoneHash_array[b] == "c096b999"):(BoneName = "Left Eyelid Top 4")
		(BoneHash_array[b] == "b791890f"):(BoneName = "Left Eyelid Top 5")
		(BoneHash_array[b] == "2e98d8b5"):(BoneName = "Left Eyelid Top 6")
		(BoneHash_array[b] == "599fe823"):(BoneName = "Left Eyelid Top 7")
		(BoneHash_array[b] == "c920f5b2"):(BoneName = "Left Eyelid Top 8")
		(BoneHash_array[b] == "be27c524"):(BoneName = "Left Eyelid Top 9")
		(BoneHash_array[b] == "dee04cc1"):(BoneName = "Left Eyelid Top 10")
		(BoneHash_array[b] == "bf9b533"):(BoneName = "Left Eyelid Lower 1")
		(BoneHash_array[b] == "7cfe85a5"):(BoneName = "Left Eyelid Lower 2")
		(BoneHash_array[b] == "e5f7d41f"):(BoneName = "Left Eyelid Lower 3")
		(BoneHash_array[b] == "92f0e489"):(BoneName = "Left Eyelid Lower 4")

		(BoneHash_array[b] == "40aad366"):(BoneName = "Right Eyebrow Inner")
		(BoneHash_array[b] == "37ade3f0"):(BoneName = "Right Eyebrow Center Inner")
		(BoneHash_array[b] == "aea4b24a"):(BoneName = "Right Eyebrow Center")
		(BoneHash_array[b] == "d9a382dc"):(BoneName = "Right Eyebrow Center Outer")
		(BoneHash_array[b] == "47c7177f"):(BoneName = "Right Eyebrow Outer")
		(BoneHash_array[b] == "7edb887b"):(BoneName = "Right Eyebrow Mark Root")
		(BoneHash_array[b] == "10921b9e"):(BoneName = "Right Eyebrow Mark Inner")
		(BoneHash_array[b] == "67952b08"):(BoneName = "Right Eyebrow Mark Outer")
		(BoneHash_array[b] == "56125d1c"):(BoneName = "Left Eyebrow Inner")
		(BoneHash_array[b] == "21156d8a"):(BoneName = "Left Eyebrow Center Inner")
		(BoneHash_array[b] == "b81c3c30"):(BoneName = "Left Eyebrow Center")
		(BoneHash_array[b] == "cf1b0ca6"):(BoneName = "Left Eyebrow Center Outer")
		(BoneHash_array[b] == "517f9905"):(BoneName = "Left Eyebrow Outer")
		(BoneHash_array[b] == "84d4b518"):(BoneName = "Left Eyebrow Mark Root")
		(BoneHash_array[b] == "62a95e4"):(BoneName = "Left Eyebrow Mark Inner")
		(BoneHash_array[b] == "712da572"):(BoneName = "Left Eyebrow Mark Outer")

		(BoneHash_array[b] == "ebec70c7"):(BoneName = "Skirt Root")
		(BoneHash_array[b] == "9ceb4051"):(BoneName = "Skirt Center")

		(BoneHash_array[b] == "14d46df"):(BoneName = "Skirt A 1")
		(BoneHash_array[b] == "764a7649"):(BoneName = "Skirt A 2")
		(BoneHash_array[b] == "ef4327f3"):(BoneName = "Skirt A 3")
		(BoneHash_array[b] == "98441765"):(BoneName = "Skirt A 4")
		(BoneHash_array[b] == "62082c6"):(BoneName = "Skirt A 5")
		(BoneHash_array[b] == "7127b250"):(BoneName = "Skirt A 6")

		(BoneHash_array[b] == "13f8e931"):(BoneName = "Skirt B 1")
		(BoneHash_array[b] == "64ffd9a7"):(BoneName = "Skirt B 2")
		(BoneHash_array[b] == "fdf6881d"):(BoneName = "Skirt B 3")
		(BoneHash_array[b] == "8af1b88b"):(BoneName = "Skirt B 4")
		(BoneHash_array[b] == "14952d28"):(BoneName = "Skirt B 5")
		(BoneHash_array[b] == "63921dbe"):(BoneName = "Skirt B 6")

		(BoneHash_array[b] == "ab448e54"):(BoneName = "Skirt C 1")
		(BoneHash_array[b] == "dc43bec2"):(BoneName = "Skirt C 2")
		(BoneHash_array[b] == "454aef78"):(BoneName = "Skirt C 3")
		(BoneHash_array[b] == "324ddfee"):(BoneName = "Skirt C 4")
		(BoneHash_array[b] == "ac294a4d"):(BoneName = "Skirt C 5")
		(BoneHash_array[b] == "db2e7adb"):(BoneName = "Skirt C 6")

		(BoneHash_array[b] == "3693b6ed"):(BoneName = "Skirt D 1")
		(BoneHash_array[b] == "4194867b"):(BoneName = "Skirt D 2")
		(BoneHash_array[b] == "d89dd7c1"):(BoneName = "Skirt D 3")
		(BoneHash_array[b] == "af9ae757"):(BoneName = "Skirt D 4")
		(BoneHash_array[b] == "31fe72f4"):(BoneName = "Skirt D 5")
		(BoneHash_array[b] == "46f94262"):(BoneName = "Skirt D 6")

		(BoneHash_array[b] == "8e2fd188"):(BoneName = "Skirt E 1")
		(BoneHash_array[b] == "f928e11e"):(BoneName = "Skirt E 2")
		(BoneHash_array[b] == "6021b0a4"):(BoneName = "Skirt E 3")
		(BoneHash_array[b] == "17268032"):(BoneName = "Skirt E 4")
		(BoneHash_array[b] == "89421591"):(BoneName = "Skirt E 5")
		(BoneHash_array[b] == "fe452507"):(BoneName = "Skirt E 6")

		(BoneHash_array[b] == "9c9a7e66"):(BoneName = "Skirt F 1")
		(BoneHash_array[b] == "eb9d4ef0"):(BoneName = "Skirt F 2")
		(BoneHash_array[b] == "72941f4a"):(BoneName = "Skirt F 3")
		(BoneHash_array[b] == "5932fdc"):(BoneName = "Skirt F 4")
		(BoneHash_array[b] == "9bf7ba7f"):(BoneName = "Skirt F 5")
		(BoneHash_array[b] == "ecf08ae9"):(BoneName = "Skirt F 6")

		(BoneHash_array[b] == "24261903"):(BoneName = "Skirt G 1")
		(BoneHash_array[b] == "53212995"):(BoneName = "Skirt G 2")
		(BoneHash_array[b] == "ca28782f"):(BoneName = "Skirt G 3")
		(BoneHash_array[b] == "bd2f48b9"):(BoneName = "Skirt G 4")
		(BoneHash_array[b] == "234bdd1a"):(BoneName = "Skirt G 5")
		(BoneHash_array[b] == "544ced8c"):(BoneName = "Skirt G 6")

		(BoneHash_array[b] == "7c450955"):(BoneName = "Skirt H 1")
		(BoneHash_array[b] == "b4239c3"):(BoneName = "Skirt H 2")
		(BoneHash_array[b] == "924b6879"):(BoneName = "Skirt H 3")
		(BoneHash_array[b] == "e54c58ef"):(BoneName = "Skirt H 4")
		(BoneHash_array[b] == "7b28cd4c"):(BoneName = "Skirt H 5")
		(BoneHash_array[b] == "c2ffdda"):(BoneName = "Skirt H 6")

		(BoneHash_array[b] == "c4f96e30"):(BoneName = "Skirt I 1")
		(BoneHash_array[b] == "b3fe5ea6"):(BoneName = "Skirt I 2")
		(BoneHash_array[b] == "2af70f1c"):(BoneName = "Skirt I 3")
		(BoneHash_array[b] == "5df03f8a"):(BoneName = "Skirt I 4")
		(BoneHash_array[b] == "c394aa29"):(BoneName = "Skirt I 5")
		(BoneHash_array[b] == "b4939abf"):(BoneName = "Skirt I 6")

		(BoneHash_array[b] == "d64cc1de"):(BoneName = "Skirt J 1")
		(BoneHash_array[b] == "a14bf148"):(BoneName = "Skirt J 2")
		(BoneHash_array[b] == "3842a0f2"):(BoneName = "Skirt J 3")
		(BoneHash_array[b] == "4f459064"):(BoneName = "Skirt J 4")
		(BoneHash_array[b] == "d12105c7"):(BoneName = "Skirt J 5")
		(BoneHash_array[b] == "a6263551"):(BoneName = "Skirt J 6")

		(BoneHash_array[b] == "6ef0a6bb"):(BoneName = "Skirt K 1")
		(BoneHash_array[b] == "19f7962d"):(BoneName = "Skirt K 2")
		(BoneHash_array[b] == "80fec797"):(BoneName = "Skirt K 3")
		(BoneHash_array[b] == "f7f9f701"):(BoneName = "Skirt K 4")
		(BoneHash_array[b] == "699d62a2"):(BoneName = "Skirt K 5")
		(BoneHash_array[b] == "1e9a5234"):(BoneName = "Skirt K 6")

		(BoneHash_array[b] == "f3279e02"):(BoneName = "Skirt L 1")
		(BoneHash_array[b] == "8420ae94"):(BoneName = "Skirt L 2")
		(BoneHash_array[b] == "1d29ff2e"):(BoneName = "Skirt L 3")
		(BoneHash_array[b] == "6a2ecfb8"):(BoneName = "Skirt L 4")
		(BoneHash_array[b] == "f44a5a1b"):(BoneName = "Skirt L 5")
		(BoneHash_array[b] == "834d6a8d"):(BoneName = "Skirt L 6")

		(BoneHash_array[b] == "d9acd947"):(BoneName = "Scarf Front")
		(BoneHash_array[b] == "64079a9"):(BoneName = "Scarf 1")
		(BoneHash_array[b] == "7147493f"):(BoneName = "Scarf 2")
		(BoneHash_array[b] == "e84e1885"):(BoneName = "Scarf 3")
		(BoneHash_array[b] == "9f492813"):(BoneName = "Scarf 4")
		(BoneHash_array[b] == "12dbdb0"):(BoneName = "Scarf 5")

		(BoneHash_array[b] == "3ae9256c"):(BoneName = "Necktie 1")
		(BoneHash_array[b] == "4dee15fa"):(BoneName = "Necktie 2")
		(BoneHash_array[b] == "d4e74440"):(BoneName = "Necktie 3")
		(BoneHash_array[b] == "a3e074d6"):(BoneName = "Necktie 4")
		(BoneHash_array[b] == "3d84e175"):(BoneName = "Necktie 5")
		(BoneHash_array[b] == "4a83d1e3"):(BoneName = "Necktie 6")
		(BoneHash_array[b] == "d38a8059"):(BoneName = "Necktie 7")

		(BoneHash_array[b] == "b44ed5d0"):(BoneName = "Wing Root") -- SK:SV
		(BoneHash_array[b] == "50d61004"):(BoneName = "Wing Right 1")
		(BoneHash_array[b] == "c9df41be"):(BoneName = "Wing Right 2")
		(BoneHash_array[b] == "bed87128"):(BoneName = "Wing Right 3")
		(BoneHash_array[b] == "39e7331d"):(BoneName = "Wing Left 1")
		(BoneHash_array[b] == "a0ee62a7"):(BoneName = "Wing Left 2")
		(BoneHash_array[b] == "d7e95231"):(BoneName = "Wing Left 3")
		(BoneHash_array[b] == "7c855b6c"):(BoneName = "Wing Right 1") -- SK:EV, NepU
		(BoneHash_array[b] == "b826bfa"):(BoneName = "Wing Right 2")
		(BoneHash_array[b] == "928b3a40"):(BoneName = "Wing Right 3")
		(BoneHash_array[b] == "cc437bc0"):(BoneName = "Wing Left 1")
		(BoneHash_array[b] == "bb444b56"):(BoneName = "Wing Left 2")
		(BoneHash_array[b] == "224d1aec"):(BoneName = "Wing Left 3")
		(BoneHash_array[b] == "8b873549"):(BoneName = "Wing Right 1")
		(BoneHash_array[b] == "128e64f3"):(BoneName = "Wing Right 2")
		(BoneHash_array[b] == "65895465"):(BoneName = "Wing Right 3")
		(BoneHash_array[b] == "e2b61650"):(BoneName = "Wing Left 1")
		(BoneHash_array[b] == "7bbf47ea"):(BoneName = "Wing Left 2")
		(BoneHash_array[b] == "cb8777c"):(BoneName = "Wing Left 3")
		
		(BoneHash_array[b] == "8b062d05"):(BoneName = "Tail 1") -- SK:SV Mirai
		(BoneHash_array[b] == "120f7cbf"):(BoneName = "Tail 2")
		(BoneHash_array[b] == "65084c29"):(BoneName = "Tail 3")
		(BoneHash_array[b] == "fb6cd98a"):(BoneName = "Tail 4")
		(BoneHash_array[b] == "8c6be91c"):(BoneName = "Tail 5")
		(BoneHash_array[b] == "1562b8a6"):(BoneName = "Tail 6")
		(BoneHash_array[b] == "639b977d"):(BoneName = "Ribbon Bow Right Root")
		(BoneHash_array[b] == "19fda3b9"):(BoneName = "Ribbon Bow Right 1")
		(BoneHash_array[b] == "6efa932f"):(BoneName = "Ribbon Bow Right 2")
		(BoneHash_array[b] == "fa92c6c7"):(BoneName = "Ribbon Tail Right Root")
		(BoneHash_array[b] == "b480c57"):(BoneName = "Ribbon Tail Right 1")
		(BoneHash_array[b] == "7c4f3cc1"):(BoneName = "Ribbon Tail Right 2")
		(BoneHash_array[b] == "e5466d7b"):(BoneName = "Ribbon Tail Right 3")
		(BoneHash_array[b] == "92415ded"):(BoneName = "Ribbon Tail Right 4")
		(BoneHash_array[b] == "75231907"):(BoneName = "Ribbon Bow Left Root")
		(BoneHash_array[b] == "2021c052"):(BoneName = "Ribbon Bow Left 1")
		(BoneHash_array[b] == "5726f0c4"):(BoneName = "Ribbon Bow Left 2")
		(BoneHash_array[b] == "ec2a48bd"):(BoneName = "Ribbon Tail Left Root")
		(BoneHash_array[b] == "32946fbc"):(BoneName = "Ribbon Tail Left 1")
		(BoneHash_array[b] == "45935f2a"):(BoneName = "Ribbon Tail Left 2")
		(BoneHash_array[b] == "dc9a0e90"):(BoneName = "Ribbon Tail Left 3")
		(BoneHash_array[b] == "ab9d3e06"):(BoneName = "Ribbon Tail Left 4")

		(BoneHash_array[b] == "451ce3ea"):(BoneName = "Right Gatling")
		(BoneHash_array[b] == "bf13de89"):(BoneName = "Left Gatling")
		(BoneHash_array[b] == "b5e9a4a0"):(BoneName = "Bowstring")
		(BoneHash_array[b] == "2c271cf3"):(BoneName = "Right Forearm Cloth A 1")
		(BoneHash_array[b] == "5b202c65"):(BoneName = "Right Forearm Cloth A 2")
		(BoneHash_array[b] == "2de576c4"):(BoneName = "Right Forearm Cloth B 1")
		(BoneHash_array[b] == "5ae24652"):(BoneName = "Right Forearm Cloth B 2")
		(BoneHash_array[b] == "2fa3c89d"):(BoneName = "Right Forearm Cloth C 1")
		(BoneHash_array[b] == "58a4f80b"):(BoneName = "Right Forearm Cloth C 2")
		(BoneHash_array[b] == "2e61a2aa"):(BoneName = "Right Forearm Cloth D 1")
		(BoneHash_array[b] == "5966923c"):(BoneName = "Right Forearm Cloth D 2")
		(BoneHash_array[b] == "2b2eb42f"):(BoneName = "Right Arm Cloth A 1")
		(BoneHash_array[b] == "5c2984b9"):(BoneName = "Right Arm Cloth A 2")
		(BoneHash_array[b] == "2aecde18"):(BoneName = "Right Arm Cloth B 1")
		(BoneHash_array[b] == "5debee8e"):(BoneName = "Right Arm Cloth B 2")
		(BoneHash_array[b] == "9ce13c5f"):(BoneName = "Left Forearm Cloth A 1")
		(BoneHash_array[b] == "ebe60cc9"):(BoneName = "Left Forearm Cloth A 2")
		(BoneHash_array[b] == "9d235668"):(BoneName = "Left Forearm Cloth B 1")
		(BoneHash_array[b] == "ea2466fe"):(BoneName = "Left Forearm Cloth B 2")
		(BoneHash_array[b] == "9f65e831"):(BoneName = "Left Forearm Cloth C 1")
		(BoneHash_array[b] == "e862d8a7"):(BoneName = "Left Forearm Cloth C 2")
		(BoneHash_array[b] == "9ea78206"):(BoneName = "Left Forearm Cloth D 1")
		(BoneHash_array[b] == "e9a0b290"):(BoneName = "Left Forearm Cloth D 2")
		(BoneHash_array[b] == "9be89483"):(BoneName = "Left Arm Cloth A 1")
		(BoneHash_array[b] == "ecefa415"):(BoneName = "Left Arm Cloth A 2")
		(BoneHash_array[b] == "9a2afeb4"):(BoneName = "Left Arm Cloth B 1")
		(BoneHash_array[b] == "ed2dce22"):(BoneName = "Left Arm Cloth B 2")
		(BoneHash_array[b] == "649ebdd2"):(BoneName = "Left Finger Middle 1") -- Must've been a spelling mistake.
		(BoneHash_array[b] == "fa634073"):(BoneName = "Hair Left 1")
		(BoneHash_array[b] == "8d6470e5"):(BoneName = "Hair Left 2")
		(BoneHash_array[b] == "146d215f"):(BoneName = "Hair Left 3")
		(BoneHash_array[b] == "2651c105"):(BoneName = "Hair Left 4")
		(BoneHash_array[b] == "4aa560df"):(BoneName = "Hair Right 1")
		(BoneHash_array[b] == "3da25049"):(BoneName = "Hair Right 2")
		(BoneHash_array[b] == "a4ab01f3"):(BoneName = "Hair Right 3")
		(BoneHash_array[b] == "f981e8e6"):(BoneName = "Hair Right 4")
		(BoneHash_array[b] == "dde4d2a8"):(BoneName = "Hat")
		(BoneHash_array[b] == "b7f6f055"):(BoneName = "Backpack")
		(BoneHash_array[b] == "694d3b1b"):(BoneName = "Right Arm Guard")
		(BoneHash_array[b] == "93420678"):(BoneName = "Left Arm Guard")
		(BoneHash_array[b] == "1984a394"):(BoneName = "Right Propeller")
		(BoneHash_array[b] == "e38b9ef7"):(BoneName = "Left Propeller")
	)
	
	BoneParent = BoneParent_array[b]
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	tfm.row4 = BonePos_array[b]
	
	if (getNodeByName BoneName) != undefined do (
	append BoneArray (getNodeByName BoneName)
	)
	if (getNodeByName BoneName) == undefined do (
	if (BoneParent != -1) do (
	tfm = tfm * BoneArray[(BoneParent + 1)].objecttransform
	 )
	 )

		newBone = bonesys.createbone	\
					tfm.row4	\
					(tfm.row4 + 0.01 * (normalize tfm.row1)) \
					(normalize tfm.row3)
			newBone.name = BoneName
			newBone.width = 0.03
			newBone.height = 0.03
			newBone.transform = tfm
			newBone.setBoneEnable false 0
			newBone.wirecolor = yellow
			newbone.showlinks = true
			newBone.pos.controller = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
		if (BoneParent != -1) then
		newBone.parent = BoneArray[BoneParent + 1]
		append BoneArray newBone
	)
	-- print ("Bone End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f CommandsStart #seek_set
	-- print ("Commands Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + CommandsCount as string)
	MatID = 1
	RigID = 1
	VisID = 1
	for g = 1 to CommandsCount do(
		CommandID = readbyte f #unsigned + 1
		Command = readbyte f #unsigned
		-- print ("Command: 0x"+((bit.intAsHex(Command))as string) + " " + CommandID as string)

		if Command == 0x10 do(
		VisID = VisID + 1
		)

		if Command == 0x20 do(
		MatID = CommandID
		)

		if Command == 0x40 do(
		RigID = CommandID
		)

		if Command == 0x60 do(
		MatID = CommandID
		)

		if Command == 0x30 do(
			Face_array2 = #()
			Face_array3 = #()
			Vert_array2 = #()
			Normal_array2 = #()
			Color_array2 = #()
			Alpha_array2 = #()
			UV_array2 = #()
			UV2_array2 = #()
			UV3_array2 = #()
			ActualB1_array = #()
			Weight_array = #()
			Weight_array2 = #()
			WriteUV2 = 0
			WriteUV3 = 0

		RigShift = (32 * RigID) - 32

		if RigCount > 0 then(
			for x = 1 to B1_array.count do(
			ImproperBone1 = B1_array[x].Bone1
			ImproperBone2 = B1_array[x].Bone2
			ImproperBone3 = B1_array[x].Bone3
			ImproperBone4 = B1_array[x].Bone4
			ProperBone1 = RigBone_array[ImproperBone1 + RigShift]
			ProperBone2 = RigBone_array[ImproperBone2 + RigShift]
			ProperBone3 = RigBone_array[ImproperBone3 + RigShift]
			ProperBone4 = RigBone_array[ImproperBone4 + RigShift]
			if ProperBone1 == undefined do(ProperBone1 = 1)
			if ProperBone2 == undefined do(ProperBone2 = 1)
			if ProperBone3 == undefined do(ProperBone3 = 1)
			if ProperBone4 == undefined do(ProperBone4 = 1)
			append ActualB1_array (ActualBoneInfo_Struct Bone1:ProperBone1 Bone2:ProperBone2 Bone3:ProperBone3 Bone4:ProperBone4)
			)
		) else if RigCount == 0 then(ActualB1_array = B1_array)

		if BoneCount > 0 do(
			for b = 1 to W1_array.count Do (
				w = (weight_data boneids:#() weights:#())
				maxweight = 0

				if(W1_array[b].Weight1 != 0) then
					 maxweight = maxweight + W1_array[b].Weight1
				if(W1_array[b].Weight2 != 0) then
					 maxweight = maxweight + W1_array[b].Weight2
				if(W1_array[b].Weight3 != 0) then
					 maxweight = maxweight + W1_array[b].Weight3
				if(W1_array[b].Weight4 != 0) then
					 maxweight = maxweight + W1_array[b].Weight4

				if(maxweight != 0) then
					 (
						if(W1_array[b].Weight1 != 0) then
						(
						 w1 = W1_array[b].Weight1 as float
						 append w.boneids (ActualB1_array[b].Bone1)
						 append w.weights (w1)
						)
						if(W1_array[b].Weight2 != 0) then
						(
						 w2 = W1_array[b].Weight2 as float
						 append w.boneids (ActualB1_array[b].Bone2)
						 append w.weights (w2)
						)
						if(W1_array[b].Weight3 != 0) then
						(
						 w3 = W1_array[b].Weight3 as float
						 append w.boneids (ActualB1_array[b].Bone3)
						 append w.weights (w3)
						)
						if(W1_array[b].Weight4 != 0) then
						(
						 w4 = W1_array[b].Weight4 as float
						 append w.boneids (ActualB1_array[b].Bone4)
						 append w.weights (w4)
						)
					 )
				append Weight_array w
			)
		)
		
		for y = 1 to PolyGroupAmount_array[CommandID] do(
		append Face_array2 Face_array[y + PolyGroupAdd_array[CommandID]]
		)

		FaceSort_array = #()

		for x = 1 to Face_array2.count do(
		append FaceSort_array Face_array2[x].x
		append FaceSort_array Face_array2[x].y
		append FaceSort_array Face_array2[x].z
		)

		sort FaceSort_array

		VertexMin = FaceSort_array[1]
		VertexMax = FaceSort_array[FaceSort_array.count]

		if UV2_array.count > 0 and UV_array[VertexMin] != UV2_array[VertexMin] do(
		WriteUV2 = 1
		)
		if UV3_array.count > 0 and UV_array[VertexMin] != UV3_array[VertexMin] do(
			if UV3_array.count > 0 and UV2_array[VertexMin] != UV3_array[VertexMin] do(
				WriteUV3 = 1
			)
		)

		for x = VertexMin to VertexMax do(
			append Vert_array2 Vert_array[x]
			append Color_array2 Color_array[x]
			append Alpha_array2 Alpha_array[x]
			append UV_array2 UV_array[x]
			if WriteUV2 == 1 do(
				append UV2_array2 UV2_array[x]
			)
			if WriteUV3 == 1 do(
				append UV3_array2 UV3_array[x]
			)
			append Weight_array2 Weight_array[x]
		)

		for x = 1 to PolyGroupAmount_array[CommandID] do(
			Faces3 = ((Face_array2[x] - VertexMin) + 1)
			append Face_array3 Faces3
		)

		msh = mesh vertices:Vert_array2 faces:Face_array3
		msh.numTVerts = UV_array2.count
		if ColorDisable == false then (
		setNumCPVVerts msh msh.numTVerts
		setCVertMode msh true
		setShadeCVerts msh true
		)
		defaultVCFaces msh
		buildTVFaces msh
		if ColorDisable == false then (
		for j = 1 to Color_array2.count do setvertcolor msh j Color_array2[j]
		for j = 1 to Alpha_array2.count do(meshop.setVertAlpha msh -2 j Alpha_array2[j])
		)
		for j = 1 to UV_array2.count do setTVert msh j UV_array2[j]
		for j = 1 to Face_array3.count do setTVFace msh j Face_array3[j]
		for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
		msh.name = ("Mat=" + (MatID as string) + " Vis=" + (VisID as string))
		
		if BoneArray.count > 0 do(
		max modify mode
		select msh

		skinMod = skin ()
		boneIDMap = #()
		addModifier msh skinMod
		msh.Skin.weightAllVertices = false

		for i = 1 to BoneArray.count do
		(
			 maxbone = getnodebyname BoneArray[i].name
			 if i != BoneCount then
				skinOps.addBone skinMod maxbone 0
			 else
				skinOps.addBone skinMod maxbone 1
		)

		local numSkinBones = skinOps.GetNumberBones skinMod
		for i = 1 to numSkinBones do
		(
			local boneName = skinOps.GetBoneName skinMod i 0
			for j = 1 to BoneCount do
			(
				if boneName == BoneArray[j].Name then
				(
					boneIDMap[j] = i
					j = BoneCount + 1
				)
			)
		) -- This fixes bone ordering in 3DS Max 2012. Thanks to sunnydavis for the fix!

		modPanel.setCurrentObject skinMod

		for i = 1 to Vert_array2.count do(
			skinOps.SetVertexWeights skinMod i 1 1
			skinOps.unnormalizeVertex skinMod i true 
			skinOps.SetVertexWeights skinMod i 1 0
		)
			skinOps.RemoveZeroWeights skinMod
		for i = 1 to Vert_array2.count do(
			skinOps.unnormalizeVertex skinMod i false
		) -- These fix broken rigging for 3DS Max 2015 and above.

		for i = 1 to Weight_array2.count do (
			w = Weight_array2[i]
			bi = #() --bone index array
			wv = #() --weight value array
			
			for j = 1 to w.boneids.count do
			(
				boneid = w.boneids[j]
				weight = w.weights[j]
				append bi boneIDMap[boneid]
				append wv weight
			)
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)

		)

		if UV2_array2.count > 0 do(
		msh = mesh vertices:Vert_array2 faces:Face_array3
		msh.numTVerts = UV2_array2.count
		if ColorDisable == false then (
		setNumCPVVerts msh msh.numTVerts
		setCVertMode msh true
		setShadeCVerts msh true
		)
		defaultVCFaces msh
		buildTVFaces msh
		if ColorDisable == false then (
		for j = 1 to Color_array2.count do setvertcolor msh j Color_array2[j]
		for j = 1 to Alpha_array2.count do(meshop.setVertAlpha msh -2 j Alpha_array2[j])
		)
		for j = 1 to UV2_array2.count do setTVert msh j UV2_array2[j]
		for j = 1 to Face_array3.count do setTVFace msh j Face_array3[j]
		for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
		msh.name = ("Mat=" + (MatID as string) + " Vis=" + (VisID as string) + " Layer 2")

		if BoneArray.count > 0 do(
		max modify mode
		select msh

		skinMod = skin ()
		boneIDMap = #()
		addModifier msh skinMod
		msh.Skin.weightAllVertices = false

		for i = 1 to BoneArray.count do
		(
			 maxbone = getnodebyname BoneArray[i].name
			 if i != BoneCount then
				skinOps.addBone skinMod maxbone 0
			 else
				skinOps.addBone skinMod maxbone 1
		)

		local numSkinBones = skinOps.GetNumberBones skinMod
		for i = 1 to numSkinBones do
		(
			local boneName = skinOps.GetBoneName skinMod i 0
			for j = 1 to BoneCount do
			(
				if boneName == BoneArray[j].Name then
				(
					boneIDMap[j] = i
					j = BoneCount + 1
				)
			)
		) -- This fixes bone ordering in 3DS Max 2012. Thanks to sunnydavis for the fix!

		modPanel.setCurrentObject skinMod

		for i = 1 to Vert_array2.count do(
			skinOps.SetVertexWeights skinMod i 1 1
			skinOps.unnormalizeVertex skinMod i true 
			skinOps.SetVertexWeights skinMod i 1 0
		)
			skinOps.RemoveZeroWeights skinMod
		for i = 1 to Vert_array2.count do(
			skinOps.unnormalizeVertex skinMod i false
		) -- These fix broken rigging for 3DS Max 2015 and above.

		for i = 1 to Weight_array2.count do (
			w = Weight_array2[i]
			bi = #() --bone index array
			wv = #() --weight value array

			for j = 1 to w.boneids.count do
			(
				boneid = w.boneids[j]
				weight = w.weights[j]
				append bi boneIDMap[boneid]
				append wv weight
			)
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)

		)

		)

		if UV3_array2.count > 0 do(
		msh = mesh vertices:Vert_array2 faces:Face_array3
		msh.numTVerts = UV3_array2.count
		if ColorDisable == false then (
		setNumCPVVerts msh msh.numTVerts
		setCVertMode msh true
		setShadeCVerts msh true
		)
		defaultVCFaces msh
		buildTVFaces msh
		if ColorDisable == false then (
		for j = 1 to Color_array2.count do setvertcolor msh j Color_array2[j]
		for j = 1 to Alpha_array2.count do(meshop.setVertAlpha msh -2 j Alpha_array2[j])
		)
		for j = 1 to UV3_array2.count do setTVert msh j UV3_array2[j]
		for j = 1 to Face_array3.count do setTVFace msh j Face_array3[j]
		for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
		msh.name = ("Mat=" + (MatID as string) + " Vis=" + (VisID as string) + " Layer 3")

		if BoneArray.count > 0 do(
		max modify mode
		select msh

		skinMod = skin ()
		boneIDMap = #()
		addModifier msh skinMod
		msh.Skin.weightAllVertices = false

		for i = 1 to BoneArray.count do
		(
			 maxbone = getnodebyname BoneArray[i].name
			 if i != BoneCount then
				skinOps.addBone skinMod maxbone 0
			 else
				skinOps.addBone skinMod maxbone 1
		)

		local numSkinBones = skinOps.GetNumberBones skinMod
		for i = 1 to numSkinBones do
		(
			local boneName = skinOps.GetBoneName skinMod i 0
			for j = 1 to BoneCount do
			(
				if boneName == BoneArray[j].Name then
				(
					boneIDMap[j] = i
					j = BoneCount + 1
				)
			)
		) -- This fixes bone ordering in 3DS Max 2012. Thanks to sunnydavis for the fix!

		modPanel.setCurrentObject skinMod

		for i = 1 to Vert_array2.count do(
			skinOps.SetVertexWeights skinMod i 1 1
			skinOps.unnormalizeVertex skinMod i true 
			skinOps.SetVertexWeights skinMod i 1 0
		)
			skinOps.RemoveZeroWeights skinMod
		for i = 1 to Vert_array2.count do(
			skinOps.unnormalizeVertex skinMod i false
		) -- These fix broken rigging for 3DS Max 2015 and above.

		for i = 1 to Weight_array2.count do (
			w = Weight_array2[i]
			bi = #() --bone index array
			wv = #() --weight value array

			for j = 1 to w.boneids.count do
			(
				boneid = w.boneids[j]
				weight = w.weights[j]
				append bi boneIDMap[boneid]
				append wv weight
			)
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)

		)

		)

		)

	)
	-- print ("Commands End: 0x"+((bit.intAsHex(ftell f))as string))

	)

	if TMD0 == 0x746D6430 do(
	Unknown1 = readBEword f
	Unknown2 = readBEword f
	Unknown3 = readBEword f
	Unknown4 = readBEword f
	Unknown5 = readBEword f
	Unknown6 = readBEword f

	BoundMinX = readBEfloat f
	BoundMinY = readBEfloat f
	BoundMinZ = readBEfloat f
	BoundMaxX = readBEfloat f

	BoundMaxY = readBEfloat f
	BoundMaxZ = readBEfloat f

	UnknownStart1 = readBElong f
	Blank1 = readBElong f
	Blank2 = readBElong f
	CommandsStart = readBElong f
	ShaderStart = readBElong f
	Blank3 = readBElong f
	Blank4 = readBElong f
	Blank5 = readBElong f
	PolyGroupStart = readBElong f
	FaceStart = readBElong f
	TexInfoStart = readBElong f
	Blank6 = readBElong f
	UnknownStart7 = readBElong f
	VertexStart = readBElong f
	Blank7 = readBElong f
	Blank8 = readBElong f
	
	UnknownCount1 = readBElong f
	BlankCount1 = readBElong f
	BlankCount2 = readBElong f
	CommandsCount = readBElong f
	ShaderCount = readBElong f
	BlankCount3 = readBElong f
	BlankCount4 = readBElong f
	BlankCount5 = readBElong f
	PolyGroupCount = readBElong f
	FaceCount = readBElong f
	TexInfoCount = readBElong f
	BlankCount6 = readBElong f
	UnknownCount7 = readBElong f
	VertexCount = readBElong f

	RigGroupStart = readBElong f
	RigStart = readBElong f
	BoneStart = readBElong f
	BoneHierarchyStart = readBElong f
	RigGroupCount = readBElong f
	RigCount = readBElong f
	BoneCount = readBElong f
	BoneHierarchyCount = readBElong f
	NormalsStart = readBElong f
	fseek f 0xCC #seek_set
	UVStart = readBElong f
	fseek f 0xD8 #seek_set
	ColorStart = readBElong f
	fseek f 0xE4 #seek_set
	WeightStart = readBElong f
	IndexStart = readBElong f

-- 	fseek f UnknownStart1 #seek_set
-- 	print ("Info1 Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + UnknownCount1 as string)
-- 	for g = 1 to UnknownCount1 do(
-- 	BoundMinX = readBEfloat f
-- 	BoundMinY = readBEfloat f
-- 	BoundMinZ = readBEfloat f
-- 	BoundMaxX = readBEfloat f

-- 	BoundMaxY = readBEfloat f
-- 	BoundMaxZ = readBEfloat f
-- 	UnknownA1 = readBElong f
-- 	UnknownA2 = readBElong f

-- 	UnknownA3 = readBElong f
-- 	UnknownA4 = readBElong f
-- 	UnknownA5 = readBElong f
-- 	)
-- 	print ("Info1 End: 0x"+((bit.intAsHex(ftell f))as string))

-- 	fseek f TexInfoStart #seek_set
-- 	print ("Texture Info Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + TexInfoCount as string)
-- 	for g = 1 to TexInfoCount do(
-- 	TexHash = readBElong f
-- 	TexNum = readBEword f
-- 	TexU = readBEword f
-- 	TexV = readBEword f
-- 	TexNumB1 = readbyte f #unsigned
-- 	TexNumB2 = readbyte f #unsigned
-- 	)
-- 	print ("Texture Info End: 0x"+((bit.intAsHex(ftell f))as string))

-- 	fseek f UnknownStart7 #seek_set
-- 	print ("Info7 Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + UnknownCount7 as string)
-- 	for g = 1 to UnknownCount7 do(
-- 	UnknownHash = readBElong f
-- 	UnknownNum1 = readBEword f
-- 	UnknownNum2 = readBEword f
-- 	FFFF = readBEword f
-- 	blank = readBEword f
-- 	)
-- 	print ("Info7 Info End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f RigGroupStart #seek_set
	-- print ("Rig Group Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + RigGroupCount as string)
	for g = 1 to RigGroupCount do(
	RigIDCount = readBElong f
	RigIDStart = readBElong f
	append RigIDCount_array RigIDCount
	append RigIDStart_array RigIDStart
	)
	-- print ("Rig Group End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f RigStart #seek_set
	-- print ("Rig Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + RigCount as string)
	for g = 1 to RigCount do(
		RigBone = readbyte f #unsigned + 1
		append RigBone_array RigBone
	)
	-- print ("Rig End: 0x"+((bit.intAsHex(ftell f))as string))

-- 	fseek f ShaderStart #seek_set
-- 	print ("Shader Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + ShaderCount as string)
-- 	for g = 1 to ShaderCount do(
-- 	ShaderHash = readBElong f
-- 	ShaderFormat = readBElong f
-- 	TexU = readBEword f
-- 	TexV = readBEword f
-- 	blank = readBElong f
-- 	ffffffff = readBElong f
-- 	)
-- 	print ("Shader Info End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f PolyGroupStart #seek_set
	-- print ("PolyGroup Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + PolyGroupCount as string)
	for g = 1 to PolyGroupCount do(
	PolyGroupAmount = readBElong f
	PolyGroupAdd = readBElong f
	append PolyGroupAmount_array PolyGroupAmount
	append PolyGroupAdd_array PolyGroupAdd
	)
	-- print ("PolyGroup End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f FaceStart #seek_set
	-- print ("Face Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + FaceCount as string)
	for g = 1 to FaceCount do(
	f1 = readBEword f + 1
	f2 = readBEword f + 1
	f3 = readBEword f + 1
	append Face_array [(f1),(f2),(f3)]
	)
	-- print ("Face End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f VertexStart #seek_set
	-- print ("Vertex Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertexCount as string)
	for g = 1 to VertexCount do(
	vx = readBEfloat f
	vy = readBEfloat f
	vz = readBEfloat f
	append Vert_array [vx,vy,vz]
	)
	-- print ("Vertex End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f NormalsStart #seek_set
	-- print ("Normals Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertexCount as string)
	for g = 1 to VertexCount do(
	nq = readbyte f
	nx = readbyte f
	ny = readbyte f
	nz = readbyte f
-- 	append Normal_array [nx,ny,nz]
	)
	-- print ("Normals End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f UVStart #seek_set
	-- print ("UV Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertexCount as string)
	for g = 1 to VertexCount do(
	tu = readBEword f as float / 1024
	tv = ((readBEword f as float / 1024) * -1)
	append UV_array [tu,tv,0]
	)
	-- print ("UV End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f IndexStart #seek_set
	-- print ("Index Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertexCount as string)
	for g = 1 to VertexCount do(
	bone1 = (readbyte f #unsigned) + 1
	bone2 = (readbyte f #unsigned) + 1
	bone3 = (readbyte f #unsigned) + 1
	bone4 = (readbyte f #unsigned) + 1
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
	)
	-- print ("Index End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f WeightStart #seek_set
	-- print ("Weight Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertexCount as string)
	for g = 1 to VertexCount do(
	weight1 = (readbyte f #unsigned as float) / 255
	weight2 = (readbyte f #unsigned as float) / 255
	weight3 = (readbyte f #unsigned as float) / 255
	weight4 = (readbyte f #unsigned as float) / 255
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
	)
	-- print ("Weight End: 0x"+((bit.intAsHex(ftell f))as string))

-- 	fseek f ColorStart #seek_set
-- 	print ("Color Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertexCount as string)
-- 	for g = 1 to VertexCount do(
-- 	colorr = readbyte f #unsigned
-- 	colorg = readbyte f #unsigned
-- 	colorb = readbyte f #unsigned
-- 	colora = (readbyte f #unsigned) as float / 255
-- 	append Color_array [colorr,colorg,colorb]
-- 	append Alpha_Array colora
-- 	)
-- 	print ("Color End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f BoneHierarchyStart #seek_set
	-- print ("Bone Hierarchy Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + BoneHierarchyCount as string)
	for b = 1 to BoneHierarchyCount do(
	BoneHash = readBElong f
	BoneHX = readBEfloat f
	BoneHY = readBEfloat f
	BoneHZ = readBEfloat f
	BoneParent = readBElong f
	BoneH0 = readBElong f
	append BoneHash_array BoneHash
	append BoneParent_array BoneParent
	append BonePos_array [BoneHX,BoneHY,BoneHZ]
	)
	-- print ("Bone Hierarchy End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f BoneStart #seek_set
	-- print ("Bone Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + BoneCount as string)
	for b = 1 to BoneCount do(
	BoneName = ("Bone 0x" + (bit.intAsHex(BoneHash_array[b])) as string)
	BoneParent = BoneParent_array[b]
	m11 = readBEfloat f; m12 = readBEfloat f; m13 = readBEfloat f; m14 = readBEfloat f
	m21 = readBEfloat f; m22 = readBEfloat f; m23 = readBEfloat f; m24 = readBEfloat f
	m31 = readBEfloat f; m32 = readBEfloat f; m33 = readBEfloat f; m34 = readBEfloat f
	m41 = readBEfloat f; m42 = readBEfloat f; m43 = readBEfloat f; m44 = readBEfloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	tfm.row4 = BonePos_array[b]

	if (getNodeByName BoneName) != undefined do (
	append BoneArray (getNodeByName BoneName)
	)
	if (getNodeByName BoneName) == undefined do (
	if (BoneParent != -1) do (
	tfm = tfm * BoneArray[(BoneParent + 1)].objecttransform
	 )
	 )

		newBone = bonesys.createbone	\
					tfm.row4	\
					(tfm.row4 + 0.01 * (normalize tfm.row1)) \
					(normalize tfm.row3)
			newBone.name	 = BoneName
			newBone.width	= 0.03
			newBone.height = 0.03
			newBone.transform = tfm
			newBone.setBoneEnable false 0
			newBone.wirecolor = yellow
			newbone.showlinks = true
			newBone.pos.controller			= TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
		if (BoneParent != -1) then
		newBone.parent = BoneArray[BoneParent + 1]
		append BoneArray newBone
	)
	-- print ("Bone End: 0x"+((bit.intAsHex(ftell f))as string))

	fseek f CommandsStart #seek_set
	-- print ("Commands Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + CommandsCount as string)
	MatID = 1
	RigID = 1
	VisID = 1
	for g = 1 to CommandsCount do(
		Command = readbyte f #unsigned
		CommandID = readbyte f #unsigned + 1
	
		if Command == 0x10 do(
		VisID = VisID + 1
		)

		if Command == 0x50 do(
		MatID = CommandID
		)

		if Command == 0x40 do(
		RigID = CommandID
		)

		if Command == 0x30 do(
			Face_array2 = #()
			Face_array3 = #()
			Vert_array2 = #()
			Normal_array2 = #()
			UV_array2 = #()
			ActualB1_array = #()
			Weight_array = #()
			Weight_array2 = #()

		RigShift = RigIDStart_array[RigID]

		if RigCount > 0 do(
			for x = 1 to B1_array.count do(
			ImproperBone1 = B1_array[x].Bone1
			ImproperBone2 = B1_array[x].Bone2
			ImproperBone3 = B1_array[x].Bone3
			ImproperBone4 = B1_array[x].Bone4
			ProperBone1 = RigBone_array[ImproperBone1 + RigShift]
			ProperBone2 = RigBone_array[ImproperBone2 + RigShift]
			ProperBone3 = RigBone_array[ImproperBone3 + RigShift]
			ProperBone4 = RigBone_array[ImproperBone4 + RigShift]
			if ProperBone1 == undefined do(ProperBone1 = 1)
			if ProperBone2 == undefined do(ProperBone2 = 1)
			if ProperBone3 == undefined do(ProperBone3 = 1)
			if ProperBone4 == undefined do(ProperBone4 = 1)
			append ActualB1_array (ActualBoneInfo_Struct Bone1:ProperBone1 Bone2:ProperBone2 Bone3:ProperBone3 Bone4:ProperBone4)
			)

			for b = 1 to W1_array.count Do (
			w = (weight_data boneids:#() weights:#())
			maxweight = 0
				 
			if(W1_array[b].Weight1 != 0) then
				 maxweight = maxweight + W1_array[b].Weight1
			if(W1_array[b].Weight2 != 0) then
				 maxweight = maxweight + W1_array[b].Weight2
			if(W1_array[b].Weight3 != 0) then
				 maxweight = maxweight + W1_array[b].Weight3
			if(W1_array[b].Weight4 != 0) then
				 maxweight = maxweight + W1_array[b].Weight4

			if(maxweight != 0) then
				 (
					if(W1_array[b].Weight1 != 0) then
					(
					 w1 = W1_array[b].Weight1 as float
					 append w.boneids (ActualB1_array[b].Bone1)
					 append w.weights (w1)
					)
					if(W1_array[b].Weight2 != 0) then
					(
					 w2 = W1_array[b].Weight2 as float
					 append w.boneids (ActualB1_array[b].Bone2)
					 append w.weights (w2)
					)
					if(W1_array[b].Weight3 != 0) then
					(
					 w3 = W1_array[b].Weight3 as float
					 append w.boneids (ActualB1_array[b].Bone3)
					 append w.weights (w3)
					)
					if(W1_array[b].Weight4 != 0) then
					(
					 w4 = W1_array[b].Weight4 as float
					 append w.boneids (ActualB1_array[b].Bone4)
					 append w.weights (w4)
					)
				 )
			append Weight_array w
			)
		)

		for y = 1 to PolyGroupAmount_array[CommandID] do(
		append Face_array2 Face_array[y + PolyGroupAdd_array[CommandID]]
		)

		FaceSort_array = #()

		for x = 1 to Face_array2.count do(
		append FaceSort_array Face_array2[x].x
		append FaceSort_array Face_array2[x].y
		append FaceSort_array Face_array2[x].z
		)

		sort FaceSort_array

		VertexMin = FaceSort_array[1]
		VertexMax = FaceSort_array[FaceSort_array.count]

		for x = VertexMin to VertexMax do(
			append Vert_array2 Vert_array[x]
-- 			append Normal_array2 Normal_array[x]
			append UV_array2 UV_array[x]
			append Weight_array2 Weight_array[x]
		)

		for x = 1 to PolyGroupAmount_array[CommandID] do(
			Faces3 = ((Face_array2[x] - VertexMin) + 1)
			append Face_array3 Faces3
		)

		msh = mesh vertices:Vert_array2 faces:Face_array3
		msh.numTVerts = Vert_array2.count
		setNumCPVVerts msh msh.numTVerts
		-- setCVertMode msh true
		-- setShadeCVerts msh true
		defaultVCFaces msh
		buildTVFaces msh
		-- for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
		-- for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
		for j = 1 to Vert_array2.count do setTVert msh j UV_array2[j]
		for j = 1 to Face_array3.count do setTVFace msh j Face_array3[j]
		for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
		msh.name = ("Mat=" + (MatID as string) + " Vis=" + (VisID as string))

		if BoneArray.count > 0 do(
		max modify mode
		select msh

		skinMod = skin ()
		boneIDMap = #()
		addModifier msh skinMod
		msh.Skin.weightAllVertices = false

		for i = 1 to BoneArray.count do
		(
			 maxbone = getnodebyname BoneArray[i].name
			 if i != BoneCount then
				skinOps.addBone skinMod maxbone 0
			 else
				skinOps.addBone skinMod maxbone 1
		)

		local numSkinBones = skinOps.GetNumberBones skinMod
		for i = 1 to numSkinBones do
		(
			local boneName = skinOps.GetBoneName skinMod i 0
			for j = 1 to BoneCount do
			(
				if boneName == BoneArray[j].Name then
				(
					boneIDMap[j] = i
					j = BoneCount + 1
				)
			)
		) -- This fixes bone ordering in 3DS Max 2012. Thanks to sunnydavis for the fix!

		modPanel.setCurrentObject skinMod

		for i = 1 to Vert_array2.count do(
			skinOps.SetVertexWeights skinMod i 1 1
			skinOps.unnormalizeVertex skinMod i true 
			skinOps.SetVertexWeights skinMod i 1 0
		)
			skinOps.RemoveZeroWeights skinMod
		for i = 1 to Vert_array2.count do(
			skinOps.unnormalizeVertex skinMod i false
		) -- These fix broken rigging for 3DS Max 2015 and above.

		for i = 1 to Weight_array2.count do (
			w = Weight_array2[i]
			bi = #() --bone index array
			wv = #() --weight value array
			
			for j = 1 to w.boneids.count do
			(
				boneid = w.boneids[j]
				weight = w.weights[j]
				append bi boneIDMap[boneid]
				append wv weight
			)
			skinOps.ReplaceVertexWeights skinMod i bi wv
		)

		)

		)


	)
	-- print ("Commands End: 0x"+((bit.intAsHex(ftell f))as string))

	)

	-- print ("Ended: 0x"+((bit.intAsHex(ftell f))as string))

	gc()
	fclose f
	clearSelection()

Print ("Done! ("+((((timestamp())-st)*0.001)as string)+" Seconds)")

	)

	)

)

CreateDialog TamsoftImporter