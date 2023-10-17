-- NieR: Automata model importer by Random Talking Bush.

rollout NieRAutomataRollout "NieR Automata model importer" width:365 height:165
(
	button btnImport "Import Model" pos:[7,8] width:351 height:50
	groupBox OptionsBox "Options" pos:[7,58] width:351 height:40
	checkbox tglLODs "Import LODs?" pos:[17,75] tooltip: "Enable this to import Level-of-Detail models" checked: false
	checkbox tglDebug "Print debug information?" pos:[213,75] checked: false
	label lblCred "This script was written by Random Talking Bush, if you use it, please remember to give me thanks for this. If something doesn't work right, please contact me on The VG Resource (Random Talking Bush), Twitter, Tumblr or Steam (RandomTBush) and let me know, and I'll try to fix it." pos:[8,105] width:355 height:80

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

	fn readHalfFloat fstream = (
	return convertTo32(Readshort fstream)
	)

	fn ReadFixedString fstream fixedLen = (
		local str = ""
		for strlen = 1 to fixedLen do
		(
			str += bit.intAsChar (ReadByte fstream #unsigned)
		)
		str
	)

	fn printDebug pr = (if tglDebug.state do print(pr))

on btnImport pressed do(
fname = getOpenFileName \ 
caption:"NieR Automata Model File" \
types:"NieR Automata Model File(*.wmb)|*.wmb" \
historyCategory:"NieRAutomataObjectPresets"

if fname != undefined do(
	clearlistener()

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
	struct Poly_Struct
	(
		VertexStart, VertexBStart, VertexSize, VertexBSize, VertexCount, UnknownCount, FaceStart, FacePointCount
	)
	struct SubGroup_Struct
	(
		PolyGroup, RigSet, FacePointStart, VertexEnd, FacePointCount, FaceCount
	)
	struct ModelInfo_Struct
	(
		ModelGroup, VisGroup, MatID, Unknown2, LODName
	)
	struct RigSet_Struct
	(
		RigBoneStart, RigBoneCount
	)
	struct Material_Struct
	(
		MatName1, MatName2, MatType, MatUnk1Count, TexTypeStart, TexTypeCount, MatUnk2Start, MatUnk2Count, MatParamStart, MatParamCount
	)
	struct VisGroup_Struct
	(
		MaterialIDsStart, MaterialIDsCount, BoneIDsStart, BoneIDsCount, VisName
	)

	f = fopen fname "rb"
	p = getFilenamePath fname
	h = getFilenameFile fname

	local LODEnable = tglLODs.state
	WMB3 = readfixedstring f 4

	if WMB3 == "WMB3" do (
		BoneArray = #()
		PolyStruct_array = #()
		SubGroupStruct_array = #()
		ModelInfoStruct_array = #()
		MaterialStruct_array = #()
		RigBones_array = #()
		RigSetStruct_array = #()
		VisGroupStruct_array = #()
		Face_array = #()
		Vert_array = #()
		Normal_array = #()
		UV_array = #()
		UV2_array = #()
		B1_array = #()
		W1_array = #()
		Weight_array = #()

		fseek f 0x0C #seek_set
		FileFlags = readshort f #unsigned
		case FileFlags of(
			default:(throw("Unexpected format!"))
			0x00:(printDebug("Model is unrigged, has short face values"))
			0x02:(printDebug("Model is rigged, has short face values"))
			0x08:(printDebug("Model is unrigged, has long face values"))
			0x0A:(printDebug("Model is rigged, has long face values"))
		)
		SingleBindID = readshort f + 1
		BoundMinX = readfloat f
		BoundMinY = readfloat f
		BoundMinZ = readfloat f
		BoundMaxX = readfloat f

		BoundMaxY = readfloat f
		BoundMaxZ = readfloat f
		BoneStart = readlong f #unsigned
		BoneCount = readlong f #unsigned

		Unknown1Start = readlong f #unsigned
		Unknown1Count = readlong f #unsigned
		PolyStart = readlong f #unsigned
		PolyCount = readlong f #unsigned

		SubGroupStart = readlong f #unsigned
		SubGroupCount = readlong f #unsigned
		ModelInfoStart = readlong f #unsigned
		ModelInfoCount = readlong f #unsigned

		BlankStart = readlong f #unsigned
		BlankCount = readlong f #unsigned
		RigBonesStart = readlong f #unsigned
		RigBonesCount = readlong f #unsigned

		RigSetStart = readlong f #unsigned
		RigSetCount = readlong f #unsigned
		MaterialStart = readlong f #unsigned
		MaterialCount = readlong f #unsigned

		VisGroupStart = readlong f #unsigned
		VisGroupCount = readlong f #unsigned
		Unknown2Start = readlong f #unsigned
		Unknown2Count = readlong f #unsigned

		fseek f BoneStart #seek_set

		for b = 1 to BoneCount do(
 			printDebug("Bone " + (b as string) + " start = 0x"+((bit.intAsHex(ftell f))as string))
			BoneName = "Bone" + (b as string)
			BoneUnk1 = readbyte f #unsigned
			BoneUnk2 = readbyte f #unsigned
			BoneParent = readshort f + 1

			BonePosX = readfloat f
			BonePosY = readfloat f
			BonePosZ = readfloat f

			BoneRotX = readfloat f
			BoneRotY = readfloat f
			BoneRotZ = readfloat f

			BoneSclX = readfloat f
			BoneSclY = readfloat f
			BoneSclZ = readfloat f

			BonePosX2 = readfloat f
			BonePosY2 = readfloat f
			BonePosZ2 = readfloat f

			BoneRotX2 = readfloat f
			BoneRotY2 = readfloat f
			BoneRotZ2 = readfloat f
				
			BoneSclX2 = readfloat f
			BoneSclY2 = readfloat f
			BoneSclZ2 = readfloat f
				
			BonePosX3 = readfloat f
			BonePosY3 = readfloat f
			BonePosZ3 = readfloat f

			tfm = scaleMatrix [BoneSclX,BoneSclY,BoneSclZ]
			tfm = tfm * (rotateXMatrix (radToDeg BoneRotX)) * (rotateYMatrix (radToDeg BoneRotY)) * (rotateZMatrix (radToDeg BoneRotZ))
			tfm.row4 = [BonePosX, BonePosY, BonePosZ]

			if (getNodeByName BoneName) != undefined do (
				append BoneArray (getNodeByName BoneName)
			)

			if (getNodeByName BoneName) == undefined do (
				if (BoneParent != 0) do (
					tfm = tfm * BoneArray[(BoneParent)].objecttransform
				)
			)

			newBone = bonesys.createbone	\
						  tfm.row4	\
						  (tfm.row4 + 0.01 * (normalize tfm.row1)) \
						  (normalize tfm.row3)
					newBone.name   = BoneName
					newBone.width  = 0.01
					newBone.height = 0.01
					newBone.transform = tfm
					newBone.setBoneEnable false 0
					newBone.wirecolor = yellow
					newbone.showlinks = true
					newBone.pos.controller      = TCB_position ()
					newBone.rotation.controller = TCB_rotation ()
				if (BoneParent != 0) then
				newBone.parent = BoneArray[BoneParent]
				append BoneArray newBone
		)

		fseek f SubGroupStart #seek_set

		for b = 1 to SubGroupCount do(
		PolyGroup = readlong f #unsigned + 1
		RigSet = readlong f #unsigned + 1
		Blank = readlong f #unsigned
		FacePointStart = readlong f #unsigned + 3
		VertexEnd = readlong f #unsigned
		FacePointCount = readlong f #unsigned
		FaceCount = readlong f #unsigned
		append SubGroupStruct_array (SubGroup_Struct PolyGroup:PolyGroup RigSet:RigSet FacePointStart:FacePointStart VertexEnd:VertexEnd FacePointCount:FacePointCount FaceCount:FaceCount) 
		)

		fseek f ModelInfoStart #seek_set

		for b = 1 to ModelInfoCount do(
		LODNameStart = readlong f #unsigned
		Blank = readlong f #unsigned
		Blank = readlong f #unsigned
		ModelDataStart = readlong f #unsigned
		ModelDataCount = readlong f #unsigned
		ModRet = (ftell f)

		fseek f LODNameStart #seek_set
		
		LODName = readstring f

		fseek f ModelDataStart #seek_set

		for c = 1 to ModelDataCount do(
			ModelGroup = readlong f #unsigned + 1
			VisGroup = readlong f #unsigned + 1
			MatID = readlong f #unsigned + 1
			FFFFFFFF = readlong f #unsigned
			Unknown2 = readlong f #unsigned + 1
			FFFFFFFF = readlong f #unsigned
			append ModelInfoStruct_array (ModelInfo_Struct ModelGroup:ModelGroup VisGroup:VisGroup MatID:MatID Unknown2:Unknown2 LODName:LODName)
		)

		fseek f ModRet #seek_set

		)

		fseek f RigBonesStart #seek_set

		for b = 1 to RigBonesCount do(
		RigBone = readlong f #unsigned + 1
		append RigBones_array RigBone
		)

		fseek f RigSetStart #seek_set

		for b = 1 to RigSetCount do(
		RigBoneStart = readlong f #unsigned
		RigBoneCount = readlong f #unsigned
		append RigSetStruct_array (RigSet_Struct RigBoneStart:RigBoneStart RigBoneCount:RigBoneCount)
		)

		fseek f PolyStart #seek_set

		for b = 1 to PolyCount do(
 			printDebug("Poly Group " + (b as string) + " start = 0x"+((bit.intAsHex(ftell f))as string))
			VertexStart = readlong f #unsigned
			VertexBStart = readlong f #unsigned
			Blank = readlong f #unsigned
			Blank = readlong f #unsigned

			VertexSize = readlong f #unsigned
			VertexBSize = readlong f #unsigned
			Blank = readlong f #unsigned
			Blank = readlong f #unsigned

			VertexCount = readlong f #unsigned
			UnknownCount = readlong f #unsigned
			FaceStart = readlong f #unsigned
			FacePointCount = readlong f #unsigned

			append PolyStruct_array (Poly_Struct VertexStart:VertexStart VertexBStart:VertexBStart VertexSize:VertexSize VertexBSize:VertexBSize VertexCount:VertexCount UnknownCount:UnknownCount FaceStart:FaceStart FacePointCount:FacePointCount)
		)

		fseek f MaterialStart #seek_set
		
		for b = 1 to MaterialCount do(
		Flags1 = readshort f #unsigned
		Flags2 = readshort f #unsigned
		Flags3 = readshort f #unsigned
		Flags4 = readshort f #unsigned
		MatName1Start = readlong f #unsigned
		MatName2Start = readlong f #unsigned
		MatTypeStart = readlong f #unsigned
		MatUnk1Count = readlong f #unsigned
		TexTypeStart = readlong f #unsigned
		TexTypeCount = readlong f #unsigned
		MatUnk2Start = readlong f #unsigned
		MatUnk2Count = readlong f #unsigned
		MatParamStart = readlong f #unsigned
		MatParamCount = readlong f #unsigned

		MatRet = (ftell f)
		
		fseek f MatName1Start #seek_set
		MatName1 = readstring f
		fseek f MatName2Start #seek_set
		MatName2 = readstring f		
		fseek f MatTypeStart #seek_set
		MatType = readstring f

		fseek f MatRet #seek_set
		append MaterialStruct_array (Material_Struct MatName1:MatName1 MatName2:MatName2 MatType:MatType MatUnk1Count:MatUnk1Count TexTypeStart:TexTypeStart TexTypeCount:TexTypeCount MatUnk2Start:MatUnk2Start MatUnk2Count:MatUnk2Count MatParamStart:MatParamStart MatParamCount:MatParamCount)

		)

		fseek f VisGroupStart #seek_set
		
		for b = 1 to VisGroupCount do(
		printDebug("Rig Set Info " + (b as string) + " start = 0x"+((bit.intAsHex(ftell f))as string))
		StringStart = readlong f #unsigned
		BoundMinX = readfloat f
		BoundMinY = readfloat f
		BoundMinZ = readfloat f
		BoundMaxX = readfloat f
		BoundMaxY = readfloat f
		BoundMaxZ = readfloat f
		MaterialIDsStart = readlong f #unsigned
		MaterialIDsCount = readlong f #unsigned
		BoneIDsStart = readlong f #unsigned
		BoneIDsCount = readlong f #unsigned
		VisRet = (ftell f)

		fseek f StringStart #seek_set
		VisName = readstring f
		append VisGroupStruct_array (VisGroup_Struct MaterialIDsStart:MaterialIDsStart MaterialIDsCount:MaterialIDsCount BoneIDsStart:BoneIDsStart BoneIDsCount:BoneIDsCount VisName:VisName)

		fseek f VisRet #seek_set
		)

		fseek f Unknown2Start #seek_set

		for b = 1 to Unknown2Count do(
		Unknown1 = readlong f #unsigned
		Unknown2 = readlong f #unsigned
		)

		VertCountStart = 1
		for m = 1 to SubGroupStruct_array.count do(
			Face_array2 = #()
			Vert_array2 = #()
			Normal_array2 = #()
			UV_array2 = #()
			Weight_array = #()
			Weight_array2 = #()

			if (m > 1 and SubGroupStruct_array[m].PolyGroup != SubGroupStruct_array[m - 1].PolyGroup) or (m == 1) do(
			Face_array = #()
			Vert_array = #()
			Normal_array = #()
			UV_array = #()
			B1_array = #()
			W1_array = #()
			VertCountStart = 1
			
			fseek f PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexStart #seek_set
 			printDebug("Vertex " + (m as string) + " start = 0x"+((bit.intAsHex(ftell f))as string))
			if FileFlags == 0x02 or FileFlags == 0x0A do(
				case of(
					default:(throw("Unexpected vertex length!"))
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexSize == 0x1C):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						nx = (readbyte f as float) / 127
						ny = (readbyte f as float) / 127
						nz = (readbyte f as float) / 127
						nq = readbyte f
						tu = readhalffloat f * 2
						tv = ((readhalffloat f * 2) * -1) + 1
						bone1 = (readbyte f #unsigned) + 1
						bone2 = (readbyte f #unsigned) + 1
						bone3 = (readbyte f #unsigned) + 1
						bone4 = (readbyte f #unsigned) + 1
						weight1 = (readbyte f #unsigned as float) / 255
						weight2 = (readbyte f #unsigned as float) / 255
						weight3 = (readbyte f #unsigned as float) / 255
						weight4 = (readbyte f #unsigned as float) / 255
						append Vert_array [vx,vy,vz]
						append UV_array [tu,tv,0]
						append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
						append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
						)
					)
				)
			)
			if FileFlags == 0x00 or FileFlags == 0x08 do(
				case of(
					default:(throw("Unexpected vertex length!"))
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexSize == 0x1C):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						nx = (readbyte f as float) / 127
						ny = (readbyte f as float) / 127
						nz = (readbyte f as float) / 127
						nq = readbyte f
						tu = readhalffloat f * 2
						tv = ((readhalffloat f * 2) * -1) + 1
						tu2 = readhalffloat f * 2
						tv2 = ((readhalffloat f * 2) * -1) + 1
						unk1 = readbyte f #unsigned
						unk2 = readbyte f #unsigned
						unk3 = readbyte f #unsigned
						unk4 = readbyte f #unsigned
						bone1 = 1
						bone2 = 1
						bone3 = 1
						bone4 = 1
						weight1 = 1
						weight2 = 0
						weight3 = 0
						weight4 = 0
						append Vert_array [vx,vy,vz]
						append UV_array [tu,tv,0]
						append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
						append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
						)
					)
				)
			)
 			printDebug("Vertex " + (m as string) + " end = 0x"+((bit.intAsHex(ftell f))as string))

			fseek f PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexBStart #seek_set
 			printDebug("Vertex Plus " + (m as string) + " start = 0x"+((bit.intAsHex(ftell f))as string))

			if FileFlags == 0x00 or FileFlags == 0x08 do(
				case of(
					default:(throw("Unexpected vertex length!"))
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexBSize == 0x08):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						nx = readhalffloat f
						ny = readhalffloat f
						nz = readhalffloat f
						nq = readhalffloat f
						append Normal_array [nx,ny,nz]
						)
					)
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexBSize == 0x0C):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						nx = readhalffloat f
						ny = readhalffloat f
						nz = readhalffloat f
						nq = readhalffloat f
						tu = readhalffloat f * 2
						tv = ((readhalffloat f * 2) * -1) + 1
						append Normal_array [nx,ny,nz]
						)
					)
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexBSize == 0x10):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						nx = readhalffloat f
						ny = readhalffloat f
						nz = readhalffloat f
						nq = readhalffloat f
						tu = readhalffloat f * 2
						tv = ((readhalffloat f * 2) * -1) + 1
						tu2 = readhalffloat f * 2
						tv2 = ((readhalffloat f * 2) * -1) + 1
						append Normal_array [nx,ny,nz]
						)
					)
				)
			)
			if FileFlags == 0x02 or FileFlags == 0x0A do(
				case of(
					default:(throw("Unexpected vertex length!"))
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexBSize == 0x0C):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						tu = readhalffloat f * 2
						tv = ((readhalffloat f * 2) * -1) + 1
						nx = readhalffloat f
						ny = readhalffloat f
						nz = readhalffloat f
						nq = readhalffloat f
						append Normal_array [nx,ny,nz]
						)
					)
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexBSize == 0x10):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						tu = readhalffloat f * 2
						tv = ((readhalffloat f * 2) * -1) + 1
						blank = readshort f #unsigned
						unknown1 = readbyte f #unsigned
						unknown2 = readbyte f #unsigned
						nx = readhalffloat f
						ny = readhalffloat f
						nz = readhalffloat f
						nq = readhalffloat f
						append Normal_array [nx,ny,nz]
						)
					)
					(PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexBSize == 0x14):(
						for v = 1 to PolyStruct_array[SubGroupStruct_array[m].PolyGroup].VertexCount do(
						tu = readhalffloat f * 2
						tv = ((readhalffloat f * 2) * -1) + 1
						unk1 = readbyte f #unsigned
						unk2 = readbyte f #unsigned
						unk3 = readbyte f #unsigned
						unk4 = readbyte f #unsigned
						nx = readhalffloat f
						ny = readhalffloat f
						nz = readhalffloat f
						nq = readhalffloat f
						tu2 = readhalffloat f * 2
						tv2 = ((readhalffloat f * 2) * -1) + 1
						append Normal_array [nx,ny,nz]
						append UV2_array [tu2,tv2,0]
						)
					)
				)
			)
 			printDebug("Vertex Plus " + (m as string) + " end = 0x"+((bit.intAsHex(ftell f))as string))

			fseek f PolyStruct_array[SubGroupStruct_array[m].PolyGroup].FaceStart #seek_set
 			printDebug("Faces " + (m as string) + " start = 0x"+((bit.intAsHex(ftell f))as string))
			case of(
				default:(
					for p = 1 to (PolyStruct_array[SubGroupStruct_array[m].PolyGroup].FacePointCount / 3) do(
					f1 = readlong f #unsigned + 1
					f2 = readlong f #unsigned + 1
					f3 = readlong f #unsigned + 1
					append Face_array [f3,f2,f1]
					)
				)
				(FileFlags == 0x00 or FileFlags == 0x02):(
					for p = 1 to (PolyStruct_array[SubGroupStruct_array[m].PolyGroup].FacePointCount / 3) do(
					f1 = readshort f #unsigned + 1
					f2 = readshort f #unsigned + 1
					f3 = readshort f #unsigned + 1
					append Face_array [f3,f2,f1]
					)
				)
			)
 			printDebug("Faces " + (m as string) + " end = 0x"+((bit.intAsHex(ftell f))as string))

			)
			
			FixRig_array = #()

			if RigSetCount > 0 then(
				fseek f RigSetStruct_array[SubGroupStruct_array[m].RigSet].RigBoneStart #seek_set
				for x = 1 to RigSetStruct_array[SubGroupStruct_array[m].RigSet].RigBoneCount do(
				RigBone = RigBones_array[readshort f #unsigned + 1]
				append FixRig_array RigBone
				)
			) else (append FixRig_array SingleBindID)

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
					 append w.boneids (FixRig_array[B1_array[b].Bone1])
					 append w.weights (w1)
				  )
				  if(W1_array[b].Weight2 != 0) then
				  (
					 w2 = W1_array[b].Weight2 as float
					 append w.boneids (FixRig_array[B1_array[b].Bone2])
					 append w.weights (w2)
				  )
				  if(W1_array[b].Weight3 != 0) then
				  (
					 w3 = W1_array[b].Weight3 as float
					 append w.boneids (FixRig_array[B1_array[b].Bone3])
					 append w.weights (w3)
				  )
				  if(W1_array[b].Weight4 != 0) then
				  (
					 w4 = W1_array[b].Weight4 as float
					 append w.boneids (FixRig_array[B1_array[b].Bone4])
					 append w.weights (w4)
				  )      
			   )
			append Weight_array w
			)

			for x = VertCountStart to SubGroupStruct_array[m].VertexEnd do(
			append Vert_array2 Vert_array[x]
			append Normal_array2 Normal_array[x]
			append UV_array2 UV_array[x]
			append Weight_array2 Weight_array[x]
			)

			for x = (SubGroupStruct_array[m].FacePointStart / 3) to ((SubGroupStruct_array[m].FacePointStart / 3) + (SubGroupStruct_array[m].FacePointCount / 3) - 1) do(
				Faces2 = ((Face_array[x] - VertCountStart) + 1)
				append Face_array2 Faces2
			)

			VertCountStart = (VertCountStart + (SubGroupStruct_array[m].VertexEnd - VertCountStart) + 1)

			if ModelInfoStruct_array[m].LODName == "LOD0" or LODEnable == true do(

				msh = mesh vertices:Vert_array2 faces:Face_array2
				msh.numTVerts = Vert_array2.count
				defaultVCFaces msh
				buildTVFaces msh
				msh.name = (VisGroupStruct_array[ModelInfoStruct_array[m].VisGroup].VisName + " (" + MaterialStruct_array[ModelInfoStruct_array[m].MatID].MatName1 + ") <" + ModelInfoStruct_array[m].LODName + ">")
				for j = 1 to UV_array2.count do setTVert msh j UV_array2[j]
				for j = 1 to Face_array2.count do setTVFace msh j Face_array2[j]
				for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
				max modify mode
				select msh

				for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
				select msh
				addmodifier msh (Edit_Normals ()) ui:off
				msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
				EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
				EN_setNormal = msh.Edit_Normals.SetNormal
				normID = #{}
				for v = 1 to Normal_array2.count do
				(
					free normID
					EN_convertVS #{v} &normID
					for id in normID do EN_setNormal id Normal_array2[v]
				)

				if BoneCount > 0 do(
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

			)

		)

	)
	
	fclose f
)
)

)

CreateDialog NieRAutomataRollout