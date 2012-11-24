/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-07-26
Last Updated: 2012-07-26
Version: 6

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	This script handles the token in the sketchfab system
Usage:
	Runs automatically when the sketchfab publisher is run

Features:

Wishlist:
Changelog:
	2012-07-26: moved to a separate file
	2012-08-13: made the ini-path relative to the current scriptpath
</SCRIPTFILE>
*******************************************************************************************************/

(
struct str_token 
(
	/*<STRUCT>
	Description:
		This struct contains methods to handle an ini-file with a token. The ini-file is created at first use
		The user can then enter his token and it's stored in the ini-file.
		There's no security whatsoever. the token is stored as text.
	</STRUCT>*/
	
	iniPath = sketchfab.scriptpath + "/sketchfab.ini",
	
	function fn_getTokenFromIni iniPath =
	(
		/*<FUNCTION>
		Description:
			Gets a tokenvalue from the inifile.
		Arguments:
			<string> iniPath: the path where the inifile should be		
		Return:
			<token> a tokenvalue.
		</FUNCTION>*/
		
		local theToken = getINISetting iniPath "Sketchfab" "apitoken" 
		theToken
	),
	
	function fn_storeTokenInIni iniPath theToken:"" clearToken:false =
	(
		/*<FUNCTION>
		Description:
			Stores a token value in the inifile.
		Arguments:
			<string> iniPath: the path where the inifile should be		
			<token> theToken: A tokenvalue
			<boolean> clearToken: clears the token from the inifile
		Return:
			A new token has been stored
		</FUNCTION>*/
		
		if clearToken then theToken = ""
		setINISetting iniPath "Sketchfab" "apitoken" theToken
	),
	
	function fn_createTokenIni iniPath =
	(
		/*<FUNCTION>
		Description:
			Creates a new ini-file which is going to hold the token-value. This means the token 
			doesn't need to be entered every session.
		Arguments:
			<string> iniPath: the path where the inifile should be
		Return:
			creates a new ini-file on disk if it doesn't exist already
		</FUNCTION>*/
		
		if not doesFileExist iniPath do
		(
			makedir (getFilenamePath inipath)
			setINISetting iniPath "Sketchfab" "apitoken" ""
		)
	)
)

--load the struct into the main script-struct
sketchfab.token = str_token()
)