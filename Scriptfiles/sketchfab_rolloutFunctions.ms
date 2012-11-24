/*******************************************************************************************************
<SCRIPTFILE>
Created: 2012-10-01
Last Updated: 2012-10-01
Version: 0.10

Author: Klaas Nienhuis, mail@klaasnienhuis.nl, www.klaasnienhuis.nl
Version: 3ds max 2012

Description:
	Methods which help in managing gui-presets. taken from Johan Boekhovens's talk at the EUE
Usage:
	RUN IT

Features:

Wishlist:
Changelog:
	2012-10-17: adding support for storing values of dotnet controls on max-rollouts, first up: dotnet textbox
</SCRIPTFILE>
*******************************************************************************************************/

(
	struct myRollloutFunctions
	(
		/**********************/
		/* LOAD SAVE SETTINGS */
		/**********************/

		fn saveControlSettings myRollout cfgFile =
		(
			try
			(
				for ctrl in myRollout.controls where matchPattern (ctrl as string) pattern:"*_save*" do
				(
					case classof ctrl of
					(
						SpinnerControl : 
						(
							setIniSetting cfgFile "Spinners_value" ctrl.name (ctrl.value as string)
							setIniSetting cfgFile "Spinners_enabled" ctrl.name (ctrl.enabled as string)
						)
						SliderControl : setIniSetting cfgFile "Sliders" ctrl.name (ctrl.value as string)
						CheckButtonControl : setIniSetting cfgFile "CheckButtons" ctrl.name (ctrl.state as string)
						CheckBoxControl : setIniSetting cfgFile "CheckBoxes" ctrl.name (ctrl.state as string)
						EditTextControl : setIniSetting cfgFile "EditTexts" ctrl.name ctrl.text
						ColorPickerControl : setIniSetting cfgFile "ColorPickers" ctrl.name (ctrl.color as string)
						RadioControl : setIniSetting cfgFile "RadioButtons" ctrl.name (ctrl.state as string)
						dotnetcontrol: 
						(
							case of
							(
								(matchpattern (ctrl as string) pattern:"*System.Windows.Forms.TextBox*" ): setIniSetting cfgFile "Dotnetcontrols" (ctrl as string) ctrl.text
							)
						)
					)
				)
			)catch(print "Some saving errors have occured while saving settings for the gui.")
		), -- end storeControlSettings
		
		fn loadControlSettings myRollout cfgFile =
		(
			try
			(
				for ctrl in myRollout.controls where matchPattern (ctrl as string) pattern:"*_save*" do
				(
					case classof ctrl of
					(
						SpinnerControl : 
						(
							ctrl.value = execute (getIniSetting cfgFile "Spinners_value" ctrl.name)
							ctrl.enabled = execute (getIniSetting cfgFile "Spinners_enabled" ctrl.name)
						)
						SliderControl : ctrl.value = execute (getIniSetting cfgFile "Sliders" ctrl.name)
						CheckButtonControl : ctrl.state = execute (getIniSetting cfgFile "CheckButtons" ctrl.name)
						CheckBoxControl : ctrl.state = execute (getIniSetting cfgFile "CheckBoxes" ctrl.name)
						EditTextControl : ctrl.text = getIniSetting cfgFile "EditTexts" ctrl.name
						ColorPickerControl : ctrl.color = execute (getIniSetting cfgFile "ColorPickers" ctrl.name)
						RadioControl : ctrl.state = execute (getIniSetting cfgFile "RadioButtons" ctrl.name)
						dotnetcontrol: 
						(
							case of
							(
								(matchpattern (ctrl as string) pattern:"*System.Windows.Forms.TextBox*" ): ctrl.text = getIniSetting cfgFile "Dotnetcontrols" (ctrl as string)--setIniSetting cfgFile "RadioButtons" ctrl (ctrl.text as string)
							)
						)
						
					)
				)
			)catch(print "Some loading errors have occured or reverting to default settings")
			
		), -- end loadControlSettings
		
		--ROLLOUT POSITIONS
		fn saveRolloutPosition myRollout cfgFile =
		(
			try(setIniSetting cfgFile "UI" "Position" ((GetDialogPos myRollout) as string))catch()
		), -- end saveRolloutPosition
		
		fn loadRolloutPosition myRollout cfgFile = 
		(
			try( SetDialogPos myRollout (execute(getIniSetting cfgFile "UI" "Position")) )catch(print "Reverting to default rolloutposition")
		), -- end loadRolloutPosition
		
		--FLOATER POSITIONS
		fn saveFloaterPosition myFloater cfgFile =
		(
			try(setIniSetting cfgFile "UI" "FloaterPosition" ((myFloater.pos) as string))catch()
		),
		
		fn loadFloaterPosition myFloater cfgFile = 
		(
			try( myFloater.pos = (execute(getIniSetting cfgFile "UI" "FloaterPosition")) )catch(print "Reverting to default floaterposition")
		)
		
		
	)
	sketchfab.myRollloutFunctions = myRollloutFunctions()
)