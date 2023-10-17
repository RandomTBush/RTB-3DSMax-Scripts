-- Super Smash Bros. Ultimate / New Pokémon Snap model importer by Random Talking Bush, with help from Ploaj.

-- Changelog:
-- May 26th, 2021
-- Added support for models from New Pokémon Snap.
-- Added a vertex color multiplier option.
-- Models now reset their pivot points and XForms to 0 for ease with modding.
-- Fixed an oversight causing rigging (mainly for custom models, but also Bomberman's remote bomb) and materials to import incorrectly.
-- Fixed certain models with 0 bones (the Mii's Rex hair and Geno hat) not importing.
-- Fixed models refusing to import in 3DS Max 2021 (the "twoSided" error was due to it trying to apply "Standard" material settings to a "Physical" material, which apparently is the new default).

-- December 26th, 2018
-- Fixed models with 0 rigging influences not being bound to anything.
-- Fixed models with invalid bones causing the script to error.

rollout ModelImporter "Smash Ultimate / New PKMN Snap Importer" width:330 height:225
(
	button btnImport "Import *.NUMDLB / *.NUSRCMDLB" pos:[7,8] width:316 height:50
	groupBox OptionsBox "Options" pos:[7,58] width:316 height:60
	checkbox tglVertColors "Enable vertex colors?" pos:[17,75] checked: true
	checkbox tglVertColorsMult "Multiply vertex colors?" pos:[17,95] tooltip: "If this is enabled, the model will multiply the color values by 2 (so instead of 127 being the default, it'll be 255 -- any color values above 127 will be lost, though)." checked: false
	checkbox tglDebug "Print debug information?" pos:[170,75] checked: false
	checkbox tglSnapScaleFix "Pokémon Snap size fix" pos:[170,95] tooltip: "New Pokémon Snap's models are teeny-tiny by default. This option will scale the models up to 100x their original size, making them match the scaling seen in the Switch Pokémon games." checked: false
	label lblCred "This script was written by Random Talking Bush (with Ploaj's help) for use with Super Smash Bros. Ultimate and New Pokémon Snap. If used, please consider giving thanks to us, Nintendo, or one of the many third-parties in the game. If something doesn't work right, please contact me on The VG Resource (Random Talking Bush), XeNTaX, Twitter or Steam (RandomTBush) so I can fix it." pos:[8,125] width:317 height:80
	label lblUpdate "(Updated 05/26/2021)" pos:[ModelImporter.width-115,ModelImporter.height-19] width:110

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
			((Ef==31)AND(M!=0)): 0 --hack-- should be #inf
		)
	)
	fn ReadFixedString bstream fixedLen = (
		local str = ""
		for i = 1 to fixedLen do
		(
			str += bit.intAsChar (ReadByte bstream #unsigned)
		)
		str
	)
	fn printDebug pr = (if tglDebug.state do print(pr))

	on btnImport pressed do(
		mdlname = getOpenFileName \ 
		caption:"Super Smash Bros. Ultimate / New Pokémon Snap Model" \
		types:"NUMDLB / NUSRCMDLB Models (*.numdlb, *.nusrcmdlb)|*.numdlb;*.nusrcmdlb" \
		historyCategory:"SmUshPresets"
		if MDLName != undefined do(
			clearlistener()
			BoneCount = 0
			MATB_array = #()
			MODLGrp_array = #()
			Materials_array = #()
			BoneArray = #()
			BoneFixArray = #()
			BoneTrsArray = #()
			BoneParent_array = #()
			BoneName_array = #()
			PolyGrp_array = #()
			WeightGrp_array = #()
			local VertColors = tglVertColors.state
			local VertColorsMult = tglVertColorsMult.checked
			local SnapScaleFix = tglSnapScaleFix.checked
			md = fopen MDLName "rb"
			fpath = getFilenamePath MDLName
			struct MODLStruct (MSHGrpName, MSHSubgroupNum, MSHMatName)
			
			fseek md 0x10 #seek_set
			MODLCheck = readlong md
			if MODLCheck == 0x4D4F444C do(
				MODLVerA = readshort md #unsigned
				MODLVerB = readshort md #unsigned
				MODLNameOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
				SKTNameOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
				MATNameOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
				MATBCount = readlong md; fseek md 0x04 #seek_cur
				ANMNameOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
				MSHNameOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
				MSHDatOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
				MSHDatCount = readlong md
				fseek md SKTNameOff #seek_set
				SKTName = (fpath + readstring md)
				fseek md MATNameOff #seek_set
				for x = 1 to MATBCount do(
					MATStringOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
					MATRet = (ftell md)
					fseek md MATStringOff #seek_set
					MATBFilename = (fpath + readstring md)
					append MATB_array MATBFilename
					fseek md MATRet #seek_set
				)
				fseek md MSHNameOff #seek_set
				MSHName = (fpath + readstring md); fseek md 0x04 #seek_cur
				fseek md MSHDatOff #seek_set
				for g = 1 to MSHDatCount do(
					MSHGrpNameOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
					MSHSubgroupNum = readlong md; fseek md 0x04 #seek_cur
					MSHMatNameOff = (ftell md) + readlong md; fseek md 0x04 #seek_cur
					MSHRet = (ftell md)
					fseek md MSHGrpNameOff #seek_set
					MSHGrpName = readstring md
					fseek md MSHMatNameOff #seek_set
					MSHMatName = readstring md
					append MODLGrp_array (MODLStruct MSHGrpName:MSHGrpName MSHSubgroupNum:MSHSubgroupNum MSHMatName:MSHMatName)
					fseek md MSHRet #seek_set
				)
				printDebug(MODLGrp_array)
				fclose md
			)

			if MATB_array != undefined do(
				struct MatStruct (MatName, MatColName, MatCol2Name, MatBakeName, MatNorName, MatNor2Name, MatEmiName, MatEmi2Name, MatPrmName, MatPrm2Name, MatEnvName, MatEnv2Name)
				for q = 1 to MATB_array.count do(
					mt = fopen MATB_array[q] "rb"
					fseek mt 0x10 #seek_set
					MATCheck = readlong mt
					if MATCheck == 0x4D41544C do(
						MATVerA = readshort mt #unsigned
						MATVerB = readshort mt #unsigned
						MATHeadOff = (ftell mt) + readlong mt; fseek mt 0x04 #seek_cur
						MATCount = readlong mt; fseek mt 0x04 #seek_cur
						fseek mt MATHeadOff #seek_set
						for m = 1 to MATCount do(
							MatColName = ""
							MatCol2Name = ""
							MatBakeName = ""
							MatNorName = ""
							MatNor2Name = ""
							MatEmiName = ""
							MatEmi2Name = ""
							MatPrmName = ""
							MatPrm2Name = ""
							MatEnvName = ""
							MatEnv2Name = ""
							MATNameOff = (ftell mt) + readlong mt; fseek mt 0x04 #seek_cur
							MATParamGrpOff = (ftell mt) + readlong mt; fseek mt 0x04 #seek_cur
							MATParamGrpCount = readlong mt; fseek mt 0x04 #seek_cur
							MATShdrNameOff = (ftell mt) + readlong mt; fseek mt 0x04 #seek_cur
							MATRet = (ftell mt)
							fseek mt MATNameOff #seek_set
							MatName = readstring mt
							print ("Textures for " + MatName as string + ":")
							fseek mt MATParamGrpOff #seek_set
							for p = 1 to MATParamGrpCount do(
								MatParamID = readlong mt; fseek mt 0x04 #seek_cur
								MatParamOff = (ftell mt) + readlong mt; fseek mt 0x04 #seek_cur
								MatParamType = readlong mt; fseek mt 0x04 #seek_cur
								MatParamRet = (ftell mt)
								if MatParamType == 0x0B do(
									fseek mt (MatParamOff + 0x08) #seek_set
									TexName = readstring mt
									print ("(0x" + bit.intAsHex(MatParamID) as string + "): " + TexName as string)
									case MatParamID of(
										default:(printDebug("Unknown type (" + bit.intAsHex(MatParamID) as string + ") for " + TexName as string))
										0x5C:(MatColName = TexName)
										0x5D:(MatCol2Name = TexName)
										0x5F:(MatBakeName = TexName)
										0x60:(MatNorName = TexName)
										0x61:(MatEmiName = TexName; if MatColName == "" do(MatColName = TexName))
										0x62:(MatPrmName = TexName)
										0x63:(MatEnvName = TexName)
										0x65:(MatBakeName = TexName)
										0x66:(MatColName = TexName)
										0x67:(MatCol2Name = TexName)
										0x6A:(MatEmi2Name = TexName; if MatCol2Name == "" do(MatCol2Name = TexName))
										0x133:() -- "noise_for_warp"
									)
									fseek mt MatParamRet #seek_set
								)
							)
							if MATParamGrpCount == 0 do(
								miname = (fpath + MatName) + ".matinstb"
								mi = fopen miname "rb"
								if mi != undefined do(
									HeaderStart = readlong mi
									HeaderParam1Off = readshort mi #unsigned
									HeaderParam2Off = readshort mi #unsigned
									HeaderParam3Off = readshort mi #unsigned
									HeaderParam4Off = readshort mi #unsigned
									HeaderParam5Off = readshort mi #unsigned
									HeaderParam6Off = readshort mi #unsigned

									HeaderParam7Off = readshort mi #unsigned
									HeaderParam8Off = readshort mi #unsigned
									HeaderParam9Off = readshort mi #unsigned
									HeaderParam10Off = readshort mi #unsigned
									HeaderParam11Off = readshort mi #unsigned
									HeaderParam12Off = readshort mi #unsigned
									HeaderParam13Off = readshort mi #unsigned
									HeaderParam14Off = readshort mi #unsigned

									HeaderParam15Off = readshort mi #unsigned
									HeaderParam16Off = readshort mi #unsigned
									HeaderParam17Off = readshort mi #unsigned
									HeaderParam18Off = readshort mi #unsigned
									HeaderParam19Off = readshort mi #unsigned
									HeaderParam20Off = readshort mi #unsigned
									HeaderParam21Off = readshort mi #unsigned
									HeaderParam22Off = readshort mi #unsigned

									fseek mi (HeaderParam7Off + HeaderStart) #seek_set
									TexParamStart = (ftell mi) + readlong mi #unsigned
									fseek mi TexParamStart #seek_set
									TexCount = readlong mi
									for t = 1 to TexCount do(
										TexSubOffset = (ftell mi) + readlong mi
										TexRet = (ftell mi)
										fseek mi TexSubOffset #seek_set

										TexSubHeaderOffset = (ftell mi) - readlong mi
										fseek mi TexSubHeaderOffset #seek_set
										TexSubHeader1Len = readshort mi #unsigned
										TexSubHeader1A = readshort mi #unsigned
										TexSubHeader1B = readshort mi #unsigned
										TexSubHeader1C = readshort mi #unsigned
										TexSubHeader1D = readshort mi #unsigned
										TexSubHeader1E = readshort mi #unsigned
										TexSubHeader1F = readshort mi #unsigned
										TexSubHeader1G = readshort mi #unsigned
										TexSubHeader1H = readshort mi #unsigned
										TexSubHeader1I = readshort mi #unsigned
										TexSubHeader1J = readshort mi #unsigned
										TexSubHeader1K = readshort mi #unsigned

										fseek mi (TexSubOffset + TexSubHeader1B) #seek_set
										TexTypeOff = (ftell mi) + readlong mi
										TexNameOff = (ftell mi) + readlong mi
										TexFloatA = readfloat mi
										TexUnkA = readlong mi
										TexSubHeaderOffA = (ftell mi) + readlong mi
										TexTypeBOff = (ftell mi) + readlong mi

										fseek mi TexTypeOff #seek_set
										TexTypeStrLen = readlong mi
										TexTypeStr = ReadFixedString mi TexTypeStrLen
										fseek mi TexNameOff #seek_set
										TexNameStrLen = (readlong mi - 7)
										TexNameStr = ReadFixedString mi TexNameStrLen
										fseek mi TexTypeBOff #seek_set
										TexTypeBStrLen = readlong mi
										TexTypeBStr = ReadFixedString mi TexTypeBStrLen
										print ("(" + TexTypeStr as string + "): " + TexNameStr as string)
										case TexTypeStr of(
											defaut:()
											"sampler_diffuse":(MatColName = TexNameStr)
											"baseColorTexture":(MatColName = TexNameStr)
											"waterDepthColor":(MatColName = TexNameStr)
											"waterfallBlend1Texture":(MatColName = TexNameStr)
											"normalTexture":(MatNorName = TexNameStr)
											"sampler_waveNormalTexture":(MatNorName = TexNameStr)
											"sampler_waveNormalTexture2":(MatNor2Name = TexNameStr)
											"waveNormalTexture1":(MatNorName = TexNameStr)
											"emissiveTexture":(MatEmiName = TexNameStr)
											"emissiveTexture2":(MatEmi2Name = TexNameStr)
											"emissive2Texture":(MatEmi2Name = TexNameStr)
											"paramsTexture":(MatPrmName = TexNameStr)
											"blendBaseColorTexture":(MatCol2Name = TexNameStr)
											"waterfallBlend2Texture":(MatColName = TexNameStr)
											"blendNormalTexture":(MatNor2Name = TexNameStr)
											"blendEmissiveTexture":(MatEmi2Name = TexNameStr)
											"blendParamsTexture":(MatPrm2Name = TexNameStr)
											"sampler_cubemapReflect":(MatEnvName = TexNameStr)
											"sampler_cubemapRefract":(MatEnv2Name = TexNameStr)
										)	-- Additional types: sampler_flocky, flockyInnerColorTexture, specularTexture, tangentTexture, moonTexture, skyTexture, starTexture, sunTexture, flowingLightBaseTexture, flowingLightColorTexture, flowingLightPhaseTexture, sampler_flowingLightColor, sampler_flowingLightColorAlpha
										fseek mi TexRet #seek_set
									)
									fclose mi
								)
							)
							print "-----"
							append Materials_array (MatStruct MatName:MatName MatColName:MatColName MatCol2Name:MatCol2Name MatBakeName:MatBakeName MatNorName:MatNorName MatNor2Name:MatNor2Name MatEmiName:MatEmiName MatEmi2Name:MatEmi2Name MatPrmName:MatPrmName MatPrm2Name:MatPrm2Name MatEnvName:MatEnvName MatEnv2Name:MatEnv2Name)
							fseek mt MATRet #seek_set
						)
					)
					fclose mt
				)
				multimat = MultiMaterial()
				multimat.name = "SSBUMesh"
				multimat.numsubs = Materials_array.count
				for m = 1 to Materials_array.count do(
					MultiMat.materialList[m] = StandardMaterial()
					mat = multimat.materialList[m]
					mat.name = Materials_array[m].MatName
					mat.showinviewport = true
					mat.twosided = false
					tm = Bitmaptexture filename:(fpath + (Materials_array[m].MatColName as string) + ".png")
					tm.alphasource = 0
					mat.diffuseMap = tm
					mat.opacityMap = tm
					mat.opacityMap.monoOutput = 1
				)
				printDebug(Materials_array)
			)

			if SKTName != undefined do(
				b = fopen SKTName "rb"
				fseek b 0x10 #seek_set
				BoneCheck = readlong b
				if BoneCheck == 0x534B454C do(
					fseek b 0x18 #seek_set
					BoneOffset = (ftell b) + readlong b; fseek b 0x04 #seek_cur
					BoneCount = readlong b; fseek b 0x04 #seek_cur
					BoneMatrOffset = (ftell b) + readlong b; fseek b 0x04 #seek_cur
					BoneMatrCount = readlong b; fseek b 0x04 #seek_cur
					BoneInvMatrOffset = (ftell b) + readlong b; fseek b 0x04 #seek_cur
					BoneInvMatrCount = readlong b; fseek b 0x04 #seek_cur
					BoneRelMatrOffset = (ftell b) + readlong b; fseek b 0x04 #seek_cur
					BoneRelMatrCount = readlong b; fseek b 0x04 #seek_cur
					BoneRelMatrInvOffset = (ftell b) + readlong b; fseek b 0x04 #seek_cur
					BoneRelMatrInvCount = readlong b; fseek b 0x04 #seek_cur
					fseek b BoneOffset #seek_set

					for c = 1 to BoneCount do(
						BoneNameOffset = (ftell b) + readlong b; fseek b 0x04 #seek_cur
						BoneRet = (ftell b)
						fseek b BoneNameOffset #seek_set
						BoneName = readstring b
						fseek b BoneRet #seek_set
						BoneID = readshort b
						BoneParent = readshort b + 1
						BoneUnk = readlong b
						append BoneParent_array BoneParent
						append BoneName_array BoneName
					)
					fseek b BoneMatrOffset #seek_set

					for c = 1 to BoneCount do(
						m11 = readfloat b; m12 = readfloat b; m13 = readfloat b; m14 = readfloat b
						m21 = readfloat b; m22 = readfloat b; m23 = readfloat b; m24 = readfloat b
						m31 = readfloat b; m32 = readfloat b; m33 = readfloat b; m34 = readfloat b
						m41 = readfloat b; m42 = readfloat b; m43 = readfloat b; m44 = readfloat b
						if SnapScaleFix == true do(m41 = m41 * 100; m42 = m42 * 100; m43 = m43 * 100)
						tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
						newBone = bonesys.createbone   \
							tfm.row4   \
							(tfm.row4 + 0.01 * (normalize tfm.row1)) \
							(normalize tfm.row3)
							BoneName = BoneName_array[c]
							BoneParent = BoneParent_array[c]
							newBone.name = BoneName
							newBone.width  = 0.01
							newBone.height = 0.01
							newBone.transform = tfm
							newBone.setBoneEnable false 0
							newBone.wirecolor = yellow
							newBone.showlinks = true
							newBone.pos.controller      = TCB_position ()
							newBone.rotation.controller = TCB_rotation ()
							if (BoneParent != 0) then
							newBone.parent = BoneArray[(BoneParent)]
							if BoneParent > c do(append BoneFixArray c) -- This thing again?
							append BoneArray newBone
							append BoneTrsArray newBone.transform
					)
					for x = 1 to BoneFixArray.count do(
						select BoneArray[BoneFixArray[x]]
						$.parent = BoneArray[BoneParent_array[BoneFixArray[x]]]
					)
				)
				fclose b
			)

			if MSHName != undefined do(
				f = fopen MSHName "rb"
				st = timestamp()

				struct weight_data (boneids, weights)
				struct PolyGrpStruct (VisGrpName, SubGroupNum, SingleBindName, FacepointCount, FacepointStart, FaceLongBit, VertCount, VertStart, VertStride, UVStart, UVStride, BuffParamStart, BuffParamCount)
				struct WeightGrpStruct (GrpName, SubGroupNum, WeightInfMax, WeightFlag2, WeightFlag3, WeightFlag4, RigInfOffset, RigInfCount)

				fseek f 0x10 #seek_set
				MSHCheck = readlong f
				if MSHCheck == 0x4D455348 do(
					fseek f 0x88 #seek_set
					PolyGrpInfOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					PolyGrpCount = readlong f; fseek f 0x04 #seek_cur
					UnkOffset1 = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					UnkCount1 = readlong f; fseek f 0x04 #seek_cur
					FaceBuffSizeB = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					VertBuffOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					UnkCount2 = readlong f; fseek f 0x04 #seek_cur
					FaceBuffOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					FaceBuffSize = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					WeightBuffOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					WeightCount = readlong f; fseek f 0x04 #seek_cur

					fseek f PolyGrpInfOffset #seek_set
					for g = 1 to PolyGrpCount do(
						VisGrpNameOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
						SubGroupNum = readlong f
						Unk1 = readlong f
						SingleBindNameOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
						VertCount = readlong f
						FacepointCount = readlong f
						Unk2 = readlong f -- Always 3?
						VertStart = readlong f
						UVStart = readlong f
						UnkOff1 = readlong f
						Unk3 = readlong f -- Always 0?
						VertStride = readlong f
						UVStride = readlong f
						Unk4 = readlong f -- Either 0 or 32
						Unk5 = readlong f -- Always 0
						FacepointStart = readlong f
						Unk6 = readlong f -- Always 4
						FaceLongBit = readlong f -- Either 0 or 1
						Unk8 = readlong f -- Either 0 or 1
						SortPriority = readlong f
						Unk9 = readlong f -- 0, 1, 256 or 257
						fseek f 0x64 #seek_cur -- A bunch of unknown float values.
						BuffParamStart = (ftell f) + readlong f; fseek f 0x04 #seek_cur
						BuffParamCount = readlong f
						Unk10 = readlong f -- Always 0
						PolyGrpRet = (ftell f)
						fseek f VisGrpNameOffset #seek_set
						VisGrpName = readstring f
						fseek f SingleBindNameOffset #seek_set
						SingleBindName = readstring f
						append PolyGrp_array (PolyGrpStruct VisGrpName:VisGrpName SubGroupNum:SubGroupNum SingleBindName:SingleBindName FacepointCount:FacepointCount FacepointStart:FacepointStart FaceLongBit:FaceLongBit VertCount:VertCount VertStart:VertStart VertStride:VertStride UVStart:UVStart UVStride:UVStride BuffParamStart:BuffParamStart BuffParamCount:BuffParamCount)
						printDebug(VisGrpName as string + " SubGroup " + SubGroupNum as string + " unknowns: 1: " + Unk1 as string + " | Off1: " + UnkOff1 as string + " | 2: " + Unk2 as string + " | 3: " + Unk3 as string + " | 4: " + Unk4 as string + " | 5: " + Unk5 as string + " | 6: " + Unk6 as string + " | LongFace: " + FaceLongBit as string + " | 8: " + Unk8 as string + " | Sort: " + SortPriority as string + " | 9: " + Unk9 as string + " | 10: " + Unk10 as string)
						fseek f PolyGrpRet #seek_set
					)
					printDebug(PolyGrp_array)

					fseek f VertBuffOffset #seek_set
					VertOffStart = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					VertBuffSize = readlong f; fseek f 0x04 #seek_cur
					UVOffStart = (ftell f) + readlong f; fseek f 0x04 #seek_cur
					UVBuffSize = readlong f; fseek f 0x04 #seek_cur
					
					fseek f WeightBuffOffset #seek_set
					
					for b = 1 to WeightCount do(
						GrpNameOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
						SubGroupNum = readlong f; fseek f 0x04 #seek_cur
						WeightInfMax = readbyte f #unsigned; WeightFlag2 = readbyte f #unsigned; WeightFlag3 = readbyte f #unsigned; WeightFlag4 = readbyte f #unsigned; fseek f 0x04 #seek_cur
						RigInfOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
						RigInfCount = readlong f; fseek f 0x04 #seek_cur
						WeightRet = (ftell f)
						fseek f GrpNameOffset #seek_set
						GrpName = readstring f
						append WeightGrp_array (WeightGrpStruct GrpName:GrpName SubGroupNum:SubGroupNum WeightInfMax:WeightInfMax WeightFlag2:WeightFlag2 WeightFlag3:WeightFlag3 WeightFlag4:WeightFlag4 RigInfOffset:RigInfOffset RigInfCount:RigInfCount)
						fseek f WeightRet #seek_set
					)
					printDebug(WeightGrp_array)

					for p = 1 to PolyGrpCount do(
						Vert_array = #()
						Normal_array = #()
						Color_array = #(); Color2_array = #(); Color3_array = #(); Color4_array = #(); Color5_array = #()
						Alpha_array = #(); Alpha2_array = #(); Alpha3_array = #(); Alpha4_array = #(); Alpha5_array = #()
						UV_array = #(); UV2_array = #(); UV3_array = #(); UV4_array = #(); UV5_array = #()
						Face_array = #()
						Weight_array = #()
						SingleBindID = 0

						fseek f PolyGrp_array[p].BuffParamStart #seek_set
						
						PosFmt = 0; NormFmt = 0; BinormFmt = 0; Binorm2Fmt = 0; TanFmt = 0; Tan2Fmt = 0
						ColorCount = 0; ColorFmt = 0; UVCount = 0; UVFmt = 0 -- Assuming all UV mapping and color layers use the same format check is a terrible idea, but I don't think more than one format is used simultaneously.
						
						for v = 1 to PolyGrp_array[p].BuffParamCount do(
							BuffParamType = readlong f
							BuffParamFmt = readlong f + 1 -- Adding one so that "0" counts as "none".
							BuffParamSet = readlong f
							BuffParamOffset = readlong f
							BuffParamLayer = readlong f
							BuffParamUnk1 = readlong f -- always 0?
							BuffParamStrOff1 = (ftell f) + readlong f; fseek f 0x04 #seek_cur
							BuffParamStrOff2 = (ftell f) + readlong f; fseek f 0x04 #seek_cur
							BuffParamUnk2 = readlong f -- always 1?
							BuffParamUnk3 = readlong f -- always 0?
							BuffParamRet = (ftell f)
							fseek f BuffParamStrOff2 #seek_set
							BuffNameOff = (ftell f) + readlong f; fseek f 0x04 #seek_set
							fseek f BuffNameOff #seek_set
							BuffName = readstring f
							case BuffName of(
								default: (throw ("Unknown format!"))
								"Position0":(PosFmt = BuffParamFmt)
								"Normal0":(NormFmt = BuffParamFmt)
								"Binormal0":(BinormFmt = BuffParamFmt)
								"Binormal1":(Binorm2Fmt = BuffParamFmt)
								"Tangent0":(TanFmt = BuffParamFmt)
								"Tangent1":(Tan2Fmt = BuffParamFmt)
								"map1":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"uvSet":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"uvSet1":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"uvSet2":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"bake1":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"TextureCoordinate0":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"TextureCoordinate1":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"TextureCoordinate2":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"TextureCoordinate3":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"LightMapTextureCoordinate1":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"LightMapTextureCoordinate2":(UVCount = UVCount + 1; UVFmt = BuffParamFmt)
								"colorSet1":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet2":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet2_1":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet2_2":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet2_3":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet3":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet4":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet5":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet6":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"colorSet7":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"Color0":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"Color1":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
								"Color2":(ColorCount = ColorCount + 1; ColorFmt = BuffParamFmt)
							)
							fseek f BuffParamRet #seek_set
						)

						fseek f (VertOffStart + PolyGrp_array[p].VertStart) #seek_set

						printDebug("Vert start: " + (ftell f as string))
						for v = 1 to PolyGrp_array[p].VertCount do(
							case PosFmt of(
								default: (throw ("Unknown position format!"))
								1:(
									vx = readfloat f; vy = readfloat f; vz = readfloat f
									if SnapScaleFix == true do(vx = vx * 100; vy = vy * 100; vz = vz * 100)
									append Vert_array [vx,vy,vz]
								)
							)
							case NormFmt of(
								default: (throw ("Unknown normals format!"))
								1:(
									nx = readfloat f; ny = readfloat f; nz = readfloat f
									append Normal_array [nx,ny,nz]
								)
								6:(
									nx = readhalffloat f; ny = readhalffloat f; nz = readhalffloat f; nq = readhalffloat f
									append Normal_array [nx,ny,nz]
								)
							)
							case BinormFmt of(
								default: (throw ("Unknown binormals format!"))
								0:()
								1:(
									binx = readfloat f; biny = readfloat f; binz = readfloat f
								)
								6:(
									binx = readhalffloat f; biny = readhalffloat f; binz = readhalffloat f; binq = readhalffloat f
								)
							)
							case Binorm2Fmt of(
								default: (throw ("Unknown binormals 2 format!"))
								0:()
								1:(
									bin2x = readfloat f; bin2y = readfloat f; bin2z = readfloat f
								)
								6:(
									bin2x = readhalffloat f; bin2y = readhalffloat f; bin2z = readhalffloat f; bin2q = readhalffloat f
								)
							)
							case TanFmt of(
								default: (throw ("Unknown tangents format!"))
								0:()
								1:(
									tanx = readfloat f; tany = readfloat f; tanz = readfloat f
								)
								6:(
									tanx = readhalffloat f; tany = readhalffloat f; tanz = readhalffloat f; tanq = readhalffloat f
								)
							)
							case Tan2Fmt of(
								default: (throw ("Unknown tangents 2 format!"))
								0:()
								1:(
									tan2x = readfloat f; tan2y = readfloat f; tan2z = readfloat f
								)
								6:(
									tan2x = readhalffloat f; tan2y = readhalffloat f; tan2z = readhalffloat f; tan2q = readhalffloat f
								)
							)
						)
						printDebug("Vert end: " + (ftell f as string))

						fseek f (UVOffStart + PolyGrp_array[p].UVStart) #seek_set

						printDebug("UV start: " + (ftell f as string))
						for v = 1 to PolyGrp_array[p].VertCount do(
							case UVCount of(
								default: (throw ("More than 5 UV sets, crashing gracefully."))
								0:(
									append UV_array [0,0,0]
								)
								1:(
									case UVFmt of(
										default: (throw ("Unknown UVs format!"))
										8:(
											tu = (readfloat f); tv = ((readfloat f) * -1) + 1
											append UV_array [tu,tv,0]
										)
										9:(
											tu = (readhalffloat f); tv = ((readhalffloat f) * -1) + 1
											append UV_array [tu,tv,0]
										)
									)
								)
								2:(
									case UVFmt of(
										default: (throw ("Unknown UVs format!"))
										8:(
											tu = (readfloat f); tv = ((readfloat f) * -1) + 1
											tu2 = (readfloat f); tv2 = ((readfloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
										)
										9:(
											tu = (readhalffloat f); tv = ((readhalffloat f) * -1) + 1
											tu2 = (readhalffloat f); tv2 = ((readhalffloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
										)
									)
								)
								3:(
									case UVFmt of(
										default: (throw ("Unknown UVs format!"))
										8:(
											tu = (readfloat f); tv = ((readfloat f) * -1) + 1
											tu2 = (readfloat f); tv2 = ((readfloat f) * -1) + 1
											tu3 = (readfloat f); tv3 = ((readfloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
											append UV3_array [tu3,tv3,0]
										)
										9:(
											tu = (readhalffloat f); tv = ((readhalffloat f) * -1) + 1
											tu2 = (readhalffloat f); tv2 = ((readhalffloat f) * -1) + 1
											tu3 = (readhalffloat f); tv3 = ((readhalffloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
											append UV3_array [tu3,tv3,0]
										)
									)
								)
								4:(
									case UVFmt of(
										default: (throw ("Unknown UVs format!"))
										8:(
											tu = (readfloat f); tv = ((readfloat f) * -1) + 1
											tu2 = (readfloat f); tv2 = ((readfloat f) * -1) + 1
											tu3 = (readfloat f); tv3 = ((readfloat f) * -1) + 1
											tu4 = (readfloat f); tv4 = ((readfloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
											append UV3_array [tu3,tv3,0]
											append UV4_array [tu4,tv4,0]
										)
										9:(
											tu = (readhalffloat f); tv = ((readhalffloat f) * -1) + 1
											tu2 = (readhalffloat f); tv2 = ((readhalffloat f) * -1) + 1
											tu3 = (readhalffloat f); tv3 = ((readhalffloat f) * -1) + 1
											tu4 = (readhalffloat f); tv4 = ((readhalffloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
											append UV3_array [tu3,tv3,0]
											append UV4_array [tu4,tv4,0]
										)
									)
								)
								5:(
									case UVFmt of(
										default: (throw ("Unknown UVs format!"))
										8:(
											tu = (readfloat f); tv = ((readfloat f) * -1) + 1
											tu2 = (readfloat f); tv2 = ((readfloat f) * -1) + 1
											tu3 = (readfloat f); tv3 = ((readfloat f) * -1) + 1
											tu4 = (readfloat f); tv4 = ((readfloat f) * -1) + 1
											tu5 = (readfloat f); tv5 = ((readfloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
											append UV3_array [tu3,tv3,0]
											append UV4_array [tu4,tv4,0]
											append UV5_array [tu5,tv5,0]
										)
										9:(
											tu = (readhalffloat f); tv = ((readhalffloat f) * -1) + 1
											tu2 = (readhalffloat f); tv2 = ((readhalffloat f) * -1) + 1
											tu3 = (readhalffloat f); tv3 = ((readhalffloat f) * -1) + 1
											tu4 = (readhalffloat f); tv4 = ((readhalffloat f) * -1) + 1
											tu5 = (readhalffloat f); tv5 = ((readhalffloat f) * -1) + 1
											append UV_array [tu,tv,0]
											append UV2_array [tu2,tv2,0]
											append UV3_array [tu3,tv3,0]
											append UV4_array [tu4,tv4,0]
											append UV5_array [tu5,tv5,0]
										)
									)
								)
							)
							case ColorCount of(
								default: (throw ("More than 5 color sets, crashing gracefully."))
								0:(
									if VertColorsMult != true then(
										append Color_array [128,128,128]
									) else (
										append Color_array [255,255,255]
									)
									append Alpha_array 1
								)
								1:(
									case ColorFmt of(
										default: (throw ("Unknown colors format!"))
										3:(
											colorr = readbyte f #unsigned; colorg = readbyte f #unsigned; colorb = readbyte f #unsigned; colora = (readbyte f #unsigned as float) / 128
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr >= 254 do(colorr = 255)
												if colorg >= 254 do(colorg = 255)
												if colorb >= 254 do(colorb = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
										)
										5:(
											colorr = readfloat f * 255; colorg = readfloat f * 255; colorb = readfloat f * 255; colora = readfloat f
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr > 255 do(colorr = 255)
												if colorg > 255 do(colorg = 255)
												if colorb > 255 do(colorb = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
										)
									)
								)
								2:(
									case ColorFmt of(
										default: (throw ("Unknown colors format!"))
										3:(
											colorr = readbyte f #unsigned; colorg = readbyte f #unsigned; colorb = readbyte f #unsigned; colora = (readbyte f #unsigned as float) / 128
											colorr2 = readbyte f #unsigned; colorg2 = readbyte f #unsigned; colorb2 = readbyte f #unsigned; colora2 = (readbyte f #unsigned as float) / 128
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr >= 254 do(colorr = 255)
												if colorg >= 254 do(colorg = 255)
												if colorb >= 254 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 >= 254 do(colorr2 = 255)
												if colorg2 >= 254 do(colorg2 = 255)
												if colorb2 >= 254 do(colorb2 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
										)
										5:(
											colorr = readfloat f * 255; colorg = readfloat f * 255; colorb = readfloat f * 255; colora = readfloat f
											colorr2 = readfloat f * 255; colorg2 = readfloat f * 255; colorb2 = readfloat f * 255; colora2 = readfloat f
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr > 255 do(colorr = 255)
												if colorg > 255 do(colorg = 255)
												if colorb > 255 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 > 255 do(colorr2 = 255)
												if colorg2 > 255 do(colorg2 = 255)
												if colorb2 > 255 do(colorb2 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
										)
									)
								)
								3:(
									case ColorFmt of(
										default: (throw ("Unknown colors format!"))
										3:(
											colorr = readbyte f #unsigned; colorg = readbyte f #unsigned; colorb = readbyte f #unsigned; colora = (readbyte f #unsigned as float) / 128
											colorr2 = readbyte f #unsigned; colorg2 = readbyte f #unsigned; colorb2 = readbyte f #unsigned; colora2 = (readbyte f #unsigned as float) / 128
											colorr3 = readbyte f #unsigned; colorg3 = readbyte f #unsigned; colorb3 = readbyte f #unsigned; colora3 = (readbyte f #unsigned as float) / 128
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr >= 254 do(colorr = 255)
												if colorg >= 254 do(colorg = 255)
												if colorb >= 254 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 >= 254 do(colorr2 = 255)
												if colorg2 >= 254 do(colorg2 = 255)
												if colorb2 >= 254 do(colorb2 = 255)
												colorr3 = colorr3 * 2; colorg3 = colorg3 * 2; colorb3 = colorb3 * 2
												if colorr3 >= 254 do(colorr3 = 255)
												if colorg3 >= 254 do(colorg3 = 255)
												if colorb3 >= 254 do(colorb3 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
											append Color3_array [colorr3,colorg3,colorb3]; append Alpha3_array colora3
										)
										5:(
											colorr = readfloat f * 255; colorg = readfloat f * 255; colorb = readfloat f * 255; colora = readfloat f
											colorr2 = readfloat f * 255; colorg2 = readfloat f * 255; colorb2 = readfloat f * 255; colora2 = readfloat f
											colorr3 = readfloat f * 255; colorg3 = readfloat f * 255; colorb3 = readfloat f * 255; colora3 = readfloat f
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr > 255 do(colorr = 255)
												if colorg > 255 do(colorg = 255)
												if colorb > 255 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 > 255 do(colorr2 = 255)
												if colorg2 > 255 do(colorg2 = 255)
												if colorb2 > 255 do(colorb2 = 255)
												colorr3 = colorr3 * 2; colorg3 = colorg3 * 2; colorb3 = colorb3 * 2
												if colorr3 > 255 do(colorr3 = 255)
												if colorg3 > 255 do(colorg3 = 255)
												if colorb3 > 255 do(colorb3 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
											append Color3_array [colorr3,colorg3,colorb3]; append Alpha3_array colora3
										)
									)
								)
								4:(
									case ColorFmt of(
										default: (throw ("Unknown colors format!"))
										3:(
											colorr = readbyte f #unsigned; colorg = readbyte f #unsigned; colorb = readbyte f #unsigned; colora = (readbyte f #unsigned as float) / 128
											colorr2 = readbyte f #unsigned; colorg2 = readbyte f #unsigned; colorb2 = readbyte f #unsigned; colora2 = (readbyte f #unsigned as float) / 128
											colorr3 = readbyte f #unsigned; colorg3 = readbyte f #unsigned; colorb3 = readbyte f #unsigned; colora3 = (readbyte f #unsigned as float) / 128
											colorr4 = readbyte f #unsigned; colorg4 = readbyte f #unsigned; colorb4 = readbyte f #unsigned; colora4 = (readbyte f #unsigned as float) / 128
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr >= 254 do(colorr = 255)
												if colorg >= 254 do(colorg = 255)
												if colorb >= 254 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 >= 254 do(colorr2 = 255)
												if colorg2 >= 254 do(colorg2 = 255)
												if colorb2 >= 254 do(colorb2 = 255)
												colorr3 = colorr3 * 2; colorg3 = colorg3 * 2; colorb3 = colorb3 * 2
												if colorr3 >= 254 do(colorr3 = 255)
												if colorg3 >= 254 do(colorg3 = 255)
												if colorb3 >= 254 do(colorb3 = 255)
												colorr4 = colorr4 * 2; colorg4 = colorg4 * 2; colorb4 = colorb4 * 2
												if colorr4 >= 254 do(colorr4 = 255)
												if colorg4 >= 254 do(colorg4 = 255)
												if colorb4 >= 254 do(colorb4 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
											append Color3_array [colorr3,colorg3,colorb3]; append Alpha3_array colora3
											append Color4_array [colorr4,colorg4,colorb4]; append Alpha4_array colora4
										)
										5:(
											colorr = readfloat f * 255; colorg = readfloat f * 255; colorb = readfloat f * 255; colora = readfloat f
											colorr2 = readfloat f * 255; colorg2 = readfloat f * 255; colorb2 = readfloat f * 255; colora2 = readfloat f
											colorr3 = readfloat f * 255; colorg3 = readfloat f * 255; colorb3 = readfloat f * 255; colora3 = readfloat f
											colorr4 = readfloat f * 255; colorg4 = readfloat f * 255; colorb4 = readfloat f * 255; colora4 = readfloat f
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr > 255 do(colorr = 255)
												if colorg > 255 do(colorg = 255)
												if colorb > 255 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 > 255 do(colorr2 = 255)
												if colorg2 > 255 do(colorg2 = 255)
												if colorb2 > 255 do(colorb2 = 255)
												colorr3 = colorr3 * 2; colorg3 = colorg3 * 2; colorb3 = colorb3 * 2
												if colorr3 > 255 do(colorr3 = 255)
												if colorg3 > 255 do(colorg3 = 255)
												if colorb3 > 255 do(colorb3 = 255)
												colorr4 = colorr4 * 2; colorg4 = colorg4 * 2; colorb4 = colorb4 * 2
												if colorr4 > 255 do(colorr4 = 255)
												if colorg4 > 255 do(colorg4 = 255)
												if colorb4 > 255 do(colorb4 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
											append Color3_array [colorr3,colorg3,colorb3]; append Alpha3_array colora3
											append Color4_array [colorr4,colorg4,colorb4]; append Alpha4_array colora4
										)
									)
								)
								5:(
									case ColorFmt of(
										default: (throw ("Unknown colors format!"))
										3:(
											colorr = readbyte f #unsigned; colorg = readbyte f #unsigned; colorb = readbyte f #unsigned; colora = (readbyte f #unsigned as float) / 128
											colorr2 = readbyte f #unsigned; colorg2 = readbyte f #unsigned; colorb2 = readbyte f #unsigned; colora2 = (readbyte f #unsigned as float) / 128
											colorr3 = readbyte f #unsigned; colorg3 = readbyte f #unsigned; colorb3 = readbyte f #unsigned; colora3 = (readbyte f #unsigned as float) / 128
											colorr4 = readbyte f #unsigned; colorg4 = readbyte f #unsigned; colorb4 = readbyte f #unsigned; colora4 = (readbyte f #unsigned as float) / 128
											colorr5 = readbyte f #unsigned; colorg5 = readbyte f #unsigned; colorb5 = readbyte f #unsigned; colora5 = (readbyte f #unsigned as float) / 128
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr >= 254 do(colorr = 255)
												if colorg >= 254 do(colorg = 255)
												if colorb >= 254 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 >= 254 do(colorr2 = 255)
												if colorg2 >= 254 do(colorg2 = 255)
												if colorb2 >= 254 do(colorb2 = 255)
												colorr3 = colorr3 * 2; colorg3 = colorg3 * 2; colorb3 = colorb3 * 2
												if colorr3 >= 254 do(colorr3 = 255)
												if colorg3 >= 254 do(colorg3 = 255)
												if colorb3 >= 254 do(colorb3 = 255)
												colorr4 = colorr4 * 2; colorg4 = colorg4 * 2; colorb4 = colorb4 * 2
												if colorr4 >= 254 do(colorr4 = 255)
												if colorg4 >= 254 do(colorg4 = 255)
												if colorb4 >= 254 do(colorb4 = 255)
												colorr5 = colorr5 * 2; colorg5 = colorg5 * 2; colorb5 = colorb5 * 2
												if colorr5 >= 254 do(colorr5 = 255)
												if colorg5 >= 254 do(colorg5 = 255)
												if colorb5 >= 254 do(colorb5 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
											append Color3_array [colorr3,colorg3,colorb3]; append Alpha3_array colora3
											append Color4_array [colorr4,colorg4,colorb4]; append Alpha4_array colora4
											append Color5_array [colorr5,colorg5,colorb5]; append Alpha5_array colora5
										)
										5:(
											colorr = readfloat f * 255; colorg = readfloat f * 255; colorb = readfloat f * 255; colora = readfloat f
											colorr2 = readfloat f * 255; colorg2 = readfloat f * 255; colorb2 = readfloat f * 255; colora2 = readfloat f
											colorr3 = readfloat f * 255; colorg3 = readfloat f * 255; colorb3 = readfloat f * 255; colora3 = readfloat f
											colorr4 = readfloat f * 255; colorg4 = readfloat f * 255; colorb4 = readfloat f * 255; colora4 = readfloat f
											colorr5 = readfloat f * 255; colorg5 = readfloat f * 255; colorb5 = readfloat f * 255; colora5 = readfloat f
											if VertColorsMult == true do(
												colorr = colorr * 2; colorg = colorg * 2; colorb = colorb * 2
												if colorr > 255 do(colorr = 255)
												if colorg > 255 do(colorg = 255)
												if colorb > 255 do(colorb = 255)
												colorr2 = colorr2 * 2; colorg2 = colorg2 * 2; colorb2 = colorb2 * 2
												if colorr2 > 255 do(colorr2 = 255)
												if colorg2 > 255 do(colorg2 = 255)
												if colorb2 > 255 do(colorb2 = 255)
												colorr3 = colorr3 * 2; colorg3 = colorg3 * 2; colorb3 = colorb3 * 2
												if colorr3 > 255 do(colorr3 = 255)
												if colorg3 > 255 do(colorg3 = 255)
												if colorb3 > 255 do(colorb3 = 255)
												colorr4 = colorr4 * 2; colorg4 = colorg4 * 2; colorb4 = colorb4 * 2
												if colorr4 > 255 do(colorr4 = 255)
												if colorg4 > 255 do(colorg4 = 255)
												if colorb4 > 255 do(colorb4 = 255)
												colorr5 = colorr5 * 2; colorg5 = colorg5 * 2; colorb5 = colorb5 * 2
												if colorr5 > 255 do(colorr5 = 255)
												if colorg5 > 255 do(colorg5 = 255)
												if colorb5 > 255 do(colorb5 = 255)
											)
											append Color_array [colorr,colorg,colorb]; append Alpha_array colora
											append Color2_array [colorr2,colorg2,colorb2]; append Alpha2_array colora2
											append Color3_array [colorr3,colorg3,colorb3]; append Alpha3_array colora3
											append Color4_array [colorr4,colorg4,colorb4]; append Alpha4_array colora4
											append Color5_array [colorr5,colorg5,colorb5]; append Alpha5_array colora5
										)
									)
								)
							)
						)
						printDebug("UV end: " + (ftell f as string))

						fseek f (FaceBuffOffset + PolyGrp_array[p].FacepointStart) #seek_set
						printDebug("Face start: " + (ftell f as string))
						for fc = 1 to (PolyGrp_array[p].FacepointCount / 3) do(
							case PolyGrp_array[p].FaceLongBit of(
								default:(throw("Unknown face bit value!"))
								0:(
										fa = readshort f #unsigned + 1; fb = readshort f #unsigned + 1; fc = readshort f #unsigned + 1
										append Face_array [fa,fb,fc]
								)
								1:(
										fa = readlong f #unsigned + 1; fb = readlong f #unsigned + 1; fc = readlong f #unsigned + 1
										append Face_array [fa,fb,fc]
								)
							)
						)
						printDebug("Face end: " + (ftell f as string))

						if PolyGrp_array[p].SingleBindName != "" and BoneCount > 0 then (
							for b = 1 to BoneArray.count do(
								if PolyGrp_array[p].SingleBindName == BoneArray[b].name do(
									SingleBindID = b
								)
							)
							for b = 1 to Vert_array.count do(
								append Weight_array (weight_data boneids:#(SingleBindID) weights:#(1.0))
							)
						) else (
							for b = 1 to Vert_array.count do(
								append Weight_array (weight_data boneids:#() weights:#())
							)
							RigSet = 1
							for b = 1 to WeightGrp_array.count do(
								if (PolyGrp_array[p].VisGrpName == WeightGrp_array[b].GrpName) and (PolyGrp_array[p].SubGroupNum == WeightGrp_array[b].SubGroupNum) do(
									RigSet = b
									exit
								)
							)

							fseek f WeightGrp_array[RigSet].RigInfOffset #seek_set
							printDebug("Rig info start: " + (ftell f) as string)

							if WeightGrp_array[RigSet].RigInfCount != 0 then (
								for x = 1 to WeightGrp_array[RigSet].RigInfCount do(
									RigBoneNameOffset = (ftell f) + readlong f; fseek f 0x04 #seek_cur
									RigBuffStart = (ftell f) + readlong f; fseek f 0x04 #seek_cur
									RigBuffSize = readlong f; fseek f 0x04 #seek_cur
									RigRet = (ftell f)
									fseek f RigBoneNameOffset #seek_set
									RigBoneName = readstring f
									fseek f RigBuffStart #seek_set
									RigBoneID = 0
									for b = 1 to BoneArray.count do(
										if RigBoneName == BoneArray[b].name do(
											RigBoneID = b
										)
									)
									if RigBoneID == 0 do(
										print (RigBoneName + " doesn't exist on " + PolyGrp_array[p].VisGrpName + "! Transferring rigging to " + BoneArray[1].name + ".")
										RigBoneID = 1
									)
									for y = 1 to (RigBuffSize / 0x06) do(
										RigVertID = readshort f + 1
										RigValue = readfloat f
										append Weight_array[RigVertID].boneids RigBoneID
										append Weight_array[RigVertID].weights RigValue
									)
									fseek f RigRet #seek_set
								) 
							) else (
								print (PolyGrp_array[p].VisGrpName + " has no influences! Treating as a root singlebind instead.")
								Weight_array = #()
								for b = 1 to Vert_array.count do(
									append Weight_array (weight_data boneids:#(1) weights:#(1.0))
								)
							)
						)

						MatID = 1
						
						for b = 1 to WeightGrp_array.count do(
							if (PolyGrp_array[p].VisGrpName == WeightGrp_array[b].GrpName) and (PolyGrp_array[p].SubGroupNum == WeightGrp_array[b].SubGroupNum) do(
								RigSet = b
								exit
							)
						)
						for c = 1 to MODLGrp_array.count do(
							if (PolyGrp_array[p].VisGrpName == MODLGrp_array[c].MSHGrpName) and (PolyGrp_array[p].SubGroupNum == MODLGrp_array[c].MSHSubgroupNum) do(
								for b = 1 to Materials_array.count do(
									if Materials_array[b].MatName == MODLGrp_array[c].MSHMatName do(
										MatID = b
										exit
									)
								)
								exit
							)
						)
						msh = mesh vertices:Vert_array faces:Face_array
						msh.numTVerts = Vert_array.count
						if PolyGrp_array[p].SingleBindName != "" and BoneCount > 0 do(
							SingleBindID = 1
							for b = 1 to BoneName_array.count do(
								if PolyGrp_array[p].SingleBindName == BoneName_array[b] do(
									SingleBindID = b
									exit
								)
							)
							msh.transform = BoneTrsArray[SingleBindID]
						)
						if VertColors == true then (
							setNumCPVVerts msh msh.numTVerts
							setCVertMode msh true
							setShadeCVerts msh true
						)
						defaultVCFaces msh
						buildTVFaces msh
						msh.name = (PolyGrp_array[p].VisGrpName as string)
						msh.material = multimat
						for j = 1 to UV_array.count do setTVert msh j UV_array[j]
						if UV2_array.count > 0 do(
							meshop.setNumMaps msh 3 keep:true
							for i = 1 to UV2_array.count do (
								meshop.setMapVert msh 2 i UV2_array[i]
							)
						)
						if UV3_array.count > 0 do(
							meshop.setNumMaps msh 4 keep:true
							for i = 1 to UV3_array.count do (
								meshop.setMapVert msh 3 i UV3_array[i]
							)
						)
						if UV4_array.count > 0 do(
							meshop.setNumMaps msh 5 keep:true
							for i = 1 to UV4_array.count do (
								meshop.setMapVert msh 4 i UV4_array[i]
							)
						)
						if UV5_array.count > 0 do(
							meshop.setNumMaps msh 6 keep:true
							for i = 1 to UV5_array.count do (
								meshop.setMapVert msh 5 i UV5_array[i]
							)
						)
						for j = 1 to Face_array.count do (
							setTVFace msh j Face_array[j]
							setFaceMatID msh j MatID
						)
						if VertColors == true do(
							for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
							for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
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

						$.pivot = [0,0,0]
						ResetXForm $
						CollapseStack $

						if BoneCount > 0 do(
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

							-- These fix broken rigging for 3DS Max 2015 and above.
							for i = 1 to Vert_array.count do(
								skinOps.SetVertexWeights skinMod i 1 1
								skinOps.unnormalizeVertex skinMod i true 
								skinOps.SetVertexWeights skinMod i 1 0
								skinOps.unnormalizeVertex skinMod i false
							)
							skinOps.RemoveZeroWeights skinMod

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
				)
				fclose f
				Print ("Done! ("+((((timestamp())-st)*0.001)as string)+" Seconds)")
			)

		)
	)

)

CreateDialog ModelImporter
