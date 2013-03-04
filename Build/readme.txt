Welcome to the readme of the SketchfabPublisher script. The readme contains a list of the contents of the installer and some instructions on how to install the script.
You can install the mzp-file by dropping it onto any viewport, or by running it from the menu: MAXScript>>Run file...
If you want to check out the contents of the mzp-file yourself, you can unzip it just like a zip-file.

A message from the developer
	This script enables you to publish models directly to your sketchfab account on www.sketchfab.com.
	License: GPL, http://opensource.org/licenses/gpl-3.0.html
	Support: sketchfab@klaasnienhuis.nl
	Contact: twitter: klaasnienhuis, blog www.klaasnienhuis.nl

name "Sketchfab"
description "Klaas Nienhuis Scripts"
version 7.3

The following files are copied to your system
	scriptfiles\sketchfab.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_dae.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_errorHandling.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_gui.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_htmlPost.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_multithread.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_obj.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_rolloutFunctions.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_token.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	scriptfiles\sketchfab_zip.ms >> $userScripts\KlaasTools\Sketchfab\scriptfiles\
	art\sketchfabBanner_007.jpg >> $userScripts\KlaasTools\Sketchfab\art\
	art\sketchfab_16i.bmp >> $userIcons\
	art\sketchfab_24i.bmp >> $userIcons\
	art\sketchfab_24i.ico >> $userIcons\
	installfiles\KlaasNienhuis_Sketchfab_Install.ms >> $userScripts\KlaasTools\Sketchfab\
	presets\obj_preset_sketchfab.ini >> $userScripts\KlaasTools\Sketchfab\presets\
	presets\opencollada_preset_sketchfab.ini >> $userScripts\KlaasTools\Sketchfab\presets\

If dropped on the viewport, the following scripts are executed
	KlaasNienhuis_Sketchfab_Install.ms

If executed by the menu: MAXScript>>Run file... the following scripts are executed 
	KlaasNienhuis_Sketchfab_Install.ms

