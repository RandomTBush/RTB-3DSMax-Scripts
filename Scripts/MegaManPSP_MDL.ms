-- Mega Man Powered Up / Mega Man Maverick Hunter X model importer by Random Talking Bush.

fname = getOpenFileName \ 
caption:"Mega Man PSP file" \
types:"Mega Man PSP models (*.MDL)|*.MDL" \
historyCategory:"MegaManPSP"
if fname != undefined do(
f = fopen fname "rb"
clearlistener()

for a = 1 to 1 do (
Bone_Matrix_Array = #()
BoneParent_array = #()
BoneArray = #()

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

fseek f 0x00 #seek_set

polygroups = readshort f #unsigned
unknown1 = readshort f #unsigned
unknown2 = readshort f #unsigned
unknown3 = readshort f #unsigned
unknown4 = readshort f #unsigned
unknown5 = readshort f #unsigned
boneoffset = readlong f #unsigned

if boneoffset != 0 do(

fseek f boneoffset #seek_set
boneunknown1 = readlong f #unsigned
boneunknown2 = readlong f #unsigned
boneheaderlength = readlong f #unsigned
BoneCount = readlong f #unsigned
	for b = 1 to BoneCount do(
	boneparent = (readbyte f #unsigned) + 1
	if boneparent == 256 do(boneparent = 0)
	append BoneParent_array boneparent
	)
fseek f (boneoffset + boneheaderlength) #seek_set

	for b = 1 to BoneCount do(
	BoneName = "Bone" + (b as string)
	BoneParent = BoneParent_array[b]
	BoneTX = readfloat f; BoneTY = readfloat f; BoneTZ = readfloat f; BoneTQ = readfloat f
	tfm = matrix3 [1,0,0] [0,1,0] [0,0,1] [BoneTX,BoneTY,BoneTZ]
	if (getNodeByName BoneName) != undefined do (
	append BoneArray (getNodeByName BoneName)
	)
	if (getNodeByName BoneName) == undefined do (
		if (BoneParent != 0) do (
		tfm = tfm * BoneArray[(boneparent)].objecttransform
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
	if (BoneParent != 0) then
	newBone.parent = BoneArray[(BoneParent)]
	append BoneArray newBone
	)

)

fseek f 0x10 #seek_set
	for p = 1 to polygroups do(
	fseek f 0x20 #seek_cur
	polyoffset = readlong f #unsigned
	polygroupplus = readshort f #unsigned
	fseek f 0x26 #seek_cur
	polytotal = readlong f #unsigned
	hopto = (ftell f)

	for g = 1 to polygroupplus do(
	PolyCount_array = #()
	StartDirection_array = #()
	Vert_array = #()
	Normal_array = #()
	UV_array = #()
	Face_array = #()
	W1_array = #()
	B1_array = #()
	Weight_array = #()
	
	fseek f polyoffset #seek_set
	vertextotal = readshort f #unsigned
	textureID = readshort f #unsigned + 1
	vertexstart = readlong f #unsigned
	polystart = readlong f #unsigned
	vertexblank = readlong f #unsigned
	Bone1 = readbyte f #unsigned + 1
	Bone2 = readbyte f #unsigned + 1
	Bone3 = readbyte f #unsigned + 1
	Bone4 = readbyte f #unsigned + 1
	Bone5 = readbyte f #unsigned + 1
	Bone6 = readbyte f #unsigned + 1
	Bone7 = readbyte f #unsigned + 1
	Bone8 = readbyte f #unsigned + 1
	if Bone1 == 0 or Bone1 == 256 do(Bone1 = 1)
	if Bone2 == 0 or Bone2 == 256 do(Bone2 = 1)
	if Bone3 == 0 or Bone3 == 256 do(Bone3 = 1)
	if Bone4 == 0 or Bone4 == 256 do(Bone4 = 1)
	if Bone5 == 0 or Bone5 == 256 do(Bone5 = 1)
	if Bone6 == 0 or Bone6 == 256 do(Bone6 = 1)
	if Bone7 == 0 or Bone7 == 256 do(Bone7 = 1)
	if Bone8 == 0 or Bone8 == 256 do(Bone8 = 1)
	fseek f 0x04 #seek_cur
	polyoffset = (ftell f)

	fseek f (polystart + 0x18) #seek_set

	startdirectionvar = 1
	polycheck = readbyte f #unsigned
	fseek f -0x01 #seek_cur

	if polycheck > 1 do(
	polyfailsafe = 1
	)
	
	polycounttotal = 0
	while polycounttotal < vertextotal do(
	if polyfailsafe != 1 do(
	startdirectionvar = readbyte f #unsigned
	if startdirectionvar == 0 do(startdirectionvar = -1)
	fseek f 0x03 #seek_cur
	)
	append StartDirection_array (startdirectionvar * -1)
	polycount = readshort f #unsigned
	fseek f 0x02 #seek_cur
	polycounttotal = polycounttotal + polycount
	append PolyCount_array polycount
	)

	fseek f vertexstart #seek_set

	for v = 1 to vertextotal do(
	if boneoffset != 0 do(
	Weight1 = (readbyte f #unsigned as float) / 128
	Weight2 = (readbyte f #unsigned as float) / 128
	Weight3 = (readbyte f #unsigned as float) / 128
	Weight4 = (readbyte f #unsigned as float) / 128
	Weight5 = (readbyte f #unsigned as float) / 128
	Weight6 = (readbyte f #unsigned as float) / 128
	Weight7 = (readbyte f #unsigned as float) / 128
	Weight8 = (readbyte f #unsigned as float) / 128
	)
	tu = readshort f as float / 128
	tv = ((readshort f as float / 128) * -1) + 1
	nx = readshort f as float / 32768
	ny = readshort f as float / 32768
	nz = readshort f as float / 32768
	nq = readshort f as float / 32768
	vx = readfloat f
	vy = readfloat f
	vz = readfloat f
	append Vert_array [vx,vy,vz]
	append Normal_array [nx,ny,nz]
	append UV_array [tu,tv,0]
	if boneoffset != 0 do(
	append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
	append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone7:Bone7 Bone8:Bone8)
	)
	)

	VertAdd = 1
	
for o = 1 to PolyCount_array.count do(
	StartDirection = StartDirection_array[o]
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
		) while IndexCounter != PolyCount_Array[o]
		VertAdd = VertAdd + PolyCount_Array[o]
)

if boneoffset != 0 do(

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

)

	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = Vert_array.count
	buildTVFaces msh
	msh.name = (TextureID as string)
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
	
	if boneoffset != 0 do(
	
	skinMod = skin ()
	addModifier msh skinMod
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

	)

	fseek f hopto #seek_set

	)
)

gc()
fclose f

)