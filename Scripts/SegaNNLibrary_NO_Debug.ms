fn floatSwap2 f = (
	i = bit.floatAsInt f
	h = bit.intashex i
	while h.count < 8 do h = "0" + h
	
	s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
	bit.intAsFloat (bit.hexasint s)
)	

fn readBEshort fstream = (
	short = readshort fstream #unsigned
	short = bit.swapBytes short 1 2
	return short
)

fn ReadBEHalfFloat Fstream = (
  local BH  = readByte Fstream #unsigned
  local BL  = readByte Fstream #unsigned
  local N = BH*256 + BL
  local S = floor((mod N 65536) / 32768)
  local Ef = floor((mod N 32768) / 1024)
  local M = mod N 1024
  if (Ef==0)AND(M==0) then return ( (-1.0)^S * 0.0 )
  if (Ef==0)AND(M!=0) then return ( (-1.0)^S * 2.0^-14 * (M / 2.0^10) )
  if (Ef>0)AND(Ef<31) then return ( (-1.0)^S * 2.0^(Ef-15) * (1 + M/2.0^10) )
  if (Ef==31)AND(M==0) then return ( (-1.0)^S * 1/0.0 )
  if (Ef==31)AND(M!=0) then return 0	--hack-- should be #inf   
 )--end fn ReadBEHalfFloat

fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)

fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)

fn ReadFixedString bstream fixedLen = (
    local str = ""
    for i = 1 to fixedLen do
    (
        str += bit.intAsChar (ReadByte bstream #unsigned)
    )
    str
)

fn ReadBEBAMS fstream = (
	(ReadBEShort fstream /65536)*360
	fseek fstream 2#seek_cur
)

fn ReadFixedString bstream fixedLen = (
    local str = ""
    for i = 1 to fixedLen do
    (
        str += bit.intAsChar (ReadByte bstream #unsigned)
    )
    str
)

fn ReadBAMS fstream = (
	(ReadShort fstream /65536)*360
	fseek fstream 2#seek_cur
)

fn killext str = (
str[str.count-2] = "p"
str[str.count-1] = "n"
str[str.count] = "g"
return str
)

fn readBEshortS fstream = (
	short = readshort fstream
	short = bit.swapBytes short 1 2
	return short
)

fn readBEUV fstream = (
	short = readshort fstream
	short = bit.swapBytes short 1 2
	short = (short as float) /256
	return short
)

rollout SegaNORollout "Import *NO Files" width:425 height:230
(
	button btnENO "Import ENO" pos:[8,8] width:150 height:39
	button btnXNO "Import XNO" pos:[8,52] width:150 height:39
	button btnZNO "Import ZNO" pos:[8,96] width:150 height:39
	button btnGNO "Import GNO" pos:[8,140] width:150 height:39
	label lblCred "This tool was created by ItsEasyActually (darkspines35/Brooks) and updated by Random Talking Bush. It was made for importing Sonic models from Wii, 360, and PC based titles. Please give credit where it is due. Enjoy!" pos:[8,185] width:400 height:80
	label lblENO "Used for Sonic Free Riders [XBox 360]." pos:[164,8] width:255 height:39
	label lblXNO "Used for Sonic the Hedgehog (2006) [XBox 360]." pos:[164,52] width:255 height:39
	label lblZNO "Used for Sonic the Hedgehog 4: Episode I / II [PC]." pos:[164,96] width:255 height:39
	label lblGNO "Used for Sonic and the Secret Rings / Black Knight / Unleashed (Wii) / 4: Episode I / II, Super Monkey Ball Banana Blitz / Step and Roll. [Wii]" pos:[165,140] width:255 height:39
	checkbox tglVertAlpha "Use Vertex Alphas?" pos:[164,68] width:150 height:15 tooltip: "If this is enabled, the model will use the vertex alpha information for the model instead of the vertex colours. Best used with the character models." checked: false

	on btnENO pressed do(
clearlistener()
fname = GetOpenFileName caption:"Open ENO model" types:"ENO Model File(*.eno)|*.eno"
if fname != undefined do(
f = fopen fname "rb"   --open file in read only format

struct VertGroup(
	VOffset
)
struct PolyGroup(
	POffset
)
struct BoneInfo(
	BoneName
)
struct Ftotal(
	FaceTotal
)

VertGroupArray=#()
PolyGroupArray=#()
BoneArray=#()
BoneInfoArray=#()
TextureNames = #()


-- NEIF --
NEIF = ReadFixedString f 4
NEIFSize = ReadLong f 
StructFlag = ReadBELong f
fseek f 0x14#seek_cur

If StructFlag == 1 Do (
	-- NENN --
	NENN = ReadFixedString f 4
	NENNSize = ReadLong f
	fseek f NENNSize#seek_cur
)

If StructFlag == 2 Do (
	-- NETL --
	NETL = ReadFixedString f 4
	NETLSize = ReadLong f
	Rtn = ftell f
	
	TexInfo = ReadBELong f + 0x20
	fseek f TexInfo#seek_set
	TexTotal = ReadBELong f
	TexStart = ReadBELong f +0x20
	fseek f TexStart#seek_set
	
	For tx = 1 to TexTotal Do (
		fseek f 4#seek_cur
		TexNameOff = ReadBELong f +0x20
		fseek f 12#seek_cur
		TxRtn = ftell f
		fseek f TexNameOff#seek_set
		TexName = ReadString f
		print TexName
		append TextureNames (TexName)
		fseek f TxRtn#seek_set
	)
	fseek f Rtn#seek_set
	fseek f NETLSize#seek_cur
)

If StructFlag == 3 Do (
	-- NETL --
	NETL = ReadFixedString f 4
	NETLSize = ReadLong f
	Rtn = ftell f
	
	TexInfo = ReadBELong f + 0x20
	fseek f TexInfo#seek_set
	TexTotal = ReadBELong f
	TexStart = ReadBELong f +0x20
	fseek f TexStart#seek_set
	
	For tx = 1 to TexTotal Do (
		fseek f 4#seek_cur
		TexNameOff = ReadBELong f +0x20
		fseek f 12#seek_cur
		TxRtn = ftell f
		fseek f TexNameOff#seek_set
		TexName = ReadString f
		print TexName
		append TextureNames (TexName)
		fseek f TxRtn#seek_set
	)
	fseek f Rtn#seek_set
	fseek f NETLSize#seek_cur
	
	-- NENN --
	NENN = ReadFixedString f 4
	NENNSize = ReadLong f
	fseek f NENNSize#seek_cur
)

-- NEOB --
NEOB = ReadFixedString f 4
NEOBSize = ReadLong f
GInfoOff = ReadBELong f + 0x30

fseek f GInfoOff#seek_set
Print ("GInfoOff start = 0x"+(bit.intAsHex(ftell f)as string))
TexElmTotal = ReadBELong f
TexElmOff = ReadBELong f + 0x20
VertGroupTotal = ReadBELong f
VertGroupOff = ReadBELong f + 0x20
PolyGroupTotal = ReadBELong f
PolyGroupOff = ReadBELong f + 0x20
BoneTotal = ReadBELong f
fseek f 4#seek_cur
BoneOffset = ReadBELong f + 0x20
NodeTotal = ReadBELong f
LinkTotal = ReadBELong f
LinkOffset = ReadBELong f + 0x20
Print ("GInfoOff end = 0x"+(bit.intAsHex(ftell f)as string))

-- Building Vert Groups --
fseek f VertGroupOff#seek_set
Print ("VertGroupOff start = 0x"+(bit.intAsHex(ftell f)as string))
For vg = 1 to VertGroupTotal Do (
	fseek f 4#seek_cur
	VertInfoOffset = ReadBELong f + 0x20
	append VertGroupArray (VertGroup VOffset:VertInfoOffset)
)
Print ("VertGroupOff end = 0x"+(bit.intAsHex(ftell f)as string))

-- Building Poly Groups --
fseek f PolyGroupOff#seek_set
Print ("PolyGroupOff start = 0x"+(bit.intAsHex(ftell f)as string))
For pg = 1 to PolyGroupTotal Do (
	fseek f 4#seek_cur
	PolyInfoOffset = ReadBELong f + 0x20
	append PolyGroupArray (PolyGroup POffset:PolyInfoOffset)
)
Print ("PolyGroupOff end = 0x"+(bit.intAsHex(ftell f)as string))

-- Bone Importing Functions -- 
fseek f BoneOffset#seek_set
Print ("Bones start = 0x"+((bit.intAsHex(ftell f))as string))
ProperBone_array = #()
For t = 1 to BoneTotal Do (
	BoneName = "Bone" + t as string
	Header1 = ReadByte f #unsigned
	Header2 = ReadByte f #unsigned
	Header3 = ReadByte f #unsigned
	Header4 = ReadByte f #unsigned
	NodeIndex = ReadBEShort f + 1
	if NodeIndex != 65536 do(
	append ProperBone_array t
	)
	ParentBoneID = ReadBEShort f + 1
	BoneChildID = ReadBEShort f + 1
	Sibling = ReadBEShort f + 1
	PosX = ReadBEFloat f
	PosY = ReadBEFloat f
	PosZ = ReadBEFloat f
	RotX = ReadBEBAMS f
	RotY = ReadBEBAMS f
	RotZ = ReadBEBAMS f
	ScaleX = ReadBEFloat f
	ScaleY = ReadBEFloat f
	ScaleZ = ReadBEFloat f
	
	m11 = ReadBEFloat f; m21 = ReadBEFloat f; m31 = ReadBEFloat f; m41 = ReadBEFloat f
	m12 = ReadBEFloat f; m22 = ReadBEFloat f; m32 = ReadBEFloat f; m42 = ReadBEFloat f
	m13 = ReadBEFloat f; m23 = ReadBEFloat f; m33 = ReadBEFloat f; m43 = ReadBEFloat f
	m14 = ReadBEFloat f; m24 = ReadBEFloat f; m34 = ReadBEFloat f; m44 = ReadBEFloat f
	tfm = matrix3 [m11,m12,m13,m14] [m21,m22,m23,m24] [m31,m32,m33,m34] [m41,m42,m43,m44]
-- if (getNodeByName BoneName) != undefined do (
-- append BoneArray (getNodeByName BoneName)
-- )
-- if (getNodeByName BoneName) == undefined do (
-- if (BoneParent != -1) do (
-- tfm = tfm * BoneArray[(ParentBoneID + 1)].objecttransform
-- )
-- )
	fseek f 0x20#seek_cur


	newBone = bonesys.createbone \
				  tfm.row4	\
				  (tfm.row4 + 1 * (normalize tfm.row1)) \
				  (normalize tfm.row3)
			
			newBone.width = 0.01
			newBone.height = 0.01
			newBone.transform = tfm
			newBone.wirecolor = yellow
			newbone.showlinks = true
			
			pos = [m14,m24,m34]
			pos = pos * tfm
			
			
			newBone.pos.x += ((-1)*pos.x)
			newBone.pos.y += ((-1)*pos.y)
			newBone.pos.z += ((-1)*pos.z)
			
			newBone.setBoneEnable false 0
			newBone.pos.controller      = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
			
			If ParentBoneID != 0xFFFF Do (
				newBone.parent = BoneArray[ParentBoneID]
			)
			
			append BoneArray newBone
)
Print ("Bones end = 0x"+((bit.intAsHex(ftell f))as string))	

-- Mesh Importing Functions --
fseek f LinkOffset#seek_set
Print ("Link start = 0x"+(bit.intAsHex(ftell f)as string))
For b = 1 to LinkTotal Do (
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
	fseek f 4#seek_cur
	LinkBlockTotal = ReadBELong f
	LinkBlockOffset = ReadBELong f + 0x20
	fseek f 8#seek_cur
	NL = ftell f
	Print ("Link end = 0x"+(bit.intAsHex(ftell f)as string))
	fseek f LinkBlockOffset#seek_set
	
	For l = 1 to LinkBlockTotal Do (
		Vert_Array=#()
		UV_Array=#()
		Face_Array=#()
		Face_Total=#()
		W1_array = #()
		B1_array = #()
		Weight_array = #()

		Print ("Link Block start = 0x"+(bit.intAsHex(ftell f)as string))
		fseek f 0x10#seek_cur
		VisibilityBone = ReadBELong f + 1
		SingleBindBone = ReadBELong f + 1
		SomethingElse = ReadBELong f + 1
		VertID = ReadBELong f + 1
		PolyID = ReadBELong f + 1
		fseek f 4#seek_cur
		NextLink = ftell f
		Print ("Link Block end = 0x"+(bit.intAsHex(ftell f)as string))
		fseek f VertGroupArray[VertID].VOffset#seek_set
		Print ("Vertex Group start = 0x"+(bit.intAsHex(ftell f)as string))
		fseek f 8#seek_cur
		VertType = ReadBELong f
		VertexTotal = ReadBELong f
		VertexBuffer = ReadBELong f + 0x20
		NodeSize = ReadBELong f
		NodeBuffer = ReadBELong f + 0x20
		Print ("Vertex Group end = 0x"+(bit.intAsHex(ftell f)as string))
		
		fseek f NodeBuffer #seek_set
		Print ("Node buffer start: 0x"+((bit.intAsHex(ftell f))as string))
			
		NodeList_array = #()
		for n = 1 to NodeSize do(
		Node = ReadBELong f + 1
		append NodeList_array Node
		)
		If NodeBuffer == 0x20 do(
		append NodeList_array SingleBindBone
		)
		print NodeList_array
		Print ("Node buffer end: 0x"+((bit.intAsHex(ftell f))as string))

		fseek f VertexBuffer#seek_set
		Print ("Vertex Type = 0x" +  ((bit.intAsHex(VertType))as string) + ", Vertex data at: 0x"+((bit.intAsHex(ftell f))as string))

		if VertType == 0x0C Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				weight1 = 1
				weight2 = 0
				weight3 = 0
				weight4 = 0
				bone4 = 4
				bone3 = 3
				bone2 = 2
				bone1 = NodeList_array[1]
				bone1 = ProperBone_Array[Bone1]
				append Vert_array[vx,vy,vz]
				append UV_array[0,0,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)	

		if VertType == 0x10 Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				weight1 = 1
				weight2 = 0
				weight3 = 0
				weight4 = 0
				bone4 = 4
				bone3 = 3
				bone2 = 2
				bone1 = NodeList_array[1]
				bone1 = ProperBone_Array[Bone1]
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)

		if VertType == 0x14 Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				fseek f 0x4#seek_cur
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				weight1 = 1
				weight2 = 0
				weight3 = 0
				weight4 = 0
				bone4 = 4
				bone3 = 3
				bone2 = 2
				bone1 = NodeList_array[1]
				bone1 = ProperBone_Array[Bone1]
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)
		
		if VertType == 0x1C Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				fseek f 0x4#seek_cur
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				fseek f 0x8#seek_cur
				weight1 = 1
				weight2 = 0
				weight3 = 0
				weight4 = 0
				bone4 = 4
				bone3 = 3
				bone2 = 2
				bone1 = NodeList_array[1]
				bone1 = ProperBone_Array[Bone1]
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)
		
		if VertType == 0x20 Do (
		for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				weight1 = ReadBEFloat f
				weight2 = ReadBEFloat f
				weight3 = ReadBEFloat f
				weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				bone1 = NodeList_array[1]
				bone1 = ProperBone_Array[bone1]
				if NodeList_Array.count > 1 do(
					bone2 = NodeList_Array[2]
					bone2 = ProperBone_Array[bone2]
					if NodeList_Array.count > 2 do(
						bone3 = NodeList_Array[3]
						bone3 = ProperBone_Array[bone3]
						if NodeList_Array.count > 3 do(
							bone4 = NodeList_Array[4]
							bone4 = ProperBone_Array[bone4]
							if bone4 < bone3 do(weight4 = 0)
						)
					)
				)
				fseek f 0x04#seek_cur
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)
		
		if VertType == 0x24 Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				weight1 = ReadBEFloat f
				weight2 = ReadBEFloat f
				weight3 = ReadBEFloat f
				weight4 = 0
				bone4 = (readbyte f #unsigned) + 1
				bone4 = NodeList_array[bone4]
				bone4 = ProperBone_Array[bone4]
				bone3 = (readbyte f #unsigned) + 1
				bone3 = NodeList_array[bone3]
				bone3 = ProperBone_Array[bone3]
				bone2 = (readbyte f #unsigned) + 1
				bone2 = NodeList_array[Bone2]
				bone2 = ProperBone_Array[bone2]
				bone1 = (readbyte f #unsigned) + 1
				bone1 = NodeList_array[bone1]
				bone1 = ProperBone_Array[bone1]
				fseek f 0x04#seek_cur
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)

		if VertType == 0x28 Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				weight1 = ReadBEFloat f
				weight2 = ReadBEFloat f
				weight3 = ReadBEFloat f
				weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				bone1 = NodeList_array[1]
				bone1 = ProperBone_Array[bone1]
				if NodeList_Array.count > 1 do(
					bone2 = NodeList_Array[2]
					bone2 = ProperBone_Array[bone2]
					if NodeList_Array.count > 2 do(
						bone3 = NodeList_Array[3]
						bone3 = ProperBone_Array[bone3]
						if NodeList_Array.count > 3 do(
							bone4 = NodeList_Array[4]
							bone4 = ProperBone_Array[bone4]
							if bone4 < bone3 do(weight4 = 0)
						)
					)
				)
				fseek f 0x04#seek_cur
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				fseek f 0x08#seek_cur
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)

		if VertType == 0x2C Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				weight1 = ReadBEFloat f
				weight2 = ReadBEFloat f
				weight3 = ReadBEFloat f
				weight4 = 0
				if NodeList_array.count > 4 then (
				bone4 = (readbyte f #unsigned) + 1
				bone4 = NodeList_array[bone4]
				bone4 = ProperBone_Array[bone4]
				bone3 = (readbyte f #unsigned) + 1
				bone3 = NodeList_array[bone3]
				bone3 = ProperBone_Array[bone3]
				bone2 = (readbyte f #unsigned) + 1
				bone2 = NodeList_array[bone2]
				bone2 = ProperBone_Array[bone2]
				bone1 = (readbyte f #unsigned) + 1
				bone1 = NodeList_array[bone1]
				bone1 = ProperBone_Array[bone1]
				) else (
				if NodeList_array.count > 3 then (
				bone4 = NodeList_array[4]
				bone4 = ProperBone_Array[4]
				) else (
				bone4 = 1
				)
				if NodeList_array.count > 2 then (
				bone3 = NodeList_array[3]
				bone3 = ProperBone_Array[3]
				) else (
				bone3 = 1
				)
				if NodeList_array.count > 1 then (
				bone2 = NodeList_array[2]
				bone2 = ProperBone_Array[2]
				) else (
				bone2 = 1
				)
				bone1 = NodeList_array[1]
				bone1 = ProperBone_Array[1]
				)
				fseek f 0x04#seek_cur
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				fseek f 0x8#seek_cur
				if NodeList_array.count < 5 do(
				fseek f 0x4#seek_cur
				)
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)

		if VertType == 0x30 Do (
			for v = 1 to VertexTotal Do (
				vx = ReadBEFloat f
				vy = ReadBEFloat f
				vz = ReadBEFloat f
				weight1 = ReadBEFloat f
				weight2 = ReadBEFloat f
				weight3 = ReadBEFloat f
				weight4 = 0
				bone4 = (readbyte f #unsigned) + 1
				bone4 = NodeList_array[bone4]
				bone4 = ProperBone_Array[bone4]
				bone3 = (readbyte f #unsigned) + 1
				bone3 = NodeList_array[bone3]
				bone3 = ProperBone_Array[bone3]
				bone2 = (readbyte f #unsigned) + 1
				bone2 = NodeList_array[bone2]
				bone2 = ProperBone_Array[bone2]
				bone1 = (readbyte f #unsigned) + 1
				bone1 = NodeList_array[bone1]
				bone1 = ProperBone_Array[bone1]
				fseek f 0x04#seek_cur
				tu = ReadBEHalfFloat f
				tv = (-ReadBEHalfFloat f) + 1
				fseek f 0xC#seek_cur
				append Vert_array[vx,vy,vz]
				append UV_array[tu,tv,0]
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
			)
		)

		Print ("Vertex end = 0x"+((bit.intAsHex(ftell f))as string))		
		fseek f PolyGroupArray[PolyID].POffset#seek_set
		Print ("FaceTotalTable start = 0x"+((bit.intAsHex(ftell f))as string))	
		fseek f 0x4#seek_cur
		FullFaceTotal = ReadBELong f
		FaceTotalList = ReadBELong f
		FaceTotalTableOff = ReadBELong f + 0x20
		PolyBufferOffset = ReadBELong f +0x20

		Print ("FaceTotalTable end = 0x"+(bit.intAsHex(ftell f)as string))			
		fseek f FaceTotalTableOff#seek_set
		Print ("FaceTotalTableOff start = 0x"+(bit.intAsHex(ftell f)as string))
		For ft = 1 to FaceTotalList Do (
			FaceTotal = ReadBEShort f
			append Face_Total (Ftotal FaceTotal:FaceTotal)
			print ("Face point total = " + FaceTotal as string)
		)
		Print ("FaceTotalTableOff end = 0x"+(bit.intAsHex(ftell f)as string))
	
		fseek f PolyBufferOffset#seek_set
		Print ("Polygon start = 0x"+((bit.intAsHex(ftell f))as string))
		For pb = 1 to Face_Total.count Do (
		StartDirection = -1
		f1 = ReadBEShort f + 1
		f2 = ReadBEShort f + 1
		FaceDirection = StartDirection
		IndexCounter = 2
		Do (
			f3 = ReadBEShort f
			IndexCounter += 1
			if (f3==0xFFFF) then (
				f1 = (ReadShort f) + 1
				f2 = (ReadShort f) + 1
				FaceDirection = StartDirection
				IndexCounter += 2
			) else (
				f3 += 1
				FaceDirection *= -1
				if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
					if FaceDirection > 0 then append face_Array [f1,f2,f3]
					else append face_Array [f1,f3,f2]
				)
				f1 = f2
				f2 = f3
			)
		)
		while IndexCounter != Face_Total[pb].FaceTotal
	)
		Print ("Polygon end = 0x"+(bit.intAsHex(ftell f)as string))
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
	
		msh = mesh vertices:Vert_array faces:Face_array
		msh.numTVerts = UV_array.count
		buildTVFaces msh
		for j = 1 to UV_array.count do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
		msh.name = ((bit.intAsHex(VertType))as string)
		max modify mode
		select msh
		
		skinMod = skin ()
		addModifier msh skinMod
		BoneCount = BoneArray.count
		for i = 1 to BoneCount do
		(
		maxbone = getnodebyname BoneArray[i].name
		if i != BoneCount then
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
   
		)

		modPanel.setCurrentObject skinMod

		for i = 1 to Weight_array.count do (
		w = Weight_array[i]
		bi = #() --bone index array
		wv = #() --weight value array
   
		for j = 1 to w.boneids.count do
		(
			boneid = w.boneids[j]
			weight = w.weights[j]
			append bi boneid
			append wv weight
		)   
   
		skinOps.ReplaceVertexWeights skinMod i bi wv
   
		)
	
		fseek f NextLink#seek_set
	)
		
		
		
	fseek f NL#seek_set
)
	
Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
fclose f
)
)

	on btnGNO pressed do(
clearlistener()
fname = GetOpenFileName caption:"Open GNO model" types:"GNO Model File(*.gno)|*.gno"
if fname != undefined do(
f = fopen fname "rb"   --open file in read only format
fext= getFilenameType fname
fpath= getFilenamePath fname
filename = getFilenameFile fname

struct VertGroup(
	VOffset
)
struct PolyGroup(
	POffset
)
struct BoneInfo(
	BoneName
)
struct Bone_Info_Struct
(
	Bone1, Bone2, Bone3, Bone4, Bone5, Bone6, Bone7, Bone8
)
struct Weight_Info_Struct
(
	Weight1, Weight2, Weight3, Weight4, Weight5, Weight6, Weight7, Weight8
)
struct weight_data
(
   boneids, weights
)
VertGroupArray=#()
PolyGroupArray=#()
BoneArray=#()
BoneInfoArray=#()
TextureNames = #()
error = #()

-- NGIF --
NGIF = ReadFixedString f 4
NGIFSize = ReadLong f 
StructFlag = ReadBELong f
fseek f 0x14#seek_cur

If StructFlag == 1 Do (
	-- NGNN --
	NGNN = ReadFixedString f 4
	NGNNSize = ReadLong f
	fseek f NGNNSize#seek_cur
)

If StructFlag == 2 Do (
	-- NGTL --
	NGTL = ReadFixedString f 4
	NGTLSize = ReadLong f + 0x28
	TextureOffset = ReadBELong f + 0x20
	fseek f TextureOffset#seek_set
	
	TextureTotal = ReadBELong f
	fseek f 4#seek_cur
	For t = 1 to TextureTotal Do (
		TexName = killext (ReadString f)
		Print TexName
		append TextureNames (TexName)
	)
	fseek f NGTLSize#seek_set
)

If StructFlag == 3 Do (
	-- NGTL --
	NGTL = ReadFixedString f 4
	NGTLSize = ReadLong f
	fseek f NGTLSize#seek_cur
	
	-- NGNN --
	NGNN = ReadFixedString f 4
	NGNNSize = ReadLong f
	fseek f NGNNSize#seek_cur
)

-- NGOB --
NGOB = ReadFixedString f 4
NGOBSize = ReadLong f
GInfoOff = ReadBELong f + 0x30

fseek f GInfoOff#seek_set
Print ("GInfoOff Start = 0x"+(bit.intAsHex(ftell f)as string))

TexElmTotal = ReadBELong f
TexElmOff = ReadBELong f + 0x20
VertGroupTotal = ReadBELong f
VertGroupOff = ReadBELong f + 0x20
PolyGroupTotal = ReadBELong f
PolyGroupOff = ReadBELong f + 0x20
BoneTotal = ReadBELong f
fseek f 4#seek_cur
BoneOffset = ReadBELong f + 0x20
NodeTotal = ReadBELong f
LinkTotal = ReadBELong f
LinkOffset = ReadBELong f + 0x20

-- Building Vert Groups --
fseek f VertGroupOff#seek_set
For vg = 1 to VertGroupTotal Do (
	fseek f 4#seek_cur
	VertInfoOffset = ReadBELong f + 0x20
	append VertGroupArray (VertGroup VOffset:VertInfoOffset)
)

-- Building Poly Groups --
fseek f PolyGroupOff#seek_set
For pg = 1 to PolyGroupTotal Do (
	fseek f 4#seek_cur
	PolyInfoOffset = ReadBELong f + 0x20
	append PolyGroupArray (PolyGroup POffset:PolyInfoOffset)
)

-- Bone Importing --

-- GNA Functions for Bone Names --
-- if (doesFileExist (fpath+filename+".gna"))==true do(
-- g = fopen (fpath+filename+".gna") "rb"

-- fseek g 0x28#seek_set
-- NameTotalOff = ReadBELong g + 0x24
-- fseek g NameTotalOff#seek_set
-- NameTotal = ReadBELong g
-- BlockOffset = ReadBELong g + 0x20
-- fseek g BlockOffset#seek_set


-- For n = 1 to NameTotal Do (
-- 	BoneID = ReadBELong g + 1
-- 	BoneNameOffset = ReadBELong g + 0x20
-- 	Next = ftell g
-- 	fseek g BoneNameOffset#seek_set
-- 	BoneName = ReadString g 
-- 	fseek g Next#seek_set
-- 	append BoneInfoArray (BoneName)
-- )

-- For bn = 1 to BoneInfoArray.count Do (
-- 	Print BoneInfoArray[bn]
-- )
-- )
fseek f BoneOffset#seek_set
Print ("Bones Start = 0x"+(bit.intAsHex(ftell f)as string))
ProperBone_array = #()
For t = 1 to BoneTotal Do (
	Header1 = ReadByte f #unsigned
	Header2 = ReadByte f #unsigned
	Header3 = ReadByte f #unsigned
	Header4 = ReadByte f #unsigned
	print ("Bone #" + t as string + " Header values = "+ Header1 as string + ", " + Header2 as string + ", " + Header3 as string + ", " + Header4 as string)
	NodeIndex = ReadBEShort f + 1
	If NodeIndex != 65536 do (
	append ProperBone_array t
	)
	ParentBoneID = ReadBEShort f + 1
	BoneChildID = ReadBEShort f + 1
	Sibling = ReadBEShort f + 1
	PosX = ReadBEFloat f
	PosY = ReadBEFloat f
	PosZ = ReadBEFloat f
	RotX = ReadBEBAMS f
	RotY = ReadBEBAMS f
	RotZ = ReadBEBAMS f
	ScaleX = ReadBEFloat f
	ScaleY = ReadBEFloat f
	ScaleZ = ReadBEFloat f
	
	m11 = ReadBEFloat f; m21 = ReadBEFloat f; m31 = ReadBEFloat f; m41 = ReadBEFloat f
	m12 = ReadBEFloat f; m22 = ReadBEFloat f; m32 = ReadBEFloat f; m42 = ReadBEFloat f
	m13 = ReadBEFloat f; m23 = ReadBEFloat f; m33 = ReadBEFloat f; m43 = ReadBEFloat f
	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [0,0,0,1]
	fseek f 0x20#seek_cur


	newBone = bonesys.createbone \
				  tfm.row4	\
				  (tfm.row4 + 1 * (normalize tfm.row1)) \
				  (normalize tfm.row3)
				
--			newBone.name = BoneInfoArray[t] as string
			
			newBone.width = 0.01
			newBone.height = 0.01
			newBone.transform = tfm
			newBone.wirecolor = yellow
			newbone.showlinks = true
			
			pos = [m41,m42,m43]
			pos = pos * tfm

			newBone.pos.x += ((-1)*pos.x)
			newBone.pos.y += ((-1)*pos.y)
			newBone.pos.z += ((-1)*pos.z)

			newBone.setBoneEnable false 0
			newBone.pos.controller      = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()

			If ParentBoneID != 0xFFFF Do (
				newBone.parent = BoneArray[ParentBoneID]
			)

			append BoneArray newBone
)
-- Print "Bones DONE"
Print ("Bones end = 0x"+(bit.intAsHex(ftell f)as string))

-- Mesh Importing --
fseek f LinkOffset#seek_set
Print ("Link Start = 0x"+(bit.intAsHex(ftell f)as string))

For b = 1 to LinkTotal Do (
	fseek f 4#seek_cur
	LinkBlockTotal = ReadBELong f
	LinkBlockOffset = ReadBELong f + 0x20
	fseek f 8#seek_cur
	NL = ftell f
	fseek f LinkBlockOffset#seek_set

	For l = 1 to LinkBlockTotal Do (
	Print ("Link Block Start = 0x"+(bit.intAsHex(ftell f)as string))
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	UVIndex=#()
	UVIndex2=#()
	W1_array = #()
	B1_array = #()
	Weight_array = #()
	fseek f 0x10 #seek_cur
	VisibilityBone = ReadBELong f + 1
	SingleBindBone = ReadBELong f + 1
	SomethingElse = ReadBELong f + 1
	VertID = ReadBELong f + 1
	PolyID = ReadBELong f + 1
	NextLink = ftell f
	fseek f VertGroupArray[VertID].VOffset#seek_set
	Print ("Vert Group Array Start = 0x"+(bit.intAsHex(ftell f)as string))
	VertFlag = ReadBEShort f
	VertTotal = ReadBEShort f
	VertOffset = ReadBELong f + 0x20
	fseek f 16#seek_cur
	UVFlag = ReadBEShort f
	UVTotal = ReadBEShort f
	UVOffset = ReadBELong f + 0x20
	fseek f 8#seek_cur
	NodeFlag = ReadBEShort f
	NodeTotal = ReadBEShort f
	NodeOffset = ReadBELong f + 0x20
	Print ("Vert Flag = "+((VertFlag)as string))
	Print ("Vert Total = "+((VertTotal)as string))
	Print ("UV Flag = "+((UVFlag)as string))
	Print ("UV Total = "+((UVTotal)as string))
	Print ("Node Flag = "+((NodeFlag)as string))
	Print ("Node Total = "+((NodeTotal)as string))
	Print ("Node Offset = 0x"+(bit.intAsHex(NodeOffset)as string))

	fseek f VertOffset#seek_set
	Print ("Vert Start = 0x"+(bit.intAsHex(ftell f)as string))
	If VertFlag == 1 Do (
		For v = 1 to VertTotal Do (
			vx = ReadBEFloat f
			vy = ReadBEFloat f
			vz = ReadBEFloat f
			append Vert_Array[vx,vy,vz]
		)
	)
	If VertFlag == 6 Do (
		For v = 1 to VertTotal Do (
			vx = ((ReadBEShort f as float) /256)
			If vx > 255 Do (
				vx = vx - 256
			)
			vy = ((ReadBEShort f as float) /256)
			If vy > 255 Do (
				vy = vy - 256
			)
			vz = ((ReadBEShort f as float) /256)
			If vz > 255 Do (
				vz = vz - 256
			)
			append Vert_Array[vx,vy,vz]
		)
	)
	If VertFlag == 7 Do (
		For v = 1 to VertTotal Do (
			vx = ((ReadBEShort f as float) /1024)
			If vx > 63 Do (
				vx = vx - 64
			)
			vy = ((ReadBEShort f as float) /1024)
			If vy > 63 Do (
				vy = vy - 64
			)
			vz = ((ReadBEShort f as float) /1024)
			If vz > 63 Do (
				vz = vz - 64
			)
			append Vert_Array[vx,vy,vz]
		)
	)
	Print ("Vert End = 0x"+(bit.intAsHex(ftell f)as string))
		
	fseek f UVOffset#seek_set
	Print ("UV Start = 0x"+(bit.intAsHex(ftell f)as string))
	If UVFlag == 0 Do (
		For u = 1 to VertTotal Do (
		append UV_Array[0,0,0]
		)
	)
	If UVFlag == 2 Do (
		For u = 1 to UVTotal Do (
			tu = (ReadBEShortS f as float) /256
			tv = ((ReadBEShortS f as float)*-1) /256
			If tu > 127 Do (
				tu = tu - 256
			)
			If tv > 127 Do (
				tv = tv - 256
			)
			If tu < -127 Do (
				tu = tu + 256
			)
			If tv < -127 Do (
				tv = tv + 256
			)
			tv = tv + 1
			append UV_Array[tu,tv,0]
		)
	)
	If UVFlag == 3 Do (
		For u = 1 to UVTotal Do (
			tu = (ReadBEShortS f as float) /1024
			If tu > 63 Do (
				tu = tu - 64
			)
			If tu < -1 Do (
				tu = tu + 64
			)
			tv = ((ReadBEShortS f as float)*-1) /1024
			If tv > 63 Do (
				tv = tv - 64
			)
			If tv < -1 Do (
				tv = tv + 1024
			)
			tv = tv + 1
			append UV_Array[tu,tv,0]
		)
	)
	Print ("UV End = 0x"+(bit.intAsHex(ftell f)as string))

		fseek f PolyGroupArray[PolyID].POffset#seek_set
		Print ("Poly Group Start = 0x"+(bit.intAsHex(ftell f)as string))
		Header1 = ReadByte f #unsigned
		Header2 = ReadByte f #unsigned
		Header3 = ReadByte f #unsigned
		Header4 = ReadByte f #unsigned
		PolyOffset = ReadBELong f + 0x20
		PolySize = ReadBELong f
		ColorOffset = ReadBELong f + 0x20
		fseek f PolyOffset#seek_set
		Print ("Poly Offset Start = 0x"+(bit.intAsHex(ftell f)as string))
			
		fseek f 0x14#seek_cur
		PolyFlag = ReadByte f #unsigned
		ByteTotal = 21
		Print ("Poly Flag = " + (PolyFlag as string))
		Print ("Poly Size = " + (PolySize as string))
		Print ("Poly Start = 0x"+(bit.intAsHex(ftell f)as string))

Do ( 
	PolyType = ReadByte f#unsigned
	If PolyType == 0x99 Do (
		FaceTotal = ReadBEShort f
		ByteTotal += 3
		
		If PolyFlag == 0 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal +=4
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				ByteTotal += 2
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					f2 = (ReadBEShort f) + 1
					FaceDirection = StartDirection
					ByteTotal += 4
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then append face_Array [f1,f2,f3]
						else append face_Array [f1,f3,f2]
					)
					f1 = f2
					f2 = f3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 1 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 8
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				u3 = ReadBEShort f + 1
				ByteTotal += 4
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					u1 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					u2 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 8
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 4 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			fseek f 0x02 #seek_cur
			f2 = ReadBEShort f + 1
			fseek f 0x02 #seek_cur
			FaceDirection = StartDirection
			ByteTotal += 8
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				fseek f 0x02 #seek_cur
				ByteTotal += 6
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					fseek f 0x02 #seek_cur
					f2 = (ReadBEShort f) + 1
					fseek f 0x02 #seek_cur
					FaceDirection = StartDirection
					ByteTotal += 4
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							u1 = 1
							u2 = 1
							u3 = 1
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						u1 = 1
						u2 = 1
						u3 = 1
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					f2 = f3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 10 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 8
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				u3 = ReadBEShort f + 1
				ByteTotal += 4
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					u1 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					u2 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 8
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 14 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 8
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				u3 = ReadBEShort f + 1
				ByteTotal += 4
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					u1 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					u2 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 8
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 16 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 10
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				u3 = ReadBEShort f + 1
				ByteTotal += 6
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					u2 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					u3 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 8
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 17 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			fseek f 2#seek_cur
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			fseek f 2#seek_cur
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 10
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				fseek f 2#seek_cur
				u3 = ReadBEShort f + 1
				ByteTotal += 6
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					fseek f 2#seek_cur
					u2 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					fseek f 2#seek_cur
					u3 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 10
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 20 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			fseek f 2#seek_cur
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			fseek f 2#seek_cur
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 10
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				fseek f 2#seek_cur
				u3 = ReadBEShort f + 1
				ByteTotal += 6
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					fseek f 2#seek_cur
					u2 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					fseek f 2#seek_cur
					u3 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 10
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 21 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			fseek f 4#seek_cur
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			fseek f 4#seek_cur
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 10
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				fseek f 4#seek_cur
				u3 = ReadBEShort f + 1
				ByteTotal += 6
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					fseek f 4#seek_cur
					u2 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					fseek f 4#seek_cur
					u3 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 10
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 24 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			fseek f 2#seek_cur
			u1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			fseek f 2#seek_cur
			u2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 10
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				fseek f 2#seek_cur
				u3 = ReadBEShort f + 1
				ByteTotal += 6
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					fseek f 2#seek_cur
					u1 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					fseek f 2#seek_cur
					u2 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 10
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
					)
					)
					f1 = f2
					u1 = u2
					f2 = f3
					u2 = u3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 33 Do (
		Print ("Poly Flag 33, needs filled in!")
		error = "yes"
		)
		If PolyFlag == 36 Do (
			StartDirection = 1
			f1 = ReadBEShort f + 1
			n1 = ReadBEShort f + 1
			u1 = ReadBEShort f + 1
			v1 = ReadBEShort f + 1
			f2 = ReadBEShort f + 1
			n2 = ReadBEShort f + 1
			u2 = ReadBEShort f + 1
			v2 = ReadBEShort f + 1
			FaceDirection = StartDirection
			ByteTotal += 16
			IndexCounter = 2
			Do (
				f3 = ReadBEShort f
				n3 = ReadBEShort f + 1
				u3 = ReadBEShort f + 1
				v3 = ReadBEShort f + 1
				ByteTotal += 8
				IndexCounter += 1
				if (f3==0xFFFF) then (
					f1 = (ReadBEShort f) + 1
					n1 = ReadBEShort f + 1
					u2 = ReadBEShort f + 1
					v2 = ReadBEShort f + 1
					f2 = (ReadBEShort f) + 1
					n2 = ReadBEShort f + 1
					u3 = ReadBEShort f + 1
					v3 = ReadBEShort f + 1
					FaceDirection = StartDirection
					ByteTotal += 10
					IndexCounter += 2
				) else (
					f3 += 1
					FaceDirection *= -1
					if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
						if FaceDirection > 0 then ( append face_Array [f1,f2,f3] 
							append UVIndex [u1,u2,u3]
							append UVIndex2 [v1,v2,v3]
						)else( append face_Array [f1,f3,f2]
						append UVIndex [u1,u3,u2]
						append UVIndex2 [v1,v3,v2]
					)
					)
					f1 = f2
					u1 = u2
					v1 = v2
					f2 = f3
					u2 = u3
					v2 = v3
				)
			)
			while IndexCounter != FaceTotal
		)
		If PolyFlag == 37 Do (
		Print ("Poly Flag 37, needs filled in!")
		error = "yes"
		)
	)
	If PolyType == 0x00 Do (
		ByteTotal = PolySize
	)
) while ByteTotal != PolySize

	Print ("Poly End = 0x"+((bit.intAsHex(ftell f))as string))

	fseek f NodeOffset#seek_set
	Print ("Node Start = 0x"+(bit.intAsHex(ftell f)as string))
	If NodeFlag == 0 Do (
		For u = 1 to VertTotal Do (
		Bone1 = SingleBindBone
		Bone1 = ProperBone_Array[Bone1]
		Bone2 = 1
		Bone3 = 1
		Bone4 = 1
		Bone5 = 1
		Bone6 = 1
		Bone7 = 1
		Bone8 = 1
		Weight1 = 1
		Weight2 = 0
		Weight3 = 0
		Weight4 = 0
		Weight5 = 0
		Weight6 = 0
		Weight7 = 0
		Weight8 = 0
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone7:Bone7 Bone8:Bone8)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
		)
	)
	If NodeFlag == 1 Do (
		For u = 1 to NodeTotal Do (
		Bone1 = ReadByte f #unsigned + 1
		Bone1 = ProperBone_Array[Bone1]
		Bone2 = ReadByte f #unsigned + 1
		Bone2 = ProperBone_Array[Bone2]
		Bone3 = 1
		Bone4 = 1
		Bone5 = 1
		Bone6 = 1
		Bone7 = 1
		Bone8 = 1
		Weight1 = (ReadBEshort f as float / 16384)
		Weight2 = (1 as float - Weight1)
		Weight3 = 0
		Weight4 = 0
		Weight5 = 0
		Weight6 = 0
		Weight7 = 0
		Weight8 = 0
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone7:Bone7 Bone8:Bone8)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
		)
	)
	If NodeFlag == 8 Do (
	NodeTotal2 = NodeTotal
		Do (
		NodeTotal2 = NodeTotal2 - 1
		Bone1 = ReadBEshort f + 1
		Bone1 = ProperBone_Array[Bone1]
		Weight1 = (ReadBEshort f as float) / 16384
		Bone2 = 1
		Weight2 = 0
		Bone3 = 1
		Weight3 = 0
		Bone4 = 1
		Weight4 = 0
		Bone5 = 1
		Weight5 = 0
		Bone6 = 1
		Weight6 = 0
		Bone7 = 1
		Weight7 = 0
		Bone8 = 1
		Weight8 = 0
		if Weight1 < 0.999 do(
		NodeTotal2 = NodeTotal2 - 1
		Bone2 = ReadBEshort f + 1
		Bone2 = ProperBone_Array[Bone2]
		Weight2 = (ReadBEshort f as float) / 16384
			if (Weight1 + Weight2) < 0.999 do(
			NodeTotal2 = NodeTotal2 - 1
			Bone3 = ReadBEshort f + 1
			Bone3 = ProperBone_Array[Bone3]
			Weight3 = (ReadBEshort f as float) / 16384
			)
				if (Weight1 + Weight2 + Weight3) < 0.999 do(
				NodeTotal2 = NodeTotal2 - 1
				Bone4 = ReadBEshort f + 1
				Bone4 = ProperBone_Array[Bone4]
				Weight4 = (ReadBEshort f as float) / 16384
					if (Weight1 + Weight2 + Weight3 + Weight4) < 0.999 do(
					NodeTotal2 = NodeTotal2 - 1
					Bone5 = ReadBEshort f + 1
					Bone5 = ProperBone_Array[Bone5]
					Weight5 = (ReadBEshort f as float) / 16384
					)
						if (Weight1 + Weight2 + Weight3 + Weight4 + Weight5) < 0.999 do(
						NodeTotal2 = NodeTotal2 - 1
						Bone6 = ReadBEshort f + 1
						Bone6 = ProperBone_Array[Bone6]
						Weight6 = (ReadBEshort f as float) / 16384
							if (Weight1 + Weight2 + Weight3 + Weight4 + Weight5 + Weight6) < 0.999 do(
							NodeTotal2 = NodeTotal2 - 1
							Bone7 = ReadBEshort f + 1
							Bone7 = ProperBone_Array[Bone7]
							Weight7 = (ReadBEshort f as float) / 16384
									if (Weight1 + Weight2 + Weight3 + Weight4 + Weight5 + Weight6 + Weight7) < 0.999 do(
									NodeTotal2 = NodeTotal2 - 1
									Bone8 = ReadBEshort f + 1
									Bone8 = ProperBone_Array[Bone8]
									Weight8 = (ReadBEshort f as float) / 16384
									)
							)
					)
				)
		)
		append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone6:Bone6 Bone6:Bone6)
		append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
		) While NodeTotal2 != 0
	)
	Print ("Node End = 0x"+(bit.intAsHex(ftell f)as string))


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
if(W1_array[b].Weight5 != 0) then
   maxweight = maxweight + W1_array[b].Weight5
if(W1_array[b].Weight6 != 0) then
   maxweight = maxweight + W1_array[b].Weight6
if(W1_array[b].Weight7 != 0) then
   maxweight = maxweight + W1_array[b].Weight7
if(W1_array[b].Weight8 != 0) then
   maxweight = maxweight + W1_array[b].Weight8

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
      if(W1_array[b].Weight5 != 0) then
      (
         w5 = W1_array[b].Weight5 as float
         append w.boneids (B1_array[b].Bone5)
         append w.weights (w5)
      )      
      if(W1_array[b].Weight6 != 0) then
      (
         w6 = W1_array[b].Weight6 as float
         append w.boneids (B1_array[b].Bone6)
         append w.weights (w6)
      )      
      if(W1_array[b].Weight7 != 0) then
      (
         w7 = W1_array[b].Weight7 as float
         append w.boneids (B1_array[b].Bone7)
         append w.weights (w7)
      )      
      if(W1_array[b].Weight8 != 0) then
      (
         w8 = W1_array[b].Weight8 as float
         append w.boneids (B1_array[b].Bone8)
         append w.weights (w8)
      )      
   )
append Weight_array w
)

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = UV_Array.count
	buildTVFaces msh
	for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
	for j = 1 to UVIndex.count do setTVFace msh j UVIndex[j]
	msh.name = "V" + VertFlag as string + " U" + UVFlag as string + " P" + PolyFlag as string + " N" + NodeFlag as string
max modify mode
select msh

      --set smoothing group of all faces to 1 to get one normal per vertex
      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1

if BoneTotal != 0 do(
skinMod = skin ()
addModifier msh skinMod
for i = 1 to BoneTotal do
(
   maxbone = getnodebyname BoneArray[i].name
   if i != BoneTotal then
      skinOps.addBone skinMod maxbone 0
   else
      skinOps.addBone skinMod maxbone 1
   
)

modPanel.setCurrentObject skinMod

for i = 1 to Vert_array.count do (
   w = Weight_array[i]
   bi = #() --bone index array
   wv = #() --weight value array
   
   for j = 1 to w.boneids.count do
   (
      boneid = w.boneids[j]
      weight = w.weights[j]
      append bi boneid
      append wv weight
   )   
   
   skinOps.ReplaceVertexWeights skinMod i bi wv
   
	)
)

if UVIndex2.count > 0 do(
	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = UV_Array.count
	buildTVFaces msh
	for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
	for j = 1 to UVIndex2.count do setTVFace msh j UVIndex2[j]
	msh.name = "V" + VertFlag as string + " U" + UVFlag as string + " P" + PolyFlag as string + " N" + NodeFlag as string + " Layer 2"
max modify mode
select msh

if BoneTotal != 0 do(
skinMod = skin ()
addModifier msh skinMod
for i = 1 to BoneTotal do
(
   maxbone = getnodebyname BoneArray[i].name
   if i != BoneTotal then
      skinOps.addBone skinMod maxbone 0
   else
      skinOps.addBone skinMod maxbone 1
   
)

modPanel.setCurrentObject skinMod

for i = 1 to Weight_array.count do (
   w = Weight_array[i]
   bi = #() --bone index array
   wv = #() --weight value array
   
   for j = 1 to w.boneids.count do
   (
      boneid = w.boneids[j]
      weight = w.weights[j]
      append bi boneid
      append wv weight
   )   
   
   skinOps.ReplaceVertexWeights skinMod i bi wv
   
	)
)
)

	fseek f NextLink#seek_set
	)

	fseek f NL#seek_set
)
Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
if error == "yes" do(
Print "Something didn't import properly! Check out the console!"
)
fclose f
-- fclose g
)
)

	on btnXNO pressed do(
clearlistener()
fname = GetOpenFileName caption:"Open XNO model" types:"XNO Model File(*.xno)|*.xno"
if fname != undefined do(
f = fopen fname "rb"   --open file in read only format
p = getFilenamePath fname
local UseVertAlpha = tglVertAlpha.checked

struct TexElm(
	TOffset
)
struct VertGroup(
	VOffset
)
struct PolyGroup(
	POffset
)
struct BoneName(
	BoneName
)
struct Ftotal(
	FaceTotal
)

TexElmOffArray=#()
VertGroupArray=#()
PolyGroupArray=#()
BoneArray=#()
BoneInfoArray=#()
TextureNames = #()

-- NXIF -- 
Print ("NXIF start = 0x"+(bit.intAsHex(ftell f)as string))
NXIF = ReadFixedString f 4
NXIFSize = ReadLong f - 4
NXIFStruct = ReadLong f
fseek f NXIFSize#seek_cur

Print ("NXIF end = 0x"+(bit.intAsHex(ftell f)as string))
If NXIFStruct == 2 Do (
Print ("NXTL start = 0x"+(bit.intAsHex(ftell f)as string))
	NXTL = ReadFixedString f 4
	NXTLSize = ReadLong f 
)

If NXIFStruct == 3 Do (
Print ("NXTL start = 0x"+(bit.intAsHex(ftell f)as string))
	NXTL = ReadFixedString f 4
	NXTLSize = ReadLong f
	Rtn = ftell f
	
	TexInfo = ReadLong f + 0x20
	fseek f TexInfo#seek_set
	TexTotal = ReadLong f
	TexStart = ReadLong f +0x20
	fseek f TexStart#seek_set
	
	For tx = 1 to TexTotal Do (
		fseek f 4#seek_cur
		TexNameOff = ReadLong f +0x20
		fseek f 12#seek_cur
		TxRtn = ftell f
		fseek f TexNameOff#seek_set
		TexName = ReadString f
		print TexName
		append TextureNames (TexName)
		fseek f TxRtn#seek_set
	)
	fseek f Rtn#seek_set
	fseek f NXTLSize#seek_cur
	
Print ("NXTL end = 0x"+(bit.intAsHex(ftell f)as string))

Print ("NXNN start = 0x"+(bit.intAsHex(ftell f)as string))
	NXNN = ReadFixedString f 4
	NXNNSize = ReadLong f 
	Rtn = ftell f
	BOffset = ReadLong f + 0x24
	fseek f BOffset#seek_set
	NameTotal = ReadLong f
	NamesOff = ReadLong f + 0x20
	fseek f NamesOff#seek_set
	
	For n = 1 to NameTotal Do (
		BoneID = ReadLong f + 1
		BoneNameOffset = ReadLong f + 0x20
		Next = ftell f
		fseek f BoneNameOffset#seek_set
		BoneName = ReadString f 
		fseek f Next#seek_set
		append BoneInfoArray (BoneName)
	)
	
	fseek f Rtn#seek_set
	fseek f NXNNSize#seek_cur
Print ("NXNN end = 0x"+(bit.intAsHex(ftell f)as string))
)

If NXIFStruct == 4 Do (
Print ("NXTL start = 0x"+(bit.intAsHex(ftell f)as string))
	NXTL = ReadFixedString f 4
	NXTLSize = ReadLong f
	Rtn = ftell f
	
	TexInfo = ReadLong f + 0x20
	fseek f TexInfo#seek_set
	TexTotal = ReadLong f
	TexStart = ReadLong f +0x20
	fseek f TexStart#seek_set
	
	For tx = 1 to TexTotal Do (
		fseek f 4#seek_cur
		TexNameOff = ReadLong f +0x20
		fseek f 12#seek_cur
		TxRtn = ftell f
		fseek f TexNameOff#seek_set
		TexName = ReadString f
		print TexName
		append TextureNames (TexName)
		fseek f TxRtn#seek_set
	)
	fseek f Rtn#seek_set
	fseek f NXTLSize#seek_cur
	
Print ("NXTL end = 0x"+(bit.intAsHex(ftell f)as string))

Print ("NXEF start = 0x"+(bit.intAsHex(ftell f)as string))
	NXEF = ReadFixedString f 4
	NXEFSize = ReadLong f 
	fseek f NXEFSize#seek_cur
Print ("NXEF end = 0x"+(bit.intAsHex(ftell f)as string))

Print ("NXNN start = 0x"+(bit.intAsHex(ftell f)as string))
	NXNN = ReadFixedString f 4
	NXNNSize = ReadLong f 
	Rtn = ftell f
	BOffset = ReadLong f + 0x24
	fseek f BOffset#seek_set
	NameTotal = ReadLong f
	NamesOff = ReadLong f + 0x20
	fseek f NamesOff#seek_set

	For n = 1 to NameTotal Do (
		BoneID = ReadLong f + 1
		BoneNameOffset = ReadLong f + 0x20
		Next = ftell f
		fseek f BoneNameOffset#seek_set
		BoneName = ReadString f 
		fseek f Next#seek_set
		append BoneInfoArray (BoneName)
	)
	
	fseek f Rtn#seek_set
	fseek f NXNNSize#seek_cur
Print ("NXNN end = 0x"+(bit.intAsHex(ftell f)as string))
)

-- NXOB --
Print ("NXOB start = 0x"+(bit.intAsHex(ftell f)as string))
NXOB = ReadFixedString f 4
NXOBSize = ReadLong f
GInfoOff = ReadLong f +0x20
fseek f 0x14 #seek_cur
Print ("NXOB end = 0x"+(bit.intAsHex(ftell f)as string))

fseek f GInfoOff#seek_set
Print ("GInfoOff start: 0x"+((bit.intAsHex(ftell f))as string))
fseek f 0x10#seek_cur

TexElmTotal = ReadLong f
TexElmOff = ReadLong f + 0x20
VertGroupTotal = ReadLong f
VertGroupOff = ReadLong f + 0x20
PolyElmTotal = ReadLong f
PolyElmOff = ReadLong f +0x20
BoneTotal = ReadLong f
fseek f 4#seek_cur
BoneOffset = ReadLong f + 0x20
NodeTotal = ReadLong f
LinkTotal = ReadLong f
LinkOffset = ReadLong f + 0x20
fseek f 4#seek_cur
Print ("GInfoOff end: 0x"+((bit.intAsHex(ftell f))as string))

-- Texture Element Array Building --

fseek f TexElmOff#seek_set
Print ("TexElmOff start: 0x"+((bit.intAsHex(ftell f))as string))
for vg = 1 to TexElmTotal Do (
	fseek f 4#seek_cur
	TexElmOffInfoOffset = ReadLong f +0x20
	append TexElmOffArray (TexElm TOffset:TexElmOffInfoOffset)
)
Print ("TexElmOff end: 0x"+((bit.intAsHex(ftell f))as string))
	
-- Vertex Group Array Building --

fseek f VertGroupOff#seek_set
Print ("VertGroupOff start: 0x"+((bit.intAsHex(ftell f))as string))
for vg = 1 to VertGroupTotal Do (
	fseek f 4#seek_cur
	VertInfoOffset = ReadLong f +0x20
	append VertGroupArray (VertGroup VOffset:VertInfoOffset)
)
Print ("VertGroupOff end: 0x"+((bit.intAsHex(ftell f))as string))
	
-- Poly Group Array Building --

fseek f PolyElmOff#seek_set
Print ("PolyElmOff start: 0x"+((bit.intAsHex(ftell f))as string))
for pg = 1 to PolyElmTotal Do (
	fseek f 4#seek_cur
	PolyInfoOffset = ReadLong f + 0x20
	append PolyGroupArray (PolyGroup POffset:PolyInfoOffset)
)
Print ("PolyElmOff end: 0x"+((bit.intAsHex(ftell f))as string))

-- Bone Importing -- (Works without errors)

fseek f BoneOffset#seek_set
ProperBone_array = #()
Print ("Bone start: 0x"+((bit.intAsHex(ftell f))as string))
for t = 1 to BoneTotal Do (
	Header1 = ReadByte f #unsigned
	Header2 = ReadByte f #unsigned
	Header3 = ReadByte f #unsigned
	Header4 = ReadByte f #unsigned
	print ("Bone #" + t as string + "(" + BoneInfoArray[t] as string + ") Header values = "+ Header1 as string + ", " + Header2 as string + ", " + Header3 as string + ", " + Header4 as string)
	NodeID = ReadShort f#unsigned
	if NodeID != 65535 do(
		append ProperBone_array t
	)
	ParentID = ReadShort f#unsigned +1
	ChildID = ReadShort f#unsigned
	SiblingID = ReadShort f#unsigned
	PosX = ReadFloat f
	PosY = ReadFloat f
	PosZ = ReadFloat f
	RotX = ReadBAMS f
	RotY = ReadBAMS f
	RotZ = ReadBAMS f
	ScaleX = ReadFloat f
	ScaleY = ReadFloat f
	ScaleZ = ReadFloat f
	m11 = ReadFloat f; m21 = ReadFloat f; m31 = ReadFloat f; m41 = ReadFloat f
	m12 = ReadFloat f; m22 = ReadFloat f; m32 = ReadFloat f; m42 = ReadFloat f
	m13 = ReadFloat f; m23 = ReadFloat f; m33 = ReadFloat f; m43 = ReadFloat f
	m14 = ReadFloat f; m24 = ReadFloat f; m34 = ReadFloat f; m44 = ReadFloat f
	tfm = matrix3 [m11,m12,m13,m14] [m21,m22,m23,m24] [m31,m32,m33,m34] [m41,m42,m43,m44]
	fseek f 0x20#seek_cur
	
	newBone = bonesys.createbone \
				  tfm.row4	\
				  (tfm.row4 + 1 * (normalize tfm.row1)) \
				  (normalize tfm.row3)

			if BoneInfoArray[t] != undefined do(
			newBone.name = BoneInfoArray[t] as string
			)
			newBone.width = 0.01
			newBone.height = 0.01
			newBone.transform = tfm
			newBone.wirecolor = yellow
			newbone.showlinks = true

			pos = [m14,m24,m34]
			pos = pos * tfm

			newBone.pos.x += ((-1)*pos.x)
			newBone.pos.y += ((-1)*pos.y)
			newBone.pos.z += ((-1)*pos.z)
			
			If ParentID != 0xFFFF Do (
				newBone.parent = BoneArray[ParentID]
			)

			newBone.setBoneEnable false 0
			newBone.pos.controller      = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
			
			append BoneArray newBone
)
Print ("Bone end: 0x"+((bit.intAsHex(ftell f))as string))
	
fseek f LinkOffset#seek_set
Print ("Link start: 0x"+((bit.intAsHex(ftell f))as string))
For b = 1 to LinkTotal Do (
	fseek f 4#seek_cur
	LinkBlockTotal = ReadLong f
	LinkBlockOffset = ReadLong f +0x20
	fseek f 8#seek_cur
	NL = ftell f
	Print ("Link end: 0x"+((bit.intAsHex(ftell f))as string))
	fseek f LinkBlockOffset#seek_set

	For l = 1 to LinkBlockTotal Do (
		Vert_Array=#()
		Normal_Array=#()
		Color_Array=#()
		Alpha_Array=#()
		UV_Array=#()
		W1_array = #()
		B1_array = #()
		Weight_array = #()
		Face_Array=#()
		Face_Total=#()
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

		Print ("Link Block start = 0x"+(bit.intAsHex(ftell f)as string))
		fseek f 0x10#seek_cur
		VisibilityBone = ReadLong f #unsigned +1
		SingleBindBone = ReadLong f #unsigned +1
		MatID = ReadLong f #unsigned +1
		VertID = ReadLong f #unsigned +1
		LinkID = ReadLong f #unsigned +1
		PolyID = ReadLong f #unsigned +1
		NextLink = ftell f
		Print ("Link Block end = 0x"+(bit.intAsHex(ftell f)as string))

		fseek f TexElmOffArray[MatID].TOffset#seek_set
		Print ("Texture element array start: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f 8#seek_cur
		TexBuffer1 = ReadLong f #unsigned + 0x20
		TexBuffer2 = ReadLong f #unsigned + 0x20
		TexBuffer3 = ReadLong f #unsigned + 0x20
		fseek f 12 #seek_cur
		Print ("Texture element array end: 0x"+((bit.intAsHex(ftell f))as string))

		fseek f TexBuffer1 #seek_set
		Print ("Texture buffer 1 start: 0x"+((bit.intAsHex(ftell f))as string))
		MatFloatA1 = readfloat f
		MatFloatA2 = readfloat f
		MatFloatA3 = readfloat f
		MatFloatA4 = readfloat f
		MatFloatB1 = readfloat f
		MatFloatB2 = readfloat f
		MatFloatB3 = readfloat f
		MatFloatB4 = readfloat f
		MatFloatC1 = readfloat f
		MatFloatC2 = readfloat f
		MatFloatC3 = readfloat f
		MatFloatC4 = readfloat f
		MatFloatD1 = readfloat f
		MatFloatD2 = readfloat f
		MatFloatD3 = readfloat f
		MatFloatD4 = readfloat f
		MatFloatE1 = readfloat f
		MatFloatE2 = readfloat f
		MatFloatE3 = readfloat f
		MatFloatE4 = readfloat f
		Print ("Texture buffer 1 end: 0x"+((bit.intAsHex(ftell f))as string))
			
		fseek f TexBuffer2 #seek_set
		Print ("Texture buffer 2 start: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f 0x40 #seek_cur
		Print ("Texture buffer 2 end: 0x"+((bit.intAsHex(ftell f))as string))	

		fseek f TexBuffer3 #seek_set
		Print ("Texture buffer 3 start: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f 4 #seek_cur
		TextureID = ReadLong f + 1
		Print ("Texture buffer 3 abrupt end: 0x"+((bit.intAsHex(ftell f))as string))

		fseek f VertGroupArray[VertID].VOffset#seek_set
		Print ("Vertex group array start: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f 8#seek_cur
		VertSize = ReadLong f #unsigned
		VertTotal = ReadLong f #unsigned
		VertBuffer = ReadLong f #unsigned + 0x20
		NodeSize = ReadLong f #unsigned
		NodeBuffer = ReadLong f #unsigned + 0x20
		fseek f 0x14 #seek_cur
		Print ("Vertex group end: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f NodeBuffer #seek_set
		Print ("Node buffer start: 0x"+((bit.intAsHex(ftell f))as string))
			
		NodeList_array = #()
		for n = 1 to NodeSize do(
		Node = ReadLong f #unsigned + 1
		append NodeList_array Node
		)
		If NodeBuffer == 0x20 do(
		append NodeList_array SingleBindBone
		)
		print NodeList_array
		Print ("Node buffer end: 0x"+((bit.intAsHex(ftell f))as string))
			
		fseek f VertBuffer#seek_set
		Print ("Vertex buffer start: 0x"+((bit.intAsHex(ftell f))as string) + ", Vert Size = 0x" + ((bit.intAsHex(VertSize))as string) )
		If VertSize == 0x14 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_Array 255
				append UV_Array[tu,tv,0]
			)
		)
		If VertSize == 0x18 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x1C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[0,0,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x20 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[255,255,255]
				append Alpha_Array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x24 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x28 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				colorb2 = ReadByte f #unsigned
				colorg2 = ReadByte f #unsigned
				colorr2 = ReadByte f #unsigned
				colora2 = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x2C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				tu2 = ReadFloat f
				tv2 = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x30 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
					if NodeList_array.count > 1 do(
					Bone2 = NodeList_array[2]
					Bone2 = ProperBone_array[Bone2]
						if NodeList_array.count > 2 do(
						Bone3 = NodeList_array[3]
						Bone3 = ProperBone_array[Bone3]
							if NodeList_array.count > 3 do(
							Bone4 = NodeList_array[4]
							Bone4 = ProperBone_array[Bone4]
							if bone4 < bone3 do(weight4 = 0)
							)
						)
					)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x34 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = ReadByte f #unsigned + 1
				Bone1 = NodeList_array[Bone1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = ReadByte f #unsigned + 1
				Bone2 = NodeList_array[Bone2]
				Bone2 = ProperBone_array[Bone2]
				Bone3 = ReadByte f #unsigned + 1
				Bone3 = NodeList_array[Bone3]
				Bone3 = ProperBone_array[Bone3]
				Bone4 = ReadByte f #unsigned + 1
				Bone4 = NodeList_array[Bone4]
				Bone4 = ProperBone_array[Bone4]
				if bone4 < bone3 do(weight4 = 0)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x38 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				fseek f 0x1C#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				fseek f 0x08#seek_cur
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_Array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x3C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				nx2 = ReadFloat f
				ny2 = ReadFloat f
				nz2 = ReadFloat f
				nx3 = ReadFloat f
				ny3 = ReadFloat f
				nz3 = ReadFloat f
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x40 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				fseek f 0x1C#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				fseek f 0x10#seek_cur
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_Array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x44 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_array[1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = 2
				Bone3 = 3
				Bone4 = 4
				fseek f 0x1C#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				fseek f 0x14#seek_cur
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_Array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x48 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = ReadByte f #unsigned + 1
				Bone1 = NodeList_array[Bone1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = ReadByte f #unsigned + 1
				Bone2 = NodeList_array[Bone2]
				Bone2 = ProperBone_array[Bone2]
				Bone3 = ReadByte f #unsigned + 1
				Bone3 = NodeList_array[Bone3]
				Bone3 = ProperBone_array[Bone3]
				Bone4 = ReadByte f #unsigned + 1
				Bone4 = NodeList_array[Bone4]
				Bone4 = ProperBone_array[Bone4]
				if Bone4 < Bone3 do(Weight4 = 0)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				nx2 = ReadFloat f
				ny2 = ReadFloat f
				nz2 = ReadFloat f
				nx3 = ReadFloat f
				ny3 = ReadFloat f
				nz3 = ReadFloat f
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[255,255,255]
				append Alpha_Array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x4C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = ReadByte f #unsigned + 1
				Bone1 = NodeList_array[Bone1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = ReadByte f #unsigned + 1
				Bone2 = NodeList_array[Bone2]
				Bone2 = ProperBone_array[Bone2]
				Bone3 = ReadByte f #unsigned + 1
				Bone3 = NodeList_array[Bone3]
				Bone3 = ProperBone_array[Bone3]
				Bone4 = ReadByte f #unsigned + 1
				Bone4 = NodeList_array[Bone4]
				Bone4 = ProperBone_array[Bone4]
				if Bone4 < Bone3 do(Weight4 = 0)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				nx2 = ReadFloat f
				ny2 = ReadFloat f
				nz2 = ReadFloat f
				nx3 = ReadFloat f
				ny3 = ReadFloat f
				nz3 = ReadFloat f
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x54 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = ReadByte f #unsigned + 1
				Bone1 = NodeList_array[Bone1]
				Bone1 = ProperBone_array[Bone1]
				Bone2 = ReadByte f #unsigned + 1
				Bone2 = NodeList_array[Bone2]
				Bone2 = ProperBone_array[Bone2]
				Bone3 = ReadByte f #unsigned + 1
				Bone3 = NodeList_array[Bone3]
				Bone3 = ProperBone_array[Bone3]
				Bone4 = ReadByte f #unsigned + 1
				Bone4 = NodeList_array[Bone4]
				Bone4 = ProperBone_array[Bone4]
				if Bone4 < Bone3 do(Weight4 = 0)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				tu = ReadFloat f
				tv = (ReadFloat f * -1) + 1
				tu2 = ReadFloat f
				tv2 = (ReadFloat f * -1) + 1
				nx2 = ReadFloat f
				ny2 = ReadFloat f
				nz2 = ReadFloat f
				nx3 = ReadFloat f
				ny3 = ReadFloat f
				nz3 = ReadFloat f
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		Print ("Vertex buffer end: 0x"+((bit.intAsHex(ftell f))as string))
	
		fseek f PolyGroupArray[LinkID].POffset#seek_set
		Print ("Polygon info start: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f 0x04 #seek_cur
		FullFaceTotal = ReadLong f
		FaceTotalList = ReadLong f
		FaceTotalTableOff = ReadLong f + 0x20
		PolyBufferOffset = ReadLong f + 0x20
		fseek f 0x0C #seek_cur
		Print ("Polygon info end: 0x"+((bit.intAsHex(ftell f))as string))

		fseek f FaceTotalTableOff#seek_set
		Print ("Polygon total table start: 0x"+((bit.intAsHex(ftell f))as string))
		For ft = 1 to FaceTotalList Do (
			FaceTotal = ReadShort f
			append Face_Total (Ftotal FaceTotal:FaceTotal)
		)
		Print ("Polygon total table end: 0x"+((bit.intAsHex(ftell f))as string))
			
		fseek f PolyBufferOffset#seek_set
		Print ("Polygon face start: 0x"+((bit.intAsHex(ftell f))as string))
		For pb = 1 to Face_Total.count Do (
		StartDirection = -1
		f1 = ReadShort f#unsigned + 1
		f2 = ReadShort f#unsigned + 1
		FaceDirection = StartDirection
		IndexCounter = 2
		Do (
			f3 = ReadShort f#unsigned
			IndexCounter += 1
			if (f3==0xFFFF) then (
				f1 = (ReadShort f#unsigned) + 1
				f2 = (ReadShort f#unsigned) + 1
				FaceDirection = StartDirection
				IndexCounter += 2
			) else (
				f3 += 1
				FaceDirection *= -1
				if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
					if FaceDirection > 0 then append face_Array [f1,f2,f3]
					else append face_Array [f1,f3,f2]
				)
				f1 = f2
				f2 = f3
			)
		)
		while IndexCounter != Face_Total[pb].FaceTotal
	)
Print ("Polygon face end: 0x"+((bit.intAsHex(ftell f))as string))

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

		msh = mesh vertices:Vert_array faces:Face_array
		msh.numTVerts = UV_array.count
		setNumCPVVerts msh msh.numTVerts
		setCVertMode msh true
		setShadeCVerts msh true
		defaultVCFaces msh
		for p = 1 to Color_array.count do(
		if UseVertAlpha == false then (setvertcolor msh p Color_array[p]) else (setvertcolor msh p [Alpha_array[p],Alpha_array[p],Alpha_array[p]])
		)
		buildTVFaces msh
		mat = standardMaterial()
		mat.name = TextureNames[TextureID]
		mat.showinviewport = true
		mat.twosided = false
		tm = Bitmaptexture filename:(p + TextureNames[TextureID])
		tm.alphasource = 2
		mat.diffuseMap = tm
		msh.name = (TextureNames[TextureID] as string) + "(" + ((bit.intAsHex(VertSize))as string) + ")"
		msh.material = mat
		for j = 1 to UV_array.count do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
		max modify mode
		select msh
		
      --set smoothing group of all faces to 1 to get one normal per vertex
      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
      --set normals via edit normals modifier
      select msh
      addmodifier msh (Edit_Normals ()) ui:off
      msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
      EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
      EN_setNormal = msh.Edit_Normals.SetNormal
      normID = #{}
      --apply normals
      for v = 1 to Normal_array.count do
      (
         free normID
         EN_convertVS #{v} &normID
         for id in normID do EN_setNormal id Normal_array[v]
      )

		skinMod = skin ()
		addModifier msh skinMod
		BoneCount = BoneArray.count
		for i = 1 to BoneCount do
		(
		maxbone = getnodebyname BoneArray[i].name
		if i != BoneCount then
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
   
		)

		modPanel.setCurrentObject skinMod

		for i = 1 to Weight_array.count do (
		w = Weight_array[i]
		bi = #() --bone index array
		wv = #() --weight value array
   
		for j = 1 to w.boneids.count do
		(
			boneid = w.boneids[j]
			weight = w.weights[j]
			append bi boneid
			append wv weight
		)   
   
		skinOps.ReplaceVertexWeights skinMod i bi wv
   
		)
	  
--		Print ("Object = " + (LinkID as string))
--		Print ("Poly = " + (PolyID as string))
--		Print ("VertSize = " + ((bit.intAsHex VertSize) as string))
		fseek f NextLink#seek_set
	)
	fseek f NL#seek_set
)
Print ("Link end: 0x"+((bit.intAsHex(ftell f))as string))
fclose f
)
)

	on btnZNO pressed do(
clearlistener()
fname = GetOpenFileName caption:"Open ZNO model" types:"ZNO Model File(*.zno)|*.zno"
if fname != undefined do(
f = fopen fname "rb"   --open file in read only format
local UseVertAlpha = tglVertAlpha.checked

struct VertGroup(
	VOffset
)
struct PolyGroup(
	POffset
)
VertGroupArray=#()
PolyGroupArray=#()
BoneArray=#()
Print ("Header info start: 0x"+((bit.intAsHex(ftell f))as string))	

-- NZIF --
NZIF = ReadFixedString f 4
NZIFSize = ReadLong f
StructFlag = ReadLong f
fseek f 0x14#seek_cur

If StructFlag == 2 Do (
	-- NZTL --
	NZTL = ReadFixedString f 4
	NZTLSize = ReadLong f
	fseek f NZTLSize#seek_cur
)

If StructFlag == 3 Do (
	-- NZTL --
	NZTL = ReadFixedString f 4
	NZTLSize = ReadLong f
	fseek f NZTLSize#seek_cur
	
	-- NZNN -- 
	NZNN = ReadFixedString f 4
	NZNNSize = ReadLong f
	fseek f NZNNSize#seek_cur
)


-- NZOB --
NZOB = ReadFixedString f 4
NZOBSize = ReadLong f
GInfoOff = ReadLong f +0x20
Print ("Header info end: 0x"+((bit.intAsHex(ftell f))as string))	

fseek f GInfoOff#seek_set
Print ("GInfoOff start: 0x"+((bit.intAsHex(ftell f))as string))

fseek f 0x10#seek_cur

TexElmTotal = ReadLong f
TexElmOff = ReadLong f + 0x20
VertGroupTotal = ReadLong f
VertGroupOff = ReadLong f + 0x20
PolyElmTotal = ReadLong f
PolyElmOff = ReadLong f +0x20
BoneTotal = ReadLong f
fseek f 4#seek_cur
BoneOffset = ReadLong f + 0x20
NodeTotal = ReadLong f
LinkTotal = ReadLong f
LinkOffset = ReadLong f + 0x20
Print ("GInfoOff end: 0x"+((bit.intAsHex(ftell f))as string))

-- Vertex Group Array Building --

fseek f VertGroupOff#seek_set
Print ("VertGroup start: 0x"+((bit.intAsHex(ftell f))as string))
for vg = 1 to VertGroupTotal Do (
	fseek f 4#seek_cur
	VertInfoOffset = ReadLong f +0x20
	append VertGroupArray (VertGroup VOffset:VertInfoOffset)
)
Print ("VertGroup end: 0x"+((bit.intAsHex(ftell f))as string))

-- Poly Group Array Building --

fseek f PolyElmOff#seek_set 
Print ("PolyElm start: 0x"+((bit.intAsHex(ftell f))as string))
for pg = 1 to PolyElmTotal Do (
	fseek f 4#seek_cur
	PolyInfoOffset = ReadLong f + 0x20
	append PolyGroupArray (PolyGroup POffset:PolyInfoOffset)
)
Print ("PolyElm end: 0x"+((bit.intAsHex(ftell f))as string))
 -- Bone Importing -- (Doesn't import bones correctly, but MSN_BODY seems to import close to properly.)

 fseek f BoneOffset#seek_set
 ProperBone_array = #()
 Print ("Bones start: 0x"+((bit.intAsHex(ftell f))as string))
 for t = 1 to BoneTotal Do (
	Header1 = ReadByte f #unsigned
	Header2 = ReadByte f #unsigned
	Header3 = ReadByte f #unsigned
	Header4 = ReadByte f #unsigned
	NodeID = ReadShort f#unsigned
	if NodeID != 65535 do(
	append ProperBone_array t
	)
 	ParentID = ReadShort f#unsigned +1
 	ChildID = ReadShort f#unsigned
 	SiblingID = ReadShort f#unsigned
 	PosX = ReadFloat f
 	PosY = ReadFloat f
 	PosZ = ReadFloat f
 	RotX = ReadBAMS f
 	RotY = ReadBAMS f
 	RotZ = ReadBAMS f
 	ScaleX = ReadFloat f
 	ScaleY = ReadFloat f
 	ScaleZ = ReadFloat f
 	m11 = ReadFloat f; m21 = ReadFloat f; m31 = ReadFloat f; m41 = ReadFloat f
 	m12 = ReadFloat f; m22 = ReadFloat f; m32 = ReadFloat f; m42 = ReadFloat f
 	m13 = ReadFloat f; m23 = ReadFloat f; m33 = ReadFloat f; m43 = ReadFloat f
 	m14 = ReadFloat f; m24 = ReadFloat f; m34 = ReadFloat f; m44 = ReadFloat f
 	tfm = matrix3 [m11,m12,m13,m14] [m21,m22,m23,m24] [m31,m32,m33,m34] [m41,m42,m43,m44]
	fseek f 0x20#seek_cur
	print ("Bone #" + t as string + " Header values = "+ Header1 as string + ", " + Header2 as string + ", " + Header3 as string + ", " + Header4 as string + ", Node ID = " + NodeID as string)
 	
 	newBone = bonesys.createbone \
 				  tfm.row4	\
 				  (tfm.row4 + 1 * (normalize tfm.row1)) \
 				  (normalize tfm.row3)
 					
 			newBone.width = 0.01
 			newBone.height = 0.01
 			newBone.transform = tfm
 			newBone.wirecolor = yellow
 			newbone.showlinks = true
 			
 			pos = [m14,m24,m34]
 			pos = pos * tfm 			
 			
 			newBone.pos.x += ((-1)*pos.x)
 			newBone.pos.y += ((-1)*pos.y)
 			newBone.pos.z += ((-1)*pos.z)
 			
 			If ParentID != 0xFFFF Do (
 				newBone.parent = BoneArray[ParentID]
 			)
 			
 			
 			newBone.setBoneEnable false 0
 			newBone.pos.controller      = TCB_position ()
 			newBone.rotation.controller = TCB_rotation ()
 			
 			append BoneArray newBone
 )
	Print ("Bones end: 0x"+((bit.intAsHex(ftell f))as string))
 
-- Mesh/Object Importing Functions -- (Commented out to test bones. Uncomment to use)

fseek f LinkOffset#seek_set
Print ("LinkOffset start: 0x"+((bit.intAsHex(ftell f))as string))	
For b = 1 to LinkTotal Do (
	fseek f 4#seek_cur
	LinkBlockTotal = ReadLong f
	LinkBlockOffset = ReadLong f +0x20
	fseek f 8#seek_cur
	NL = ftell f
	Print ("LinkOffset end: 0x"+((bit.intAsHex(ftell f))as string))	
	fseek f LinkBlockOffset#seek_set

	For l = 1 to LinkBlockTotal Do (
		Vert_Array=#()
		Normal_Array=#()
		Color_Array=#()
		Alpha_Array=#()
		UV_Array=#()
		UV_Array2=#()
		Face_Array=#()
		W1_array = #()
		B1_array = #()
		Weight_array = #()
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
		Print ("Link Block start: 0x"+((bit.intAsHex(ftell f))as string))	
		fseek f 0x10#seek_cur
		VisibilityBone = ReadLong f #unsigned + 1
		SingleBindBone = ReadLong f #unsigned + 1
		SomethingElse = ReadLong f #unsigned + 1	
		VertID = ReadLong f #unsigned + 1
		PolyID = ReadLong f #unsigned + 1
		LinkID = ReadLong f #unsigned + 1
		NextLink = ftell f
		Print ("Link Block end: 0x"+((bit.intAsHex(ftell f))as string))

		fseek f VertGroupArray[VertID].VOffset#seek_set
		Print ("Vertex group start: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f 8#seek_cur
		VertSize = ReadLong f #unsigned
		VertTotal = ReadLong f #unsigned
		VertBuffer = ReadLong f #unsigned + 0x20
		NodeSize = ReadLong f #unsigned
		NodeBuffer = ReadLong f #unsigned + 0x20
		Print ("Vertex group end: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f NodeBuffer #seek_set
		Print ("Node buffer start: 0x"+((bit.intAsHex(ftell f))as string))
		NodeList_array = #()
		for n = 1 to NodeSize do(
		Node = ReadLong f #unsigned + 1
		append NodeList_array Node
		)
		If NodeBuffer == 0x20 do(
		append NodeList_array SingleBindBone
		)
		print NodeList_array
		Print ("Node buffer end: 0x"+((bit.intAsHex(ftell f))as string))
			
		fseek f VertBuffer#seek_set
		Print ("Vertex buffer start: 0x"+((bit.intAsHex(ftell f))as string))
		Print ("VertSize = " + ((bit.intAsHex VertSize) as string))
		If VertSize == 0x14 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
			)
		)
		If VertSize == 0x18 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				fseek f 0x04#seek_cur
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x1C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				fseek f 0x08#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x20 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				fseek f 0x0C #seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x24 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				fseek f 0x04 #seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x28 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				fseek f 0x04#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x2C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x30 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = ReadByte f #unsigned + 1
				Bone1 = NodeList_Array[Bone1]
				Bone1 = ProperBone_Array[Bone1]
				Bone2 = ReadByte f #unsigned + 1
				Bone2 = NodeList_Array[Bone2]
				Bone2 = ProperBone_Array[Bone2]
				Bone3 = ReadByte f #unsigned + 1
				Bone3 = NodeList_Array[Bone3]
				Bone3 = ProperBone_Array[Bone3]
				Bone4 = ReadByte f #unsigned + 1
				Bone4 = NodeList_Array[Bone4]
				Bone4 = ProperBone_Array[Bone4]
				if Bone4 < Bone3 do(Weight4 = 0)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x34 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				fseek f 0x04#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x38 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				fseek f 0x04#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x3C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				fseek f 0x04#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				tu2 = ReadFloat f
				tv2 = (ReadFloat f*-1) + 1
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_array colora
				append UV_Array[tu,tv,0]
				append UV_Array2[tu2,tv2,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x40 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = 1
				Weight2 = 0
				Weight3 = 0
				Weight4 = 0
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				colorb = ReadByte f #unsigned
				colorg = ReadByte f #unsigned
				colorr = ReadByte f #unsigned
				colora = ReadByte f #unsigned
				fseek f 0x04#seek_cur
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				fseek f 0x18#seek_cur
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[colorr,colorg,colorb]
				append Alpha_array colora
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x44 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				fseek f 0x18 #seek_cur
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x48 Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = ReadByte f #unsigned + 1
				Bone1 = NodeList_Array[Bone1]
				Bone1 = ProperBone_Array[Bone1]
				Bone2 = ReadByte f #unsigned + 1
				Bone2 = NodeList_Array[Bone2]
				Bone2 = ProperBone_Array[Bone2]
				Bone3 = ReadByte f #unsigned + 1
				Bone3 = NodeList_Array[Bone3]
				Bone3 = ProperBone_Array[Bone3]
				Bone4 = ReadByte f #unsigned + 1
				Bone4 = NodeList_Array[Bone4]
				Bone4 = ProperBone_Array[Bone4]
				if Bone4 < Bone3 do(Weight4 = 0)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				fseek f 0x18#seek_cur
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		If VertSize == 0x4C Do (
			for v = 1 to VertTotal Do (
				vx = ReadFloat f
				vy = ReadFloat f
				vz = ReadFloat f
				Weight1 = ReadFloat f
				Weight2 = ReadFloat f
				Weight3 = ReadFloat f
				Weight4 = 1 as float - (Weight1 + Weight2 + Weight3)
				Bone1 = NodeList_Array[1]
				Bone1 = ProperBone_Array[Bone1]
				if NodeList_Array.count > 1 do(
					Bone2 = NodeList_Array[2]
					Bone2 = ProperBone_Array[Bone2]
					if NodeList_Array.count > 2 do(
						Bone3 = NodeList_Array[3]
						Bone3 = ProperBone_Array[Bone3]
						if NodeList_Array.count > 3 do(
							Bone4 = NodeList_Array[4]
							Bone4 = ProperBone_Array[Bone4]
							if Bone4 < Bone3 do(Weight4 = 0)
						)
					)
				)
				nx = ReadFloat f
				ny = ReadFloat f
				nz = ReadFloat f
				tu = ReadFloat f
				tv = (ReadFloat f*-1) + 1
				fseek f 0x20#seek_cur
				append Vert_Array[vx,vy,vz]
				append Normal_Array[nx,ny,nz]
				append Color_Array[255,255,255]
				append Alpha_array 255
				append UV_Array[tu,tv,0]
				append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
				append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			)
		)
		Print ("Vertex buffer end: 0x"+((bit.intAsHex(ftell f))as string))
		
		fseek f PolyGroupArray[PolyID].POffset#seek_set
		Print ("Poly Group start: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f 0xC#seek_cur
		PolyOffset = ReadLong f + 0x20
		Print ("Poly Group end: 0x"+((bit.intAsHex(ftell f))as string))
		fseek f PolyOffset#seek_set
	
		Print ("Poly Offset start: 0x"+((bit.intAsHex(ftell f))as string))
		FaceTotal = ReadLong f
		StartDirection = -1
		f1 = ReadShort f#unsigned + 1
		f2 = ReadShort f#unsigned + 1
		FaceDirection = StartDirection
		IndexCounter = 2
		Do (
			f3 = ReadShort f#unsigned
			IndexCounter += 1
			if (f3==0xFFFF) then (
				f1 = (ReadShort f#unsigned) + 1
				f2 = (ReadShort f#unsigned) + 1
				FaceDirection = StartDirection
				IndexCounter += 2
			) else (
				f3 += 1
				FaceDirection *= -1
				if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
					if FaceDirection > 0 then append face_Array [f1,f2,f3]
					else append face_Array [f1,f3,f2]
				)
				f1 = f2
				f2 = f3
			)
		)
		while IndexCounter != FaceTotal
		Print ("Poly Offset end: 0x"+((bit.intAsHex(ftell f))as string))

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

		msh = mesh vertices:Vert_array faces:Face_array
		msh.numTVerts = UV_array.count
		setNumCPVVerts msh msh.numTVerts
		setCVertMode msh true
		setShadeCVerts msh true
		defaultVCFaces msh
		for p = 1 to Color_array.count do(
		if UseVertAlpha == false then (setvertcolor msh p Color_array[p]) else (setvertcolor msh p [Alpha_array[p],Alpha_array[p],Alpha_array[p]])
		)
		buildTVFaces msh
		for j = 1 to UV_array.count do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
		msh.name = ((bit.intAsHex(VertSize))as string)
		max modify mode
		select msh
		
      --set smoothing group of all faces to 1 to get one normal per vertex
      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
      --set normals via edit normals modifier
      select msh
      addmodifier msh (Edit_Normals ()) ui:off
      msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
      EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
      EN_setNormal = msh.Edit_Normals.SetNormal
      normID = #{}
      --apply normals
      for v = 1 to Normal_array.count do
      (
         free normID
         EN_convertVS #{v} &normID
         for id in normID do EN_setNormal id Normal_array[v]
      )

		skinMod = skin ()
		addModifier msh skinMod
		BoneCount = BoneArray.count
		for i = 1 to BoneCount do
		(
		maxbone = getnodebyname BoneArray[i].name
		if i != BoneCount then
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
   
		)

		modPanel.setCurrentObject skinMod

		for i = 1 to Weight_array.count do (
		w = Weight_array[i]
		bi = #() --bone index array
		wv = #() --weight value array
   
		for j = 1 to w.boneids.count do
		(
			boneid = w.boneids[j]
			weight = w.weights[j]
			append bi boneid
			append wv weight
		)   
   
		skinOps.ReplaceVertexWeights skinMod i bi wv
   
		)
		
if UV_Array2.count > 0 do(
		msh = mesh vertices:Vert_array faces:Face_array
		msh.numTVerts = UV_array2.count
		setNumCPVVerts msh msh.numTVerts
		setCVertMode msh true
		setShadeCVerts msh true
		defaultVCFaces msh
		for p = 1 to Color_array.count do(
		if UseVertAlpha == false then (setvertcolor msh p Color_array[p]) else (setvertcolor msh p [Alpha_array[p],Alpha_array[p],Alpha_array[p]])
		)
		buildTVFaces msh
		for j = 1 to UV_array2.count do setTVert msh j UV_array2[j]
		for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
		msh.name = (((bit.intAsHex(VertSize))as string) + " Layer 2")
		max modify mode
		select msh
		
      --set smoothing group of all faces to 1 to get one normal per vertex
      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
      --set normals via edit normals modifier
      select msh
      addmodifier msh (Edit_Normals ()) ui:off
      msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
      EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
      EN_setNormal = msh.Edit_Normals.SetNormal
      normID = #{}
      --apply normals
      for v = 1 to Normal_array.count do
      (
         free normID
         EN_convertVS #{v} &normID
         for id in normID do EN_setNormal id Normal_array[v]
      )

		skinMod = skin ()
		addModifier msh skinMod
		BoneCount = BoneArray.count
		for i = 1 to BoneCount do
		(
		maxbone = getnodebyname BoneArray[i].name
		if i != BoneCount then
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
   
		)

		modPanel.setCurrentObject skinMod

		for i = 1 to Weight_array.count do (
		w = Weight_array[i]
		bi = #() --bone index array
		wv = #() --weight value array
   
		for j = 1 to w.boneids.count do
		(
			boneid = w.boneids[j]
			weight = w.weights[j]
			append bi boneid
			append wv weight
		)   
   
		skinOps.ReplaceVertexWeights skinMod i bi wv
   
		)
)

		fseek f NextLink#seek_set
	)
	fseek f NL#seek_set
)
Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
fclose f
)
)

)

CreateDialog SegaNORollout