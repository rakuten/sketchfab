/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-08-04
Last Updated: 2012-09-23
Version: 1

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	The methods related to the collada-fileformat: presets and exporting. The methods are adapted to the opencollada format.
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	2012-08-08: added the copying of the preset-ini for the opencollada
	2012-08-08: added the export-method for opencollada
	2012-09-23: edded errorhandling for the fn_exportSelected-method
</SCRIPTFILE>
*******************************************************************************************************/
(

	
struct colladaStruct
(
	iniPreset =  (GetDir #maxData) + "OpenCOLLADA.ini", --the exportpreset for the opencollada files

	function fn_detectExporter =
	(
		/*<FUNCTION>
		Description:
			Detect if the opencollada plugin has been installed.
		Arguments:
		Return:
		</FUNCTION>*/
		
		local theClasses =exporterPlugin.classes
		local theIndex = findItem theclasses OpenCOLLADAExporter
		case theIndex of
		(
			0: 
			(
				print	"The opencollada exporter has not been found, please download it first: http://opencollada.org/"
				false
			)
			default: 
			(
				print "The opencollada exporter is present. Proceeding now"
				true
			)
		)
	),
	
	function fn_copyPresetFile =
	(
		/*<FUNCTION>
		Description:
			Copies the installed presetfile to the local machine. This should help installing the right preset on multiple max-versions
		Arguments:
		Return:
		</FUNCTION>*/
		
		--delete the existing preset
		deleteFile sketchfab.collada.iniPreset
		
		--copy the native preset to the local machine
		local boolCopySuccess = copyFile (sketchfab.scriptpath + "/opencollada_preset_sketchfab.ini") sketchfab.collada.iniPreset 
	),
	
	function fn_insertSketchfabColladaExportPreset =
	(
		/*<FUNCTION>
		Description:
			inserts the sketchfab preset where it needs to go. Checks in all relevant places.
		Arguments:
		Return:
		</FUNCTION>*/
		
		try
		(
			--copy the preset-file to the local machine
			if NOT sketchfab.collada.fn_copyPresetFile() do throw "Collada-Preset can't be copied"
		)catch(sketchfab.error.scriptError message:"Collada-preset couldn't be created")
	),
	
	function fn_exportSelected theSelection strName: strFileType:".dae"=
	(
		/*<FUNCTION>
		Description:
			Exports the selected objects to a collada-file on disk. Uses the temp-location of the max install
		Arguments:
			<object array> theSelection: an array of objects
			<string> strName: the name of the file
			<string> strFileType: the filetype to export to. Set to dae as default
		Return:
			<string> The directory with the generated export
		</FUNCTION>*/
		local theDir
		try
		(
			theDir = (getdir #temp) + "/sketchfabExport/" + strName + "/"--base folder needs to be on a mapped drive or a physical disk. This makes it possible to slice off the common rootpath.
			makedir theDir
			local theFileName = theDir + strName + strFileType
			exportFile theFileName #noprompt selectedOnly:true using:OpenCOLLADAExporter
		)catch
		(
			sketchfab.error.scriptError message:"collada.fn_exportSelected"
		)
		theDir
	)
	
)
sketchfab.collada = colladaStruct()
)