-- Compile Heart ISM2 model importer by Random Talking Bush, based on howfie's Lightwave importer.
-- If there are any problems, please contact me at The VG Resource (Random Talking Bush), Steam, Twitter, Tumblr or XeNTaX (RandomTBush) so I can fix it up ASAP.

-- Changelog:
-- September 26th, 2017:
-- Fixed a script error caused by my own stupidity, preventing half of the script from working correctly!

-- August 21st, 2017:
-- Added a few more options for DDS/PNG toggle, folder path, and model scale (100x by default)
-- Added option to output face.anm information.
-- Merged the Console / PC and debug versions of the script all together.
-- Single-bind objects will now rig themselves to the first bone.
-- Re-implemented vertex alphas.
-- Fixed models with invalid bone IDs not loading (e.g. Harley's model in FFF:ADF), and also prints warning messages to the console.
-- Fixed certain models using the wrong material IDs (e.g. Dark Orange's wings in MDNVII).

rollout ISM2Importer "Compile Heart ISM2 model importer" width:525 height:160
(
	groupBox OptionsBox pos:[7,2] width:510 height:90
	label lblDisclaimer "This script was written by Random Talking Bush, based on the LightWave importer by howfie. If you use it, consider giving thanks to Idea Factory, Compile Heart, howfie and myself. If something doesn't work right, please contact me on The VG Resource (Random Talking Bush), Twitter, Tumblr or Steam (RandomTBush) so that any problems can be fixed." pos:[7,97] width:(ISM2Importer.width-16) height:80
	button btnImport "Import ISM2" pos:[15,15] width:135 height:30
	button btnFaceANM "Parse Face.ANM" pos:[15,52] width:135 height:30 tooltip: "This will output offsets and such from any face.anm file to the Listener, for use with face texture assembly. Note that it assumes the face textures are 1024x1024."
	spinner spnModelScale "Model Scale:" width:85 pos:[365,25] range: [1,99999,100]
	checkbox tglVertColors "Enable vertex colours?" pos:[320,45] tooltip: "Enable this to import the vertex colouring. Models from older games like Neptunia mk2 and Victory don't use vertex colours, so this option won't change anything for those." checked: true
	checkbox tglDebug "Print debug information to Listener" pos:[320,65] width:185
	radiobuttons tglTexFormat "Texture format:" labels:#("DDS","PNG") pos:[160,17] height:10 columns:2 default:1
	radiobuttons tglTexPath "Texture path:" labels:#("TEXTURE\001","Relative") pos:[160,52] height:10 columns:2 default:1
	
	label lblUpdate "(Updated: 09-26-2017)" pos:[ISM2Importer.width-115,ISM2Importer.height-19]

fn floatSwap2 f = (
	i = bit.floatAsInt f
	h = bit.intashex i
	while h.count < 8 do h = "0" + h
	
	s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
	bit.intAsFloat (bit.hexasint s)
)	

fn convertTo32 input16 = (
	inputAsInt = input16
	sign = bit.get inputAsInt 16
	exponent = (bit.shift (bit.and inputAsInt (bit.hexasint "7C00")) -10) as integer - 16
	fraction = bit.and inputAsInt (bit.hexasint "03FF")
	if sign==true then sign = 1 else sign = 0
	exponentF = exponent + 127
	--Output 32 bit integer representing a 32 bit float
	outputAsFloat = bit.or (bit.or (bit.shift fraction 13) (bit.shift exponentF 23)) (bit.shift sign 31)
	-- The line below is to fix rounding down to 0 properly for rigging.
	if outputAsFloat == 931135488 do(outputAsFloat = 0)
	--Output Check
	return bit.intasfloat outputasfloat
)

fn readHalfFloat fstream = (
return convertTo32(readshort fstream)
)

fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)

fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)

fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)

fn ReadBEHalfFloat fstream = (
return convertTo32(readBEword fstream)
)

fn printDebug pr = (if tglDebug.state do print(pr))

on btnImport pressed do(
fname = getOpenFileName \ 
caption:"Compile Heart ISM2 Model File" \
types:"Compile Heart ISM2 Model File(*.ism2)|*.ism2" \
historyCategory:"CompileHeartISM1ObjectPresets"
local ModelScale = spnModelScale.value
local VertColors = tglVertColors.checked
local TexFormat = tglTexFormat.state
local TexPath = tglTexPath.state

if fname != undefined do(
f = fopen fname "rb"
p = getFilenamePath fname -- return the path "c:\\test\\"
g = getFilenameFile fname -- return the file "test"
clearlistener()
st = timestamp() --get start time in milliseconds

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

MultiMat = #()
Mat = #()
MatTotal = #()
tm = #()
tfm = #()
BNArr = #()
BNArrRig = #()
Vert_array = #()
Normal_array = #()
Normal2_array = #()
UV_array = #()
Color_array = #()
Alpha_array = #()
W1_array = #()
B1_array = #()
Weight_array = #()
Face_array = #()
FaceTex_array = #()
String_array = #()
BoneTotal = #()
TextureName_array = #()
TexturePath_array = #()
MatName_array = #()
MatTexName_array = #()
SurfaceName_array = #()
PolyNum = 1

ISM2 = readlong f #unsigned
if ISM2 == 843928393 then(
fseek f 0x14 #seek_set
EndianCheck = readlong f #unsigned
fseek f 0x04 #seek_set
-- disableSceneRedraw()
if EndianCheck > 0 and EndianCheck < 65535 then(
VersionA = readbyte f #unsigned
VersionB = readbyte f #unsigned
VersionC = readbyte f #unsigned
VersionD = readbyte f #unsigned
header3 = readlong f #unsigned
header4 = readlong f #unsigned
filesize = readlong f #unsigned
sectioncount = readlong f #unsigned
header7 = readlong f #unsigned
header8 = readlong f #unsigned
SectionType_array = #()
SectionOffset_array = #()
for b = 1 to SectionCount do(
SectionType = readlong f #unsigned
printDebug("SectionType: " + SectionType as string)
SectionOffset = readlong f #unsigned
append SectionType_array SectionType
append SectionOffset_array SectionOffset
)

for b = 1 to SectionCount do(
fseek f SectionOffset_array[b] #seek_set
	
if SectionType_array[b] == 3 do(
printDebug("Bone data is located at 0x" + (bit.intAsHex(ftell f))as string)
sectiontype = readlong f #unsigned
bonedataheaderlength = readlong f #unsigned
bonetotal = readlong f #unsigned
bonedatastring1 = readlong f #unsigned + 1
bonedatastring1 = String_array[bonedatastring1]
bonedatastring2 = readlong f #unsigned + 1
bonedatastring2 = String_array[bonedatastring2]
BoneOffset_array = #()
for c = 1 to BoneTotal do(
BoneOffset = readlong f #unsigned
append BoneOffset_array BoneOffset
)
for c = 1 to BoneTotal do(
fseek f BoneOffset_array[c] #seek_set
sectiontype = readlong f #unsigned
boneheaderlength = readlong f #unsigned
boneheadertotal = readlong f #unsigned
bonename1 = readlong f #unsigned + 1
bonename1 = String_array[bonename1]
bonename2 = readlong f #unsigned + 1
bonename2 = String_array[bonename2]
boneheaderstuff1 = readlong f #unsigned
boneheaderstuff2 = readlong f #unsigned
boneparentoffset = readlong f #unsigned
BoneParent = -1
for d = 1 to BoneTotal do(
	if boneparentoffset == BoneOffset_array[d] do(BoneParent = d)
)
boneheaderstuff4 = readlong f #unsigned
boneheaderstuff5 = readlong f #unsigned
boneheaderstuff6 = readlong f #unsigned
BoneIDNum = readlong f + 1
boneheaderstuff8 = readlong f #unsigned
boneheaderstuff9 = readlong f #unsigned
boneheaderstuff10 = readlong f #unsigned
boneheaderstuff11 = readlong f #unsigned
BoneHeader_array = #()
for d = 1 to BoneHeaderTotal do(
BoneHeader = readlong f #unsigned 
append BoneHeader_array BoneHeader
)
for d = 1 to BoneHeaderTotal do(
fseek f BoneHeader_array[d] #seek_set
sectiontype = readlong f #unsigned

if SectionType == 76 do(
printDebug("Surface offsets is located at 0x" + (bit.intAsHex(ftell f))as string)
surfaceheaderlength = readlong f #unsigned
surfacetotal = readlong f #unsigned
surfacename = readlong f #unsigned + 1
surfacename = String_array[surfacename]
surfacestuff1 = readlong f #unsigned
surfacestuff2 = readlong f #unsigned
	
	SurfaceOffset_array = #()
	for d = 1 to SurfaceTotal do(
	SurfaceOffset = readlong f #unsigned 
	append SurfaceOffset_array SurfaceOffset
	)
	
	for d = 1 to SurfaceTotal do(
	fseek f SurfaceOffset_array[d] #seek_set
	printDebug("Surface start is located at 0x" + (bit.intAsHex(ftell f))as string)
	sectiontype = readlong f #unsigned
	surfaceheaderlength = readlong f #unsigned
	surfacetotal = readlong f #unsigned
	surfacematname = readlong f #unsigned + 1
	surfacematname = String_array[surfacematname]
	surfacetexname = readlong f #unsigned + 1
	surfacetexname = String_array[surfacetexname]
	append SurfaceName_array surfacetexname
	printDebug("Info: " + surfacematname as string + ", " + surfacetexname as string)
	)
	
)

if SectionType == 91 do(
printDebug("Bone transforms for " + BoneName1 as string + " is located at 0x" + (bit.intAsHex(ftell f))as string)
bonetransformlength = readlong f #unsigned
bonetransformtotal = readlong f #unsigned
BoneTransformIndex_array = #()

for e = 1 to BoneTransformTotal do(
BoneTransformIndex = readlong f #unsigned
append BoneTransformIndex_array BoneTransformIndex
)

m11 = 1; m12 = 0; m13 = 0; m14 = 0
m21 = 0; m22 = 1; m23 = 0; m24 = 0
m31 = 0; m32 = 0; m33 = 1; m34 = 0
m41 = 0; m42 = 0; m43 = 0; m44 = 0
m15 = 1; m16 = 0; m17 = 0; m18 = 0
m25 = 0; m26 = 1; m27 = 0; m28 = 0
m35 = 0; m36 = 0; m37 = 1; m38 = 0
RotX = 0; RotY = 0; RotZ = 0
ScaleX = 1; ScaleY = 1; ScaleZ = 1

for t = 1 to BoneTransformTotal do(
fseek f BoneTransformIndex_array[t] #seek_set
sectiontype = readlong f #unsigned
printDebug("SectionType = " + SectionType as string)

if SectionType == 20 do(
printDebug("Bone transform (Matrix: Translation) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
m41 = Readfloat f * ModelScale
m42 = Readfloat f * ModelScale
m43 = Readfloat f * ModelScale
printDebug("Values = " + m41 as string + ", " + m42 as string + ", " + m43 as string)
)

if SectionType == 21 do(
printDebug("Bone transform (Scale) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
ScaleX = Readfloat f
ScaleY = Readfloat f
ScaleZ = Readfloat f
printDebug("Values = " + ScaleX as string + ", " + ScaleY as string + ", " + ScaleZ as string)
)

if SectionType == 93 do(
printDebug("Bone transform (Matrix: X) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
m15 = Readfloat f
m16 = Readfloat f
m17 = Readfloat f
m18 = Readfloat f
printDebug("Values = " + m15 as string + ", " + m16 as string + ", " + m17 as string + ", " + m18 as string)
)

if SectionType == 94 do(
printDebug("Bone transform (Matrix: Y) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
m25 = Readfloat f
m26 = Readfloat f
m27 = Readfloat f
m28 = Readfloat f
printDebug("Values = " + m25 as string + ", " + m26 as string + ", " + m27 as string + ", " + m28 as string)
)

if SectionType == 95 do(
printDebug("Bone transform (Matrix: Z) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
m35 = Readfloat f
m36 = Readfloat f
m37 = Readfloat f
m38 = Readfloat f
printDebug("Values = " + m35 as string + ", " + m36 as string + ", " + m37 as string + ", " + m38 as string)
)

if SectionType == 103 do(
printDebug("Bone transform (Joint Orient X) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
m11 = Readfloat f
m12 = Readfloat f
m13 = Readfloat f
m14 = Readfloat f
printDebug("Values = " + m11 as string + ", " + m12 as string + ", " + m13 as string + ", " + m14 as string)
)

if SectionType == 104 do(
printDebug("Bone transform (Joint Orient Y) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
m21 = Readfloat f
m22 = Readfloat f
m23 = Readfloat f
m24 = Readfloat f
printDebug("Values = " + m21 as string + ", " + m22 as string + ", " + m23 as string + ", " + m24 as string)
)

if SectionType == 105 do(
printDebug("Bone transform (Joint Orient Z) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
m31 = Readfloat f
m32 = Readfloat f
m33 = Readfloat f
m34 = Readfloat f
printDebug("Values = " + m31 as string + ", " + m32 as string + ", " + m33 as string + ", " + m34 as string)
)

if SectionType == 112 do(
printDebug("Bone data (Collision Flag) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 113 do(
printDebug("Bone data (Collision Radius) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 114 do(
printDebug("Bone data (Physics Flag) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = readlong f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 115 do(
printDebug("Bone data (Physics Radius) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 116 do(
printDebug("Bone data (Physics Cost) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 117 do(
printDebug("Bone data (Physics Mass) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 118 do(
printDebug("Bone data (Physics Expand) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 119 do(
printDebug("Bone data (Physics Shape Memory) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 122 do(
printDebug("Bone data (122) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 123 do(
printDebug("Bone data (123) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 124 do(
printDebug("Bone data (124) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 125 do(
printDebug("Bone data (125) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 126 do(
printDebug("Bone data (126) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readlong f
stuff2 = readlong f
stuff3 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 130 do(
printDebug("Bone data (130) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 132 do(
printDebug("Bone data (132) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 133 do(
printDebug("Bone data (133) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 134 do(
printDebug("Bone data (134) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 140 do(
printDebug("Bone data (140) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 141 do(
printDebug("Bone data (141) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 142 do(
printDebug("Bone data (142) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 143 do(
printDebug("Bone data (143) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 144 do(
printDebug("Bone data (144) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 145 do(
printDebug("Bone data (145) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 150 do(
printDebug("Bone data (150) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 151 do(
printDebug("Bone data (151) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 160 do(
printDebug("Bone data (160) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = readlong f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 161 do(
printDebug("Bone data (161) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 162 do(
printDebug("Bone data (162) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 163 do(
printDebug("Bone data (163) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

if SectionType == 164 do(
printDebug("Bone data (164) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readlong f #unsigned + 1
stuff1 = readshort f
stuff2 = readshort f
stuff3 = readlong f
stuff4 = Readfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string + ", " + stuff4 as string)
)

)

tfm = scaleMatrix [ScaleX,ScaleY,ScaleZ]
tfm = tfm * (rotateXMatrix m18) * (rotateYMatrix m28) * (rotateZMatrix m38)
tfm2 = scaleMatrix [ScaleX,ScaleY,ScaleZ]
tfm2 = tfm2 * (rotateXMatrix m14) * (rotateYMatrix m24) * (rotateZMatrix m34)
tfm = tfm * tfm2
tfm.row4 = [m41,m42,m43]

if (getNodeByName BoneName1) == undefined do (
if (BoneParent != -1) do (
tfm = tfm * BnArr[BoneParent].objecttransform
)
)	

newBone = bonesys.createbone   \
              tfm.row4   \
              (tfm.row4 + 0.01 * (normalize tfm.row1)) \
              (normalize tfm.row3)
         newBone.name = BoneName1
         newBone.width  = 0.01
         newBone.height = 0.01
         newBone.transform = tfm
		 newBone.scale = [ScaleX, ScaleY, ScaleZ]
         newBone.setBoneEnable false 0
         newBone.wirecolor = yellow
         newbone.showlinks = true
         newBone.pos.controller      = TCB_position ()
         newBone.rotation.controller = TCB_rotation ()
	if (BoneParent != -1) then
	newBone.parent = BNArr[BoneParent]
	append BNArr newBone
	if BoneIDNum != 0 then
	BNArrRig[BoneIDNum] = newBone

printDebug("--------------------")
)

if SectionType == 92 do(
printDebug("Bone parenting is located at 0x" + (bit.intAsHex(ftell f))as string)
)

)

)
)

if SectionType_array[b] == 11 do(
printDebug("Vertex block header data is located at 0x" + (bit.intAsHex(ftell f))as string)
sectiontype = readlong f #unsigned
vertexdataheaderlength = readlong f #unsigned
vertexdataheadertotal = readlong f #unsigned
VertexDataOffset_array = #()
for c = 1 to VertexDataHeaderTotal do(
VertexDataOffset = readlong f #unsigned
append VertexDataOffset_array VertexDataOffset
)
for c = 1 to VertexDataHeaderTotal do(
fseek f VertexDataOffset_array[c] #seek_set
sectiontype = readlong f #unsigned
if SectionType == 10 do(
printDebug("Vertex header header data is located at 0x" + (bit.intAsHex(ftell f))as string)
vertexheaderlength = readlong f #unsigned
vertexheadertotal = readlong f #unsigned
vertexheader1 = readlong f #unsigned
vertexheader2 = readlong f #unsigned
vertexheader3 = readlong f #unsigned
vertexheader4 = readlong f #unsigned
vertexheader5 = readlong f #unsigned
VertexHeaderOffset_array = #()
for d = 1 to VertexHeaderTotal do(
VertexHeaderOffset = readlong f #unsigned
append VertexHeaderOffset_array VertexHeaderOffset
)
for d = 1 to VertexHeaderTotal do(
fseek f VertexHeaderOffset_array[d] #seek_set
sectiontype = readlong f #unsigned
	
if SectionType == 70 do(
printDebug("Polygon block is located at 0x" + (bit.intAsHex(ftell f))as string)
polygondatalength = readlong f #unsigned
polygondatatotal = readlong f #unsigned
polygonname = readlong f #unsigned + 1
blank = readlong f #unsigned
polygondatastuff1 = readshort f #unsigned
polygondatastuff2 = readshort f #unsigned
polygontotal = readlong f #unsigned
PolygonDataOffset_array = #()
for e = 1 to PolygonDataTotal do(
PolygonDataOffset = readlong f #unsigned
append PolygonDataOffset_array PolygonDataOffset
)
for e = 1 to PolygonDataTotal do(
fseek f PolygonDataOffset_array[e] #seek_set
printDebug("Polygon header data is located at 0x" + (bit.intAsHex(ftell f))as string)
sectiontype = readlong f #unsigned

if SectionType == 69 do(
printDebug("Polygon data is located at 0x" + (bit.intAsHex(ftell f))as string)
polygonlength = readlong f #unsigned
polygontotal = readlong f #unsigned
polygontype = readshort f #unsigned
polygontypeB = readshort f #unsigned
blank = readlong f #unsigned
MatNum = PolyNum

		for z = 1 to SurfaceName_array.count do(
			MatName = MatName_array[z]
			SurfaceName = SurfaceName_array[PolyNum]
			if MatName == SurfaceName do(
			MatNum = z
			)
		)

if PolygonType == 0x05 do(
for g = 1 to PolygonTotal / 3 do(
f1 = readshort f #unsigned + 1
f2 = readshort f #unsigned + 1
f3 = readshort f #unsigned + 1
append Face_array [(f1),(f2),(f3)]
append FaceTex_array MatNum
)
)
if PolygonType == 0x07 do(
for g = 1 to PolygonTotal / 3 do(
f1 = readlong f #unsigned + 1
f2 = readlong f #unsigned + 1
f3 = readlong f #unsigned + 1
append Face_array [(f1),(f2),(f3)]
append FaceTex_array MatNum
)
)
PolyNum = PolyNum + 1
printDebug("Polygon data ends at 0x" + (bit.intAsHex(ftell f))as string)

)

)
)

if SectionType == 89 do(
printDebug("Vertex block data is located at 0x" + (bit.intAsHex(ftell f))as string)
vertexlength = readlong f #unsigned
vertextotal = readlong f #unsigned
VertexType = readshort f #unsigned
VertexTypeB = readshort f #unsigned
VertexCount = readlong f #unsigned
VertexSize = readlong f #unsigned
vertexstuff = readlong f #unsigned
VertexOffset_array = #()
printDebug("Vertex size: 0x" +(bit.intAsHex(vertexsize))as string)
printDebug("Vertex type: " + vertextype as string)
for e = 1 to VertexTotal do(
VertexOffset = readlong f #unsigned
append VertexOffset_array VertexOffset
)
for e = 1 to VertexTotal do(
fseek f VertexOffset_array[e] #seek_set
printDebug("Vertex header data is located at 0x" + (bit.intAsHex(ftell f))as string)
vertexvalues1 = readlong f #unsigned
vertexvalues2 = readlong f #unsigned
vertexvalues3 = readlong f #unsigned
vertexvalues4 = readlong f #unsigned
vertexvalues5 = readlong f #unsigned
vertexstartoffset = readlong f #unsigned
fseek f vertexstartoffset #seek_set
)
printDebug("Vertex/UV/Weighting data is located at 0x" + (bit.intAsHex(ftell f))as string)
for e = 1 to VertexCount do(

if VertexType == 0x01 do(
vx = Readfloat f * ModelScale
vy = Readfloat f * ModelScale
vz = Readfloat f * ModelScale
nx = (ReadHalfFloat f * 2)
ny = (ReadHalfFloat f * 2)
nz = (ReadHalfFloat f * 2)
tu = (ReadHalfFloat f * 2)
nx2 = (ReadHalfFloat f * 2)
ny2 = (ReadHalfFloat f * 2)
nz2 = (ReadHalfFloat f * 2)
tv = ((ReadHalfFloat f * 2) * -1) + 1
colorr = readbyte f #unsigned
colorg = readbyte f #unsigned
colorb = readbyte f #unsigned
colora = (readbyte f #unsigned) as float / 255
append Vert_array [vx,vy,vz]
append Normal_array [nx,ny,nz]
append Normal2_array [nx2,ny2,nz2]
append UV_array [tu,tv,0]
append Color_array [colorr,colorg,colorb]
append Alpha_Array colora
)

if VertexType == 0x03 and VertexSize == 0x10 and VersionA == 1 do(
bone1 = (readbyte f #unsigned) + 1
bone2 = (readbyte f #unsigned) + 1
bone3 = (readbyte f #unsigned) + 1
bone4 = (readbyte f #unsigned) + 1
bone5 = 1
bone6 = 1
bone7 = 1
bone8 = 1
weight1 = ReadHalfFloat f
weight2 = ReadHalfFloat f
weight3 = ReadHalfFloat f
weight4 = ReadHalfFloat f
weight5 = 0 as float
weight6 = 0 as float
weight7 = 0 as float
weight8 = 0 as float
fseek f 0x04 #seek_cur
append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone7:Bone7 Bone8:Bone8)
append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
)

if VertexType == 0x03 and VertexSize == 0x20 and VersionA == 1 do(
bone1 = (readbyte f #unsigned) + 1
bone2 = (readbyte f #unsigned) + 1
bone3 = (readbyte f #unsigned) + 1
bone4 = (readbyte f #unsigned) + 1
bone5 = 1
bone6 = 1
bone7 = 1
bone8 = 1
weight1 = Readfloat f
weight2 = Readfloat f
weight3 = Readfloat f
weight4 = Readfloat f
weight5 = 0 as float
weight6 = 0 as float
weight7 = 0 as float
weight8 = 0 as float
fseek f 0x0C #seek_cur
append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone7:Bone7 Bone8:Bone8)
append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
)

if VertexType == 0x03 and VertexSize == 0x20 and VersionA == 2 do(
bone1 = (readshort f #unsigned) + 1
bone2 = (readshort f #unsigned) + 1
bone3 = (readshort f #unsigned) + 1
bone4 = (readshort f #unsigned) + 1
bone5 = 1
bone6 = 1
bone7 = 1
bone8 = 1
weight1 = Readfloat f
weight2 = Readfloat f
weight3 = Readfloat f
weight4 = Readfloat f
weight5 = 0 as float
weight6 = 0 as float
weight7 = 0 as float
weight8 = 0 as float
fseek f 0x08 #seek_cur
append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone7:Bone7 Bone8:Bone8)
append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
)

if VertexType == 0x03 and VertexSize == 0x30 and VersionA == 2 do(
bone1 = (readshort f #unsigned) + 1
bone2 = (readshort f #unsigned) + 1
bone3 = (readshort f #unsigned) + 1
bone4 = (readshort f #unsigned) + 1
bone5 = (readshort f #unsigned) + 1
bone6 = (readshort f #unsigned) + 1
bone7 = (readshort f #unsigned) + 1
bone8 = (readshort f #unsigned) + 1
weight1 = Readfloat f
weight2 = Readfloat f
weight3 = Readfloat f
weight4 = Readfloat f
weight5 = Readfloat f
weight6 = Readfloat f
weight7 = Readfloat f
weight8 = Readfloat f
append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4 Bone5:Bone5 Bone6:Bone6 Bone7:Bone7 Bone8:Bone8)
append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4 Weight5:Weight5 Weight6:Weight6 Weight7:Weight7 Weight8:Weight8)
)

)
printDebug("Vertex/UV/Weighting data ends at 0x" + (bit.intAsHex(ftell f))as string)

)

if SectionType == 110 do(
printDebug("Bounding box is located at 0x" + (bit.intAsHex(ftell f))as string)
-- SectionType = readlong f #unsigned
-- fseek f 0x08 #seek_cur
-- BoundMinX = readfloat f * ModelScale
-- BoundMinY = readfloat f * ModelScale
-- BoundMinZ = readfloat f * ModelScale
-- BoundMinQ = readfloat f * ModelScale
-- BoundMaxX = readfloat f * ModelScale
-- BoundMaxY = readfloat f * ModelScale
-- BoundMaxZ = readfloat f * ModelScale
-- BoundMaxQ = readfloat f * ModelScale
-- printDebug("Bounding box: " + BoundMinX as string + " - " + BoundMinY as string + " - " + BoundMinZ as string + " / " + BoundMaxX as string + " - " + BoundMaxY as string + " - " + BoundMaxZ as string)
)
)
)
)
)

if SectionType_array[b] == 33 do(
sectiontype = readlong f #unsigned
stringheaderlength = readlong f #unsigned
stringtotal = readlong f #unsigned
StringOffset_array = #()
for c = 1 to StringTotal do(
StringOffset = readlong f #unsigned
append StringOffset_array StringOffset
)
for c = 1 to StringTotal do(
fseek f StringOffset_array[c] #seek_set
ISM2String = readstring f
append String_array ISM2String
)
)

if SectionType_array[b] == 46 do(
printDebug("Texture data is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionType = readlong f #unsigned
TextureHeaderLength = readlong f #unsigned
TextureTotal = readlong f #unsigned
TextureOffset_array = #()
for c = 1 to TextureTotal do(
TextureOffset = readlong f #unsigned
append TextureOffset_array TextureOffset
)
for c = 1 to TextureTotal do(
fseek f TextureOffset_array[c] #seek_set
sectiontype = readlong f #unsigned
TextureDataString1 = readlong f #unsigned + 1
TextureDataString1 = String_array[TextureDataString1]
TextureDataString2 = readlong f #unsigned + 1
TextureDataString2 = String_array[TextureDataString2]
TextureDataString3 = readlong f #unsigned + 1
TextureDataString3 = String_array[TextureDataString3]
TextureDataString4 = readlong f #unsigned + 1
TextureDataString4 = String_array[TextureDataString4]
texturestuff1 = readlong f #unsigned
texturestuff2 = readlong f #unsigned
texturestuff3 = readlong f #unsigned
texturename = TextureDataString4
texturepath = p + "TEXTURE/001/" + texturename
append TextureName_array texturepath
)
printDebug(TextureName_array)
)

-- if SectionType_array[b] == 50 do(
-- printDebug("Bone matrix data is located at 0x" + (bit.intAsHex(ftell f))as string)
-- sectiontype = readlong f #unsigned
-- matrixheaderlength = readlong f #unsigned
-- matrixtotal = readlong f #unsigned
-- matrixstuff1 = readlong f #unsigned
-- matrixstuff2 = readlong f #unsigned
-- MatrixOffset = readlong f #unsigned
-- fseek f MatrixOffset #seek_set

-- printDebug("Bone matrix data B is located at 0x" + (bit.intAsHex(ftell f))as string)
-- sectiontype = readlong f #unsigned
-- matrixheaderlength = readlong f #unsigned
-- matrixtotal = readlong f #unsigned
-- matrixstuff1 = readlong f #unsigned
-- matrixstuff2 = readlong f #unsigned
-- MatrixOffset = readlong f #unsigned

-- printDebug("Bone matrix data C is located at 0x" + (bit.intAsHex(ftell f))as string)
-- fseek f MatrixOffset #seek_set
-- sectiontype = readlong f #unsigned
-- matrixheaderlength = readlong f #unsigned
-- matrixtotal = readlong f #unsigned
-- matrixstuff1 = readlong f #unsigned
-- matrixstuff2 = readlong f #unsigned
-- m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14= readfloat f
-- m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
-- m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
-- m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
-- MatrixOffset1 = readlong f #unsigned
-- MatrixOffset2 = readlong f #unsigned
-- fseek f MatrixOffset2 #seek_set

-- printDebug("Bone matrix data D is located at 0x" + (bit.intAsHex(ftell f))as string)
-- sectiontype = readlong f #unsigned
-- matrixheaderlength = readlong f #unsigned
-- matrixtotal = readlong f #unsigned / 10
-- matrixstuff1 = readlong f #unsigned
-- matrixstuff2 = readshort f #unsigned
-- matrixstuff3 = readshort f #unsigned
-- matrixstuff4 = readlong f #unsigned
-- matrixstuff5 = readlong f #unsigned
-- matrixstuff6 = readlong f #unsigned

-- for t = 1 to MatrixTotal do(
-- m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14= readfloat f
-- m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
-- m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
-- m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f

-- tfm = inverse(matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m14,m24,m34])
-- append Bone_Matrix_array tfm
-- )
-- )

if SectionType_array[b] == 97 do(
printDebug("Material data (97) is located at 0x" + (bit.intAsHex(ftell f))as string)

SectionType = readlong f #unsigned
MaterialHeaderLength = readlong f #unsigned
MatTotal = readlong f #unsigned
MatOffset_array = #()

for z = 1 to MatTotal do(
MatOffset = readlong f #unsigned
append MatOffset_array MatOffset
)

multimat = MultiMaterial()
multimat.name = "Neptunia"
multimat.numsubs = MatTotal

	for z = 1 to MatTotal do(
	fseek f MatOffset_array[z] #seek_set
	printDebug("Material data (13) is located at 0x" + (bit.intAsHex(ftell f))as string)
	SectionType = readlong f #unsigned
	HeaderLength = readlong f #unsigned
	MatSubTotal = readlong f #unsigned
	MatSubString1 = readlong f #unsigned + 1
	MatSubString1 = String_array[MatSubString1]
	MatSubString2 = readlong f #unsigned + 1
	MatSubString2 = String_array[MatSubString2]
	MatSubString3 = readlong f #unsigned + 1
	MatSubString3 = String_array[MatSubString3]
	append MatName_array MatSubString1
	Blank = readlong f #unsigned
	printDebug("Info: " + MatSubString1 as string + ", " + MatSubString2 as string + ", " + MatSubString3 as string)
		if MatSubTotal > 0 do(
		MatSubOffset = readlong f #unsigned
		fseek f MatSubOffset #seek_set
		printDebug("Material data (108) is located at 0x" + (bit.intAsHex(ftell f))as string)
		SectionType = readlong f #unsigned
		HeaderLength = readlong f #unsigned
		MatSubBTotal = readlong f #unsigned
			MatSubBOffset = readlong f #unsigned
			fseek f MatSubBOffset #seek_set
			printDebug("Material data (106) is located at 0x" + (bit.intAsHex(ftell f))as string)
			SectionType = readlong f #unsigned
			HeaderLength = readlong f #unsigned
			MatSubCTotal = readlong f #unsigned
			MatSubCString = readlong f #unsigned + 1
			MatSubCString = String_array[MatSubCString]
			Blank = readlong f
			printDebug("Info: " + MatSubCString as string)
				MatSubCOffset = readlong f #unsigned
				fseek f MatSubCOffset #seek_set
				printDebug("Material data (107) is located at 0x" + (bit.intAsHex(ftell f))as string)
				SectionType = readlong f #unsigned
				HeaderLength = readlong f #unsigned
				MatSubDTotal = readlong f #unsigned
				MatSubDStuffA = readlong f #unsigned
				MatSubDStuffB = readlong f #unsigned
				Blank = readlong f #unsigned
				printDebug("Info: " + MatSubDStuffA as string + ", " + MatSubDStuffB as string)
					MatSubDOffset = readlong f #unsigned
					fseek f MatSubDOffset #seek_set
					printDebug("Material data (107-B) is located at 0x" + (bit.intAsHex(ftell f))as string)
					SectionType = readlong f #unsigned
					HeaderLength = readlong f #unsigned
					MatSubETotal = readlong f #unsigned
					MatSubEStuffA = readlong f #unsigned
					MatSubEStuffB = readlong f #unsigned
					Blank = readlong f #unsigned
					printDebug("Info: " + MatSubEStuffA as string + ", " + MatSubEStuffB as string)
						MatSubEOffset = readlong f #unsigned
						fseek f MatSubEOffset #seek_set
						printDebug("Material data (107-C) is located at 0x" + (bit.intAsHex(ftell f))as string)
						MatTexName = readlong f #unsigned + 1
						MatTexName = String_array[MatTexName]
						printDebug("Info: " + MatTexName as string)
								append MatTexName_array MatTexName
		)
		if MatSubTotal == 0 do(
		MatTexName = "Tex_c.dds"
		append MatTexName_array MatTexName
		)
	)
	for z = 1 to MatTotal do(
	mat = multimat.materialList[z]
	mat.name = MatName_array[z] as string
	mat.showinviewport = true
	mat.twosided = false
	if TexFormat == 1 then (
		if TexPath == 1 then (
		tm = Bitmaptexture filename:(p + "TEXTURE/001/" + MatTexName_array[z] as string + ".dds")
		) else (
			tm = Bitmaptexture filename:(p + MatTexName_array[z] as string + ".dds")
		)
	) else (
		if TexPath == 1 then (
		tm = Bitmaptexture filename:(p + "TEXTURE/001/" + MatTexName_array[z] as string + ".png")
		) else (
			tm = Bitmaptexture filename:(p + MatTexName_array[z] as string + ".png")
		)
	)
	tm.alphasource = 0
	mat.diffuseMap = tm
	mat.opacityMap = tm
	mat.opacityMap.monoOutput = 1
	)

)

-- if SectionType_array[b] == 98 do(
-- printDebug("Unknown data (98) is located at 0x" + (bit.intAsHex(ftell f))as string)
-- )

)


if BNArrRig.count == 0 do(
for b = 1 to Vert_array.count do(
	append B1_array (Bone_Info_Struct Bone1:1 Bone2:1 Bone3:1 Bone4:1 Bone5:1 Bone6:1 Bone7:1 Bone8:1)
	append W1_array (Weight_Info_Struct Weight1:1 Weight2:0 Weight3:0 Weight4:0 Weight5:0 Weight6:0 Weight7:0 Weight8:0)
	)
	BNArrRig[1] = BNArr[1]
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

for j = 1 to BNArrRig.count do(
	if BNArrRig[j] == undefined do(
		BNArrRig[j] = BNArrRig[1]
		print ("Bone #" + j as string + " is invalid! Defaulting to root bone!")
		)
)

msh = mesh vertices:Vert_array faces:Face_array
msh.name = g
msh.material = multimat

msh.numTVerts = Vert_array.count

if VertColors == true then (
	setNumCPVVerts msh msh.numTVerts
	setCVertMode msh true
	setShadeCVerts msh true
)

defaultVCFaces msh
buildTVFaces msh
if VertColors == true then (
for j = 1 to Color_array.count do setvertcolor msh j Color_array[j]
for j = 1 to Alpha_array.count do(meshop.setVertAlpha msh -2 j Alpha_array[j])
)
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do (	
	setTVFace msh j Face_array[j]
	setFaceMatID msh j FaceTex_array[j]
)
for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1

max modify mode
select msh

      --set smoothing group of all faces to 1 to get one normal per vertex
      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
      --set normals via edit normals modifier
      select msh
      addmodifier msh (Edit_Normals ()) ui:off
      msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
      EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
      EN_setNormal = msh.Edit_Normals.SetNormal
      normID = #{}
      --apply normals
      for v = 1 to Normal_array.count do
      (
         free normID
         EN_convertVS #{v} &normID
         for id in normID do EN_setNormal id Normal_array[v]
      )

skinMod = skin ()
addModifier msh skinMod

for i = 1 to BNArrRig.count do
(
   maxbone = getnodebyname BNArrRig[i].name
   if i != BoneTotal then
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
) else (
VersionA = readbyte f #unsigned
VersionB = readbyte f #unsigned
VersionC = readbyte f #unsigned
VersionD = readbyte f #unsigned
header3 = readBElong f
header4 = readBElong f
filesize = readBElong f
sectioncount = readBElong f
header7 = readBElong f
header8 = readBElong f
SectionType_array = #()
SectionOffset_array = #()
for b = 1 to SectionCount do(
SectionType = readBElong f
printDebug("SectionType: " + SectionType as string)
SectionOffset = readBElong f
append SectionType_array SectionType
append SectionOffset_array SectionOffset
)

for b = 1 to SectionCount do(
fseek f SectionOffset_array[b] #seek_set
	
if SectionType_array[b] == 3 do(
printDebug("Bone data is located at 0x" + (bit.intAsHex(ftell f))as string)
sectiontype = readBElong f
bonedataheaderlength = readBElong f
bonetotal = readBElong f
bonedatastring1 = readBElong f + 1
bonedatastring1 = String_array[bonedatastring1]
bonedatastring2 = readBElong f + 1
bonedatastring2 = String_array[bonedatastring2]
BoneOffset_array = #()
for c = 1 to BoneTotal do(
BoneOffset = readBElong f
append BoneOffset_array BoneOffset
)
for c = 1 to BoneTotal do(
fseek f BoneOffset_array[c] #seek_set
sectiontype = readBElong f
boneheaderlength = readBElong f
boneheadertotal = readBElong f
bonename1 = readBElong f + 1
bonename1 = String_array[bonename1]
bonename2 = readBElong f + 1
bonename2 = String_array[bonename2]
boneheaderstuff1 = readBElong f
boneheaderstuff2 = readBElong f
boneparentoffset = readBElong f
BoneParent = -1
for d = 1 to BoneTotal do(
	if boneparentoffset == BoneOffset_array[d] do(BoneParent = d)
)
boneheaderstuff4 = readBElong f
boneheaderstuff5 = readBElong f
boneheaderstuff6 = readBElong f
BoneIDNum = readBElong f + 1
boneheaderstuff8 = readBElong f
boneheaderstuff9 = readBElong f
boneheaderstuff10 = readBElong f
boneheaderstuff11 = readBElong f
BoneHeader_array = #()
for d = 1 to BoneHeaderTotal do(
BoneHeader = readBElong f
append BoneHeader_array BoneHeader
)
for d = 1 to BoneHeaderTotal do(
fseek f BoneHeader_array[d] #seek_set
sectiontype = readBElong f

if SectionType == 76 do(
printDebug("Surface offsets is located at 0x" + (bit.intAsHex(ftell f))as string)
surfaceheaderlength = readBElong f
surfacetotal = readBElong f 
surfacename = readBElong f + 1
surfacename = String_array[surfacename]
surfacestuff1 = readBElong f
surfacestuff2 = readBElong f
	
	SurfaceOffset_array = #()
	for d = 1 to SurfaceTotal do(
	SurfaceOffset = readBElong f
	append SurfaceOffset_array SurfaceOffset
	)
	
	for d = 1 to SurfaceTotal do(
	fseek f SurfaceOffset_array[d] #seek_set
	printDebug("Surface start is located at 0x" + (bit.intAsHex(ftell f))as string)
	sectiontype = readBElong f
	surfaceheaderlength = readBElong f
	surfacetotal = readBElong f
	surfacematname = readBElong f + 1
	surfacematname = String_array[surfacematname]
	surfacetexname = readBElong f + 1
	surfacetexname = String_array[surfacetexname]
	append SurfaceName_array surfacetexname
	printDebug("Info: " + surfacematname as string + ", " + surfacetexname as string)
	)
	
)

if SectionType == 91 do(
printDebug("Bone transforms for " + BoneName1 as string + " is located at 0x" + (bit.intAsHex(ftell f))as string)
bonetransformlength = readBElong f
bonetransformtotal = readBElong f
BoneTransformIndex_array = #()

for e = 1 to BoneTransformTotal do(
BoneTransformIndex = readBElong f
append BoneTransformIndex_array BoneTransformIndex
)

m11 = 1; m12 = 0; m13 = 0; m14 = 0
m21 = 0; m22 = 1; m23 = 0; m24 = 0
m31 = 0; m32 = 0; m33 = 1; m34 = 0
m41 = 0; m42 = 0; m43 = 0; m44 = 0
m15 = 1; m16 = 0; m17 = 0; m18 = 0
m25 = 0; m26 = 1; m27 = 0; m28 = 0
m35 = 0; m36 = 0; m37 = 1; m38 = 0
RotX = 0; RotY = 0; RotZ = 0
ScaleX = 1; ScaleY = 1; ScaleZ = 1

for t = 1 to BoneTransformTotal do(
fseek f BoneTransformIndex_array[t] #seek_set
sectiontype = readBElong f
printDebug("SectionType = " + SectionType as string)

if SectionType == 20 do(
printDebug("Bone transform (Matrix: Translation) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
m41 = readBEfloat f * ModelScale
m42 = readBEfloat f * ModelScale
m43 = readBEfloat f * ModelScale
printDebug("Values = " + m41 as string + ", " + m42 as string + ", " + m43 as string)
)

if SectionType == 21 do(
printDebug("Bone transform (Scale) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
ScaleX = readBEfloat f
ScaleY = readBEfloat f
ScaleZ = readBEfloat f
printDebug("Values = " + ScaleX as string + ", " + ScaleY as string + ", " + ScaleZ as string)
)

if SectionType == 93 do(
printDebug("Bone transform (Matrix: X) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
m15 = readBEfloat f
m16 = readBEfloat f
m17 = readBEfloat f
m18 = readBEfloat f
printDebug("Values = " + m15 as string + ", " + m16 as string + ", " + m17 as string + ", " + m18 as string)
)

if SectionType == 94 do(
printDebug("Bone transform (Matrix: Y) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
m25 = readBEfloat f
m26 = readBEfloat f
m27 = readBEfloat f
m28 = readBEfloat f
printDebug("Values = " + m25 as string + ", " + m26 as string + ", " + m27 as string + ", " + m28 as string)
)

if SectionType == 95 do(
printDebug("Bone transform (Matrix: Z) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
m35 = readBEfloat f
m36 = readBEfloat f
m37 = readBEfloat f
m38 = readBEfloat f
printDebug("Values = " + m35 as string + ", " + m36 as string + ", " + m37 as string + ", " + m38 as string)
)

if SectionType == 103 do(
printDebug("Bone transform (Joint Orient X) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
m11 = readBEfloat f
m12 = readBEfloat f
m13 = readBEfloat f
m14 = readBEfloat f
printDebug("Values = " + m11 as string + ", " + m12 as string + ", " + m13 as string + ", " + m14 as string)
)

if SectionType == 104 do(
printDebug("Bone transform (Joint Orient Y) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
m21 = readBEfloat f
m22 = readBEfloat f
m23 = readBEfloat f
m24 = readBEfloat f
printDebug("Values = " + m21 as string + ", " + m22 as string + ", " + m23 as string + ", " + m24 as string)
)

if SectionType == 105 do(
printDebug("Bone transform (Joint Orient Z) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
m31 = readBEfloat f
m32 = readBEfloat f
m33 = readBEfloat f
m34 = readBEfloat f
printDebug("Values = " + m31 as string + ", " + m32 as string + ", " + m33 as string + ", " + m34 as string)
)

if SectionType == 112 do(
printDebug("Bone data (Collision Flag) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 113 do(
printDebug("Bone data (Collision Radius) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 114 do(
printDebug("Bone data (Physics Flag) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBElong f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 115 do(
printDebug("Bone data (Physics Radius) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 116 do(
printDebug("Bone data (Physics Cost) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 117 do(
printDebug("Bone data (Physics Mass) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 118 do(
printDebug("Bone data (Physics Expand) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 119 do(
printDebug("Bone data (Physics Shape Memory) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 122 do(
printDebug("Bone data (122) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 123 do(
printDebug("Bone data (123) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 124 do(
printDebug("Bone data (124) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 125 do(
printDebug("Bone data (125) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

if SectionType == 126 do(
printDebug("Bone data (126) is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionString = readBElong f + 1
stuff1 = readBElong f
stuff2 = readBElong f
stuff3 = readBEfloat f
printDebug("Values = " + stuff1 as string + ", " + stuff2 as string + ", " + stuff3 as string)
)

)

tfm = scaleMatrix [ScaleX,ScaleY,ScaleZ]
tfm = tfm * (rotateXMatrix m18) * (rotateYMatrix m28) * (rotateZMatrix m38)
tfm2 = scaleMatrix [ScaleX,ScaleY,ScaleZ]
tfm2 = tfm2 * (rotateXMatrix m14) * (rotateYMatrix m24) * (rotateZMatrix m34)
tfm = tfm * tfm2
tfm.row4 = [m41,m42,m43]

if (getNodeByName BoneName1) == undefined do (
if (BoneParent != -1) do (
tfm = tfm * BnArr[BoneParent].objecttransform
)
)	

newBone = bonesys.createbone   \
              tfm.row4   \
              (tfm.row4 + 0.01 * (normalize tfm.row1)) \
              (normalize tfm.row3)
         newBone.name = BoneName1
         newBone.width  = 0.01
         newBone.height = 0.01
         newBone.transform = tfm
		 newBone.scale = [ScaleX, ScaleY, ScaleZ]
         newBone.setBoneEnable false 0
         newBone.wirecolor = yellow
         newbone.showlinks = true
         newBone.pos.controller      = TCB_position ()
         newBone.rotation.controller = TCB_rotation ()
	if (BoneParent != -1) then
	newBone.parent = BNArr[BoneParent]
	append BNArr newBone
	if BoneIDNum != 0 then
	BNArrRig[BoneIDNum] = newBone

printDebug("--------------------")
)

if SectionType == 92 do(
printDebug("Bone parenting is located at 0x" + (bit.intAsHex(ftell f))as string)
)

)

)
)

if SectionType_array[b] == 11 do(
printDebug("Vertex block header data is located at 0x" + (bit.intAsHex(ftell f))as string)
sectiontype = readBElong f
vertexdataheaderlength = readBElong f
vertexdataheadertotal = readBElong f
VertexDataOffset_array = #()
for c = 1 to VertexDataHeaderTotal do(
VertexDataOffset = readBElong f
append VertexDataOffset_array VertexDataOffset
)
for c = 1 to VertexDataHeaderTotal do(
fseek f VertexDataOffset_array[c] #seek_set
sectiontype = readBElong f
if SectionType == 10 do(
printDebug("Vertex header header data is located at 0x" + (bit.intAsHex(ftell f))as string)
vertexheaderlength = readBElong f
vertexheadertotal = readBElong f
vertexheader1 = readBElong f
vertexheader2 = readBElong f
vertexheader3 = readBElong f
vertexheader4 = readBElong f
vertexheader5 = readBElong f
VertexHeaderOffset_array = #()
for d = 1 to VertexHeaderTotal do(
VertexHeaderOffset = readBElong f
append VertexHeaderOffset_array VertexHeaderOffset
)
for d = 1 to VertexHeaderTotal do(
fseek f VertexHeaderOffset_array[d] #seek_set
sectiontype = readBElong f
	
if SectionType == 70 do(
printDebug("Polygon block is located at 0x" + (bit.intAsHex(ftell f))as string)
polygondatalength = readBElong f
polygondatatotal = readBElong f
polygonname = readBElong f + 1
blank = readBElong f
polygondatastuff2 = readBEword f
polygondatastuff3 = readBEword f
polygondatastuff4 = readBElong f
PolygonDataOffset_array = #()
for e = 1 to PolygonDataTotal do(
PolygonDataOffset = readBElong f
append PolygonDataOffset_array PolygonDataOffset
)
for e = 1 to PolygonDataTotal do(
fseek f PolygonDataOffset_array[e] #seek_set
printDebug("Polygon header data is located at 0x" + (bit.intAsHex(ftell f))as string)
sectiontype = readBElong f

if SectionType == 69 do(
printDebug("Polygon data is located at 0x" + (bit.intAsHex(ftell f))as string)
polygonlength = readBElong f
polygontotal = readBElong f
polygontype = readBEword f
polygontypeB = readBEword f
blank = readBElong f
MatNum = PolyNum

		for z = 1 to SurfaceName_array.count do(
			MatName = MatName_array[z]
			SurfaceName = SurfaceName_array[PolyNum]
			if MatName == SurfaceName do(
			MatNum = z
			)
		)

for g = 1 to PolygonTotal / 3 do(
f1 = readBEword f + 1
f2 = readBEword f + 1
f3 = readBEword f + 1
append Face_array [(f1),(f2),(f3)]
append FaceTex_array MatNum
)

PolyNum = PolyNum + 1
printDebug("Polygon data ends at 0x" + (bit.intAsHex(ftell f))as string)

)

)
)

if SectionType == 89 do(
printDebug("Vertex block data is located at 0x" + (bit.intAsHex(ftell f))as string)
vertexlength = readBElong f
vertextotal = readBElong f
VertexTypeB = readBEword f
VertexType = readBEword f
VertexCount = readBElong f
VertexSize = readBElong f
vertexstuff = readBElong f
VertexOffset_array = #()
printDebug("Vertex size: 0x" +(bit.intAsHex(vertexsize))as string)
printDebug("Vertex type: " + vertextype as string)
for e = 1 to VertexTotal do(
VertexOffset = readBElong f
append VertexOffset_array VertexOffset
)
for e = 1 to VertexTotal do(
fseek f VertexOffset_array[e] #seek_set
printDebug("Vertex header data is located at 0x" + (bit.intAsHex(ftell f))as string)
vertexvalues1 = readBElong f
vertexvalues2 = readBElong f
vertexvalues3 = readBElong f
vertexvalues4 = readBElong f
vertexvalues5 = readBElong f
vertexstartoffset = readBElong f
fseek f vertexstartoffset #seek_set
)
printDebug("Vertex/UV/Weighting data is located at 0x" + (bit.intAsHex(ftell f))as string)
for e = 1 to VertexCount do(

if VertexType == 0x01 and vertexsize == 32 do(
vx = readBEfloat f * ModelScale
vy = readBEfloat f * ModelScale
vz = readBEfloat f * ModelScale
nx = readBEhalffloat f * 2
ny = readBEhalffloat f * 2
nz = readBEhalffloat f * 2
nx2 = readBEhalffloat f
ny2 = readBEhalffloat f
nz2 = readBEhalffloat f
nx3 = readBEhalffloat f
ny3 = readBEhalffloat f
nz3 = readBEhalffloat f
nq3 = readBEhalffloat f
append Vert_array [vx,vy,vz]
append Normal_array [nx,ny,nz]
)

if VertexType == 0x01 and vertexsize == 48 do(
vx = readBEfloat f * ModelScale
vy = readBEfloat f * ModelScale
vz = readBEfloat f * ModelScale
nx = readBEhalffloat f * 2
ny = readBEhalffloat f * 2
nz = readBEhalffloat f * 2
nx2 = readBEhalffloat f
ny2 = readBEhalffloat f
nz2 = readBEhalffloat f
nx3 = readBEhalffloat f
ny3 = readBEhalffloat f
nz3 = readBEhalffloat f
nx4 = readBEhalffloat f
ny4 = readBEhalffloat f
nz4 = readBEhalffloat f
fseek f 0x0C #seek_cur
append Vert_array [vx,vy,vz]
append Normal_array [nx,ny,nz]
)

if VertexType == 0x02 do(
tu = readBEhalffloat f * 2
tv = ((readBEhalffloat f * 2) * -1) + 1
append UV_array [tu,tv,0]
)

if VertexType == 0x03 do(
bone1 = readBEword f + 1
bone2 = readBEword f + 1
bone3 = readBEword f + 1
bone4 = readBEword f + 1
weight1 = readBEfloat f
weight2 = readBEfloat f
weight3 = readBEfloat f
weight4 = readBEfloat f
fseek f 0x08 #seek_cur
append B1_array (Bone_Info_Struct Bone1:Bone1 Bone2:Bone2 Bone3:Bone3 Bone4:Bone4)
append W1_array (Weight_Info_Struct Weight1:Weight1 Weight2:Weight2 Weight3:Weight3 Weight4:Weight4)
)

)
printDebug("Vertex/UV/Weighting data ends at 0x" + (bit.intAsHex(ftell f))as string)

)

if SectionType == 110 do(
printDebug("Bounding box is located at 0x" + (bit.intAsHex(ftell f))as string)
)
)
)
)
)

if SectionType_array[b] == 33 do(
sectiontype = readBElong f
stringheaderlength = readBElong f
stringtotal = readBElong f
StringOffset_array = #()
for c = 1 to StringTotal do(
StringOffset = readBElong f
append StringOffset_array StringOffset
)
for c = 1 to StringTotal do(
fseek f StringOffset_array[c] #seek_set
ISM2String = readstring f
append String_array ISM2String
)
)

if SectionType_array[b] == 46 do(
printDebug("Texture data is located at 0x" + (bit.intAsHex(ftell f))as string)
SectionType = readBElong f
TextureHeaderLength = readBElong f
TextureTotal = readBElong f
TextureOffset_array = #()
for c = 1 to TextureTotal do(
TextureOffset = readBElong f
append TextureOffset_array TextureOffset
)
for c = 1 to TextureTotal do(
fseek f TextureOffset_array[c] #seek_set
sectiontype = readBElong f
TextureDataString1 = readBElong f + 1
TextureDataString1 = String_array[TextureDataString1]
TextureDataString2 = readBElong f + 1
TextureDataString2 = String_array[TextureDataString2]
TextureDataString3 = readBElong f + 1
TextureDataString3 = String_array[TextureDataString3]
TextureDataString4 = readBElong f + 1
TextureDataString4 = String_array[TextureDataString4]
texturestuff1 = readBElong f
texturestuff2 = readBElong f
texturestuff3 = readBElong f
texturename = TextureDataString4
texturepath = p + "TEXTURE/001/" + texturename
append TextureName_array texturepath
)
printDebug(TextureName_array)
)

if SectionType_array[b] == 97 do(
printDebug("Material data (97) is located at 0x" + (bit.intAsHex(ftell f))as string)

SectionType = readBElong f
MaterialHeaderLength = readBElong f
MatTotal = readBElong f
MatOffset_array = #()

for z = 1 to MatTotal do(
MatOffset = readBElong f
append MatOffset_array MatOffset
)

multimat = MultiMaterial()
multimat.name = "Neptunia"
multimat.numsubs = MatTotal

	for z = 1 to MatTotal do(
	fseek f MatOffset_array[z] #seek_set
	printDebug("Material data (13) is located at 0x" + (bit.intAsHex(ftell f))as string)
	SectionType = readBElong f
	HeaderLength = readBElong f
	MatSubTotal = readBElong f
	MatSubString1 = readBElong f + 1
	MatSubString1 = String_array[MatSubString1]
	MatSubString2 = readBElong f + 1
	MatSubString2 = String_array[MatSubString2]
	MatSubString3 = readBElong f + 1
	MatSubString3 = String_array[MatSubString3]
	append MatName_array MatSubString1
	Blank = readBElong f
	printDebug("Info: " + MatSubString1 as string + ", " + MatSubString2 as string + ", " + MatSubString3 as string)
		if MatSubTotal > 0 do(
		MatSubOffset = readBElong f
		fseek f MatSubOffset #seek_set
		printDebug("Material data (108) is located at 0x" + (bit.intAsHex(ftell f))as string)
		SectionType = readBElong f
		HeaderLength = readBElong f
		MatSubBTotal = readBElong f
			MatSubBOffset = readBElong f
			fseek f MatSubBOffset #seek_set
			printDebug("Material data (106) is located at 0x" + (bit.intAsHex(ftell f))as string)
			SectionType = readBElong f
			HeaderLength = readBElong f
			MatSubCTotal = readBElong f
			MatSubCString = readBElong f + 1
			MatSubCString = String_array[MatSubCString]
			Blank = readBElong f
			printDebug("Info: " + MatSubCString as string)
				MatSubCOffset = readBElong f
				fseek f MatSubCOffset #seek_set
				printDebug("Material data (107) is located at 0x" + (bit.intAsHex(ftell f))as string)
				SectionType = readBElong f
				HeaderLength = readBElong f
				MatSubDTotal = readBElong f
				MatSubDStuffA = readBElong f
				MatSubDStuffB = readBElong f
				Blank = readBElong f
				printDebug("Info: " + MatSubDStuffA as string + ", " + MatSubDStuffB as string)
					MatSubDOffset = readBElong f
					fseek f MatSubDOffset #seek_set
					printDebug("Material data (107-B) is located at 0x" + (bit.intAsHex(ftell f))as string)
					SectionType = readBElong f 
					HeaderLength = readBElong f
					MatSubETotal = readBElong f
					MatSubEStuffA = readBElong f
					MatSubEStuffB = readBElong f
					Blank = readBElong f
					printDebug("Info: " + MatSubEStuffA as string + ", " + MatSubEStuffB as string)
						MatSubEOffset = readBElong f
						fseek f MatSubEOffset #seek_set
						printDebug("Material data (107-C) is located at 0x" + (bit.intAsHex(ftell f))as string)
						MatTexName = readBElong f + 1
						MatTexName = String_array[MatTexName]
						printDebug("Info: " + MatTexName as string)
								append MatTexName_array MatTexName
		)
		if MatSubTotal == 0 do(
		MatTexName = "Tex_c.dds"
		append MatTexName_array MatTexName
		)
	)
	for z = 1 to MatTotal do(
	mat = multimat.materialList[z]
	mat.name = MatName_array[z] as string
	mat.showinviewport = true
	mat.twosided = false
	if TexFormat == 1 then (
		if TexPath == 1 then (
		tm = Bitmaptexture filename:(p + "TEXTURE/001/" + MatTexName_array[z] as string + ".dds")
		) else (
			tm = Bitmaptexture filename:(p + MatTexName_array[z] as string + ".dds")
		)
	) else (
		if TexPath == 1 then (
		tm = Bitmaptexture filename:(p + "TEXTURE/001/" + MatTexName_array[z] as string + ".png")
		) else (
			tm = Bitmaptexture filename:(p + MatTexName_array[z] as string + ".png")
		)
	)
	tm.alphasource = 0
	mat.diffuseMap = tm
	mat.opacityMap = tm
	mat.opacityMap.monoOutput = 1
	)

)

-- if SectionType_array[b] == 98 do(
-- printDebug("Unknown data (98) is located at 0x" + (bit.intAsHex(ftell f))as string)
-- )

)

	
if BNArrRig.count == 0 do(
for b = 1 to Vert_array.count do(
	append B1_array (Bone_Info_Struct Bone1:1 Bone2:1 Bone3:1 Bone4:1 Bone5:1 Bone6:1 Bone7:1 Bone8:1)
	append W1_array (Weight_Info_Struct Weight1:1 Weight2:0 Weight3:0 Weight4:0 Weight5:0 Weight6:0 Weight7:0 Weight8:0)
	)
	BNArrRig[1] = BNArr[1]
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

for j = 1 to BNArrRig.count do(
	if BNArrRig[j] == undefined do(
		BNArrRig[j] = BNArrRig[1]
		print ("Bone #" + j as string + " is invalid! Defaulting to root bone!")
		)
)

print Weight_array

msh = mesh vertices:Vert_array faces:Face_array
msh.name = g
msh.material = multimat

msh.numTVerts = Vert_array.count

defaultVCFaces msh
buildTVFaces msh
for j = 1 to UV_array.count do setTVert msh j UV_array[j]
for j = 1 to Face_array.count do (	
	setTVFace msh j Face_array[j]
	setFaceMatID msh j FaceTex_array[j]
)
for j = 1 to msh.numfaces do setFaceSmoothGroup msh j 1

max modify mode
select msh

      --set smoothing group of all faces to 1 to get one normal per vertex
      for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
      --set normals via edit normals modifier
      select msh
      addmodifier msh (Edit_Normals ()) ui:off
      msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
      EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
      EN_setNormal = msh.Edit_Normals.SetNormal
      normID = #{}
      --apply normals
      for v = 1 to Normal_array.count do
      (
         free normID
         EN_convertVS #{v} &normID
         for id in normID do EN_setNormal id Normal_array[v]
      )

skinMod = skin ()
addModifier msh skinMod

for i = 1 to BNArrRig.count do
(
   maxbone = getnodebyname BNArrRig[i].name
   if i != BoneTotal then
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
Print ("Done! ("+((((timestamp())-st)*0.001)as string)+" Seconds)")
enableSceneRedraw()
) else (print ("Not an ISM2 file!"))

gc()
fclose f
)
)

on btnFaceANM pressed do(
PosScale = 2.0
fname = getOpenFileName \ 
caption:"Compile Heart ANM Face File" \
types:"Compile Heart ANM Face File(*.anm)|*.anm" \
historyCategory:"CompileHeartISM1ObjectPresets"
if fname != undefined do(
f = fopen fname "rb"
clearlistener()

fseek f 0x00 #seek_set
VersionNum = readBEfloat f	

if VersionNum == 1.3 or VersionNum == 1.4 then (
	FaceCountA = readBElong f
	fseek f (0x60 * FaceCountA) #seek_cur
	FaceCountB = readBElong f
	for z = 1 to FaceCountB do(
		TexNum = readBElong f
		ExpressionType = readBElong f
		-- ExpressionType 0 = Base
		-- ExpressionType 1 = Right Eye
		-- ExpressionType 2 = Left Eye
		-- ExpressionType 3 = Right Eyelid
		-- ExpressionType 4 = Left Eyelid
		-- ExpressionType 5 = Right Eyebrow
		-- ExpressionType 6 = Left Eyebrow
		-- ExpressionType 7 = Mouth
		case ExpressionType of (
			0:(ExpressionType = "Base")
			1:(ExpressionType = "R.Pupil")
			2:(ExpressionType = "L.Pupil")
			3:(ExpressionType = "R.Eyelid")
			4:(ExpressionType = "L.Eyelid")
			5:(ExpressionType = "R.Eyebrow")
			6:(ExpressionType = "L.Eyebrow")
			7:(ExpressionType = "Mouth")
		)
		
		UnknownNum1 = readBElong f
		UnknownNum2 = readBElong f
		Chunk = readBElong f
		TexCenterX = (readBEfloat f * PosScale)
		TexCenterY = (readBEfloat f * PosScale)
		TexSizeX = (readBEfloat f * PosScale)
		TexSizeY = (readBEfloat f * PosScale)
		FloatA = readBEfloat f
		FloatB = readBEfloat f
		FloatC = readBEfloat f
		FloatD = readBEfloat f
		BlankFloat = readBEfloat f
		UnknownNum4 = readbyte f #unsigned
		print ("Tex #" + (TexNum as string) + ", " + (ExpressionType as string) + ", " + (UnknownNum1 as string) + ", " + (UnknownNum2 as string) + ", Chunk: " + (Chunk as string) + ", TexCenterX: " + (TexCenterX as string) + ", TexCenterY: " + (TexCenterY as string) + ", TexSizeX: " + (TexSizeX as string) + ", TexSizeY: " + (TexSizeY as string) + ", " + (FloatA as string) + ", " + (FloatB as string) + ", " + (FloatC as string) + ", " + (FloatD as string) + ", " + (UnknownNum4 as string) )
	)
	TexNameNum = readBElong f
	fseek f (0x20 * TexNameNum) #seek_cur
	print ("Extras:")
	ExtNum = readBElong f
	for x = 1 to ExtNum do(
		TexNum = readBElong f
		ExpressionType = readBElong f
		case ExpressionType of (
			0:(ExpressionType = "Base")
			1:(ExpressionType = "R.Pupil")
			2:(ExpressionType = "L.Pupil")
			3:(ExpressionType = "R.Eyelid")
			4:(ExpressionType = "L.Eyelid")
			5:(ExpressionType = "R.Eyebrow")
			6:(ExpressionType = "L.Eyebrow")
			7:(ExpressionType = "Mouth")
		)
		UnknownNum1 = readBElong f
		UnknownNum2 = readBElong f
		ChunkStart = readBElong f
		ChunkEnd = readBElong f
		UnknownFloat = (readBEfloat f * PosScale)
		UnknownNum3 = readbyte f #unsigned
		TexCenterX = (readBEfloat f * PosScale)
		TexCenterY = (readBEfloat f * PosScale)
		TexSizeX = (readBEfloat f * PosScale)
		TexSizeY = (readBEfloat f * PosScale)
		BlankFloat1 = readBEfloat f
		BlankFloat2 = readBEfloat f
		UnknownNum4 = readbyte f #unsigned
		UnknownNum5 = readbyte f #unsigned
		print ("Tex #" + (TexNum as string) + ", " + (ExpressionType as string) + ", " + (UnknownNum1 as string) + ", " + (UnknownNum2 as string) + ", ChunkStart: " + (ChunkStart as string) + ", ChunkEnd: " + (ChunkEnd as string) + ", " + (UnknownFloat as string) + ", TexCenterX: " + (TexCenterX as string) + ", TexCenterY: " + (TexCenterY as string) + ", TexSizeX: " + (TexSizeX as string) + ", TexSizeY: " + (TexSizeY as string) + ", " + (UnknownNum4 as string) + ", " + (UnknownNum5 as string))
	)
) else (
	FaceCountA = readlong f #unsigned
	fseek f (0x60 * FaceCountA) #seek_cur
	FaceCountB = readlong f #unsigned
	for z = 1 to FaceCountB do(
		TexNum = readlong f #unsigned
		ExpressionType = readlong f #unsigned
		case ExpressionType of (
			0:(ExpressionType = "Base")
			1:(ExpressionType = "R.Pupil")
			2:(ExpressionType = "L.Pupil")
			3:(ExpressionType = "R.Eyelid")
			4:(ExpressionType = "L.Eyelid")
			5:(ExpressionType = "R.Eyebrow")
			6:(ExpressionType = "L.Eyebrow")
			7:(ExpressionType = "Mouth")
		)
		UnknownNum1 = readlong f #unsigned
		UnknownNum2 = readlong f #unsigned
		Chunk = readlong f #unsigned
		TexCenterX = readfloat f
		TexCenterY = readfloat f
		TexSizeX = readfloat f
		TexSizeY = readfloat f
		FloatA = readfloat f
		FloatB = readfloat f
		FloatC = readfloat f
		FloatD = readfloat f
		BlankFloat = readfloat f
		UnknownNum4 = readbyte f #unsigned
		print ("Tex #: " + (TexNum as string) + ", " + (ExpressionType as string) + ", " + (UnknownNum1 as string) + ", " + (UnknownNum2 as string) + ", Chunk: " + (Chunk as string) + ", TexCenterX: " + (TexCenterX as string) + ", TexCenterY: " + (TexCenterY as string) + ", TexSizeX: " + (TexSizeX as string) + ", TexSizeY: " + (TexSizeY as string) + ", " + (FloatA as string) + ", " + (FloatB as string) + ", " + (FloatC as string) + ", " + (FloatD as string) + ", " + (UnknownNum4 as string) )
	)
	TexNameNum = readlong f
	fseek f (0x20 * TexNameNum) #seek_cur
	print ("Extras:")
	ExtNum = readlong f
	for x = 1 to ExtNum do(
		TexNum = readlong f
		ExpressionType = readlong f
		case ExpressionType of (
			0:(ExpressionType = "Base")
			1:(ExpressionType = "R.Pupil")
			2:(ExpressionType = "L.Pupil")
			3:(ExpressionType = "R.Eyelid")
			4:(ExpressionType = "L.Eyelid")
			5:(ExpressionType = "R.Eyebrow")
			6:(ExpressionType = "L.Eyebrow")
			7:(ExpressionType = "Mouth")
		)
		UnknownNum1 = readlong f
		UnknownNum2 = readlong f
		ChunkStart = readlong f
		ChunkEnd = readlong f
		UnknownFloat = (readfloat f * PosScale)
		UnknownNum3 = readbyte f #unsigned
		TexCenterX = (readfloat f * PosScale)
		TexCenterY = (readfloat f * PosScale)
		TexSizeX = (readfloat f * PosScale)
		TexSizeY = (readfloat f * PosScale)
		BlankFloat1 = readfloat f
		BlankFloat2 = readfloat f
		UnknownNum4 = readbyte f #unsigned
		UnknownNum5 = readbyte f #unsigned
		print ("Tex #: " + (TexNum as string) + ", " + (ExpressionType as string) + ", " + (UnknownNum1 as string) + ", " + (UnknownNum2 as string) + ", ChunkStart: " + (ChunkStart as string) + ", ChunkEnd: " + (ChunkEnd as string) + ", " + (UnknownFloat as string) + ", TexCenterX: " + (TexCenterX as string) + ", TexCenterY: " + (TexCenterY as string) + ", TexSizeX: " + (TexSizeX as string) + ", TexSizeY: " + (TexSizeY as string) + ", " + (UnknownNum4 as string) + ", " + (UnknownNum5 as string))
	)
	)


)
)

)

CreateDialog ISM2Importer
clearListener()