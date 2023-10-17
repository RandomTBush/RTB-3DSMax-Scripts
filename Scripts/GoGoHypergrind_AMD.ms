-- Go Go Hypergrind! model importer by Random Talking Bush.

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

fname = getOpenFileName \ 
caption:"Go Go Hypergrind AMD file" \
types:"Go Go Hypergrind AMD(*.amd)|*.amd" \
historyCategory:"GoGoHypergrind"
f = fopen fname "rb"

if fname != undefined do(

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

p = getFilenamePath fname
h = getFilenameFile fname
fname2 = p + h + ".skn"
q = fopen fname2 "rb"
fname3 = p + h + ".shp"
shp = fopen fname3 "rb"

clearlistener()
B1Temp_array = #()
W1Temp_array = #()
BoneArray = #()
BoneCount = 0

if q != undefined do (
Trans_array = #()
Rotation_array = #()
Scale_array = #()
Bone_Matrix_Array = #()
BoneName_array = #()
BoneParent_array = #()
BoneFixArray = #()
fseek q 0x08 #seek_set
BoneCount = readBElong q
BoneStart = readBElong q
SingleBindCount = readBElong q
SingleBindStart = readBElong q
DoubleBindCount = readBElong q
DoubleBindStart = readBElong q
TripleBindCount = readBElong q
TripleBindStart = readBElong q
QuadBindCount = readBElong q
QuadBindStart = readBElong q
fseek q BoneStart #seek_set
for x = 1 to BoneCount do(
bonename = ("Bone" + x as string)
boneparent = (readBElong q) + 1
if boneparent == 0 do(boneparent = -1)
rx = readBEfloat q
ry = readBEfloat q
rz = readBEfloat q
rq = readBEfloat q

tx = readBEfloat q
ty = readBEfloat q
tz = readBEfloat q

sx = readBEfloat q
sy = readBEfloat q
sz = readBEfloat q

append Trans_array [tx,ty,tz]
append Rotation_array [rx,ry,rz]
append Scale_array [sx,sy,sz]
append BoneName_array bonename
append BoneParent_array BoneParent
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

fseek q SingleBindStart #seek_set
for x = 1 to SingleBindCount do(
VertNum = readBElong q + 1
VertNum2 = readBElong q + 1
BoneIDStart = readBElong q
WeightStart = readBElong q
goback = (ftell q)

fseek q BoneIDStart #seek_set
Bone1 = readBEword q + 1
Bone2 = 1
Bone3 = 1
Bone4 = 1
B1Temp_array[VertNum] = (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)

fseek q WeightStart #seek_set
Weight1 = readBEfloat q
Weight2 = 0
Weight3 = 0
Weight4 = 0
W1Temp_array[VertNum] = (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)

fseek q goback #seek_set
)

fseek q DoubleBindStart #seek_set
for x = 1 to DoubleBindCount do(
VertNum = readBElong q + 1
VertNum2 = readBElong q + 1
BoneIDStart = readBElong q
WeightStart = readBElong q
goback = (ftell q)

fseek q BoneIDStart #seek_set
Bone1 = readBEword q + 1
Bone2 = readBEword q + 1
Bone3 = 1
Bone4 = 1
B1Temp_array[VertNum] = (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)

fseek q WeightStart #seek_set
Weight1 = readBEfloat q
Weight2 = readBEfloat q
Weight3 = 0
Weight4 = 0
W1Temp_array[VertNum] = (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)

fseek q goback #seek_set
)

fseek q TripleBindStart #seek_set
for x = 1 to TripleBindCount do(
VertNum = readBElong q + 1
VertNum2 = readBElong q + 1
BoneIDStart = readBElong q
WeightStart = readBElong q
goback = (ftell q)

fseek q BoneIDStart #seek_set
Bone1 = readBEword q + 1
Bone2 = readBEword q + 1
Bone3 = readBEword q + 1
Bone4 = 1
B1Temp_array[VertNum] = (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)

fseek q WeightStart #seek_set
Weight1 = readBEfloat q
Weight2 = readBEfloat q
Weight3 = readBEfloat q
Weight4 = 0
W1Temp_array[VertNum] = (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)

fseek q goback #seek_set
)

fseek q QuadBindStart #seek_set
for x = 1 to QuadBindCount do(
VertNum = readBElong q + 1
VertNum2 = readBElong q + 1
BoneIDStart = readBElong q
WeightStart = readBElong q
goback = (ftell q)

fseek q BoneIDStart #seek_set
Bone1 = readBEword q + 1
Bone2 = readBEword q + 1
Bone3 = readBEword q + 1
Bone4 = readBEword q + 1
B1Temp_array[VertNum] = (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)

fseek q WeightStart #seek_set
Weight1 = readBEfloat q
Weight2 = readBEfloat q
Weight3 = readBEfloat q
Weight4 = readBEfloat q
W1Temp_array[VertNum] = (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)

fseek q goback #seek_set
)

)

if f != undefined do (
fseek f 0x08 #seek_set
ModelCount = readBElong f
fseek f 0x20 #seek_set
-- print ("Model Count = " + (ModelCount as string))
	
for m = 1 to ModelCount do(
VertTemp_array = #()
NormalTemp_array = #()
ColorTemp_array = #()
AlphaTemp_array = #()
UVTemp_array = #()
PolyGroupCount = readBElong f
VertCount = readBEword f
NormalsCount = readBEword f
ColorCount = readBEword f
UVCount = readBEword f
PolyGroupStart = readBElong f
VertStart = readBElong f
NormalsStart = readBElong f
ColorStart = readBElong f
UVStart = readBElong f
fseek f 0x10 #seek_cur
modelreturn = (ftell f)

fseek f VertStart #seek_set
-- print ("Vertex Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + VertCount as string)

for x = 1 to VertCount do(
vx = readBEfloat f
vy = readBEfloat f
vz = readBEfloat f
append VertTemp_array [vx,vy,vz]
)

-- print ("Vertex End: 0x"+((bit.intAsHex(ftell f))as string))

if NormalsCount > 0 do(
fseek f NormalsStart #seek_set
-- print ("Normals Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + NormalsCount as string)
for x = 1 to NormalsCount do(
nx = readBEfloat f
ny = readBEfloat f
nz = readBEfloat f
append NormalTemp_array [nx,ny,nz]
)

-- print ("Normals End: 0x"+((bit.intAsHex(ftell f))as string))
)

fseek f ColorStart #seek_set
-- print ("Color Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + ColorCount as string)
for x = 1 to ColorCount do(
colorr = readbyte f #unsigned
colorg = readbyte f #unsigned
colorb = readbyte f #unsigned
colora = readbyte f #unsigned
append ColorTemp_array [colorr,colorg,colorb]
append AlphaTemp_array colora
)

-- print ("Color End: 0x"+((bit.intAsHex(ftell f))as string))

fseek f UVStart #seek_set
-- print ("UV Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + UVCount as string)
for x = 1 to UVCount do(
tu = readBEfloat f
tv = readBEfloat f * -1
append UVTemp_array [tu,tv,0]
)

-- print ("UV End: 0x"+((bit.intAsHex(ftell f))as string))

fseek f PolyGroupStart #seek_set
-- print ("Poly Group Start: 0x"+((bit.intAsHex(ftell f))as string) + ", Count = " + PolyGroupCount as string)
for x = 1 to PolyGroupCount do(
Vert_array = #()
Normal_array = #()
Color_array = #()
UV_array = #()
UV2_array = #()
Face_array = #()
B1_array = #()
W1_array = #()
Weight_array = #()
UVLayers = readBElong f
TexNum = readBEword f
TexNumL2 = readBEword f
fseek f 0x0C #seek_cur
PosX = readBEfloat f
PosY = readBEfloat f
PosZ = readBEfloat f
PolyCount = readBElong f
PolyStart = readBElong f
fseek f 0x08 #seek_cur
goback = (ftell f)

fseek f PolyStart #seek_set
-- print ("Poly Start " + x as string + " Start: 0x"+((bit.intAsHex(ftell f))as string))
PolyType = readBEword f
if PolyType > 0 and PolyType != 0x98 do(throw "Error building model!")

VertAdd = 1
do(
PolyAmt = readBEword f
for z = 1 to PolyAmt do(
VertNum = readBEword f + 1
if NormalsCount > 0 do(NormNum = readBEword f + 1)
ColorNum = readBEword f + 1
UVNum = readBEword f + 1
if UVLayers == 2 do(UV2Num = readBEword f + 1)
VertDat = VertTemp_array[VertNum]
if NormalsCount > 0 do(NormDat = NormalTemp_array[NormNum])
ColorDat = ColorTemp_array[ColorNum]
UVDat = UVTemp_array[UVNum]
if UVLayers == 2 do(UV2Dat = UVTemp_array[UV2Num])
VertDat = VertTemp_array[VertNum]
BoneDat = B1Temp_array[VertNum]
WeightDat = W1Temp_array[VertNum]
append Vert_array VertDat
if NormalsCount > 0 do(append Normal_array NormDat)
append Color_array ColorDat
append UV_array UVDat
if UVLayers == 2 do(append UV2_array UV2Dat)
append B1_array BoneDat
append W1_array WeightDat
)
PolyType = readBEword f
if PolyType > 0 and PolyType != 0x98 do(throw "SCANNER SOMETHING ERROR HAPPEN")

	StartDirection = -1
	f1 = VertAdd
	f2 = VertAdd + 1
	f3 = VertAdd + 1
	IndexCounter = 2
	FaceDirection = StartDirection
		Do (
				f3 += 1
				IndexCounter = IndexCounter +1
				if (f1!=f2)AND(f2!=f3)AND(f3!=f1) then (
					if FaceDirection > 0 then append Face_Array [f1,f2,f3]
					else append Face_Array [f1,f3,f2]
			)
				FaceDirection *= -1
				f1 = f2
				f2 = f3
		) while IndexCounter != PolyAmt
		VertAdd = VertAdd + PolyAmt

) while PolyType != 0

fseek f goback #seek_set

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
mat.name = (TexNum as string)
mat.showinviewport = true
mat.twosided = false
tm = Bitmaptexture filename:(p + "Texture" + TexNum as string + ".png")
tm.alphasource = 0
mat.diffuseMap = tm
mat.opacityMap = tm
mat.opacityMap.monoOutput = 1

msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = Vert_array.count
setNumCPVVerts msh msh.numTVerts
setCVertMode msh true
setShadeCVerts msh true
defaultVCFaces msh
buildTVFaces msh

for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
msh.name = ("Model " + m as string + " Mesh " + x as string)
msh.material = mat
max modify mode
select msh

if NormalsCount > 0 do(
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
mat = standardMaterial()
mat.name = (TexNumL2 as string)
mat.showinviewport = true
mat.twosided = false
tm = Bitmaptexture filename:(p + "Texture" + TexNumL2 as string + ".png")
tm.alphasource = 0
mat.diffuseMap = tm
mat.opacityMap = tm
mat.opacityMap.monoOutput = 1

msh = mesh vertices:Vert_array faces:Face_array
msh.numTVerts = Vert_array.count
setNumCPVVerts msh msh.numTVerts
setCVertMode msh true
setShadeCVerts msh true
defaultVCFaces msh
buildTVFaces msh

for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
for j = 1 to UV2_array.count do setTVert msh j UV2_array[j]
for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
msh.name = ("Model " + m as string + " Mesh " + x as string + " Layer 2")
msh.material = mat
max modify mode
select msh

if NormalsCount > 0 do(
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


if shp != undefined and x == 1 do(
	fseek shp 0x08 #seek_set
	SHPCount = readBElong shp
	fseek shp 0x04 #seek_cur

	for y = 1 to SHPCount do(
	VertSHP_array = #()
	VertSHPTemp_array = VertTemp_array
	SHPVerts = readBElong shp
	SHPStart = readBElong shp
	fseek shp 0x08 #seek_cur
	returnSHP = (ftell shp)

	fseek shp SHPStart #seek_set
		
		for z = 1 to SHPVerts do(
		VertNum = readBElong shp + 1
		vx = readBEfloat shp
		vy = readBEfloat shp
		vz = readBEfloat shp
		VertSHPTemp_array[VertNum] = [vx,vy,vz]
		)

	fseek f PolyStart #seek_set
	PolyType = readBEword f
	VertAdd = 1
	do(
	PolyAmt = readBEword f
	for z = 1 to PolyAmt do(
	VertNum = readBEword f + 1
	fseek f 0x06 #seek_cur
	VertDat = VertSHPTemp_array[VertNum]
	append VertSHP_array VertDat
	)
	PolyType = readBEword f
		
		StartDirection = -1
		f1 = VertAdd
		f2 = VertAdd + 1
		f3 = VertAdd + 1
		IndexCounter = 2
		FaceDirection = StartDirection
			Do (
					f3 += 1
					IndexCounter = IndexCounter +1
					FaceDirection *= -1
					f1 = f2
					f2 = f3
			) while IndexCounter != PolyAmt
			VertAdd = VertAdd + PolyAmt

	) while PolyType != 0

	msh = mesh vertices:VertSHP_array faces:Face_array
	msh.numTVerts = VertSHP_array.count
	setNumCPVVerts msh msh.numTVerts
	setCVertMode msh true
	setShadeCVerts msh true
	defaultVCFaces msh
	buildTVFaces msh

	for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
	msh.name = ("Flex " + y as string)
	max modify mode
	select msh

	if NormalsCount > 0 do(
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
	  )

	fseek shp returnSHP #seek_set

	)

	)
)

fseek f modelreturn #seek_set

)

)

fclose f
fclose q
fclose s

)