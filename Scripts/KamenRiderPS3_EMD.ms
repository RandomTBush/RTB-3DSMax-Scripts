-- Script written up by Random Talking Bush.
-- If used, I wouldn't mind getting some thanks out of it.
-- That rigging information wasn't fun to fix up.
-- Yes, I borrowed a couple of things from other scripts, partly
-- because I didn't know how to set up most things myself. Sorry.

if (heapSize < 20000000) then
	heapSize = 200000000 -- allow ~ 40 MB instead of just 7.5 MB. Prevents "Runtime Error: Out of scripter memory"

fname = getOpenFileName \ 
caption:"Kamen Rider Battride War Model File" \
types:"Kamen Rider Battride War Model File(*.EMD)|*.EMD" \
historyCategory:"KRBWEMDObjectPresets"
f = fopen fname "rb"
p = getFilenamePath fname -- return the path "c:\\test\\"
g = getFilenameFile fname -- return the file "test"
clearlistener()

fn floatSwap2 f = (
	i = bit.floatAsInt f
	h = bit.intashex i
	while h.count < 8 do h = "0" + h
	
	s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
	bit.intAsFloat (bit.hexasint s)
)	

fn ReadBEword fstream = (
	return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)

fn convertTo32 input16 = (
	inputAsInt = input16
	sign = bit.get inputAsInt 16
	exponent = (bit.shift (bit.and inputAsInt (bit.hexasint "7C00")) -10) as integer - 16
	fraction = bit.and inputAsInt (bit.hexasint "03FF")
	if sign==true then sign = 1 else sign = 0
	exponentF = exponent + 127
	--Ouput 32 bit integer representing a 32 bit float
	outputAsFloat = bit.or (bit.or (bit.shift fraction 13) (bit.shift exponentF 23)) (bit.shift sign 31)
	--Output Check	
	return bit.intasfloat outputasfloat
)

fn ReadBEHalfFloat fstream = (
	return convertTo32(ReadBEword fstream)
)

fn ReadBElong fstream = (
	long = readlong fstream
	long = bit.swapBytes long 1 4
	long = bit.swapBytes long 2 3
	return long
)

fn ReadBEfloat fstream = (
	return floatSwap2(readfloat fstream)
)

for a = 1 to 1 do (
Bone_Matrix_array = #()
BNArr = #()
MatName_array = #()
SubMatName_array = #()
NodeID_array = #()
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

fseek f 0x24 #seek_set
PolygonCount = ReadBElong f
nothing = ReadBElong f
BoneCount = ReadBElong f
MatCount = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
something = ReadBElong f
something = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
PolygonOffset = ReadBElong f
nothing = ReadBElong f
BoneOffset = ReadBElong f
MaterialsOffset = ReadBElong f
UVOffset = ReadBElong f
UVOffsetMinus10 = ReadBElong f
UVOffsetLength = ReadBElong f
fseek f BoneOffset #seek_set
if BoneCount != 0 do(
for x = 1 to BoneCount Do (
headerthing1 = readBEword f
headerthing2 = readBEword f
headerlength = ReadBElong f
bonenum = ReadBElong f
floaty = readBEfloat f
jump = (ftell f as integer) + 32
BoneName = readstring f
fseek f jump #seek_set
fseek f 0xE0 #seek_cur
BoneParent = ReadBElong f
bonechildren = ReadBElong f
nodeID = ReadBElong f + 1
append nodeID_array nodeID
internalnum = ReadBElong f
m11 = ReadBEfloat f; m12 = ReadBEfloat f; m13 = ReadBEfloat f; m14 = ReadBEfloat f
m21 = ReadBEfloat f; m22 = ReadBEfloat f; m23 = ReadBEfloat f; m24 = ReadBEfloat f
m31 = ReadBEfloat f; m32 = ReadBEfloat f; m33 = ReadBEfloat f; m34 = ReadBEfloat f
m41 = ReadBEfloat f; m42 = ReadBEfloat f; m43 = ReadBEfloat f; m44 = ReadBEfloat f
m51 = ReadBEfloat f; m52 = ReadBEfloat f; m53 = ReadBEfloat f; m54 = ReadBEfloat f
m61 = ReadBEfloat f; m62 = ReadBEfloat f; m63 = ReadBEfloat f; m64 = ReadBEfloat f
m71 = ReadBEfloat f; m72 = ReadBEfloat f; m73 = ReadBEfloat f; m74 = ReadBEfloat f
m81 = ReadBEfloat f; m82 = ReadBEfloat f; m83 = ReadBEfloat f; m84 = ReadBEfloat f
tfm = (matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43])
if (getNodeByName BoneName) != undefined do (
append BNArr (getNodeByName BoneName)
)
if (getNodeByName BoneName) == undefined do (
if (BoneParent != -1) do (
tfm = tfm * BNArr[(boneparent + 1)].objecttransform
)
)
append Bone_Matrix_array tfm

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
newBone.parent = BNArr[(BoneParent + 1)]
append BNArr newBone
)
)

print "--------------------"
for x = 1 to MatCount Do (
headerthing = ReadBElong f
headerlength = ReadBElong f - 8
jumpmat1 = (ftell f as integer) + headerlength
materialnum = ReadBElong f
maybenothing = ReadBElong f
jumpmat2 = (ftell f as integer) + 540
MaterialName = readstring f
print MaterialName
append MatName_array MaterialName
fseek f jumpmat2 #seek_set
submaterialnum = ReadBElong f
if submaterialnum == 0 do(
	if g == "CCS00" and MaterialName == "CCS00eye02" do(SubMaterialName = "CCS00eye00_CO") -- This is to fix CCS00.emd
	if g == "KAB00" and MaterialName == "eye2" do(SubMaterialName = "KAB00eye00_CO") -- This is to fix KAB00.emd
	if g == "GAI01_W01" and MaterialName == "GAI01W04_base" do(SubMaterialName = "GAI01djgun00_CO") -- This is to fix KAB00.emd
	if SubMaterialName == undefined do(SubMaterialName = "null")
	print (SubMaterialName + " (supplemented texture)")
	append SubMatName_array SubMaterialName
)
fseek f jumpmat1 #seek_set
for y = 1 to submaterialnum Do (
subheaderthing = ReadBElong f
subheaderlength = ReadBElong f - 8
jumpsubmat1 = (ftell f as integer) + subheaderlength
submaterialnum = ReadBElong f
maybenothing = ReadBElong f
jumpsubmat2 = (ftell f as integer) + 256
SubMaterialName = readstring f
print SubMaterialName
if y == 1 do(append SubMatName_array SubMaterialName)
fseek f jumpsubmat2 #seek_set
float1 = readBEfloat f
materiallink = ReadBElong f
submaterialnum2 = ReadBElong f
maybenothing = ReadBElong f
fseek f jumpsubmat1 #seek_set
)

print "--------------------"
)
fseek f PolygonOffset #seek_set

for x = 1 to PolygonCount Do (
headerthing1 = readbyte f #unsigned
headerthing2 = readbyte f #unsigned
headerthing3 = readbyte f #unsigned
headerthing4 = readbyte f #unsigned
headerlength = ReadBElong f
headerjump = ((ftell f as integer) - 8) + headerlength
polynum = ReadBElong f
floaty = readBEfloat f
jump2 = (ftell f as integer) + 32
PolygonName = readstring f
fseek f jump2 #seek_set
fseek f 0xE0 #seek_cur
BoundXMin = readBEfloat f
BoundYMin = readBEfloat f
BoundZMin = readBEfloat f
nothing = ReadBElong f
BoundXMax = readBEfloat f
BoundYMax = readBEfloat f
BoundZMax = readBEfloat f
nothing = ReadBElong f
matgroupnum = readBEword f + 1
headerthing1 = readBEword f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f

groups = 1

if headerthing1 == 0x204 do (
groups = ReadBEword f
headerthing1 = readBEword f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f

anothermaybeusefuloffset = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
)

for g = 1 to groups do(
NodeFix_array = #()
Vert_array = #()
Normal_array = #()
Color_Array=#()
Alpha_Array=#()
UV_array = #()
Face_array = #()
W1_array = #()
B1_array = #()
Weight_array = #()

if g > 1 do (fseek f 0x50 #seek_cur)

seek = readlong f
while seek == 0 and seek != undefined do(seek = readlong f)
fseek f -0x04 #seek_cur
jump3 = (ftell f as integer)
polystart = ReadBElong f
polyjump = (jump3 + polystart)
polyamount = readBEword f
spacing = readBEword f
vertexstart = ReadBElong f
vertexjump = (jump3 + vertexstart)
maybenormals = ReadBElong f
vertamount = readBEword f
spacing = readBEword f
normalslength = ReadBElong f
somethingamount = readBEword f
spacing = readBEword f
somethingoffset = ReadBElong f
UVlength = ReadBElong f
NodeThing1 = (ReadBEword f / 0x30)
NodeThing2 = (ReadBEword f / 0x30)
NodeThing3 = (ReadBEword f / 0x30)
NodeThing4 = (ReadBEword f / 0x30)
UVamount = ReadBEword f
spacing = readBEword f
BoneWeightStart = ReadBElong f
BoneWeightJump = (jump3 + BoneWeightStart)
ActualUVStart = ReadBElong f
somekindaoffset = readBElong f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
nothing = ReadBElong f
anotheroffset1 = ReadBELong f
anotheroffsetlength1 = readBElong f
nothing = readBElong f
anotheroffset2 = ReadBELong f
anotheroffsetlength2 = readBElong f
nothing = readBElong f
nothing = readBElong f
polygonstartagain = readBElong f
nothing = readBElong f
nothing = readBElong f
bytechunk1 = readBEword f
bytechunk2 = readBEword f
bytechunk3 = readBEword f
bytechunk4 = readBEword f
pointamount = readBEword f
UVsize = (UVlength / 4) / pointamount
faceamount = readBEword f
end = readBElong f
	
fseek f polyjump #seek_set
for b = 1 to polyamount / 6 do(
f1 = ReadBEword f + 1
f2 = ReadBEword f + 1
f3 = ReadBEword f + 1
if b < (faceamount + 1) do(append Face_array [(f3),(f2),(f1)])
)

fseek f vertexjump #seek_set
for b = 1 to vertamount / 12 do(
vx = ReadBEfloat f
vy = ReadBEfloat f
vz = ReadBEfloat f
if b < (pointamount + 1) do(append Vert_array [vx,vy,vz])
)
seek = readlong f
while seek == 0 and seek != undefined do(seek = readlong f)
fseek f -0x04 #seek_cur

-- This is only a placeholdery thing. Ignore it.
for b = 1 to vertamount / 12 do(
nx = ReadBEFloat f
ny = ReadBEFloat f
nz = ReadBEFloat f
--if b < (pointamount + 1) do(append Normal_array [nx,ny,nz])
)

fseek f UVOffset #seek_set

for b = 1 to pointamount do(
	if UVsize == 2 do(
	colora = ReadByte f #unsigned
	colorr = ReadByte f #unsigned
	colorg = ReadByte f #unsigned
	colorb = ReadByte f #unsigned
	tu = (ReadBEHalfFloat f) * 2
	tv = ((ReadBEHalfFloat f) * -2) + 1
	append Color_array [colorr, colorg, colorb]
	append Alpha_array colora
	append UV_array [tu, tv, 0]
	)
	if UVsize == 3 do(
	colora = ReadByte f #unsigned
	colorr = ReadByte f #unsigned
	colorg = ReadByte f #unsigned
	colorb = ReadByte f #unsigned
	tu = (ReadBEHalfFloat f) * 2
	tv = ((ReadBEHalfFloat f) * -2) + 1
	tu2 = (ReadBEHalfFloat f) * 2
	tv2 = ((ReadBEHalfFloat f) * -2) + 1
	append Color_array [colorr, colorg, colorb]
	append Alpha_array colora
	append UV_array [tu, tv, 0]
	)
	if UVsize == 4 do(
	colora = ReadByte f #unsigned
	colorr = ReadByte f #unsigned
	colorg = ReadByte f #unsigned
	colorb = ReadByte f #unsigned
	tu = (ReadBEHalfFloat f) * 2
	tv = ((ReadBEHalfFloat f) * -2) + 1
	tu2 = (ReadBEHalfFloat f) * 2
	tv2 = ((ReadBEHalfFloat f) * -2) + 1
	tu3 = (ReadBEHalfFloat f) * 2
	tv3 = ((ReadBEHalfFloat f) * -2) + 1
	append Color_array [colorr, colorg, colorb]
	append Alpha_array colora
	append UV_array [tu, tv, 0]
	)
	if UVsize == 5 do(
	tu = (ReadBEHalfFloat f) * 2
	tv = ((ReadBEHalfFloat f) * -2) + 1
	tu2 = (ReadBEHalfFloat f) * 2
	tv2 = ((ReadBEHalfFloat f) * -2) + 1
	tu3 = (ReadBEHalfFloat f) * 2
	tv3 = ((ReadBEHalfFloat f) * -2) + 1
	colora = ReadByte f #unsigned
	colorr = ReadByte f #unsigned
	colorg = ReadByte f #unsigned
	colorb = ReadByte f #unsigned
	tu4 = (ReadBEHalfFloat f) * 2
	tv4 = ((ReadBEHalfFloat f) * -2) + 1
	append Color_array [colorr, colorg, colorb]
	append Alpha_array colora
	append UV_array [tu4, tv4, 0]
	)
	if UVsize == 6 do(
	tu = (ReadBEHalfFloat f) * 2
	tv = ((ReadBEHalfFloat f) * -2) + 1
	tu2 = (ReadBEHalfFloat f) * 2
	tv2 = ((ReadBEHalfFloat f) * -2) + 1
	tu3 = (ReadBEHalfFloat f) * 2
	tv3 = ((ReadBEHalfFloat f) * -2) + 1
	colora = ReadByte f #unsigned
	colorr = ReadByte f #unsigned
	colorg = ReadByte f #unsigned
	colorb = ReadByte f #unsigned
	tu4 = (ReadBEHalfFloat f) * 2
	tv4 = ((ReadBEHalfFloat f) * -2) + 1
	tu5 = (ReadBEHalfFloat f) * 2
	tv5 = ((ReadBEHalfFloat f) * -2) + 1
	append Color_array [colorr, colorg, colorb]
	append Alpha_array colora
	append UV_array [tu4, tv4, 0]
	)
)

seek = readlong f
while seek == 0 and seek != undefined do(seek = readlong f)
fseek f -0x04 #seek_cur

UVOffset = (ftell f as integer)

if BoneCount != 0 do(
fseek f BoneWeightJump #seek_set
for b = 1 to Vert_array.count do(
Weight1 = (readbyte f #unsigned as float / 255)
Bone1 = #()
IDB1 = (readbyte f #unsigned) + 1
ID1 = IDB1 + NodeThing1

if IDB1 >= (NodeThing3 + 1) do(
ID1 = IDB1 + NodeThing2 - NodeThing3
)

for c = 1 to NodeID_array.count do(
	if ID1 == NodeID_array[c] do(
	Bone1 = c
	)
)

Weight2 = (readbyte f #unsigned as float / 255)
Bone2 = #()
IDB2 = (readbyte f #unsigned) + 1
ID2 = IDB2 + NodeThing1

if IDB2 >= (NodeThing3 + 1) do(
ID2 = IDB2 + NodeThing2 - NodeThing3
)

for c = 1 to NodeID_array.count do(
	if ID2 == NodeID_array[c] do(
	Bone2 = c
	)
)

Weight3 = (readbyte f #unsigned as float / 255)
IDB3 = (readbyte f #unsigned) + 1
ID3 = IDB3 + NodeThing1
Bone3 = #()

if IDB3 >= (NodeThing3 + 1) do(
ID3 = IDB3 + NodeThing2 - NodeThing3
)
	for c = 1 to NodeID_array.count do(
		if ID3 == NodeID_array[c] do(
		Bone3 = c
		)
	)

Weight4 = (readbyte f #unsigned as float / 255)
IDB4 = (readbyte f #unsigned) + 1
ID4 = IDB4 + NodeThing1
Bone4 = #()

if IDB4 >= (NodeThing3 + 1) do(
ID4 = IDB4 + NodeThing2 - NodeThing3
)
	for c = 1 to NodeID_array.count do(
		if ID4 == NodeID_array[c] do(
		Bone4 = c
		)
	)
append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
--append B1_array (Bone_Info_Struct Bone1:ID1 Bone2:ID2 Bone3:ID3 Bone4:ID4)
--append B1_array (Bone_Info_Struct Bone1:IDB1 Bone2:IDB2 Bone3:IDB3 Bone4:IDB4)
append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
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

)

mat = standardMaterial()
mat.name = MatName_array[matgroupnum]
mat.showinviewport = true
mat.twosided = false
tm = Bitmaptexture filename:(p + "/textures/" + SubMatName_array[matgroupnum] + ".dds")
tm.alphasource = 2
mat.diffuseMap = tm

msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = Vert_array.count
-- Coloring stuff. Uncomment if you want stage models to be tutti-frutti.
-- setNumCPVVerts msh msh.numTVerts
-- setCVertMode msh true
-- setShadeCVerts msh true
-- defaultVCFaces msh
-- for p = 1 to Color_array.count do(
-- setvertcolor msh p Color_array[p]
-- )
buildTVFaces msh
for j = 1 to Vert_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
msh.name = PolygonName
msh.material = mat
max modify mode
select msh

      --set smoothing group of all faces to 1 to get one normal per vertex
      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
      --set normals via edit normals modifier

-- If there are in fact normals, then uncomment this.
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
  
if BoneCount != 0 do(
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

fseek f headerjump #seek_set

)
)

fclose f