--the macro used to link the script to a button or menu-item
macroScript Sketchfab category:"Klaas Tools" tooltip:"Sketchfab 7.3" buttonText:"Sketchfab" Icon:#("sketchfab",1) 
(
	fileIn ((getDir #userScripts)+"\\KlaasTools\\Sketchfab\\scriptfiles\\sketchfab.ms") quiet:true
)

--the messagebox which tells you something has been installed and where to find it
messageBox "Sketchfab v7.3 has now been installed!\n\nTo run it goto:\nCustomize -> Customize User Interface -> Toolbars\nCategory: \"Klaas tools\" and drag \"Sketchfab\" to a toolbar.\n\nClick the toolbar icon to run it!"

--initializes the icons, so the sketchfab icon should show up upon first install
colorman.reInitIcons()
