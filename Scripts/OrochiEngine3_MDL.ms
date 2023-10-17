-- World of Final Fantasy (PC) model importer by Random Talking Bush.

-- Changelog:
-- December 4th, 2017:
-- Added a check for compressed models so it won't crash if you forget to decompress 'em.
-- Implemented multiple UV mapping layers because I'm a twit and forgot all about it.

-- November 26th, 2017: Fixed static models not importing.

fn ReadHalfFloat Fstream = (
	local BL  = readByte Fstream #unsigned
	local BH  = readByte Fstream #unsigned
	local N = BH*256 + BL
	local S = floor((mod N 65536) / 32768)
	local Ef = floor((mod N 32768) / 1024)
	local M = mod N 1024
	local ret=case of(
		((Ef==0)AND(M==0)): ( (-1.0)^S * 0.0 )
		((Ef==0)AND(M!=0)): ( (-1.0)^S * 2.0^-14 * (M / 2.0^10) )
		((Ef>0)AND(Ef<31)): ( (-1.0)^S * 2.0^(Ef-15) * (1 + M/2.0^10) )
		((Ef==31)AND(M==0)): ( (-1.0)^S * 1/0.0 )
		((Ef==31)AND(M!=0)): 0
	)
)

ModelScale = 10 -- The models are ridiculously small by default, modify this if you want tthe scale to be different.

fname = getOpenFileName \ 
caption:"World of Final Fantasy Model File" \
types:"World of Final Fantasy Model File(*.mdl)|*.mdl" \
historyCategory:"WoFFObjectPresets"

if fname != undefined do(
	clearlistener()
	f = fopen fname "rb"
	p = getFilenamePath fname
	g = getFilenameFile fname

struct BoneGrp_Struct(
	PosX, PosY, PosZ, ScaleX, ScaleY, ScaleZ, Unk1, BoneParent, Unk3, Unk4, Unk5, Unk6
)

struct VisGrp_Struct(
	VISNum, LODNum, Unknown3, VertStart, VertCount, PolyStart, PolyCount, Float1, Float2, Float3
)

struct PolyGrp_Struct(
	PolyGrpStart, PolyGrpCount, VertStart, VertSize, VertStride, PolyStart, PolySize, Unknown1, Unknown2, NodeIDStart, NodeIDCount, MatID, Unknown6
)

struct Bone_Info_Struct(
	bone1, bone2, bone3, bone4
)

struct Weight_Info_Struct(
	weight1, weight2, weight3, weight4
)

struct weight_data(
	boneids, weights
)

String_array = #()
PolyGrp_array = #()
BoneGrp_array = #()
VisGrp_array = #()
Node_array = #()
BoneArray = #()

fseek f 0x80 #seek_set
ZLIBCheck = readlong f
fseek f 0x00 #seek_set
if ZLIBCheck == 0x5A4C4942 then(
print "Model is compressed! Decompress it and try again."
fclose f
) else (

st = timestamp()
disableSceneRedraw()

StringBuffSize = readlong f
NodeBuffSize = readlong f
BoneCount = readlong f
UnkCount = readlong f
Blank = readlong f
Unk2Count = readlong f
VisGrpCount = readlong f
MeshCount = readlong f
VertexBuffSize = readlong f
PolyBuffSize = readlong f
VertStrideBuffSize = readlong f

NodeBuffStart = StringBuffSize + 0x2C
	
for s = 1 to BoneCount do(
	StringName = readstring f
	append String_array StringName
)

fseek f NodeBuffStart #seek_set
BoneBuffStart = NodeBuffStart + NodeBuffSize

for x = 1 to (NodeBuffSize / 2) do(
	NodeID = readshort f #unsigned + 1
	append Node_array NodeID
)

fseek f BoneBuffStart #seek_set

for x = 1 to BoneCount do(
	fseek f 0x10 #seek_cur
	PosX = readfloat f
	PosY = readfloat f
	PosZ = readfloat f
	ScaleX = readfloat f
	ScaleY = readfloat f
	ScaleZ = readfloat f
	Unk1 = readlong f
	BoneParent = readshort f + 1
	Unk3 = readshort f
	Unk4 = readshort f
	Unk5 = readshort f
	Unk6 = readlong f
	fseek f 0x08 #seek_cur
	append BoneGrp_array (BoneGrp_Struct PosX:PosX PosY:PosY PosZ:PosZ ScaleX:ScaleX ScaleY:ScaleY ScaleZ:ScaleZ Unk1:Unk1 BoneParent:BoneParent Unk3:Unk3 Unk4:Unk4 Unk5:Unk5 Unk6:Unk6)
)

for x = 1 to BoneCount do(
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f * ModelScale; m42 = readfloat f * ModelScale; m43 = readfloat f * ModelScale; m44 = readfloat f
)

for x = 1 to BoneCount do(
	BoneName = String_array[x]
	BoneParent = BoneGrp_array[x].BoneParent
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f * ModelScale; m42 = readfloat f * ModelScale; m43 = readfloat f * ModelScale; m44 = readfloat f
	
	tfm = scaleMatrix [BoneGrp_array[x].ScaleX,BoneGrp_array[x].ScaleY,BoneGrp_array[x].ScaleZ]
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	tfm = inverse(tfm)

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

for x = 1 to VisGrpCount do(
	VISNum = readlong f
	LODNum = readshort f
	Unknown3 = readshort f
	VertCount = readlong f
	PolyStart = readlong f / 3
	PolyCount = readlong f / 3
	VertStart = readlong f
	fseek f 0x08 #seek_cur
	Float1 = readfloat f; Float2 = readfloat f; Float3 = readfloat f; Float4 = readfloat f
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	append VisGrp_array (VisGrp_Struct VISNum:VISNum LODNum:LODNum Unknown3:Unknown3 VertStart:VertStart VertCount:VertCount PolyStart:PolyStart PolyCount:PolyCount Float1:Float1 Float2:Float2 Float3:Float3)
)

for x = 1 to MeshCount do(
	PolyArrInfo = (PolyGrp_Struct \ 
	PolyGrpStart: (readlong f) \
	PolyGrpCount: (readlong f) \
	VertStart: (readlong f) \
	VertSize: (readlong f) \
	VertStride: (readlong f) \
	PolyStart: (readlong f) \
	PolySize: (readlong f) \
	Unknown1: (readlong f) \
	Unknown2: (readlong f) \
	NodeIDStart: (readlong f) \
	NodeIDCount: (readlong f) \
	MatID: (readlong f) \
	Unknown6: (readlong f) \
	)
	append PolyGrp_array PolyArrInfo
)

VertBuffStart = (ftell f)
PolyBuffStart = VertBuffStart + VertexBuffSize
VertStrideBuffStart = PolyBuffStart + PolyBuffSize

for x = 1 to MeshCount do(
	Vert_Array = #()
	Normal_Array = #()
	UV_Array = #()
	UV2_Array = #()
	UV3_Array = #()
	UV4_Array = #()
	Color_Array = #()
	Alpha_Array = #()
	NodeID_array = #()
	B1_array = #()
	W1_array = #()
	Weight_array = #()
	Face_array = #()
	
	fseek f VertStrideBuffStart #seek_set
	
	HasVertex = 0; HasNormals = 0; HasColors = 0; HasColors2 = 0; HasBones = 0; HasWeights = 0
	HasUVs = 0; HasUVs2 = 0; HasUVs3 = 0; HasUVs4 = 0
	HasBinormals = 0; HasBinormals2 = 0; HasTangents = 0; HasTangents2 = 0

	EndCheck = 0
	Do (
		EndCheck = readshort f
		StrideStart = readshort f
		VertAmount = readbyte f #unsigned
		VertFormat = readbyte f #unsigned
		VertFormatPrint = VertFormat
		case VertFormat of(
		default:(fclose f; throw "Unknown vertex format!")
		0x00:(VertFormatPrint = "Empty")
		0x02:(VertFormatPrint = "Floats")
		0x03:(VertFormatPrint = "Half-Floats")
		0x04:(VertFormatPrint = "Bytes (Weights)")
		0x07:(VertFormatPrint = "Bytes (Node IDs)")
		0x14:(VertFormatPrint = "Bytes (Colors)")
		)
		VertType = readbyte f #unsigned
		VertTypePrint = VertType
		if EndCheck != -1 do(
			case VertType of(
			default:(fclose f; throw "Unknown vertex type!")
			0x00:(
				VertTypePrint = "Positions"
				HasVertex = VertFormat
				)
			0x01:(
				VertTypePrint = "Weights"
				HasWeights = VertFormat
				)
			0x02:(
				VertTypePrint = "Normals"
				HasNormals = VertFormat
				)
			0x03:(
				VertTypePrint = "Colors"
				HasColors = VertFormat
				)
			0x04:(
				VertTypePrint = "Colors 2?"
				HasColors2 = VertFormat
				)
			0x07:(
				VertTypePrint = "Node IDs"
				HasBones = VertFormat
				)
			0x08:(
				VertTypePrint = "UVs"
				HasUVs = VertFormat
				)
			0x09:(
				VertTypePrint = "UVs (Layer 2)"
				HasUVs2 = VertFormat
				)
			0x0A:(
				VertTypePrint = "UVs (Layer 3)"
				HasUVs3 = VertFormat
				)
			0x0B:(
				VertTypePrint = "UVs (Layer 4)"
				HasUVs4 = VertFormat
				)
			0x0C:(
				VertTypePrint = "Binormals 2?"
				HasBinormals2 = VertFormat
				)
			0x0D:(
				VertTypePrint = "Tangents 2?"
				HasTangents2 = VertFormat
				)
			0x0E:(
				VertTypePrint = "Binormals?"
				HasBinormals = VertFormat
				)
			0x0F:(
				VertTypePrint = "Tangents?"
				HasTangents = VertFormat
				)
			)
		)
		Unknown = readbyte f #unsigned
		if EndCheck != -1 do(print ("0x" + (bit.intAsHex(StrideStart)) as string + ": " + VertFormatPrint as string  + ", " + VertTypePrint as string))
	) while EndCheck != -1
	print "----------"
	VertStrideBuffStart = (ftell f)

	fseek f (VertBuffStart + (PolyGrp_array[x].VertStart)) #seek_set
	VertCount = (PolyGrp_array[x].VertSize) / (PolyGrp_array[x].VertStride)

	for y = 1 to PolyGrp_array[x].NodeIDCount do(
	append NodeID_array Node_array[y + PolyGrp_array[x].NodeIDStart]	
	)

	for y = 1 to VertCount do(
		case HasVertex of(
			default:(fclose f; throw "Unknown position format!")
			0x02:(
				vx = readfloat f * ModelScale
				vy = readfloat f * ModelScale
				vz = readfloat f * ModelScale
				append Vert_Array[vx,vy,vz]
			)
			0x03:(
				vx = readhalffloat f * ModelScale
				vy = readhalffloat f * ModelScale
				vz = readhalffloat f * ModelScale
				vq = readhalffloat f * ModelScale
				append Vert_Array[vx,vy,vz]
			)
		)
		case HasNormals of(
			default:(fclose f; throw "Unknown normals format!")
			0x00:()
			0x02:(
				nx = readfloat f
				ny = readfloat f
				nz = readfloat f
				append Normal_Array[nx,ny,nz]
			)
			0x03:(
				nx = readhalffloat f
				ny = readhalffloat f
				nz = readhalffloat f
				nq = readhalffloat f
				append Normal_Array[nx,ny,nz]
			)
		)
		case HasBinormals of(
			default:(fclose f; throw "Unknown binormals format!")
			0x00:()
			0x02:(
				bnx = readfloat f
				bny = readfloat f
				bnz = readfloat f
			)
			0x03:(
				bnx = readhalffloat f
				bny = readhalffloat f
				bnz = readhalffloat f
				bnq = readhalffloat f
			)
		)
		case HasBinormals2 of(
			default:(fclose f; throw "Unknown binormals2 format!")
			0x00:()
			0x02:(
				bnx2 = readfloat f
				bny2 = readfloat f
				bnz2 = readfloat f
			)
			0x03:(
				bnx2 = readhalffloat f
				bny2 = readhalffloat f
				bnz2 = readhalffloat f
				bnq2 = readhalffloat f
			)
		)
		case HasTangents of(
			default:(fclose f; throw "Unknown tangents format!")
			0x00:()
			0x02:(
				tanx = readfloat f
				tany = readfloat f
				tanz = readfloat f
			)
			0x03:(
				tanx = readhalffloat f
				tany = readhalffloat f
				tanz = readhalffloat f
				tanq = readhalffloat f
			)
		)
		case HasTangents2 of(
			default:(fclose f; throw "Unknown tangents2 format!")
			0x00:()
			0x02:(
				tanx2 = readfloat f
				tany2 = readfloat f
				tanz2 = readfloat f
			)
			0x03:(
				tanx2 = readhalffloat f
				tany2 = readhalffloat f
				tanz2 = readhalffloat f
				tanq2 = readhalffloat f
			)
		)
		case HasColors of(
			default:(fclose f; throw "Unknown colors format!")
			0x00:(
				append Color_Array[255,255,255]
				append Alpha_Array 1
			)
			0x14:(
				colorr = readbyte f #unsigned
				colorg = readbyte f #unsigned
				colorb = readbyte f #unsigned
				colora = readbyte f #unsigned
				append Color_Array[colorr,colorg,colorb]
				append Alpha_Array colora
			)
		)
		case HasColors2 of(
			default:(fclose f; throw "Unknown colors2 format!")
			0x00:()
			0x14:(
				colorr2 = readbyte f #unsigned
				colorg2 = readbyte f #unsigned
				colorb2 = readbyte f #unsigned
				colora2 = readbyte f #unsigned
			)
		)
		case HasUVs of(
			default:(fclose f; throw "Unknown UVs format!")
			0x00:(append UV_Array[0,0,0])
			0x02:(
				tu = readfloat f
				tv = (readfloat f * -1) + 1
				append UV_Array[tu,tv,0]
			)
			0x03:(
				tu = readhalffloat f
				tv = (readhalffloat f * -1) + 1
				append UV_Array[tu,tv,0]
			)
		)
		case HasUVs2 of(
			default:(fclose f; throw "Unknown UVs2 format!")
			0x00:()
			0x02:(
				tu2 = readfloat f
				tv2 = (readfloat f * -1) + 1
				append UV2_Array[tu2,tv2,0]
			)
			0x03:(
				tu2 = readhalffloat f
				tv2 = (readhalffloat f * -1) + 1
				append UV2_Array[tu2,tv2,0]
			)
		)
		case HasUVs3 of(
			default:(fclose f; throw "Unknown UVs3 format!")
			0x00:()
			0x02:(
				tu3 = readfloat f
				tv3 = (readfloat f * -1) + 1
				append UV3_Array[tu3,tv3,0]
			)
			0x03:(
				tu3 = readhalffloat f
				tv3 = (readhalffloat f * -1) + 1
				append UV3_Array[tu3,tv3,0]
			)
		)
		case HasUVs4 of(
			default:(fclose f; throw "Unknown UVs4 format!")
			0x00:()
			0x02:(
				tu4 = readfloat f
				tv4 = (readfloat f * -1) + 1
				append UV4_Array[tu4,tv4,0]
			)
			0x03:(
				tu4 = readhalffloat f
				tv4 = (readhalffloat f * -1) + 1
				append UV4_Array[tu4,tv4,0]
			)
		)
		case HasBones of(
			default:(fclose f; throw "Unknown bones format!")
			0x00:(append B1_Array (Bone_Info_Struct bone1:1 bone2:1 bone3:1 bone4:1))
			0x07:(
				bone1 = readbyte f #unsigned + 1
				bone2 = readbyte f #unsigned + 1
				bone3 = readbyte f #unsigned + 1
				bone4 = readbyte f #unsigned + 1
				bone1 = NodeID_array[bone1]
				bone2 = NodeID_array[bone2]
				bone3 = NodeID_array[bone3]
				bone4 = NodeID_array[bone4]
				append B1_Array (Bone_Info_Struct bone1:bone1 bone2:bone2 bone3:bone3 bone4:bone4)
			)
		)
		case HasWeights of(
			default:(fclose f; throw "Unknown weights format!")
			0x00:(append W1_Array (Weight_Info_Struct weight1:1 weight2:0 weight3:0 weight4:0))
			0x04:(
				weight1 = (readbyte f #unsigned as float) / 255
				weight2 = (readbyte f #unsigned as float) / 255
				weight3 = (readbyte f #unsigned as float) / 255
				weight4 = (readbyte f #unsigned as float) / 255
				append W1_Array (Weight_Info_Struct weight1:weight1 weight2:weight2 weight3:weight3 weight4:weight4)
			)
		)
	)

	fseek f (PolyBuffStart + (PolyGrp_array[x].PolyStart)) #seek_set
	PolyCount = (PolyGrp_array[x].PolySize) / 6
	
	for p = 1 to PolyCount do(
		fa = readshort f #unsigned + 1
		fb = readshort f #unsigned + 1
		fc = readshort f #unsigned + 1
		append Face_array[fa,fb,fc]
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

	VisGrpAdd = PolyGrp_array[x].PolyGrpStart
	for v = 1 to PolyGrp_array[x].PolyGrpCount do(
	Face_array2 = #()

	for w = 1 to VisGrp_array[v + VisGrpAdd].PolyCount do(
		Faces = Face_array[w + VisGrp_array[v + VisGrpAdd].PolyStart] - VisGrp_array[v + VisGrpAdd].VertStart
		append Face_array2 Faces
	)
	
	VertexMin = VisGrp_array[v + VisGrpAdd].VertStart + 1
	VertexMax = (VisGrp_array[v + VisGrpAdd].VertStart + VisGrp_array[v + VisGrpAdd].VertCount)
	Vert_array2 = #()
	Normal_array2 = #()
	UV_array2 = #()
	UV2_array2 = #()
	UV3_array2 = #()
	UV4_array2 = #()
	Weight_array2 = #()
	
	for y = VertexMin to VertexMax do(
	append Vert_array2 Vert_array[y]
	append Normal_array2 Normal_array[y]
-- 	append Color_array2 Color_array[y]
-- 	append Alpha_array2 Alpha_array[y]
	append UV_array2 UV_array[y]
	if UV2_array.count != 0 do(append UV2_array2 UV2_array[y])
	if UV3_array.count != 0 do(append UV3_array2 UV3_array[y])
	if UV4_array.count != 0 do(append UV4_array2 UV4_array[y])
	append Weight_array2 Weight_array[y]
	)

		msh = mesh vertices:Vert_array2 faces:Face_array2
		msh.name = (g as string + " (LOD: " + VisGrp_array[v + VisGrpAdd].LODNum as string + ", VIS: " + VisGrp_array[v + VisGrpAdd].VISNum as string + ", MAT: " + PolyGrp_array[x].MatID as string + ")")
		msh.numTVerts = Vert_array2.count
	-- 	setNumCPVVerts msh msh.numTVerts
	-- 	setCVertMode msh true
	-- 	setShadeCVerts msh true
		defaultVCFaces msh
		buildTVFaces msh
	-- 	for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
	-- 	for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
		for j = 1 to UV_array2.count do setTVert msh j UV_array2[j]
		for j = 1 to Face_array2.count do setTVFace msh j Face_array2[j]
		for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1

		max modify mode
		select msh

		for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
		select msh
		addmodifier msh (Edit_Normals ()) ui:off
		msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array2.count}
		EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		EN_setNormal = msh.Edit_Normals.SetNormal
		normID = #{}
		for v = 1 to Normal_array2.count do
		(
			free normID
			EN_convertVS #{v} &normID
			for id in normID do EN_setNormal id Normal_array2[v]
		)

		if BoneCount != 0 do(
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

		local UVarrays = #(UV2_array2,UV3_array2,UV4_array2)
		for uva=1 to UVarrays.count do(
			local uvac=UVarrays[uva].count
			if uvac > 0 do(
				meshop.setNumMaps msh (uva+2) keep:true
				for i = 1 to uvac do meshop.setMapVert msh (uva+1) i UVarrays[uva][i]
			)
		)

	)

)

fclose f
Print ("Done! ("+((((timestamp())-st)*0.001)as string)+" Seconds)")
enableSceneRedraw()
)

	)
