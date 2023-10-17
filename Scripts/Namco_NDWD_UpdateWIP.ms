-- Pokken Tournament / Touch My Katamari model importer by Random Talking Bush.
-- Totally not recycled from my Smash Bros. importer.

-- Changelog:
-- May 24th, 2020: Added bugfixing for 3DS Max 2015+, and some tidying up.
-- September 6th, 2016. Added support for Touch My Katamari's models, which were nearly identical to Pokken's.

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

fn readHalfFloat fstream = (
	return convertTo32(Readshort fstream)
)

rollout PokkenImporter "Pokken Tournament / Touch My Katamari model importer" width:390 height:145
(
	button btnImport "Import Model" pos:[8,8] width:375 height:40
	label lblDisclaimer "This script was written by Random Talking Bush, if you use it, please remember to give me thanks for this. If something doesn't work right, please contact me on The VG Resource (Random Talking Bush), Twitter, Tumblr or Steam (RandomTBush) and let me know, and I'll try to fix it." pos:[8,50] width:375 height:80
	label lblUpdate "(Updated: 05/24/2020)" pos:[238,125] width:375 height:80
	checkbox tglColorMult "Multiply vertex colours?" pos:[8,108] width:150 height:15 tooltip: "If this is enabled, the model will multiply the colour values by 2 (so instead of 127 being the default, it'll be 255 -- any colour values above 127 will be lost, though)." checked: false
	checkbox tglColorDisable "Disable vertex colours?" pos:[8,125] width:150 height:15 tooltip: "Pokken Tournament's use of vertex colouring is odd, and doesn't work well outside of the game. Check this to disable it." checked: true
	checkbox tglPNGTex "Use PNG instead of DDS?" pos:[238,108] width:150 height:15 tooltip: "Self explanatory." checked: false

	on btnImport pressed do(
		local colormult = tglColorMult.checked
		local colordisable = tglColorDisable.checked
		local PNGTex = tglPNGTex.checked
		clearlistener()
		fname = getOpenFileName \ 
		caption:"Pokken Tournament model file" \
		types:"Pokken Tournament model(*.nud)|*.nud" \
		historyCategory:"PokkenTournament"

		if fname != undefined do (
			m = fopen fname "rb"
			p = getFilenamePath fname
			h = getFilenameFile fname
			fname2 = p + h + ".vbn"
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
			VertexSize_array = #()
			PolyStart_array = #()
			PolyAmount_array = #()
			PolySize_array = #()
			VertexAddStart_array = #()
			UVSize_array = #()
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
			NDP3 = readlong m #unsigned
			filesize = readlong m #unsigned
			unknown1 = readshort m #unsigned
			polysets = readshort m #unsigned
			unknown2 = readshort m #unsigned
			somethingsets = readshort m #unsigned
			PolyClumpStart = (readlong m #unsigned) + 0x30
			PolyClumpSize = readlong m #unsigned
			VertexClumpStart = (PolyClumpStart + PolyClumpSize)
			VertexClumpSize = readlong m #unsigned
			VertexAddClumpStart = (VertexClumpStart + VertexClumpSize)
			VertexAddClumpSize = readlong m #unsigned
			NameClumpStart = (VertexAddClumpStart + VertexAddClumpSize)
			thisfloat1 = readlong m #unsigned
			thisfloat2 = readlong m #unsigned
			thisfloat3 = readlong m #unsigned
			thisfloat4 = readlong m #unsigned

			ObjCount = 0
			for z = 1 to polysets do(
				floata = readlong m #unsigned
				floatb = readlong m #unsigned
				floatc = readlong m #unsigned
				floatd = readlong m #unsigned
				floate = readlong m #unsigned
				floatf = readlong m #unsigned
				floatg = readlong m #unsigned
				floath = readlong m #unsigned
				polynamestart = readlong m #unsigned
				identifiera = readlong m #unsigned
				singlebind = readshort m #unsigned + 1
				if SingleBind == 65536 do(SingleBind = 1)
				polyamount = readshort m #unsigned
				positionb = readlong m #unsigned
				ObjCount = (ObjCount + polyamount)
				for s = 1 to polyamount do(
					append PolyName_array polynamestart
					append SingleBind_array singlebind
				)
			)

			for z = 1 to ObjCount do(
				PolyStart = (readlong m #unsigned + PolyClumpStart)
				VertexStart = (readlong m #unsigned + VertexClumpStart)
				VertexAddStart = (readlong m #unsigned + VertexAddClumpStart)
				VertexAmount = readshort m #unsigned
				VertexSize = readbyte m #unsigned
				UVSize = readbyte m #unsigned
				TextureLayer1Properties = readlong m #unsigned
				TextureLayer2Properties = readlong m #unsigned
				TextureLayer3Properties = readlong m #unsigned
				TextureLayer4Properties = readlong m #unsigned
				PolyAmount = readshort m #unsigned
				PolySize = readbyte m #unsigned
				PolyFlag = readbyte m #unsigned
				fseek m 0x0C #seek_cur
				append VertexStart_array VertexStart
				append PolyStart_array PolyStart
				append VertexAddStart_array VertexAddStart
				append VertexAmount_array VertexAmount
				append PolyAmount_array PolyAmount
				append VertexSize_array VertexSize
				append UVSize_array UVSize
				append PolySize_array PolySize
				append TexturePropertiesS1Start_array TextureLayer1Properties
				append TexturePropertiesS2Start_array TextureLayer2Properties
				append TexturePropertiesS3Start_array TextureLayer3Properties
				append TexturePropertiesS4Start_array TextureLayer4Properties
			)

			BoneCount = 0

			if q != undefined do(
				VBN = readlong q
				fseek q 0x08 #seek_set

				if VBN == 0x56424E20 do(
					fseek q 0x04 #seek_cur
					BoneCount = readlong q #unsigned
					fseek q 0x20 #seek_set
					for x = 1 to BoneCount do(
						jumpman = (ftell q + 0x44)
						BoneName = readstring q
						fseek q jumpman #seek_set
						BoneParent = readshort q + 1
						fseek q 0x02 #seek_cur
						if BoneParent == 0 do(BoneParent = -1)
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
				nothing = readlong m #unsigned
				TexSomethingCount = readshort m #unsigned
				TexLayerCount = readshort m #unsigned
				UnkTex5 = readbyte m #unsigned
				UnkTex6 = readbyte m #unsigned
				UnkTex7 = readbyte m #unsigned
				UnkTex8 = readbyte m #unsigned
				something = readlong m #unsigned
				nothing = readlong m #unsigned
				nothing = readlong m #unsigned
				nothing = readlong m #unsigned
				print "Texture information:"

				for x = 1 to TexLayerCount do(
					TexIndex = readbyte m #unsigned
					TexSubgroup = readbyte m #unsigned
					TexGroup = readbyte m #unsigned
					TexClass = readbyte m #unsigned
					case x of(
						default:(throw("Unexpected TexLayer value!"))
						1:(
							Layer1Write = 1
							append TextureIDL1_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
						)
						2:(
							Layer2Write = 1
							append TextureIDL2_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
						)
						3:(
							Layer3Write = 1
							append TextureIDL3_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
						)
						4:(
							Layer4Write = 1
							append TextureIDL4_array (TexIDSet_Struct TexClass:TexClass TexGroup:TexGroup TexSubgroup:TexSubgroup TexIndex:TexIndex)
						)
					)
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					UnkTexC = readbyte m #unsigned
					UnkTexD = readbyte m #unsigned
					UnkTexE = readbyte m #unsigned
					UnkTexF = readbyte m #unsigned
					UnkTexG = readbyte m #unsigned
					UnkTexH = readbyte m #unsigned
					UnkTexI = readbyte m #unsigned
					UnkTexJ = readbyte m #unsigned
					nothing = readlong m #unsigned
					print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
				)

				headerread = readlong m #unsigned
				fseek m -0x04 #seek_cur
				if headerread != 0 do(
					do(
						headerread = readlong m #unsigned
						TexPropNameStart = readlong m #unsigned
						something4 = readlong m #unsigned
						nothing = readlong m #unsigned
						TexFloatStart = (ftell m)
						TexFloatA = readfloat m
						TexFloatB = readfloat m
						TexFloatC = readfloat m
						TexFloatD = readfloat m
						fseek m (NameClumpStart + TexPropNameStart) #seek_set
						TexPropName = readstring m
						fseek m (TexFloatStart + 0x10) #seek_set
						if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
						if TexPropName == "NU_materialHash" do(
							fseek m -0x10 #seek_cur
							TexFloatA = readlong m #unsigned
							TexFloatB = readlong m #unsigned
							TexFloatC = readlong m #unsigned
							TexFloatD = readlong m #unsigned	
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
					nothing = readlong m #unsigned
					TexSomethingCount = readshort m #unsigned
					TexLayerCount = readshort m #unsigned
					UnkTex5 = readbyte m #unsigned
					UnkTex6 = readbyte m #unsigned
					UnkTex7 = readbyte m #unsigned
					UnkTex8 = readbyte m #unsigned
					something = readlong m #unsigned
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					print "Texture information:"
						
					for x = 1 to TexLayerCount do(
						TexIndex = readbyte m #unsigned
						TexSubgroup = readbyte m #unsigned
						TexGroup = readbyte m #unsigned
						TexClass = readbyte m #unsigned
						nothing = readlong m #unsigned
						nothing = readlong m #unsigned
						UnkTexC = readbyte m #unsigned
						UnkTexD = readbyte m #unsigned
						UnkTexE = readbyte m #unsigned
						UnkTexF = readbyte m #unsigned
						UnkTexG = readbyte m #unsigned
						UnkTexH = readbyte m #unsigned
						UnkTexI = readbyte m #unsigned
						UnkTexJ = readbyte m #unsigned
						nothing = readlong m #unsigned
						print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
					)

					headerread = readBElong m
					fseek m -0x04 #seek_cur
					if headerread != 0 do(
						do(
							headerread = readlong m #unsigned
							TexPropNameStart = readlong m #unsigned
							something4 = readlong m #unsigned
							nothing = readlong m #unsigned
							TexFloatStart = (ftell m)
							TexFloatA = readfloat m
							TexFloatB = readfloat m
							TexFloatC = readfloat m
							TexFloatD = readfloat m
							fseek m (NameClumpStart + TexPropNameStart) #seek_set
							TexPropName = readstring m
							fseek m (TexFloatStart + 0x10) #seek_set
							if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
							if TexPropName == "NU_materialHash" do(
								fseek m -0x10 #seek_cur
								TexFloatA = readlong m #unsigned
								TexFloatB = readlong m #unsigned
								TexFloatC = readlong m #unsigned
								TexFloatD = readlong m #unsigned	
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
					nothing = readlong m #unsigned
					TexSomethingCount = readshort m #unsigned
					TexLayerCount = readshort m #unsigned
					UnkTex5 = readbyte m #unsigned
					UnkTex6 = readbyte m #unsigned
					UnkTex7 = readbyte m #unsigned
					UnkTex8 = readbyte m #unsigned
					something = readlong m #unsigned
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					print "Texture information:"
						
					for x = 1 to TexLayerCount do(
						TexIndex = readbyte m #unsigned
						TexSubgroup = readbyte m #unsigned
						TexGroup = readbyte m #unsigned
						TexClass = readbyte m #unsigned
						nothing = readlong m #unsigned
						nothing = readlong m #unsigned
						UnkTexC = readbyte m #unsigned
						UnkTexD = readbyte m #unsigned
						UnkTexE = readbyte m #unsigned
						UnkTexF = readbyte m #unsigned
						UnkTexG = readbyte m #unsigned
						UnkTexH = readbyte m #unsigned
						UnkTexI = readbyte m #unsigned
						UnkTexJ = readbyte m #unsigned
						nothing = readlong m #unsigned
						print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
					)

					headerread = readBElong m
					fseek m -0x04 #seek_cur
					if headerread != 0 do(
						do(
							headerread = readlong m #unsigned
							TexPropNameStart = readlong m #unsigned
							something4 = readlong m #unsigned
							nothing = readlong m #unsigned
							TexFloatStart = (ftell m)
							TexFloatA = readfloat m
							TexFloatB = readfloat m
							TexFloatC = readfloat m
							TexFloatD = readfloat m
							fseek m (NameClumpStart + TexPropNameStart) #seek_set
							TexPropName = readstring m
							fseek m (TexFloatStart + 0x10) #seek_set
							if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
							if TexPropName == "NU_materialHash" do(
								fseek m -0x10 #seek_cur
								TexFloatA = readlong m #unsigned
								TexFloatB = readlong m #unsigned
								TexFloatC = readlong m #unsigned
								TexFloatD = readlong m #unsigned	
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
					nothing = readlong m #unsigned
					TexSomethingCount = readshort m #unsigned
					TexLayerCount = readshort m #unsigned
					UnkTex5 = readbyte m #unsigned
					UnkTex6 = readbyte m #unsigned
					UnkTex7 = readbyte m #unsigned
					UnkTex8 = readbyte m #unsigned
					something = readlong m #unsigned
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					print "Texture information:"
						
					for x = 1 to TexLayerCount do(
					TexIndex = readbyte m #unsigned
					TexSubgroup = readbyte m #unsigned
					TexGroup = readbyte m #unsigned
					TexClass = readbyte m #unsigned
					nothing = readlong m #unsigned
					nothing = readlong m #unsigned
					UnkTexC = readbyte m #unsigned
					UnkTexD = readbyte m #unsigned
					UnkTexE = readbyte m #unsigned
					UnkTexF = readbyte m #unsigned
					UnkTexG = readbyte m #unsigned
					UnkTexH = readbyte m #unsigned
					UnkTexI = readbyte m #unsigned
					UnkTexJ = readbyte m #unsigned
					nothing = readlong m #unsigned
					print ("Class: " + TexClass as string+ ", Group: " + TexGroup as string + ", Subgroup " + TexSubgroup as string + ", Index " + TexIndex as string)
					)

					headerread = readBElong m
					fseek m -0x04 #seek_cur
					if headerread != 0 do(do(
					headerread = readlong m #unsigned
					TexPropNameStart = readlong m #unsigned
					something4 = readlong m #unsigned
					nothing = readlong m #unsigned
					TexFloatStart = (ftell m)
					TexFloatA = readfloat m
					TexFloatB = readfloat m
					TexFloatC = readfloat m
					TexFloatD = readfloat m
					fseek m (NameClumpStart + TexPropNameStart) #seek_set
					TexPropName = readstring m
					fseek m (TexFloatStart + 0x10) #seek_set
					if TexPropName != "NU_materialHash" do(print ("(0x" + ((bit.intAsHex(TexFloatStart))as string) + ") " + TexPropName as string + " = " + TexFloatA as string + ", " + TexFloatB as string + ", " + TexFloatC as string + ", " + TexFloatD as string))
					if TexPropName == "NU_materialHash" do(
						fseek m -0x10 #seek_cur
						TexFloatA = readlong m #unsigned
						TexFloatB = readlong m #unsigned
						TexFloatC = readlong m #unsigned
						TexFloatD = readlong m #unsigned	
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
				case VertexSize_array[z] of(
					default:(throw("Unexpected vertex size!"))
					0x00:(
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							floatyval = readfloat m
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
							tu = (readhalffloat m) * 2
							tv = (((readhalffloat m) * 2) * -1) + 1
							if UVSize_array[z] >= 0x20 do(
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								append UV2_array[tu2, tv2, 0]
							)
							if UVSize_array[z] >= 0x30 do(
								tu3 = (readhalffloat m) * 2
								tv3 = (((readhalffloat m) * 2) * -1) + 1
								append UV3_array[tu3, tv3, 0]
							)
							if UVSize_array[z] >= 0x40 do(
								tu4 = (readhalffloat m) * 2
								tv4 = (((readhalffloat m) * 2) * -1) + 1
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
					)
					0x06:(
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							nx = readhalffloat m
							ny = readhalffloat m
							nz = readhalffloat m
							nq = readhalffloat m
							colorr = 255
							colorg = 255
							colorb = 255
							colora = 255
							if UVSize_array[z] == 0x12 or UVSize_array[z] == 0x22 or UVSize_array[z] == 0x32 or UVSize_array[z] == 0x42 do(
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
							if UVSize_array[z] == 0x14 or UVSize_array[z] == 0x24 or UVSize_array[z] == 0x34 or UVSize_array[z] == 0x44 do(
								nx2 = readhalffloat m
								ny2 = readhalffloat m
								nz2 = readhalffloat m
								nq2 = readhalffloat m
							)
							if UVSize_array[z] == 0x10 or UVSize_array[z] == 0x12 or UVSize_array[z] == 0x14 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
							)
							if UVSize_array[z] == 0x11 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
							)
							if UVSize_array[z] == 0x20 or UVSize_array[z] == 0x22 or UVSize_array[z] == 0x24 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
							)
							if UVSize_array[z] == 0x21 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
							)
							if UVSize_array[z] == 0x30 or UVSize_array[z] == 0x32 or UVSize_array[z] == 0x34 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								tu3 = (readhalffloat m) * 2
								tv3 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
							)
							if UVSize_array[z] == 0x31 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								tu3 = readfloat m
								tv3 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
							)
							if UVSize_array[z] == 0x40 or UVSize_array[z] == 0x42 or UVSize_array[z] == 0x44 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								tu3 = (readhalffloat m) * 2
								tv3 = (((readhalffloat m) * 2) * -1) + 1
								tu4 = (readhalffloat m) * 2
								tv4 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
								append UV4_array[tu4, tv4, 0]
							)
							if UVSize_array[z] == 0x41 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								tu3 = readfloat m
								tv3 = ((readfloat m) * -1) + 1
								tu4 = readfloat m
								tv4 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
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
							append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
							append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
						)
					)
					0x07:(
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							nx = readhalffloat m
							ny = readhalffloat m
							nz = readhalffloat m
							nq = readhalffloat m
							nx2 = readhalffloat m
							ny2 = readhalffloat m
							nz2 = readhalffloat m
							nq2 = readhalffloat m
							nx3 = readhalffloat m
							ny3 = readhalffloat m
							nz3 = readhalffloat m
							nq3 = readhalffloat m
							colorr = 255
							colorg = 255
							colorb = 255
							colora = 255
							if UVSize_array[z] == 0x12 or UVSize_array[z] == 0x22 or UVSize_array[z] == 0x32 or UVSize_array[z] == 0x42 do(
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
							if UVSize_array[z] == 0x14 or UVSize_array[z] == 0x24 or UVSize_array[z] == 0x34 or UVSize_array[z] == 0x44 do(
								nx4 = readhalffloat m
								ny4 = readhalffloat m
								nz4 = readhalffloat m
								nq4 = readhalffloat m
							)
							if UVSize_array[z] == 0x10 or UVSize_array[z] == 0x12 or UVSize_array[z] == 0x14 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
							)
							if UVSize_array[z] == 0x11 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
							)
							if UVSize_array[z] == 0x20 or UVSize_array[z] == 0x22 or UVSize_array[z] == 0x24 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
							)
							if UVSize_array[z] == 0x21 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
							)
							if UVSize_array[z] == 0x30 or UVSize_array[z] == 0x32 or UVSize_array[z] == 0x34 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								tu3 = (readhalffloat m) * 2
								tv3 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
							)
							if UVSize_array[z] == 0x31 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								tu3 = readfloat m
								tv3 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
							)
							if UVSize_array[z] == 0x40 or UVSize_array[z] == 0x42 or UVSize_array[z] == 0x44 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								tu3 = (readhalffloat m) * 2
								tv3 = (((readhalffloat m) * 2) * -1) + 1
								tu4 = (readhalffloat m) * 2
								tv4 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
								append UV4_array[tu4, tv4, 0]
							)
							if UVSize_array[z] == 0x41 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								tu3 = readfloat m
								tv3 = ((readfloat m) * -1) + 1
								tu4 = readfloat m
								tv4 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
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
							append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
							append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
						)
					)
					0x08:(
						for x = 1 to VertexAmount_array[z] do(
							vx = 0
							vy = 0
							vz = 0
							nx = readhalffloat m
							ny = readhalffloat m
							nz = readhalffloat m
							nq = readhalffloat m
							nx2 = readhalffloat m
							ny2 = readhalffloat m
							nz2 = readhalffloat m
							nq2 = readhalffloat m
							nx3 = readhalffloat m
							colorr = 255
							colorg = 255
							colorb = 255
							colora = 255
							if UVSize_array[z] == 0x12 or UVSize_array[z] == 0x22 or UVSize_array[z] == 0x32 or UVSize_array[z] == 0x42 do(
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
							if UVSize_array[z] == 0x14 or UVSize_array[z] == 0x24 or UVSize_array[z] == 0x34 or UVSize_array[z] == 0x44 do(
								nx4 = readhalffloat m
								ny4 = readhalffloat m
								nz4 = readhalffloat m
								nq4 = readhalffloat m
							)
							if UVSize_array[z] == 0x10 or UVSize_array[z] == 0x12 or UVSize_array[z] == 0x14 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
							)
							if UVSize_array[z] == 0x11 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
							)
							if UVSize_array[z] == 0x20 or UVSize_array[z] == 0x22 or UVSize_array[z] == 0x24 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
							)
							if UVSize_array[z] == 0x21 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
							)
							if UVSize_array[z] == 0x30 or UVSize_array[z] == 0x32 or UVSize_array[z] == 0x34 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								tu3 = (readhalffloat m) * 2
								tv3 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
							)
							if UVSize_array[z] == 0x31 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								tu3 = readfloat m
								tv3 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
							)
							if UVSize_array[z] == 0x40 or UVSize_array[z] == 0x42 or UVSize_array[z] == 0x44 do(
								tu = (readhalffloat m) * 2
								tv = (((readhalffloat m) * 2) * -1) + 1
								tu2 = (readhalffloat m) * 2
								tv2 = (((readhalffloat m) * 2) * -1) + 1
								tu3 = (readhalffloat m) * 2
								tv3 = (((readhalffloat m) * 2) * -1) + 1
								tu4 = (readhalffloat m) * 2
								tv4 = (((readhalffloat m) * 2) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
								append UV4_array[tu4, tv4, 0]
							)
							if UVSize_array[z] == 0x41 do(
								tu = readfloat m
								tv = ((readfloat m) * -1) + 1
								tu2 = readfloat m
								tv2 = ((readfloat m) * -1) + 1
								tu3 = readfloat m
								tv3 = ((readfloat m) * -1) + 1
								tu4 = readfloat m
								tv4 = ((readfloat m) * -1) + 1
								append UV_array[tu, tv, 0]
								append UV2_array[tu2, tv2, 0]
								append UV3_array[tu3, tv3, 0]
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
							append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
							append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
						)
					)
					0x11:(
						case UVSize_array[z] of(
							default:(throw("Unexpected UV size!"))
							0x10:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x12:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x14:(
								for x = 1 to VertexAmount_array[z] do(
									nx2 = readhalffloat m
									ny2 = readhalffloat m
									nz2 = readhalffloat m
									nq2 = readhalffloat m
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
								)
							)
							0x20:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x22:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x24:(
								for x = 1 to VertexAmount_array[z] do(
									nx2 = readhalffloat m
									ny2 = readhalffloat m
									nz2 = readhalffloat m
									nq2 = readhalffloat m
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
								)
							)
							0x30:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x32:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x34:(
								for x = 1 to VertexAmount_array[z] do(
									nx2 = readhalffloat m
									ny2 = readhalffloat m
									nz2 = readhalffloat m
									nq2 = readhalffloat m
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
								)
							)
							0x40:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x42:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x44:(
								for x = 1 to VertexAmount_array[z] do(
									nx2 = readhalffloat m
									ny2 = readhalffloat m
									nz2 = readhalffloat m
									nq2 = readhalffloat m
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
								)
							)
						)
						fseek m VertexAddStart_array[z] #seek_set
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							nx = readfloat m
							ny = readfloat m
							nz = readfloat m
							nq = readfloat m
							nr = readfloat m
							Bone1 = readlong m #unsigned + 1
							Bone2 = readlong m #unsigned + 1
							Bone3 = readlong m #unsigned + 1
							Bone4 = readlong m #unsigned + 1
							Weight1 = readfloat m
							Weight2 = readfloat m
							Weight3 = readfloat m
							Weight4 = readfloat m
							append Vert_array[vx, vy, vz]
							append Normal_array[nx, ny, nz]
							append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
							append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
						)
					)
					0x13:(
						case UVSize_array[z] of(
							default:(throw("Unexpected UV size!"))
							0x10:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x12:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x20:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x22:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x30:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x32:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x40:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x42:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
						)
						fseek m VertexAddStart_array[z] #seek_set
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							vq = readfloat m
							nx = readfloat m
							ny = readfloat m
							nz = readfloat m
							nq = readfloat m
							nx2 = readfloat m
							ny2 = readfloat m
							nz2 = readfloat m
							nq2 = readfloat m
							nx3 = readfloat m
							ny3 = readfloat m
							nz3 = readfloat m
							nq3 = readfloat m
							Bone1 = readlong m #unsigned + 1
							Bone2 = readlong m #unsigned + 1
							Bone3 = readlong m #unsigned + 1
							Bone4 = readlong m #unsigned + 1
							Weight1 = readfloat m
							Weight2 = readfloat m
							Weight3 = readfloat m
							Weight4 = readfloat m
							append Vert_array[vx, vy, vz]
							append Normal_array[nx, ny, nz]
							append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
							append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
						)
					)
					0x40:(
						case UVSize_array[z] of(
							default:(throw("Unexpected UV size!"))
							0x12:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x22:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x32:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x42:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
						)
						fseek m VertexAddStart_array[z] #seek_set
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							floatyval = readfloat m
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
					)
					0x46:(
						case UVSize_array[z] of(
							default:(throw("Unexpected UV size!"))
							0x10:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x12:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x20:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x22:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x30:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x32:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x40:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x42:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
						)
						fseek m VertexAddStart_array[z] #seek_set
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							nx = readhalffloat m
							ny = readhalffloat m
							nz = readhalffloat m
							nq = readhalffloat m
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
					)
					0x47:(
						case UVSize_array[z] of(
							default:(throw("Unexpected UV size!"))
							0x10:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x12:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x20:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x22:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x30:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x32:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x40:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
							0x42:(
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
									tu = (readhalffloat m) * 2
									tv = (((readhalffloat m) * 2) * -1) + 1
									tu2 = (readhalffloat m) * 2
									tv2 = (((readhalffloat m) * 2) * -1) + 1
									tu3 = (readhalffloat m) * 2
									tv3 = (((readhalffloat m) * 2) * -1) + 1
									tu4 = (readhalffloat m) * 2
									tv4 = (((readhalffloat m) * 2) * -1) + 1
									append UV_array[tu, tv, 0]
									append UV2_array[tu2, tv2, 0]
									append UV3_array[tu3, tv3, 0]
									append UV4_array[tu4, tv4, 0]
									append Color_Array[colorr,colorg,colorb]
									append Alpha_Array colora
								)
							)
						)
						fseek m VertexAddStart_array[z] #seek_set
						for x = 1 to VertexAmount_array[z] do(
							vx = readfloat m
							vy = readfloat m
							vz = readfloat m
							nx = readhalffloat m
							ny = readhalffloat m
							nz = readhalffloat m
							nq = readhalffloat m
							nx2 = readhalffloat m
							ny2 = readhalffloat m
							nz2 = readhalffloat m
							nq2 = readhalffloat m
							nx3 = readhalffloat m
							ny3 = readhalffloat m
							nz3 = readhalffloat m
							nq3 = readhalffloat m
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
					)
				)

				fseek m PolyStart_array[z] #seek_set
				case PolySize_array[z] of(
					default:(throw("Unexpected poly size!"))
					0x00:(
						FaceCount = PolyAmount_array[z]
						FaceStart = ftell m
						VerStart = (FaceCount * 2) + FaceStart
						StartDirection = 1
						f1 = (readshort m #unsigned) + 1
						f2 = (readshort m #unsigned) + 1  
						FaceDirection = StartDirection
						Do (
							f3 = (readshort m #unsigned)
							if (f3==0xFFFF) then (
								f1 = (readshort m #unsigned) + 1
								f2 = (readshort m #unsigned) + 1
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
					)
					0x04:(
						FaceCount = PolyAmount_array[z]
						FaceStart = ftell m
						VerStart = (FaceCount * 2) + FaceStart
						StartDirection = 1
						f1 = (readshort m #unsigned) + 1
						f2 = (readshort m #unsigned) + 1  
						FaceDirection = StartDirection
						Do (
							f3 = (readshort m #unsigned)
							if (f3==0xFFFF) then (
								f1 = (readshort m #unsigned) + 1
								f2 = (readshort m #unsigned) + 1
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
				if PNGTex == false then (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL1_array[z].TexClass as string + "_" + TextureIDL1_array[z].TexGroup as string + "_" + TextureIDL1_array[z].TexSubgroup as string + "_" + TextureIDL1_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL1_array[z].TexClass as string + "_" + TextureIDL1_array[z].TexGroup as string + "_" + TextureIDL1_array[z].TexSubgroup as string + "_" + TextureIDL1_array[z].TexIndex as string + ".png"))
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

				for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
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
					if PNGTex == false then (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL2_array[z].TexClass as string + "_" + TextureIDL2_array[z].TexGroup as string + "_" + TextureIDL2_array[z].TexSubgroup as string + "_" + TextureIDL2_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL2_array[z].TexClass as string + "_" + TextureIDL2_array[z].TexGroup as string + "_" + TextureIDL2_array[z].TexSubgroup as string + "_" + TextureIDL2_array[z].TexIndex as string + ".png"))
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

					for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
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
					if PNGTex == false then (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL3_array[z].TexClass as string + "_" + TextureIDL3_array[z].TexGroup as string + "_" + TextureIDL3_array[z].TexSubgroup as string + "_" + TextureIDL3_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL3_array[z].TexClass as string + "_" + TextureIDL3_array[z].TexGroup as string + "_" + TextureIDL3_array[z].TexSubgroup as string + "_" + TextureIDL3_array[z].TexIndex as string + ".png"))
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

					for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
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
					if PNGTex == false then (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL4_array[z].TexClass as string + "_" + TextureIDL4_array[z].TexGroup as string + "_" + TextureIDL4_array[z].TexSubgroup as string + "_" + TextureIDL4_array[z].TexIndex as string + ".dds")) else (tm = Bitmaptexture filename:(p + h + "_" + TextureIDL4_array[z].TexClass as string + "_" + TextureIDL4_array[z].TexGroup as string + "_" + TextureIDL4_array[z].TexSubgroup as string + "_" + TextureIDL4_array[z].TexIndex as string + ".png"))
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

					for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
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

			)

		)

		gc()
		fclose m
		fclose q
	)
)

CreateDialog PokkenImporter