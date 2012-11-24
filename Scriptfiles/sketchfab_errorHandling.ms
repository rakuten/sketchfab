/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-07-26
Last Updated: 2012-09-23
Version: 1

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Error handling structs. Largely adapted from tim hawker's excellent nested layer manager
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	2012-09-23: edited errorhandling to make more sense with my script
	2012-09-23: improved saving of the error-file
</SCRIPTFILE>
*******************************************************************************************************/


(
	struct errorhandlingStruct (
		
		--Script error function is fired in the catch component of a try within a function.
		function scriptError message:"undefined" = (
			
			--stop a timer
			sketchfab.obj.objExportTimer.stop()
			
			--Print to listener
			try ( format ("Sketchfab: I'm very sorry, it seems an error has occurred\nError Occured In: %\nError Message: % \n" ) message (getCurrentException())) catch()
			
			--Create log and show message to user about error. Ask if log should be saved.
			try (
				local errorLog = "" as StringStream
				format "Sketchfab Publisher Error Report Log \n" to:errorLog
				format "Please send to sketchfab@klaasnienhuis.nl to help bugfixing, thanks!\n\n" to:errorlog
				format "Sketchfab version: %\n" sketchfab.version to:errorLog
				format "Max version: %\n" (maxversion())[1] to:errorlog
				format "Date & Time: %\n" localTime to:errorLog
				format "Error Occured In: %\n" message to:errorLog
				format "Exception Information: %\n\n\n" (getCurrentException()) to:errorLog
				format "THREADS:\n" to:errorlog
				threads to:errorlog --writes the threads to the errorlog. Some processes in the publisher are multithreaded, so this makes sense.
				format "\nSTACK INFORMATION:\n" to:errorLog
				stack to:errorlog --writes the error-stack to the errorlog
				
				if queryBox "Sketchfab Publisher has experienced an unexpected error and will close after this message. Would you like to save an error log report? \n\nPlease send log reports to me for bug fixing. My email is sketchfab@klaasnienhuis.nl" title:"Sketchfab Publisher" do
				(	
					--set up a universal timestamp
					local t = getLocalTime()
					local parsedTime = t[1] as string + "-" + (formattedprint t[2] format:"02u") + "-" + (formattedprint t[4] format:"02u") + " " + (formattedprint t[5] format:"02u") + "-" + (formattedprint t[6] format:"02u") + "-" + (formattedprint t[7] format:"02u")

					--set up a filename for the errormessage
					local fileName = "Sketchfab Publisher Log Report " + parsedTime + ".txt"
					local fileDir = getSaveFileName caption:"Save Log File..." fileName:fileName
					
					--create a file and write the errolog to that file
					if fileDir != undefined do (
						local txtFile = createFile fileDir
						format (errorLog as string) to:txtFile
						close txtFile
					)
				)
			) catch (
				messageBox "An error has occured creating the error report." title:"Sketchfab Publisher"
			)
			
			
-- 			try (
-- 				nestedLayerManager.io.save altErrorHandle:true
-- 				nestedLayerManager.ui.mf.dispose()
-- 			)catch(
-- 				nestedLayerManager.ui.mf.dispose()
-- 			)
			
			try (
				sketchfab = undefined
				gc light:true
			) catch()
			
			try (
				fileIn (sketchfab.scriptfile + "/sketchfab_publisher.ms")
			) catch (
				messageBox "Sketchfab publisher has failed to reload.\nRestarting 3ds Max may fix the problem." \
				title:"Sketchfab Publisher"
			)
			
			updateToolBarButtons()
			
		)--,
		
-- 		function saveError = (
-- 			messageBox "Yikes. An error occured whilst trying to save Nested Layer Manager. Please save this file iteratively to avoid any potential data loss.\n\nIf you did save a log file please send it to me so that I can debug this error. (tim@timsportfolio.co.uk)" \
-- 			title:"Nested Layer Manager"
-- 		)
		
	)--End Struct
	
	sketchfab.error = errorhandlingStruct()
	
)