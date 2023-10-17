-- Nintendo Switch Pokémon (Let's Go! Pikachu & Eevee, Sword & Shield, Legends: Arceus, Scarlet & Violet) model importer by Random Talking Bush.
-- #TeamEevee

-- Changelog:
-- November 26, 2022: Fixed common trainer models from Scarlet & Violet ("model_vr") not importing due to an oversight.
-- November 20, 2022: Added support for Pokémon Scarlet & Violet.
-- February 6, 2022: Fixed models with more than 65536 vertices on a single mesh group (e.g. objects_area04_building01) failing to import. (Thanks, New3DsSuchti!)
-- Fixed trainer models erroring in non-ancient 3DS Max versions when importing out of the intended order. (Thanks, FreohrWeohnataKausta!)
-- Added an option to "simplify" materials upon importing, to assist with using the Render to Texture function to re-bake colourized Pokémon textures.
-- January 30th, 2022: Tweaked Pokémon Legends: Arceus models to correctly use Physical materials if using 3DS Max 2017 or above, and build / assign roughness and metalness maps accordingly.
-- January 28th, 2022: Added support for Pokémon Legends: Arceus.
-- Fixed models refusing to import in 3DS Max 2021 (the "twoSided" error was due to it trying to apply "Standard" material settings to a "Physical" material, which apparently is the new default).
-- November 15th, 2019: Fixed issues with the script preventing Sword/Shield models from loading.

rollout ModelImporter "Nintendo Switch Pokémon Model Importer" width:330 height:345
(
	button btnImportGFBMDL "Import *.GFBMDL" pos:[7,8] width:155 height:50 tooltip: "Let's Go! Pikachu / Eevee, Sword / Shield"
	button btnImportTRMDL "Import *.TRMDL" pos:[168,8] width:155 height:50 tooltip: "Pokémon Legends: Arceus, Scarlet / Violet"
	groupBox OptionsBox "Options (General)" pos:[7,65] width:316 height:60
	groupBox OptionsBoxPLA "Options (Legends: Arceus, Scarlet/Violet)" pos:[7,130] width:316 height:95
	label lblVertColors "Vertex colors:" pos:[17,80]
	radiobuttons tglVertColors labels:#("Default","Set 2","Off") pos:[17,100]
	checkbox tglMat "Print material information?" pos:[170,80] checked: false tooltip: "Enable this to print all of the model's material parameters to the Listener window. While not entirely necessary for Let's Go or Sword/Shield models, it's pretty much mandatory for Legends: Arceus due to everything using color masks."
	checkbox tglDebug "Print debug information?" pos:[170,100] checked: false tooltip: "Enable this to print useless information to the Listener window."
	checkbox tglArceusLODs "Import LOD models?" pos:[17,145] checked: false tooltip: "If enabled, this will also import the two lower-poly Level-of-Detail models that Pokémon and NPC characters have alongside the base model."
	checkbox tglArceusScale "Scale to LG/SwSh models?" pos:[170,145] checked: true tooltip: "Pokémon Legends: Arceus and Scarlet/Violet's models are normally 1:100th the scale of the respective models in Let's Go, Sword/Shield and the 3DS games. Enabling this will scale them up 100x to match them. Note that this will break any animation imports."
	checkbox tglArceusMaskSplit "Use split texture masks?" pos:[17,165] checked: false tooltip: "Enable this option if you've taken the time to split the ''lym'' texture files into four separate greyscaled ''lym'' textures (suffixed with '''lym_A'', ''lym_B'', ''lym_C'' and ''lym_D'' for red/green/blue/alpha respectively) to use those instead of the original, merged RGBA images."
	checkbox tglArceusShiny "Use Shiny material?" pos:[170,165] checked: false tooltip: "If enabled, the model will use the respective Shiny (''rare'') material files for Pokémon instead, if applicable."
	checkbox tglArceusSimpleMat "Simplify materials?" pos:[170,185] checked: false tooltip: "If enabled, the model will ignore any material that isn't diffuse, enable self-illumination and will force Standard on 3DS Max 2017 or higher. Should make texture baking a little less complicated for Legends: Arceus."
	spinner spnArceusColorMult "Color multiplier:" width:80 pos:[65,185] range: [0,255,100] tooltip: "While the default is 100%, the material colors are naturally dark (e.g. shades of white being only 44% brightness). Recommended range is around double the original amount. Don't adjust this value for Scarlet/Violet as its color values are already proper amounts." -- Assuming 0.39 = 1 in RGB, 255 should be the absolute maximum it should be without the textures going nuclear.
	label lblTrainerMerge "Trainer model fixes:" pos:[17,205]
	radiobuttons tglTrainerMerge labels:#("Legends: Arceus","Scarlet / Violet") pos:[118,205]
	label lblCred "This script was written by Random Talking Bush for use with the Switch Pokémon games (Let's Go! Pikachu/Eevee, Sword/Shield, Legends: Arceus and Scarlet/Violet). If used, please consider giving thanks to me, Nintendo, Game Freak and The Pokémon Company. If something doesn't work right, please contact me on The VG Resource (Random Talking Bush), XeNTaX, Twitter or Steam (RandomTBush) so I can fix it." pos:[8,230] width:317 height:90
	label lblUpdate "(Updated: 11-26-2022)" pos:[ModelImporter.width-120,ModelImporter.height-19] width:115

	fn readHalfFloat fstream = (
		local BL  = readByte Fstream #unsigned
		local BH  = readByte Fstream #unsigned
		local N = BH*256 + BL
		local S = floor((mod N 65536) / 32768)
		local Ef = floor((mod N 32768) / 1024)
		local M = mod N 1024
		if (Ef==0)AND(M==0) then return ( (-1.0)^S * 0.0 )
		if (Ef==0)AND(M!= 0) then return ( (-1.0)^S * 2.0^-14 * (M / 2.0^10) )
		if (Ef>0)AND(Ef<31) then return ( (-1.0)^S * 2.0^(Ef-15) * (1 + M/2.0^10) )
		if (Ef==31)AND(M==0) then return ( (-1.0)^S * 1/0.0 )
		if (Ef==31)AND(M!= 0) then return 0	--hack-- should be #inf   
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
	fn printMat pr = (if tglMat.state do print(pr))
	fn TrainerRigLink CharaCheck = (
		-- Trainer models expect their base skeletons imported first. This sets up the placeholder names that it expects so things import correctly.
		global BoneRigArray = #()
		case CharaCheck of (
			default:(
				-- Overrides node IDs for player and common NPC character models in this game, this needs to be hardcoded so that additional model parts won't have broken rigging or bone positions.
				-- IDs from 1 to 72 are assigned to the base skeleton file for common NPC characters (cc_base0001_00_young_m, and yes you're reading that right, *every single NPC* uses the same bones).
				BoneRigArray[1] = "foot_base"
				BoneRigArray[2] = "waist"
				BoneRigArray[3] = "spine_01"
				BoneRigArray[4] = "spine_02"
				BoneRigArray[5] = "spine_03"
				BoneRigArray[6] = "neck"
				BoneRigArray[7] = "look"
				BoneRigArray[8] = "head"
				BoneRigArray[9] = "left_shoulder"
				BoneRigArray[10] = "left_arm_width"
				BoneRigArray[11] = "left_arm_01"
				BoneRigArray[12] = "left_arm_02"
				BoneRigArray[13] = "left_hand"
				BoneRigArray[14] = "left_thumb_01"
				BoneRigArray[15] = "left_thumb_02"
				BoneRigArray[16] = "left_thumb_03"
				BoneRigArray[17] = "left_index_01"
				BoneRigArray[18] = "left_index_02"
				BoneRigArray[19] = "left_index_03"
				BoneRigArray[20] = "left_middle_01"
				BoneRigArray[21] = "left_middle_02"
				BoneRigArray[22] = "left_middle_03"
				BoneRigArray[23] = "left_ring_01"
				BoneRigArray[24] = "left_ring_02"
				BoneRigArray[25] = "left_ring_03"
				BoneRigArray[26] = "left_pinky_01"
				BoneRigArray[27] = "left_pinky_02"
				BoneRigArray[28] = "left_pinky_03"
				BoneRigArray[29] = "left_attach_off"
				BoneRigArray[30] = "left_attach_on"
				BoneRigArray[31] = "left_hand_roll"
				BoneRigArray[32] = "left_arm_02_sub"
				BoneRigArray[33] = "left_arm_02_roll"
				BoneRigArray[34] = "left_arm_01_roll"
				BoneRigArray[35] = "right_shoulder"
				BoneRigArray[36] = "right_arm_width"
				BoneRigArray[37] = "right_arm_01"
				BoneRigArray[38] = "right_arm_02"
				BoneRigArray[39] = "right_hand"
				BoneRigArray[40] = "right_thumb_01"
				BoneRigArray[41] = "right_thumb_02"
				BoneRigArray[42] = "right_thumb_03"
				BoneRigArray[43] = "right_index_01"
				BoneRigArray[44] = "right_index_02"
				BoneRigArray[45] = "right_index_03"
				BoneRigArray[46] = "right_middle_01"
				BoneRigArray[47] = "right_middle_02"
				BoneRigArray[48] = "right_middle_03"
				BoneRigArray[49] = "right_ring_01"
				BoneRigArray[50] = "right_ring_02"
				BoneRigArray[51] = "right_ring_03"
				BoneRigArray[52] = "right_pinky_01"
				BoneRigArray[53] = "right_pinky_02"
				BoneRigArray[54] = "right_pinky_03"
				BoneRigArray[55] = "right_attach_off"
				BoneRigArray[56] = "right_attach_on"
				BoneRigArray[57] = "right_hand_roll"
				BoneRigArray[58] = "right_arm_02_sub"
				BoneRigArray[59] = "right_arm_02_roll"
				BoneRigArray[60] = "right_arm_01_roll"
				BoneRigArray[61] = "hips"
				BoneRigArray[62] = "leg_width"
				BoneRigArray[63] = "left_leg_01"
				BoneRigArray[64] = "left_leg_02"
				BoneRigArray[65] = "left_foot"
				BoneRigArray[66] = "left_toe"
				BoneRigArray[67] = "left_leg_02_sub"
				BoneRigArray[68] = "right_leg_01"
				BoneRigArray[69] = "right_leg_02"
				BoneRigArray[70] = "right_foot"
				BoneRigArray[71] = "right_toe"
				BoneRigArray[72] = "right_leg_02_sub"
				-- IDs from 73 to 137 are assigned to the face skeleton file. We can leave these blank as they're not shared with other models.
				BoneRigArray[73] = ""
				BoneRigArray[74] = ""
				BoneRigArray[75] = ""
				BoneRigArray[76] = ""
				BoneRigArray[77] = ""
				BoneRigArray[78] = ""
				BoneRigArray[79] = ""
				BoneRigArray[80] = ""
				BoneRigArray[81] = ""
				BoneRigArray[82] = ""
				BoneRigArray[83] = ""
				BoneRigArray[84] = ""
				BoneRigArray[85] = ""
				BoneRigArray[86] = ""
				BoneRigArray[87] = ""
				BoneRigArray[88] = ""
				BoneRigArray[89] = ""
				BoneRigArray[90] = ""
				BoneRigArray[91] = ""
				BoneRigArray[92] = ""
				BoneRigArray[93] = ""
				BoneRigArray[94] = ""
				BoneRigArray[95] = ""
				BoneRigArray[96] = ""
				BoneRigArray[97] = ""
				BoneRigArray[98] = ""
				BoneRigArray[99] = ""
				BoneRigArray[100] = ""
				BoneRigArray[101] = ""
				BoneRigArray[102] = ""
				BoneRigArray[103] = ""
				BoneRigArray[104] = ""
				BoneRigArray[105] = ""
				BoneRigArray[106] = ""
				BoneRigArray[107] = ""
				BoneRigArray[108] = ""
				BoneRigArray[109] = ""
				BoneRigArray[110] = ""
				BoneRigArray[111] = ""
				BoneRigArray[112] = ""
				BoneRigArray[113] = ""
				BoneRigArray[114] = ""
				BoneRigArray[115] = ""
				BoneRigArray[116] = ""
				BoneRigArray[117] = ""
				BoneRigArray[118] = ""
				BoneRigArray[119] = ""
				BoneRigArray[120] = ""
				BoneRigArray[121] = ""
				BoneRigArray[122] = ""
				BoneRigArray[123] = ""
				BoneRigArray[124] = ""
				BoneRigArray[125] = ""
				BoneRigArray[126] = ""
				BoneRigArray[127] = ""
				BoneRigArray[128] = ""
				BoneRigArray[129] = ""
				BoneRigArray[130] = ""
				BoneRigArray[131] = ""
				BoneRigArray[132] = ""
				BoneRigArray[133] = ""
				BoneRigArray[134] = ""
				BoneRigArray[135] = ""
				BoneRigArray[136] = ""
				BoneRigArray[137] = ""
				-- IDs from 138 and so on are assigned to the outfit skeleton file(s), and are also different depending on the respective model.
				-- We don't need placeholders for these, as they're filled in as necessary by the outfits themselves.
			)
			"FlorianJuliana":(
				-- IDs from 1 to 72 are assigned to the base skeleton file, Florian and Juliana use the exact same skeleton file (model_pc_base/model/p0_base).
				-- It's essentially the same as the default NPCs from both Arceus or Scarlet & Violet, but we're duplicating it anyway.
				BoneRigArray[1] = "foot_base"
				BoneRigArray[2] = "waist"
				BoneRigArray[3] = "spine_01"
				BoneRigArray[4] = "spine_02"
				BoneRigArray[5] = "spine_03"
				BoneRigArray[6] = "neck"
				BoneRigArray[7] = "look"
				BoneRigArray[8] = "head"
				BoneRigArray[9] = "left_shoulder"
				BoneRigArray[10] = "left_arm_width"
				BoneRigArray[11] = "left_arm_01"
				BoneRigArray[12] = "left_arm_02"
				BoneRigArray[13] = "left_hand"
				BoneRigArray[14] = "left_thumb_01"
				BoneRigArray[15] = "left_thumb_02"
				BoneRigArray[16] = "left_thumb_03"
				BoneRigArray[17] = "left_index_01"
				BoneRigArray[18] = "left_index_02"
				BoneRigArray[19] = "left_index_03"
				BoneRigArray[20] = "left_middle_01"
				BoneRigArray[21] = "left_middle_02"
				BoneRigArray[22] = "left_middle_03"
				BoneRigArray[23] = "left_ring_01"
				BoneRigArray[24] = "left_ring_02"
				BoneRigArray[25] = "left_ring_03"
				BoneRigArray[26] = "left_pinky_01"
				BoneRigArray[27] = "left_pinky_02"
				BoneRigArray[28] = "left_pinky_03"
				BoneRigArray[29] = "left_attach_off"
				BoneRigArray[30] = "left_attach_on"
				BoneRigArray[31] = "left_hand_roll"
				BoneRigArray[32] = "left_arm_02_sub"
				BoneRigArray[33] = "left_arm_02_roll"
				BoneRigArray[34] = "left_arm_01_roll"
				BoneRigArray[35] = "right_shoulder"
				BoneRigArray[36] = "right_arm_width"
				BoneRigArray[37] = "right_arm_01"
				BoneRigArray[38] = "right_arm_02"
				BoneRigArray[39] = "right_hand"
				BoneRigArray[40] = "right_thumb_01"
				BoneRigArray[41] = "right_thumb_02"
				BoneRigArray[42] = "right_thumb_03"
				BoneRigArray[43] = "right_index_01"
				BoneRigArray[44] = "right_index_02"
				BoneRigArray[45] = "right_index_03"
				BoneRigArray[46] = "right_middle_01"
				BoneRigArray[47] = "right_middle_02"
				BoneRigArray[48] = "right_middle_03"
				BoneRigArray[49] = "right_ring_01"
				BoneRigArray[50] = "right_ring_02"
				BoneRigArray[51] = "right_ring_03"
				BoneRigArray[52] = "right_pinky_01"
				BoneRigArray[53] = "right_pinky_02"
				BoneRigArray[54] = "right_pinky_03"
				BoneRigArray[55] = "right_attach_off"
				BoneRigArray[56] = "right_attach_on"
				BoneRigArray[57] = "right_hand_roll"
				BoneRigArray[58] = "right_arm_02_sub"
				BoneRigArray[59] = "right_arm_02_roll"
				BoneRigArray[60] = "right_arm_01_roll"
				BoneRigArray[61] = "hips"
				BoneRigArray[62] = "leg_width"
				BoneRigArray[63] = "left_leg_01"
				BoneRigArray[64] = "left_leg_02"
				BoneRigArray[65] = "left_foot"
				BoneRigArray[66] = "left_toe"
				BoneRigArray[67] = "left_leg_02_sub"
				BoneRigArray[68] = "right_leg_01"
				BoneRigArray[69] = "right_leg_02"
				BoneRigArray[70] = "right_foot"
				BoneRigArray[71] = "right_toe"
				BoneRigArray[72] = "right_leg_02_sub"
				-- IDs from 73 to 92 are assigned to the hair models (p0_hrs*).
				-- The names for these are irrelevant as outfits never use 'em, but they need to be filled in to prevent errors.
				BoneRigArray[73] = ""
				BoneRigArray[74] = ""
				BoneRigArray[75] = ""
				BoneRigArray[76] = ""
				BoneRigArray[77] = ""
				BoneRigArray[78] = ""
				BoneRigArray[79] = ""
				BoneRigArray[80] = ""
				BoneRigArray[81] = ""
				BoneRigArray[82] = ""
				BoneRigArray[83] = ""
				BoneRigArray[84] = ""
				BoneRigArray[85] = ""
				BoneRigArray[86] = ""
				BoneRigArray[87] = ""
				BoneRigArray[88] = ""
				BoneRigArray[89] = ""
				BoneRigArray[90] = ""
				BoneRigArray[91] = ""
				BoneRigArray[92] = ""
				-- IDs from 93 to 104 are assigned to the face skeleton file (p0_face0000_heroine).
				-- We don't *have* to fill these in since nothing links directly to it unlike in Legends: Arceus, but I'm doing so anyway because I can.
				BoneRigArray[93] = "root_face"
				BoneRigArray[94] = "eyescale"
				BoneRigArray[95] = "left_eyeball_segoff"
				BoneRigArray[96] = "left_pupil_01"
				BoneRigArray[97] = "left_pupil_02"
				BoneRigArray[98] = "left_eyehilight_01"
				BoneRigArray[99] = "left_eyehilight_02"
				BoneRigArray[100] = "right_eyeball_segoff"
				BoneRigArray[101] = "right_pupil_01"
				BoneRigArray[102] = "right_pupil_02"
				BoneRigArray[103] = "right_eyehilight_01"
				BoneRigArray[104] = "right_eyehilight_02"
				-- IDs from 105 to 114 are assigned to the bags (p0_bag*), and are different on a model-by-model basis just like the hair is.
				BoneRigArray[105] = ""
				BoneRigArray[106] = ""
				BoneRigArray[107] = ""
				BoneRigArray[108] = ""
				BoneRigArray[109] = ""
				BoneRigArray[110] = ""
				BoneRigArray[111] = ""
				BoneRigArray[112] = ""
				BoneRigArray[113] = ""
				BoneRigArray[114] = ""
				-- IDs from 105 to 114 are assigned to the outfits (p1_drs0000_uniform and p2_drs0000_uniform), and are also different just like everything above.
				BoneRigArray[115] = ""
				BoneRigArray[116] = ""
				BoneRigArray[117] = ""
				BoneRigArray[118] = ""
				BoneRigArray[119] = ""
				BoneRigArray[120] = ""
				BoneRigArray[121] = ""
				BoneRigArray[122] = ""
				BoneRigArray[123] = ""
				BoneRigArray[124] = ""
				-- IDs from 125 and so on are assigned to the headwear (p0_hdw0000_default and p0_hdw0013_porkpie), and... if you're reading up to there, you should already know what I'm gonna say.
				-- We don't need placeholders for these, as they're filled in as necessary by the hats themselves.
			)
			"Rei":(
				-- IDs from 1 to 74 are assigned to the base skeleton file, Rei and Akari both use the exact same skeleton file (p2_base0001_00_default).
				BoneRigArray[1] = "foot_base"
				BoneRigArray[2] = "waist"
				BoneRigArray[3] = "spine_01"
				BoneRigArray[4] = "spine_02"
				BoneRigArray[5] = "spine_03"
				BoneRigArray[6] = "neck"
				BoneRigArray[7] = "look"
				BoneRigArray[8] = "head"
				BoneRigArray[9] = "left_shoulder"
				BoneRigArray[10] = "left_arm_width"
				BoneRigArray[11] = "left_arm_01"
				BoneRigArray[12] = "left_arm_02"
				BoneRigArray[13] = "left_hand"
				BoneRigArray[14] = "left_thumb_01"
				BoneRigArray[15] = "left_thumb_02"
				BoneRigArray[16] = "left_thumb_03"
				BoneRigArray[17] = "left_index_01"
				BoneRigArray[18] = "left_index_02"
				BoneRigArray[19] = "left_index_03"
				BoneRigArray[20] = "left_middle_01"
				BoneRigArray[21] = "left_middle_02"
				BoneRigArray[22] = "left_middle_03"
				BoneRigArray[23] = "left_ring_01"
				BoneRigArray[24] = "left_ring_02"
				BoneRigArray[25] = "left_ring_03"
				BoneRigArray[26] = "left_pinky_01"
				BoneRigArray[27] = "left_pinky_02"
				BoneRigArray[28] = "left_pinky_03"
				BoneRigArray[29] = "left_attach_off"
				BoneRigArray[30] = "left_attach_on"
				BoneRigArray[31] = "left_hand_roll"
				BoneRigArray[32] = "left_arm_02_sub"
				BoneRigArray[33] = "left_arm_02_roll"
				BoneRigArray[34] = "left_arm_01_roll"
				BoneRigArray[35] = "right_shoulder"
				BoneRigArray[36] = "right_arm_width"
				BoneRigArray[37] = "right_arm_01"
				BoneRigArray[38] = "right_arm_02"
				BoneRigArray[39] = "right_hand"
				BoneRigArray[40] = "right_thumb_01"
				BoneRigArray[41] = "right_thumb_02"
				BoneRigArray[42] = "right_thumb_03"
				BoneRigArray[43] = "right_index_01"
				BoneRigArray[44] = "right_index_02"
				BoneRigArray[45] = "right_index_03"
				BoneRigArray[46] = "right_middle_01"
				BoneRigArray[47] = "right_middle_02"
				BoneRigArray[48] = "right_middle_03"
				BoneRigArray[49] = "right_ring_01"
				BoneRigArray[50] = "right_ring_02"
				BoneRigArray[51] = "right_ring_03"
				BoneRigArray[52] = "right_pinky_01"
				BoneRigArray[53] = "right_pinky_02"
				BoneRigArray[54] = "right_pinky_03"
				BoneRigArray[55] = "right_attach_off"
				BoneRigArray[56] = "right_attach_on"
				BoneRigArray[57] = "right_hand_roll"
				BoneRigArray[58] = "right_arm_02_sub"
				BoneRigArray[59] = "right_arm_02_roll"
				BoneRigArray[60] = "right_arm_01_roll"
				BoneRigArray[61] = "bag"
				BoneRigArray[62] = "bag_a"
				BoneRigArray[63] = "hips"
				BoneRigArray[64] = "leg_width"
				BoneRigArray[65] = "left_leg_01"
				BoneRigArray[66] = "left_leg_02"
				BoneRigArray[67] = "left_foot"
				BoneRigArray[68] = "left_toe"
				BoneRigArray[69] = "left_leg_02_sub"
				BoneRigArray[70] = "right_leg_01"
				BoneRigArray[71] = "right_leg_02"
				BoneRigArray[72] = "right_foot"
				BoneRigArray[73] = "right_toe"
				BoneRigArray[74] = "right_leg_02_sub"
				-- IDs from 75 to 125 are assigned to the face skeleton file (p1_face0001_00_default). Rei has a few less face bones compared to Akari, and requires placeholders because of which.
				BoneRigArray[75] = "lower_head"
				BoneRigArray[76] = "upper_jaw"
				BoneRigArray[77] = "upper_lip"
				BoneRigArray[78] = "left_upper_lip_a"
				BoneRigArray[79] = "right_upper_lip_a"
				BoneRigArray[80] = "upper_teeth"
				BoneRigArray[81] = "lower_jaw"
				BoneRigArray[82] = "lower_lip"
				BoneRigArray[83] = "left_lower_lip_a"
				BoneRigArray[84] = "right_lower_lip_a"
				BoneRigArray[85] = "lower_teeth"
				BoneRigArray[86] = "tongue"
				BoneRigArray[87] = "left_side_lip"
				BoneRigArray[88] = "right_side_lip"
				BoneRigArray[89] = "upper_head"
				BoneRigArray[90] = "left_root_eyeball"
				BoneRigArray[91] = "left_eyeball"
				BoneRigArray[92] = "left_eyehilight"
				BoneRigArray[93] = "left_upper_eyelid_a"
				BoneRigArray[94] = "left_upper_eyelid_b"
				BoneRigArray[95] = "left_upper_eyelid_c"
				BoneRigArray[96] = "left_lower_eyelid_a"
				BoneRigArray[97] = "left_lower_eyelid_b"
				BoneRigArray[98] = "left_lower_eyelid_c"
				BoneRigArray[99] = "left_side_eyelid_a"
				BoneRigArray[100] = "left_side_eyelid_b"
				BoneRigArray[101] = "right_root_eyeball"
				BoneRigArray[102] = "right_eyeball"
				BoneRigArray[103] = "right_eyehilight"
				BoneRigArray[104] = "right_upper_eyelid_a"
				BoneRigArray[105] = "right_upper_eyelid_b"
				BoneRigArray[106] = "right_upper_eyelid_c"
				BoneRigArray[107] = "right_lower_eyelid_a"
				BoneRigArray[108] = "right_lower_eyelid_b"
				BoneRigArray[109] = "right_lower_eyelid_c"
				BoneRigArray[110] = "right_side_eyelid_a"
				BoneRigArray[111] = "right_side_eyelid_b"
				BoneRigArray[112] = "left_eyebrow_a"
				BoneRigArray[113] = "left_eyebrow_b"
				BoneRigArray[114] = "left_eyebrow_c"
				BoneRigArray[115] = "left_eyebrow_d"
				BoneRigArray[116] = "right_eyebrow_a"
				BoneRigArray[117] = "right_eyebrow_b"
				BoneRigArray[118] = "right_eyebrow_c"
				BoneRigArray[119] = "right_eyebrow_d"
				BoneRigArray[120] = ""
				BoneRigArray[121] = ""
				BoneRigArray[122] = ""
				BoneRigArray[123] = ""
				BoneRigArray[124] = ""
				BoneRigArray[125] = ""
				-- IDs from 126 to 147 are assigned to the hair skeleton file, and are different on a model-by-model basis.
				-- The names for these are irrelevant as outfits never use 'em, but they need to be filled in to prevent errors.
				BoneRigArray[126] = ""
				BoneRigArray[127] = ""
				BoneRigArray[128] = ""
				BoneRigArray[129] = ""
				BoneRigArray[130] = ""
				BoneRigArray[131] = ""
				BoneRigArray[132] = ""
				BoneRigArray[133] = ""
				BoneRigArray[134] = ""
				BoneRigArray[135] = ""
				BoneRigArray[136] = ""
				BoneRigArray[137] = ""
				BoneRigArray[138] = ""
				BoneRigArray[139] = ""
				BoneRigArray[140] = ""
				BoneRigArray[141] = ""
				BoneRigArray[142] = ""
				BoneRigArray[143] = ""
				BoneRigArray[144] = ""
				BoneRigArray[145] = ""
				BoneRigArray[146] = ""
				BoneRigArray[147] = ""
				-- IDs from 148 and so on are assigned to the outfit skeleton file(s), and are also different depending on the respective model.
				-- We don't need placeholders for these, as they're filled in as necessary by the outfits themselves.
			)
			"Akari":(
				-- IDs from 1 to 74 are assigned to the base skeleton file, Rei and Akari both use the exact same skeleton file (p2_base0001_00_default).
				BoneRigArray[1] = "foot_base"
				BoneRigArray[2] = "waist"
				BoneRigArray[3] = "spine_01"
				BoneRigArray[4] = "spine_02"
				BoneRigArray[5] = "spine_03"
				BoneRigArray[6] = "neck"
				BoneRigArray[7] = "look"
				BoneRigArray[8] = "head"
				BoneRigArray[9] = "left_shoulder"
				BoneRigArray[10] = "left_arm_width"
				BoneRigArray[11] = "left_arm_01"
				BoneRigArray[12] = "left_arm_02"
				BoneRigArray[13] = "left_hand"
				BoneRigArray[14] = "left_thumb_01"
				BoneRigArray[15] = "left_thumb_02"
				BoneRigArray[16] = "left_thumb_03"
				BoneRigArray[17] = "left_index_01"
				BoneRigArray[18] = "left_index_02"
				BoneRigArray[19] = "left_index_03"
				BoneRigArray[20] = "left_middle_01"
				BoneRigArray[21] = "left_middle_02"
				BoneRigArray[22] = "left_middle_03"
				BoneRigArray[23] = "left_ring_01"
				BoneRigArray[24] = "left_ring_02"
				BoneRigArray[25] = "left_ring_03"
				BoneRigArray[26] = "left_pinky_01"
				BoneRigArray[27] = "left_pinky_02"
				BoneRigArray[28] = "left_pinky_03"
				BoneRigArray[29] = "left_attach_off"
				BoneRigArray[30] = "left_attach_on"
				BoneRigArray[31] = "left_hand_roll"
				BoneRigArray[32] = "left_arm_02_sub"
				BoneRigArray[33] = "left_arm_02_roll"
				BoneRigArray[34] = "left_arm_01_roll"
				BoneRigArray[35] = "right_shoulder"
				BoneRigArray[36] = "right_arm_width"
				BoneRigArray[37] = "right_arm_01"
				BoneRigArray[38] = "right_arm_02"
				BoneRigArray[39] = "right_hand"
				BoneRigArray[40] = "right_thumb_01"
				BoneRigArray[41] = "right_thumb_02"
				BoneRigArray[42] = "right_thumb_03"
				BoneRigArray[43] = "right_index_01"
				BoneRigArray[44] = "right_index_02"
				BoneRigArray[45] = "right_index_03"
				BoneRigArray[46] = "right_middle_01"
				BoneRigArray[47] = "right_middle_02"
				BoneRigArray[48] = "right_middle_03"
				BoneRigArray[49] = "right_ring_01"
				BoneRigArray[50] = "right_ring_02"
				BoneRigArray[51] = "right_ring_03"
				BoneRigArray[52] = "right_pinky_01"
				BoneRigArray[53] = "right_pinky_02"
				BoneRigArray[54] = "right_pinky_03"
				BoneRigArray[55] = "right_attach_off"
				BoneRigArray[56] = "right_attach_on"
				BoneRigArray[57] = "right_hand_roll"
				BoneRigArray[58] = "right_arm_02_sub"
				BoneRigArray[59] = "right_arm_02_roll"
				BoneRigArray[60] = "right_arm_01_roll"
				BoneRigArray[61] = "bag"
				BoneRigArray[62] = "bag_a"
				BoneRigArray[63] = "hips"
				BoneRigArray[64] = "leg_width"
				BoneRigArray[65] = "left_leg_01"
				BoneRigArray[66] = "left_leg_02"
				BoneRigArray[67] = "left_foot"
				BoneRigArray[68] = "left_toe"
				BoneRigArray[69] = "left_leg_02_sub"
				BoneRigArray[70] = "right_leg_01"
				BoneRigArray[71] = "right_leg_02"
				BoneRigArray[72] = "right_foot"
				BoneRigArray[73] = "right_toe"
				BoneRigArray[74] = "right_leg_02_sub"
				-- IDs from 75 to 125 are assigned to the face skeleton file (p2_face0001_00_default). Akari has a few extra face bones compared to Rei, for her eyelashes.
				BoneRigArray[75] = "lower_head"
				BoneRigArray[76] = "upper_jaw"
				BoneRigArray[77] = "upper_lip"
				BoneRigArray[78] = "left_upper_lip_a"
				BoneRigArray[79] = "right_upper_lip_a"
				BoneRigArray[80] = "upper_teeth"
				BoneRigArray[81] = "lower_jaw"
				BoneRigArray[82] = "lower_lip"
				BoneRigArray[83] = "left_lower_lip_a"
				BoneRigArray[84] = "right_lower_lip_a"
				BoneRigArray[85] = "lower_teeth"
				BoneRigArray[86] = "tongue"
				BoneRigArray[87] = "left_side_lip"
				BoneRigArray[88] = "right_side_lip"
				BoneRigArray[89] = "upper_head"
				BoneRigArray[90] = "left_root_eyeball"
				BoneRigArray[91] = "left_eyeball"
				BoneRigArray[92] = "left_eyehilight"
				BoneRigArray[93] = "left_upper_eyelid_a"
				BoneRigArray[94] = "left_eyelash_a"
				BoneRigArray[95] = "left_eyelash_b"
				BoneRigArray[96] = "left_upper_eyelid_b"
				BoneRigArray[97] = "left_eyelash_c"
				BoneRigArray[98] = "left_upper_eyelid_c"
				BoneRigArray[99] = "left_lower_eyelid_a"
				BoneRigArray[100] = "left_lower_eyelid_b"
				BoneRigArray[101] = "left_lower_eyelid_c"
				BoneRigArray[102] = "left_side_eyelid_a"
				BoneRigArray[103] = "left_side_eyelid_b"
				BoneRigArray[104] = "right_root_eyeball"
				BoneRigArray[105] = "right_eyeball"
				BoneRigArray[106] = "right_eyehilight"
				BoneRigArray[107] = "right_upper_eyelid_a"
				BoneRigArray[108] = "right_eyelash_a"
				BoneRigArray[109] = "right_eyelash_b"
				BoneRigArray[110] = "right_upper_eyelid_b"
				BoneRigArray[111] = "right_eyelash_c"
				BoneRigArray[112] = "right_upper_eyelid_c"
				BoneRigArray[113] = "right_lower_eyelid_a"
				BoneRigArray[114] = "right_lower_eyelid_b"
				BoneRigArray[115] = "right_lower_eyelid_c"
				BoneRigArray[116] = "right_side_eyelid_a"
				BoneRigArray[117] = "right_side_eyelid_b"
				BoneRigArray[118] = "left_eyebrow_a"
				BoneRigArray[119] = "left_eyebrow_b"
				BoneRigArray[120] = "left_eyebrow_c"
				BoneRigArray[121] = "left_eyebrow_d"
				BoneRigArray[122] = "right_eyebrow_a"
				BoneRigArray[123] = "right_eyebrow_b"
				BoneRigArray[124] = "right_eyebrow_c"
				BoneRigArray[125] = "right_eyebrow_d"
				-- IDs from 126 to 147 are assigned to the hair skeleton file, and are different on a model-by-model basis.
				-- The names for these are irrelevant as outfits never use 'em, but they need to be filled in to prevent errors.
				BoneRigArray[126] = ""
				BoneRigArray[127] = ""
				BoneRigArray[128] = ""
				BoneRigArray[129] = ""
				BoneRigArray[130] = ""
				BoneRigArray[131] = ""
				BoneRigArray[132] = ""
				BoneRigArray[133] = ""
				BoneRigArray[134] = ""
				BoneRigArray[135] = ""
				BoneRigArray[136] = ""
				BoneRigArray[137] = ""
				BoneRigArray[138] = ""
				BoneRigArray[139] = ""
				BoneRigArray[140] = ""
				BoneRigArray[141] = ""
				BoneRigArray[142] = ""
				BoneRigArray[143] = ""
				BoneRigArray[144] = ""
				BoneRigArray[145] = ""
				BoneRigArray[146] = ""
				BoneRigArray[147] = ""
				-- IDs from 148 and so on are assigned to the outfit skeleton file(s), and are also different depending on the respective model.
				-- We don't need placeholders for these, as they're filled in as necessary by the outfits themselves.
			)
		)
	)

	on btnImportGFBMDL pressed do (
		fname = getOpenFileName \ 
		caption:"Nintendo Switch Pokémon Model File" \
		types:"Nintendo Switch Pokémon LGPE / SwSh Model File (*.gfbmdl)|*.gfbmdl" \
		historyCategory:"GFBMDLPresets"
		if fname != undefined do (
			f = fopen fname "rb"
			p = getFilenamePath fname
			g = getFilenameFile fname
			clearlistener()
			st = timestamp()

			struct Bone_Info_Struct (Bone1, Bone2, Bone3, Bone4)
			struct Weight_Info_Struct (Weight1, Weight2, Weight3, Weight4)
			struct weight_data (boneids, weights)
			struct MatData_Struct (MatName, MatCol0, MatUVScaleU, MatUVScaleV, MatUVTrsU, MatUVTrsV, MatUVRot, MatUVScale2U, MatUVScale2V, MatUVTrs2U, MatUVTrs2V, MatUVRot2)

			local VertColors = tglVertColors.state
			BoneArray = #()
			BoneRigArray = #()
			BoneName_array = #()
			VisGroupBone_array = #()
			MatStringArray = #()
			TexStringArray = #()
			MatData_array = #()

			fseek f 0x04 #seek_set
			SwShCheck = readshort f #unsigned
			if SwShCheck == 0x00 then (fseek f 0x28 #seek_set)
			else (fseek f 0x2C #seek_set)
			TexNameDataOffset = (ftell f) + readlong f
			MatNameDataOffset = (ftell f) + readlong f
			Unk2DataOffset = (ftell f) + readlong f
			Unk1DataOffset = (ftell f) + readlong f
			ShaderDataOffset = (ftell f) + readlong f
			VisGroupDataOffset = (ftell f) + readlong f
			VertDataOffset = (ftell f) + readlong f
			BoneDataOffset = (ftell f) + readlong f
			printDebug ("Unknown1 (materials) offset: " + Unk1DataOffset as string)
			printDebug ("Unknown2 (blank?) offset: " + Unk2DataOffset as string)

			fseek f MatNameDataOffset #seek_set
			MatNameCount = readlong f
			for m = 1 to MatNameCount do (
				MatNameOffset = (ftell f) + readlong f
				MatRet = (ftell f)
				fseek f MatNameOffset #seek_set
				MatNameLength = readlong f
				MatName = readstring f
				append MatStringArray MatName
				fseek f MatRet #seek_set
			)

			printDebug ("--------------------")
			printDebug ("Material names:")
			printDebug (MatStringArray)
			printDebug ("--------------------")
			
			fseek f TexNameDataOffset #seek_set
			TexNameCount = readlong f
			for t = 1 to TexNameCount do (
				TexNameOffset = (ftell f) + readlong f
				TexRet = (ftell f)
				fseek f TexNameOffset #seek_set
				TexNameLength = readlong f
				TexName = readstring f
				append TexStringArray TexName
				fseek f TexRet #seek_set
			)
			printDebug ("Texture names:")
			printDebug (TexStringArray)
			printDebug ("--------------------")

			fseek f BoneDataOffset #seek_set
			BoneCount = readlong f

			for b = 1 to BoneCount do (
				BoneOffset = (ftell f) + readlong f
				BoneRet = (ftell f)
				fseek f BoneOffset #seek_set
				printDebug ("Bone " + b as string + " start: " + BoneOffset as string)
				BoneInfoOffset = (ftell f) - readlong f
				fseek f BoneInfoOffset #seek_set
				
				BoneInfoLength = readshort f #unsigned
				BoneStringStart = readshort f #unsigned
				BoneUnk2Start = readshort f #unsigned
				BoneUnk1Start = readshort f #unsigned
				BoneParentStart = readshort f #unsigned
				BoneBlank3Start = readshort f #unsigned
				BoneByteStart = readshort f #unsigned
				BoneSclStart = readshort f #unsigned
				BoneRotStart = readshort f #unsigned
				BoneTrsStart = readshort f #unsigned
				BoneRigFlag2 = readshort f #unsigned -- 16 =  "rigged", 20 = "unrigged"
				BoneRigFlag1 = readshort f #unsigned -- 4 = "rigged", 8 = "unrigged"

				fseek f (BoneOffset + BoneTrsStart) #seek_set
				BoneTX = readfloat f; BoneTY = readfloat f; BoneTZ = readfloat f
				fseek f (BoneOffset + BoneRotStart) #seek_set
				BoneRX = readfloat f; BoneRY = readfloat f; BoneRZ = readfloat f
				fseek f (BoneOffset + BoneSclStart) #seek_set
				BoneSX = readfloat f; BoneSY = readfloat f; BoneSZ = readfloat f
				
				if BoneParentStart != 0x00 then (
					fseek f (BoneOffset + BoneParentStart) #seek_set
					BoneParent = readlong f + 1
					) else (
					BoneParent = 1
				)
				fseek f (BoneOffset + BoneStringStart) #seek_set
				BoneStrLen = readlong f
				BoneName = readstring f
				if BoneRigFlag1 == 4 do (append BoneRigArray BoneName)
				append BoneName_array BoneName

			tfm = scaleMatrix [BoneSX,BoneSY,BoneSZ]
			tfm = tfm * (rotateXMatrix (radToDeg BoneRX)) * (rotateYMatrix (radToDeg BoneRY)) * (rotateZMatrix (radToDeg BoneRZ))
			tfm.row4 = [BoneTX, BoneTY, BoneTZ]

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
							newBone.name = BoneName
							newBone.width  = 0.01
							newBone.height = 0.01
							newBone.transform = tfm
							newBone.wirecolor = yellow
							newbone.showlinks = true
							newBone.setBoneEnable false 0
							newBone.pos.controller      = TCB_position ()
							newBone.rotation.controller = TCB_rotation ()
				if (BoneParent != 0) then
				newBone.parent = BoneArray[(BoneParent)]
				append BoneArray newBone

				fseek f BoneRet #seek_set
			)

			fseek f VisGroupDataOffset #seek_set
			VisGroupCount = readlong f
			for v = 1 to VisGroupCount do (
				VisGroupOffset = (ftell f) + readlong f
				VisGroupRet = (ftell f)
				fseek f VisGroupOffset #seek_set
				printDebug ("VisGroup " + v as string + " start: " + (ftell f) as string)
				VisPtr = (ftell f) - readlong f
				fseek f VisPtr #seek_set
				VisGroupHeadLen = readshort f #unsigned
				case VisGroupHeadLen of (
					default:(throw ("Unknown header length!"))
					0x000A:(
						VisGroupUnk1Ptr = readshort f #unsigned
						VisGroupVisBonePtr = readshort f #unsigned
						VisGroupUnk2Ptr = readshort f #unsigned
						VisGroupBoundPtr = readshort f #unsigned
						VisGroupUnk3Ptr = 0
					)
					0x000C:(
						VisGroupUnk1Ptr = readshort f #unsigned
						VisGroupVisBonePtr = readshort f #unsigned
						VisGroupUnk2Ptr = readshort f #unsigned
						VisGroupBoundPtr = readshort f #unsigned
						VisGroupUnk3Ptr = readshort f #unsigned
					)
				)
				fseek f (VisGroupOffset + VisGroupBoundPtr) #seek_set
				VisBoundMinX = readfloat f
				VisBoundMinY = readfloat f
				VisBoundMinZ = readfloat f
				VisBoundMaxX = readfloat f
				VisBoundMaxY = readfloat f
				VisBoundMaxZ = readfloat f
				fseek f (VisGroupOffset + VisGroupVisBonePtr) #seek_set
				VisBoneName = readlong f + 1
				fseek f (VisGroupOffset + VisGroupUnk2Ptr) #seek_set
				VisBoneUnk = readlong f + 1
				append VisGroupBone_array BoneName_array[VisBoneName]
				printDebug ("VisGroup " + v as string + " end: " + (ftell f) as string)
				fseek f VisGroupRet #seek_set
			)

			fseek f ShaderDataOffset #seek_set
			MatShadCount = readlong f
			for x = 1 to MatShadCount do (
				MatCol0 = "null"; MatUVScaleU = 1.0; MatUVScaleV = 1.0; MatUVTrsU = 0; MatUVTrsV = 0; MatUVRot = 0; MatUVScale2U = 1.0; MatUVScale2V = 1.0; MatUVTrs2U = 0; MatUVTrs2V = 0; MatUVRot2 = 0
				MatShadOffset = (ftell f) + readlong f
				MatRet = (ftell f)
				fseek f MatShadOffset #seek_set
				MatShadPropOff = (ftell f) - readlong f
				fseek f MatShadPropOff #seek_set
				MatShadPropHeadLen = readshort f #unsigned
				MatShadPropProp = readshort f #unsigned
				MatShadPropMatString = readshort f #unsigned
				MatShadPropShadString = readshort f #unsigned
				MatShadPropUnk1 = readshort f #unsigned -- always 0?
				MatShadPropUnk2 = readshort f #unsigned
				MatShadPropUnk3 = readshort f #unsigned
				MatShadPropParam1 = readshort f #unsigned
				MatShadPropParam2 = readshort f #unsigned
				MatShadPropParam3 = readshort f #unsigned
				MatShadPropParam4 = readshort f #unsigned
				MatShadPropParam5 = readshort f #unsigned
				MatShadPropParam6 = readshort f #unsigned
				MatShadPropTexList = readshort f #unsigned
				MatShadPropParamA = readshort f #unsigned
				MatShadPropParamB = readshort f #unsigned
				MatShadPropParamC = readshort f #unsigned
				MatShadPropUnk4 = readshort f #unsigned
				MatShadPropUnk5 = readshort f #unsigned
				MatShadPropUnk6 = readshort f #unsigned -- always 0?
				MatShadPropUnk7 = readshort f #unsigned
				MatShadPropUnk8 = readshort f #unsigned -- always 0?
				MatShadPropPointer = readshort f #unsigned

				fseek f (MatShadOffset + MatShadPropMatString) #seek_set
				MatShadStringPtr = (ftell f) + readlong f
				fseek f MatShadStringPtr #seek_set
				MatShadMatStringLen = readlong f
				MatShadMatString = readstring f

				print ("Textures used for " + MatShadMatString as string + ":")
				fseek f (MatShadOffset + MatShadPropTexList) #seek_set
				MatTexPtr = (ftell f) + readlong f
				fseek f MatTexPtr #seek_set
				MatTexCount = readlong f
				for y = 1 to MatTexCount do (
					MatTexOffset = (ftell f) + readlong f
					MatTexRet = (ftell f)
					fseek f MatTexOffset #seek_set
					MatTexLytPtr = (ftell f) - readlong f
					fseek f MatTexLytPtr #seek_set
					MatTexLytHeadLen = readshort f #unsigned
					case MatTexLytHeadLen of (
						default: (throw ("Unknown header length!"))
						0x0A:(
						MatTexLytStrPtr = readshort f #unsigned
						MatTexLytHdrPtr = readshort f #unsigned
						MatTexLytIDPtr = readshort f #unsigned
						MatTexLytUnkPtr = readshort f #unsigned
						)
					)
					fseek f (MatTexOffset + MatTexLytStrPtr) #seek_set
					MatTexStrLen = readlong f
					MatTexString = readstring f
					if MatTexLytIDPtr != 0 then (
					fseek f (MatTexOffset + MatTexLytIDPtr) #seek_set
					MatTexID = TexStringArray[readlong f + 1]
					) else (MatTexID = TexStringArray[1])
					print (MatTexString as string + ": " + MatTexID as string)
					fseek f MatTexRet #seek_set
					if MatTexString == "Col0Tex" or MatTexString == "L0ColTex" or MatTexString == "Texture01" or MatTexString == "TextureMap01" do (MatCol0 = MatTexID)
				)
				printMat("--------------------")

				printMat ("Material properties for " + MatShadMatString as string + ":")
				fseek f (MatShadOffset + MatShadPropParamA) #seek_set
				MatPropAPtr = (ftell f) + readlong f
				fseek f MatPropAPtr #seek_set
				MatPropACount = readlong f
				for y = 1 to MatPropACount do (
					MatPropAStart = (ftell f) + readlong f
					MatPropRet = (ftell f)
					fseek f MatPropAStart #seek_set
					MatPropAPropPtr = (ftell f) - readlong f
					fseek f MatPropAPropPtr #seek_set
					MatPropAHeadLen = readshort f #unsigned
					case MatPropAHeadLen of (
						default:(throw ("Unknown header length!"))
						0x06:(
							MatPropAStringPtr = readshort f #unsigned
							MatPropAFmtPtr = readshort f #unsigned
							MatPropAVarPtr = 0
						)
						0x08:(
							MatPropAStringPtr = readshort f #unsigned
							MatPropAFmtPtr = readshort f #unsigned
							MatPropAVarPtr = readshort f #unsigned
						)
					)
					fseek f (MatPropAStart + MatPropAStringPtr) #seek_set
					MatPropAStrLen = readlong f
					MatPropAString = readstring f
					fseek f (MatPropAStart + MatPropAFmtPtr) #seek_set
					MatPropAFmt = readlong f
					if MatPropAVarPtr != 0 then (
					fseek f (MatPropAStart + MatPropAVarPtr) #seek_set
						case MatPropAFmt of (
							default:(throw ("Unknown format!"))
							4:(MatPropAVar = readbyte f #unsigned; if MatPropAVar == 1 do (MatPropAVar = "True"))
						)
					) else (MatPropAVar = "False")
					printMat (MatPropAString as string + ": " + MatPropAVar as string)
					
					fseek f MatPropRet #seek_set
				)
				fseek f (MatShadOffset + MatShadPropParamB) #seek_set
				MatPropBPtr = (ftell f) + readlong f
				fseek f MatPropBPtr #seek_set
				MatPropBCount = readlong f
				for y = 1 to MatPropBCount do (
					MatPropBStart = (ftell f) + readlong f
					MatPropRet = (ftell f)
					fseek f MatPropBStart #seek_set
					MatPropBPropPtr = (ftell f) - readlong f
					fseek f MatPropBPropPtr #seek_set
					MatPropBHeadLen = readshort f #unsigned
					case MatPropBHeadLen of (
						default:(throw ("Unknown header length!"))
						0x06:(
							MatPropBStringPtr = readshort f #unsigned
							MatPropBFmtPtr = readshort f #unsigned
							MatPropBVarPtr = 0
						)
						0x08:(
							MatPropBStringPtr = readshort f #unsigned
							MatPropBFmtPtr = readshort f #unsigned
							MatPropBVarPtr = readshort f #unsigned
						)
					)					
					fseek f (MatPropBStart + MatPropBStringPtr) #seek_set
					MatPropBStrLen = readlong f
					MatPropBString = readstring f
					if MatPropBFmtPtr != 0 do (
					fseek f (MatPropBStart + MatPropBFmtPtr) #seek_set
					MatPropBFmt = readlong f
					)
					fseek f (MatPropBStart + MatPropBVarPtr) #seek_set
					if MatPropBVarPtr != 0 then (
						case MatPropBFmt of (
							default:(throw ("Unknown format!"))
							4:(MatPropBVar = readlong f)
							8:(MatPropBVar = readfloat f)
						)
					) else (MatPropBVar = 0)
					printMat (MatPropBString as string + ": " + MatPropBVar as string)
					case MatPropBString of (
						"ColorUVScaleU":(MatUVScaleU = MatPropBVar)
						"ColorUVScaleV":(MatUVScaleV = MatPropBVar)
						"ColorUVTranslateU":(MatUVTrsU = MatPropBVar)
						"ColorUVTranslateV":(MatUVTrsV = MatPropBVar)
						"Layer1UVScaleU":(MatUVScale2U = MatPropBVar)
						"Layer1UVScaleV":(MatUVScale2V = MatPropBVar)
						"Layer1UVTranslateU":(MatUVTrs2U = MatPropBVar)
						"Layer1UVTranslateV":(MatUVTrs2V = MatPropBVar)
						"L0ScaleU":(MatUVScaleU = MatPropBVar)
						"L0ScaleV":(MatUVScaleV = MatPropBVar)
						"L0UVTranslateU":(MatUVTrsU = MatPropBVar)
						"L0UVTranslateV":(MatUVTrsV = MatPropBVar)
						"L1ScaleU":(MatUVScale2U = MatPropBVar)
						"L1ScaleV":(MatUVScale2V = MatPropBVar)
						"L1UVTranslateU":(MatUVTrs2U = MatPropBVar)
						"L1UVTranslateV":(MatUVTrs2V = MatPropBVar)
						"Tex01_Scale_U":(MatUVScaleU = MatPropBVar)
						"Tex01_Scale_V":(MatUVScaleV = MatPropBVar)
						"Tex01_Translate_U":(MatUVTrsU = MatPropBVar)
						"Tex01_Translate_V":(MatUVTrsV = MatPropBVar)
						"Tex01_Rotate":(MatUVRot = MatPropBVar)
						"Tex02_Scale_U":(MatUVScale2U = MatPropBVar)
						"Tex02_Scale_V":(MatUVScale2V = MatPropBVar)
						"Tex02_Translate_U":(MatUVTrs2U = MatPropBVar)
						"Tex02_Translate_V":(MatUVTrs2V = MatPropBVar)
						"Tex02_Rotate":(MatUVRot2 = MatPropBVar)
					)
					fseek f MatPropRet #seek_set
				)
				fseek f (MatShadOffset + MatShadPropParamC) #seek_set
				MatPropCPtr = (ftell f) + readlong f
				fseek f MatPropCPtr #seek_set
				MatPropCCount = readlong f
				for y = 1 to MatPropCCount do (
					MatPropCStart = (ftell f) + readlong f
					MatPropRet = (ftell f)
					fseek f MatPropCStart #seek_set
					MatPropCPropPtr = (ftell f) - readlong f
					fseek f MatPropCPropPtr #seek_set
					MatPropCHeadLen = readshort f #unsigned
					case MatPropCHeadLen of (
						default:(throw ("Unknown header length!"))
						0x08:(
							MatPropCStringPtr = readshort f #unsigned
							MatPropCFmtPtr = readshort f #unsigned
							MatPropCVarPtr = readshort f #unsigned
						)
					)
					fseek f (MatPropCStart + MatPropCStringPtr) #seek_set
					MatPropCStrLen = readlong f
					MatPropCString = readstring f
					fseek f (MatPropCStart + MatPropCFmtPtr) #seek_set
					MatPropCFmt = readlong f
					fseek f (MatPropCStart + MatPropCVarPtr) #seek_set
					case MatPropCFmt of (
						default:(throw ("Unknown format!"))
						4:(MatPropCVar1 = readfloat f; MatPropCVar2 = readfloat f; MatPropCVar3 = readfloat f)
						8:(MatPropCVar1 = readlong f; MatPropCVar2 = readlong f; MatPropCVar3 = readlong f)
					)
					printMat (MatPropCString as string + ": " + MatPropCVar1 as string + " | " + MatPropCVar2 as string + " | " + MatPropCVar3 as string)
					
					fseek f MatPropRet #seek_set
				)
				append MatData_array (MatData_Struct MatName:MatShadMatString MatCol0:MatCol0 MatUVScaleU:MatUVScaleU MatUVScaleV:MatUVScaleV MatUVTrsU:MatUVTrsU MatUVTrsV:MatUVTrsV MatUVRot:MatUVRot MatUVScale2U:MatUVScale2U MatUVScale2V:MatUVScale2V MatUVTrs2U:MatUVTrs2U MatUVTrs2V:MatUVTrs2V MatUVRot2:MatUVRot2)
				if MatShadPropUnk1 != 0 do (fseek f (MatShadOffset + MatShadPropUnk1) #seek_set; MatShadPropUnk1 = readbyte f)
				if MatShadPropUnk2 != 0 do (fseek f (MatShadOffset + MatShadPropUnk2) #seek_set; MatShadPropUnk2 = readbyte f)
				if MatShadPropUnk3 != 0 do (fseek f (MatShadOffset + MatShadPropUnk3) #seek_set; MatShadPropUnk3 = readbyte f)
				if MatShadPropParam1 != 0 do (fseek f (MatShadOffset + MatShadPropParam1) #seek_set; MatShadPropParam1 = readlong f)
				if MatShadPropParam2 != 0 do (fseek f (MatShadOffset + MatShadPropParam2) #seek_set; MatShadPropParam2 = readlong f)
				if MatShadPropParam3 != 0 do (fseek f (MatShadOffset + MatShadPropParam3) #seek_set; MatShadPropParam3 = readlong f)
				if MatShadPropParam4 != 0 do (fseek f (MatShadOffset + MatShadPropParam4) #seek_set; MatShadPropParam4 = readlong f)
				if MatShadPropParam5 != 0 do (fseek f (MatShadOffset + MatShadPropParam5) #seek_set; MatShadPropParam5 = readlong f)
				if MatShadPropParam6 != 0 do (fseek f (MatShadOffset + MatShadPropParam6) #seek_set; MatShadPropParam6 = readlong f)
				if MatShadPropUnk4 != 0 do (fseek f (MatShadOffset + MatShadPropUnk4) #seek_set; MatShadPropUnk4 = readbyte f)
				if MatShadPropUnk5 != 0 do (fseek f (MatShadOffset + MatShadPropUnk5) #seek_set; MatShadPropUnk5 = readbyte f)
				if MatShadPropUnk6 != 0 do (fseek f (MatShadOffset + MatShadPropUnk6) #seek_set; MatShadPropUnk6 = readbyte f)
				if MatShadPropUnk7 != 0 do (fseek f (MatShadOffset + MatShadPropUnk7) #seek_set; MatShadPropUnk7 = readbyte f)
				if MatShadPropUnk8 != 0 do (fseek f (MatShadOffset + MatShadPropUnk8) #seek_set; MatShadPropUnk8 = readbyte f)
				printMat ("Unknowns = BoolA: " + MatShadPropUnk1 as string + " | BoolB: " + MatShadPropUnk2 as string + " | BoolC: " + MatShadPropUnk3 as string + " | ValA: " + MatShadPropParam1 as string + " | ValB: " + MatShadPropParam2 as string + " | ValC: " + MatShadPropParam3 as string + " | ValD: " + MatShadPropParam4 as string + " | ValE: " + MatShadPropParam5 as string + " | ValF: " + MatShadPropParam6 as string + " | BoolD: " + MatShadPropUnk4 as string + " | BoolE: " + MatShadPropUnk5 as string + " | BoolF: " + MatShadPropUnk6 as string + " | BoolG: " + MatShadPropUnk7 as string + " | BoolH: " + MatShadPropUnk8 as string)
				fseek f MatRet #seek_set
				print "--------------------"
			)
			print MatData_array

			multimat = MultiMaterial()
			multimat.name = g
			multimat.numsubs = MatNameCount
			for m = 1 to MatNameCount do (
				multimat.materialList[m] = StandardMaterial() -- Forces materials to be in Standard format, as 2021+ assume Physical.
				mat = multimat.materialList[m]
				mat.name = MatData_array[m].MatName as string
				mat.showinviewport = true
				mat.twosided = false
				tm = Bitmaptexture filename:(p + MatData_array[m].MatCol0 + ".png")
				tm.alphasource = 0
				mat.diffuseMap = tm
				mat.opacityMap = tm
				mat.opacityMap.monoOutput = 1
			)

			fseek f VertDataOffset #seek_set
			VertBufferCount = readlong f

			for x = 1 to VertBufferCount do (
				Vert_array = #()
				Normal_array = #()
				Color_array = #()
				Alpha_array = #()
				UV_array = #()
				UV2_array = #()
				UV3_array = #()
				UV4_array = #()
				Face_array = #()
				FaceMatID_array = #()
				B1_array = #()
				W1_array = #()
				Weight_array = #()

				PositionsFmt = "None"; NormalsFmt = "None"; TangentsFmt = "None"
				UVsFmt = "None"; UVs2Fmt = "None"; UVs3Fmt = "None"; UVs4Fmt = "None"
				ColorsFmt = "None"; Colors2Fmt = "None"; BonesFmt = "None"; WeightsFmt = "None"
				BitangentsFmt = "None"
				VertBufferStride = 0

				VertBufferOffset = (ftell f) + readlong f
				VertBufferRet = (ftell f)
				fseek f VertBufferOffset #seek_set
				printDebug ("Vertex group " + x as string + " start: " + ftell f as string)
				VertLytPtr = (ftell f) - readlong f
				fseek f VertLytPtr #seek_set

				VertLytHeadLen = readshort f
				case VertLytHeadLen of (
					default: (throw ("Unknown header length!"))
					0x0A:(
						VertBuffVertPtr = readshort f #unsigned
						VertBuffPolyPtr = readshort f #unsigned
						VertBuffInfoPtr = readshort f #unsigned
						VertBuffUnkPtr = readshort f #unsigned
					)
				)

				VertBuffVertStart = (VertBufferOffset + VertBuffVertPtr)
				fseek f (VertBufferOffset + VertBuffPolyPtr) #seek_set
				VertBuffPolyStart = (ftell f) + readlong f
				fseek f (VertBufferOffset + VertBuffInfoPtr) #seek_set
				VertBuffInfoStart = (ftell f) + readlong f

				fseek f VertBuffInfoStart #seek_set

				VertInfoCount = readlong f

				-- Types:
				-- 0x00 = Positions
				-- 0x01 = Normals
				-- 0x02 = Tangents
				-- 0x03 = UVs (1)
				-- 0x04 = UVs (2)
				-- 0x05 = UVs (3)
				-- 0x06 = UVs (4)
				-- 0x07 = Colors
				-- 0x08 = Colors 2
				-- 0x0B = Bone IDs
				-- 0x0C = Weights
				-- 0x0D = Bitangents

				-- Formats:
				-- 0x01 = Half-floats
				-- 0x02 = Floats
				-- 0x03 = Unsigned bytes
				-- 0x05 = Unsigned shorts
				-- 0x08 = Unsigned bytes as float (# / 255)

				for v = 1 to VertInfoCount do (
					VertInfoOffset = (ftell f) + readlong f
					VertInfoRet = (ftell f)
					fseek f VertInfoOffset #seek_set
					printDebug ("Vertex format data " + v as string + " start: " + (ftell f) as string)
					VertInfoLytPtr = (ftell f) - readlong f

					fseek f VertInfoLytPtr #seek_set

					VertInfoLytHeadLen = readshort f #unsigned
					case VertInfoLytHeadLen of (
						default: (throw ("Unknown header length!"))
						0x0A:(
							VertInfoLytSize = readshort f #unsigned
							VertInfoTypePtr = readshort f #unsigned
							VertInfoFmtPtr = readshort f #unsigned
							VertInfoUnkPtr = readshort f #unsigned
						)
					)

					if VertInfoFmtPtr != 0x00 then (
						fseek f (VertInfoOffset + VertInfoFmtPtr) #seek_set
						VertBuffFmt = readlong f
					) else (VertBuffFmt = 0)

					case VertBuffFmt of (
							default:(throw ("Unknown vertex format detected!"))
							0:(VertBuffFmt = "Floats")
							1:(VertBuffFmt = "Half-Floats")
							3:(VertBuffFmt = "Bytes")
							5:(VertBuffFmt = "Shorts")
							8:(VertBuffFmt = "BytesAsFloat")
						)

					if VertInfoTypePtr != 0x00 then (
						fseek f (VertInfoOffset + VertInfoTypePtr) #seek_set
						VertBuffType = readlong f
					) else (VertBuffType = 0)

					case VertBuffType of (
						default:(throw ("Unknown vertex type detected!"))
						0:(
							PositionsFmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown positions combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x08) -- Estimated
								"Floats":(VertBufferStride = VertBufferStride + 0x0C)
							)
						)
						1:(
							NormalsFmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown normals combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x08)
								"Floats":(VertBufferStride = VertBufferStride + 0x0C) -- Estimated
							)
						)
						2:(
							TangentsFmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown tangents combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x08)
								"Floats":(VertBufferStride = VertBufferStride + 0x0C) -- Estimated
							)
						)
						3:(
							UVsFmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown UV combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x04)
								"Floats":(VertBufferStride = VertBufferStride + 0x08)
							)
						)
						4:(
							UVs2Fmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown UV2 combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x04)
								"Floats":(VertBufferStride = VertBufferStride + 0x08)
							)
						)
						5:(
							UVs3Fmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown UV3 combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x04)
								"Floats":(VertBufferStride = VertBufferStride + 0x08)
							)
						)
						6:(
							UVs4Fmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown UV4 combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x04)
								"Floats":(VertBufferStride = VertBufferStride + 0x08)
							)
						)
						7:(
							ColorsFmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown colors combination detected!"))
								"Bytes":(VertBufferStride = VertBufferStride + 0x04)
							)
						)
						8:(
							Colors2Fmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown colors 2 combination detected!"))
								"Bytes":(VertBufferStride = VertBufferStride + 0x04)
							)
						)
						11:(
							BonesFmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown bones combination detected!"))
								"Shorts":(VertBufferStride = VertBufferStride + 0x08)
								"Bytes":(VertBufferStride = VertBufferStride + 0x04)
							)
						)
						12:(
							WeightsFmt = VertBuffFmt
							case VertBuffFmt of (
								default:(throw ("Unknown weights combination detected!"))
								"BytesAsFloat":(VertBufferStride = VertBufferStride + 0x04)
							)
						)
						13:(
							BitangentsFmt = VertBuffFmt
							case BitangentsFmt of (
								default:(throw ("Unknown bitangents combination detected!"))
								"Half-Floats":(VertBufferStride = VertBufferStride + 0x08)
							)
						)
					)

					printDebug ("Vertex format data " + v as string + " end: " + (ftell f) as string)
					fseek f VertInfoRet #seek_set
				)
				printDebug ("Stride: 0x" + bit.intAsHex(VertBufferStride) as string + " | Normals: " + NormalsFmt as string + " | Tangents: " + TangentsFmt as string + " | UV1: " + UVsFmt as string + " | UV2: " + UVs2Fmt as string + " | UV3: " + UVs3Fmt as string + " | UV4: " + UVs4Fmt as string + " | Colors: " + ColorsFmt as string + " | Colors 2: " + Colors2Fmt as string + " | Bones: " + BonesFmt as string + " | Weights: " + WeightsFmt as string + " | Bitangents: " + BitangentsFmt as string)

				fseek f VertBuffPolyStart #seek_set
				PolyBuffDatCount = readlong f
				for p = 1 to PolyBuffDatCount do (
					PolyBuffDatOffset = (ftell f) + readlong f
					PolyRet = (ftell f)
					fseek f PolyBuffDatOffset #seek_set
					printDebug ("Facepoint " + p as string + " data start: " + ftell f as string)

					PolyLytPtr = (ftell f) - readlong f
					fseek f PolyLytPtr #seek_set

					PolyLytHeadLen = readshort f
					case PolyLytHeadLen of (
						default: (throw ("Unknown header length!"))
						0x08:(
							PolyStartPtr = readshort f #unsigned
							PolyMatIDPtr = readshort f #unsigned
							PolyUnkPtr = readshort f #unsigned
						)
					)
					
					if PolyMatIDPtr != 0x00 then (
						fseek f (PolyBuffDatOffset + PolyMatIDPtr) #seek_set
						MatID = readlong f + 1
					) else (MatID = 1)
					
					fseek f (PolyBuffDatOffset + PolyStartPtr) #seek_set
					FacepointCount = readlong f
					printDebug ("Facepoint " + p as string + " start: " + ftell f as string)

					for v = 1 to (FacepointCount / 3) do (
						fa = readshort f #unsigned + 1
						fb = readshort f #unsigned + 1
						fc = readshort f #unsigned + 1
						append Face_array [fa,fb,fc]
						append FaceMatID_array MatID
					)

					printDebug ("Facepoint " + p as string + " end: " + ftell f as string)
					fseek f PolyRet #seek_set
				)

				fseek f VertBuffVertStart #seek_set
				VertBufferSize = readlong f
				printDebug ("Vertex buffer " + x as string + " start: " + ftell f as string)
				-- Who needs a proper vertex count anyway am I right?

				for v = 1 to (VertBufferSize / VertBufferStride) do (
					case PositionsFmt of (
						default:(throw ("Unknown positions type!"))
						"Half-Floats":(
							vx = readhalffloat f
							vy = readhalffloat f
							vz = readhalffloat f
							vq = readhalffloat f
						)
						"Floats":(
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
						)
					)
					case NormalsFmt of (
						default:(throw ("Unknown normals type!"))
						"Half-Floats":(
							nx = readhalffloat f
							ny = readhalffloat f
							nz = readhalffloat f
							nq = readhalffloat f
						)
						"Floats":(
							nx = readfloat f
							ny = readfloat f
							nz = readfloat f
						)
					)
					case TangentsFmt of (
						default:(throw ("Unknown tangents type!"))
						"None":()
						"Half-Floats":(
							binx = readhalffloat f
							biny = readhalffloat f
							binz = readhalffloat f
							binq = readhalffloat f
						)
						"Floats":(
							binx = readfloat f
							biny = readfloat f
							binz = readfloat f
						)
					)
					case UVsFmt of (
						default:(throw ("Unknown UV type!"))
						"None":(tu = 0; tv = 0)
						"Half-Floats":(
							tu = readhalffloat f
							tv = readhalffloat f
						)
						"Floats":(
							tu = readfloat f
							tv = readfloat f
						)					
					)
					case UVs2Fmt of (
						default:(throw ("Unknown UV2 type!"))
						"None":()
						"Half-Floats":(
							tu2 = readhalffloat f
							tv2 = readhalffloat f
							append UV2_array [tu2,tv2,0]
						)
						"Floats":(
							tu2 = readfloat f
							tv2 = readfloat f
							append UV2_array [tu2,tv2,0]
						)
					)
					case UVs3Fmt of (
						default:(throw ("Unknown UV3 type!"))
						"None":()
						"Half-Floats":(
							tu3 = readhalffloat f
							tv3 = readhalffloat f
							append UV3_array [tu3,tv3,0]
						)
						"Floats":(
							tu3 = readfloat f
							tv3 = readfloat f
							append UV3_array [tu3,tv3,0]
						)
					)
					case UVs4Fmt of (
						default:(throw ("Unknown UV4 type!"))
						"None":()
						"Half-Floats":(
							tu4 = readhalffloat f
							tv4 = readhalffloat f
							append UV4_array [tu4,tv4,0]
						)
						"Floats":(
							tu4 = readfloat f
							tv4 = readfloat f
							append UV4_array [tu4,tv4,0]
						)
					)
					case ColorsFmt of (
						default:(throw ("Unknown color type!"))
						"None":(colorr = 255; colorg = 255; colorb = 255; colora = 1)
						"Bytes":(
							colorr = readbyte f #unsigned
							colorg = readbyte f #unsigned
							colorb = readbyte f #unsigned
							colora = readbyte f #unsigned as float / 255
						)
					)
					case Colors2Fmt of (
						default:(throw ("Unknown color 2 type!"))
						"None":(colorr2 = 255; colorg2 = 255; colorb2 = 255; colora2 = 1)
						"Bytes":(
							colorr2 = readbyte f #unsigned
							colorg2 = readbyte f #unsigned
							colorb2 = readbyte f #unsigned
							colora2 = readbyte f #unsigned as float / 255
						)
					)
					case BonesFmt of (
						default:(throw ("Unknown bones type!"))
						"None":(Bone1 = 1; Bone2 = 0; Bone3 = 0; Bone4  = 0)
						"Shorts":(
							Bone1 = readshort f #unsigned + 1
							Bone2 = readshort f #unsigned + 1
							Bone3 = readshort f #unsigned + 1
							Bone4 = readshort f #unsigned + 1
						)
						"Bytes":(
							Bone1 = readbyte f #unsigned + 1
							Bone2 = readbyte f #unsigned + 1
							Bone3 = readbyte f #unsigned + 1
							Bone4 = readbyte f #unsigned + 1
						)
					)
					case WeightsFmt of (
						default:(throw ("Unknown weights type!"))
						"None":(Weight1 = 1; Weight2 = 0; Weight3 = 0; Weight4 = 0)
						"BytesAsFloat":(
							Weight1 = (readbyte f #unsigned as float) / 255
							Weight2 = (readbyte f #unsigned as float) / 255
							Weight3 = (readbyte f #unsigned as float) / 255
							Weight4 = (readbyte f #unsigned as float) / 255
						)
					)
					case BitangentsFmt of (
						default:(throw ("Unknown bitangents type!"))
						"None":()
						"Half-Floats":(
							tanx = readhalffloat f
							tany = readhalffloat f
							tanz = readhalffloat f
							tanq = readhalffloat f
						)
						"Floats":(
							tanx = readfloat f
							tany = readfloat f
							tanz = readfloat f
						)
					)
					append Vert_array [vx,vy,vz]
					append Normal_array [nx,ny,nz]
					case VertColors of (
						1:(append Color_array [colorr,colorg,colorb]; append Alpha_array colora)
						2:(append Color_array [colorr2,colorg2,colorb2]; append Alpha_array colora2)
					)					
					append UV_array [tu,tv,0]
					append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
					append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
				)
				printDebug ("Vertex buffer " + x as string + " end: " + ftell f as string)

				fseek f VertBufferRet #seek_set

				for b = 1 to W1_array.count do (
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

				msh = mesh vertices:Vert_array faces:Face_array
				msh.numTVerts = Vert_array.count
				buildTVFaces msh
				msh.name = (VisGroupBone_array[x] as string)
				msh.material = multimat
				for j = 1 to UV_array.count do setTVert msh j UV_array[j]
				if UV2_array.count > 0 do (
					meshop.setNumMaps msh 3 keep:true
					for i = 1 to UV2_array.count do (
						meshop.setMapVert msh 2 i UV2_array[i]
					)
				)
				if UV3_array.count > 0 do (
					meshop.setNumMaps msh 4 keep:true
					for i = 1 to UV3_array.count do (
						meshop.setMapVert msh 3 i UV3_array[i]
					)
				)
				if UV4_array.count > 0 do (
					meshop.setNumMaps msh 5 keep:true
					for i = 1 to UV4_array.count do (
						meshop.setMapVert msh 4 i UV4_array[i]
					)
				)
				for j = 1 to Face_array.count do (	
					setTVFace msh j Face_array[j]
					setFaceMatID msh j FaceMatID_array[j]
				)
				if VertColors != 3 do (
					setNumCPVVerts msh msh.numTVerts
					setCVertMode msh true
					setShadeCVerts msh true
					for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
					for j = 1 to Alpha_array.count do (meshop.setVertAlpha msh -2 j Alpha_array[j])
				)
				for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
				max modify mode
				select msh
				
				addmodifier msh (Edit_Normals ()) ui:off
				msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
				EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
				EN_setNormal = msh.Edit_Normals.SetNormal
				normID = #{}

				for v = 1 to Normal_array.count do (
					free normID
					EN_convertVS #{v} &normID
					for id in normID do EN_setNormal id Normal_array[v]
				)

				if BoneRigArray.count > 0 do (
					max modify mode
					select msh

					skinMod = skin ()
					boneIDMap = #()
					addModifier msh skinMod
					msh.Skin.weightAllVertices = false

					for i = 1 to BoneRigArray.count do
					(
						 maxbone = getnodebyname BoneRigArray[i]
						 if i != BoneRigArray.count then
							skinOps.addBone skinMod maxbone 0
						 else
							skinOps.addBone skinMod maxbone 1
					)

					local numSkinBones = skinOps.GetNumberBones skinMod
					for i = 1 to numSkinBones do
					(
						local boneName = skinOps.GetBoneName skinMod i 0
						for j = 1 to BoneRigArray.count do
						(
							if boneName == BoneRigArray[j] then
							(
								boneIDMap[j] = i
								j = BoneRigArray.count + 1
							)
						)
					) -- This fixes bone ordering in 3DS Max 2012. Thanks to sunnydavis for the fix!

					modPanel.setCurrentObject skinMod

					for i = 1 to Vert_array.count do (
						skinOps.SetVertexWeights skinMod i 1 1
						skinOps.unnormalizeVertex skinMod i true 
						skinOps.SetVertexWeights skinMod i 1 0
					)
						skinOps.RemoveZeroWeights skinMod
					for i = 1 to Vert_array.count do (
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

			Print ("Done! ("+((((timestamp())-st)*0.001)as string)+" Seconds)")
		)
	)

	on btnImportTRMDL pressed do (
		fname = getOpenFileName \ 
		caption:"Nintendo Switch Pokémon Model File" \
		types:"Nintendo Switch Pokémon LA / SV Model File (*.trmdl)|*.trmdl" \
		historyCategory:"TRMDLPresets"
		if fname != undefined do (
			trmdl = fopen fname "rb"
			trskl = undefined
			trmsh = undefined
			trmtr = undefined
			filep = getFilenamePath fname
			filen = getFilenameFile fname
			clearlistener()
			st = timestamp()

			struct Bone_Info_Struct (Bone1, Bone2, Bone3, Bone4)
			struct Weight_Info_Struct (Weight1, Weight2, Weight3, Weight4)
			struct weight_data (boneids, weights)
			struct PolyGroup_Struct (PolyGroupName, VisGroupName, VertBufferStride, PositionsFmt, NormalsFmt, BinormalsFmt, TangentsFmt, Tangents2Fmt, Tangents3Fmt, UVsFmt, UVs2Fmt, UVs3Fmt, UVs4Fmt, ColorsFmt, Colors2Fmt, BonesFmt, WeightsFmt, SVUnkFmt)
			struct MatData_Struct (MatName, MatShader, MatCol0, MatLym0, MatNrm0, MatEmi0, MatRgh0, MatMtl0, MatColor1R, MatColor1G, MatColor1B, MatColor2R, MatColor2G, MatColor2B, MatColor3R, MatColor3G, MatColor3B, MatColor4R, MatColor4G, MatColor4B, MatEmiColor1R, MatEmiColor1G, MatEmiColor1B, MatEmiColor2R, MatEmiColor2G, MatEmiColor2B, MatEmiColor3R, MatEmiColor3G, MatEmiColor3B, MatEmiColor4R, MatEmiColor4G, MatEmiColor4B, MatRghLayer0, MatRghLayer1, MatRghLayer2, MatRghLayer3, MatRghLayer4, MatMtlLayer0, MatMtlLayer1, MatMtlLayer2, MatMtlLayer3, MatMtlLayer4)

			local VertColors = tglVertColors.state
			local ArceusLODs = tglArceusLODs.checked
			local ArceusScale = tglArceusScale.checked
			local ArceusMaskSplit = tglArceusMaskSplit.checked
			local ArceusShiny = tglArceusShiny.checked
			local ArceusSimpleMat = tglArceusSimpleMat.checked
			local ArceusColorMult = spnArceusColorMult.value
			local TrainerMerge = tglTrainerMerge.state
			local MaxVer = maxVersion()
			TRMSHLODs_array = #()
			BoneArray = #()
			BoneRigArray = #()
			TRSKLBoneAdjust = 1 -- Always start at 1 unless otherwise specified, because 0 doesn't count.
			CharaCheck = "None" -- This is necessary to make character models import correctly, due to shared bone structures.

			printDebug ("Parsing TRMDL...")
			TRMDLFileStart = readlong trmdl; fseek trmdl TRMDLFileStart #seek_set
			TRMDLStruct = (ftell trmdl) - readlong trmdl; fseek trmdl TRMDLStruct #seek_set
			TRMDLStructLen = readshort trmdl #unsigned
			case TRMDLStructLen of (
				default:(throw ("Unexpected TRMDL header struct length!"))
				0x0012:(
					TRMDLStructSectionLen = readshort trmdl #unsigned
					TRMDLStructStart = readshort trmdl #unsigned
					TRMDLStructTRMSH = readshort trmdl #unsigned
					TRMDLStructTRSKL = readshort trmdl #unsigned
					TRMDLStructTRMTR = readshort trmdl #unsigned
					TRMDLStructCustom = readshort trmdl #unsigned
					TRMDLStructBoundBox = readshort trmdl #unsigned
					TRMDLStructFloat = readshort trmdl #unsigned
				)
				0x0014:(
					-- Scarlet/Violet Only
					TRMDLStructSectionLen = readshort trmdl #unsigned
					TRMDLStructStart = readshort trmdl #unsigned
					TRMDLStructTRMSH = readshort trmdl #unsigned
					TRMDLStructTRSKL = readshort trmdl #unsigned
					TRMDLStructTRMTR = readshort trmdl #unsigned
					TRMDLStructCustom = readshort trmdl #unsigned
					TRMDLStructBoundBox = readshort trmdl #unsigned
					TRMDLStructFloat = readshort trmdl #unsigned
					TRMDLStructTRLTT = readshort trmdl #unsigned
				)
				0x0018:(
					-- Scarlet/Violet Only
					TRMDLStructSectionLen = readshort trmdl #unsigned
					TRMDLStructStart = readshort trmdl #unsigned
					TRMDLStructTRMSH = readshort trmdl #unsigned
					TRMDLStructTRSKL = readshort trmdl #unsigned
					TRMDLStructTRMTR = readshort trmdl #unsigned
					TRMDLStructCustom = readshort trmdl #unsigned
					TRMDLStructBoundBox = readshort trmdl #unsigned
					TRMDLStructFloat = readshort trmdl #unsigned
					TRMDLStructTRLTT = readshort trmdl #unsigned
					TRMDLStructUnkA = readshort trmdl #unsigned
					TRMDLStructUnkB = readshort trmdl #unsigned
				)
			)
			if TRMDLStructTRMSH != 0 do (
				fseek trmdl (TRMDLFileStart + TRMDLStructTRMSH) #seek_set
				TRMSHStart = (ftell trmdl) + readlong trmdl; fseek trmdl TRMSHStart #seek_set
				TRMSHCount = readlong trmdl
				for x = 1 to TRMSHCount do (
					TRMSHOffset = (ftell trmdl) + readlong trmdl
					TRMSHRet = (ftell trmdl)
					fseek trmdl TRMSHOffset #seek_set
					TRMSHStruct = (ftell trmdl) - readlong trmdl; fseek trmdl TRMSHStruct #seek_set
					TRMSHStructLen = readshort trmdl #unsigned
					case TRMSHStructLen of (
						default:(throw ("Unexpected TRMSH struct length!"))
						0x0006:(
							TRMSHStructSectionLen = readshort trmdl #unsigned
							TRMSHStructPtrName = readshort trmdl #unsigned
						)
					)
					if TRMSHStructPtrName != 0 do (
						fseek trmdl (TRMSHOffset + TRMSHStructPtrName) #seek_set
						TRMSHNameOffset = (ftell trmdl) + readlong trmdl
						fseek trmdl TRMSHNameOffset #seek_set
						TRMSHNameLen = readlong trmdl
						CharaCheck = ReadFixedString trmdl 3; fseek trmdl -3 #seek_cur -- Hacky fix to make character models work correctly.
						case TrainerMerge of (
							1:(
								case CharaCheck of (
									default:(CharaCheck = "None")
									"p0_":(CharaCheck = "FlorianJuliana") -- Specifically for Scarlet/Violet, adding this here to prevent crashes if you forget to change the option before importing.
									"p1_":(CharaCheck = "Rei")
									"p2_":(CharaCheck = "Akari")
								)
							)
							2:(
								case CharaCheck of (
									default:(CharaCheck = "None")
									"p0_":(CharaCheck = "FlorianJuliana") -- Almost everything is shared between the two.
									"p1_":(CharaCheck = "FlorianJuliana") -- Florian specifically. Rei has a different bone count, can't use the same value for that.
									"p2_":(CharaCheck = "FlorianJuliana") -- Juliana specifically. Akari has a different bone count, can't use the same value for that.
								)
							)
						)
						TRMSHName = ReadFixedString trmdl TRMSHNameLen
						print TRMSHName
						append TRMSHLODs_array TRMSHName
					)
					fseek trmdl TRMSHRet #seek_set
				)
			)
			if TRMDLStructTRSKL != 0 do (
				fseek trmdl (TRMDLFileStart + TRMDLStructTRSKL) #seek_set
				TRSKLStart = (ftell trmdl) + readlong trmdl; fseek trmdl TRSKLStart #seek_set
				TRSKLStruct = (ftell trmdl) - readlong trmdl; fseek trmdl TRSKLStruct #seek_set
				TRSKLStructLen = readshort trmdl #unsigned
				case TRSKLStructLen of (
					default:(throw ("Unexpected TRSKL struct length!"))
					0x0006:(
						TRSKLStructSectionLen = readshort trmdl #unsigned
						TRSKLStructPtrName = readshort trmdl #unsigned
					)
				)
				if TRSKLStructPtrName != 0 do (
					fseek trmdl (TRSKLStart + TRSKLStructPtrName) #seek_set
					TRSKLNameOffset = (ftell trmdl) + readlong trmdl
					fseek trmdl TRSKLNameOffset #seek_set
					TRSKLNameLen = readlong trmdl
					TRSKLName = ReadFixedString trmdl TRSKLNameLen
					print TRSKLName
					if doesFileExist (filep + TRSKLName) == true then (
						trskl = fopen (filep + TRSKLName) "rb"
					) else (
						print ("Can't find " + TRSKLName + "!")
					)
				)
			)
			if TRMDLStructTRMTR != 0 do (
				fseek trmdl (TRMDLFileStart + TRMDLStructTRMTR) #seek_set
				TRMTRStart = (ftell trmdl) + readlong trmdl; fseek trmdl TRMTRStart #seek_set
				TRMTRCount = readlong trmdl
				for x = 1 to TRMTRCount do (
					TRMTROffset = (ftell trmdl) + readlong trmdl
					TRMTRRet = (ftell trmdl)
					fseek trmdl TRMTROffset #seek_set
					TRMTRNameLen = readlong trmdl - 6
					TRMTRName = ReadFixedString trmdl TRMTRNameLen
					if ArceusShiny == true do (TRMTRShinyName = TRMTRName + "_rare.trmtr")
					TRMTRName = TRMTRName + ".trmtr"
					if ArceusShiny == true do (
						if doesFileExist (filep + TRMTRShinyName) == true then (
							TRMTRName = TRMTRShinyName
						) else (
							print ("Shiny (''rare'') material not found, falling back to the original file instead.")
						)
					)
					print TRMTRName
					if x == 1 do (
						if doesFileExist (filep + TRMTRName) == true then (
							trmtr = fopen (filep + TRMTRName) "rb"
						) else (
							print ("Can't find " + TRMTRName + "!")
						)
					)
					fseek trmdl TRMTRRet #seek_set
				)
			)
			fclose trmdl

			if trskl != undefined then (
				printDebug ("Parsing TRSKL...")
				TRSKLFileStart = readlong trskl
				fseek trskl TRSKLFileStart #seek_set
				TRSKLStruct = (ftell trskl) - readlong trskl; fseek trskl TRSKLStruct #seek_set
				TRSKLStructLen = readshort trskl #unsigned
				case TRSKLStructLen of (
					default:(throw ("Unexpected TRSKL header struct length!"))
					0x000C:(
						TRSKLStructSectionLen = readshort trskl #unsigned
						TRSKLStructStart = readshort trskl #unsigned
						TRSKLStructBone = readshort trskl #unsigned
						TRSKLStructB = readshort trskl #unsigned
						TRSKLStructC = readshort trskl #unsigned
						TRSKLStructBoneAdjust = 0 
					)
					0x000E:(
						TRSKLStructSectionLen = readshort trskl #unsigned
						TRSKLStructStart = readshort trskl #unsigned
						TRSKLStructBone = readshort trskl #unsigned
						TRSKLStructB = readshort trskl #unsigned
						TRSKLStructC = readshort trskl #unsigned
						TRSKLStructBoneAdjust = readshort trskl #unsigned
					)
				)
				if TRSKLStructBoneAdjust != 0 do (
					fseek trskl (TRSKLFileStart + TRSKLStructBoneAdjust) #seek_set
					TRSKLBoneAdjust = readlong trskl + 1; printDebug ("Mesh node IDs start at " + TRSKLBoneAdjust as string)
					TrainerRigLink(CharaCheck)
				)
				if TRSKLStructBone != 0 do (
					fseek trskl (TRSKLFileStart + TRSKLStructBone) #seek_set
					TRSKLBoneStart = (ftell trskl) + readlong trskl; fseek trskl TRSKLBoneStart #seek_set
					BoneCount = readlong trskl
					for x = 1 to BoneCount do (
						BoneOffset = (ftell trskl) + readlong trskl
						BoneRet = (ftell trskl)
						fseek trskl BoneOffset #seek_set
						printDebug ("Bone " + x as string + " start: " + BoneOffset as string)
						TRSKLBoneStruct = (ftell trskl) - readlong trskl; fseek trskl TRSKLBoneStruct #seek_set
						TRSKLBoneStructLen = readshort trskl #unsigned
						case TRSKLBoneStructLen of (
							default:(throw ("Unexpected TRSKL bone struct length!"))
							0x0012:(
								TRSKLBoneStructPtrSectionLen = readshort trskl #unsigned
								TRSKLBoneStructPtrString = readshort trskl #unsigned
								TRSKLBoneStructPtrBone = readshort trskl #unsigned
								TRSKLBoneStructPtrC = readshort trskl #unsigned
								TRSKLBoneStructPtrD = readshort trskl #unsigned
								TRSKLBoneStructPtrParent = readshort trskl #unsigned
								TRSKLBoneStructPtrRigID = readshort trskl #unsigned
								TRSKLBoneStructPtrBoneMerge = readshort trskl #unsigned
								TRSKLBoneStructPtrH = 0
								TRSKLBoneStructPtrI = 0
							)
							0x0014:(
								TRSKLBoneStructPtrSectionLen = readshort trskl #unsigned
								TRSKLBoneStructPtrString = readshort trskl #unsigned
								TRSKLBoneStructPtrBone = readshort trskl #unsigned
								TRSKLBoneStructPtrC = readshort trskl #unsigned
								TRSKLBoneStructPtrD = readshort trskl #unsigned
								TRSKLBoneStructPtrParent = readshort trskl #unsigned
								TRSKLBoneStructPtrRigID = readshort trskl #unsigned
								TRSKLBoneStructPtrBoneMerge = readshort trskl #unsigned
								TRSKLBoneStructPtrH = readshort trskl #unsigned
								TRSKLBoneStructPtrI = 0
							)
							0x0016:(
								TRSKLBoneStructPtrSectionLen = readshort trskl #unsigned
								TRSKLBoneStructPtrString = readshort trskl #unsigned
								TRSKLBoneStructPtrBone = readshort trskl #unsigned
								TRSKLBoneStructPtrC = readshort trskl #unsigned
								TRSKLBoneStructPtrD = readshort trskl #unsigned
								TRSKLBoneStructPtrParent = readshort trskl #unsigned
								TRSKLBoneStructPtrRigID = readshort trskl #unsigned
								TRSKLBoneStructPtrBoneMerge = readshort trskl #unsigned
								TRSKLBoneStructPtrH = readshort trskl #unsigned
								TRSKLBoneStructPtrI = readshort trskl #unsigned
							)
						)
						if TRSKLBoneStructPtrBoneMerge != 0 do (
							fseek trskl (BoneOffset + TRSKLBoneStructPtrBoneMerge) #seek_set
							BoneMergeStart = (ftell trskl) + readlong trskl; fseek trskl BoneMergeStart #seek_set
							BoneMergeStringLen = readlong trskl
							if BoneMergeStringLen != 0 then (
								BoneMergeString = ReadFixedString trskl BoneMergeStringLen
								printDebug ("BoneMerge to " + BoneMergeString)
								) else (BoneMergeString = "")
						)
						if TRSKLBoneStructPtrBone != 0 do (
							fseek trskl (BoneOffset + TRSKLBoneStructPtrBone) #seek_set
							BonePosStart = (ftell trskl) + readlong trskl; fseek trskl BonePosStart #seek_set
							BonePosStruct = (ftell trskl) - readlong trskl; fseek trskl BonePosStruct #seek_set
							BonePosStructLen = readshort trskl #unsigned
							case BonePosStructLen of (
								default:(throw ("Unexpected bone position struct length!"))
								0x000A:(
									BonePosStructSectionLen = readshort trskl #unsigned
									BonePosStructPtrScl = readshort trskl #unsigned
									BonePosStructPtrRot = readshort trskl #unsigned
									BonePosStructPtrTrs = readshort trskl #unsigned
								)
							)

							fseek trskl (BonePosStart + BonePosStructPtrTrs) #seek_set
							BoneTX = readfloat trskl; BoneTY = readfloat trskl; BoneTZ = readfloat trskl
							if ArceusScale == true do (BoneTX = BoneTX * 100; BoneTY = BoneTY * 100; BoneTZ = BoneTZ * 100)
							fseek trskl (BonePosStart + BonePosStructPtrRot) #seek_set
							BoneRX = readfloat trskl; BoneRY = readfloat trskl; BoneRZ = readfloat trskl
							fseek trskl (BonePosStart + BonePosStructPtrScl) #seek_set
							BoneSX = readfloat trskl; BoneSY = readfloat trskl; BoneSZ = readfloat trskl

							if TRSKLBoneStructPtrString != 0 do (
								fseek trskl (BoneOffset + TRSKLBoneStructPtrString) #seek_set
								BoneStringStart = (ftell trskl) + readlong trskl; fseek trskl BoneStringStart #seek_set
								BoneStrLen = readlong trskl; BoneName = ReadFixedString trskl BoneStrLen
							)
							if TRSKLBoneStructPtrParent != 0x00 then (
								fseek trskl (BoneOffset + TRSKLBoneStructPtrParent) #seek_set
								BoneParent = readlong trskl + 1
								) else (
								BoneParent = 0
							)
							if TRSKLBoneStructPtrRigID != 0 do (
								fseek trskl (BoneOffset + TRSKLBoneStructPtrRigID) #seek_set
								BoneRigID = readlong trskl + TRSKLBoneAdjust
								BoneRigArray[BoneRigID] = BoneName
							)

							tfm = scaleMatrix [BoneSX,BoneSY,BoneSZ]
							tfm = tfm * (rotateXMatrix (radToDeg BoneRX)) * (rotateYMatrix (radToDeg BoneRY)) * (rotateZMatrix (radToDeg BoneRZ))
							tfm.row4 = [BoneTX, BoneTY, BoneTZ]

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
							newBone.name = BoneName
							newBone.width  = 0.01
							newBone.height = 0.01
							newBone.transform = tfm
							newBone.wirecolor = yellow
							newBone.showlinks = true
							newBone.setBoneEnable false 0
							newBone.pos.controller      = TCB_position ()
							newBone.rotation.controller = TCB_rotation ()
							if (BoneParent != 0) then
								newBone.parent = BoneArray[(BoneParent)]
							if TRSKLBoneAdjust > 1 do (
								if BoneMergeString != "" and TRSKLBoneAdjust > 1 do (
									newBone.parent = getnodebyname BoneMergeString
									if newBone.parent != undefined then (
										newBone.transform = newBone.transform * newBone.parent.transform
									) else (
										case CharaCheck of (
											default:(print ("Can't parent " + BoneName as string + " to " + BoneMergeString + "! Please import 'cc_base0001_00_young_m' or 'cc_base' first, then try again."))
											"FlorianJuliana":(print ("Can't parent " + BoneName as string + " to " + BoneMergeString + "! Please import both 'p0_base' and 'p0_face0000_00_face00' first, then try again."))
											"Rei":(print ("Can't parent " + BoneName as string + " to " + BoneMergeString + "! Please import both 'p2_base0001_00_default' and 'p1_face0001_00_default' first, then try again."))
											"Akari":(print ("Can't parent " + BoneName as string + " to " + BoneMergeString + "! Please import both 'p2_base0001_00_default' and 'p2_face0001_00_default' first, then try again."))
										)
									)
								)
							)
							append BoneArray newBone
						)
						fseek trskl BoneRet #seek_set
					)
				)
				fclose trskl
			) else (
				-- If no skeleton, assume the default set.
				TrainerRigLink(CharaCheck)
			)

			if trmtr != undefined do (
				printDebug ("Parsing TRMTR...")
				TRMTRFileStart = readlong trmtr
				MatData_array = #()
				fseek trmtr TRMTRFileStart #seek_set
				TRMTRStruct = (ftell trmtr) - readlong trmtr; fseek trmtr TRMTRStruct #seek_set
				TRMTRStructLen = readshort trmtr #unsigned
				case TRMTRStructLen of (
					default:(throw ("Unexpected TRMTR header struct length!"))
					0x0008:(
						TRMTRStructSectionLen = readshort trmtr #unsigned
						TRMTRStructStart = readshort trmtr #unsigned
						TRMTRStructMaterial = readshort trmtr #unsigned
					)
				)
				if TRMTRStructMaterial != 0 do (
					fseek trmtr (TRMTRFileStart + TRMTRStructMaterial) #seek_set
					MatStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatStart #seek_set
					MatCount = readlong trmtr
					for x = 1 to MatCount do (
						MatShader = "Standard"; MatCol0 = ""; MatLym0 = ""; MatNrm0 = ""; MatEmi0 = ""; MatRgh0 = ""; MatMtl0 = ""
						MatUVScaleU = 1.0; MatUVScaleV = 1.0; MatUVTrsU = 0; MatUVTrsV = 0
						MatUVScale2U = 1.0; MatUVScale2V = 1.0; MatUVTrs2U = 0; MatUVTrs2V = 0
						MatColor1R = 100.0; MatColor1G = 100.0; MatColor1B = 100.0
						MatColor2R = 100.0; MatColor2G = 100.0; MatColor2B = 100.0
						MatColor3R = 100.0; MatColor3G = 100.0; MatColor3B = 100.0
						MatColor4R = 100.0; MatColor4G = 100.0; MatColor4B = 100.0
						MatEmiColor1R = 0.0; MatEmiColor1G = 0.0; MatEmiColor1B = 0.0
						MatEmiColor2R = 0.0; MatEmiColor2G = 0.0; MatEmiColor2B = 0.0
						MatEmiColor3R = 0.0; MatEmiColor3G = 0.0; MatEmiColor3B = 0.0
						MatEmiColor4R = 0.0; MatEmiColor4G = 0.0; MatEmiColor4B = 0.0
						MatRghLayer0 = 1.0; MatRghLayer1 = 100.0; MatRghLayer2 = 100.0; MatRghLayer3 = 100.0; MatRghLayer4 = 100.0
						MatMtlLayer0 = 0.0; MatMtlLayer1 = 0.0; MatMtlLayer2 = 0.0; MatMtlLayer3 = 0.0; MatMtlLayer4 = 0.0
						MatOffset = (ftell trmtr) + readlong trmtr
						MatRet = (ftell trmtr)
						fseek trmtr MatOffset #seek_set
						printMat ("--------------------")
						MatStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatStruct #seek_set
						MatStructLen = readshort trmtr #unsigned
						case MatStructLen of (
							default:(throw ("Unexpected material struct length!"))
							0x0024:(
								MatStructSectionLen = readshort trmtr #unsigned
								MatStructPtrParamA = readshort trmtr #unsigned -- material name
								MatStructPtrParamB = readshort trmtr #unsigned -- shader parameters
								MatStructPtrParamC = readshort trmtr #unsigned -- texture assignment
								MatStructPtrParamD = readshort trmtr #unsigned -- float values
								MatStructPtrParamE = readshort trmtr #unsigned -- float parameters
								MatStructPtrParamF = readshort trmtr #unsigned -- two float parameters
								MatStructPtrParamG = readshort trmtr #unsigned -- three float parameters
								MatStructPtrParamH = readshort trmtr #unsigned -- four float parameters
								MatStructPtrParamI = readshort trmtr #unsigned -- unknown parameters
								MatStructPtrParamJ = readshort trmtr #unsigned -- single byte parameters
								MatStructPtrParamK = readshort trmtr #unsigned -- unknown parameters
								MatStructPtrParamL = readshort trmtr #unsigned -- unknown parameters
								MatStructPtrParamM = readshort trmtr #unsigned -- unknown parameters
								MatStructPtrParamN = readshort trmtr #unsigned -- single boolean parameter, pm0488_00_00 seems to be the only model with this parameter
								MatStructPtrParamO = readshort trmtr #unsigned -- single long value parameter, related to translucency?
								MatStructPtrParamP = readshort trmtr #unsigned -- opacity/translucency parameter
							)
						)
						if MatStructPtrParamA != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamA) #seek_set
							MatParamAStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamAStart #seek_set
							MatNameLen = readlong trmtr
							MatName = ReadFixedString trmtr MatNameLen
							printMat ("Material properties for " + MatName + ":")
						)
						if MatStructPtrParamB != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamB) #seek_set
							MatParamBStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamBStart #seek_set
							MatParamBSectionCount = readlong trmtr
							for z = 1 to MatParamBSectionCount do (
								MatParamBOffset = (ftell trmtr) + readlong trmtr
								MatParamBRet = (ftell trmtr)
								fseek trmtr MatParamBOffset #seek_set
								MatParamBStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamBStruct #seek_set
								MatParamBStructLen = readshort trmtr #unsigned
								case MatParamBStructLen of (
									default:(throw ("Unexpected MatParamB struct length!"))
									0x0008:(
										MatParamBStructSectionLen = readshort trmtr #unsigned
										MatParamBStructPtrString = readshort trmtr #unsigned
										MatParamBStructPtrParams = readshort trmtr #unsigned
									)
								)
								if MatParamBStructPtrString != 0 do (
									fseek trmtr (MatParamBOffset + MatParamBStructPtrString) #seek_set
									MatParamBShaderStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamBShaderStart #seek_set
									MatParamBShaderLen = readlong trmtr
									MatParamBShaderString = ReadFixedString trmtr MatParamBShaderLen
									printMat ("Shader: " + MatParamBShaderString)
									if z == 1 do (MatShader = MatParamBShaderString)
								)
								if MatParamBStructPtrParams != 0 do (
									fseek trmtr (MatParamBOffset + MatParamBStructPtrParams) #seek_set
									MatParamBSubStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamBSubStart #seek_set
									MatParamBSubCount = readlong trmtr
									for y = 1 to MatParamBSubCount do (
										MatParamBSubOffset = (ftell trmtr) + readlong trmtr; 
										MatParamBSubRet = (ftell trmtr)
										fseek trmtr MatParamBSubOffset #seek_set
										MatParamBSubStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamBSubStruct #seek_set
										MatParamBSubStructLen = readshort trmtr #unsigned
										case MatParamBSubStructLen of (
											default:(throw ("Unexpected MatParamBSub struct length!"))
											0x0008:(
												MatParamBSubStructSectionLen = readshort trmtr #unsigned
												MatParamBSubStructPtrString = readshort trmtr #unsigned
												MatParamBSubStructPtrValue = readshort trmtr #unsigned
											)
										)
										if MatParamBSubStructPtrString != 0 do (
											fseek trmtr (MatParamBSubOffset + MatParamBSubStructPtrString) #seek_set
											MatParamBSubStringStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamBSubStringStart #seek_set
											MatParamBSubStringLen = readlong trmtr
											MatParamBSubString = ReadFixedString trmtr MatParamBSubStringLen
										)
										if MatParamBSubStructPtrValue != 0 do (
											fseek trmtr (MatParamBSubOffset + MatParamBSubStructPtrValue) #seek_set
											MatParamBSubValueStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamBSubValueStart #seek_set
											MatParamBSubValueLen = readlong trmtr
											MatParamBSubValue = ReadFixedString trmtr MatParamBSubValueLen
											printMat (MatParamBSubString + ": " + MatParamBSubValue as string)
											if MatParamBSubString == "EnableEmissionColorMap" do (MatEmi0 ="none")
										)
										fseek trmtr MatParamBSubRet #seek_set
									)
								)
								fseek trmtr MatParamBRet #seek_set
							)
						)
						if MatStructPtrParamC != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamC) #seek_set
							MatParamCStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamCStart #seek_set
							MatParamCCount = readlong trmtr
							for z = 1 to MatParamCCount do (
								MatParamCOffset = (ftell trmtr) + readlong trmtr
								MatParamCRet = (ftell trmtr)
								fseek trmtr MatParamCOffset #seek_set
								MatParamCStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamCStruct #seek_set
								MatParamCStructLen = readshort trmtr #unsigned
								case MatParamCStructLen of (
									default:(throw ("Unexpected MatParamC struct length!"))
									0x0008:(
										MatParamCStructSectionLen = readshort trmtr #unsigned
										MatParamCStructPtrString = readshort trmtr #unsigned
										MatParamCStructPtrValue = readshort trmtr #unsigned
										MatParamCStructPtrID = 0
									)
									0x000A:(
										MatParamCStructSectionLen = readshort trmtr #unsigned
										MatParamCStructPtrString = readshort trmtr #unsigned
										MatParamCStructPtrValue = readshort trmtr #unsigned
										MatParamCStructPtrID = readshort trmtr #unsigned
									)
								)
								if MatParamCStructPtrString != 0 do (
									fseek trmtr (MatParamCOffset + MatParamCStructPtrString) #seek_set
									MatParamCStringStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamCStringStart #seek_set
									MatParamCStringLen = readlong trmtr
									MatParamCString = ReadFixedString trmtr MatParamCStringLen
								)
								if MatParamCStructPtrValue != 0 do (
									fseek trmtr (MatParamCOffset + MatParamCStructPtrValue) #seek_set
									MatParamCValueStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamCValueStart #seek_set
									MatParamCValueLen = readlong trmtr - 5 -- Trimming the ".bntx" from the end.
									MatParamCValue = ReadFixedString trmtr MatParamCValueLen
								)
								if MatParamCStructPtrID != 0 then (
									fseek trmtr (MatParamCOffset + MatParamCStructPtrID) #seek_set
									MatParamCID = readlong trmtr
								) else (MatParamCID = 0)
								case MatParamCString of (
									"BaseColorMap":(MatCol0 = MatParamCValue)
									"LayerMaskMap":(MatLym0 = MatParamCValue)
									"NormalMap":(MatNrm0 = MatParamCValue)
									"EmissionColorMap":(MatEmi0 = MatParamCValue)
									"RoughnessMap":(MatRgh0 = MatParamCValue)
									"MetallicMap":(MatMtl0 = MatParamCValue)
								)
								-- There's also all of the following, which aren't automatically assigned to keep things simple.
								-- "AOMap"
								-- "AOMap1"
								-- "AOMap2"
								-- "BaseColorMap1"
								-- "DisplacementMap"
								-- "EyelidShadowMaskMap"
								-- "FlowMap"
								-- "FoamMaskMap"
								-- "GrassCollisionMap"
								-- "HighlightMaskMap"
								-- "LowerEyelidColorMap"
								-- "NormalMap1"
								-- "NormalMap2"
								-- "PackedMap"
								-- "UpperEyelidColorMap"
								-- "WeatherLayerMaskMap"
								-- "WindMaskMap"
								printMat (MatParamCString + ": " + MatParamCValue + " [" + MatParamCID as string + "]")
								fseek trmtr MatParamCRet #seek_set
							)
						)
						if MatStructPtrParamD != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamD) #seek_set
							MatParamDStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamDStart #seek_set
							MatParamDCount = readlong trmtr
							for z = 1 to MatParamDCount do (
								MatParamDOffset = (ftell trmtr) + readlong trmtr
								MatParamDRet = (ftell trmtr)
								fseek trmtr MatParamDOffset #seek_set
								MatParamDStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamDStruct #seek_set
								MatParamDStructLen = readshort trmtr #unsigned
								case MatParamDStructLen of (
									default:(throw ("Unexpected MatParamD struct length!"))
									0x001E:(
										MatParamDStructSectionLen = readshort trmtr #unsigned
										MatParamDStructPtrA = readshort trmtr #unsigned
										MatParamDStructPtrB = readshort trmtr #unsigned
										MatParamDStructPtrC = readshort trmtr #unsigned
										MatParamDStructPtrD = readshort trmtr #unsigned
										MatParamDStructPtrE = readshort trmtr #unsigned
										MatParamDStructPtrF = readshort trmtr #unsigned
										MatParamDStructPtrG = readshort trmtr #unsigned
										MatParamDStructPtrH = readshort trmtr #unsigned
										MatParamDStructPtrI = readshort trmtr #unsigned
										MatParamDStructPtrJ = readshort trmtr #unsigned
										MatParamDStructPtrK = readshort trmtr #unsigned
										MatParamDStructPtrL = readshort trmtr #unsigned
										MatParamDStructPtrM = readshort trmtr #unsigned
									)
								)
								if MatParamDStructPtrA != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrA) #seek_set
									MatParamDValueA = readlong trmtr
								) else (MatParamDValueA = 0)
								if MatParamDStructPtrB != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrB) #seek_set
									MatParamDValueB = readlong trmtr
								) else (MatParamDValueB = 0)
								if MatParamDStructPtrC != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrC) #seek_set
									MatParamDValueC = readlong trmtr
								) else (MatParamDValueC = 0)
								if MatParamDStructPtrD != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrD) #seek_set
									MatParamDValueD = readlong trmtr
								) else (MatParamDValueD = 0)
								if MatParamDStructPtrE != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrE) #seek_set
									MatParamDValueE = readlong trmtr
								) else (MatParamDValueE = 0)
								if MatParamDStructPtrF != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrF) #seek_set
									MatParamDValueF = readlong trmtr
								) else (MatParamDValueF = 0)
								if MatParamDStructPtrG != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrG) #seek_set
									MatParamDValueG = readlong trmtr
								) else (MatParamDValueG = 0)
								if MatParamDStructPtrH != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrH) #seek_set
									MatParamDValueH = readlong trmtr
								) else (MatParamDValueH = 0)
								if MatParamDStructPtrI != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrI) #seek_set
									MatParamDValueI = readlong trmtr
								) else (MatParamDValueI = 0)
								if MatParamDStructPtrJ != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrJ) #seek_set
									MatParamDValueJ = readlong trmtr
								) else (MatParamDValueJ = 0)
								if MatParamDStructPtrK != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrK) #seek_set
									MatParamDValueK = readlong trmtr
								) else (MatParamDValueK = 0)
								if MatParamDStructPtrL != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrL) #seek_set
									MatParamDValueL = readlong trmtr
								) else (MatParamDValueL = 0)
								if MatParamDStructPtrM != 0 then (
									fseek trmtr (MatParamDOffset + MatParamDStructPtrM) #seek_set
									MatParamDValueM1 = readfloat trmtr; MatParamDValueM2 = readfloat trmtr; MatParamDValueM3 = readfloat trmtr
								) else (MatParamDValueM1 = 0; MatParamDValueM2 = 0; MatParamDValueM3 = 0)
								printMat ("Flags #" + z as string + ": " + MatParamDValueA as string + " | " + MatParamDValueB as string + " | " + MatParamDValueC as string + " | " + MatParamDValueD as string + " | " + MatParamDValueE as string + " | " + MatParamDValueF as string + " | " + MatParamDValueG as string + " | " + MatParamDValueH as string + " | " + MatParamDValueI as string + " | " + MatParamDValueJ as string + " | " + MatParamDValueK as string + " | " + MatParamDValueL as string + " | " + MatParamDValueM1 as string + ", " + MatParamDValueM2 as string + ", " + MatParamDValueM3 as string)
								fseek trmtr MatParamDRet #seek_set
							)
						)
						if MatStructPtrParamE != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamE) #seek_set
							MatParamEStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamEStart #seek_set
							MatParamECount = readlong trmtr
							for z = 1 to MatParamECount do (
								MatParamEOffset = (ftell trmtr) + readlong trmtr
								MatParamERet = (ftell trmtr)
								fseek trmtr MatParamEOffset #seek_set
								MatParamEStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamEStruct #seek_set
								MatParamEStructLen = readshort trmtr #unsigned
								case MatParamEStructLen of (
									default:(throw ("Unexpected MatParamE struct length!"))
									0x0006:(
										MatParamEStructSectionLen = readshort trmtr #unsigned
										MatParamEStructPtrString = readshort trmtr #unsigned
										MatParamEStructPtrValue = 0
									)
									0x0008:(
										MatParamEStructSectionLen = readshort trmtr #unsigned
										MatParamEStructPtrString = readshort trmtr #unsigned
										MatParamEStructPtrValue = readshort trmtr #unsigned
									)
								)
								if MatParamEStructPtrString != 0 do (
									fseek trmtr (MatParamEOffset + MatParamEStructPtrString) #seek_set
									MatParamEStringStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamEStringStart #seek_set
									MatParamEStringLen = readlong trmtr
									MatParamEString = ReadFixedString trmtr MatParamEStringLen
								)
								if MatParamEStructPtrValue != 0 then (
									fseek trmtr (MatParamEOffset + MatParamEStructPtrValue) #seek_set
									MatParamEValue = readfloat trmtr
								) else (MatParamEValue = 0 as float)
								case MatParamEString of (
									"Roughness":(MatRghLayer0 = MatParamEValue)
									"RoughnessLayer1":(MatRghLayer1 = MatParamEValue)
									"RoughnessLayer2":(MatRghLayer2 = MatParamEValue)
									"RoughnessLayer3":(MatRghLayer3 = MatParamEValue)
									"RoughnessLayer4":(MatRghLayer4 = MatParamEValue)
									"Metallic":(MatMtlLayer0 = MatParamEValue)
									"MetallicLayer1":(MatMtlLayer1 = MatParamEValue)
									"MetallicLayer2":(MatMtlLayer2 = MatParamEValue)
									"MetallicLayer3":(MatMtlLayer3 = MatParamEValue)
									"MetallicLayer4":(MatMtlLayer4 = MatParamEValue)
								)
								printMat (MatParamEString + ": " + MatParamEValue as string)
								fseek trmtr MatParamERet #seek_set
							)
						)
						if MatStructPtrParamF != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamF) #seek_set
							MatParamFStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamFStart #seek_set
							MatParamFCount = readlong trmtr
							for z = 1 to MatParamFCount do (
								MatParamFOffset = (ftell trmtr) + readlong trmtr
								MatParamFRet = (ftell trmtr)
								fseek trmtr MatParamFOffset #seek_set
								MatParamFStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamFStruct #seek_set
								MatParamFStructLen = readshort trmtr #unsigned
								case MatParamFStructLen of (
									default:(throw ("Unexpected MatParamF struct length!"))
									0x0008:(
										MatParamFStructSectionLen = readshort trmtr #unsigned
										MatParamFStructPtrString = readshort trmtr #unsigned
										MatParamFStructPtrValues = readshort trmtr #unsigned
									)
								)
								if MatParamFStructPtrString != 0 do (
									fseek trmtr (MatParamFOffset + MatParamFStructPtrString) #seek_set
									MatParamFStringStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamFStringStart #seek_set
									MatParamFStringLen = readlong trmtr
									MatParamFString = ReadFixedString trmtr MatParamFStringLen
								)
								if MatParamFStructPtrValues != 0 then (
									fseek trmtr (MatParamFOffset + MatParamFStructPtrValues) #seek_set
									MatParamFValue1 = readfloat trmtr
									MatParamFValue2 = readfloat trmtr
								) else (MatParamFValue1 = 0 as float; MatParamFValue2 = 0 as float)
								printMat (MatParamFString + ": " + MatParamFValue1 as string + ", " + MatParamFValue2 as string)
								fseek trmtr MatParamFRet #seek_set
							)
						)
						if MatStructPtrParamG != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamG) #seek_set
							MatParamGStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamGStart #seek_set
							MatParamGCount = readlong trmtr
							for z = 1 to MatParamGCount do (
								MatParamGOffset = (ftell trmtr) + readlong trmtr
								MatParamGRet = (ftell trmtr)
								fseek trmtr MatParamGOffset #seek_set
								MatParamGStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamGStruct #seek_set
								MatParamGStructLen = readshort trmtr #unsigned
								case MatParamGStructLen of (
									default:(throw ("Unexpected MatParamG struct length!"))
									0x0008:(
										MatParamGStructSectionLen = readshort trmtr #unsigned
										MatParamGStructPtrString = readshort trmtr #unsigned
										MatParamGStructPtrValues = readshort trmtr #unsigned
									)
								)
								if MatParamGStructPtrString != 0 do (
									fseek trmtr (MatParamGOffset + MatParamGStructPtrString) #seek_set
									MatParamGStringStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamGStringStart #seek_set
									MatParamGStringLen = readlong trmtr
									MatParamGString = ReadFixedString trmtr MatParamGStringLen
								)
								if MatParamGStructPtrValues != 0 then (
									fseek trmtr (MatParamGOffset + MatParamGStructPtrValues) #seek_set
									MatParamGValue1 = readfloat trmtr
									MatParamGValue2 = readfloat trmtr
									MatParamGValue3 = readfloat trmtr
								) else (MatParamGValue1 = 0 as float; MatParamGValue2 = 0 as float; MatParamGValue3 = 0 as float)
								printMat (MatParamGString + ": " + MatParamGValue1 as string + ", " + MatParamGValue2 as string + ", " + MatParamGValue3 as string)
								fseek trmtr MatParamGRet #seek_set
							)
						)
						if MatStructPtrParamH != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamH) #seek_set
							MatParamHStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamHStart #seek_set
							MatParamHCount = readlong trmtr
							for z = 1 to MatParamHCount do (
								MatParamHOffset = (ftell trmtr) + readlong trmtr
								MatParamHRet = (ftell trmtr)
								fseek trmtr MatParamHOffset #seek_set
								MatParamHStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamHStruct #seek_set
								MatParamHStructLen = readshort trmtr #unsigned
								case MatParamHStructLen of (
									default:(throw ("Unexpected MatParamH struct length!"))
									0x0008:(
										MatParamHStructSectionLen = readshort trmtr #unsigned
										MatParamHStructPtrString = readshort trmtr #unsigned
										MatParamHStructPtrValues = readshort trmtr #unsigned
									)
								)
								if MatParamHStructPtrString != 0 do (
									fseek trmtr (MatParamHOffset + MatParamHStructPtrString) #seek_set
									MatParamHStringStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamHStringStart #seek_set
									MatParamHStringLen = readlong trmtr
									MatParamHString = ReadFixedString trmtr MatParamHStringLen
								)
								if MatParamHStructPtrValues != 0 then (
									fseek trmtr (MatParamHOffset + MatParamHStructPtrValues) #seek_set
									MatParamHValue1 = readfloat trmtr
									MatParamHValue2 = readfloat trmtr
									MatParamHValue3 = readfloat trmtr
									MatParamHValue4 = readfloat trmtr
								) else (MatParamHValue1 = 0 as float; MatParamHValue2 = 0 as float; MatParamHValue3 = 0 as float; MatParamHValue4 = 0 as float)
								case MatParamHString of (
									"UVScaleOffset":(MatUVScaleU = MatParamHValue1; MatUVScaleV = MatParamHValue2; MatUVTrsU = MatParamHValue3; MatUVTrsV = MatParamHValue4)
									"UVScaleOffset1":(MatUVScale2U = MatParamHValue1; MatUVScale2V = MatParamHValue2; MatUVTrs2U = MatParamHValue3; MatUVTrs2V = MatParamHValue4)
									"BaseColorLayer1":(MatColor1R = MatParamHValue1 * 100; MatColor1G = MatParamHValue2 * 100; MatColor1B = MatParamHValue3 * 100)
									"BaseColorLayer2":(MatColor2R = MatParamHValue1 * 100; MatColor2G = MatParamHValue2 * 100; MatColor2B = MatParamHValue3 * 100)
									"BaseColorLayer3":(MatColor3R = MatParamHValue1 * 100; MatColor3G = MatParamHValue2 * 100; MatColor3B = MatParamHValue3 * 100)
									"BaseColorLayer4":(MatColor4R = MatParamHValue1 * 100; MatColor4G = MatParamHValue2 * 100; MatColor4B = MatParamHValue3 * 100)
									"EmissionColorLayer1":(MatEmiColor1R = MatParamHValue1 * 100; MatEmiColor1G = MatParamHValue2 * 100; MatEmiColor1B = MatParamHValue3 * 100)
									"EmissionColorLayer2":(MatEmiColor2R = MatParamHValue1 * 100; MatEmiColor2G = MatParamHValue2 * 100; MatEmiColor2B = MatParamHValue3 * 100)
									"EmissionColorLayer3":(MatEmiColor3R = MatParamHValue1 * 100; MatEmiColor3G = MatParamHValue2 * 100; MatEmiColor3B = MatParamHValue3 * 100)
									"EmissionColorLayer4":(MatEmiColor4R = MatParamHValue1 * 100; MatEmiColor4G = MatParamHValue2 * 100; MatEmiColor4B = MatParamHValue3 * 100)
								)
								printMat (MatParamHString + ": " + MatParamHValue1 as string + ", " + MatParamHValue2 as string + ", " + MatParamHValue3 as string + ", " + MatParamHValue4 as string)
								fseek trmtr MatParamHRet #seek_set
							)
						)
						if MatStructPtrParamI != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamI) #seek_set
							MatParamIStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamIStart #seek_set
							MatParamIStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamIStruct #seek_set
							MatParamIStructLen = readshort trmtr #unsigned
							case MatParamIStructLen of (
								default:(throw ("Unexpected MatParamI struct length!"))
								0x0000:()
							)
						)
						if MatStructPtrParamJ != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamJ) #seek_set
							MatParamJStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamJStart #seek_set
							MatParamJCount = readlong trmtr
							for y = 1 to MatParamJCount do (
								MatParamJOffset = (ftell trmtr) + readlong trmtr; 
								MatParamJRet = (ftell trmtr)
								fseek trmtr MatParamJOffset #seek_set
								MatParamJStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamJStruct #seek_set
								MatParamJStructLen = readshort trmtr #unsigned
								case MatParamJStructLen of (
									default:(throw ("Unexpected MatParamJ struct length!"))
									0x0006:(
										MatParamJStructSectionLen = readshort trmtr #unsigned
										MatParamJStructPtrString = readshort trmtr #unsigned
										MatParamJStructPtrValue = 0
									)
									0x0008:(
										MatParamJStructSectionLen = readshort trmtr #unsigned
										MatParamJStructPtrString = readshort trmtr #unsigned
										MatParamJStructPtrValue = readshort trmtr #unsigned
									)
								)
								if MatParamJStructPtrString != 0 do (
									fseek trmtr (MatParamJOffset + MatParamJStructPtrString) #seek_set
									MatParamJStringStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamJStringStart #seek_set
									MatParamJStringLen = readlong trmtr
									MatParamJString = ReadFixedString trmtr MatParamJStringLen
								)
								if MatParamJStructPtrValue != 0 then (
									fseek trmtr (MatParamJOffset + MatParamJStructPtrValue) #seek_set
									MatParamJValue = readlong trmtr
								) else (MatParamJValue = "0")
								printMat (MatParamJString + ": " + MatParamJValue as string)
								fseek trmtr MatParamJRet #seek_set
							)
						)
						if MatStructPtrParamK != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamK) #seek_set
							MatParamKStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamKStart #seek_set
							MatParamKStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamKStruct #seek_set
							MatParamKStructLen = readshort trmtr #unsigned
							case MatParamKStructLen of (
								default:(throw ("Unexpected MatParamK struct length!"))
								0x0000:()
							)
						)
						if MatStructPtrParamL != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamL) #seek_set
							MatParamLStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamLStart #seek_set
							MatParamLStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamLStruct #seek_set
							MatParamLStructLen = readshort trmtr #unsigned
							case MatParamLStructLen of (
								default:(throw ("Unexpected MatParamL struct length!"))
								0x0000:()
							)
						)
						if MatStructPtrParamM != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamM) #seek_set
							MatParamMStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamMStart #seek_set
							MatParamMStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamMStruct #seek_set
							MatParamMStructLen = readshort trmtr #unsigned
							case MatParamMStructLen of (
								default:(throw ("Unexpected MatParamM struct length!"))
								0x0000:()
							)
						)
						if MatStructPtrParamN != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamN) #seek_set
							MatParamNStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamNStart #seek_set
							MatParamNStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamNStruct #seek_set
							MatParamNStructLen = readshort trmtr #unsigned
							case MatParamNStructLen of (
								default:(throw ("Unexpected MatParamN struct length!"))
								0x0004:(
									MatParamNStructSectionLen = readshort trmtr #unsigned
									MatParamNStructUnk = 0
								)
								0x0006:(
									MatParamNStructSectionLen = readshort trmtr #unsigned
									MatParamNStructUnk = readshort trmtr #unsigned
								)
							)
							if MatParamNStructUnk != 0 do (
								fseek trmtr (MatParamNStart + MatParamNStructUnk) #seek_set
								MatParamNValue = readbyte trmtr #unsigned
								printMat ("Unknown value A = " + MatParamNValue as string)
							)
						)
						if MatStructPtrParamO != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamO) #seek_set
							MatParamOStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamOStart #seek_set
							MatParamOStruct = (ftell trmtr) - readlong trmtr; fseek trmtr MatParamOStruct #seek_set
							MatParamOStructLen = readshort trmtr #unsigned
							case MatParamOStructLen of (
								default:(throw ("Unexpected MatParamO struct length!"))
								0x0004:(
									MatParamOStructSectionLen = readshort trmtr #unsigned
									MatParamOStructUnk = 0
									MatParamOStructValue = 0
								)
								0x0008:(
									MatParamOStructSectionLen = readshort trmtr #unsigned
									MatParamOStructUnk = readshort trmtr #unsigned
									MatParamOStructValue = readshort trmtr #unsigned
								)
							)
							if MatParamOStructValue != 0 do (
								fseek trmtr (MatParamOStart + MatParamOStructValue) #seek_set
								MatParamOValue = readbyte trmtr #unsigned
								printMat ("Unknown value B = " + MatParamOValue as string)
							)
						)
						if MatStructPtrParamP != 0 do (
							fseek trmtr (MatOffset + MatStructPtrParamP) #seek_set
							MatParamPStart = (ftell trmtr) + readlong trmtr; fseek trmtr MatParamPStart #seek_set
							MatParamPStringLen = readlong trmtr
							MatParamPString = ReadFixedString trmtr MatParamPStringLen
							printMat MatParamPString
						)
						append MatData_array (MatData_Struct MatName:MatName MatShader:MatShader MatCol0:MatCol0 MatLym0:MatLym0 MatNrm0:MatNrm0 MatEmi0:MatEmi0 MatRgh0:MatRgh0 MatMtl0:MatMtl0 MatColor1R:MatColor1R MatColor1G:MatColor1G MatColor1B:MatColor1B MatColor2R:MatColor2R MatColor2G:MatColor2G MatColor2B:MatColor2B MatColor3R:MatColor3R MatColor3G:MatColor3G MatColor3B:MatColor3B MatColor4R:MatColor4R MatColor4G:MatColor4G MatColor4B:MatColor4B MatEmiColor1R:MatEmiColor1R MatEmiColor1G:MatEmiColor1G MatEmiColor1B:MatEmiColor1B MatEmiColor2R:MatEmiColor2R MatEmiColor2G:MatEmiColor2G MatEmiColor2B:MatEmiColor2B MatEmiColor3R:MatEmiColor3R MatEmiColor3G:MatEmiColor3G MatEmiColor3B:MatEmiColor3B MatEmiColor4R:MatEmiColor4R MatEmiColor4G:MatEmiColor4G MatEmiColor4B:MatEmiColor4B MatRghLayer0:MatRghLayer0 MatRghLayer1:MatRghLayer1 MatRghLayer2:MatRghLayer2 MatRghLayer3:MatRghLayer3 MatRghLayer4:MatRghLayer4 MatMtlLayer0:MatMtlLayer0 MatMtlLayer1:MatMtlLayer1 MatMtlLayer2:MatMtlLayer2 MatMtlLayer3:MatMtlLayer3 MatMtlLayer4:MatMtlLayer4)
						fseek trmtr MatRet #seek_set
					)
					printMat ("--------------------")
				)
				fclose trmtr
				printDebug MatData_array
				multimat = MultiMaterial()
				multimat.name = filen
				multimat.numsubs = MatData_array.count
				for m = 1 to MatData_array.count do (
					tm = Bitmaptexture name:"BaseColorMap" filename:(filep + MatData_array[m].MatCol0 + ".png")
					tm.alphasource = 0
					if ArceusMaskSplit == true then (
						lmA = Bitmaptexture name:"LayerMaskMap1" filename:(filep + MatData_array[m].MatLym0 + "_A.png") -- Red channel
						lmB = Bitmaptexture name:"LayerMaskMap2" filename:(filep + MatData_array[m].MatLym0 + "_B.png") -- Green channel
						lmC = Bitmaptexture name:"LayerMaskMap3" filename:(filep + MatData_array[m].MatLym0 + "_C.png") -- Blue channel
						lmD = Bitmaptexture name:"LayerMaskMap4" filename:(filep + MatData_array[m].MatLym0 + "_D.png") -- Alpha channel
					) else (lm = Bitmaptexture name:"LayerMaskMap" filename:(filep + MatData_array[m].MatLym0 + ".png"))
					if MatData_array[m].MatNrm0 != "" do (nm = Bitmaptexture name:"NormalMap" filename:(filep + MatData_array[m].MatNrm0 + ".png"))
					if MatData_array[m].MatEmi0 != "" do (em = Bitmaptexture name:"EmissionColorMap" filename:(filep + MatData_array[m].MatEmi0 + ".png"))
					if MatData_array[m].MatRgh0 != "" do (rm = Bitmaptexture name:"RoughnessMap" filename:(filep + MatData_array[m].MatRgh0 + ".png"))
					if MatData_array[m].MatMtl0 != "" do (mm = Bitmaptexture name:"MetallicMap" filename:(filep + MatData_array[m].MatMtl0 + ".png"))
					if MaxVer[1] >= 19000 and ArceusSimpleMat == false then(
						multimat.materialList[m] = PhysicalMaterial() -- We have the technology!
						mat = multimat.materialList[m]
						mat.name = MatData_array[m].MatName as string
						mat.showinviewport = true
						if MatData_array[m].MatLym0 != "" then (
							-- Gotta set up a Composite material for this. For the _lym textures:
							-- BaseColorLayer1 = Red
							-- BaseColorLayer2 = Green
							-- BaseColorLayer3 = Blue
							-- BaseColorLayer4 = Alpha
							mat.base_color_map = CompositeTexturemap()
							mat.base_color_map.mapList.count = 5
							mat.base_color_map.mapList[1] = tm
							mat.base_color_map.mapList[2] = Color_Correction name:"BaseColorLayer1" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor1R gainG:MatData_array[m].MatColor1G gainB:MatData_array[m].MatColor1B
							mat.base_color_map.mapList[3] = Color_Correction name:"BaseColorLayer2" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor2R gainG:MatData_array[m].MatColor2G gainB:MatData_array[m].MatColor2B
							mat.base_color_map.mapList[4] = Color_Correction name:"BaseColorLayer3" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor3R gainG:MatData_array[m].MatColor3G gainB:MatData_array[m].MatColor3B
							mat.base_color_map.mapList[5] = Color_Correction name:"BaseColorLayer4" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor4R gainG:MatData_array[m].MatColor4G gainB:MatData_array[m].MatColor4B
							if ArceusMaskSplit == false then (
								mat.base_color_map.mask[2] = Color_Correction name:"LayerMaskMap1" map:lm color:[1.0,1.0,1.0,1.0] rewireR:0 rewireG:0 rewireB:0 rewireA:9 -- Red/Green/Blue = Red, Alpha = One
								mat.base_color_map.mask[3] = Color_Correction name:"LayerMaskMap2" map:lm color:[1.0,1.0,1.0,1.0] rewireR:1 rewireG:1 rewireB:1 rewireA:9 -- Red/Green/Blue = Green, Alpha = One
								mat.base_color_map.mask[4] = Color_Correction name:"LayerMaskMap3" map:lm color:[1.0,1.0,1.0,1.0] rewireR:2 rewireG:2 rewireB:2 rewireA:9 -- Red/Green/Blue = Blue, Alpha = One
								mat.base_color_map.mask[5] = Color_Correction name:"LayerMaskMap4" map:lm color:[1.0,1.0,1.0,1.0] rewireR:3 rewireG:3 rewireB:3 rewireA:9 -- Red/Green/Blue = Alpha, Alpha = One
							) else (
								mat.base_color_map.mask[2] = lmA
								mat.base_color_map.mask[3] = lmB
								mat.base_color_map.mask[4] = lmC
								mat.base_color_map.mask[5] = lmD
							)
						) else (mat.base_color_map = tm)
						if MatData_array[m].MatShader == "Transparent" do (mat.cutout_map = tm; mat.cutout_map.monoOutput = 1)
						if MatData_array[m].MatNrm0 != "" do (mat.bump_map = Normal_Bump normal_map:nm)
						if MatData_array[m].MatEmi0 != "" and MatData_array[m].MatEmi0 != "none" then (
							-- If we have an emission map, we use it and disregard the per-layer parameters.
							mat.emit_color_map = em; mat.emit_color_map_on = true
						) else (
							if MatData_array[m].MatEmi0 == "none" do (
							-- ...if we *don't* have an emission map, we build one using the layer mask and the respective parameters.
								mat.emit_color_map = CompositeTexturemap()
								mat.emit_color_map.mapList.count = 5
								mat.emit_color_map.mapList[1] = Color_Correction name:"EmissionColor" map:undefined color:[0.0,0.0,0.0,1.0]
								mat.emit_color_map.mapList[2] = Color_Correction name:"EmissionColorLayer1" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor1R gainG:MatData_array[m].MatEmiColor1G gainB:MatData_array[m].MatEmiColor1B
								mat.emit_color_map.mapList[3] = Color_Correction name:"EmissionColorLayer2" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor2R gainG:MatData_array[m].MatEmiColor2G gainB:MatData_array[m].MatEmiColor2B
								mat.emit_color_map.mapList[4] = Color_Correction name:"EmissionColorLayer3" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor3R gainG:MatData_array[m].MatEmiColor3G gainB:MatData_array[m].MatEmiColor3B
								mat.emit_color_map.mapList[5] = Color_Correction name:"EmissionColorLayer4" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor4R gainG:MatData_array[m].MatEmiColor4G gainB:MatData_array[m].MatEmiColor4B
								if ArceusMaskSplit == false then (
									mat.emit_color_map.mask[2] = Color_Correction name:"LayerMaskMap1" map:lm color:[1.0,1.0,1.0,1.0] rewireR:0 rewireG:0 rewireB:0 rewireA:9 -- Red/Green/Blue = Red, Alpha = One
									mat.emit_color_map.mask[3] = Color_Correction name:"LayerMaskMap2" map:lm color:[1.0,1.0,1.0,1.0] rewireR:1 rewireG:1 rewireB:1 rewireA:9 -- Red/Green/Blue = Green, Alpha = One
									mat.emit_color_map.mask[4] = Color_Correction name:"LayerMaskMap3" map:lm color:[1.0,1.0,1.0,1.0] rewireR:2 rewireG:2 rewireB:2 rewireA:9 -- Red/Green/Blue = Blue, Alpha = One
									mat.emit_color_map.mask[5] = Color_Correction name:"LayerMaskMap4" map:lm color:[1.0,1.0,1.0,1.0] rewireR:3 rewireG:3 rewireB:3 rewireA:9 -- Red/Green/Blue = Alpha, Alpha = One
								) else (
									mat.emit_color_map.mask[2] = lmA
									mat.emit_color_map.mask[3] = lmB
									mat.emit_color_map.mask[4] = lmC
									mat.emit_color_map.mask[5] = lmD
								)
								mat.emit_color_map_on = true
							)
						)
						mat.roughness = MatData_array[m].MatRghLayer0
						mat.roughness_inv = false -- It's on by default, we don't want that.
						if MatData_array[m].MatRgh0 != "" then (
							-- If we have a roughness map, we use it and disregard the per-layer parameters.
							mat.roughness_map = rm
						) else (
							if MatData_array[m].MatLym0 != "" do (
								-- ...if we *don't* have a roughness map, we build one using the layer mask and the respective parameters.
								mat.roughness_map = CompositeTexturemap()
								mat.roughness_map.mapList.count = 5
								mat.roughness_map.mapList[1] = Color_Correction name:"Roughness" map:undefined color:[MatData_array[m].MatRghLayer0,MatData_array[m].MatRghLayer0,MatData_array[m].MatRghLayer0,1.0]
								mat.roughness_map.mapList[2] = Color_Correction name:"RoughnessLayer1" map:undefined color:[MatData_array[m].MatRghLayer1,MatData_array[m].MatRghLayer1,MatData_array[m].MatRghLayer1,1.0]
								mat.roughness_map.mapList[3] = Color_Correction name:"RoughnessLayer2" map:undefined color:[MatData_array[m].MatRghLayer2,MatData_array[m].MatRghLayer2,MatData_array[m].MatRghLayer2,1.0]
								mat.roughness_map.mapList[4] = Color_Correction name:"RoughnessLayer3" map:undefined color:[MatData_array[m].MatRghLayer3,MatData_array[m].MatRghLayer3,MatData_array[m].MatRghLayer3,1.0]
								mat.roughness_map.mapList[5] = Color_Correction name:"RoughnessLayer4" map:undefined color:[MatData_array[m].MatRghLayer4,MatData_array[m].MatRghLayer4,MatData_array[m].MatRghLayer4,1.0]
								if ArceusMaskSplit == false then (
									mat.roughness_map.mask[2] = Color_Correction name:"LayerMaskMap1" map:lm color:[1.0,1.0,1.0,1.0] rewireR:0 rewireG:0 rewireB:0 rewireA:9 -- Red/Green/Blue = Red, Alpha = One
									mat.roughness_map.mask[3] = Color_Correction name:"LayerMaskMap2" map:lm color:[1.0,1.0,1.0,1.0] rewireR:1 rewireG:1 rewireB:1 rewireA:9 -- Red/Green/Blue = Green, Alpha = One
									mat.roughness_map.mask[4] = Color_Correction name:"LayerMaskMap3" map:lm color:[1.0,1.0,1.0,1.0] rewireR:2 rewireG:2 rewireB:2 rewireA:9 -- Red/Green/Blue = Blue, Alpha = One
									mat.roughness_map.mask[5] = Color_Correction name:"LayerMaskMap4" map:lm color:[1.0,1.0,1.0,1.0] rewireR:3 rewireG:3 rewireB:3 rewireA:9 -- Red/Green/Blue = Alpha, Alpha = One
								) else (
									mat.roughness_map.mask[2] = lmA
									mat.roughness_map.mask[3] = lmB
									mat.roughness_map.mask[4] = lmC
									mat.roughness_map.mask[5] = lmD
								)
							)
						)
						mat.metalness = MatData_array[m].MatMtlLayer0
						if MatData_array[m].MatMtl0 != "" then (
							-- If we have a metalness map, we use it and disregard the per-layer parameters.
							mat.metalness_map = mm
						) else (
							if MatData_array[m].MatLym0 != "" do (
								-- ...if we *don't* have a metalness map, we build one using the layer mask and the respective parameters.
								mat.metalness_map = CompositeTexturemap()
								mat.metalness_map.mapList.count = 5
								mat.metalness_map.mapList[1] = Color_Correction name:"Metalness" map:undefined color:[MatData_array[m].MatMtlLayer0,MatData_array[m].MatMtlLayer0,MatData_array[m].MatMtlLayer0,1.0]
								mat.metalness_map.mapList[2] = Color_Correction name:"MetalnessLayer1" map:undefined color:[MatData_array[m].MatMtlLayer1,MatData_array[m].MatMtlLayer1,MatData_array[m].MatMtlLayer1,1.0]
								mat.metalness_map.mapList[3] = Color_Correction name:"MetalnessLayer2" map:undefined color:[MatData_array[m].MatMtlLayer2,MatData_array[m].MatMtlLayer2,MatData_array[m].MatMtlLayer2,1.0]
								mat.metalness_map.mapList[4] = Color_Correction name:"MetalnessLayer3" map:undefined color:[MatData_array[m].MatMtlLayer3,MatData_array[m].MatMtlLayer3,MatData_array[m].MatMtlLayer3,1.0]
								mat.metalness_map.mapList[5] = Color_Correction name:"MetalnessLayer4" map:undefined color:[MatData_array[m].MatMtlLayer4,MatData_array[m].MatMtlLayer4,MatData_array[m].MatMtlLayer4,1.0]
								if ArceusMaskSplit == false then (
									mat.metalness_map.mask[2] = Color_Correction name:"LayerMaskMap1" map:lm color:[1.0,1.0,1.0,1.0] rewireR:0 rewireG:0 rewireB:0 rewireA:9 -- Red/Green/Blue = Red, Alpha = One
									mat.metalness_map.mask[3] = Color_Correction name:"LayerMaskMap2" map:lm color:[1.0,1.0,1.0,1.0] rewireR:1 rewireG:1 rewireB:1 rewireA:9 -- Red/Green/Blue = Green, Alpha = One
									mat.metalness_map.mask[4] = Color_Correction name:"LayerMaskMap3" map:lm color:[1.0,1.0,1.0,1.0] rewireR:2 rewireG:2 rewireB:2 rewireA:9 -- Red/Green/Blue = Blue, Alpha = One
									mat.metalness_map.mask[5] = Color_Correction name:"LayerMaskMap4" map:lm color:[1.0,1.0,1.0,1.0] rewireR:3 rewireG:3 rewireB:3 rewireA:9 -- Red/Green/Blue = Alpha, Alpha = One
								) else (
									mat.metalness_map.mask[2] = lmA
									mat.metalness_map.mask[3] = lmB
									mat.metalness_map.mask[4] = lmC
									mat.metalness_map.mask[5] = lmD
								)
							)
						)
					) else (
						multimat.materialList[m] = StandardMaterial() -- If using a pre-ART Renderer version of 3DS Max (anything before 2017), forces materials to be in Standard format just in case.
						mat = multimat.materialList[m]
						mat.name = MatData_array[m].MatName as string
						mat.showinviewport = true
						mat.twosided = false
						if MatData_array[m].MatLym0 != "" then (
							-- Gotta set up a Composite material for this. For the _lym textures:
							-- BaseColorLayer1 = Red
							-- BaseColorLayer2 = Green
							-- BaseColorLayer3 = Blue
							-- BaseColorLayer4 = Alpha
							mat.diffuseMap = CompositeTexturemap()
							mat.diffuseMap.mapList.count = 5
							mat.diffuseMap.mapList[1] = tm
							mat.diffuseMap.mapList[2] = Color_Correction name:"BaseColorLayer1" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor1R gainG:MatData_array[m].MatColor1G gainB:MatData_array[m].MatColor1B
							mat.diffuseMap.mapList[3] = Color_Correction name:"BaseColorLayer2" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor2R gainG:MatData_array[m].MatColor2G gainB:MatData_array[m].MatColor2B
							mat.diffuseMap.mapList[4] = Color_Correction name:"BaseColorLayer3" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor3R gainG:MatData_array[m].MatColor3G gainB:MatData_array[m].MatColor3B
							mat.diffuseMap.mapList[5] = Color_Correction name:"BaseColorLayer4" map:tm color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatColor4R gainG:MatData_array[m].MatColor4G gainB:MatData_array[m].MatColor4B
							if ArceusMaskSplit == false then (
								mat.diffuseMap.mask[2] = Color_Correction name:"LayerMaskMap1" map:lm color:[1.0,1.0,1.0,1.0] rewireR:0 rewireG:0 rewireB:0 rewireA:9 -- Red/Green/Blue = Red, Alpha = One
								mat.diffuseMap.mask[3] = Color_Correction name:"LayerMaskMap2" map:lm color:[1.0,1.0,1.0,1.0] rewireR:1 rewireG:1 rewireB:1 rewireA:9 -- Red/Green/Blue = Green, Alpha = One
								mat.diffuseMap.mask[4] = Color_Correction name:"LayerMaskMap3" map:lm color:[1.0,1.0,1.0,1.0] rewireR:2 rewireG:2 rewireB:2 rewireA:9 -- Red/Green/Blue = Blue, Alpha = One
								mat.diffuseMap.mask[5] = Color_Correction name:"LayerMaskMap4" map:lm color:[1.0,1.0,1.0,1.0] rewireR:3 rewireG:3 rewireB:3 rewireA:9 -- Red/Green/Blue = Alpha, Alpha = One
							) else (
								mat.diffuseMap.mask[2] = lmA
								mat.diffuseMap.mask[3] = lmB
								mat.diffuseMap.mask[4] = lmC
								mat.diffuseMap.mask[5] = lmD
							)
						) else (mat.diffuseMap = tm)

						if ArceusSimpleMat == false then (
							if MatData_array[m].MatShader == "Transparent" do (mat.opacityMap = tm; mat.opacityMap.monoOutput = 1)
							if MatData_array[m].MatNrm0 != "" do (mat.bumpMap = Normal_Bump normal_map:nm)
							if MatData_array[m].MatEmi0 != "" and MatData_array[m].MatEmi0 != "none" then (
								-- If we have an emission map, we use it and disregard the per-layer parameters.
								mat.selfillumMap = em; mat.useSelfIllumColor = true
							) else (
								if MatData_array[m].MatEmi0 == "none" do (
								-- ...if we *don't* have an emission map, we build one using the layer mask and the respective parameters.
									mat.selfillumMap = CompositeTexturemap()
									mat.selfillumMap.mapList.count = 5
									mat.selfillumMap.mapList[1] = Color_Correction name:"EmissionColor" map:undefined color:[0.0,0.0,0.0,1.0]
									mat.selfillumMap.mapList[2] = Color_Correction name:"EmissionColorLayer1" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor1R gainG:MatData_array[m].MatEmiColor1G gainB:MatData_array[m].MatEmiColor1B
									mat.selfillumMap.mapList[3] = Color_Correction name:"EmissionColorLayer2" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor2R gainG:MatData_array[m].MatEmiColor2G gainB:MatData_array[m].MatEmiColor2B
									mat.selfillumMap.mapList[4] = Color_Correction name:"EmissionColorLayer3" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor3R gainG:MatData_array[m].MatEmiColor3G gainB:MatData_array[m].MatEmiColor3B
									mat.selfillumMap.mapList[5] = Color_Correction name:"EmissionColorLayer4" map:undefined color:[1.0,1.0,1.0,1.0] lightnessMode:1 enableR:true enableG:true enableB:true gainRGB:ArceusColorMult gainR:MatData_array[m].MatEmiColor4R gainG:MatData_array[m].MatEmiColor4G gainB:MatData_array[m].MatEmiColor4B
									if ArceusMaskSplit == false then (
										mat.selfillumMap.mask[2] = Color_Correction name:"LayerMaskMap1" map:lm color:[1.0,1.0,1.0,1.0] rewireR:0 rewireG:0 rewireB:0 rewireA:9 -- Red/Green/Blue = Red, Alpha = One
										mat.selfillumMap.mask[3] = Color_Correction name:"LayerMaskMap2" map:lm color:[1.0,1.0,1.0,1.0] rewireR:1 rewireG:1 rewireB:1 rewireA:9 -- Red/Green/Blue = Green, Alpha = One
										mat.selfillumMap.mask[4] = Color_Correction name:"LayerMaskMap3" map:lm color:[1.0,1.0,1.0,1.0] rewireR:2 rewireG:2 rewireB:2 rewireA:9 -- Red/Green/Blue = Blue, Alpha = One
										mat.selfillumMap.mask[5] = Color_Correction name:"LayerMaskMap4" map:lm color:[1.0,1.0,1.0,1.0] rewireR:3 rewireG:3 rewireB:3 rewireA:9 -- Red/Green/Blue = Alpha, Alpha = One
									) else (
										mat.selfillumMap.mask[2] = lmA
										mat.selfillumMap.mask[3] = lmB
										mat.selfillumMap.mask[4] = lmC
										mat.selfillumMap.mask[5] = lmD
									)
									mat.useSelfIllumColor = true
								)
							)
						) else (
							mat.selfIllumAmount = 100
						)
					)
				)
			)

			if ArceusLODs == false and TRMSHCount > 1 do (TRMSHCount = 1)
			for w = 1 to TRMSHCount do (
				if doesFileExist (filep + TRMSHLODs_array[w]) == true then (
					PolyGroup_array = #()
					trmsh = fopen (filep + TRMSHLODs_array[w]) "rb"
					TRMSHFileStart = readlong trmsh
					printDebug ("Parsing TRMSH...")
					fseek trmsh TRMSHFileStart #seek_set
					TRMSHStruct = (ftell trmsh) - readlong trmsh; fseek trmsh TRMSHStruct #seek_set
					TRMSHStructLen = readshort trmsh #unsigned
					case TRMSHStructLen of (
						default:(throw ("Unexpected TRMSH header struct length!"))
						0x000A:(
							TRMSHStructSectionLen = readshort trmsh #unsigned
							TRMSHStructStart = readshort trmsh #unsigned
							TRMSHStructPolyGroup = readshort trmsh #unsigned
							TRMSHStructTRMBF = readshort trmsh #unsigned
						)
					)
					if TRMSHStructTRMBF != 0 do (
						fseek trmsh (TRMSHFileStart + TRMSHStructTRMBF) #seek_set
						TRMBFFilenameStart = (ftell trmsh) + readlong trmsh
						fseek trmsh TRMBFFilenameStart #seek_set
						TRMBFFilenameLen = readlong trmsh
						TRMBFFilename = ReadFixedString trmsh TRMBFFilenameLen
						print TRMBFFilename
						if doesFileExist (filep + TRMBFFilename) == true then (
							trmbf = fopen (filep + TRMBFFilename) "rb"
						) else (
							print ("Can't find " + TRMBFFilename + "!")
						)
					)
					if trmbf != undefined then (
						printDebug ("Parsing TRMBF...")
						TRMBFFileStart = readlong trmbf; fseek trmbf TRMBFFileStart #seek_set
						TRMBFStruct = (ftell trmbf) - readlong trmbf; fseek trmbf TRMBFStruct #seek_set
						TRMBFStructLen = readshort trmbf #unsigned
						case TRMBFStructLen of (
							default:(throw ("Unexpected TRMBF header struct length!"))
							0x0008:(
								TRMBFStructSectionLen = readshort trmbf #unsigned
								TRMBFStructStart = readshort trmbf #unsigned
								TRMBFStructBuffer = readshort trmbf #unsigned
							)
						)
						if TRMSHStructPolyGroup != 0 do (
							fseek trmsh (TRMSHFileStart + TRMSHStructPolyGroup) #seek_set
							PolyGroupStart = (ftell trmsh) + readlong trmsh
							fseek trmsh PolyGroupStart #seek_set
							PolyGroupCount = readlong trmsh
							
							fseek trmbf (TRMBFFileStart + TRMBFStructBuffer) #seek_set
							VertBufferStart = (ftell trmbf) + readlong trmbf
							VertBufferCount = readlong trmbf

							for x = 1 to PolyGroupCount do (
								Vert_array = #()
								Normal_array = #()
								Color_array = #()
								Alpha_array = #()
								UV_array = #()
								UV2_array = #()
								UV3_array = #()
								UV4_array = #()
								Face_array = #()
								FaceMatID_array = #()
								B1_array = #()
								W1_array = #()
								Weight_array = #()
								Morphs_array = #()
								MorphName_array = #()
								GroupOffset_array = #()
								PolyGroupName = ""; VisGroupName = ""; VertBufferStride = 0; MatID = 1
								PositionsFmt = "None"; NormalsFmt = "None"; BinormalsFmt = "None"
								TangentsFmt = "None"; Tangents2Fmt = "None"; Tangents3Fmt = "None"
								UVsFmt = "None"; UVs2Fmt = "None"; UVs3Fmt = "None"; UVs4Fmt = "None"
								ColorsFmt = "None"; Colors2Fmt = "None"; BonesFmt = "None"; WeightsFmt = "None"; SVUnkFmt = "None"

								PolyGroupOffset = (ftell trmsh) + readlong trmsh
								PolyGroupRet = ftell trmsh
								fseek trmsh PolyGroupOffset #seek_set
								printDebug ("PolyGroup offset #" + x as string + ": " + PolyGroupOffset as string)
								PolyGroupStruct = (ftell trmsh) - readlong trmsh
								fseek trmsh PolyGroupStruct #seek_set
								PolyGroupStructLen = readshort trmsh #unsigned
								case PolyGroupStructLen of (
									default:(throw ("Unexpected PolyGroup struct length!"))
									0x001E:(
										PolyGroupStructSectionLen = readshort trmsh #unsigned
										PolyGroupStructPtrPolyGroupName = readshort trmsh #unsigned
										PolyGroupStructPtrBBox = readshort trmsh #unsigned
										PolyGroupStructPtrUnkA = readshort trmsh #unsigned
										PolyGroupStructPtrVertBuff = readshort trmsh #unsigned
										PolyGroupStructPtrMatList = readshort trmsh #unsigned
										PolyGroupStructPtrUnkB = readshort trmsh #unsigned
										PolyGroupStructPtrUnkC = readshort trmsh #unsigned
										PolyGroupStructPtrUnkD = readshort trmsh #unsigned
										PolyGroupStructPtrUnkE = readshort trmsh #unsigned
										PolyGroupStructPtrUnkFloat = readshort trmsh #unsigned
										PolyGroupStructPtrUnkG = readshort trmsh #unsigned
										PolyGroupStructPtrMorphName = readshort trmsh #unsigned
										PolyGroupStructPtrVisGroupName = readshort trmsh #unsigned
										PolyGroupStructPtrUnkI = 0
										PolyGroupStructPtrGroupName = 0
									)
									0x0022:(
										-- Scarlet/Violet Only
										PolyGroupStructSectionLen = readshort trmsh #unsigned
										PolyGroupStructPtrPolyGroupName = readshort trmsh #unsigned
										PolyGroupStructPtrBBox = readshort trmsh #unsigned
										PolyGroupStructPtrUnkA = readshort trmsh #unsigned
										PolyGroupStructPtrVertBuff = readshort trmsh #unsigned
										PolyGroupStructPtrMatList = readshort trmsh #unsigned
										PolyGroupStructPtrUnkB = readshort trmsh #unsigned
										PolyGroupStructPtrUnkC = readshort trmsh #unsigned
										PolyGroupStructPtrUnkD = readshort trmsh #unsigned
										PolyGroupStructPtrUnkE = readshort trmsh #unsigned
										PolyGroupStructPtrUnkFloat = readshort trmsh #unsigned
										PolyGroupStructPtrUnkG = readshort trmsh #unsigned
										PolyGroupStructPtrMorphName = readshort trmsh #unsigned
										PolyGroupStructPtrVisGroupName = readshort trmsh #unsigned
										PolyGroupStructPtrUnkI = readshort trmsh #unsigned
										PolyGroupStructPtrGroupName = readshort trmsh #unsigned
									)
								)
								if PolyGroupStructPtrMatList != 0 do (
									fseek trmsh (PolyGroupOffset + PolyGroupStructPtrMatList) #seek_set
									MatOffset = (ftell trmsh) + readlong trmsh
									fseek trmsh MatOffset #seek_set
									MatCount = readlong trmsh
									for y = 1 to MatCount do (
										MatEntryOffset = (ftell trmsh) + readlong trmsh
										MatRet = ftell trmsh
										fseek trmsh MatEntryOffset #seek_set
										MatStruct = (ftell trmsh) - readlong trmsh
										fseek trmsh MatStruct #seek_set
										MatStructLen = readshort trmsh #unsigned
										case MatStructLen of (
											default:(throw ("Unexpected material struct length!"))
											0x000E:(
												MatStructSectionLen = readshort trmsh #unsigned
												MatStructPtrFacepointCount = readshort trmsh #unsigned
												MatStructPtrFacepointStart = readshort trmsh #unsigned
												MatStructPtrUnkC = readshort trmsh #unsigned
												MatStructPtrString = readshort trmsh #unsigned
												MatStructPtrUnkD = readshort trmsh #unsigned
											)
										)
										if MatStructPtrFacepointCount != 0 do (
											fseek trmsh (MatEntryOffset + MatStructPtrFacepointCount) #seek_set
											MatFacepointCount = (readlong trmsh / 3)
										)
										if MatStructPtrFacepointStart != 0 then (
											fseek trmsh (MatEntryOffset + MatStructPtrFacepointStart) #seek_set
											MatFacepointStart = (readlong trmsh / 3)
										) else (MatFacepointStart = 0)
										if MatStructPtrUnkC != 0 do (
											fseek trmsh (MatEntryOffset + MatStructPtrUnkC) #seek_set
											MatUnkC = readlong trmsh
										)
										if MatStructPtrString != 0 do (
											fseek trmsh (MatEntryOffset + MatStructPtrString) #seek_set
											MatNameOffset = (ftell trmsh) + readlong trmsh
											fseek trmsh MatNameOffset #seek_set
											MatNameLen = readlong trmsh
											MatName = ReadFixedString trmsh MatNameLen
										)
										if MatStructPtrUnkD != 0 do (
											fseek trmsh (MatEntryOffset + MatStructPtrUnkD) #seek_set
											MatUnkD = readlong trmsh
										)
										MatID = 1
										for z = 1 to MatData_array.count do (
											if MatData_array[z].MatName == MatName do (
												MatID = z
												exit
											)
										)
										for z = 1 to MatFacepointCount do (
											append FaceMatID_array MatID
										)
										printDebug ("Material " + MatName + ": FaceCount = " + MatFacepointCount as string + ", FaceStart = " + MatFacepointStart as string)
										fseek trmsh MatRet #seek_set
									)
								)
								if PolyGroupStructPtrPolyGroupName != 0 do (
									fseek trmsh (PolyGroupOffset + PolyGroupStructPtrPolyGroupName) #seek_set
									PolyGroupNameOffset = (ftell trmsh) + readlong trmsh; fseek trmsh PolyGroupNameOffset #seek_set
									PolyGroupNameLen = readlong trmsh
									PolyGroupName = ReadFixedString trmsh PolyGroupNameLen
									printDebug ("Building " + PolyGroupName + "...")
								)
								if PolyGroupStructPtrVisGroupName != 0 do (
									fseek trmsh (PolyGroupOffset + PolyGroupStructPtrVisGroupName) #seek_set
									VisGroupNameOffset = (ftell trmsh) + readlong trmsh; fseek trmsh VisGroupNameOffset #seek_set
									VisGroupNameLen = readlong trmsh
									VisGroupName = ReadFixedString trmsh VisGroupNameLen
									printDebug ("VisGroup = " + PolyGroupName)
								)
								if PolyGroupStructPtrMorphName != 0 do (
									fseek trmsh (PolyGroupOffset + PolyGroupStructPtrMorphName) #seek_set
									MorphNameHeaderOffset = (ftell trmsh) + readlong trmsh; fseek trmsh MorphNameHeaderOffset #seek_set
									MorphNameCount = readlong trmsh
									for x = 1 to MorphNameCount do (
										MorphNameHeaderOffset = (ftell trmsh) + readlong trmsh
										MorphRet = (ftell trmsh)
										fseek trmsh MorphNameHeaderOffset #seek_set
										MorphNameStruct = (ftell trmsh) - readlong trmsh
										fseek trmsh MorphNameStruct #seek_set
										MorphNameStructLen = readshort trmsh #unsigned
										case MorphNameStructLen of (
											default:(throw ("Unexpected morph name struct length!"))
											0x0008:(
												MorphNameStructSectionLen = readshort trmsh #unsigned
												MorphNameStructPtrID = readshort trmsh #unsigned
												MorphNameStructPtrName = readshort trmsh #unsigned
											)
										)
										fseek trmsh (MorphNameHeaderOffset + MorphNameStructPtrID) #seek_set
										MorphNameID = readlong trmsh
										fseek trmsh (MorphNameHeaderOffset + MorphNameStructPtrName) #seek_set
										MorphNameStart = (ftell trmsh) + readlong trmsh
										fseek trmsh MorphNameStart #seek_set
										MorphNameLen = readlong trmsh
										MorphName = ReadFixedString trmsh MorphNameLen
										append MorphName_array MorphName
										fseek trmsh MorphRet #seek_set
									)
								)
								if PolyGroupStructPtrGroupName != 0 do (
									-- Let's set this up and come back to it a bit later.
									fseek trmsh (PolyGroupOffset + PolyGroupStructPtrGroupName) #seek_set
									GroupNameHeaderOffset = (ftell trmsh) + readlong trmsh; fseek trmsh GroupNameHeaderOffset #seek_set
									GroupNameCount = readlong trmsh
									for x = 1 to GroupNameCount do (
										GroupNameOffset = (ftell trmsh) + readlong trmsh
										append GroupOffset_array GroupNameOffset
									)
								)
								if PolyGroupStructPtrVertBuff != 0 do (
									fseek trmsh (PolyGroupOffset + PolyGroupStructPtrVertBuff) #seek_set
									PolyGroupVertBuffOffset = (ftell trmsh) + readlong trmsh
									fseek trmsh PolyGroupVertBuffOffset #seek_set
									VertBuffCount = readlong trmsh
									VertBuffOffset = (ftell trmsh) + readlong trmsh
									fseek trmsh VertBuffOffset #seek_set
									VertBuffStruct = (ftell trmsh) - readlong trmsh
									fseek trmsh VertBuffStruct #seek_set
									VertBuffStructLen = readshort trmsh #unsigned
									case VertBuffStructLen of (
										default:(throw ("Unexpected vertex buffer struct length!"))
										0x0008:(
											VertBuffStructSectionLen = readshort trmsh #unsigned
											VertBuffStructPtrParam = readshort trmsh #unsigned
											VertBuffStructPtrB = readshort trmsh #unsigned
										)
									)
									if VertBuffStructPtrParam != 0 do (
										fseek trmsh (VertBuffOffset + VertBuffStructPtrParam) #seek_set
										VertBuffParamOffset = (ftell trmsh) + readlong trmsh
										fseek trmsh VertBuffParamOffset #seek_set
										VertBuffParamCount = readlong trmsh
										for y = 1 to VertBuffParamCount do (
											VertBuffParamOffset = (ftell trmsh) + readlong trmsh
											VertBuffParamRet = (ftell trmsh)
											fseek trmsh VertBuffParamOffset #seek_set
											VertBuffParamStruct = (ftell trmsh) - readlong trmsh
											fseek trmsh VertBuffParamStruct #seek_set
											VertBuffParamStructLen = readshort trmsh #unsigned
											case VertBuffParamStructLen of (
												default:(throw ("Unknown vertex buffer parameter struct length!"))
												0x000C:(
													VertBuffParamStructSectionLen = readshort trmsh #unsigned
													VertBuffParamPtrUnkA = readshort trmsh #unsigned
													VertBuffParamPtrType = readshort trmsh #unsigned
													VertBuffParamPtrLayer = readshort trmsh #unsigned
													VertBuffParamPtrFmt = readshort trmsh #unsigned
													VertBuffParamPtrPosition = 0
												)
												0x000E:(
													VertBuffParamStructSectionLen = readshort trmsh #unsigned
													VertBuffParamPtrUnkA = readshort trmsh #unsigned
													VertBuffParamPtrType = readshort trmsh #unsigned
													VertBuffParamPtrLayer = readshort trmsh #unsigned
													VertBuffParamPtrFmt = readshort trmsh #unsigned
													VertBuffParamPtrPosition = readshort trmsh #unsigned
												)
											)
											if VertBuffParamPtrType != 0 do (
												fseek trmsh (VertBuffParamOffset + VertBuffParamPtrType) #seek_set
												VertBuffParamType = readlong trmsh
											)
											if VertBuffParamPtrLayer != 0 then (
												fseek trmsh (VertBuffParamOffset + VertBuffParamPtrLayer) #seek_set
												VertBuffParamLayer = readlong trmsh
											) else (VertBuffParamLayer = 0)
											if VertBuffParamPtrFmt != 0 do (
												fseek trmsh (VertBuffParamOffset + VertBuffParamPtrFmt) #seek_set
												VertBuffParamFormat = readlong trmsh
											)
											if VertBuffParamPtrPosition != 0 then (
												fseek trmsh (VertBuffParamOffset + VertBuffParamPtrPosition) #seek_set
												VertBuffParamPosition = readlong trmsh
											) else (VertBuffParamPosition = 0)

											-- Types:
											-- 0x01: = Positions
											-- 0x02 = Normals
											-- 0x03 = Tangents
											-- 0x04 = Binormals
											-- 0x05 = Colors
											-- 0x06 = UVs
											-- 0x07 = NodeIDs
											-- 0x08 = Weights
											-- 0x09 = ?????? (Scarlet/Violet only)

											-- Formats:
											-- 0x14 = 4 bytes as float / R8_G8_B8_A8_UNSIGNED_NORMALIZED
											-- 0x16 = 4 bytes / W8_X8_Y8_Z8_UNSIGNED
											-- 0x24 = 1 long? (Scarlet/Violet only)
											-- 0x27 = 4 shorts as float / W16_X16_Y16_Z16_SIGNED_NORMALIZED
											-- 0x2B = 4 half-floats / W16_X16_Y16_Z16_FLOAT
											-- 0x30 = 2 floats / X32_Y32_FLOAT
											-- 0x33 = 3 floats / X32_Y32_Z32_FLOAT
											-- 0x36 = 4 floats / W32_X32_Y32_Z32_FLOAT 

											case VertBuffParamType of (
												default:(throw ("Unknown vertex type!"))
												0x01:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected positions layer!"))
														0:(
															case VertBuffParamFormat of (
																default:(throw ("Unexpected positions format!"))
																0x33:(PositionsFmt = "3Floats"; VertBufferStride = VertBufferStride + 0x0C)
															)
														)
													)
												)
												0x02:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected normals layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected normals format!"))
															0x2B:(NormalsFmt = "4HalfFloats"; VertBufferStride = VertBufferStride + 0x08)
															0x33:(NormalsFmt = "3Floats"; VertBufferStride = VertBufferStride + 0x0C)
															)
														)
													)
												)
												0x03:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected tangents layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected tangents format!"))
															0x2B:(TangentsFmt = "4HalfFloats"; VertBufferStride = VertBufferStride + 0x08)
															0x33:(TangentsFmt = "3Floats"; VertBufferStride = VertBufferStride + 0x0C)
															)
														)
														1:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected tangents (layer 2) format!"))
															0x2B:(Tangents2Fmt = "4HalfFloats"; VertBufferStride = VertBufferStride + 0x08)
															0x33:(Tangents2Fmt = "3Floats"; VertBufferStride = VertBufferStride + 0x0C)
															)
														)
														2:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected tangents (layer 3) format!"))
															0x2B:(Tangents3Fmt = "4HalfFloats"; VertBufferStride = VertBufferStride + 0x08)
															0x33:(Tangents3Fmt = "3Floats"; VertBufferStride = VertBufferStride + 0x0C)
															)
														)
													)
												)
												0x04:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected binormals layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected binormals format!"))
															0x2B:(BinormalsFmt = "4HalfFloats"; VertBufferStride = VertBufferStride + 0x08)
															0x33:(BinormalsFmt = "3Floats"; VertBufferStride = VertBufferStride + 0x0C)
															)
														)
													)
												)
												0x05:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected colors layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected colors format!"))
															0x14:(ColorsFmt = "4BytesAsFloat"; VertBufferStride = VertBufferStride + 0x04)
															0x36:(ColorsFmt = "4Floats"; VertBufferStride = VertBufferStride + 0x10)
															)
														)
														1:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected colors 2 format!"))
															0x14:(Colors2Fmt = "4BytesAsFloat"; VertBufferStride = VertBufferStride + 0x04)
															0x36:(Colors2Fmt = "4Floats"; VertBufferStride = VertBufferStride + 0x10)
															)
														)
													)
												)
												0x06:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected UVs layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected UVs format!"))
															0x30:(UVsFmt = "2Floats"; VertBufferStride = VertBufferStride + 0x08)
															)
														)
														1:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected UVs 2 format!"))
															0x30:(UVs2Fmt = "2Floats"; VertBufferStride = VertBufferStride + 0x08)
															)
														)
														2:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected UVs 3 format!"))
															0x30:(UVs3Fmt = "2Floats"; VertBufferStride = VertBufferStride + 0x08)
															)
														)
														3:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected UVs 4 format!"))
															0x30:(UVs4Fmt = "2Floats"; VertBufferStride = VertBufferStride + 0x08)
															)
														)
													)
												)
												0x07:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected node IDs layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected node IDs format!"))
															0x16:(BonesFmt = "4Bytes"; VertBufferStride = VertBufferStride + 0x04)
															)
														)
													)
												)
												0x08:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected weights layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected weights format!"))
															0x27:(WeightsFmt = "4ShortsAsFloat"; VertBufferStride = VertBufferStride + 0x08)
															)
														)
													)
												)
												0x09:(
													case VertBuffParamLayer of (
														default:(throw ("Unexpected ?????? layer!"))
														0:(
															case VertBuffParamFormat of (
															default:(throw ("Unexpected ?????? format!"))
															0x24:(SVUnkFmt = "1Long?"; VertBufferStride = VertBufferStride + 0x04)
															)
														)
													)
												)
											)
											fseek trmsh VertBuffParamRet #seek_set
										)
									)
								)
								append PolyGroup_array (PolyGroup_Struct PolyGroupName:PolyGroupName VisGroupName:VisGroupName VertBufferStride:VertBufferStride PositionsFmt:PositionsFmt NormalsFmt:NormalsFmt BinormalsFmt:BinormalsFmt TangentsFmt:TangentsFmt Tangents2Fmt:Tangents2Fmt Tangents3Fmt:Tangents3Fmt UVsFmt:UVsFmt UVs2Fmt:UVs2Fmt UVs3Fmt:UVs3Fmt UVs4Fmt:UVs4Fmt ColorsFmt:ColorsFmt Colors2Fmt:Colors2Fmt BonesFmt:BonesFmt WeightsFmt:WeightsFmt SVUnkFmt:SVUnkFmt)
								fseek trmsh PolyGroupRet #seek_set

								VertBufferOffset = (ftell trmbf) + readlong trmbf
								VertBufferRet = (ftell trmbf)
								fseek trmbf VertBufferOffset #seek_set
								VertBufferStruct = (ftell trmbf) - readlong trmbf; fseek trmbf VertBufferStruct #seek_set
								VertBufferStructLen = readshort trmbf #unsigned
								case VertBufferStructLen of (
									default:(throw ("Unexpected vertex buffer struct length!"))
									0x0008:(
										VertBufferStructSectionLength = readshort trmbf #unsigned
										VertBufferStructPtrFaces = readshort trmbf #unsigned
										VertBufferStructPtrVerts = readshort trmbf #unsigned
										VertBufferStructPtrGroups = 0
									)
									0x000A:(
										-- Scarlet/Violet Only
										VertBufferStructSectionLength = readshort trmbf #unsigned
										VertBufferStructPtrFaces = readshort trmbf #unsigned
										VertBufferStructPtrVerts = readshort trmbf #unsigned
										VertBufferStructPtrGroups = readshort trmbf #unsigned
									)
								)
								if VertBufferStructPtrFaces != 0 do (
									fseek trmbf (VertBufferOffset + VertBufferStructPtrFaces) #seek_set
									FaceBufferStart = (ftell trmbf) + readlong trmbf; fseek trmbf FaceBufferStart #seek_set
									FaceBufferCount = readlong trmbf
									for y = 1 to FaceBufferCount do (
										FaceBuffOffset = (ftell trmbf) + readlong trmbf
										FaceBuffRet = (ftell trmbf)
										fseek trmbf FaceBuffOffset #seek_set
										printDebug ("Facepoint " + x as string + " header: " + ftell trmbf as string)
										FaceBuffStruct = (ftell trmbf) - readlong trmbf; fseek trmbf FaceBuffStruct #seek_set
										FaceBuffStructLen = readshort trmbf #unsigned
										case FaceBuffStructLen of (
											default:(throw ("Unexpected face buffer struct length!"))
											0x0006:(
												FaceBufferStructSectionLength = readshort trmbf #unsigned
												FaceBufferStructPtr = readshort trmbf #unsigned
											)
										)
										if FaceBufferStructPtr != 0 do (
											fseek trmbf (FaceBuffOffset + FaceBufferStructPtr) #seek_set
											FacepointStart = (ftell trmbf) + readlong trmbf; fseek trmbf FacepointStart #seek_set
											FacepointByteCount = readlong trmbf
											printDebug ("Facepoint " + x as string + " start: " + ftell trmbf as string)
											if Vert_array.count > 65536 then (
												-- There might be a flag that determines the face length, but this works just as well.
												for v = 1 to (FacepointByteCount / 12) do (
													fa = readlong trmbf + 1
													fb = readlong trmbf + 1
													fc = readlong trmbf + 1
													append Face_array [fa,fb,fc]
												)
											) else (
												for v = 1 to (FacepointByteCount / 6) do (
													fa = readshort trmbf #unsigned + 1
													fb = readshort trmbf #unsigned + 1
													fc = readshort trmbf #unsigned + 1
													append Face_array [fa,fb,fc]
												)
											)
											printDebug ("Facepoint " + x as string + " end: " + ftell trmbf as string)
										)
										fseek trmbf FaceBuffRet #seek_set
									)
								)

								if VertBufferStructPtrVerts != 0 do (
									fseek trmbf (VertBufferOffset + VertBufferStructPtrVerts) #seek_set
									VertBufferSubStart = (ftell trmbf) + readlong trmbf; fseek trmbf VertBufferSubStart #seek_set
									VertBufferSubCount = readlong trmbf
									for y = 1 to VertBufferSubCount do (
										VertBufferSubOffset = (ftell trmbf) + readlong trmbf
										VertBufferSubRet = (ftell trmbf)
										fseek trmbf VertBufferSubOffset #seek_set
										if y == 1 then (
											printDebug ("Vertex buffer " + x as string + " header: " + (ftell trmbf) as string)
										) else (
											printDebug ("Vertex buffer " + x as string + " morph " + (y - 1) as string + " header: " + (ftell trmbf) as string)
										)
										VertBufferSubStruct = (ftell trmbf) - readlong trmbf; fseek trmbf VertBufferSubStruct #seek_set
										VertBufferSubStructLen = readshort trmbf #unsigned
										case VertBufferSubStructLen of (
											default:(throw ("Unexpected vertex buffer struct length!"))
											0x0006:(
												VertBufferSubStructSectionLength = readshort trmbf #unsigned
												VertBufferSubStructPtr = readshort trmbf #unsigned
											)
										)
										if VertBufferSubStructPtr != 0 do (
											fseek trmbf (VertBufferSubOffset + VertBufferSubStructPtr) #seek_set
											VertBufferStart = (ftell trmbf) + readlong trmbf; fseek trmbf VertBufferStart #seek_set
											VertBufferByteCount = readlong trmbf
											if y == 1 then (
												printDebug ("Vertex buffer " + x as string + " start: " + (ftell trmbf) as string)
												for v = 1 to (VertBufferByteCount / PolyGroup_array[x].VertBufferStride) do (
													case PolyGroup_array[x].PositionsFmt of (
														default:(throw ("Unknown positions type!"))
														"4HalfFloats":(
															vx = readhalffloat trmbf
															vy = readhalffloat trmbf
															vz = readhalffloat trmbf
															vq = readhalffloat trmbf
															if ArceusScale == true do (vx = vx * 100; vy = vy * 100; vz = vz * 100)
														)
														"3Floats":(
															vx = readfloat trmbf
															vy = readfloat trmbf
															vz = readfloat trmbf
															if ArceusScale == true do (vx = vx * 100; vy = vy * 100; vz = vz * 100)
														)
													)
													case PolyGroup_array[x].NormalsFmt of (
														default:(throw ("Unknown normals type!"))
														"4HalfFloats":(
															nx = readhalffloat trmbf
															ny = readhalffloat trmbf
															nz = readhalffloat trmbf
															nq = readhalffloat trmbf
														)
														"3Floats":(
															nx = readfloat trmbf
															ny = readfloat trmbf
															nz = readfloat trmbf
														)
													)
													case PolyGroup_array[x].TangentsFmt of (
														default:(throw ("Unknown tangents type!"))
														"None":()
														"4HalfFloats":(
															tanx = readhalffloat trmbf
															tany = readhalffloat trmbf
															tanz = readhalffloat trmbf
															tanq = readhalffloat trmbf
														)
														"3Floats":(
															tanx = readfloat trmbf
															tany = readfloat trmbf
															tanz = readfloat trmbf
														)
													)
													case PolyGroup_array[x].Tangents2Fmt of (
														default:(throw ("Unknown tangents (layer 2) type!"))
														"None":()
														"4HalfFloats":(
															tan2x = readhalffloat trmbf
															tan2y = readhalffloat trmbf
															tan2z = readhalffloat trmbf
															tan2q = readhalffloat trmbf
														)
														"3Floats":(
															tan2x = readfloat trmbf
															tan2y = readfloat trmbf
															tan2z = readfloat trmbf
														)
													)
													case PolyGroup_array[x].Tangents3Fmt of (
														default:(throw ("Unknown tangents (layer 3) type!"))
														"None":()
														"4HalfFloats":(
															tan3x = readhalffloat trmbf
															tan3y = readhalffloat trmbf
															tan3z = readhalffloat trmbf
															tan3q = readhalffloat trmbf
														)
														"3Floats":(
															tan3x = readfloat trmbf
															tan3y = readfloat trmbf
															tan3z = readfloat trmbf
														)
													)
													case PolyGroup_array[x].BinormalsFmt of (
														default:(throw ("Unknown binormals type!"))
														"None":()
														"4HalfFloats":(
															binx = readhalffloat trmbf
															biny = readhalffloat trmbf
															binz = readhalffloat trmbf
															binq = readhalffloat trmbf
														)
														"3Floats":(
															binx = readfloat trmbf
															biny = readfloat trmbf
															binz = readfloat trmbf
														)
													)
													case PolyGroup_array[x].UVsFmt of (
														default:(throw ("Unknown UVs type!"))
														"None":(tu = 0; tv = 0)
														"2Floats":(
															tu = readfloat trmbf
															tv = readfloat trmbf
														)					
													)
													case PolyGroup_array[x].UVs2Fmt of (
														default:(throw ("Unknown UV2s type!"))
														"None":()
														"2Floats":(
															tu2 = readfloat trmbf
															tv2 = readfloat trmbf
															append UV2_array [tu2,tv2,0]
														)
													)
													case PolyGroup_array[x].UVs3Fmt of (
														default:(throw ("Unknown UV3s type!"))
														"None":()
														"2Floats":(
															tu3 = readfloat trmbf
															tv3 = readfloat trmbf
															append UV3_array [tu3,tv3,0]
														)
													)
													case PolyGroup_array[x].UVs4Fmt of (
														default:(throw ("Unknown UV4s type!"))
														"None":()
														"2Floats":(
															tu4 = readfloat trmbf
															tv4 = readfloat trmbf
															append UV4_array [tu4,tv4,0]
														)
													)
													case PolyGroup_array[x].ColorsFmt of (
														default:(throw ("Unknown colors type!"))
														"None":(colorr = 255; colorg = 255; colorb = 255; colora = 1)
														"4BytesAsFloat":(
															colorr = readbyte trmbf #unsigned
															colorg = readbyte trmbf #unsigned
															colorb = readbyte trmbf #unsigned
															colora = readbyte trmbf #unsigned as float / 255
														)
														"4Floats":(
															colorr = readfloat trmbf * 255
															colorg = readfloat trmbf * 255
															colorb = readfloat trmbf * 255
															colora = readfloat trmbf
														)
													)
													case PolyGroup_array[x].Colors2Fmt of (
														default:(throw ("Unknown colors 2 type!"))
														"None":(colorr2 = 255; colorg2 = 255; colorb2 = 255; colora2 = 1)
														"4BytesAsFloat":(
															colorr2 = readbyte trmbf #unsigned
															colorg2 = readbyte trmbf #unsigned
															colorb2 = readbyte trmbf #unsigned
															colora2 = readbyte trmbf #unsigned as float / 255
														)
														"4Floats":(
															colorr2 = readfloat trmbf * 255
															colorg2 = readfloat trmbf * 255
															colorb2 = readfloat trmbf * 255
															colora2 = readfloat trmbf
														)
													)
													case PolyGroup_array[x].BonesFmt of (
														default:(throw ("Unknown bones type!"))
														"None":(Bone1 = 1; Bone2 = 0; Bone3 = 0; Bone4  = 0)
														"4Bytes":(
															Bone1 = readbyte trmbf #unsigned + 1
															Bone2 = readbyte trmbf #unsigned + 1
															Bone3 = readbyte trmbf #unsigned + 1
															Bone4 = readbyte trmbf #unsigned + 1
														)
													)
													case PolyGroup_array[x].WeightsFmt of (
														default:(throw ("Unknown weights type!"))
														"None":(Weight1 = 1; Weight2 = 0; Weight3 = 0; Weight4 = 0)
														"4ShortsAsFloat":(
															Weight1 = (readshort trmbf #unsigned as float) / 65535
															Weight2 = (readshort trmbf #unsigned as float) / 65535
															Weight3 = (readshort trmbf #unsigned as float) / 65535
															Weight4 = (readshort trmbf #unsigned as float) / 65535
														)
													)
													case PolyGroup_array[x].SVUnkFmt of (
														default:(throw ("Unknown ?????? type!"))
														"None":()
														"1Long?":(
															SVUnk = readlong trmbf #unsigned
														)
													)

													append Vert_array [vx,vy,vz]
													append Normal_array [nx,ny,nz]
													case VertColors of (
														1:(append Color_array [colorr,colorg,colorb]; append Alpha_array colora)
														2:(append Color_array [colorr2,colorg2,colorb2]; append Alpha_array colora2)
													)					
													append UV_array [tu,tv,0]
													append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
													append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)

												)
												printDebug ("Vertex buffer " + x as string + " end: " + (ftell trmbf) as string)

												for b = 1 to W1_array.count do (
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

												msh = mesh vertices:Vert_array faces:Face_array
												msh.numTVerts = Vert_array.count
												buildTVFaces msh
												msh.name = (PolyGroup_array[x].PolyGroupName as string)
												msh.material = multimat
												for j = 1 to UV_array.count do setTVert msh j UV_array[j]
												if UV2_array.count > 0 do (
													meshop.setNumMaps msh 3 keep:true
													for i = 1 to UV2_array.count do (
														meshop.setMapVert msh 2 i UV2_array[i]
													)
												)
												if UV3_array.count > 0 do (
													meshop.setNumMaps msh 4 keep:true
													for i = 1 to UV3_array.count do (
														meshop.setMapVert msh 3 i UV3_array[i]
													)
												)
												if UV4_array.count > 0 do (
													meshop.setNumMaps msh 5 keep:true
													for i = 1 to UV4_array.count do (
														meshop.setMapVert msh 4 i UV4_array[i]
													)
												)
												for j = 1 to Face_array.count do (	
													setTVFace msh j Face_array[j]
													setFaceMatID msh j FaceMatID_array[j]
												)
												if VertColors != 3 do (
													setNumCPVVerts msh msh.numTVerts
													setCVertMode msh true
													setShadeCVerts msh true
													for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
													for j = 1 to Alpha_array.count do (meshop.setVertAlpha msh -2 j Alpha_array[j])
												)
												for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
												if PolyGroup_array[x].VisGroupName != "" do (
													msh.parent = getnodebyname PolyGroup_array[x].VisGroupName
													if msh.parent != undefined do (msh.transform = msh.parent.transform)
												)
												max modify mode
												select msh
												addmodifier msh (Edit_Normals ()) ui:off
												msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
												EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
												EN_setNormal = msh.Edit_Normals.SetNormal
												normID = #{}
												for v = 1 to Normal_array.count do (
													free normID
													EN_convertVS #{v} &normID
													for id in normID do EN_setNormal id Normal_array[v]
												)
												CollapseStack $
												if BoneRigArray.count > 0 do (
													max modify mode
													select msh

													skinMod = skin ()
													boneIDMap = #()
													addModifier msh skinMod
													msh.Skin.weightAllVertices = false

													for i = 1 to BoneRigArray.count do (
														maxbone = getnodebyname BoneRigArray[i]
														if maxbone != undefined do (
															if i != BoneRigArray.count then (
																skinOps.addBone skinMod maxbone 0
															) else (
																skinOps.addBone skinMod maxbone 1
															)
														)
													)

													local numSkinBones = skinOps.GetNumberBones skinMod
													for i = 1 to numSkinBones do (
														local boneName = skinOps.GetBoneName skinMod i 0
														for j = 1 to BoneRigArray.count do
														(
															if boneName == BoneRigArray[j] then
															(
																boneIDMap[j] = i
																j = BoneRigArray.count + 1
															)
														)
													) -- This fixes bone ordering in 3DS Max 2012. Thanks to sunnydavis for the fix!

													modPanel.setCurrentObject skinMod
													if (skinOps.GetNumberBones skinMod) > 0 then (
														for i = 1 to Vert_array.count do (
															skinOps.SetVertexWeights skinMod i 1 1
															skinOps.unnormalizeVertex skinMod i true 
															skinOps.SetVertexWeights skinMod i 1 0
														)
															skinOps.RemoveZeroWeights skinMod
														for i = 1 to Vert_array.count do (
															skinOps.unnormalizeVertex skinMod i false
														) -- These fix broken rigging for 3DS Max 2015 and above.

														for i = 1 to Weight_array.count do (
															w = Weight_array[i]
															bi = #() --bone index array
															wv = #() --weight value array
															
															for j = 1 to w.boneids.count do (
																boneid = w.boneids[j]
																weight = w.weights[j]
																if boneIDMap[boneid] != undefined then (
																	append bi boneIDMap[boneid]
																	append wv weight
																) else (
																	append bi 1
																	append wv 0
																)
															)
															skinOps.ReplaceVertexWeights skinMod i bi wv
														)
													) else (
														if x == 1 do (
															if TRSKLBoneAdjust > 1 do (
																case CharaCheck of (
																	default:(print "Can't add bones! Please import 'cc_base0001_00_young_m' or 'cc_base' first, then try again.")
																	"FlorianJuliana":(print ("Can't add bones! Please import both 'p0_base' and 'p0_face0000_00_face00' first, then try again."))
																	"Rei":(print "Can't add bones! Please import both 'p2_base0001_00_default' and 'p1_face0001_00_default' first, then try again.")
																	"Akari":(print "Can't add bones! Please import both 'p2_base0001_00_default' and 'p2_face0001_00_default' first, then try again.")
																)
															)
														)
													)
												)
											) else (
												printDebug ("Vertex buffer " + x as string + " morph " + (y - 1) as string + " start: " + (ftell trmbf) as string)
												MorphVert_array = #()
												MorphNormal_array = #()
												for v = 1 to (VertBufferByteCount / 0x1C) do (
													-- Morphs always seem to use this setup.
													vx = readfloat trmbf
													vy = readfloat trmbf
													vz = readfloat trmbf
													nx = readhalffloat trmbf
													ny = readhalffloat trmbf
													nz = readhalffloat trmbf
													nq = readhalffloat trmbf
													tanx = readhalffloat trmbf
													tany = readhalffloat trmbf
													tanz = readhalffloat trmbf
													tanq = readhalffloat trmbf
													if ArceusScale == true do (vx = vx * 100; vy = vy * 100; vz = vz * 100)
													append MorphVert_array [vx,vy,vz]
													append MorphNormal_array [nx,ny,nz]
												)
												printDebug ("Vertex buffer " + x as string + " morph " + (y - 1) as string + " end: " + (ftell trmbf) as string)

												-- Simplified version of mesh importing, disregard UVs and bones to speed things up since these are meant to be assigned to a Morpher.
												msh = mesh vertices:MorphVert_array faces:Face_array
												msh.numTVerts = MorphVert_array.count
												buildTVFaces msh
												msh.name = (MorphName_array[y - 1])
												for j = 1 to Face_array.count do (	
													setTVFace msh j Face_array[j]
													setFaceMatID msh j FaceMatID_array[j]
												)
												for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
												if PolyGroup_array[x].VisGroupName != "" do (
													msh.parent = getnodebyname PolyGroup_array[x].VisGroupName
													if msh.parent != undefined do (msh.transform = msh.parent.transform)
												)
												max modify mode
												select msh
												addmodifier msh (Edit_Normals ()) ui:off
												msh.Edit_Normals.MakeExplicit selection:#{1..MorphNormal_array.count}
												EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
												EN_setNormal = msh.Edit_Normals.SetNormal
												normID = #{}
												for v = 1 to MorphNormal_array.count do (
													free normID
													EN_convertVS #{v} &normID
													for id in normID do EN_setNormal id MorphNormal_array[v]
												)
												CollapseStack $
												append Morphs_array msh
											)
										)
										fseek trmbf VertBufferSubRet #seek_set
									)
									if VertBufferSubCount > 1 do (
										morphintime = getNodeByName PolyGroupName
										select morphintime
										MorphMod = morpher()
										addModifier $ MorphMod
										$.morpher.autoload_of_targets = 1
										for b = 1 to MorphName_array.count Do (
											-- Add all applicable morphs, then delete the temporary meshes to reduce clutter.
											WM3_MC_BuildFromNode $.morpher b Morphs_array[b]
											delete Morphs_array[b]
										)
									)
								)

								if VertBufferStructPtrGroups != 0 do (
									fseek trmbf (VertBufferOffset + VertBufferStructPtrGroups) #seek_set
									GroupsStart = (ftell trmbf) + readlong trmbf; fseek trmbf GroupsStart #seek_set
									GroupsCount = readlong trmbf
									if GroupsCount > 0 do (
										MorphNameNext = 1
										for y = 1 to GroupsCount do (
											fseek trmsh GroupOffset_array[y] #seek_set
											GroupNameStruct = (ftell trmsh) - readlong trmsh
											fseek trmsh GroupNameStruct #seek_set
											GroupNameStructLen = readshort trmsh #unsigned
											case GroupNameStructLen of (
												default:(throw ("Unexpected morph group buffer struct length!"))
												0x000A:(
													GroupStructSectionLen = readshort trmsh #unsigned
													GroupStructPtrParamA = readshort trmsh #unsigned
													GroupStructPtrParamMorph = readshort trmsh #unsigned
													GroupStructPtrParamName = readshort trmsh #unsigned
												)
											)

											fseek trmsh (GroupOffset_array[y] + GroupStructPtrParamName) #seek_set
											GroupNameOffset = (ftell trmsh) + readlong trmsh
											fseek trmsh GroupNameOffset #seek_set
											GroupNameLen = readlong trmsh
											GroupName = ReadFixedString trmsh GroupNameLen

											fseek trmsh (GroupOffset_array[y] + GroupStructPtrParamMorph) #seek_set
											GroupMorphOffset = (ftell trmsh) + readlong trmsh
											fseek trmsh GroupMorphOffset #seek_set
											GroupMorphNameCount = readlong trmsh
											for y = 1 to GroupMorphNameCount do (
												GroupMorphNameOffset = (ftell trmsh) + readlong trmsh
												GroupMorphNameRet = (ftell trmsh)
												fseek trmsh GroupMorphNameOffset #seek_set

												GroupNameMorphStruct = (ftell trmsh) - readlong trmsh
												fseek trmsh GroupNameMorphStruct #seek_set
												GroupNameMorphStructLen = readshort trmsh #unsigned
												case GroupNameMorphStructLen of (
													default:(throw ("Unexpected morph group buffer struct length!"))
													0x000A:(
														GroupNameMorphStructSectionLen = readshort trmsh #unsigned
														GroupNameMorphStructPtrParamID = readshort trmsh #unsigned
														GroupNameMorphStructPtrParamName = readshort trmsh #unsigned
														GroupNameMorphStructPtrParamFlag = readshort trmsh #unsigned
													)
												)
												fseek trmsh (GroupMorphNameOffset + GroupNameMorphStructPtrParamName) #seek_set
												GroupMorphNameOffset = (ftell trmsh) + readlong trmsh
												fseek trmsh GroupMorphNameOffset #seek_set
												GroupMorphNameLen = readlong trmsh
												GroupMorphName = ReadFixedString trmsh GroupMorphNameLen
												append MorphName_array GroupMorphName
												fseek trmsh GroupMorphNameRet #seek_set
											)

											MorphVertIDs_array = #()
											GroupOffset = (ftell trmbf) + readlong trmbf
											GroupRet = (ftell trmbf)
											fseek trmbf GroupOffset #seek_set
											GroupStruct = (ftell trmbf) - readlong trmbf
											fseek trmbf GroupStruct #seek_set
											GroupStructLen = readshort trmbf #unsigned
											case GroupStructLen of (
												default:(throw ("Unexpected morph group buffer struct length!"))
												0x0006:(
													GroupStructSectionLen = readshort trmbf #unsigned
													GroupStructPtrParam = readshort trmbf #unsigned
												)
											)
											fseek trmbf (GroupOffset + GroupStructPtrParam) #seek_set
											GroupMorphsOffset = (ftell trmbf) + readlong trmbf
											fseek trmbf GroupMorphsOffset #seek_set
											GroupMorphsCount = readlong trmbf
											printDebug ("Group " + z as string + " header start: " + GroupMorphsOffset as string)

											for y = 1 to GroupMorphsCount do (
												MorphBufferGroupsOffset = (ftell trmbf) + readlong trmbf
												MorphBufferGroupsRet = (ftell trmbf)
												fseek trmbf MorphBufferGroupsOffset #seek_set
												printDebug ("Group " + z as string + " morph " + (y - 1) as string + " start: " + (ftell trmbf) as string)
												MorphBufferStruct = (ftell trmbf) - readlong trmbf
												fseek trmbf MorphBufferStruct #seek_set
												MorphBufferStructLen = readshort trmbf #unsigned
												case MorphBufferStructLen of (
													default:(throw ("Unexpected group sub buffer struct length!"))
													0x0006:(
														MorphBufferStructSectionLen = readshort trmbf #unsigned
														MorphBufferStructPtrParam = readshort trmbf #unsigned
													)
												)
												fseek trmbf (MorphBufferGroupsOffset + MorphBufferStructPtrParam) #seek_set
												MorphBufferGroupsSubOffset = (ftell trmbf) + readlong trmbf
												MorphBufferGroupsByteCount = readlong trmbf
												if y == 1 then (
													-- TODO: Are the "-1" IDs important? If so, what are they used for?
													for v = 1 to (MorphBufferGroupsByteCount / 0x04) do (
														MorphVertID = readlong trmbf + 1
														append MorphVertIDs_array MorphVertID
													)
												) else (
													MorphVert_array = #()
													MorphNormal_array = #()
													for v = 1 to Vert_array.count do (
														append MorphVert_array Vert_array[v]
														append MorphNormal_array Normal_array[v]
													)
													for v = 1 to (MorphBufferGroupsByteCount / 0x1C) do (
														-- Morphs always seem to use this setup.
														vx = readfloat trmbf
														vy = readfloat trmbf
														vz = readfloat trmbf
														nx = readhalffloat trmbf
														ny = readhalffloat trmbf
														nz = readhalffloat trmbf
														nq = readhalffloat trmbf
														tanx = readhalffloat trmbf
														tany = readhalffloat trmbf
														tanz = readhalffloat trmbf
														tanq = readhalffloat trmbf
														if ArceusScale == true do (vx = vx * 100; vy = vy * 100; vz = vz * 100)
														-- Unlike the earlier ones, these are treated as "delta" positions instead of being absolute.
														if MorphVertIDs_array[v] != 0 do (
															MorphVert_array[MorphVertIDs_array[v]] = [Vert_array[MorphVertIDs_array[v]].x + vx,Vert_array[MorphVertIDs_array[v]].y + vy,Vert_array[MorphVertIDs_array[v]].z + vz]
															MorphNormal_array[MorphVertIDs_array[v]] = [Normal_array[MorphVertIDs_array[v]].x + nx,Normal_array[MorphVertIDs_array[v]].y + ny,Normal_array[MorphVertIDs_array[v]].z + nz]
														)
													)
													printDebug ("Group " + z as string + " morph " + (y - 1) as string + " end: " + (ftell trmbf) as string)

													-- Simplified version of mesh importing, disregard UVs and bones to speed things up since these are meant to be assigned to a Morpher.
													-- The game intends for these to be split between multiple groups, but we're gonna stuff them all into a single model for convenience's sake.
													msh = mesh vertices:MorphVert_array faces:Face_array
													msh.numTVerts = MorphVert_array.count
													buildTVFaces msh
													msh.name = MorphName_array[MorphNameNext]
													MorphNameNext = MorphNameNext + 1
													for j = 1 to Face_array.count do (	
														setTVFace msh j Face_array[j]
														setFaceMatID msh j FaceMatID_array[j]
													)
													for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1
													if PolyGroup_array[x].VisGroupName != "" do (
														msh.parent = getnodebyname PolyGroup_array[x].VisGroupName
														if msh.parent != undefined do (msh.transform = msh.parent.transform)
													)
													max modify mode
													select msh
													addmodifier msh (Edit_Normals ()) ui:off
													msh.Edit_Normals.MakeExplicit selection:#{1..MorphNormal_array.count}
													EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
													EN_setNormal = msh.Edit_Normals.SetNormal
													normID = #{}
													for v = 1 to MorphNormal_array.count do (
														free normID
														EN_convertVS #{v} &normID
														for id in normID do EN_setNormal id MorphNormal_array[v]
													)
													CollapseStack $
													append Morphs_array msh
												)
												fseek trmbf MorphBufferGroupsRet #seek_set
											)
											fseek trmbf GroupRet #seek_set
										)
										morphintime = getNodeByName PolyGroupName
										select morphintime
										MorphMod = morpher()
										addModifier $ MorphMod
										$.morpher.autoload_of_targets = 1
										for b = 1 to MorphName_array.count Do (
											-- Add all applicable morphs, then delete the temporary meshes to reduce clutter.
											WM3_MC_BuildFromNode $.morpher b Morphs_array[b]
											delete Morphs_array[b]
										)
									)
								)

								fseek trmbf VertBufferRet #seek_set
								
							)
							printDebug ("--------------------")
						)
					)
					fclose trmsh
					fclose trmbf
				) else (
					print ("Couldn't find " + TRMSHLODs_array[w] + "!")
				)
			)

			Print ("Done! ("+((((timestamp())-st)*0.001)as string)+" Seconds)")
		)
	)

)

CreateDialog ModelImporter