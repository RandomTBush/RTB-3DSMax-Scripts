-- Pokémon X/Y BCH model importer by Random Talking Bush.
-- If there are any problems, please contact me at The VG Resource (Random Talking Bush), Steam, Twitter or Tumblr (RandomTBush) so I can fix it up ASAP.
-- Last modified February 14th, 2016.

fname = getOpenFileName \ 
caption:"Pokemon X/Y file" \
types:"Pokemon X/Y models (*.bin/*.bch)|*.bin; *.bch" \
historyCategory:"PkmnXY"
if fname != undefined do(
clearlistener()
m = fopen fname "rb"
p = getFilenamePath fname

for a = 1 to 1 do (
Bone_Matrix_Array = #()
BoneName_array = #()
BoneArray = #()
TextureID_array = #()
MaterialNames_array = #()
TextureNames_array = #()
VertSize_array = #()
VertSize2_array = #()
VertFormat_array = #()
VertCount_array = #()
VertOffsetStart_array = #()
VertBytes_array = #()
PolySize_array = #()
FaceOffsetStart_array = #()
FaceCount_array = #()
NodeStart_array = #()
NodeIDOffset_array = #()
NodeIDSet_array = #()

struct Vertex_Bytes_Struct
(
	VertByte1, VertByte2, VertByte3, VertByte4
)
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

filestart = 0
headercheck = readshort m #unsigned
fseek m 0 #seek_set
if headercheck != 17218 do(
fseek m 0x04 #seek_cur
filestart = readlong m #unsigned
fseek m filestart #seek_set
)
print ("BCH header start: 0x"+((bit.intAsHex(ftell m))as string))
BCH = readlong m #unsigned
Unknown = readlong m #unsigned
NodesNSuchOffset = readlong m #unsigned + filestart
NamesOffset = readlong m #unsigned + filestart
DefinitionOffset = readlong m #unsigned + filestart
DataOffset = readlong m #unsigned + filestart
UnknownStuffOffset = readlong m #unsigned + filestart
	
NodesNSuchLength = readlong m #unsigned
NamesLength = readlong m #unsigned
DefinitionLength = readlong m #unsigned
DataLength = readlong m #unsigned
UnknownStuffLength = readlong m #unsigned

Unknown13 = readlong m #unsigned
Unknown14 = readlong m #unsigned

print ("First header chunk: 0x"+((bit.intAsHex(NodesNSuchOffset))as string))
print ("Strings header chunk: 0x"+((bit.intAsHex(NamesOffset))as string))
print ("Definition header chunk: 0x"+((bit.intAsHex(DefinitionOffset))as string))
print ("Data header chunk: 0x"+((bit.intAsHex(DataOffset))as string))
print ("Fifth header chunk: 0x"+((bit.intAsHex(UnknownStuffOffset))as string))


Data2Start = ftell m
print ("CC header chunk: 0x"+((bit.intAsHex(ftell m))as string))
SeaSea = readlong m #unsigned - 4
fseek m SeaSea #seek_cur
Data2Offset = readlong m #unsigned + Data2Start
fseek m Data2Offset #seek_set

print ("Data2 header chunk: 0x"+((bit.intAsHex(ftell m))as string))
fseek m 0x34 #seek_cur
TexTableOffset = readlong m #unsigned
TexTotal = readlong m #unsigned
fseek m 0x04 #seek_cur
PolyTableOffset = readlong m #unsigned
PolyTotal = readlong m #unsigned
PolyTotalB4 = PolyTotal
fseek m 0x14 #seek_cur
NodeIDOffset = readlong m #unsigned
fseek m 0x14 #seek_cur
BoneCount = readlong m #unsigned
print ("Bone count: " + BoneCount as string)
BoneOffsetThingy = readlong m #unsigned + NodesNSuchOffset
fseek m BoneOffsetThingy #seek_set

print ("Bones header: 0x"+((bit.intAsHex(ftell m))as string))
fseek m 0x0C #seek_cur
for b = 1 to BoneCount do(
fseek m 0x0C #seek_cur
)

print ("Bones start: 0x"+((bit.intAsHex(ftell m))as string))
for b = 1 to BoneCount Do (
BoneFlag1 = readbyte m #unsigned
BoneFlag2 = readbyte m #unsigned
BoneFlag3 = readbyte m #unsigned
BoneFlag4 = readbyte m #unsigned
BoneParent = readshort m
BoneSpacer = readshort m #unsigned
BoneSX = readfloat m; BoneSY = readfloat m; BoneSZ = readfloat m
BoneRX = readfloat m; BoneRY = readfloat m; BoneRZ = readfloat m
BoneTX = readfloat m; BoneTY = readfloat m; BoneTZ = readfloat m
m11 = readfloat m; m12 = readfloat m; m13 = readfloat m; m14= readfloat m
m21 = readfloat m; m22 = readfloat m; m23 = readfloat m; m24 = readfloat m
m31 = readfloat m; m32 = readfloat m; m33 = readfloat m; m34 = readfloat m
BoneNameOffset = readlong m #unsigned
BoneUnknown = readlong m #unsigned
brbk = ftell m
fseek m (NamesOffset + BoneNameOffset) #seek_set
BoneName = readstring m
append BoneName_array BoneName
fseek m brbk #seek_set
tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [BoneTX,BoneTY,BoneTZ]

if (getNodeByName BoneName) != undefined do (
append BoneArray (getNodeByName BoneName)
)
if (getNodeByName BoneName) == undefined do (
if (BoneParent != -1) do (
tfm2 = tfm * BoneArray[(BoneParent + 1)].objecttransform
tfm.row4 = tfm2.row4
)
)

newBone = bonesys.createbone	\
				  tfm.row4	\
				  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
				  (normalize tfm.row3)
-- 			if b < 10 do(BoneName = ("00" + b as string + " " + BoneName))
-- 			if b > 9 and b < 100 do(BoneName = "0" + b as string + " " + BoneName)
-- 			if b > 99 do(BoneName = b as string + " " + BoneName)
			newBone.name = BoneName
			newBone.width  = 0.01
			newBone.height = 0.01
			newBone.transform = tfm
			newBone.wirecolor = yellow
			newbone.showlinks = true
			newBone.setBoneEnable false 0
			newBone.pos.controller      = TCB_position ()
			newBone.rotation.controller = TCB_rotation ()
if (BoneParent != -1) then
newBone.parent = BoneArray[(BoneParent + 1)]
append BoneArray newBone
)
print ("Bones end: 0x"+((bit.intAsHex(ftell m))as string))
	
fseek m (Data2Start + TexTableOffset) #seek_set
print ("TextureTable start: 0x"+((bit.intAsHex(ftell m))as string))
for t = 1 to TexTotal do(
TextureNameOffset = readlong m #unsigned
fseek m 0x44 #seek_cur
DiffuseMapNameOffset = readlong m #unsigned
ShadowMapNameOffset = readlong m #unsigned
NormalMapNameOffset = readlong m #unsigned
MaterialNameOffset = readlong m #unsigned
brbk = ftell m
fseek m (NamesOffset + MaterialNameOffset) #seek_set
MaterialName = readstring m
append MaterialNames_array MaterialName
fseek m (NamesOffset + DiffuseMapNameOffset) #seek_set
DiffuseName = readstring m
if headercheck != 19789 do(append TextureNames_array DiffuseName)
fseek m (NamesOffset + ShadowMapNameOffset) #seek_set
DiffuseName = readstring m
if headercheck == 19789 do(append TextureNames_array DiffuseName)
fseek m brbk #seek_set
)

fseek m (Data2Start + PolyTableOffset) #seek_set

for t = 1 to PolyTotal do(
print ("PolyTable entry #" + t as string + " start: 0x"+((bit.intAsHex(ftell m))as string))
TextureID = readlong m #unsigned + 1
append TextureID_array TextureID
VisibilityGroup = readlong m #unsigned
VertexInfoStart = readlong m #unsigned
VertSize2 = readlong m #unsigned
append VertSize2_array VertSize2
PolyHeader = readlong m #unsigned
PolySize = readlong m #unsigned
print ("Polygon cluster = " + PolySize as string)
append PolySize_array PolySize
VertexHeader3 = readlong m #unsigned
VertexSize3 = readlong m #unsigned
fseek m 0x14 #seek_cur
NodeHeader = readlong m #unsigned + 0x04 + filestart
append NodeStart_array NodeHeader
brbk = ftell m
fseek m (DefinitionOffset + VertexInfoStart) #seek_set

print ("Vertex Offset Start: 0x"+((bit.intAsHex(ftell m))as string))
fseek m 0x28 #seek_cur
VertByte1 = readbyte m #unsigned
VertByte2 = readbyte m #unsigned
VertByte3 = readbyte m #unsigned
VertByte4 = readbyte m #unsigned
append VertBytes_array (Vertex_Bytes_Struct VertByte1:VertByte1 VertByte2:VertByte2 VertByte3:VertByte3 VertByte4:VertByte4)
	
fseek m 0x04 #seek_cur
VertOffsetStart = readlong m #unsigned + DataOffset
append VertOffsetStart_array VertOffsetStart
fseek m 0x06 #seek_cur
VertSize = readbyte m #unsigned
append VertSize_array VertSize
VertSize3 = readbyte m #unsigned

fseek m (DefinitionOffset + VertexHeader3) #seek_set
fseek m -0x60 #seek_cur
print ("Face Offset Start #1: 0x"+((bit.intAsHex(ftell m))as string))
VertexBytes = readlong m #unsigned
append VertFormat_array VertexBytes
fseek m 0x0C #seek_cur
FaceOffsetStart = readlong m #unsigned + DataOffset
append FaceOffsetStart_array FaceOffsetStart
fseek m 0x04 #seek_cur
FaceCount = (readlong m #unsigned / 3)
append FaceCount_array FaceCount
VertCount = (FaceOffsetStart - VertOffsetStart) / VertSize
append VertCount_array VertCount

if PolySize > 1 do(
for x = 1 to (PolySize - 1) do(
append VertBytes_array (Vertex_Bytes_Struct VertByte1:VertByte1 VertByte2:VertByte2 VertByte3:VertByte3 VertByte4:VertByte4)
append TextureID_array TextureID
append VertOffsetStart_array VertOffsetStart
append VertSize_array VertSize
append VertSize2_array VertSize2
fseek m (DefinitionOffset + VertexHeader3) #seek_set
fseek m -0x60 #seek_cur
fseek m (-0x60 * x) #seek_cur
print ("Face Offset Start #" + (x + 1) as string + ": 0x"+((bit.intAsHex(ftell m))as string))
VertexBytes = readlong m #unsigned
append VertFormat_array VertexBytes
fseek m 0x0C #seek_cur
FaceOffsetStart = readlong m #unsigned + DataOffset
append FaceOffsetStart_array FaceOffsetStart
fseek m 0x04 #seek_cur
FaceCount = (readlong m #unsigned / 3)
append FaceCount_array FaceCount
append VertCount_array VertCount
PolyTotal = PolyTotal + 1
)
)

fseek m brbk #seek_set
)

for n = 1 to PolyTotalB4 do(
fseek m NodeStart_array[n] #seek_set

append NodeIDOffset_array (ftell m)

for p = 1 to (PolySize_array[n] - 1) do(
fseek m -0x34 #seek_cur
append NodeIDOffset_array (ftell m)
)

)

for z = 1 to PolyTotal do(
Face_array = #()
Vert_array = #()
Normal_array = #()
Color_array = #()
Alpha_array = #()
UV_array = #()
UV2_array = #()
UV3_array = #()
B1_array = #()
W1_array = #()
Weight_array = #()
NodeID_array = #()
fseek m NodeIDOffset_array[z] #seek_set

print ("NodeIDTable entry #" + z as string + " start: 0x"+((bit.intAsHex(ftell m))as string))
fseek m 0x02 #seek_cur
NodeTotal = readshort m #unsigned
for o = 1 to NodeTotal do(
NodeID = readshort m #unsigned + 1
append NodeID_array NodeID
)

for n = 1 to NodeID_array.count do(
print (BoneName_array[NodeID_array[n]])
)

fseek m VertOffsetStart_array[z] #seek_set
vertsize = VertSize_array[z]
vertsize2 = VertSize2_array[z]
vertcount = VertCount_array[z]
print ("Polygon #" + z as string + "'s vertex amount: " + vertcount as string)
print ("Polygon #" + z as string + "'s vertex size / size2 / format: 0x"+((bit.intAsHex(vertsize))as string) + " / 0x"+((bit.intAsHex(vertsize2))as string) + " / 0x"+((bit.intAsHex(vertformat_array[z]))as string))
print ("Polygon #" + z as string + "'s vertex start: 0x"+((bit.intAsHex(ftell m))as string))
print ("Polygon #" + z as string + "'s bytes:")
print VertBytes_array[z]
for v = 1 to vertcount do(
		if VertBytes_array[z].VertByte1 == 0 and VertBytes_array[z].VertByte2 == 0 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
	if NodeTotal < 5 then(
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 0 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = 0
			Bone3 = 0
			Bone4 = 0
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 11 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = 0
			Bone3 = 0
			Bone4 = 0
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 13 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 155 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
-- 			if tv == 0x00000000 do(
-- 				tu = nx
-- 				tv = ny
-- 			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 157 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 219 and VertBytes_array[z].VertByte3 == 5 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 219 and VertBytes_array[z].VertByte3 == 9 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 0 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = 0
			tv = 0
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = 0
			Bone3 = 0
			Bone4 = 0
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 7 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = 0
			Bone3 = 0
			Bone4 = 0
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 9 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = 0
			tv = 0
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 13 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = 0
			tv = 0
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 87 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 87 and VertBytes_array[z].VertByte3 == 5 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = 0
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 119 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			tu2 = readfloat m
			tv2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = 0
			Bone3 = 0
			Bone4 = 0
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append UV2_array[tu2, tv2, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 119 and VertBytes_array[z].VertByte3 == 5 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			tu2 = readfloat m
			tv2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append UV2_array[tu2, tv2, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 119 and VertBytes_array[z].VertByte3 == 157 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			tu2 = readfloat m
			tv2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append UV2_array[tu2, tv2, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 119 and VertBytes_array[z].VertByte3 == 215 and VertBytes_array[z].VertByte4 == 5 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			tu2 = readfloat m
			tv2 = readfloat m
			tu3 = readfloat m
			tv3 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append UV2_array[tu2, tv2, 0]
			append UV3_array[tu3, tv3, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 151 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 151 and VertBytes_array[z].VertByte3 == 9 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = 0
			Bone3 = 0
			Bone4 = 0
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 5 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 9 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 13 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 93 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 157 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 199 and VertBytes_array[z].VertByte3 == 153 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 199 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 5 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 9 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 13 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 153 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 219 and VertBytes_array[z].VertByte2 == 5 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = 0
			tv = 0
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = NodeID_array[1]
			Bone2 = NodeID_array[2]
			Bone3 = NodeID_array[3]
			Bone4 = NodeID_array[4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
	)
	else (
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 85 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = 0
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 153 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 123 and VertBytes_array[z].VertByte2 == 221 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = readfloat m
			tv = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 87 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 87 and VertBytes_array[z].VertByte3 == 5 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = 0
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 119 and VertBytes_array[z].VertByte3 == 153 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			tu2 = readfloat m
			tv2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append UV2_array[tu2, tv2, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 119 and VertBytes_array[z].VertByte3 == 215 and VertBytes_array[z].VertByte4 == 221 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			tu2 = readfloat m
			tv2 = readfloat m
			tu3 = readfloat m
			tv3 = readfloat m
			if vx < -2000 or vx > 2000 do(exit)
			if vy < -2000 or vy > 2000 do(exit)
			if vz < -2000 or vz > 2000 do(exit)
			if nx < -2000 or nx > 2000 do(exit)
			if ny < -2000 or ny > 2000 do(exit)
			if nz < -2000 or nz > 2000 do(exit)
			if tu < -2000 or tu > 2000 do(exit)
			if tv < -2000 or tv > 2000 do(exit)
			if tu2 < -2000 or tu2 > 2000 do(exit)
			if tv2 < -2000 or tv2 > 2000 do(exit)
			if tu3 < -2000 or tu3 > 2000 do(exit)
			if tv3 < -2000 or tv3 > 2000 do(exit)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append UV2_array[tu2, tv2, 0]
			append UV3_array[tu3, tv3, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 119 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			tu2 = readfloat m
			tv2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append UV2_array[tu2, tv2, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 151 and VertBytes_array[z].VertByte3 == 9 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 85 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = 0
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 93 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 93 and VertBytes_array[z].VertByte4 == 5 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = 0
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 153 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 157 and VertBytes_array[z].VertByte4 == 9 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 183 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 13 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			nx2 = readfloat m
			ny2 = readfloat m
			nz2 = readfloat m
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 199 and VertBytes_array[z].VertByte3 == 153 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 199 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 5 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = 1
			Weight2 = 0
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 13 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 85 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = 0
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 153 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = 0
			fseek m 0x02 #seek_cur
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 215 and VertBytes_array[z].VertByte3 == 221 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = readfloat m
			tv = readfloat m
			if tv == 0x00000000 do(
				tu = nx
				tv = ny
			)
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 187 and VertBytes_array[z].VertByte2 == 221 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			nx = readfloat m
			ny = readfloat m
			nz = readfloat m
			tu = 0
			tv = 0
			colorr = 255
			colorg = 255
			colorb = 255
			colora = 1
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append Normal_array[nx, ny, nz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 219 and VertBytes_array[z].VertByte2 == 85 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = 0
			tv = 0
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = 0
			Bone4 = 0
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = 0
			Weight4 = 0
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
		if VertBytes_array[z].VertByte1 == 219 and VertBytes_array[z].VertByte2 == 221 and VertBytes_array[z].VertByte3 == 0 and VertBytes_array[z].VertByte4 == 0 do(
			vx = readfloat m
			vy = readfloat m
			vz = readfloat m
			tu = 0
			tv = 0
			colorr = readbyte m #unsigned
			colorg = readbyte m #unsigned
			colorb = readbyte m #unsigned
			colora = (readbyte m #unsigned) as float / 255
			Bone1 = readbyte m #unsigned + 1
			Bone1 = NodeID_array[Bone1]
			Bone2 = readbyte m #unsigned + 1
			Bone2 = NodeID_array[Bone2]
			Bone3 = readbyte m #unsigned + 1
			Bone3 = NodeID_array[Bone3]
			Bone4 = readbyte m #unsigned + 1
			Bone4 = NodeID_array[Bone4]
			Weight1 = readbyte m #unsigned as float / 100
			Weight2 = readbyte m #unsigned as float / 100
			Weight3 = readbyte m #unsigned as float / 100
			Weight4 = readbyte m #unsigned as float / 100
			append Vert_array[vx, vy, vz]
			append UV_array[tu, tv, 0]
			append Color_Array[colorr,colorg,colorb]
			append Alpha_Array colora
			append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
			append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
		)
	)
)
print ("Vertex end: 0x"+((bit.intAsHex(ftell m))as string))

fseek m FaceOffsetStart_array[z] #seek_set
FaceCount = FaceCount_array[z]
print ("Face amount: " + facecount as string)
print ("Face start: 0x"+((bit.intAsHex(ftell m))as string))

onebytepoly = #()
if vertcount > 256 do(
for x = 1 to facecount do(
if onebytepoly != 1 do(
fa = readshort m #unsigned + 1
fb = readshort m #unsigned + 1
fc = readshort m #unsigned + 1
append Face_array[fa, fb, fc]
if fa > vertcount do(
onebytepoly = 1
)
)
)
)
if vertcount <= 256 or onebytepoly == 1 do(
if onebytepoly == 1 do (
fseek m FaceOffsetStart_array[z] #seek_set
Face_array = #()
)
for x = 1 to facecount do(
fa = readbyte m #unsigned + 1
fb = readbyte m #unsigned + 1
fc = readbyte m #unsigned + 1
append Face_array[fa, fb, fc]
)
)

print ("Face end: 0x"+((bit.intAsHex(ftell m))as string))

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

PolyTextureID = TextureID_array[z]
mat = standardMaterial()
mat.name = MaterialNames_array[PolyTextureID]
mat.showinviewport = true
mat.twosided = false
tm = Bitmaptexture filename:(p + "/textures/" + TextureNames_array[PolyTextureID] + ".png")
tm.alphasource = 2
mat.diffuseMap = tm

msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = Vert_array.count
setNumCPVVerts msh msh.numTVerts
setCVertMode msh true
setShadeCVerts msh true
defaultVCFaces msh
buildTVFaces msh
msh.name = "Mesh " + z as string + " (" + MaterialNames_array[PolyTextureID] as string + ")"
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

	for v = 1 to Normal_array.count do(
		free normID
		EN_convertVS #{v} &normID
		for id in normID do EN_setNormal id Normal_array[v]
	)

if BoneCount > 0 do(
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to BoneCount do	(
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

if UV2_array.count > 0 do(
msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = Vert_array.count
setNumCPVVerts msh msh.numTVerts
setCVertMode msh true
setShadeCVerts msh true
defaultVCFaces msh
buildTVFaces msh
msh.name = "Mesh " + z as string + " (" + MaterialNames_array[PolyTextureID] as string + ") Layer 2"
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

	for v = 1 to Normal_array.count do(
		free normID
		EN_convertVS #{v} &normID
		for id in normID do EN_setNormal id Normal_array[v]
	)

if BoneCount > 0 do(
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to BoneCount do	(
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
	
)

if UV3_array.count > 0 do(
msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = Vert_array.count
setNumCPVVerts msh msh.numTVerts
setCVertMode msh true
setShadeCVerts msh true
defaultVCFaces msh
buildTVFaces msh
msh.name = "Mesh " + z as string + " (" + MaterialNames_array[PolyTextureID] as string + ") Layer 3"
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

	for v = 1 to Normal_array.count do(
		free normID
		EN_convertVS #{v} &normID
		for id in normID do EN_setNormal id Normal_array[v]
	)

if BoneCount > 0 do(
		skinMod = skin ()
		addModifier msh skinMod
		for i = 1 to BoneCount do	(
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
	
)
	
)

)

gc()
fclose m
)
