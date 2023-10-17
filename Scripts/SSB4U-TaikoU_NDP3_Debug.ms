-- Super Smash Bros. for Wii U / Taiko no Tatsujin Wii U model importer by Random Talking Bush.
-- Updated May 4th, 2017.
-- Fixed rigging being broken in one way or another for newer 3DS Max versions.
-- Added support for vertex types 0x21/0x23/0x26/0x29 (half-float rigging).
-- Changed internal naming from "size" to "type" for vertex/UV/face formats because that makes more sense.
-- Changed "if" setups for vertex/face information to "case of" just because.

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

rollout SSB4UImporter "Super Smash Bros. for Wii U / Taiko no Tatsujin model importer" width:390 height:250
(
	button btnImport "Import Model" pos:[8,8] width:375 height:40
	label lblDisclaimer "This script was written by Random Talking Bush, if you use it, please remember to give me thanks for this. If something doesn't work right, please contact me on The VG Resource (Random Talking Bush), Twitter, Tumblr or Steam (RandomTBush) and let me know, and I'll try to fix it." pos:[8,50] width:375 height:80
	checkbox tglColorMult "Multiply vertex colours?" pos:[8,108] width:150 height:15 tooltip: "If this is enabled, the model will multiply the colour values by 2 (so instead of 127 being the default, it'll be 255 -- any colour values above 127 will be lost, though)." checked: false
	checkbox tglColorDisable "Disable vertex colours?" pos:[8,125] width:150 height:15 tooltip: "If you'd rather not import the vertex colouring, enable this." checked: false
	checkbox tglPNGTex "Use PNG instead of DDS?" pos:[238,108] width:150 height:15 tooltip: "Self explanatory." checked: false
	label lblUpdate "(Updated: 05-04-2017)" pos:[268,125]
	label lblModding "TEXTURE ID MODIFIER:" pos:[8,150] width:120 height:15
	label lblTexIDChangeA "CLASS" pos:[8,165] width:60 height:15
	label lblTexIDChangeB "GROUP" pos:[68,165] width:60 height:15
	label lblTexIDChangeC "SUBGROUP" pos:[128,165] width:60 height:15
	label lblTexIDChangeD "INDEX" pos:[188,165] width:60 height:15
	label lblTexIDChange "For use with extra character slots in SSB4U, and to avoid texture conflicts. Input four different values (0-255) here. Make a copy just in case something goes wrong!" pos:[8,200] width:280 height:40
	spinner boxTexIDChangeA pos:[8,180] width:40 range:[0,255,64] type:#integer tooltip: "This can probably be changed without side effects. Don't use 16 (Lightwarps/Cubemaps), 21 (Effects), 32 (Stages), 39 (FS BGs), 40 (UI), 43 (Stage Editor), 66 (Enemies), 68 (Items), 70  (Assist), 72 (Pokémon) or 78-81 (Trophies) for characters as they're reserved for the things in brackets."
	spinner boxTexIDChangeB pos:[68,180] width:40 range:[0,255,0] type:#integer tooltip: "Each character has a separate number assigned to them." 
	spinner boxTexIDChangeC pos:[128,180] width:40 range:[0,255,0] type:#integer tooltip: "Costumes are usually set to c## * 4." 
	radiobuttons tglTexIDChangeD labels:#("No change","0","128") pos:[188,180]
	button btnIDFixNUD ".NUD" pos:[295,200] width:40 height:40
	button btnIDFixNUT ".NUT" pos:[335,200] width:40 height:40

	on btnImport pressed do(
	local colormult = tglColorMult.checked
	local colordisable = tglColorDisable.checked
	local PNGTex = tglPNGTex.checked
	clearlistener()
	fname = getOpenFileName \ 
	caption:"Super Smash Bros. for Wii U / Taiko model file" \
	types:"SSB4U/TnTU model(*.nud)|*.nud" \
	historyCategory:"SSB4U"

	if fname != undefined do (
	m = fopen fname "rb"
	p = getFilenamePath fname
	h = getFilenameFile fname
	fname2 = p + "model.vbn"
	q = fopen fname2 "rb"

	struct Bone_Info_Struct
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
	struct TexIDSet_Struct
	(
		TexClass, TexGroup, TexSubgroup, TexIndex
	)

	BoneName_Array = #()
	BoneParent_array = #()
	Bone_Matrix_Array = #()
	BoneArray = #()
	BoneFixArray = #()
	BoneCount = #()
	VertexStart_array = #()
	VertexAmount_array = #()
	VertexType_array = #()
	PolyStart_array = #()
	PolyAmount_array = #()
	PolyType_array = #()
	VertexAddStart_array = #()
	UVType_array = #()
	PolyName_array = #()
	SingleBind_array = #()
	TexturePropertiesS1Start_array = #()
	TexturePropertiesS2Start_array = #()
	TexturePropertiesS3Start_array = #()
	TexturePropertiesS4Start_array = #()
	TextureIDL1_array = #()
	TextureIDL2_array = #()
	TextureIDL3_array = #()
	TextureIDL4_array = #()

	fseek m 0x00 #seek_set
	NDP3 = readBElong m
	filesize = readBElong m
	unknown1 = readBEword m
	polysets = readBEword m
	unknown2 = readBEword m
	somethingsets = readBEword m
	PolyClumpStart = (readBElong m) + 0x30
	PolyClumpSize = readBElong m
	VertexClumpStart = (PolyClumpStart + PolyClumpSize)
	VertexClumpSize = readBElong m
	VertexAddClumpStart = (VertexClumpStart + VertexClumpSize)
	VertexAddClumpSize = readBElong m
	NameClumpStart = (VertexAddClumpStart + VertexAddClumpSize)
	thisfloat1 = readBEfloat m
	thisfloat2 = readBEfloat m
	thisfloat3 = readBEfloat m
	thisfloat4 = readBEfloat m

	ObjCount = 0
	for z = 1 to polysets do(
	print ("Polyset info " + z as string + " start at 0x" + (bit.intAsHex(ftell m))as string)
	Float1A = readBEfloat m
	Float2A = readBEfloat m
	Float3A = readBEfloat m
	Float4 = readBEfloat m
	Float1B = readBEfloat m
	Float2B = readBEfloat m
	Float3B = readBEfloat m
	Float5 = readBEfloat m
	polynamestart = readBElong m
	PolyFlag = readBElong m
	singlebind = readBEword m + 1
	if SingleBind == 65536 do(SingleBind = 1)
	polyamount = readBEword m
	ObjPropStart = readBElong m
	ObjCount = (ObjCount + polyamount)
	for s = 1 to polyamount do(
	append PolyName_array polynamestart
	append SingleBind_array singlebind
		)
	)

	for z = 1 to ObjCount do(
	print ("Object properties " + z as string + " start at 0x" + (bit.intAsHex(ftell m))as string)
	PolyStart = (readBElong m + PolyClumpStart)
	VertexStart = (readBElong m + VertexClumpStart)
	VertexAddStart = (readBElong m + VertexAddClumpStart)
	VertexAmount = readBEword m
	VertexType = readbyte m #unsigned
	UVType = readbyte m #unsigned
	TextureSet1Properties = readBElong m
	TextureSet2Properties = readBElong m
	TextureSet3Properties = readBElong m
	TextureSet4Properties = readBElong m
	PolyAmount = readBEword m
	PolyType = readbyte m #unsigned
	PolyFlag = readbyte m #unsigned
	fseek m 0x0C #seek_cur
	append VertexStart_array VertexStart
	append PolyStart_array PolyStart
	append VertexAddStart_array VertexAddStart
	append VertexAmount_array VertexAmount
	append PolyAmount_array PolyAmount
	append VertexType_array VertexType
	append UVType_array UVType
	append PolyType_array PolyType
	append TexturePropertiesS1Start_array TextureSet1Properties
	append TexturePropertiesS2Start_array TextureSet2Properties
	append TexturePropertiesS3Start_array TextureSet3Properties
	append TexturePropertiesS4Start_array TextureSet4Properties
	)

	BoneCount = 0

	if q != undefined do(
	VBN = readlong q
	fseek q 0x08 #seek_set

	if VBN == 0x56424E20 do(
	print "Bone structure is little-endian!"
	BoneCount = readlong q #unsigned
	fseek q 0x1C #seek_set
	for x = 1 to BoneCount do(
	jumpman = (ftell q + 0x44)
	BoneName = readstring q
	fseek q jumpman #seek_set
	BoneParent = readshort q + 1
	fseek q 0x02 #seek_cur
	if BoneParent == 0 do(BoneParent = -1)
	fseek q 0x04 #seek_cur
	append BoneName_array BoneName
	append BoneParent_array BoneParent
	)

	Trans_array = #()
	Rotation_array = #()
	Scale_array = #()

	for x = 1 to BoneCount do(
	tx = Readfloat q
	ty = Readfloat q
	tz = Readfloat q

	rx = Readfloat q
	ry = Readfloat q
	rz = Readfloat q

	sx = Readfloat q
	sy = Readfloat q
	sz = Readfloat q

	append Trans_array [tx,ty,tz]
	append Rotation_array [rx,ry,rz]
	append Scale_array [sx,sy,sz]
	)

	for x = 1 to BoneCount do(
	BoneName = BoneName_array[x]
	BoneParent = BoneParent_array[x]

	tfm = scaleMatrix [Scale_array[x].x,Scale_array[x].y,Scale_array[x].z]
	tfm = tfm * (rotateXMatrix (radToDeg Rotation_array[x].x)) * (rotateYMatrix (radToDeg Rotation_array[x].y)) * (rotateZMatrix (radToDeg Rotation_array[x].z))
	tfm.row4 = [Trans_array[x].x, Trans_array[x].y, Trans_array[x].z]

	if (BoneParent_array[x] != -1) and (BoneParent_array[x] < x) then (
	tfm = tfm * BoneArray[(BoneParent_array[x])].objecttransform
	 ) else if (x > 1) and (BoneParent_array[x] > -1) do(append BoneFixArray x)

		newBone = bonesys.createbone	\
					  tfm.row4	\
					  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
					  (normalize tfm.row3)
				newBone.name   = BoneName
				newBone.width  = 0.03
				newBone.height = 0.03
				newBone.transform = tfm
				newBone.setBoneEnable false 0
				newBone.wirecolor = yellow
				newbone.showlinks = true
				newBone.pos.controller      = TCB_position ()
				newBone.rotation.controller = TCB_rotation ()
			if (BoneParent != -1) then
			newBone.parent = BoneArray[BoneParent]
			append BoneArray newBone

	)

	for x = 1 to BoneFixArray.count do(
		select BoneArray[BoneFixArray[x]]
		tfm = scaleMatrix [Scale_array[BoneFixArray[x]].x,Scale_array[BoneFixArray[x]].y,Scale_array[BoneFixArray[x]].z]
		tfm = tfm * (rotateXMatrix (radToDeg Rotation_array[BoneFixArray[x]].x)) * (rotateYMatrix (radToDeg Rotation_array[BoneFixArray[x]].y)) * (rotateZMatrix (radToDeg Rotation_array[BoneFixArray[x]].z))
		tfm.row4 = [Trans_array[BoneFixArray[x]].x, Trans_array[BoneFixArray[x]].y, Trans_array[BoneFixArray[x]].z]
		tfm = tfm * BoneArray[BoneParent_array[BoneFixArray[x]]].objecttransform
		$.transform = tfm
		$.parent = BoneArray[BoneParent_array[BoneFixArray[x]]]
	)

		)
		
	if VBN == 0x204E4256 do(
	print "Bone structure is big-endian!"
	BoneCount = readBElong q
	fseek q 0x1C #seek_set
	for x = 1 to BoneCount do(
	jumpman = (ftell q + 0x44)
	BoneName = readstring q
	fseek q jumpman #seek_set
	fseek q 0x02 #seek_cur
	BoneParent = readBEword q + 1
	if BoneParent == 65536 do(BoneParent = -1)
	fseek q 0x04 #seek_cur
	append BoneName_array BoneName
	append BoneParent_array BoneParent
	)

	Trans_array = #()
	Rotation_array = #()
	Scale_array = #()

	for x = 1 to BoneCount do(
	tx = readBEfloat q
	ty = readBEfloat q
	tz = readBEfloat q

	rx = readBEfloat q
	ry = readBEfloat q
	rz = readBEfloat q

	sx = readBEfloat q
	sy = readBEfloat q
	sz = readBEfloat q
		
	append Trans_array [tx,ty,tz]
	append Rotation_array [rx,ry,rz]
	append Scale_array [sx,sy,sz]
	)

	for x = 1 to BoneCount do(
	BoneName = BoneName_array[x]
	BoneParent = BoneParent_array[x]

	tfm = scaleMatrix [Scale_array[x].x,Scale_array[x].y,Scale_array[x].z]
	tfm = tfm * (rotateXMatrix (radToDeg Rotation_array[x].x)) * (rotateYMatrix (radToDeg Rotation_array[x].y)) * (rotateZMatrix (radToDeg Rotation_array[x].z))
	tfm.row4 = [Trans_array[x].x, Trans_array[x].y, Trans_array[x].z]

	if (BoneParent_array[x] != -1) and (BoneParent_array[x] < x) then (
	tfm = tfm * BoneArray[(BoneParent_array[x])].objecttransform
	 ) else if (x > 1) and (BoneParent_array[x] > -1) do(append BoneFixArray x)

		newBone = bonesys.createbone	\
					  tfm.row4	\
					  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
					  (normalize tfm.row3)
				newBone.name   = BoneName
				newBone.width  = 0.03
				newBone.height = 0.03
				newBone.transform = tfm
				newBone.setBoneEnable false 0
				newBone.wirecolor = yellow
				newbone.showlinks = true
				newBone.pos.controller      = TCB_position ()
				newBone.rotation.controller = TCB_rotation ()
			if (BoneParent != -1) then
			newBone.parent = BoneArray[BoneParent]
			append BoneArray newBone
			)

	for x = 1 to BoneFixArray.count do(
		select BoneArray[BoneFixArray[x]]
		tfm = scaleMatrix [Scale_array[BoneFixArray[x]].x,Scale_array[BoneFixArray[x]].y,Scale_array[BoneFixArray[x]].z]
		tfm = tfm * (rotateXMatrix (radToDeg Rotation_array[BoneFixArray[x]].x)) * (rotateYMatrix (radToDeg Rotation_array[BoneFixArray[x]].y)) * (rotateZMatrix (radToDeg Rotation_array[BoneFixArray[x]].z))
		tfm.row4 = [Trans_array[BoneFixArray[x]].x, Trans_array[BoneFixArray[x]].y, Trans_array[BoneFixArray[x]].z]
		tfm = tfm * BoneArray[BoneParent_array[BoneFixArray[x]]].objecttransform
		$.transform = tfm
		$.parent = BoneArray[BoneParent_array[BoneFixArray[x]]]
	)

		)
	)

	for z = 1 to ObjCount do(
	Layer1Write = 0
	Layer2Write = 0
	Layer3Write = 0
	Layer4Write = 0

	fseek m TexturePropertiesS1Start_array[z] #seek_set
	print ("Polygon group " + z as string + " material properties start at 0x" + (bit.intAsHex(ftell m))as string)
	UnkTex1 = readbyte m #unsigned
	UnkTex2 = readbyte m #unsigned
	UnkTex3 = readbyte m #unsigned
	UnkTex4 = readbyte m #unsigned
	nothing1 = readBElong m
	TexSomethingCount = readBEword m
	TexLayerCount = readBEword m
	TexTransparencyA = readbyte m #unsigned
	TexTransparencyB = readbyte m #unsigned
	TexTransparencyC = readbyte m #unsigned
	TexTransparencyD = readbyte m #unsigned
	UnkTex9 = readbyte m #unsigned
	UnkTex10 = readbyte m #unsigned
	UnkTex11 = readbyte m #unsigned
	UnkTex12 = readbyte m #unsigned
	nothing2 = readBElong m
	UnkTex13 = readbyte m #unsigned
	UnkTex14 = readbyte m #unsigned
	UnkTex15 = readbyte m #unsigned
	UnkTex16 = readbyte m #unsigned
	UnkTex17 = readBEfloat m
	print "Texture information:"

	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	if x == 1 do(
		Layer1Write = 1
		append TextureIDL1_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
		)
	if x == 2 do(
		Layer2Write = 1
		append TextureIDL2_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
		)
	if x == 3 do(
		Layer3Write = 1
		append TextureIDL3_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
		)
	if x == 4 do(
		Layer4Write = 1
		append TextureIDL4_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
		)
	nothing = readBElong m
	nothing = readBElong m
	UnkTexC = readbyte m #unsigned
	UnkTexD = readbyte m #unsigned
	UnkTexE = readbyte m #unsigned
	TexFilter = readbyte m #unsigned
	UnkTexG = readbyte m #unsigned
	UnkTexH = readbyte m #unsigned
	UnkTexI = readbyte m #unsigned
	UnkTexJ = readbyte m #unsigned
	nothing = readBElong m
	print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	headerread = readBElong m
	fseek m -0x04 #seek_cur
	if headerread != 0 do(do(
	headerread = readBElong m
	TexPropNameStart = readBElong m
	something4 = readBElong m
	nothing = readBElong m
	TexFloatStart = (ftell m)
	TexFloatA = readBEfloat m
	TexFloatB = readBEfloat m
	TexFloatC = readBEfloat m
	TexFloatD = readBEfloat m
	fseek m (NameClumpStart + TexPropNameStart) #seek_set
	TexPropName = readstring m
	fseek m (TexFloatStart + 0x10) #seek_set
	if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
	if TexPropName == "NU_materialHash" do(
		fseek m -0x10 #seek_cur
		TexFloatA = readBElong m
		TexFloatB = readBElong m
		TexFloatC = readBElong m
		TexFloatD = readBElong m	
		print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = 0x" + ((bit.intAsHex(TexFloatA))as string))
		)
	fseek m (TexFloatStart + headerread - 0x10) #seek_set
	) while headerread != 0
	)

	if TexturePropertiesS2Start_array[z] != 0 do(
	fseek m TexturePropertiesS2Start_array[z] #seek_set
	print "--------------------"
	print ("Polygon group " + z as string + " Set 2 material properties:")

	UnkTex1 = readbyte m #unsigned
	UnkTex2 = readbyte m #unsigned
	UnkTex3 = readbyte m #unsigned
	UnkTex4 = readbyte m #unsigned
	nothing = readBElong m
	TexSomethingCount = readBEword m
	TexLayerCount = readBEword m
	UnkTex5 = readbyte m #unsigned
	UnkTex6 = readbyte m #unsigned
	UnkTex7 = readbyte m #unsigned
	UnkTex8 = readbyte m #unsigned
	something = readBElong m
	nothing = readBElong m
	nothing = readBElong m
	nothing = readBElong m
	print "Texture information:"
		
	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	nothing = readBElong m
	nothing = readBElong m
	UnkTexC = readbyte m #unsigned
	UnkTexD = readbyte m #unsigned
	UnkTexE = readbyte m #unsigned
	UnkTexF = readbyte m #unsigned
	UnkTexG = readbyte m #unsigned
	UnkTexH = readbyte m #unsigned
	UnkTexI = readbyte m #unsigned
	UnkTexJ = readbyte m #unsigned
	nothing = readBElong m
	print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	headerread = readBElong m
	fseek m -0x04 #seek_cur
	if headerread != 0 do(do(
	headerread = readBElong m
	TexPropNameStart = readBElong m
	something4 = readBElong m
	nothing = readBElong m
	TexFloatStart = (ftell m)
	TexFloatA = readBEfloat m
	TexFloatB = readBEfloat m
	TexFloatC = readBEfloat m
	TexFloatD = readBEfloat m
	fseek m (NameClumpStart + TexPropNameStart) #seek_set
	TexPropName = readstring m
	fseek m (TexFloatStart + 0x10) #seek_set
	if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
	if TexPropName == "NU_materialHash" do(
		fseek m -0x10 #seek_cur
		TexFloatA = readBElong m
		TexFloatB = readBElong m
		TexFloatC = readBElong m
		TexFloatD = readBElong m	
		print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = 0x" + ((bit.intAsHex(TexFloatA))as string))
		)
	fseek m (TexFloatStart + headerread - 0x10) #seek_set
	) while headerread != 0
	)

	)

	if TexturePropertiesS3Start_array[z] != 0 do(
	fseek m TexturePropertiesS3Start_array[z] #seek_set
	print "--------------------"
	print ("Polygon group " + z as string + " Set 3 material properties:")
		
	UnkTex1 = readbyte m #unsigned
	UnkTex2 = readbyte m #unsigned
	UnkTex3 = readbyte m #unsigned
	UnkTex4 = readbyte m #unsigned
	nothing = readBElong m
	TexSomethingCount = readBEword m
	TexLayerCount = readBEword m
	UnkTex5 = readbyte m #unsigned
	UnkTex6 = readbyte m #unsigned
	UnkTex7 = readbyte m #unsigned
	UnkTex8 = readbyte m #unsigned
	something = readBElong m
	nothing = readBElong m
	nothing = readBElong m
	nothing = readBElong m
	print "Texture information:"
		
	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	nothing = readBElong m
	nothing = readBElong m
	UnkTexC = readbyte m #unsigned
	UnkTexD = readbyte m #unsigned
	UnkTexE = readbyte m #unsigned
	UnkTexF = readbyte m #unsigned
	UnkTexG = readbyte m #unsigned
	UnkTexH = readbyte m #unsigned
	UnkTexI = readbyte m #unsigned
	UnkTexJ = readbyte m #unsigned
	nothing = readBElong m
	print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	headerread = readBElong m
	fseek m -0x04 #seek_cur
	if headerread != 0 do(do(
	headerread = readBElong m
	TexPropNameStart = readBElong m
	something4 = readBElong m
	nothing = readBElong m
	TexFloatStart = (ftell m)
	TexFloatA = readBEfloat m
	TexFloatB = readBEfloat m
	TexFloatC = readBEfloat m
	TexFloatD = readBEfloat m
	fseek m (NameClumpStart + TexPropNameStart) #seek_set
	TexPropName = readstring m
	fseek m (TexFloatStart + 0x10) #seek_set
	if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
	if TexPropName == "NU_materialHash" do(
		fseek m -0x10 #seek_cur
		TexFloatA = readBElong m
		TexFloatB = readBElong m
		TexFloatC = readBElong m
		TexFloatD = readBElong m	
		print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = 0x" + ((bit.intAsHex(TexFloatA))as string))
		)
	fseek m (TexFloatStart + headerread - 0x10) #seek_set
	) while headerread != 0
	)

	)

	if TexturePropertiesS4Start_array[z] != 0 do(
	fseek m TexturePropertiesS4Start_array[z] #seek_set
	print "--------------------"
	print ("Polygon group " + z as string + " Set 4 material properties:")

	UnkTex1 = readbyte m #unsigned
	UnkTex2 = readbyte m #unsigned
	UnkTex3 = readbyte m #unsigned
	UnkTex4 = readbyte m #unsigned
	nothing = readBElong m
	TexSomethingCount = readBEword m
	TexLayerCount = readBEword m
	UnkTex5 = readbyte m #unsigned
	UnkTex6 = readbyte m #unsigned
	UnkTex7 = readbyte m #unsigned
	UnkTex8 = readbyte m #unsigned
	something = readBElong m
	nothing = readBElong m
	nothing = readBElong m
	nothing = readBElong m
	print "Texture information:"

	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	nothing = readBElong m
	nothing = readBElong m
	UnkTexC = readbyte m #unsigned
	UnkTexD = readbyte m #unsigned
	UnkTexE = readbyte m #unsigned
	UnkTexF = readbyte m #unsigned
	UnkTexG = readbyte m #unsigned
	UnkTexH = readbyte m #unsigned
	UnkTexI = readbyte m #unsigned
	UnkTexJ = readbyte m #unsigned
	nothing = readBElong m
	print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	headerread = readBElong m
	fseek m -0x04 #seek_cur
	if headerread != 0 do(do(
	headerread = readBElong m
	TexPropNameStart = readBElong m
	something4 = readBElong m
	nothing = readBElong m
	TexFloatStart = (ftell m)
	TexFloatA = readBEfloat m
	TexFloatB = readBEfloat m
	TexFloatC = readBEfloat m
	TexFloatD = readBEfloat m
	fseek m (NameClumpStart + TexPropNameStart) #seek_set
	TexPropName = readstring m
	fseek m (TexFloatStart + 0x10) #seek_set
	if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
	if TexPropName == "NU_materialHash" do(
		fseek m -0x10 #seek_cur
		TexFloatA = readBElong m
		TexFloatB = readBElong m
		TexFloatC = readBElong m
		TexFloatD = readBElong m	
		print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = 0x" + ((bit.intAsHex(TexFloatA))as string))
		)
	fseek m (TexFloatStart + headerread - 0x10) #seek_set
	) while headerread != 0
	)

	)

	if TexturePropertiesS2Start_array[z] == 0 and Layer2Write == 0 do(
		append TextureIDL2_array (TexIDSet_Struct TexClass:0 TexGroup:0 TexSubgroup:0 TexIndex:0)
		)
	if TexturePropertiesS3Start_array[z] == 0 and Layer3Write == 0 do(
		append TextureIDL3_array (TexIDSet_Struct TexClass:0 TexGroup:0 TexSubgroup:0 TexIndex:0)
		)
	if TexturePropertiesS4Start_array[z] == 0 and Layer4Write == 0 do(
		append TextureIDL4_array (TexIDSet_Struct TexClass:0 TexGroup:0 TexSubgroup:0 TexIndex:0)
		)
	print ("Polygon group " + z as string + " material properties end at 0x" + (bit.intAsHex(ftell m))as string)
	print "--------------------"

	)
	print ("Texture properties end at 0x" + (bit.intAsHex(ftell m))as string)

	for z = 1 to ObjCount do(
	Face_array = #()
	Vert_array = #()
	Color_array = #()
	Alpha_array = #()
	Normal_array = #()
	UV_array = #()
	UV2_array = #()
	UV3_array = #()
	UV4_array = #()
	B1_array = #()
	W1_array = #()
	Weight_array = #()

	fseek m VertexStart_array[z] #seek_set

	case of (
		default: (throw ("Unknown vertex type!"))
		(VertexType_array[z] == 0x00):(
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		vq = readBEfloat m
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1
		if UVType_array[z] == 0x12 or UVType_array[z] == 0x22 or UVType_array[z] == 0x32 or UVType_array[z] == 0x42 do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		)
		if UVType_array[z] == 0x14 or UVType_array[z] == 0x24 or UVType_array[z] == 0x34 or UVType_array[z] == 0x44 do(
		colorr = (readBEHalfFloat m * 128) - 1
		colorg = (readBEHalfFloat m * 128) - 1
		colorb = (readBEHalfFloat m * 128) - 1
		colora = readBEHalfFloat m
		)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		if UVType_array[z] >= 0x20 do(
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV2_array[tu2, tv2, 0]
		)
		if UVType_array[z] >= 0x30 do(
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV3_array[tu3, tv3, 0]
		)
		if UVType_array[z] >= 0x40 do(
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV4_array[tu4, tv4, 0]
		)
		Bone1 = SingleBind_array[z]
		Bone2 = 0
		Bone3 = 0
		Bone4 = 0
		Weight1 = 1
		Weight2 = 0
		Weight3 = 0
		Weight4 = 0
		append Vert_array[vx, vy, vz]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		append UV_array[tu, tv, 0]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x01):(
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		vq = readBEfloat m
		nx = readBEfloat m
		ny = readBEfloat m
		nz = readBEfloat m
		nq = readBEfloat m
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1
		if UVType_array[z] == 0x12 or UVType_array[z] == 0x22 or UVType_array[z] == 0x32 or UVType_array[z] == 0x42 do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		)
		if UVType_array[z] == 0x14 or UVType_array[z] == 0x24 or UVType_array[z] == 0x34 or UVType_array[z] == 0x44 do(
		colorr = (readBEHalfFloat m * 128) - 1
		colorg = (readBEHalfFloat m * 128) - 1
		colorb = (readBEHalfFloat m * 128) - 1
		colora = readBEHalfFloat m
		)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		if UVType_array[z] >= 0x20 do(
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV2_array[tu2, tv2, 0]
		)
		if UVType_array[z] >= 0x30 do(
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV3_array[tu3, tv3, 0]
		)
		if UVType_array[z] >= 0x40 do(
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV4_array[tu4, tv4, 0]
		)
		Bone1 = SingleBind_array[z]
		Bone2 = 0
		Bone3 = 0
		Bone4 = 0
		Weight1 = 1
		Weight2 = 0
		Weight3 = 0
		Weight4 = 0
		append Vert_array[vx, vy, vz]
		append Normal_array[vx, vy, vz]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		append UV_array[tu, tv, 0]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x06):(
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEHalfFloat m
		ny = readBEHalfFloat m
		nz = readBEHalfFloat m
		nq = readBEHalfFloat m
		colorr = 255
		colorg = 255
		colorb = 255
		colora = 255
		if UVType_array[z] == 0x12 or UVType_array[z] == 0x22 or UVType_array[z] == 0x32 or UVType_array[z] == 0x42 do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		)
		if UVType_array[z] == 0x14 or UVType_array[z] == 0x24 or UVType_array[z] == 0x34 or UVType_array[z] == 0x44 do(
		colorr = (readBEHalfFloat m * 128) - 1
		colorg = (readBEHalfFloat m * 128) - 1
		colorb = (readBEHalfFloat m * 128) - 1
		colora = readBEHalfFloat m
		)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		if UVType_array[z] >= 0x22 do(
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV2_array[tu2, tv2, 0]
		)
		if UVType_array[z] >= 0x32 do(
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV3_array[tu3, tv3, 0]
		)
		if UVType_array[z] >= 0x42 do(
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV4_array[tu4, tv4, 0]
		)
		Bone1 = SingleBind_array[z]
		Bone2 = 0
		Bone3 = 0
		Bone4 = 0
		Weight1 = 1
		Weight2 = 0
		Weight3 = 0
		Weight4 = 0
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		append UV_array[tu, tv, 0]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x07):(
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEHalfFloat m
		ny = readBEHalfFloat m
		nz = readBEHalfFloat m
		nq = readBEHalfFloat m
		bnx = readBEHalfFloat m
		bny = readBEHalfFloat m
		bnz = readBEHalfFloat m
		bnq = readBEHalfFloat m
		tanx = readBEHalfFloat m
		tany = readBEHalfFloat m
		tanz = readBEHalfFloat m
		tanq = readBEHalfFloat m
		colorr = 255
		colorg = 255
		colorb = 255
		colora = 255
		if UVType_array[z] == 0x12 or UVType_array[z] == 0x22 or UVType_array[z] == 0x32 or UVType_array[z] == 0x42 do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		)
		if UVType_array[z] == 0x14 or UVType_array[z] == 0x24 or UVType_array[z] == 0x34 or UVType_array[z] == 0x44 do(
		colorr = (readBEHalfFloat m * 128) - 1
		colorg = (readBEHalfFloat m * 128) - 1
		colorb = (readBEHalfFloat m * 128) - 1
		colora = readBEHalfFloat m
		)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		if UVType_array[z] >= 0x22 do(
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV2_array[tu2, tv2, 0]
		)
		if UVType_array[z] >= 0x32 do(
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV3_array[tu3, tv3, 0]
		)
		if UVType_array[z] >= 0x42 do(
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV4_array[tu4, tv4, 0]
		)
		Bone1 = SingleBind_array[z]
		Bone2 = 0
		Bone3 = 0
		Bone4 = 0
		Weight1 = 1
		Weight2 = 0
		Weight3 = 0
		Weight4 = 0
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		append UV_array[tu, tv, 0]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x08):(
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = 0
		vy = 0
		vz = 0
		nx = readBEHalfFloat m
		ny = readBEHalfFloat m
		nz = readBEHalfFloat m
		nq = readBEHalfFloat m
		unk1 = readBEHalfFloat m
		unk2 = readBEHalfFloat m
		unk3 = readBEHalfFloat m
		unk4 = readBEHalfFloat m
		unk5 = readBEHalfFloat m
		colorr = 255
		colorg = 255
		colorb = 255
		colora = 255
		if UVType_array[z] == 0x12 or UVType_array[z] == 0x22 or UVType_array[z] == 0x32 or UVType_array[z] == 0x42 do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		)
		if UVType_array[z] == 0x14 or UVType_array[z] == 0x24 or UVType_array[z] == 0x34 or UVType_array[z] == 0x44 do(
		colorr = (readBEHalfFloat m * 128) - 1
		colorg = (readBEHalfFloat m * 128) - 1
		colorb = (readBEHalfFloat m * 128) - 1
		colora = readBEHalfFloat m
		)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		if UVType_array[z] >= 0x22 do(
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV2_array[tu2, tv2, 0]
		)
		if UVType_array[z] >= 0x32 do(
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV3_array[tu3, tv3, 0]
		)
		if UVType_array[z] >= 0x42 do(
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV4_array[tu4, tv4, 0]
		)
		Bone1 = SingleBind_array[z]
		Bone2 = 0
		Bone3 = 0
		Bone4 = 0
		Weight1 = 1
		Weight2 = 0
		Weight3 = 0
		Weight4 = 0
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		append UV_array[tu, tv, 0]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x11):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEfloat m
		ny = readBEfloat m
		nz = readBEfloat m
		nq = readBEfloat m
		nr = readBEfloat m
		Bone1 = readBElong m + 1
		Bone2 = readBElong m + 1
		Bone3 = readBElong m + 1
		Bone4 = readBElong m + 1
		Weight1 = readBEfloat m
		Weight2 = readBEfloat m
		Weight3 = readBEfloat m
		Weight4 = readBEfloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x13):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		vq = readBEfloat m
		nx = readBEfloat m
		ny = readBEfloat m
		nz = readBEfloat m
		nq = readBEfloat m
		bnx = readBEfloat m
		bny = readBEfloat m
		bnz = readBEfloat m
		bnq = readBEfloat m
		tanx = readBEfloat m
		tany = readBEfloat m
		tanz = readBEfloat m
		tanq = readBEfloat m
		Bone1 = readBElong m + 1
		Bone2 = readBElong m + 1
		Bone3 = readBElong m + 1
		Bone4 = readBElong m + 1
		Weight1 = readBEfloat m
		Weight2 = readBEfloat m
		Weight3 = readBEfloat m
		Weight4 = readBEfloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x16):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEhalffloat m
		ny = readBEhalffloat m
		nz = readBEhalffloat m
		nq = readBEhalffloat m
		Bone1 = readBElong m + 1
		Bone2 = readBElong m + 1
		Bone3 = readBElong m + 1
		Bone4 = readBElong m + 1
		Weight1 = readBEfloat m
		Weight2 = readBEfloat m
		Weight3 = readBEfloat m
		Weight4 = readBEfloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x17):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEhalffloat m
		ny = readBEhalffloat m
		nz = readBEhalffloat m
		nq = readBEhalffloat m
		bnx = readBEhalffloat m
		bny = readBEhalffloat m
		bnz = readBEhalffloat m
		bnq = readBEhalffloat m
		tanx = readBEhalffloat m
		tany = readBEhalffloat m
		tanz = readBEhalffloat m
		tanq = readBEhalffloat m
		Bone1 = readBElong m + 1
		Bone2 = readBElong m + 1
		Bone3 = readBElong m + 1
		Bone4 = readBElong m + 1
		Weight1 = readBEfloat m
		Weight2 = readBEfloat m
		Weight3 = readBEfloat m
		Weight4 = readBEfloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x21):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEfloat m
		ny = readBEfloat m
		nz = readBEfloat m
		nq = readBEfloat m
		nr = readBEfloat m
		Bone1 = readBEword m + 1
		Bone2 = readBEword m + 1
		Bone3 = readBEword m + 1
		Bone4 = readBEword m + 1
		Weight1 = readBEhalffloat m
		Weight2 = readBEhalffloat m
		Weight3 = readBEhalffloat m
		Weight4 = readBEhalffloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x23):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		vq = readBEfloat m
		nx = readBEfloat m
		ny = readBEfloat m
		nz = readBEfloat m
		nq = readBEfloat m
		bnx = readBEfloat m
		bny = readBEfloat m
		bnz = readBEfloat m
		bnq = readBEfloat m
		tanx = readBEfloat m
		tany = readBEfloat m
		tanz = readBEfloat m
		tanq = readBEfloat m
		Bone1 = readBEword m + 1
		Bone2 = readBEword m + 1
		Bone3 = readBEword m + 1
		Bone4 = readBEword m + 1
		Weight1 = readBEhalffloat m
		Weight2 = readBEhalffloat m
		Weight3 = readBEhalffloat m
		Weight4 = readBEhalffloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x26):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEhalffloat m
		ny = readBEhalffloat m
		nz = readBEhalffloat m
		nq = readBEhalffloat m
		Bone1 = readBEword m + 1
		Bone2 = readBEword m + 1
		Bone3 = readBEword m + 1
		Bone4 = readBEword m + 1
		Weight1 = readBEhalffloat m
		Weight2 = readBEhalffloat m
		Weight3 = readBEhalffloat m
		Weight4 = readBEhalffloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x27):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEhalffloat m
		ny = readBEhalffloat m
		nz = readBEhalffloat m
		nq = readBEhalffloat m
		bnx = readBEhalffloat m
		bny = readBEhalffloat m
		bnz = readBEhalffloat m
		bnq = readBEhalffloat m
		tanx = readBEhalffloat m
		tany = readBEhalffloat m
		tanz = readBEhalffloat m
		tanq = readBEhalffloat m
		Bone1 = readBEword m + 1
		Bone2 = readBEword m + 1
		Bone3 = readBEword m + 1
		Bone4 = readBEword m + 1
		Weight1 = readBEhalffloat m
		Weight2 = readBEhalffloat m
		Weight3 = readBEhalffloat m
		Weight4 = readBEhalffloat m
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x40):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		floatyval = readBEfloat m
		Bone1 = readbyte m #unsigned + 1
		Bone2 = readbyte m #unsigned + 1
		Bone3 = readbyte m #unsigned + 1
		Bone4 = readbyte m #unsigned + 1
		Weight1 = (readbyte m #unsigned) as float / 255
		Weight2 = (readbyte m #unsigned) as float / 255
		Weight3 = (readbyte m #unsigned) as float / 255
		Weight4 = (readbyte m #unsigned) as float / 255
		append Vert_array[vx, vy, vz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x46):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEHalfFloat m
		ny = readBEHalfFloat m
		nz = readBEHalfFloat m
		nq = readBEHalfFloat m
		Bone1 = readbyte m #unsigned + 1
		Bone2 = readbyte m #unsigned + 1
		Bone3 = readbyte m #unsigned + 1
		Bone4 = readbyte m #unsigned + 1
		Weight1 = (readbyte m #unsigned) as float / 255
		Weight2 = (readbyte m #unsigned) as float / 255
		Weight3 = (readbyte m #unsigned) as float / 255
		Weight4 = (readbyte m #unsigned) as float / 255
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(VertexType_array[z] == 0x47):(
		print ("UV start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", UV size: 0x"+((bit.intAsHex(UVType_array[z]))as string))
		if UVType_array[z] == 0x10 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = 127
		colorg = 127
		colorb = 127
		colora = 1 as float
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x12 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x22 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x32 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		if UVType_array[z] == 0x42 do(
		for x = 1 to VertexAmount_array[z] do(
		colorr = readbyte m #unsigned
		colorg = readbyte m #unsigned
		colorb = readbyte m #unsigned
		colora = (readbyte m #unsigned) as float / 127
		if colora >= 254 do(colora = 255)
		if colormult == true do(
			colorr = colorr * 2
			colorg = colorg * 2
			colorb = colorb * 2
			if colorr >= 254 do(colorr = 255)
			if colorg >= 254 do(colorg = 255)
			if colorb >= 254 do(colorb = 255)
			)
		tu = (readBEHalfFloat m) * 2
		tv = (((readBEHalfFloat m) * 2) * -1) + 1
		tu2 = (readBEHalfFloat m) * 2
		tv2 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu3 = (readBEHalfFloat m) * 2
		tv3 = (((readBEHalfFloat m) * 2) * -1) + 1
		tu4 = (readBEHalfFloat m) * 2
		tv4 = (((readBEHalfFloat m) * 2) * -1) + 1
		append UV_array[tu, tv, 0]
		append UV2_array[tu2, tv2, 0]
		append UV3_array[tu3, tv3, 0]
		append UV4_array[tu4, tv4, 0]
		append Color_Array[colorr,colorg,colorb]
		append Alpha_Array colora
		)
		)
		print ("UV end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))	

		fseek m VertexAddStart_array[z] #seek_set
		print ("Vertex start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string) + ", Vertex size: 0x"+((bit.intAsHex(VertexType_array[z]))as string))
		for x = 1 to VertexAmount_array[z] do(
		vx = readBEfloat m
		vy = readBEfloat m
		vz = readBEfloat m
		nx = readBEHalfFloat m
		ny = readBEHalfFloat m
		nz = readBEHalfFloat m
		nq = readBEHalfFloat m
		bnx = readBEHalfFloat m
		bny = readBEHalfFloat m
		bnz = readBEHalfFloat m
		bnq = readBEHalfFloat m
		tanx = readBEHalfFloat m
		tany = readBEHalfFloat m
		tanz = readBEHalfFloat m
		tanq = readBEHalfFloat m
		Bone1 = readbyte m #unsigned + 1
		Bone2 = readbyte m #unsigned + 1
		Bone3 = readbyte m #unsigned + 1
		Bone4 = readbyte m #unsigned + 1
		Weight1 = (readbyte m #unsigned) as float / 255
		Weight2 = (readbyte m #unsigned) as float / 255
		Weight3 = (readbyte m #unsigned) as float / 255
		Weight4 = (readbyte m #unsigned) as float / 255
		append Vert_array[vx, vy, vz]
		append Normal_array[nx, ny, nz]
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		print ("Vertex end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
	)

	fseek m PolyStart_array[z] #seek_set
	case of (
		default: (throw("Unknown polygon type!"))
		(PolyType_array[z] == 0x00):(
		print ("Face start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))

		FaceCount = PolyAmount_array[z]
		FaceStart = ftell m
		VerStart = (FaceCount * 2) + FaceStart

		StartDirection = 1
		f1 = (ReadBEword m) + 1
		f2 = (ReadBEword m) + 1  
		FaceDirection = StartDirection
		Do (
		f3 = (ReadBEword m)
		if (f3==0xFFFF) then (
		f1 = (ReadBEword m) + 1
		f2 = (ReadBEword m) + 1
		FaceDirection = StartDirection 
		) else (
		f3 += 1
		FaceDirection *= -1
		if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
		if FaceDirection > 0 then append Face_array [f3,f2,f1]
		else append Face_array [f2,f3,f1]
		)
		f1 = f2
		f2 = f3
		) 
		) while ((ftell m) != (VerStart))

		print ("Face end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
		(PolyType_array[z] == 0x40):(
		print ("Face start " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		for x = 1 to (PolyAmount_array[z] / 3) do(
		fa = readBEword m + 1
		fb = readBEword m + 1
		fc = readBEword m + 1
		append Face_array[fa, fb, fc]
		)
		print ("Face end " + z as string + ": 0x"+((bit.intAsHex(ftell m))as string))
		)
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
			 append w.boneids (B1_array[b].Bone1)
			 append w.weights (w1)
		  )
		  if(W1_array[b].Weight2 != 0) then
		  (
			 w2 = W1_array[b].Weight2 as float
			 append w.boneids (B1_array[b].Bone2)
			 append w.weights (w2)
		  )
		  if(W1_array[b].Weight3 != 0) then
		  (
			 w3 = W1_array[b].Weight3 as float
			 append w.boneids (B1_array[b].Bone3)
			 append w.weights (w3)
		  )
		  if(W1_array[b].Weight4 != 0) then
		  (
			 w4 = W1_array[b].Weight4 as float
			 append w.boneids (B1_array[b].Bone4)
			 append w.weights (w4)
		  )      
	   )
	append Weight_array w
	)

	mat = standardMaterial()
	mat.name = (TextureIDL1_array[z].TexClass as string + "_" + TextureIDL1_array[z].TexGroup as string + "_" + TextureIDL1_array[z].TexSubgroup as string + "_" + TextureIDL1_array[z].TexIndex as string)
	mat.showinviewport = true
	mat.twosided = false
	if PNGTex == false then (tm = Bitmaptexture filename:(p + "model_" + TextureIDL1_array[z].TexClass as string + "_" + TextureIDL1_array[z].TexGroup as string + "_" + TextureIDL1_array[z].TexSubgroup as string + "_" + TextureIDL1_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + "model_" + TextureIDL1_array[z].TexClass as string + "_" + TextureIDL1_array[z].TexGroup as string + "_" + TextureIDL1_array[z].TexSubgroup as string + "_" + TextureIDL1_array[z].TexIndex as string + ".png"))
	tm.alphasource = 0
	mat.diffuseMap = tm
	mat.opacityMap = tm
	mat.opacityMap.monoOutput = 1

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = Vert_array.count
	if ColorDisable == false then (
	setNumCPVVerts msh msh.numTVerts
	setCVertMode msh true
	setShadeCVerts msh true
	)
	defaultVCFaces msh
	buildTVFaces msh
	fseek m (NameClumpStart + PolyName_array[z]) #seek_set
	PolyName = readstring m
	msh.name = (PolyName + "_")
	msh.material = mat

	for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
	for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
	max modify mode
	select msh

		  addmodifier msh (Edit_Normals ()) ui:off
		  msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		  EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		  EN_setNormal = msh.Edit_Normals.SetNormal
		  normID = #{}
		  for v = 1 to Normal_array.count do
		  (
			 free normID
			 EN_convertVS #{v} &normID
			 for id in normID do EN_setNormal id Normal_array[v]
		  )

	if BoneArray.count > 0 do(
			skinMod = skin ()
			boneIDMap = #()
			addModifier msh skinMod
			for i = 1 to BoneCount do
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

			for i = 1 to Vert_array.count do(
				skinOps.SetVertexWeights skinMod i 1 1
				skinOps.unnormalizeVertex skinMod i true 
				skinOps.SetVertexWeights skinMod i 1 0
			)
				skinOps.RemoveZeroWeights skinMod
			for i = 1 to Vert_array.count do(
				skinOps.unnormalizeVertex skinMod i false
			) -- These fix broken rigging for 3DS Max 2015 and above.

			for i = 1 to Weight_array.count do (
				w = Weight_array[i]
				bi = #()
				wv = #()
				
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

	if UV2_array.count > 0 do(
	mat = standardMaterial()
	mat.name = (TextureIDL2_array[z].TexClass as string + "_" + TextureIDL2_array[z].TexGroup as string + "_" + TextureIDL2_array[z].TexSubgroup as string + "_" + TextureIDL2_array[z].TexIndex as string)
	mat.showinviewport = true
	mat.twosided = false
	if PNGTex == false then (tm = Bitmaptexture filename:(p + "model_" + TextureIDL2_array[z].TexClass as string + "_" + TextureIDL2_array[z].TexGroup as string + "_" + TextureIDL2_array[z].TexSubgroup as string + "_" + TextureIDL2_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + "model_" + TextureIDL2_array[z].TexClass as string + "_" + TextureIDL2_array[z].TexGroup as string + "_" + TextureIDL2_array[z].TexSubgroup as string + "_" + TextureIDL2_array[z].TexIndex as string + ".png"))
	tm.alphasource = 0
	mat.diffuseMap = tm
	mat.opacityMap = tm
	mat.opacityMap.monoOutput = 1

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = Vert_array.count
	if ColorDisable == false then (
	setNumCPVVerts msh msh.numTVerts
	setCVertMode msh true
	setShadeCVerts msh true
	)
	defaultVCFaces msh
	buildTVFaces msh
	fseek m (NameClumpStart + PolyName_array[z]) #seek_set
	PolyName = readstring m
	msh.name = (PolyName + "_ Layer 2")
	msh.material = mat

	for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
	for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
	for j = 1 to UV2_array.count do setTVert msh j UV2_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
	max modify mode
	select msh

		  addmodifier msh (Edit_Normals ()) ui:off
		  msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		  EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		  EN_setNormal = msh.Edit_Normals.SetNormal
		  normID = #{}
		  for v = 1 to Normal_array.count do
		  (
			 free normID
			 EN_convertVS #{v} &normID
			 for id in normID do EN_setNormal id Normal_array[v]
		  )

	if BoneArray.count > 0 do(
			skinMod = skin ()
			boneIDMap = #()
			addModifier msh skinMod
			for i = 1 to BoneCount do
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

			for i = 1 to Vert_array.count do(
				skinOps.SetVertexWeights skinMod i 1 1
				skinOps.unnormalizeVertex skinMod i true 
				skinOps.SetVertexWeights skinMod i 1 0
			)
				skinOps.RemoveZeroWeights skinMod
			for i = 1 to Vert_array.count do(
				skinOps.unnormalizeVertex skinMod i false
			) -- These fix broken rigging for 3DS Max 2015 and above.

			for i = 1 to Weight_array.count do (
				w = Weight_array[i]
				bi = #()
				wv = #()
				
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

	if UV3_array.count > 0 do(
	mat = standardMaterial()
	mat.name = (TextureIDL3_array[z].TexClass as string + "_" + TextureIDL3_array[z].TexGroup as string + "_" + TextureIDL3_array[z].TexSubgroup as string + "_" + TextureIDL3_array[z].TexIndex as string)
	mat.showinviewport = true
	mat.twosided = false
	if PNGTex == false then (tm = Bitmaptexture filename:(p + "model_" + TextureIDL3_array[z].TexClass as string + "_" + TextureIDL3_array[z].TexGroup as string + "_" + TextureIDL3_array[z].TexSubgroup as string + "_" + TextureIDL3_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + "model_" + TextureIDL3_array[z].TexClass as string + "_" + TextureIDL3_array[z].TexGroup as string + "_" + TextureIDL3_array[z].TexSubgroup as string + "_" + TextureIDL3_array[z].TexIndex as string + ".png"))
	tm.alphasource = 0
	mat.diffuseMap = tm
	mat.opacityMap = tm
	mat.opacityMap.monoOutput = 1

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = Vert_array.count
	if ColorDisable == false then (
	setNumCPVVerts msh msh.numTVerts
	setCVertMode msh true
	setShadeCVerts msh true
	)
	defaultVCFaces msh
	buildTVFaces msh
	fseek m (NameClumpStart + PolyName_array[z]) #seek_set
	PolyName = readstring m
	msh.name = (PolyName + "_ Layer 3")
	msh.material = mat

	for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
	for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
	for j = 1 to UV3_array.count do setTVert msh j UV3_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
	max modify mode
	select msh

		  addmodifier msh (Edit_Normals ()) ui:off
		  msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		  EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		  EN_setNormal = msh.Edit_Normals.SetNormal
		  normID = #{}
		  for v = 1 to Normal_array.count do
		  (
			 free normID
			 EN_convertVS #{v} &normID
			 for id in normID do EN_setNormal id Normal_array[v]
		  )

	if BoneArray.count > 0 do(
			skinMod = skin ()
			boneIDMap = #()
			addModifier msh skinMod
			for i = 1 to BoneCount do
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

			for i = 1 to Vert_array.count do(
				skinOps.SetVertexWeights skinMod i 1 1
				skinOps.unnormalizeVertex skinMod i true 
				skinOps.SetVertexWeights skinMod i 1 0
			)
				skinOps.RemoveZeroWeights skinMod
			for i = 1 to Vert_array.count do(
				skinOps.unnormalizeVertex skinMod i false
			) -- These fix broken rigging for 3DS Max 2015 and above.

			for i = 1 to Weight_array.count do (
				w = Weight_array[i]
				bi = #()
				wv = #()
				
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

	if UV4_array.count > 0 do(
	mat = standardMaterial()
	mat.name = (TextureIDL4_array[z].TexClass as string + "_" + TextureIDL4_array[z].TexGroup as string + "_" + TextureIDL4_array[z].TexSubgroup as string + "_" + TextureIDL4_array[z].TexIndex as string)
	mat.showinviewport = true
	mat.twosided = false
	if PNGTex == false then (tm = Bitmaptexture filename:(p + "model_" + TextureIDL4_array[z].TexClass as string + "_" + TextureIDL4_array[z].TexGroup as string + "_" + TextureIDL4_array[z].TexSubgroup as string + "_" + TextureIDL4_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + "model_" + TextureIDL4_array[z].TexClass as string + "_" + TextureIDL4_array[z].TexGroup as string + "_" + TextureIDL4_array[z].TexSubgroup as string + "_" + TextureIDL4_array[z].TexIndex as string + ".png"))
	tm.alphasource = 0
	mat.diffuseMap = tm
	mat.opacityMap = tm
	mat.opacityMap.monoOutput = 1

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = Vert_array.count
	if ColorDisable == false then (
	setNumCPVVerts msh msh.numTVerts
	setCVertMode msh true
	setShadeCVerts msh true
	)
	defaultVCFaces msh
	buildTVFaces msh
	fseek m (NameClumpStart + PolyName_array[z]) #seek_set
	PolyName = readstring m
	msh.name = (PolyName + "_ Layer 4")
	msh.material = mat

	for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
	for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
	for j = 1 to UV4_array.count do setTVert msh j UV4_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
	max modify mode
	select msh

		  addmodifier msh (Edit_Normals ()) ui:off
		  msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		  EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		  EN_setNormal = msh.Edit_Normals.SetNormal
		  normID = #{}
		  for v = 1 to Normal_array.count do
		  (
			 free normID
			 EN_convertVS #{v} &normID
			 for id in normID do EN_setNormal id Normal_array[v]
		  )

	if BoneArray.count > 0 do(
			skinMod = skin ()
			boneIDMap = #()
			addModifier msh skinMod
			for i = 1 to BoneCount do
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

			for i = 1 to Vert_array.count do(
				skinOps.SetVertexWeights skinMod i 1 1
				skinOps.unnormalizeVertex skinMod i true 
				skinOps.SetVertexWeights skinMod i 1 0
			)
				skinOps.RemoveZeroWeights skinMod
			for i = 1 to Vert_array.count do(
				skinOps.unnormalizeVertex skinMod i false
			) -- These fix broken rigging for 3DS Max 2015 and above.

			for i = 1 to Weight_array.count do (
				w = Weight_array[i]
				bi = #()
				wv = #()
				
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

	print ("Finished building " + PolyName as string + "!")

	)

	print ("Ended: 0x"+((bit.intAsHex(ftell m))as string))

	)

	gc()
	fclose m
	fclose q
	)

	on btnIDFixNUD pressed do(
	local TexIDChangeA = boxTexIDChangeA.value
	local TexIDChangeB = boxTexIDChangeB.value
	local TexIDChangeC = boxTexIDChangeC.value
	local TexIDChangeD = tglTexIDChangeD.state
	clearlistener()

	if TexIDChangeA == 16 do(print "Class 16 is reserved for system textures and can't be used!")

	if TexIDChangeA != 16 do(
	fname = getOpenFileName \ 
	caption:"Super Smash Bros. for Wii U / Taiko model file" \
	types:"SSB4U/TnTU model(*.nud)|*.nud" \
	historyCategory:"SSB4U"

	if fname != undefined do (
	m = fopen fname "r+"
	p = getFilenamePath fname

	TexturePropertiesS1Start_array = #()
	TexturePropertiesS2Start_array = #()
	TexturePropertiesS3Start_array = #()
	TexturePropertiesS4Start_array = #()

	fseek m 0x00 #seek_set
	fseek m 0x0A #seek_cur
	polysets = readBEword m
	fseek m 0x24 #seek_cur

	ObjCount = 0
	for z = 1 to polysets do(
	print ("Polyset info " + z as string + " start at 0x" + (bit.intAsHex(ftell m))as string)
	fseek m 0x2A #seek_cur
	polyamount = readBEword m
	ObjPropStart = readBElong m
	ObjCount = (ObjCount + polyamount)
	)

	for z = 1 to ObjCount do(
	print ("Object properties " + z as string + " start at 0x" + (bit.intAsHex(ftell m))as string)
	fseek m 0x10 #seek_cur
	TextureSet1Properties = readBElong m
	TextureSet2Properties = readBElong m
	TextureSet3Properties = readBElong m
	TextureSet4Properties = readBElong m
	fseek m 0x10 #seek_cur
	append TexturePropertiesS1Start_array TextureSet1Properties
	append TexturePropertiesS2Start_array TextureSet2Properties
	append TexturePropertiesS3Start_array TextureSet3Properties
	append TexturePropertiesS4Start_array TextureSet4Properties
	)
		
	for z = 1 to ObjCount do(
	fseek m TexturePropertiesS1Start_array[z] #seek_set
	print ("Polygon group " + z as string + " material properties start at 0x" + (bit.intAsHex(ftell m))as string)
	fseek m 0x0A #seek_cur
	TexLayerCount = readBEword m
	fseek m 0x14 #seek_cur
	print "Texture information:"

	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	print "BEFORE:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)

	fseek m -0x04 #seek_cur
	if TexClass != 16 then(
	TexClass = writebyte m TexIDChangeA
	TexGroup = writebyte m TexIDChangeB
	TexSubgroup = writebyte m TexIDChangeC

	if TexIDChangeD == 1 do(
	fseek m 0x01 #seek_cur
	)	
		
	if TexIDChangeD == 2 and TexIndex > 127 then(
	TexIndexNew = TexIndex - 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 2 and TexIndex < 128 do(
	fseek m 0x01 #seek_cur
	))

	if TexIDChangeD == 3 and TexIndex < 128 then(
	TexIndexNew = TexIndex + 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 3 and TexIndex > 127 do(
	fseek m 0x01 #seek_cur
	))

	fseek m -0x04 #seek_cur
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	) else (fseek m 0x04 #seek_cur)
	fseek m 0x14 #seek_cur
	print "AFTER:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	if TexturePropertiesS2Start_array[z] != 0 do(
	fseek m TexturePropertiesS2Start_array[z] #seek_set
	print "--------------------"
	print ("Polygon group " + z as string + " Set 2 material properties:")
	fseek m 0x0A #seek_cur
	TexLayerCount = readBEword m
	fseek m 0x14 #seek_cur
	print "Texture information:"
		
	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	print "BEFORE:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)

	fseek m -0x04 #seek_cur
	if TexClass != 16 then(
	TexClass = writebyte m TexIDChangeA
	TexGroup = writebyte m TexIDChangeB
	TexSubgroup = writebyte m TexIDChangeC

	if TexIDChangeD == 1 do(
	fseek m 0x01 #seek_cur
	)	
		
	if TexIDChangeD == 2 and TexIndex > 127 then(
	TexIndexNew = TexIndex - 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 2 and TexIndex < 128 do(
	fseek m 0x01 #seek_cur
	))

	if TexIDChangeD == 3 and TexIndex < 128 then(
	TexIndexNew = TexIndex + 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 3 and TexIndex > 127 do(
	fseek m 0x01 #seek_cur
	))

	fseek m -0x04 #seek_cur
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	) else (fseek m 0x04 #seek_cur)
	fseek m 0x14 #seek_cur
	print "AFTER:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	)

	if TexturePropertiesS3Start_array[z] != 0 do(
	fseek m TexturePropertiesS3Start_array[z] #seek_set
	print "--------------------"
	print ("Polygon group " + z as string + " Set 3 material properties:")
	fseek m 0x0A #seek_cur
	TexLayerCount = readBEword m
	fseek m 0x14 #seek_cur
	print "Texture information:"
		
	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	print "BEFORE:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)

	fseek m -0x04 #seek_cur
	if TexClass != 16 then(
	TexClass = writebyte m TexIDChangeA
	TexGroup = writebyte m TexIDChangeB
	TexSubgroup = writebyte m TexIDChangeC

	if TexIDChangeD == 1 do(
	fseek m 0x01 #seek_cur
	)	
		
	if TexIDChangeD == 2 and TexIndex > 127 then(
	TexIndexNew = TexIndex - 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 2 and TexIndex < 128 do(
	fseek m 0x01 #seek_cur
	))

	if TexIDChangeD == 3 and TexIndex < 128 then(
	TexIndexNew = TexIndex + 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 3 and TexIndex > 127 do(
	fseek m 0x01 #seek_cur
	))

	fseek m -0x04 #seek_cur
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	) else (fseek m 0x04 #seek_cur)
	fseek m 0x14 #seek_cur
	print "AFTER:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	)

	if TexturePropertiesS4Start_array[z] != 0 do(
	fseek m TexturePropertiesS4Start_array[z] #seek_set
	print "--------------------"
	print ("Polygon group " + z as string + " Set 4 material properties:")
	fseek m 0x0A #seek_cur
	TexLayerCount = readBEword m
	fseek m 0x14 #seek_cur
	print "Texture information:"

	for x = 1 to TexLayerCount do(
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	print "BEFORE:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)

	fseek m -0x04 #seek_cur
	if TexClass != 16 then(
	TexClass = writebyte m TexIDChangeA
	TexGroup = writebyte m TexIDChangeB
	TexSubgroup = writebyte m TexIDChangeC

	if TexIDChangeD == 1 do(
	fseek m 0x01 #seek_cur
	)	
		
	if TexIDChangeD == 2 and TexIndex > 127 then(
	TexIndexNew = TexIndex - 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 2 and TexIndex < 128 do(
	fseek m 0x01 #seek_cur
	))

	if TexIDChangeD == 3 and TexIndex < 128 then(
	TexIndexNew = TexIndex + 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 3 and TexIndex > 127 do(
	fseek m 0x01 #seek_cur
	))

	fseek m -0x04 #seek_cur
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	) else (fseek m 0x04 #seek_cur)
	fseek m 0x14 #seek_cur
	print "AFTER:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	)

	)

	print ("Polygon group " + z as string + " material properties end at 0x" + (bit.intAsHex(ftell m))as string)
	print "--------------------"

	)
	print ("Texture properties end at 0x" + (bit.intAsHex(ftell m))as string)

	print "Done!"
	fclose m
	)
	)
	)

	on btnIDFixNUT pressed do(
	local TexIDChangeA = boxTexIDChangeA.value
	local TexIDChangeB = boxTexIDChangeB.value
	local TexIDChangeC = boxTexIDChangeC.value
	local TexIDChangeD = tglTexIDChangeD.state
	clearlistener()

	if TexIDChangeA == 16 do(print "Class 16 is reserved for system textures and can't be used!")

	if TexIDChangeA != 16 do(
	fname = getOpenFileName \ 
	caption:"Super Smash Bros. for Wii U / Taiko model file" \
	types:"SSB4U/TnTU model(*.nut)|*.nut" \
	historyCategory:"SSB4U"

	if fname != undefined do (
	m = fopen fname "r+"
	p = getFilenamePath fname

	fseek m 0x00 #seek_set
	fseek m 0x06 #seek_cur
	FileTotal = readBEword m
	fseek m 0x08 #seek_cur
		
	for x = 1 to FileTotal do(
	fseek m 0x0C #seek_cur
	HeaderSize = readBEword m
	fseek m 0x02 #seek_cur
	fseek m (HeaderSize - 0x20) #seek_cur
	fseek m 0x08 #seek_cur

	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	print "BEFORE:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)

	fseek m -0x04 #seek_cur
	if TexClass != 16 then(
	TexClass = writebyte m TexIDChangeA
	TexGroup = writebyte m TexIDChangeB
	TexSubgroup = writebyte m TexIDChangeC

	if TexIDChangeD == 1 do(
	fseek m 0x01 #seek_cur
	)	
		
	if TexIDChangeD == 2 and TexIndex > 127 then(
	TexIndexNew = TexIndex - 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 2 and TexIndex < 128 do(
	fseek m 0x01 #seek_cur
	))

	if TexIDChangeD == 3 and TexIndex < 128 then(
	TexIndexNew = TexIndex + 128
	TexIndex = writebyte m TexIndexNew
	) else (if TexIDChangeD == 3 and TexIndex > 127 do(
	fseek m 0x01 #seek_cur
	))

	fseek m -0x04 #seek_cur
	TexClass = readbyte m #unsigned
	TexGroup = readbyte m #unsigned
	TexSubgroup = readbyte m #unsigned
	TexIndex = readbyte m #unsigned
	) else (fseek m 0x04 #seek_cur)
	print "AFTER:"
	print ("Class: " + TexClass as string + ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
	fseek m 0x04 #seek_cur

	)

	print "Done!"
	fclose m

	)

	)

	)

)
CreateDialog SSB4UImporter