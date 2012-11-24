/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-09-03
Last Updated: 2012-10-19
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Methods for posting models to sketchfab in a multipart/form-data manner. According to the new API stuff isn't sent 
	as a json anymore but as a "simple" html post. Other languages make this easy, but in dotnet it's a bit tricky. The entire 
	request has to be built by hand.
Usage:
	Use together with the sketchfab system

Features:

Wishlist:
	Add an error-handler around the getresponse
Changelog:
	2012-09-26: adjusted the fn_parseResponse to accomodate for varying responses. As of now the warning of a broken thumbnail seems to be gone...
	2012-09-30: added the fn_convertFile2Base64 method to the struct
	2012-09-30: fn_convertFile2Base64 now streams the result directly to a json-file.
	2012-09-30: increased the timeout for the upload. Default was set to 100 seconds, which is too short for larger files.
	2012-10-16: adjusted the posting-process to reflect teh new api. No more json or base64. Now it's a html file-post.
	2012-10-17: adjusted fn_parseResponse to be able to parse the repsonse according to the new api
	2012-10-19: added the source-parameter
</SCRIPTFILE>
*******************************************************************************************************/


(
	struct str_htmlPost
	(
		/*<STRUCT>
		Description:
			This struct contains all the elements needed to post a model to sketchfab. 
			made it work with the help of cedric pinson
			http://social.msdn.microsoft.com/Forums/nn-NO/ncl/thread/0b5988bf-abc3-42fb-b428-cfd041ad2744
			http://stackoverflow.com/questions/566462/upload-files-with-httpwebrequest-multipart-form-data
			http://aspnetupload.com/Upload-File-POST-HttpWebRequest-WebClient-RFC-1867.aspx
		</STRUCT>*/
		
		--API V2
		title = "",
		description = "",
		fileModel = "", --"model.obj" --the name of the actual 3D model within the zipfile
		filenameModel = "", --"model.zip" --name of the file which is to be sent to sketchfab. A zip-file in our case
		tags = "",  --list of space separated tags, optional
		token = "", -- your sketchfab API token
		isPrivate = false,
		password = "",
		source = "", --this represents the max-version
		
		--other settings
		theResponse = undefined,
		readerString = undefined, --the result of sending the json
		
		function fn_post strPath: =
		(
			/*<FUNCTION>
			Description:
				Post a file with the correct credentials to sketchfab.
			Arguments:
				<string> strPath: The location of the file on disk.
			Return:
				<bool> Function returns (anything?).
			</FUNCTION>*/
			
			local boundaryString = "klaasnienhuis_sketchfab_publisher123456789" --this string is used to separate specefif sections of the webrequest
			
			--create a HttpWebRequest with a specific uri
			global req = dotnetclass "system.net.HttpWebRequest"
			req = req.create sketchfab.url
			req.method = "POST" --setting the method to post
			req.timeOut = 1000000 --(100 seconds)
			req.ContentType = ("multipart/form-data; boundary=" + boundaryString)
			req.AllowWriteStreamBuffering = false --prevents the entire file from being read into memory anyways.
			
			--START BUILDING THE REQUEST
			--setup the key-value pairs for the form-data and store them in a byte-array
			local strFormDataTemplate = "" as StringStream
			local arrKey = #(#("title",sketchfab.htmlpost.title),#("token",sketchfab.htmlpost.token),#("filenameModel",sketchfab.htmlpost.filenamemodel),#("description",sketchfab.htmlpost.description),#("tags",sketchfab.htmlpost.tags),#("private",sketchfab.htmlpost.isprivate),#("password",sketchfab.htmlpost.password))
			for keys in arrKey do format "\r\n--%\r\nContent-Disposition: form-data; name=\"%\"\r\n\r\n%" boundaryString keys[1] keys[2] to:strFormDataTemplate
			local formBytes =  ((dotnetObject "System.Text.UTF8Encoding").getbytes (strFormDataTemplate as string))

			--write the fileheader to the requeststream
			local fileHeaderStream = "" as StringStream
			format "\r\n--%\r\nContent-Disposition: form-data; name=\"fileModel\"; filename=\"%\"\r\nContent-Type: application/octet-stream\r\n\r\n" boundaryString sketchfab.htmlpost.filemodel to:fileHeaderStream
			local fileHeaderBytes =  ((dotnetObject "System.Text.UTF8Encoding").getbytes (fileHeaderStream as string))
			
			--write the trailing string to a bytearray
			local trailingBytes = ((dotnetObject "System.Text.ASCIIEncoding").getbytes ("\r\n--" + boundaryString + "--\r\n"))
			
			--open the model-file as a max-binaryStream. This should keep memoryconsumption low
			local theBinStream = fOpen strPath "rb" --open the input file as a stream
			fseek theBinStream 0 #seek_end --find the end of the file
			local theEnd =  (ftell theBinStream ) as integer --get the last position of the file
			fseek theBinStream 0 #seek_set--reset the position to the beginning of the stream
			
			--determine the total length of the request and specify that in the header of the request
			req.ContentLength = formBytes.count + fileHeaderBytes.count + theEnd + trailingBytes.count
			
			--write bytes to the requeststream
			local reqStream = req.GetRequestStream() --open the requeststream
			reqStream.write formBytes 0 formBytes.count --write the key-value pair
			reqStream.write fileHeaderBytes 0 fileHeaderBytes.count --write the key-value pair

			local bufferLength = 65536 --we're reading and uploading the file in bunches of 65536 bytes 4096, 8192, 16384, 32768, 65536
			local startByte = 0
			local theCondition = true
			
			while theCondition do
			(
				--binary stream
				local bytesRead = (for i = (startByte +1) to (startByte+bufferLength) where i <= theEnd collect ReadByte theBinStream) --read a bunch of bytes
				
				if bytesRead.count > 0 then
				(
					--here we're writing the bytes to the stream of the WebRequest (uploading)
					reqStream.Write bytesRead 0 bytesRead.count
					--update caption and progressbar
					sketchfab.gui.roll_sketchfab.wwwSketchfab.caption = ""
					sketchfab.gui.roll_sketchfab.wwwSketchfab.caption =  "Uploading model, " + (((startByte+bytesRead.count)/1024) as string) + " of "+ ((theEnd/1024) as string) + " kb"
					sketchfab.gui.roll_sketchfab.pgbUpload.value = ((((startByte as float)+bytesRead.count)/theEnd)*100.0)
				)else
				(
					theCondition = false
				)
				startByte += bytesRead.count
			)
			FClose theBinStream
			
			--add a trailing boundary
			reqStream.write trailingBytes 0 trailingBytes.count --write the trailer

			reqStream.flush()
			reqStream.Close()
			local myResponse
			try(myResponse = req.GetResponse())catch(sketchfab.error.scriptError message:"Webrequest couldn't be sent")
			
			sketchfab.gui.roll_sketchfab.pgbUpload.value = 0
			
			myResponse
		),
		
		function fn_parseResponse = if sketchfab.htmlpost.theResponse != undefined do 
		(
			/*<FUNCTION>
			Description:
				Parse the response of the httpRequest and print it out.
				also changes the hyperlinks in the gui. They link directly to the uploaded model if teh upload is succesful
			Arguments:
			Return:
			</FUNCTION>*/
			
			--do dotnet stuff to get a string out of the httpResponse
			local dataStream = sketchfab.htmlpost.theResponse.GetResponseStream()
			local reader = dotnetobject "system.io.streamreader" dataStream
			sketchfab.htmlpost.readerstring = reader.ReadToEnd()
			
			--do some string parsing to print the response out nicely
			local newReader = substituteString sketchfab.htmlpost.readerstring "{" "#("
			newReader = substituteString newReader  "}" ")"
			newReader = substituteString newReader  ": " ","
			local arrResponse  = execute newReader --the response is something like this: #("result", #("id", "aHeKY6Q0WJm1JQqF5dgtIjBXaPU"), "success", true) (2012-10-17 API V2)
			
			--print the response
			for i = 1 to arrResponse.count do 
			(
				--display link to open the model
				if arrResponse[i] == true do
				(
					sketchfab.gui.roll_sketchfab.wwwSketchfab.address = "Http://sketchfab.com/show/" + arrResponse[2][2]
					sketchfab.gui.roll_sketchfab.wwwSketchfab.caption = "Open model " + sketchfab.htmlpost.title
				)
			)
		)			
	)
	sketchfab.htmlpost = str_htmlPost()
)