﻿import gfx.controls.RadioButton;
import gfx.controls.ButtonGroup;
import gfx.io.GameDelegate;
import gfx.ui.InputDetails;
import Shared.GlobalFunc;
import gfx.ui.NavigationCode;
import gfx.managers.FocusHandler;

import skyui.components.ButtonPanel;
import skyui.defines.ButtonArtNames;
import skyui.util.Debug;
import skyui.VRInput;
import skyui.util.GlobalFunctions;

class Quest_Journal extends MovieClip
{
	#include "../version.as"

	var bTabsDisabled: Boolean;

	var iCurrentTab: Number;

	var BottomBar: MovieClip;
	var BottomBar_mc: MovieClip;
	var TextPanel: MovieClip;

	var PageArray: Array;

	public var previousTabButton: MovieClip;
	public var nextTabButton: MovieClip;
	var TopmostPage: MovieClip;
	var QuestsFader: MovieClip;
	var StatsFader: MovieClip;
	var SystemFader: MovieClip;

	var QuestsTab: RadioButton;
	var StatsTab: RadioButton;
	var SystemTab: RadioButton;
	var TabButtonGroup: ButtonGroup;

	var ConfigPanel: MovieClip;

  public static var PAGE_QUEST: Number = 0;
  public static var PAGE_STATS: Number = 1;
  public static var PAGE_SYSTEM: Number = 2;
	public static var QUESTS_TAB: Number = 0;
	public static var STATS_TAB: Number = 1;
	public static var SETTINGS_TAB: Number = 2;

	function Quest_Journal()
	{
		super();
		BottomBar_mc = BottomBar;
		PageArray = new Array(QuestsFader.Page_mc, StatsFader.Page_mc, SystemFader.Page_mc);
		TopmostPage = QuestsFader;
		bTabsDisabled = false;
		iCurrentTab = Quest_Journal.PAGE_QUEST;
	}

	function InitExtensions()
	{
		GlobalFunc.SetLockFunction();

		ConfigPanel = _root.ConfigPanelFader.configPanel;

		QuestsTab.disableFocus = true;
		StatsTab.disableFocus = true;
		SystemTab.disableFocus = true;

		TabButtonGroup = ButtonGroup(QuestsTab.group);
		TabButtonGroup.addEventListener("itemClick", this, "onTabClick");
		TabButtonGroup.addEventListener("change", this, "onTabChange");

		GameDelegate.addCallBack("RestoreSavedSettings", this, "RestoreSavedSettings");
		GameDelegate.addCallBack("onRightStickInput", this, "onRightStickInput");
		GameDelegate.addCallBack("HideMenu", this, "DoHideMenu");
		GameDelegate.addCallBack("ShowMenu", this, "DoShowMenu");
		GameDelegate.addCallBack("StartCloseMenu", this, "CloseMenu");
		GameDelegate.addCallBack("OnShow", this, "OnShow");
		GameDelegate.call("ShouldShowMod", [], this, "SetShowMod");

		BottomBar_mc.InitBar();

		ConfigPanel.initExtensions();
	}

	function OnShow(): Void
	{
		Debug.log(">> Quest_Journal OnShow");
		Debug.dump("skse:", skse, false, 1);
		Debug.dump("skse.plugins:", skse["plugins"], false, 1);
		var vrinput = skse["plugins"]["vrinput"];
		if(vrinput != undefined)
		{
			Debug.log("vrinput plugin detected");
			vrinput.ShutoffButtonEventsToGame(true);
			vrinput.RegisterInputHandler(this, "handleVRInput");
			VRInput.init();
		} else {
			Debug.log("vrinput plugin not available");
		}

    QuestsTab.disableFocus = true;
    StatsTab.disableFocus = true;
    SystemTab.disableFocus = true;
    QuestsTab.disabled = false;
    StatsTab.disabled = false;
    SystemTab.disabled = false;
    BottomBar_mc.InitBar();
    var pageCursor = 0;
    while(pageCursor <= Quest_Journal.PAGE_SYSTEM)
    {
      var page = PageArray[pageCursor];
      Shared.Macros.BSASSERT(page != null && page != undefined,"Unable to open page " + pageCursor);
      Shared.Macros.BSASSERT(page.OnShow != null && page.OnShow != undefined,"page does not have OnShow function");
      page.OnShow();
      if(pageCursor == iCurrentTab)
      {
        page.startPage();
      }
      pageCursor = pageCursor + 1;
    }
    if(TopmostPage != null && TopmostPage != undefined)
    {
      TopmostPage.gotoAndPlay("fadeIn");
    }

		Debug.log("<< Quest_Journal OnShow");
	}

	function SetShowMod(): Void
	{
		PageArray[Quest_Journal.PAGE_SYSTEM].SetShowMod(arguments[0]);
	}

	function RestoreSavedSettings(aiSavedTab: Number, abTabsDisabled: Boolean): Void
	{
		// For some reason, the game will ask for the tab to be set to 0 (PAGE_QUEST)
		// *every* time after 'OnShow' is called.
		// This means the player will always be sent to the Quest page when the
		// quest_journal menu is brought up.
		// Strangely, the vanilla VR interface does not suffer from this problem.
		if(aiSavedTab != 0)
			iCurrentTab = Math.min(Math.max(aiSavedTab, 0), TabButtonGroup.length - 1);

		bTabsDisabled = abTabsDisabled;
		if (bTabsDisabled) {
			iCurrentTab = TabButtonGroup.length - 1;
			QuestsTab.disabled = true;
			StatsTab.disabled = true;
		}
		SwitchPageToFront(iCurrentTab, true);
		TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
	}

	function SwitchPageToFront(aiTab: Number, abForceFade: Boolean): Void
	{
		if (TopmostPage != PageArray[iCurrentTab]._parent)
		{
			TopmostPage.gotoAndStop("hide");
			PageArray[iCurrentTab]._parent.swapDepths(TopmostPage);
			TopmostPage = PageArray[iCurrentTab]._parent;
		}
		TopmostPage.gotoAndPlay(abForceFade ? "ForceFade" : "fadeIn");
		BottomBar_mc.LevelMeterRect._visible = iCurrentTab != 0;
	}

	function controllerStateText(buttonPressedLow: Number, buttonPressedHigh: Number,
			buttonTouchedLow: Number, buttonTouchedHigh: Number,
			axis: Array) {
		var output:String = "";

		for(var i = 0; i < 32; i++)
		{
			var mask = 1 << i;

			if(buttonPressedLow & mask) {
				output += "pressed: " + i + "\n";
			}
		}

		for(var i = 0; i < 32; i++)
		{
			var mask = 1 << i;

			if(buttonPressedHigh & mask) {
				output += "pressed: " + (i + 32) + "\n";
			}
		}

		for(var i = 0; i < 32; i++)
		{
			var mask = 1 << i;

			if(buttonTouchedLow & mask) {
				output += "touched: " + i + "\n";
			}
		}

		for(var i = 0; i < 32; i++)
		{
			var mask = 1 << i;

			if(buttonTouchedHigh & mask) {
				output += "touched: " + (i + 32) + "\n";
			}
		}

		for(var i = 0; i < 5; i++)
		{
			var x = axis[i*2];
			var y = axis[i*2 + 1];

			if(x != 0.0) {
				output += "x[" + i + "] = " + x + "\n";
			}
			if(y != 0.0) {
				output += "y[" + i + "] = " + y + "\n";
			}

			if(x != 0.0 || y != 0.0) {
				var vec2 = [x, y];
				output += "mag: " + GlobalFunctions.vec2Mag(vec2) + "\n";
				output += "quadrant: " + VRInput.axisQuadrant(vec2) + "\n";
				output += "region: " + VRInput.axisRegion(vec2) + "\n";
			}
		}
		return output;
	}

	var controllerTexts = ["", ""];
	var vrinputOnce = false;


	static function widgetToString(widget: Object)
	{
		var output = "";
		for (var key:String in widget) {
			output += key + ": " + widget[key] + "\n";
		}
		return output;
	}


	function handleVRInput(timestamp: Number,
			controllerHand: Number, packetNum: Number,
			buttonPressedLow: Number, buttonPressedHigh: Number,
			buttonTouchedLow: Number, buttonTouchedHigh: Number,
			axis: Array)
	{
		if(!vrinputOnce) {
		}

		controllerTexts[controllerHand-1] = controllerStateText(buttonPressedLow, buttonPressedHigh, buttonTouchedLow, buttonPressedHigh, axis);


		var updated = VRInput.updateControllerState(
				timestamp,
				controllerHand, packetNum,
				buttonPressedLow, buttonPressedHigh,
				buttonTouchedLow, buttonTouchedHigh,
				axis);

		if(updated)
		{
			// Build a list of widgets with interesting states
			var viveWidgets = [1, 2, 32, 33];
			var interestingWidgets = [];
			var widgets = VRInput.widgetStates[controllerHand-1];
			for(var i = 0; i < viveWidgets.length; i++) {
				var widget = widgets[viveWidgets[i]];
				if(widget.pressed || widget.touched || GlobalFunctions.vec2Mag(widget.axis)) {
					interestingWidgets.push(widget);
				}
			}

			// Build a string representation of all interesting widgets
			var interestingWidgetOutput = "";
			for(var i = 0; i < interestingWidgets.length; i++) {
				var widget = interestingWidgets[i];
				interestingWidgetOutput += widgetToString(widget);
			}

			// Append widget text to the output for the cooresponding hand
			if(interestingWidgetOutput.length != 0)
				controllerTexts[controllerHand-1] += "\n" + interestingWidgetOutput;

		}

		// Output all text prepared for each hand
		var output = "";

		if(controllerTexts[0].length != 0) {
			output += "Left controller:   \n";
			output += controllerTexts[0];
		}
		if(controllerTexts[1].length != 0) {
			output += "Right controller:   \n";
			output += controllerTexts[1];
		}

		TextPanel.TextArea.SetText(output);

		if(!vrinputOnce) {
			vrinputOnce = true;
		}
	}

	function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		var bHandledInput: Boolean = false;
		if (pathToFocus != undefined && pathToFocus.length > 0) {
			bHandledInput = pathToFocus[0].handleInput(details, pathToFocus.slice(1));
		}
		if (!bHandledInput && GlobalFunc.IsKeyPressed(details, false)) {
			var triggerLeft = NavigationCode.GAMEPAD_L2;
			var triggerRight = NavigationCode.GAMEPAD_R2;
			if(PageArray[Quest_Journal.PAGE_SYSTEM].GetIsRemoteDevice()) {
				triggerLeft = NavigationCode.GAMEPAD_L1;
				triggerRight = NavigationCode.GAMEPAD_R1;
			}
			if (details.navEquivalent === NavigationCode.TAB) {
				CloseMenu();
			} else if (details.navEquivalent === triggerLeft) {
				if (!bTabsDisabled) {
					PageArray[iCurrentTab].endPage();
					iCurrentTab = iCurrentTab + (details.navEquivalent == triggerLeft ? -1 : 1);
					if (iCurrentTab == -1) {
						iCurrentTab = TabButtonGroup.length - 1;
					}
					if (iCurrentTab == TabButtonGroup.length) {
						iCurrentTab = 0;
					}
					SwitchPageToFront(iCurrentTab, false);
					TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
				}
			} else if (details.navEquivalent === triggerRight) {
				if (!bTabsDisabled) {
					PageArray[iCurrentTab].endPage();
					iCurrentTab = iCurrentTab + (details.navEquivalent == triggerLeft ? -1 : 1);
					if (iCurrentTab == -1) {
						iCurrentTab = TabButtonGroup.length - 1;
					}
					if (iCurrentTab == TabButtonGroup.length) {
						iCurrentTab = 0;
					}
					SwitchPageToFront(iCurrentTab, false);
					TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
				}
			}
		}
		return true;
	}

	function CloseMenu(abForceClose: Boolean): Void
	{
		Debug.log(">> Quest_Journal");
		var vrinput = skse["plugins"]["vrinput"];
		if(vrinput != undefined)
		{
			Debug.log("-- Unregistering vr input");
			vrinput.ShutoffButtonEventsToGame(false);
			vrinput.UnregisterInputHandler(this, "handleVRInput");
		}

		if (abForceClose != true) {
			GameDelegate.call("PlaySound", ["UIJournalClose"]);
		}
		Debug.log("<< Quest_Journal");
		GameDelegate.call("CloseMenu", [iCurrentTab, QuestsFader.Page_mc.selectedQuestID, QuestsFader.Page_mc.selectedQuestInstance]);
	}

	function onTabClick(event: Object): Void
	{
		if (bTabsDisabled) {
			return;
		}

		var iOldTab: Number = iCurrentTab;

		if (event.item == QuestsTab) {
			iCurrentTab = 0;
		} else if (event.item == StatsTab) {
			iCurrentTab = 1;
		} else if (event.item == SystemTab) {
			iCurrentTab = 2;
		}
		if (iOldTab != iCurrentTab) {
			PageArray[iOldTab].endPage();
			// Moved SwitchPageToFront to within this statement
			// if you click the same tab it won't reload it
			SwitchPageToFront(iCurrentTab, false); // Bugfix for vanilla
		}
	}

	function onTabChange(event: Object): Void
	{
		event.item.gotoAndPlay("selecting");
		PageArray[iCurrentTab].startPage();
		GameDelegate.call("PlaySound", ["UIJournalTabsSD"]);
	}

	function onRightStickInput(afX: Number, afY: Number): Void
	{
		if (PageArray[iCurrentTab].onRightStickInput != undefined) {
			PageArray[iCurrentTab].onRightStickInput(afX, afY);
		}
	}

	function SetPlatform(aiPlatform: Number, abPS3Switch: Boolean): Void
	{
		VRInput.updatePlatform(aiPlatform);

		// Not sure if these are the correct mapping for next/prev tab
		var nextTabArt = ButtonArtNames.lookup(skyui.util.Input.pickButtonArt(aiPlatform, {ViveArt:"radial_Either_Right", MoveArt:"PS3_Y",OculusArt:"OCC_B", WindowsMRArt:"radial_Either_Right"}));
		var prevTabArt = ButtonArtNames.lookup(skyui.util.Input.pickButtonArt(aiPlatform, {ViveArt:"radial_Either_Left", MoveArt:"PS3_X", OculusArt:"OCC_Y", WindowsMRArt:"radial_Either_Left"}));

		// If we can't find the right button art by name, provide some defaults
		if (nextTabArt == undefined)
			nextTabArt = 281; 	// RT
		if (prevTabArt == undefined)
			prevTabArt = 280; 			// LT

		if (aiPlatform == 0) {
			previousTabButton._visible = nextTabButton._visible = false;
		} else {
			previousTabButton._visible = nextTabButton._visible = true;
			previousTabButton.gotoAndStop(prevTabArt);
			nextTabButton.gotoAndStop(nextTabArt);
		}

		for (var i: String in PageArray) {
			if (PageArray[i].SetPlatform != undefined) {
				PageArray[i].SetPlatform(aiPlatform, abPS3Switch);
			}
		}
		BottomBar_mc.setPlatform(aiPlatform, abPS3Switch);

		ConfigPanel.setPlatform(aiPlatform, abPS3Switch);
	}

	function DoHideMenu(): Void
	{
		_parent.gotoAndPlay("fadeOut");
	}

	function DoShowMenu(): Void
	{
		_parent.gotoAndPlay("fadeIn");
	}

	function DisableTabs(abEnable: Boolean): Void
	{
		QuestsTab.disabled = abEnable;
		StatsTab.disabled = abEnable;
		SystemTab.disabled = abEnable;
	}

	function ConfigPanelOpen(): Void
	{
		DisableTabs(true);
		SystemFader.Page_mc.endPage();
		DoHideMenu();
		_root.ConfigPanelFader.swapDepths(_root.QuestJournalFader);
		FocusHandler.instance.setFocus(ConfigPanel, 0);
		ConfigPanel.startPage();
	}

	function ConfigPanelClose(): Void
	{
		ConfigPanel.endPage();
		_root.QuestJournalFader.swapDepths(_root.ConfigPanelFader);
		FocusHandler.instance.setFocus(this, 0);
		DoShowMenu();
		SystemFader.Page_mc.startPage();
		DisableTabs(false);
	}
}
