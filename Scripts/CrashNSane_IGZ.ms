-- Crash Bandicoot: N-Sane Trilogy / Crash Team Racing: Nitro-Fueled (a.k.a. Alchemy Crash) *.IGZ Importer by Random Talking Bush
-- woah

rollout ModelImporter "Crash Bandicoot NST / CTR:NF Model Importer" width:330 height:210
(
	button btnImport "Import *.IGZ" pos:[7,8] width:316 height:50
	groupBox OptionsBox "Options" pos:[7,58] width:316 height:50
	radiobuttons tglMdlFormat "Model type:" labels:#("Actors","Models") pos:[18,72] height:10 columns:2 default:1
	checkbox tglDebug "Print debug information?" pos:[170,78] checked: false
	label lblCred "This work-in-progress script was written by Random Talking Bush for use with Crash Bandicoot: N-Sane Trilogy and Crash Team Racing: Nitro-Fueled. If used, please consider giving thanks to me, Naughty Dog, Vicarious Visions, Beenox and Activision. If something doesn't work right (which is likely for props and levels), please contact me on The VG Resource (Random Talking Bush), XeNTaX, Twitter or Steam (RandomTBush) so I can fix it." pos:[8,112] width:317 height:100

	fn readHalfFloat fstream = (
		local BL  = readByte Fstream #unsigned
		local BH  = readByte Fstream #unsigned
		local N = BH*256 + BL
		local S = floor((mod N 65536) / 32768)
		local Ef = floor((mod N 32768) / 1024)
		local M = mod N 1024
		if (Ef==0)AND(M==0) then return ( (-1.0)^S * 0.0 )
		if (Ef==0)AND(M!=0) then return ( (-1.0)^S * 2.0^-14 * (M / 2.0^10) )
		if (Ef>0)AND(Ef<31) then return ( (-1.0)^S * 2.0^(Ef-15) * (1 + M/2.0^10) )
		if (Ef==31)AND(M==0) then return ( (-1.0)^S * 1/0.0 )
		if (Ef==31)AND(M!=0) then return 0
	)

	fn printDebug pr = (if tglDebug.state do print(pr))

	on btnImport pressed do(
		clearlistener()
		local ModelFormat = tglMdlFormat.state
		fname = getOpenFileName \ 
		caption:"Crash Bandicoot N-Sane Trilogy / Crash Team Racing Nitro-Fueled Model File" \
		types:"Crash Bandicoot *.IGZ Model File|*.igz" \
		historyCategory:"CrashNSaneObjectPresets"
		if fname != undefined do(
			f = fopen fname "rb"
			p = getFilenamePath fname
			g = getFilenameFile fname
			st = timestamp()

			struct Material_Struct
			(
				MatName, MatDep
			)
			struct VertBuffer_Struct
			(
				VertFormat1, VertFormat2, VertFormat3, VertFormat4, VertType, VertLayer, VertUnk1, VertUnk2, VertShift
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

			BoneArray = #()
			BoneName_array = #()
			BoneParent_array = #()
			String_array = #()
			Materials_array = #()
			NodeID_array = #()

			IGZMagic = readlong f
			fseek f 0x10 #seek_set
			IGZMagicCount = readlong f
			if IGZMagic == 0x49475A01 do(
				fseek f 0x0800 #seek_set
				for b = 1 to IGZMagicCount do(
					NextOffset = (ftell f)
					IGZMagic = readlong f
					case IGZMagic of(
						default:(throw("Unexpected section type!"))
						0x50454454:(
							printDebug ("TDEP: " + NextOffset as string)
							TDEPCount = readlong f
							TDEPSize = readlong f
							TDEPStart = readlong f
							NextOffset = (NextOffset + TDEPSize)
							print "Dependencies:"
							for i = 1 to TDEPCount do(
								TDEPStringA = readstring f
								CheckByte = readbyte f
								if CheckByte != 0x00 do (fseek f -1 #seek_cur)
								TDEPStringB = readstring f
								CheckByte = readbyte f
								if CheckByte != 0x00 do (fseek f -1 #seek_cur)
								print TDEPStringA
							)
							print "----------"
						)
						0x52545354:(
							printDebug ("TSTR: " + NextOffset as string)
							TSTRCount = readlong f
							TSTRSize = readlong f
							TSTRStart = readlong f
							NextOffset = (NextOffset + TSTRSize)
							for i = 1 to TSTRCount do(
								TSTRString = readstring f
								CheckByte = readbyte f
								if CheckByte != 0x00 do (fseek f -1 #seek_cur)
								append String_array TSTRString
							)
							printDebug ("Strings:")
							printDebug (String_array)
							printDebug ("----------")
						)
						0x54454D54:(
							printDebug ("TMET: " + NextOffset as string)
							TMETCount = readlong f
							TMETSize = readlong f
							TMETStart = readlong f
							NextOffset = (NextOffset + TMETSize)
							for i = 1 to TMETCount do(
								TMETString = readstring f
								CheckByte = readbyte f
								if CheckByte != 0x00 do (fseek f -1 #seek_cur)
							)
						)
						0x5A53544D:(
							printDebug ("MTSZ: " + NextOffset as string)
							MTSZCount = readlong f
							MTSZSize = readlong f
							MTSZStart = readlong f
							NextOffset = (NextOffset + MTSZSize)
							for i = 1 to MTSZCount do(
								MTSZID = readlong f
							)
						)
						0x44495845:(
							printDebug ("EXID: " + NextOffset as string)
							EXIDCount = readlong f
							EXIDSize = readlong f
							EXIDStart = readlong f
							NextOffset = (NextOffset + EXIDSize)
							for i = 1 to EXIDCount do(
								EXIDIDA = readlong f
								EXIDIDB = readlong f
							)
						)
						0x4D4E5845:(
							printDebug ("EXNM: " + NextOffset as string)
							EXNMCount = readlong f
							EXNMSize = readlong f
							EXNMStart = readlong f
							NextOffset = (NextOffset + EXNMSize)
							for i = 1 to EXNMCount do(
								EXNMStringA = readshort f #unsigned + 1; EXNMStringA2 = readshort f #unsigned; EXNMStringA = String_array[EXNMStringA]
								EXNMStringB = readshort f #unsigned + 1; EXNMStringB2 = readshort f #unsigned; EXNMStringB = String_array[EXNMStringB]
								append Materials_array (Material_Struct MatName:EXNMStringA MatDep:EXNMStringB)
							)
							print "Materials:"
							print Materials_array
							print "----------"
						)
						0x42545652:(
							printDebug ("RVTB: " + NextOffset as string)
							RVTBCount = readlong f
							RVTBSize = readlong f
							RVTBStart = readlong f
							NextOffset = (NextOffset + RVTBSize)
							for i = 1 to RVTBCount do(
								RVTBID = readbyte f
							)
							RVTBIDA = readbyte f
							RVTBIDB = readbyte f
							RVTBIDC = readbyte f
						)
						0x54545352:(
							printDebug ("RSTT: " + NextOffset as string)
							RSTTCount = readlong f
							RSTTSize = readlong f
							RSTTStart = readlong f
							NextOffset = (NextOffset + RSTTSize)
							for i = 1 to RSTTCount do(
								RSTTID = readbyte f
							)
							RSTTIDA = readbyte f
							RSTTIDB = readbyte f
							RSTTIDC = readbyte f
							RSTTIDD = readbyte f
							RSTTIDE = readlong f
						)
						0x53464F52:(
							printDebug ("ROFS: " + NextOffset as string)
							ROFSCount = readlong f
							ROFSSize = readlong f
							ROFSStart = readlong f
							NextOffset = (NextOffset + ROFSSize)
						)
						0x44495052:(
							printDebug ("RPID: " + NextOffset as string)
							RPIDCount = readlong f
							RPIDSize = readlong f
							RPIDStart = readlong f
							NextOffset = (NextOffset + RPIDSize)
						)
						0x54584552:(
							printDebug ("REXT: " + NextOffset as string)
							REXTCount = readlong f
							REXTSize = readlong f
							REXTStart = readlong f
							NextOffset = (NextOffset + REXTSize)
						)
						0x444E4852:(
							printDebug ("RHND: " + NextOffset as string)
							RHNDCount = readlong f
							RHNDSize = readlong f
							RHNDStart = readlong f
							NextOffset = (NextOffset + RHNDSize)
						)
						0x58454E52:(
							printDebug ("RNEX: " + NextOffset as string)
							RNEXCount = readlong f
							RNEXSize = readlong f
							RNEXStart = readlong f
							NextOffset = (NextOffset + RNEXSize)
						)
						0x544F4F52:(
							printDebug ("ROOT: " + NextOffset as string)
							ROOTCount = readlong f
							ROOTSize = readlong f
							ROOTStart = readlong f
							NextOffset = (NextOffset + ROOTSize)
							for i = 1 to ROOTCount do(
								ROOTID = readlong f
							)
						)
						0x4D414E4F:(
							ModelOffset = ((ftell f) - 0x04)
							printDebug ("ONAM: " + ModelOffset as string)
							ONAMCount = readlong f
							ONAMSize = readlong f
							ONAMStart = readlong f
							ModelOffset = (ModelOffset + ONAMSize)
							for i = 1 to ONAMCount do(
								ONAMID = readlong f
							)
							ModelStart = (ftell f)
							BoneCount = 0
							
							multimat = MultiMaterial()
							multimat.name = g as string
							multimat.numsubs = Materials_array.count
							for m = 1 to Materials_array.count do(
								mat = multimat.materialList[m]
								mat.name = Materials_array[m].MatName
								mat.showinviewport = true
								mat.twosided = false
								tm = Bitmaptexture filename:(p + (Materials_array[m].MatName as string) + ".png")
								tm.alphasource = 0
								mat.diffuseMap = tm
								mat.opacityMap = tm
								mat.opacityMap.monoOutput = 1
							)
							
							printDebug ("Model Start: " + (ModelStart) as string)

							case ModelFormat of(
								1:(
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f

									SubSectCount = readlong f
									VerCheck = readlong f
										if VerCheck == 0x00000002 do(PCVer = "Yes")
									SubSectHeaderSize = readlong f
									Unknown = readlong f

									SubSectOffset = (readlong f + ModelStart); Pad64Bit = readlong f
									fseek f SubSectOffset #seek_set
									ModelInfoOffset = #()
										
									case SubSectCount of(
										default:(print "Currently unsupported, sorry."; exit())
										2:(
											InfoOffset = readlong f + ModelStart; Pad64Bit = readlong f
											ModelInfoOffset = readlong f + ModelStart; Pad64Bit = readlong f
											fseek f ModelInfoOffset #seek_set
										)
									)

									Unknown = readlong f
									Blank = readlong f

									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f

									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f

									BoneInfoOffset = readlong f + ModelStart; Pad64Bit = readlong f
									ModelInfoOffset = readlong f + ModelStart; Pad64Bit = readlong f

									UnknownOffset2 = readlong f + ModelStart; Pad64Bit = readlong f
									Blank = readlong f; if Blank != 0 do(print "Try the 'Models' option instead."; exit())
									Blank = readlong f

									BoundMinX = readfloat f
									BoundMinY = readfloat f
									BoundMinZ = readfloat f
									BoundMaxX = readfloat f

									BoundMaxY = readfloat f
									BoundMaxZ = readfloat f
									Unknown = readlong f
									Blank = readlong f

									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f

									Unknown = readlong f
									Blank = readlong f
									BoneMatrixSize = readlong f
									Unknown = readlong f

									BoneMatrixStart = readlong f + ModelStart
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f

									Unknown = readlong f
									BoneCountPS4 = readlong f
									BoneCount = readlong f
									BoneCountPC = readlong f

									BoneHeaderSize = readlong f
									Unknown = readlong f
									BoneHeaderStart = readlong f + ModelStart
									Blank = readlong f

									fseek f BoneHeaderStart #seek_set

									for b = 1 to BoneCount do(
										BoneOffset = readlong f + ModelStart; Pad64Bit = readlong f
										BoneRet = ftell f

										fseek f BoneOffset #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										BoneNameID = readlong f + 1; BoneName = String_array[BoneNameID]
										Blank = readlong f
										BoneParent = readlong f
										BoneNum = readlong f
										BoneTX = readfloat f
										BoneTY = readfloat f
										BoneTZ = readfloat f
										Blank = readlong f
										append BoneName_array BoneName
										append BoneParent_array BoneParent
										fseek f BoneRet #seek_set
									)

									fseek f BoneMatrixStart #seek_set
									for b = 1 to BoneCount do(
										if b == 1 then( 
											m11 = 1; m12 = 0; m13 = 0; m14 = 0
											m21 = 0; m22 = 1; m23 = 0; m24 = 0
											m31 = 0; m32 = 0; m33 = 1; m34 = 0
											m41 = 0; m42 = 0; m43 = 0; m44 = 1
										) else (
											m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
											m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
											m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
											m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
										)
										tfm = inverse(matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43])
										BoneName = BoneName_array[b]
										BoneParent = BoneParent_array[b]

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
										newBone.parent = BoneArray[(BoneParent + 1)]
										append BoneArray newBone
									)

									fseek f UnknownOffset2 #seek_set

									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f
									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f
									Unknown = readlong f
									Unknown = readlong f
									VertPlus = readlong f
									Unknown = readlong f
									VertStart = readlong f + ModelStart + VertPlus
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f

									fseek f ModelInfoOffset #seek_set

									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f
									Unknown = readlong f
									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Unknown = readlong f
									Unknown = readlong f
									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									ModelCount = readlong f
									printDebug ("PolyGroups: " + ModelCount as string)
									Blank = readlong f
									ModelBufferSize = readlong f
									Unknown = readlong f
									SubModelOffset = readlong f + ModelStart; Pad64Bit = readlong f
									Unknown = readlong f
									Blank = readlong f
									Unknown = readlong f
									Unknown = readlong f
									UnknownModelOffset = readlong f + ModelStart; Pad64Bit = readlong f
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f
									Blank = readlong f
									Blank = readlong f
									NodeIDCount = readlong f
									Blank = readlong f
									NodeIDSize = readlong f
									Unknown = readlong f
									NodeIDOffset = readlong f + ModelStart; Pad64Bit = readlong f

									fseek f NodeIDOffset #seek_set

									for n = 1 to NodeIDCount do(
										NodeID = readlong f + 2
										append NodeID_array NodeID
									)

									fseek f SubModelOffset #seek_set

									Vert_array = #()
									Normal_array = #()
									Color_array = #()
									Alpha_array = #()
									UV_array = #()
									UV2_array = #()
									UV3_array = #()
									UV4_array = #()
									Face_array = #()
									B1_array = #()
									B2_array = #()
									W1_array = #()
									W2_array = #()
									Weight_array = #()
									MatID_array = #()
									VertAdd = 0

									for y = 1 to ModelCount do(
										VertBuffer_array = #()
										ModelInfoOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										ModelRet = ftell f

										fseek f ModelInfoOffset #seek_set
										printDebug ("ModelInfoOffset: " + ftell f as string)
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										ModelNameID = readlong f + 1; ModelName = String_array[ModelNameID]
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										BoundMinX = readlong f
										BoundMinY = readlong f
										BoundMinZ = readlong f
										Blank = readlong f
										BoundMaxX = readlong f
										BoundMaxY = readlong f
										BoundMaxZ = readlong f
										Blank = readlong f
										MatID = readshort f #unsigned + 1
										Unknown = readshort f #unsigned
										Blank = readlong f
										VertInfoOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										PolyInfoOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										Blank = readlong f
										Blank = readlong f
										NodeIDStart = readshort f #unsigned + 1
										NodeIDTotal = readshort f #unsigned
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										
										fseek f VertInfoOffset #seek_set
										printDebug ("VertInfoOffset: " + ftell f as string)

										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset2 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset3 = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1 #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertexCount = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1B = (readlong f + ModelStart); Pad64Bit = readlong f
										VertexBufferSize = readlong f
										Unknown = readlong f
										VertexBufferStart = (readlong f) - 0x08000000 + VertStart
										Blank = readlong f
										InfoOffset1C = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1D = (readlong f + ModelStart); Pad64Bit = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										InfoOffset1E = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1B #seek_set
										VertexCount2 = readlong f
										Blank = readlong f

										fseek f InfoOffset1C #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertexBufferStride = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertBuffParamASize = readlong f
										Unknown = readlong f
										VertBuffParamAOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										VertBuffParamBSize = readlong f
										Unknown = readlong f
										VertBuffParamBOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1F = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset1G = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1H = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f

										fseek f VertBuffParamAOffset #seek_set
										for v = 1 to (VertBuffParamASize / 0x0C) do(
											VertFormat1 = readbyte f #unsigned
											VertFormat2 = readbyte f #unsigned
											VertFormat3 = readbyte f #unsigned
											VertFormat4 = readbyte f #unsigned
											VertType = readbyte f #unsigned + 1
											VertLayer = readbyte f #unsigned + 1
											VertUnk1 = readbyte f #unsigned
											VertUnk2 = readbyte f #unsigned
											VertShift = readlong f #unsigned
											printDebug (VertFormat1 as string + " / " + VertFormat2 as string + " / " + VertFormat3 as string + " / " + VertFormat4 as string + ", type: " + VertType as string + ", layer: " + VertLayer as string + ", unk: " + VertUnk1 as string + " / " + VertUnk2 as string + ", shift: " + VertShift as string)
											append VertBuffer_array (VertBuffer_Struct VertFormat1:VertFormat1 VertFormat2:VertFormat2 VertFormat3:VertFormat3 VertFormat4:VertFormat4 VertType:VertType VertLayer:VertLayer VertUnk1:VertUnk1 VertUnk2:VertUnk2 VertShift:VertShift)
										)

										fseek f VertBuffParamBOffset #seek_set
										for v = 1 to (VertBuffParamBSize / 0x04) do(
											VertUnknown = readlong f
										)

										fseek f PolyInfoOffset #seek_set
										printDebug ("PolyInfoOffset: " + ftell f as string)
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset2 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset3 = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1 #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										FacepointCount = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1B = (readlong f + ModelStart); Pad64Bit = readlong f
										PolyBufferSize = readlong f
										Unknown = readlong f
										PolyBufferStart = (readlong f) - 0x08000000 + VertStart
										Blank = readlong f
										InfoOffset1C = readlong f; Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1D = (readlong f + ModelStart); Pad64Bit = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										InfoOffset1E = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1B #seek_set
										FacepointCount2 = readlong f
										Blank = readlong f

										fseek f InfoOffset1D #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertexBufferStride = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										PolyBuffParamASize = readlong f
										Unknown = readlong f
										PolyBuffParamAOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										PolyBuffParamBSize = readlong f
										Unknown = readlong f
										PolyBuffParamBOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1F = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset1G = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1H = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f

										fseek f VertexBufferStart #seek_set
										printDebug ("Vertex start: " + ftell f as string + ", size: 0x" + (bit.intAsHex(VertexBufferStride) as string))

										for v = 1 to VertexCount do(
											for w = 1 to VertBuffer_array.count do(
												VertType = VertBuffer_array[w].VertType
												VertFmt = VertBuffer_array[w].VertFormat1
												VertLayer = VertBuffer_array[w].VertLayer
												case VertType of(
													default:(throw("Unknown vertex type!"))
													1:(
														case VertFmt of(
															default:(throw("Unknown position format!"))
															2:(
																vx = readfloat f
																vy = readfloat f
																vz = readfloat f
																append Vert_array [vx,vy,vz]
															)
															44:()
														)
													)
													2:(
														case VertFmt of(
															default:(throw("Unknown normals/binormals format!"))
															2:(
																nx = readfloat f
																ny = readfloat f
																nz = readfloat f
																if VertLayer == 1 do(append Normal_array [nx,ny,nz])
															)
														)
													)
													3:(
														case VertFmt of(
															default:(throw("Unknown tangents(?) format!"))
															2:(
																tanx = readfloat f
																tany = readfloat f
																tanz = readfloat f
															)
														)
													)
													5:(
														case VertFmt of(
															default:(throw("Unknown colors format!"))
															4:(
																colorr = readbyte f #unsigned
																colorg = readbyte f #unsigned
																colorb = readbyte f #unsigned
																colora = (readbyte f #unsigned as float) / 255
																if VertLayer == 1 do(
																	append Color_Array[colorr,colorg,colorb]
																	append Alpha_Array colora
																)
															)
														)
													)
													6:(
														case VertFmt of(
															default:(throw("Unknown UVs format!"))
															2:(
																tu = readfloat f
																tv = (readfloat f * -1) + 1
																tw = readfloat f
																if VertLayer == 1 do(append UV_array [tu,tv,0])
																if VertLayer == 2 do(append UV2_array [tu,tv,0])
																if VertLayer == 3 do(append UV3_array [tu,tv,0])
																if VertLayer == 4 do(append UV4_array [tu,tv,0])
															)
															42:(
																tu = readhalffloat f
																tv = (readhalffloat f * -1) + 1
																if VertLayer == 1 do(append UV_array [tu,tv,0])
																if VertLayer == 2 do(append UV2_array [tu,tv,0])
																if VertLayer == 3 do(append UV3_array [tu,tv,0])
																if VertLayer == 4 do(append UV4_array [tu,tv,0])
															)
														)
													)
													7:(
														case VertFmt of(
															default:(throw("Unknown weights format!"))
															26:(
																Weight1 = (readbyte f #unsigned as float) / 255
																Weight2 = (readbyte f #unsigned as float) / 255
																Weight3 = (readbyte f #unsigned as float) / 255
																Weight4 = (readbyte f #unsigned as float) / 255
																if VertLayer == 1 do(append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4))
																if VertLayer == 2 do(append W2_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4))
															)
														)
													)
													9:(
														case VertFmt of(
															default:(throw("Unknown bones format!"))
															13:(
																Bone1 = NodeID_array[(readlong f) + NodeIDStart]
																Bone2 = NodeID_array[(readlong f) + NodeIDStart]
																Bone3 = NodeID_array[(readlong f) + NodeIDStart]
																Bone4 = NodeID_array[(readlong f) + NodeIDStart]
																if Bone1 == undefined do(Bone1 = 1)
																if Bone2 == undefined do(Bone2 = 1)
																if Bone3 == undefined do(Bone3 = 1)
																if Bone4 == undefined do(Bone4 = 1)
																if VertLayer == 1 do(append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
																if VertLayer == 2 do(append B2_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
															)
															23:(
																Bone1 = NodeID_array[(readbyte f) + NodeIDStart]
																Bone2 = NodeID_array[(readbyte f) + NodeIDStart]
																Bone3 = NodeID_array[(readbyte f) + NodeIDStart]
																Bone4 = NodeID_array[(readbyte f) + NodeIDStart]
																if Bone1 == undefined do(Bone1 = 1)
																if Bone2 == undefined do(Bone2 = 1)
																if Bone3 == undefined do(Bone3 = 1)
																if Bone4 == undefined do(Bone4 = 1)
																if VertLayer == 1 do(append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
																if VertLayer == 2 do(append B2_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
															)
														)
													)
												)
											)
										)
										printDebug ("Vertex end: " + ftell f as string)
										fseek f PolyBufferStart #seek_set
										printDebug ("Facepoint start: " + ftell f as string)
										
										if VertexCount > 65535 then(
											for v = 1 to (FacepointCount / 3) do(
												fa = readlong f #unsigned + 1 + VertAdd
												fb = readlong f #unsigned + 1 + VertAdd
												fc = readlong f #unsigned + 1 + VertAdd
												append Face_array [fa,fb,fc]
												append MatID_array MatID
											)
										) else (
												for v = 1 to (FacepointCount / 3) do(
													fa = readshort f #unsigned + 1 + VertAdd
													fb = readshort f #unsigned + 1 + VertAdd
													fc = readshort f #unsigned + 1 + VertAdd
													append Face_array [fa,fb,fc]
													append MatID_array MatID
												)
										)
										printDebug ("Facepoint end: " + ftell f as string)

										fseek f ModelRet #seek_set
										VertAdd = VertAdd + VertexCount

									)

									if Color_Array.count == 0 do(
										For v = 1 to Vert_array.count do(
											append Color_Array[255,255,255]
											append Alpha_Array 1
										)
									)

									if BoneCount > 0 do(
										if B2_Array.count == 0 do(
											For v = 1 to B1_array.count do(
												append B2_Array (Bone_Info_Struct bone1:1 bone2:1 bone3:1 bone4:1)
												append W2_Array (Weight_Info_Struct weight1:0 weight2:0 weight3:0 weight4:0)
											)
										)
										for b = 1 to W1_Array.count do(
											w = (weight_data boneids:#() weights:#())
											maxweight = 0
											
											if W1_array[b].Weight1 != 0 do maxweight += W1_array[b].Weight1
											if W1_array[b].Weight2 != 0 do maxweight += W1_array[b].Weight2
											if W1_array[b].Weight3 != 0 do maxweight += W1_array[b].Weight3
											if W1_array[b].Weight4 != 0 do maxweight += W1_array[b].Weight4
											if W2_array[b].Weight1 != 0 do maxweight += W2_array[b].Weight1
											if W2_array[b].Weight2 != 0 do maxweight += W2_array[b].Weight2
											if W2_array[b].Weight3 != 0 do maxweight += W2_array[b].Weight3
											if W2_array[b].Weight4 != 0 do maxweight += W2_array[b].Weight4

											if maxweight != 0 then(
												if W1_array[b].Weight1 != 0 then(
													w1 = W1_array[b].Weight1 as float
													append w.boneids (B1_array[b].Bone1)
													append w.weights (w1)
												)
												if W1_array[b].Weight2 != 0 then(
													w2 = W1_array[b].Weight2 as float
													append w.boneids (B1_array[b].Bone2)
													append w.weights (w2)
												)
												if W1_array[b].Weight3 != 0 then(
													w3 = W1_array[b].Weight3 as float
													append w.boneids (B1_array[b].Bone3)
													append w.weights (w3)
												)
												if W1_array[b].Weight4 != 0 then(
													w4 = W1_array[b].Weight4 as float
													append w.boneids (B1_array[b].Bone4)
													append w.weights (w4)
												)
												if W2_array[b].Weight1 != 0 then(
													w5 = W2_array[b].Weight1 as float
													append w.boneids (B2_array[b].Bone1)
													append w.weights (w5)
												)
												if W2_array[b].Weight2 != 0 then(
													w6 = W2_array[b].Weight2 as float
													append w.boneids (B2_array[b].Bone2)
													append w.weights (w6)
												)
												if W2_array[b].Weight3 != 0 then(
													w7 = W2_array[b].Weight3 as float
													append w.boneids (B2_array[b].Bone3)
													append w.weights (w7)
												)
												if W2_array[b].Weight4 != 0 then(
													w8 = W2_array[b].Weight4 as float
													append w.boneids (B2_array[b].Bone4)
													append w.weights (w8)
												)
											)
											append Weight_array w
										)
									)
									print MatID_array.count
									msh = mesh vertices:Vert_array faces:Face_array
									msh.numTVerts = Vert_array.count
									buildTVFaces msh
									msh.name = g as string
									msh.material = multimat
									for j = 1 to UV_array.count do setTVert msh j UV_array[j]
									for j = 1 to Face_array.count do(
										setTVFace msh j Face_array[j]
										setFaceMatID msh j MatID_array[j]
									)
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

									if BoneCount > 0 do (
										skinMod = skin ()
										boneIDMap = #()
										addModifier msh skinMod
										msh.Skin.weightAllVertices = false

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
											bi = #() --bone index array
											wv = #() --weight value array
											
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
								2:(
									Blank = readlong f
									Blank = readlong f
									Blank = readlong f
									Unknown = readlong f

									SubSectCount = readlong f
									VerCheck = readlong f
										if VerCheck == 0x00000002 do(PCVer = "Yes")
									Unknown = readlong f
									Unknown = readlong f

									SubSectOffset = (readlong f + ModelStart); Pad64Bit = readlong f
									fseek f SubSectOffset #seek_set
									ModelInfoOffset = #()
							
									case SubSectCount of(
										default:(print "Currently unsupported, sorry."; exit())
										2:(
											InfoOffset = readlong f + ModelStart; Pad64Bit = readlong f
											ModelInfoOffset = readlong f + ModelStart; Pad64Bit = readlong f
											fseek f ModelInfoOffset #seek_set
										)
									)
										
									fseek f (ModelStart + 0xE0) #seek_set
									ModelCount = readlong f
									Blank = readlong f
									ModelOffsetBuffSize = readlong f
									Unknown = readlong f
									ModelOffset = (readlong f + ModelStart); Pad64Bit = readlong f
									ModelCount2 = readlong f
									Blank = readlong f
									Unknown = readlong f
									Unknown = readlong f
									ModelOffset2 = readlong f; Pad64Bit = readlong f
									
									fseek f (ModelInfoOffset + 0x50) #seek_set
									ModelJump = readlong f
									Unknown = readlong f
									ModelJumpOffset = readlong f + ModelStart
									fseek f (ModelJumpOffset + ModelJump + 0x18) #seek_set
									VertPlus = readlong f
									Unknown = readlong f
									VertStart = readlong f + ModelStart + VertPlus
									
									fseek f (ModelStart + 0x140) #seek_set

									Vert_array = #()
									Normal_array = #()
									Color_array = #()
									Alpha_array = #()
									UV_array = #()
									UV2_array = #()
									UV3_array = #()
									UV4_array = #()
									Face_array = #()
									B1_array = #()
									B2_array = #()
									W1_array = #()
									W2_array = #()
									Weight_array = #()
									MatID_array = #()
									VertAdd = 0

									for x = 1 to ModelCount do(
										ModelGrpOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										ModelRet = (ftell f)
										fseek f ModelGrpOffset #seek_set

										VertBuffer_array = #()
										printDebug ("Model Offset 1: " + ftell f as string)
										
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										BoundMinX = readlong f
										BoundMinY = readlong f
										BoundMinZ = readlong f
										Blank = readlong f
										BoundMaxX = readlong f
										BoundMaxY = readlong f
										BoundMaxZ = readlong f
										Blank = readlong f
										MatID = readshort f #unsigned + 1
										Unknown = readshort f #unsigned
										Blank = readlong f
										VertInfoOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										PolyInfoOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f

										fseek f VertInfoOffset #seek_set
										printDebug ("VertInfoOffset: " + ftell f as string)
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset2 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset3 = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1 #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertexCount = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1B = (readlong f + ModelStart); Pad64Bit = readlong f
										VertexBufferSize = readlong f
										Unknown = readlong f
										VertexBufferStart = (readlong f) - 0x08000000 + VertStart
										Blank = readlong f
										InfoOffset1C = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1D = (readlong f + ModelStart); Pad64Bit = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										InfoOffset1E = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1B #seek_set
										VertexCount2 = readlong f
										Blank = readlong f

										fseek f InfoOffset1C #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertexBufferStride = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertBuffParamASize = readlong f
										Unknown = readlong f
										VertBuffParamAOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										VertBuffParamBSize = readlong f
										Unknown = readlong f
										VertBuffParamBOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1F = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset1G = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1H = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f

										fseek f VertBuffParamAOffset #seek_set
										for v = 1 to (VertBuffParamASize / 0x0C) do(
											VertFormat1 = readbyte f #unsigned
											VertFormat2 = readbyte f #unsigned
											VertFormat3 = readbyte f #unsigned
											VertFormat4 = readbyte f #unsigned
											VertType = readbyte f #unsigned + 1
											VertLayer = readbyte f #unsigned + 1
											VertUnk1 = readbyte f #unsigned
											VertUnk2 = readbyte f #unsigned
											VertShift = readlong f #unsigned
											printDebug (VertFormat1 as string + " / " + VertFormat2 as string + " / " + VertFormat3 as string + " / " + VertFormat4 as string + ", type: " + VertType as string + ", layer: " + VertLayer as string + ", unk: " + VertUnk1 as string + " / " + VertUnk2 as string + ", shift: " + VertShift as string)
											append VertBuffer_array (VertBuffer_Struct VertFormat1:VertFormat1 VertFormat2:VertFormat2 VertFormat3:VertFormat3 VertFormat4:VertFormat4 VertType:VertType VertLayer:VertLayer VertUnk1:VertUnk1 VertUnk2:VertUnk2 VertShift:VertShift)
										)

										fseek f VertBuffParamBOffset #seek_set
										for v = 1 to (VertBuffParamBSize / 0x04) do(
											VertUnknown = readlong f
										)

										fseek f PolyInfoOffset #seek_set
										printDebug ("PolyInfoOffset: " + ftell f as string)
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset2 = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset3 = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1 #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										FacepointCount = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1B = (readlong f + ModelStart); Pad64Bit = readlong f
										PolyBufferSize = readlong f
										Unknown = readlong f
										PolyBufferStart = (readlong f) - 0x08000000 + VertStart
										Blank = readlong f
										InfoOffset1C = readlong f; Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1D = (readlong f + ModelStart); Pad64Bit = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										InfoOffset1E = (readlong f + ModelStart); Pad64Bit = readlong f

										fseek f InfoOffset1B #seek_set
										FacepointCount2 = readlong f
										Blank = readlong f

										fseek f InfoOffset1D #seek_set
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										VertexBufferStride = readlong f
											if PCVer == "Yes" do(Blank = readlong f)
										PolyBuffParamASize = readlong f
										Unknown = readlong f
										PolyBuffParamAOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										PolyBuffParamBSize = readlong f
										Unknown = readlong f
										PolyBuffParamBOffset = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f
										InfoOffset1F = (readlong f + ModelStart); Pad64Bit = readlong f
										InfoOffset1G = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Blank = readlong f
										Unknown = readlong f
										Unknown = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Blank = readlong f
										Unknown = readlong f
										Blank = readlong f
										InfoOffset1H = (readlong f + ModelStart); Pad64Bit = readlong f
										Unknown = readlong f
										Unknown = readlong f

										fseek f VertexBufferStart #seek_set
										printDebug ("Vertex Buffer: " + ftell f as string + ", size: 0x" + (bit.intAsHex(VertexBufferStride) as string))

										for v = 1 to VertexCount do(
											for w = 1 to VertBuffer_array.count do(
												VertType = VertBuffer_array[w].VertType
												VertFmt = VertBuffer_array[w].VertFormat1
												VertLayer = VertBuffer_array[w].VertLayer
												case VertType of(
													default:(throw("Unknown vertex type!"))
													1:(
														case VertFmt of(
															default:(throw("Unknown position format!"))
															2:(
																vx = readfloat f
																vy = readfloat f
																vz = readfloat f
																append Vert_array [vx,vy,vz]
															)
															44:()
														)
													)
													2:(
														case VertFmt of(
															default:(throw("Unknown normals/binormals format!"))
															2:(
																nx = readfloat f
																ny = readfloat f
																nz = readfloat f
																if VertLayer == 1 do(append Normal_array [nx,ny,nz])
															)
														)
													)
													3:(
														case VertFmt of(
															default:(throw("Unknown tangents(?) format!"))
															2:(
																tanx = readfloat f
																tany = readfloat f
																tanz = readfloat f
															)
														)
													)
													5:(
														case VertFmt of(
															default:(throw("Unknown colors format!"))
															4:(
																colorr = readbyte f #unsigned
																colorg = readbyte f #unsigned
																colorb = readbyte f #unsigned
																colora = (readbyte f #unsigned as float) / 255
																if VertLayer == 1 do(
																	append Color_Array[colorr,colorg,colorb]
																	append Alpha_Array colora
																)
															)
														)
													)
													6:(
														case VertFmt of(
															default:(throw("Unknown UVs format!"))
															2:(
																tu = readfloat f
																tv = (readfloat f * -1) + 1
																tw = readfloat f
																if VertLayer == 1 do(append UV_array [tu,tv,0])
																if VertLayer == 2 do(append UV2_array [tu,tv,0])
																if VertLayer == 3 do(append UV3_array [tu,tv,0])
																if VertLayer == 4 do(append UV4_array [tu,tv,0])
															)
															42:(
																tu = readhalffloat f
																tv = (readhalffloat f * -1) + 1
																if VertLayer == 1 do(append UV_array [tu,tv,0])
																if VertLayer == 2 do(append UV2_array [tu,tv,0])
																if VertLayer == 3 do(append UV3_array [tu,tv,0])
																if VertLayer == 4 do(append UV4_array [tu,tv,0])
															)
														)
													)
													7:(
														case VertFmt of(
															default:(throw("Unknown weights format!"))
															26:(
																Weight1 = (readbyte f #unsigned as float) / 255
																Weight2 = (readbyte f #unsigned as float) / 255
																Weight3 = (readbyte f #unsigned as float) / 255
																Weight4 = (readbyte f #unsigned as float) / 255
																if VertLayer == 1 do(append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4))
																if VertLayer == 2 do(append W2_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4))
															)
														)
													)
													9:(
														case VertFmt of(
															default:(throw("Unknown bones format!"))
															13:(
																Bone1 = NodeID_array[(readlong f) + NodeIDStart]
																Bone2 = NodeID_array[(readlong f) + NodeIDStart]
																Bone3 = NodeID_array[(readlong f) + NodeIDStart]
																Bone4 = NodeID_array[(readlong f) + NodeIDStart]
																if Bone1 == undefined do(Bone1 = 1)
																if Bone2 == undefined do(Bone2 = 1)
																if Bone3 == undefined do(Bone3 = 1)
																if Bone4 == undefined do(Bone4 = 1)
																if VertLayer == 1 do(append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
																if VertLayer == 2 do(append B2_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
															)
															23:(
																Bone1 = NodeID_array[(readbyte f) + NodeIDStart]
																Bone2 = NodeID_array[(readbyte f) + NodeIDStart]
																Bone3 = NodeID_array[(readbyte f) + NodeIDStart]
																Bone4 = NodeID_array[(readbyte f) + NodeIDStart]
																if Bone1 == undefined do(Bone1 = 1)
																if Bone2 == undefined do(Bone2 = 1)
																if Bone3 == undefined do(Bone3 = 1)
																if Bone4 == undefined do(Bone4 = 1)
																if VertLayer == 1 do(append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
																if VertLayer == 2 do(append B2_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4))
															)
														)
													)
												)
											)
										)
										printDebug ("Vertex end: " + ftell f as string)
										fseek f PolyBufferStart #seek_set
										printDebug ("Poly Buffer: " + ftell f as string)
										
										if VertexCount > 65535 then(
											for v = 1 to (FacepointCount / 3) do(
												fa = readlong f #unsigned + 1 + VertAdd
												fb = readlong f #unsigned + 1 + VertAdd
												fc = readlong f #unsigned + 1 + VertAdd
												append Face_array [fa,fb,fc]
												append MatID_array MatID
											)
										) else (
												for v = 1 to (FacepointCount / 3) do(
													fa = readshort f #unsigned + 1 + VertAdd
													fb = readshort f #unsigned + 1 + VertAdd
													fc = readshort f #unsigned + 1 + VertAdd
													append Face_array [fa,fb,fc]
													append MatID_array MatID
												)
										)
										printDebug ("Poly end: " + ftell f as string)

										fseek f ModelRet #seek_set
										VertAdd = VertAdd + VertexCount

									)

									If Color_Array.count == 0 do(
										For v = 1 to Vert_array.count do(
											append Color_Array[255,255,255]
											append Alpha_Array 1
										)
									)

									msh = mesh vertices:Vert_array faces:Face_array
									msh.numTVerts = Vert_array.count
									buildTVFaces msh
									msh.name = g as string
									msh.material = multimat
									for j = 1 to UV_array.count do setTVert msh j UV_array[j]
									for j = 1 to Face_array.count do(
										setTVFace msh j Face_array[j]
										setFaceMatID msh j MatID_array[j]
									)
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

								)
							)
						)
					)
					fseek f NextOffset #seek_set
				)
				Print ("Done! ("+((((timestamp())-st)*0.001)as string)+" Seconds)")
			)
		)
	)

)

CreateDialog ModelImporter