/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-05-30
Last Updated: 2012-10-19
Version: 7

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Publishes selected geometry to sketchfab
	
	to check if a json-file is valid, use this website: http://jsonlint.com/
Usage:
	RUN IT

Features:
	Multithreading, methods and suggestions taken from Lonerobot and Lukas duber
		http://lonerobot.net/?p=50
		http://forums.cgsociety.org/showpost.php?p=6986723&postcount=79
	Zip methods based on code by Rene Baca, MerlinEl
		http://forums.cgsociety.org/showthread.php?t=800618
	A hardcoded OBJ-preset with optimal settings for sketchfab
	A collada exporter with a baked in preset
	
Wishlist:

	a "clear temp" option
	use dotnet interface
	
	
Changelog:
	2012-05-30: base-struct works. Converting an obj-file to a base64 string, creating a json-file and posting it to the server of sketchfab with an api token.
	2012-06-06: added fn_captureCroppedScreengrab for capturing a screengrab to add as an image with the upload
	2012-06-20: adjusted the thumbnail size according to message from Cedric and Alban
	2012-06-22: added basic multithreading, needs to be implemented in the right places though
	2012-06-22: added obj-presets and obj-methods. This enables me to force optimal obj-settings and keep them hidden to the user.
	2012-06-22: somewhat altered the structure of the script. Now using nested structs and exposed just a single global struct: sketchfab
	2012-06-23: finalized the obj-preset handling. The correct preset is now inserted before exporting. No user-interaction needed to pich the correct export-settings
	2012-06-23: added multithreading to the export and zip
	2012-06-24: finished all multithreading. Either perform each thread separately or chain the threads to run one after another automatically
	2012-06-24: added fn_parseResponse which prints out the response nicely
	2012-06-24: added some dotnet textfields and reshuffled the GUI
	2012-06-24: added new bannerimage. This image also displays the screenshot of the model
	2012-06-25: added the token-ini struct and methods to handle the storage of the token
	2012-06-26: solved an issue where the bitmaps wouldn't be exported. Used the hwnd-system with a callback to click buttons on the export-menu
	2012-06-27: setup correct gamma-settings for the generated thumbnail. It will match the viewport correctly when gamma is on or off.
2012-06-27: V3 RELEASED
	2012-07-08: folder for zip-files is automatically created
	2012-07-17: removed verbatim strings (@"sadfasdf/asdf") to improve compatibility with max 9
	2012-07-18: worked on getting the file streamed to sketchfab, using filestream of binarystream. Converting a string to a dotnet-bytearray is too slow: (dotnetclass "System.Text.Encoding").UTF8.GetBytes "someStringHere"
	2012-07-18: finished the streaming of the data
	2012-07-18: added a progressbar
2012-07-18: V5 RELEASED
	2012-07-26: externalized the token struct
	2012-08-13: made the ini-path relative to the current scriptpath
	2012-07-27: externalized the obj and objPreset struct
	2012-07-27: adjusted the obj-preset methods. It should work with the presetfiles correctly now.
	2012-08-04: externalized the zip-methods
	2012-08-04: added dropdown to pick an exporter. This choice is sticky
	2012-08-08: added opencollada support
	2012-08-13: added a check which tells you if you have the opencollada exporter
	2012-08-13: added a field for tags
	2012-08-13: moved the description and tags fields to a separate rollout
	2012-08-29: added a source-field to the json file. This parameter contains the versionnumber of the current max-session
	2012-09-23: externalized multithreading
	2012-09-23: externalize json methods
	2012-09-23: imporved the flow of exporting to an obj. Implemented denisT's workaround for the #noprompt bug with the obj-exporter
	2012-09-23: moved out some methods to their repsective structs
	2012-09-26: added streamed version of fn_convertFile2Base64. Doesn't deliver consistently on the memory-reduction yet. Maybe output to a file directly instead of a variable
	2012-09-26: disabled the collada export till sketchfab has better support for it
	2012-09-26: adjusted the fn_parseResponse to accomodate for varying responses. As of now the warning of a broken thumbnail seems to be gone...
	SKETCHFAB_OBJ
	2012-07-27: adjusted the fn_addPreset2List-method. It should correctly add the preset to the presets-file now.
	2012-07-27: adjusted fn_replaceCurrentPreset to ignore any other external presets
	2012-08-04: improved implementing of the obj-presets
	2012-08-04: removed the hardcoded obj-preset. The preset is stored now in an ini-file shipped with the script
	2012-08-04: disabled fn_replaceCurrentPreset and fn_createNewExportPreset
	2012-09-23: added a timer and improved handling of the export dialogs. Removed the button-press for the user	
	SKETCHFAB_ERRORHANDLING
	2012-09-23: edited errorhandling to make more sense with my script
	2012-09-23: improved saving of the error-file	
2012-09-26: V6 BETA RELEASED	
	2012-09-30: now the base64 is streamed and not stored in variables. Also when during uploading an error occurs, the script doesn't try to print out the entire json file which effectively freezes your max session
	2012-10-04: edited the json to use the new API. Doesn't seem supported completely by sketchfab though. Error report sent.
	2012-10-11: separated the gui-methods from the main startup-system
	2012-10-16: added support for the new API. Finaly succeeded in uploading a file
	2012-10-17: added the htmlpost struct. This should replace the json struct
	2012-10-17: added the loading and saving of some gui-settings
	2012-10-19: added a secondary development location
</SCRIPTFILE>
*******************************************************************************************************/
(
	try(closeRolloutFloater sketchfab.gui.floater)catch() --kill any previously created dialog
	
-- 	local basePath = "//STRATUS/data/SketchfabExporter/Scripts/Version_07" --developing location1
-- 	local basePath = "C:\Documents and Settings\klaas\My Documents\Downloads\Version_07\Version_07" --developing location2
-- 	local basepath = @"N:\GitHub\sketchfab"
	local basePath = (getDir #userscripts) + "/KlaasTools/Sketchfab" --publishing location
	
	struct str_sketchfab
	(
		/*<STRUCT>
		Description:
			A struct which contains all parameters and methods needed to construct a json-file for sketchfab and post it
		Members:
			<string> member_a: a description of the member
		</STRUCT>*/

		--nested structs
		htmlpost, --this struct takes care of posting stuff to a server
		thread, --the multuthreading struct
		zip, --the zipping struct
		obj, --the obj methods
		collada, --the collada methods
		token, --the token methods
		error, --handles the error handling
		gui, --the gui for the script
		myRollloutFunctions, --methods which load and save sticky stuff, like floater-positions
		
		--other parameters
		exportedModelPath = undefined, --the path to the exported 3d-model
		zipFilePath = undefined,
		url= "https://api.sketchfab.com/v1/models",
		guiIni =  basePath + "/rolloutSettings.ini", --settings regarding the gui
		thumbnailPath =  basePath + "/art/sketchfabBanner_007.jpg",
		startTime = undefined,

		chainThreads = true, --if set to true, all threads are executed one after another. If set to false, each thread needs to be executed individually
		memory = undefined, --used for memory diagnostics
		scriptpath = "", --the path which stores the installed script
		exporter = ".obj", --string representing the current exporter
		version = 7.1,
		hideTokenRollout = true
	)
	
	global sketchfab = str_sketchfab scriptpath:basePath --create the working instance of the main struct
	
	--load the scriptfiles one by one
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_token.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_obj.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_dae.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_zip.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_htmlpost.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_multithread.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_errorhandling.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_gui.ms")
	fileIn (basePath + "\\scriptfiles" + "\\sketchfab_rolloutFunctions.ms")


)

--setup the rollout-states depending on the presence of a token in the ini-file
--if there's no token yet, the token-rollout will be the only one open. this prompts the user to provide the token 
--before trying to publish anything	
if (sketchfab.token.fn_getTokenFromIni sketchfab.token.iniPath) == "" do sketchfab.hideTokenRollout = false

--putting these lines out of scope helps make the startup work and not crap out.
sketchfab.gui.floater = newRolloutFloater ("Publish to sketchfab " + sketchfab.version as string) 264 408
addRollout sketchfab.gui.roll_sketchfab sketchfab.gui.floater rolledup:(not sketchfab.hideTokenRollout)
addRollout sketchfab.gui.roll_TagDescription sketchfab.gui.floater rolledup:true
addRollout sketchfab.gui.roll_token sketchfab.gui.floater rolledup:sketchfab.hideTokenRollout

