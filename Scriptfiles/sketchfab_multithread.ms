/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-09-23
Last Updated: 2012-10-17
Version: 1

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	The multithreading methods for the sketchfab exporter
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	2012-09-30: changed the flow in the multithreading. merged creating the json and the base64's. The base64's are being streamed inside the json directly.
	2012-09-30: diabled the searate threads for creating the base64's (zip and thumb). this is done together with the json now.
	2012-10-04: edited the flow of threading. The base64 has been ditched in the new API. The model, mtl-file and textures are zipped together with a json-file.
	2012-10-11: cleaned out some methods due to the simplification of the submitting process
	2012-10-17: replaced all json-entries with htmlpost entries
	2013-03-04: renamed struct members to ensure compatibility with 3dsMax 2014
</SCRIPTFILE>
*******************************************************************************************************/

(
struct str_multithreading
(
	exportThread = dotnetobject "CSharpUtilities.SynchronizingBackgroundWorker",
	zipThread = dotnetobject "CSharpUtilities.SynchronizingBackgroundWorker",
	postHtmlThread = dotnetobject "CSharpUtilities.SynchronizingBackgroundWorker",
	
	function event_workExportThread control arg =
	(
		/*<FUNCTION>
		Description:
			This event executes the export in a separate thread. The result is passed onto a different event.
		Arguments:
			<bool> arg_a: A description of the argument.
		Return:
			<bool> Function returns (anything?).
		</FUNCTION>*/
		
		local theDir --the directory to which the files will be exported to
		case sketchfab.exporter of
		(
			".obj": 
			(
				sketchfab.obj.fn_insertSketchfabObjExportPreset() --create the correct export-preset
				theDir = sketchfab.obj.fn_exportSelected2Obj selection strName:sketchfab.htmlpost.title --export the selected objects to a directory
			)
			".dae": 
			(
				sketchfab.collada.fn_insertSketchfabColladaExportPreset() --create the correct export preset
				theDir = sketchfab.collada.fn_exportSelected selection strName:sketchfab.htmlpost.title --export the selected objects to a directory
			)
		)
		arg.Result = theDir --the directory where the files have been exported to
	),
	
	function event_CompleteExportThread control arg =
	(
		/*<FUNCTION>
		Description:
			do something with the result of the export-thread.
		Arguments:
			<bool> arg_a: A description of the argument.
		Return:
			<bool> Function returns (anything?).
		</FUNCTION>*/
		
		sketchfab.exportedModelPath = arg.result
		if sketchfab.chainThreads AND not sketchfab.thread.zipThread.IsBusy do sketchfab.thread.zipThread.RunWorkerAsync()
	),
	
	function event_workZipThread control arg =
	(
		/*<FUNCTION>
		Description:
			This event executes the zip in a separate thread. The result is passed onto a different event.
		Arguments:
			<bool> arg_a: A description of the argument.
		Return:
			<bool> Function returns (anything?).
		</FUNCTION>*/
		
		local theZipFile = sketchfab.zip.fn_zipFiles sourcePath:sketchfab.exportedModelPath targetPath:sketchfab.exportedModelPath zipName:sketchfab.htmlpost.title--zip this directory to a single file
		arg.Result = theZipFile
	),
	
	function event_CompleteZipThread control arg =
	(
		/*<FUNCTION>
		Description:
			do something with the result of the zip-thread.
		Arguments:
			<bool> arg_a: A description of the argument.
		Return:
			<bool> Function returns (anything?).
		</FUNCTION>*/
		
		sketchfab.zipFilePath = arg.result
		if sketchfab.chainThreads AND not sketchfab.thread.postHtmlThread.IsBusy do sketchfab.thread.postHtmlThread.RunWorkerAsync()
	),
	
	function event_workpostHtmlThread control arg =
	(
		/*<FUNCTION>
		Description:
			This event executes the zip in a separate thread. The result is passed onto a different event.
		Arguments:
			<bool> arg_a: A description of the argument.
		Return:
			<bool> Function returns (anything?).
		</FUNCTION>*/
		
		local myresponse = sketchfab.htmlpost.fn_post strPath:(sketchfab.exportedModelPath + sketchfab.htmlpost.title + ".zip")
		arg.Result = myresponse		
	),
	
	function event_CompletepostHtmlThread control arg =
	(
		/*<FUNCTION>
		Description:
			do something with the result of the zip-thread.
		Arguments:
			<bool> arg_a: A description of the argument.
		Return:
			<bool> Function returns (anything?).
		</FUNCTION>*/
		
		sketchfab.htmlpost.theResponse = arg.result --store the response of the httprequiest
		if sketchfab.chainThreads do format "Sending scene to sketchfab\n\t% ms\n\tmemory %\n" (timestamp()-sketchfab.startTime) (sketchfab.memory-heapfree)

		--print the response to the listener
		sketchfab.htmlpost.fn_parseResponse()
	),
	
	function fn_initExportThread theTread =
	(
		/*<FUNCTION>
		Description:
			initializes the event-handlers for the thread
		Arguments:
		Return:
		</FUNCTION>*/
		
		--Initialise event handlers
		theTread.WorkerSupportsCancellation = true
		theTread.WorkerReportsProgress = true
		dotNet.addEventHandler theTread "DoWork" event_workExportThread
		dotNet.addEventHandler theTread "RunWorkerCompleted" event_CompleteExportThread
		if theTread.IsBusy do theTread.CancelAsync()		
	),

	function fn_initZipThread theTread =
	(
		/*<FUNCTION>
		Description:
			initializes the event-handlers for the thread
		Arguments:
		Return:
		</FUNCTION>*/
		
		--Initialise event handlers
		theTread.WorkerSupportsCancellation = true
		theTread.WorkerReportsProgress = true
		dotNet.addEventHandler theTread "DoWork" event_workZipThread
		dotNet.addEventHandler theTread "RunWorkerCompleted" event_CompleteZipThread
		if theTread.IsBusy do theTread.CancelAsync()		
	),

	function fn_initpostHtmlThread theTread =
	(
		/*<FUNCTION>
		Description:
			initializes the event-handlers for the thread
		Arguments:
		Return:
		</FUNCTION>*/
		
		--Initialise event handlers
		theTread.WorkerSupportsCancellation = true
		theTread.WorkerReportsProgress = true
		dotNet.addEventHandler theTread "DoWork" event_workpostHtmlThread
		dotNet.addEventHandler theTread "RunWorkerCompleted" event_CompletepostHtmlThread
		if theTread.IsBusy do theTread.CancelAsync()		
	),
	
	init1 = fn_initExportThread exportThread,
	init2 = fn_initZipThread zipThread,
	init3 = fn_initpostHtmlThread postHtmlThread
	
)
sketchfab.thread = str_multithreading()
)