/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-07-27
Last Updated: 2012-08-23
Version: 6

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	The methods related to the obj-fileformat: presets and exporting
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	2012-07-27: adjusted the fn_addPreset2List-method. It should correctly add the preset to the presets-file now.
	2012-07-27: adjusted fn_replaceCurrentPreset to ignore any other external presets
	2012-08-04: improved implementing of the obj-presets
	2012-08-04: removed the hardcoded obj-preset. The preset is stored now in an ini-file shipped with the script
	2012-08-04: disabled fn_replaceCurrentPreset and fn_createNewExportPreset
	2012-09-23: added a timer and improved handling of the export dialogs. Removed the button-press for the user
	2012-10-18: added timestamp to export-folder. This avoids teh nagging messages if you use the same name for an export twice.
</SCRIPTFILE>
*******************************************************************************************************/
(


	
struct str_obj
(
	iniPresets =  (GetDir #plugcfg) + "/gw_objexp_presets.ini", --a list of exportpresets. Only exists if the user has used the presets system before and changed a preset
	iniSettings = (GetDir #plugcfg) + "/gw_objexp.ini", --a single exportpreset
	presetName = "Sketchfab",
	objExportTimer = dotnetobject "Timer", --this timer is used to wait for the correct button to appear on the obj-export dialogs
	
	function event_onTick control arg = 
	(
		/*<FUNCTION>
		Description:
			This handler sits on the dotnet-timer and listens when the "DONE" button on the obj-exporter appears
			this is a workaround suggested by DenisT because the #noprompt parameter on the obj-exporter is broken.
		Arguments:
		Return:
		</FUNCTION>*/
		
		if (uiaccessor.getwindowtext control.tag[2]) == undefined do 
		(
			control.Stop()
		)
		if (uiaccessor.getwindowtext control.tag[2]) == "-= DONE =-" do 
		(
			uiaccessor.pressbutton control.tag[2]
			control.Stop()
		)
		if keyboard.escpressed do 
		(
			control.Stop()
		)
	),
	
	function fn_addPreset2List forcePreset:false =
	(
		/*<FUNCTION>
		Description:
			Adds the obj-preset to the obj-presetslist on disk, only if the list already exists and if the preset doesn't exist yet
		Arguments:
			<boolean> forcePreset: Forces an overwrite of the sketchfab preset
		Return:
			a preset is added to the obj-presetsfile
		</FUNCTION>*/
		
		local arrPreset = getINISetting sketchfab.obj.iniPresets
		
		--check for a sketchfab preset
		if findItem arrPreset sketchfab.obj.presetName == 0 OR forcePreset do
		(
			--add the new presetname to the list of presetnames
			local strPresetList = getINISetting sketchfab.obj.iniPresets "ExportPresets" "PresetNames"
			strPresetList += ","
			strPresetList += sketchfab.obj.presetName
			setINISetting sketchfab.obj.iniPresets "ExportPresets" "PresetNames" strPresetList
			
			--add all settings from the preset in the objPreset struct to the ini-file
			setINISetting sketchfab.obj.iniPresets sketchfab.obj.presetName "ID" ((strPresetList.count-1)  as string) --add an ID to the preset. It's at the end of the list
			local arrSection = getINISetting (sketchfab.scriptpath + "/obj_preset_sketchfab.ini")
			for s in arrSection where s != "General" do
			(
				local arrPropNames = getINISetting (sketchfab.scriptpath + "/obj_preset_sketchfab.ini") s
				for p in arrPropNames do setINISetting sketchfab.obj.iniPresets sketchfab.obj.presetName p (getINISetting (sketchfab.scriptpath + "/obj_preset_sketchfab.ini") s p)
			)
			
		)
		
		--edit the gw_objexp file to use this new preset
		setINISetting sketchfab.obj.iniSettings "General" "Preset" sketchfab.obj.presetName
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
		deleteFile sketchfab.obj.iniSettings
		
		--copy the native preset to the local machine
		local boolCopySuccess = copyFile (sketchfab.scriptpath + "/presets/obj_preset_sketchfab.ini") sketchfab.obj.iniSettings 
	),
	
	function fn_insertSketchfabObjExportPreset =
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
			if NOT sketchfab.obj.fn_copyPresetFile() do throw "OBJ-Preset can't be copied"
			
			--check if gw_objexp_presets exists
			if doesfileExist sketchfab.obj.iniPresets then
			(
				sketchfab.obj.fn_addPreset2List()
			)else
			(
				--edit the gw_objexp file to use the NONE preset
				setINISetting sketchfab.obj.iniSettings "General" "Preset" "<NONE>"
			)
		)catch(sketchfab.error.scriptError message:"OBJ-preset couldn't be created")
	),
	
	function fn_objExportCallback =
	(
		/*<FUNCTION>
		Description:
			Workaround by DenisT: http://forums.cgsociety.org/showpost.php?p=7358888&postcount=12
			This method can be used in a callback. It will press the "Export" and the "DONE" button on the obj-export dialog.
			This needs to be done in order to also export the maps correctly. Normally you'd use the #noprompt flag for this
			when exporting, but that one's bugged. It won't export your maps.
		Arguments:
		Return: true
		</FUNCTION>*/
		
		local WindowHandle = DialogMonitorOPS.GetWindowHandle()
		local theDialogName = UIAccessor.GetWindowText WindowHandle
		
		case theDialogName of 
		(
			"OBJ Export Options":
			(
				UIAccessor.PressButtonByName WindowHandle "Export"
			)
			"Exporting OBJ": --this dialog boasts a button which changes name after all the items have been exported. We use a timer to wait for the correct name
			(
				local theButton = windows.getchildhwnd WindowHandle "Cancel Export"
				sketchfab.obj.objExportTimer.tag = #(WindowHandle, theButton[1])
				sketchfab.obj.objExportTimer.Start()
			)
		)		
		true
	),
	
	function fn_exportSelected2Obj theSelection strName: strFileType:".obj"=
	(
		/*<FUNCTION>
		Description:
			Exports the selected objects to an obj-file on disk. Uses the temp-location of the max install
		Arguments:
			<object array> theSelection: an array of objects
			<string> strName: the name of the file
			<string> strFileType: the filetype to export to. Set to obj as default
		Return:
			<string> The directory with the generated export
		</FUNCTION>*/
		local theDir
		try
		(
			--this dialogmonitor is here to press some buttons for the user
			DialogMonitorOPS.unRegisterNotification id:#sketchfabObjExport
			DialogMonitorOPS.RegisterNotification sketchfab.obj.fn_objExportCallback ID:#sketchfabObjExport
			DialogMonitorOPS.Enabled = true		
			
			--a timestamp string
			local arrTime = getLocalTime()
			local theTime = "" as StringStream
			format "%.%.%_%.%.%-" arrTime[1] (formattedprint arrTime[2] format:"02d") (formattedprint arrTime[4] format:"02d") (formattedprint arrTime[5] format:"02d") (formattedprint arrTime[6] format:"02d") (formattedprint arrTime[7] format:"02d") to:theTime

			--set up the export
			theDir = (getdir #temp) + "/sketchfabExport/" + (theTime as string) + strName + "/"--base folder needs to be on a mapped drive or a physical disk. This makes it possible to slice off the common rootpath.
			makedir theDir
			local theFileName = theDir + strName + strFileType
			exportFile theFileName selectedOnly:true --using #noprompt will skip exporting the bitmaptextures, that's why I can't use this
			
			--disable the dialog monitor
			DialogMonitorOPS.Enabled = false
			DialogMonitorOPS.unRegisterNotification id:#sketchfabObjExport
		)catch
		(
			sketchfab.error.scriptError message:"main.fn_exportSelected2Obj"
		)
		theDir
	),
	
	--setup the dotnet timer with an interval and handler
	setinterval = (objExportTimer.interval = 100),
	handler = 	dotnet.addEventHandler objExportTimer "Tick" event_onTick
	
)
sketchfab.obj = str_obj()
)