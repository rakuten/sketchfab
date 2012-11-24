/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-08-04
Last Updated: 2012-09-30
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	zip-methods for the sketchfab script
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	2012-09-30: added message to the progressbar
</SCRIPTFILE>
*******************************************************************************************************/
(
struct zipStruct
(
	--http://forums.cgsociety.org/showthread.php?t=800618
	--based on code by Rene Baca, MerlinEl
	/* Functionality:
	-add files from a folder in to zip
	-add also subfolder files if subdirs sets to true
	-delete old files if deleteOld sets to true */			
	all_dirs = #(),
	all_files = #(),
	
	fn getDirTree dir =
	(
		all_dirs += curr_dirs = getDirectories (dir+"*")
		for i in curr_dirs do getDirTree i
	),
	
	fn getAllFiles dirs =
	(
		for d in dirs do all_files += getFiles (d + "*")
	),
	
	fn deleteOldFiles files =
	(
		for i in files do try deleteFile i catch (format "The file: %\tcannot be deleted.\n" i)
	),
	
	function fn_zipFiles sourcePath: targetPath: zipName: useSubdirs:true deleteOld:false =
	(
		/*<FUNCTION>
		Description:
			packages files together in a zipfile. Uses the max-native maxzip.exe to perform the zipping.
		Arguments:
			<string> sourcePath: the path to the folder from which the contents needs to be zipped
			<string> targetPath: the folder where the zipfile has to be stored
			<string> zipName: the name of the zipfile
		Return:
			<string> the path of the generated zipfile
		</FUNCTION>*/
		local zipFile
		
		try
		(
			sketchfab.gui.roll_sketchfab.wwwSketchfab.caption = "Zipping the model and textures, please hold"
			--reset the file and dir-containers
			all_files = #()
			all_dirs = #()
			
			--error check to see if the specified path exists
			if not doesFileExist sourcePath or not doesFileExist targetPath do return false
				
			--collecting files with full path
			all_files = getFiles (sourcePath + "*")   -- root dir files
			if useSubdirs do --also collect files from subdirs, recursively
			(
				getDirTree sourcePath --collect all subdirs in dir in to local all_dirs
				if all_dirs.count != 0 do getAllFiles all_dirs -- collect files from subdirs
			)
			print all_files
			format "Number of files: %\n" all_files.count
			
			if all_files.count == 0 do return false
			
			-- generate a zip.tmp file with the list of files to be archived
			--TODO: make sure this path exists by creating the folder
			--TODO: check if an alternative folder is an option
			local theTempFile
			local theTempFilePath = "C:/temp/" + "~zip.tmp" -- targetPath --need a path without any spaces!!
			makeDir (getFilenamePath  theTempFilePath)
			if doesFileExist theTempFilePath do deleteFile theTempFilePath -- delete old tmp file if exist
			try (theTempFile = createFile theTempFilePath) catch (print "File: " + theTempFilePath + "cannot be created"; return false)
			for i in all_files do format "%\n" (substituteString i sourcePath "") to:theTempFile --slice off the common root. Only possible when working from a drive-letter, not a unc-path. Why? Unknown!
			flush theTempFile
			close theTempFile
			
			-- archive the all_files into the zip
			local curDir = sysInfo.currentDir -- store current system dir
			local zipUtil = (getDir #maxRoot) + "maxzip.exe" 
			zipFile = targetPath + zipName + ".zip"
			local cmd = "" as stringStream
			format "\"%\" \"%\" @%" zipUtil zipFile theTempFilePath to:cmd -- thanks to ofer_z--zipFile needs to be a mapped drive?
			sysInfo.currentDir = sourcePath-- set system folder (zip tree begins here)
			(hiddendosCommand cmd exitcode:&exitcode) --EXECUTE THE ZIPPING
			sysInfo.currentDir = curDir -- restore old system dir

			--delete old files if is true
			if deleteOld do deleteOldFiles all_files
			--delete folders WIP
			
			--output the code returned by maxzip. For a list of possible codes, check here: http://www.info-zip.org/mans/zip.html under DIAGNOSTICS
			format "zip-status:%\n" exitcode
			sketchfab.gui.roll_sketchfab.wwwSketchfab.caption = ""
		)catch
		(
			sketchfab.error.scriptError message:"zip.fn_zipFiles"
		)
		zipfile --return the path of the zipfile
	)
)

--load the struct into the main script-struct
sketchfab.zip = zipStruct()
)