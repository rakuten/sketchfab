/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-10-11
Last Updated: 2012-10-19
Version: 1

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	The GUI for sketchfab
Usage:
	RUN IT

Features:

Wishlist:
	update gui to also contain private and password settings. Password has to be filled in manually or randomly generated and is printed out to the listener upon upload
Changelog:
	2012-10-17: removed all references to the json struct and replaced them with the htmlpost-struct
	2012-10-17: replaced the send-button with a dotnet-button
	2012-10-17: added a checkbox for the "private" option
	2012-10-18: replaced the dotnet-button with a devexpress one
	2012-10-18: replaced the standard progressbar with an only slightly better looking dotnet one
	2012-10-19: added the source-parameter
	2012-10-23: removed the devexpress button due to compatibility issues with max 2010
	2013-02-27: added check for empty token
	2013-02-27: new gamma setting for the banner
</SCRIPTFILE>
*******************************************************************************************************/

(
	struct str_gui
	(
		roll_sketchfab, --the rollout
		roll_TagDescription,
		roll_token,
		floater = undefined,
		ToolTipObj = dotnetobject "System.Windows.Forms.ToolTip",
		
		function fn_updateProgress theProgress theMax theMessage:undefined =
		(
			/*<FUNCTION>
			Description:
				Update the progressbar and display a message.
			Arguments:
				<int/float> theProgress: the progress we're at.
				<int/float> theMax: the maximum value
				<string> theMessage: the message to be displayed, if undefine, the message isn't altered
			Return:
			</FUNCTION>*/

			if hasproperty sketchfab.gui.roll_sketchfab.pgbUpload "value" == true do --check this if the progressbar still exists. Multithreading allows the user to close the dialog when it's still uploading stuff
			(
				--update the progress
				local theProgress = ((theProgress as float)/(theMax as float))*100.0
				sketchfab.gui.roll_sketchfab.pgbUpload.value = theProgress
				
				--update the message
				if theMessage != undefined do
				(
					sketchfab.gui.roll_sketchfab.wwwSketchfab.caption = theMessage
-- 					augmentedev.gui.roll_augmentedev.lblMessage.caption = theMessage
-- 					augmentedev.gui.roll_augmentedev.lblMessage2.text = theMessage
				)
			)
		),
		
		function fn_defineRollouts =
		(
			/*<FUNCTION>
			Description:
				Defines all rollouts in teh sketchfab system.
			Arguments:
			Return:
			</FUNCTION>*/
			
			rollout roll_sketchfab "Publish to sketchfab"
			(
				imgTag imgGrab width:224 height:140 transparent:red
				label lblTitle "Title" align:#left
				dotnetcontrol txtTitle_save "textbox" width:224
				dotnetcontrol btnSend "Button" width:224 height:40 offset:[0,15]
				hyperlink wwwSketchfab "" address:"" color:orange align:#left visitedColor:orange
				dotNetControl pgbUpload "Windows.Forms.Progressbar" width:224 height:16		
				dropdownlist ddlExporter items:#(".obj") selection:1 across:3
				checkbox chkMakePrivate_save "Private" offset:[10,3] tooltip:"Check this option if you want to hide your model from the public homepage of Sketchfab."
				hyperlink wwwKlaas "Get help online" address:"http://www.klaasnienhuis.nl/WordPress/tag/sketchfab/" color:orange align:#right visitedColor:orange offset:[-4,3]

				on roll_sketchfab open do
				(
					--style the send-button
					local theButton = sketchfab.gui.roll_sketchfab.btnSend
					theButton.flatStyle = theButton.flatStyle.flat
					theButton.backColor = (dotnetclass "system.drawing.color").FromArgb 20 152 211
					theButton.foreColor = (dotnetclass "system.drawing.color").FromArgb 255 255 255
					theButton.text = "Publish selected objects to Sketchfab"
					
					--load some gui-settings
					sketchfab.myRollloutFunctions.loadFloaterPosition sketchfab.gui.floater sketchfab.guiIni
					sketchfab.myRollloutFunctions.loadControlSettings sketchfab.gui.roll_sketchfab sketchfab.guiIni
					
-- 					--get the token from the ini and put it in the gui
					sketchfab.htmlpost.token = sketchfab.token.fn_getTokenFromIni sketchfab.token.iniPath
					
					--init the tooltips
					sketchfab.gui.ToolTipObj.SetToolTip sketchfab.gui.roll_sketchfab.txtTitle_save "Enter the title for the objects"
					sketchfab.gui.ToolTipObj.SetToolTip sketchfab.gui.roll_sketchfab.btnSend "Press to send the selected objects to your account on Sketchfab"
					sketchfab.gui.ToolTipObj.SetToolTip sketchfab.gui.roll_sketchfab.pgbUpload "Shows the progress when publishing a model to Sketchfab"
					
					--check which exporters are present. Add them to the list if they're there
					local arrExporters = sketchfab.gui.roll_sketchfab.ddlExporter.items
	-- 				local boolCollada = sketchfab.collada.fn_detectExporter()
					local boolCollada = false --disable the collada exporter for now untill sketchfab has better support for it.
					if boolCollada then
					(
						append arrExporters ".dae"
					)else
					(
	-- 					append arrExporters "Get OpenCollada: http://opencollada.org"
					)
					
					ddlExporter.items = arrExporters
					--load the current exporter from the ini-file
					local iniPath = sketchfab.scriptpath + "/sketchfab.ini"
					local theExporter = getINISetting iniPath "Sketchfab" "exporter"
					if theExporter != "" do 
					(
						sketchfab.exporter = theExporter
						local index = findItem sketchfab.gui.roll_sketchfab.ddlExporter.items theExporter
						if index != 0 do sketchfab.gui.roll_sketchfab.ddlExporter.selection = index
					)
					
					
					--create the banner
					local myGamma = 2.2
					if IDisplayGamma.colorCorrectionMode == #gamma do myGamma = fileInGamma/displayGamma --this calculation results in the correct gamma for the banner
					local bmpBanner = openbitmap sketchfab.thumbnailPath
					local guiImage = bitmap bmpBanner.width bmpBanner.height gamma:myGamma--this is the image we're outputting our screengrab to
					pasteBitmap bmpBanner guiImage [0,0] [0,0] --crop the screengrab
					imgGrab.bitmap = guiImage
					
					--create the export-preset
					sketchfab.obj.fn_insertSketchfabObjExportPreset()
-- 					sketchfab.collada.fn_insertSketchfabColladaExportPreset()
				)
				
				on ddlExporter selected arg do
				(
					local boolExporter = true
					case arg of
					(
						1: sketchfab.exporter = ".obj"
						2: 
						(
							boolExporter = sketchfab.collada.fn_detectExporter()
							if boolExporter do sketchfab.exporter = "OpenCollada"
						)
					)
					if boolExporter do
					(
						local iniPath = sketchfab.scriptpath + "/sketchfab.ini"
						setINISetting iniPath "Sketchfab" "exporter" sketchfab.exporter
					)
				)
				
				on roll_sketchfab close do
				(
					sketchfab.myRollloutFunctions.saveFloaterPosition sketchfab.gui.floater sketchfab.guiIni
					sketchfab.myRollloutFunctions.saveControlSettings sketchfab.gui.roll_sketchfab sketchfab.guiIni
					
					DialogMonitorOPS.Enabled = false
					DialogMonitorOPS.unRegisterNotification id:#sketchfabObjExport
				)
				
				
				on btnSend mouseclick do
				(
					case of
					(
						(sketchfab.gui.roll_sketchfab.txtTitle_save.text == ""): messagebox "Please fill in a title" title:"No title present"
						(selection.count == 0): messagebox "Please select some objects" title:"No selection active"
						(sketchfab.gui.roll_token.txtToken.text == ""): messagebox "Please enter a token, get it from your sketchfab account" title:"No token entered"
-- 						(sketchfab.gui.roll_sketchfab.imgGrab.bitmap == undefined): messagebox "Please create a thumbnail" title:"No thumbnail present"
						default: 
						(
							--diagnostics code
							gc()
							sketchfab.startTime = timestamp()
							sketchfab.memory = heapfree	
							
							--store variables which need to be posted to the server
							local theToken = trimleft sketchfab.gui.roll_token.txtToken.text
							theToken = trimright theToken
							sketchfab.htmlpost.token = theToken
							sketchfab.htmlpost.title = sketchfab.gui.roll_sketchfab.txtTitle_save.text
							sketchfab.htmlpost.description = sketchfab.gui.roll_TagDescription.txtDescription_save.text
							sketchfab.htmlpost.tags = sketchfab.gui.roll_TagDescription.txtTags_save.text + " 3dsMaxPublisher" --add my own tag
							sketchfab.htmlpost.isPrivate = sketchfab.gui.roll_sketchfab.chkMakePrivate_save.checked
							sketchfab.htmlpost.filenameModel = sketchfab.htmlpost.title + ".zip" --we're sending a zip-file. That's why the extension of the filename also needs to be .zip.
							sketchfab.htmlpost.fileModel = sketchfab.htmlpost.title + sketchfab.exporter
							sketchfab.htmlpost.source = "3dsMax_" + ((maxversion())[1] as string)
							
							sketchfab.chainThreads = true --this parameter makes sure all threaded operations happen consecutively
							
							--export the selected objects in a separate thread
							if not sketchfab.thread.exportThread.IsBusy do sketchfab.thread.exportThread.RunWorkerAsync()
						)
					)
					
				)
			) --end rollout
			
			rollout roll_TagDescription "Tags and description"
			(
				label lblTags "Tags (space separated)" align:#left offset:[0,0]
				dotnetcontrol txtTags_save "textbox" width:224 height:40			
				label lblDescription "Description " align:#left offset:[0,8]
				dotnetcontrol txtDescription_save "textbox" width:224 height:60 
				
				on roll_TagDescription open do
				(
					
					sketchfab.gui.roll_TagDescription.txtDescription_save.multiline = true
					sketchfab.gui.roll_TagDescription.txtDescription_save.text = "Published by 3ds Max"
					sketchfab.gui.roll_TagDescription.txtTags_save.multiline = true
					sketchfab.gui.roll_TagDescription.txtTags_save.text = "3dsMax "
					
					--load some gui-settings
					sketchfab.myRollloutFunctions.loadControlSettings sketchfab.gui.roll_TagDescription sketchfab.guiIni
					
					--init the tooltips
					sketchfab.gui.ToolTipObj.SetToolTip sketchfab.gui.roll_TagDescription.txtTags_save "Use tags to categorize your model"
					sketchfab.gui.ToolTipObj.SetToolTip sketchfab.gui.roll_TagDescription.txtDescription_save "Add a description, supports basic html like links and images"
					
				)
				
				on roll_TagDescription close do
				(
					sketchfab.myRollloutFunctions.saveControlSettings sketchfab.gui.roll_TagDescription sketchfab.guiIni
				)
				
			)
				
			rollout roll_token "Token"
			(
				dotnetcontrol txtToken "textbox" width:224
				checkbox chkShowToken "Show token" checked:false offset:[0,6] tooltip:"Show the characters of the token, just to check it."
				dotnetcontrol btnManualToken "Button" width:224 height:40 offset:[0,2]

-- 				button btnManualToken "Token not working? Enter it manually here
-- 				and restart script afterwards..." height:35 tooltip:"If the token doesn't seem to work even if it's correct, try entering it in the storagefile yourself"
				
				on roll_token open do
				(
					--style the send-button
					local theButton = sketchfab.gui.roll_token.btnManualToken
-- 					theButton.flatStyle = theButton.flatStyle.flat
-- 					theButton.backColor = (dotnetclass "system.drawing.color").FromArgb 14 116 0
-- 					theButton.foreColor = (dotnetclass "system.drawing.color").FromArgb 255 255 255
					theButton.text = "Token not working? Click button to enter directly in file. Restart script afterwards."
					
					--display the tokenvalue in the rollout
					sketchfab.gui.roll_token.txtToken.text = sketchfab.token.fn_getTokenFromIni sketchfab.token.iniPath
					sketchfab.gui.roll_token.txtToken.useSystemPasswordChar = (not sketchfab.gui.roll_token.chkShowToken.checked)
					
					--init the tooltips
					sketchfab.gui.ToolTipObj.SetToolTip sketchfab.gui.roll_token.txtToken "Enter your token here. You need it to publish to your account. \nGet your token from your dashboard on Sketchfab"
					sketchfab.gui.ToolTipObj.SetToolTip sketchfab.gui.roll_token.btnManualToken "If the token doesn't seem to work even if it's correct,\ntry entering it in the storagefile yourself"
					
				)
				
				on txtToken keyup control arg do
				(
					sketchfab.token.fn_storeTokenInIni sketchfab.token.iniPath theToken:sketchfab.gui.roll_token.txtToken.text clearToken:false
					sketchfab.htmlpost.token = sketchfab.gui.roll_token.txtToken.text
				)
				
				on chkShowToken changed arg do
				(
					sketchfab.gui.roll_token.txtToken.useSystemPasswordChar = (not sketchfab.gui.roll_token.chkShowToken.checked)
				)
				
				on btnManualToken mouseclick do
				(
					sketchfab.token.fn_createTokenIni sketchfab.token.iniPath
					ShellLaunch "notepad.exe" sketchfab.token.iniPath
				)
			)			
		),
		define = fn_defineRollouts()
	)
	
	
	struct str_tooltip
	(
		ttTitle,
		ttSend,
		
		function fn_create =
		(
			local theTooltip = dotNetObject "system.windows.forms.tooltip"
			theTooltip.setTooltip sketchfab.gui.roll_sketchfab.txtTitle_save "Enter the title for the objects"
		),
		
		
		design = fn_create()
	)
	sketchfab.gui = str_gui()
-- 	sketchfab.tooltip = str_tooltip()
)

