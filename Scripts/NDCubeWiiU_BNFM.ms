-- ND Cube model importer (Animal Crossing: amiibo Festival, Mario Party 10 and Wii Party U) by Random Talking Bush.
-- If there are any problems, please contact me at The VG Resource (Random Talking Bush), Steam, Twitter or Tumblr (RandomTBush) so I can fix it up ASAP.
-- Last modified January 10th, 2016.

fname = getOpenFileName \ 
caption:"ND Cube BNFM file" \
types:"ND Cube Wii U Model (*.BNFM)|*.BNFM" \
historyCategory:"MarioParty10"

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
)

fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)

if fname != undefined do(
t = getFilenameType fname
p = getFilenamePath fname
h = getFilenameFile fname
m = fopen fname "rb"
clearlistener()
for a = 1 to 1 do (
BoneName_array = #()
BoneParent_array = #()
BNArr = #()
String_array = #()
FaceStart_array = #()
PolyStart_array = #()
VertStart_array = #()
BoneChartStart_array = #()
PolyNameStart_array = #()
FaceCount_array = #()
VertCount_array = #()
PolyGroupCount_array = #()
MatNameStart_array = #()
Mat2NameStart_array = #()
MatNum_array = #()
PolyName_array = #()

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
fseek m 0x00 #seek_fcur

HeaderCheck = readBElong m
HeaderStart = readBElong m
Blank = readBElong m
FaceStart = readBElong m

FaceTotal = (readBElong m) / 6
VertCount = readBElong m / 44
BoneChartStart = readBElong m
Unknown = readBElong m

VertStart = readBElong m
FaceStartB = readBElong m
Unknown = readBElong m
PolyNameCount = readBElong m

BoneCount = readBElong m
PolyCount = readBElong m
MatCount = readBElong m / 6
PolyNameCountB = readBElong m

PolyNameCountC = readBElong m
BoneChartCount = readBElong m
BoneChartCountB = readBElong m
StringCount = readBElong m

UnknownStart = readBElong m
Unknown = readBElong m
BoneStart = readBElong m
PolyInfoStart = readBElong m

MaterialStart = readBElong m
UnknownStart = readBElong m
Material2Start = readBElong m
BoneMatrixStart = readBElong m

BoneMatrixStart = readBElong m
StringStart = readBElong m

fseek m BoneStart #seek_set

for x = 1 to BoneCount do(
BoneParent = -1
BoneNameStart = readBElong m
BoneReturn = ftell m
fseek m BoneNameStart #seek_set
BoneName = readstring m
append BoneName_array BoneName
fseek m BoneReturn #seek_set
fseek m 0x04 #seek_cur
BoneParentNameStart = readBElong m
BoneReturn = ftell m
fseek m BoneParentNameStart #seek_set
BoneParentName = readstring m
fseek m BoneReturn #seek_set
for y = 1 to BoneName_array.count do(
if BoneParentName == BoneName_array[y] do(BoneParent = y)
)
fseek m 0x18 #seek_cur
PosX = readBEfloat m
PosY = readBEfloat m
PosZ = readBEfloat m
ScaleX = readBEfloat m
ScaleY = readBEfloat m
ScaleZ = readBEfloat m
fseek m 0x14 #seek_cur
m11 = readBEfloat m
m12 = readBEfloat m
m13 = readBEfloat m
m14 = readBEfloat m
m21 = readBEfloat m
m22 = readBEfloat m
m23 = readBEfloat m
m24 = readBEfloat m
m31 = readBEfloat m
m32 = readBEfloat m
m33 = readBEfloat m
m34 = readBEfloat m
m41 = readBEfloat m
m42 = readBEfloat m
m43 = readBEfloat m
m44 = readBEfloat m
m51 = readBEfloat m
m52 = readBEfloat m
m53 = readBEfloat m
m54 = readBEfloat m
m61 = readBEfloat m
m62 = readBEfloat m
m63 = readBEfloat m
m64 = readBEfloat m
m71 = readBEfloat m
m72 = readBEfloat m
m73 = readBEfloat m
m74 = readBEfloat m
m81 = readBEfloat m
m82 = readBEfloat m
m83 = readBEfloat m
m84 = readBEfloat m
fseek m 0x0C #seek_cur
tfm = inverse(matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43])
tfm.row4 = [PosX,PosY,PosZ]

if (getNodeByName BoneName) != undefined do (
append BNArr (getNodeByName BoneName)
)
if (getNodeByName BoneName) == undefined do (
if (BoneParent != -1) do (
tfm = tfm * BNArr[(BoneParent)].objecttransform
)
)

newBone = bonesys.createbone   \
              tfm.row4   \
              (tfm.row4 + 0.01 * (normalize tfm.row1)) \
              (normalize tfm.row3)
         newBone.name = BoneName
         newBone.width  = 0.01
         newBone.height = 0.01
         newBone.transform = tfm
         newBone.setBoneEnable false 0
         newBone.wirecolor = yellow
         newbone.showlinks = true
         newBone.pos.controller      = TCB_position ()
         newBone.rotation.controller = TCB_rotation ()
if (BoneParent != -1) then
newBone.parent = BNArr[(BoneParent)]
append BNArr newBone
)

fseek m PolyInfoStart #seek_set
for x = 1 to PolyCount do(
PolyNameStart = readBElong m
fseek m 0x04 #seek_cur
BoneChartStart = readBElong m
PolyStart = readBElong m
fseek m 0x08 #seek_cur
FaceCount = readBElong m / 3
PolyVertCount = readBElong m
BoneIDCount = readBElong m
MatID = readBElong m
fseek m 0x08 #seek_cur
append PolyNameStart_array PolyNameStart
append BoneChartStart_array BoneChartStart
append PolyStart_array PolyStart
append FaceCount_array FaceCount
append VertCount_array PolyVertCount
)

fseek m MaterialStart #seek_set
for x = 1 to MatCount do(
MatNameStart = readBElong m
fseek m 0x110 #seek_cur
Mat2NameStart = readBElong m
fseek m 0x110 #seek_cur
append MatNameStart_array MatNameStart
append Mat2NameStart_array Mat2NameStart
)

fseek m Material2Start #seek_set
for x = 1 to MatCount do(
PolyNameStart = readBElong m
PolyReturn = ftell m
fseek m PolyNameStart #seek_set
PolyName = readstring m
fseek m PolyReturn #seek_set
fseek m 0x38 #seek_cur
append PolyName_array PolyName
)

VertReturn = VertStart
Vert_array = #()
Normal_array = #()
UV_array = #()
UV2_array = #()
B0_array = #()
W1_array = #()

for z = 1 to PolyCount do(
B1_array = #()
Face_array = #()
Color_array = #()
Weight_array = #()
BoneChart_array = #()

fseek m BoneChartStart_array[z] #seek_set

for x = 1 to BoneChartCount do(
BoneID = readBElong m + 1
append BoneChart_array BoneID
)

if VertCount_array[z] != 0 do(
Vert_array = #()
Normal_array = #()
UV_array = #()
UV2_array = #()
B0_array = #()
W1_array = #()
fseek m VertReturn #seek_set
for x = 1 to VertCount_array[z] do(
vx = readBEfloat m
vy = readBEfloat m
vz = readBEfloat m
unknown1 = readBEfloat m
colorr = readbyte m #unsigned
colorg = readbyte m #unsigned
colorb = readbyte m #unsigned
colora = readbyte m #unsigned
tu = readBEhalffloat m
tv = readBEhalffloat m
tu2 = readBEhalffloat m
tv2 = readBEhalffloat m
Bone1 = readbyte m #unsigned + 1
Bone2 = readbyte m #unsigned + 1
Bone3 = readbyte m #unsigned + 1
Bone4 = readbyte m #unsigned + 1
Weight1 = (readbyte m #unsigned as float) / 255
Weight2 = (readbyte m #unsigned as float) / 255
Weight3 = (readbyte m #unsigned as float) / 255
Weight4 = (readbyte m #unsigned as float) / 255
unknown2 = readBEfloat m
unknown3 = readBEfloat m

append Vert_array[vx, vy, vz]
-- append Normal_array[nx, ny, nz]
append UV_array[tu, tv, 0]
append UV2_array[tu2, tv2, 0]
append Color_Array[colorr,colorg,colorb]
append B0_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
)
VertReturn = (ftell m)
)

fseek m FaceStart #seek_set
fseek m PolyStart_array[z] #seek_cur

for x = 1 to FaceCount_array[z] do(
fa = (readBEword m + 1)
fb = (readBEword m + 1)
fc = (readBEword m + 1)
append Face_array[fa, fb, fc]
)

for x = 1 to Vert_array.count do(
	ImproperBone1 = B0_array[x].Bone1
	ImproperBone2 = B0_array[x].Bone2
	ImproperBone3 = B0_array[x].Bone3
	ImproperBone4 = B0_array[x].Bone4
	Bone1 = BoneChart_array[ImproperBone1]
	Bone2 = BoneChart_array[ImproperBone2]
	Bone3 = BoneChart_array[ImproperBone3]
	Bone4 = BoneChart_array[ImproperBone4]
	if Bone1 == undefined or Bone1 > BoneCount do(Bone1 = 1)
	if Bone2 == undefined or Bone2 > BoneCount do(Bone2 = 1)
	if Bone3 == undefined or Bone3 > BoneCount do(Bone3 = 1)
	if Bone4 == undefined or Bone4 > BoneCount do(Bone4 = 1)
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
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

MatID = 1
fseek m PolyNameStart_array[z] #seek_set
PolyName = readstring m
for y = 1 to PolyNameCount do(
if PolyName == PolyName_array[y] do(MatID = y)
)
fseek m MatNameStart_array[MatID] #seek_set
MatName = readstring m
mat = standardMaterial()
mat.name = MatName
mat.showinviewport = true
mat.twosided = false
tm = Bitmaptexture filename:(p + MatName + ".dds")
tm.alphasource = 2
mat.diffuseMap = tm
msh = mesh vertices:Vert_array faces:Face_array
msh.material = mat
msh.numTVerts = Vert_array.count
buildTVFaces msh
msh.name = PolyName
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
max modify mode
select msh

      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1

--       select msh
--       addmodifier msh (Edit_Normals ()) ui:off
--       msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
--       EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
--       EN_setNormal = msh.Edit_Normals.SetNormal
--       normID = #{}
--       --apply normals
--       for v = 1 to Normal_array.count do
--       (
--          free normID
--          EN_convertVS #{v} &normID
--          for id in normID do EN_setNormal id Normal_array[v]
--       )

if BoneCount > 0 do(
skinMod = skin ()
addModifier msh skinMod
for i = 1 to BoneCount do
(
   maxbone = getnodebyname BNArr[i].name
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

fseek m Mat2NameStart_array[MatID] #seek_set
MatName = readstring m

if MatName != "" do(
mat = standardMaterial()
mat.name = MatName
mat.showinviewport = true
mat.twosided = false
tm = Bitmaptexture filename:(p + MatName + ".dds")
tm.alphasource = 2
mat.diffuseMap = tm
msh = mesh vertices:Vert_array faces:Face_array
msh.material = mat
msh.numTVerts = Vert_array.count
buildTVFaces msh
msh.name = PolyName + " (Layer 2)"
for j = 1 to UV2_array.count do setTVert msh j UV2_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
max modify mode
select msh

      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1

--       select msh
--       addmodifier msh (Edit_Normals ()) ui:off
--       msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
--       EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
--       EN_setNormal = msh.Edit_Normals.SetNormal
--       normID = #{}
--       --apply normals
--       for v = 1 to Normal_array.count do
--       (
--          free normID
--          EN_convertVS #{v} &normID
--          for id in normID do EN_setNormal id Normal_array[v]
--       )

if BoneCount > 0 do(
skinMod = skin ()
addModifier msh skinMod
for i = 1 to BoneCount do
(
   maxbone = getnodebyname BNArr[i].name
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
)

gc()
fclose m