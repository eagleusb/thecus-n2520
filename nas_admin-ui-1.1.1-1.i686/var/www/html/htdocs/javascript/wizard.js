/*
 * @author: ellie_chien
 */


Ext.namespace("Ext.smart");

/* Create a wizard layout.
 * 
 * @param wizardWindow: an empty window object
 * @param suffix_id: the suffix id for each of the window elements. Recommand: produced by Ext.id() (prevent the conflict id)
 * @param closable: set this window object can be closed or not
 * 
 * @property wizardItems: an array 
 * @property btnClick: default 'C'
 * @property mask: wizard window would move by mainMask, so adding the mask for wizard
 * @property mask_msg: the loading message, default is Loading...
 * 
 * @method hideHandler(btnClick): btnClick is the clicked button at present
 * @method resetWizard(resetAllCards): resetAllCards is true or false
 * @method onStepActive(activeStep): return true or false;
 * @method beforeStepActive(activeStep, btn): return true or false;
 * @method setActiveStep(activeStep): return true or false;
 * @method getActiveStep(): return the active step
 * @method getWin(): return window object
 * @method show(): no return
 * @method setTitle(): no return
 * @method setWidth(): default 850, no return
 * @method setHeight(): default 450, no return
 * @method addWizardItem(k, t, o, stepNum, type, description): add step data into @property wizardItems
 * @method getBtnId(btn): return the @btn's id
 * @method setDisabledBtn(btn, disabled): disable the @btn by @disabled
 * @method addBtnHandler(btn, handler): add @btn handler
 * @method getValues(): return the each form data
 * 
 * @note: btn includes 'P', 'N', 'C', 'S', 'F'
 */
Ext.smart.Wizard = function (suffix_id, closable) {
	var activeItem = 0;
	this.mask_msg = "Loading...";
	this.wizardItems = [];
	this.btnClick = 'C';
	
	if (typeof suffix_id == "undefined" || suffix_id === null) {
		return;
	}
	
	this.suffix_id = suffix_id;
	
	// for next & prev buttons
	var navHandler = function (direction){
		this.btnClick = (direction > 0)?'N':'P';
		var activeItemTmp = activeItem;
		activeItemTmp += direction;

		if (!this.beforeStepActive(this.wizardItems[activeItemTmp].key, this.btnClick)) {
			return;
		}
		
		if (activeItemTmp < 0) {
			activeItemTmp = 0;
		} else if (activeItemTmp >= this.wizardItems.length) {
			activeItemTmp = this.wizardItems.length - 1;
		}
		
		setButtonsStatus(this.wizardItems[activeItemTmp].stepType);
		Ext.getCmp("steps" + suffix_id).getLayout().setActiveItem(activeItemTmp);
		Ext.getCmp("contents" + suffix_id).getLayout().setActiveItem(activeItemTmp);
		this.onStepActive(this.wizardItems[activeItemTmp].key);
		activeItem = activeItemTmp;
	};
	
	// for cancel & finish & submit (if submit handler has not been overwritten) buttons
	this.hideHandler = function (btnClick) {
		this.btnClick = btnClick;
		win.hide();
	};
	
	var win = new Ext.Window({
		id: "wizard_win" + suffix_id,
		title: "",
		width: 850,
		height: 450,
		border: false,
		resizable:false,
		closable: closable === false ? false : true,
		layout: "border",
		modal: true,
		items:[{
			layout:'card',
			activeItem:0,
			region:'west',
			id:'steps' + suffix_id,
			width: "30%",
			margin: '0 0 0 0',
			items: [{}]
		}, {
			layout:'card',
			activeItem:0,
			region: 'center',
			id: 'contents' + suffix_id,
			width: "70%",
			margin: '0 0 0 0',
			items:[{}]
		}],
		buttons: [{
			id: "prev" + suffix_id,
			text: (wizard_btn?wizard_btn.P:"Prev"),
			handler: navHandler.createDelegate(this,[-1]),
			border: false
		},{
			id: "next" + suffix_id,
			text: wizard_btn?wizard_btn.N:"Next",
			handler: navHandler.createDelegate(this,[1]),
			border: false
		},{
			id: "submit" + suffix_id,
			text: wizard_btn?wizard_btn.S:"Submit",
			handler: this.hideHandler.createDelegate(this, ['S']),
			border: false
		},{
			id: "cancel" + suffix_id,
			text: wizard_btn?wizard_btn.C:"Cancel",
			handler: this.hideHandler.createDelegate(this, ['C']),
			border: false
		},{
			id: "finish" + suffix_id,
			text: wizard_btn?wizard_btn.F:"Finish",
			handler: this.hideHandler.createDelegate(this, ['F']),
			border: false
		}]
	});
	win.on("beforeshow", function (obj) {
		setButtonsStatus('first');
	});
		
	var setButtonsStatus = function (stepType) {
		switch (stepType) {
		case 'first':
			Ext.getCmp("prev" + suffix_id).setVisible(true);
			Ext.getCmp("next" + suffix_id).setVisible(true);
			Ext.getCmp("submit" + suffix_id).setVisible(false);
			Ext.getCmp("cancel" + suffix_id).setVisible(true);
			Ext.getCmp("finish" + suffix_id).setVisible(false);
			Ext.getCmp("prev" + suffix_id).setDisabled(true);
			Ext.getCmp("next" + suffix_id).setDisabled(false);
			Ext.getCmp("submit" + suffix_id).setDisabled(true);
			Ext.getCmp("cancel" + suffix_id).setDisabled(false);
			Ext.getCmp("finish" + suffix_id).setDisabled(true);
			break;
		case 'middle':
			Ext.getCmp("prev" + suffix_id).setVisible(true);
			Ext.getCmp("next" + suffix_id).setVisible(true);
			Ext.getCmp("submit" + suffix_id).setVisible(false);
			Ext.getCmp("cancel" + suffix_id).setVisible(true);
			Ext.getCmp("finish" + suffix_id).setVisible(false);
			Ext.getCmp("prev" + suffix_id).setDisabled(false);
			Ext.getCmp("next" + suffix_id).setDisabled(false);
			Ext.getCmp("submit" + suffix_id).setDisabled(true);
			Ext.getCmp("cancel" + suffix_id).setDisabled(false);
			Ext.getCmp("finish" + suffix_id).setDisabled(true);
			break;
		case 'submit':
			Ext.getCmp("prev" + suffix_id).setVisible(true);
			Ext.getCmp("next" + suffix_id).setVisible(false);
			Ext.getCmp("submit" + suffix_id).setVisible(true);
			Ext.getCmp("cancel" + suffix_id).setVisible(true);
			Ext.getCmp("finish" + suffix_id).setVisible(false);
			Ext.getCmp("prev" + suffix_id).setDisabled(false);
			Ext.getCmp("next" + suffix_id).setDisabled(false);
			Ext.getCmp("submit" + suffix_id).setDisabled(false);
			Ext.getCmp("cancel" + suffix_id).setDisabled(false);
			Ext.getCmp("finish" + suffix_id).setDisabled(true);
			break;
		case 'final':
			Ext.getCmp("prev" + suffix_id).setVisible(false);
			Ext.getCmp("next" + suffix_id).setVisible(false);
			Ext.getCmp("submit" + suffix_id).setVisible(false);
			Ext.getCmp("cancel" + suffix_id).setVisible(false);
			Ext.getCmp("finish" + suffix_id).setVisible(true);
			Ext.getCmp("prev" + suffix_id).setDisabled(true);
			Ext.getCmp("next" + suffix_id).setDisabled(true);
			Ext.getCmp("submit" + suffix_id).setDisabled(true);
			Ext.getCmp("cancel" + suffix_id).setDisabled(true);
			Ext.getCmp("finish" + suffix_id).setDisabled(false);
			break;
		default:
		}
	};
	
	this.resetWizard = function (resetAllCards) {
		if (resetAllCards) {
			if (win.items.get(1)) {
				Ext.each(win.items.get(1).findByType("form"), function (item) {
					if (item.rendered) {
						item.items.each(function(item, index, maxLength){
							if (item.xtype != undefined && item.xtype != "sliderfield" && item.xtype != "label" && item.xtype != "box" && item.xtype != "panel") {
								item.reset();
							}
						});
					}
				});
			}
		}
		activeItem = 0;
	};		
	this.onStepActive = function (activeStep) {return true};
	this.beforeStepActive = function (activeStep, btn) {return true};
	
	this.setActiveStep = function (activeStep) {
		var activeItemTmp = -1;
		for (var i = 0; i < this.wizardItems.length; i ++) {
			if (activeStep == this.wizardItems[i].key) {
				activeItemTmp = i;
				break;
			}
		}
		if (activeItemTmp < 0) {
			return false;
		}
		if (!this.beforeStepActive(this.wizardItems[activeItemTmp].key, null)) {
			return true;
		};
		setButtonsStatus(this.wizardItems[activeItemTmp].stepType);
		Ext.getCmp("steps" + suffix_id).getLayout().setActiveItem(activeItemTmp);
		Ext.getCmp("contents" + suffix_id).getLayout().setActiveItem(activeItemTmp);
		this.onStepActive(this.wizardItems[activeItemTmp].key);
		activeItem = activeItemTmp;
		return true;
	};
	this.getActiveStep = function () {
		return this.wizardItems[activeItem].key;
	};
};

Ext.smart.Wizard.prototype.setTitle = function (title) {
	if (typeof title == "undefined" || title === null) {
		return;
	}
	Ext.getCmp("wizard_win" + this.suffix_id).setTitle(title);
};

Ext.smart.Wizard.prototype.setHeight = function (height) {
	if (typeof height == "undefined" || height === null) {
		return;
	}
	Ext.getCmp("wizard_win" + this.suffix_id).setHeight(height);
};

Ext.smart.Wizard.prototype.setWidth = function (width) {
	if (typeof width == "undefined" || width === null) {
		return;
	}
	Ext.getCmp("wizard_win" + this.suffix_id).setWidth(width);
};

Ext.smart.Wizard.prototype.show = function () {
	var items = this.wizardItems;
	var stepPanel = null;
	for (var i = 0; i < items.length; i++) {
		var stepItems = [];
		for (var j = 0; j < items.length; j++) {
			if (i == j) {
				stepItems.push({
					//layout: 'form',
					baseCls: "wizard-step-on-bg",
					frame: true,
					items:[{
						xtype: "label",
						html: "<p class='wizard-step-on'><div class='wizard-step-on-image'>" + (j+1) + "</div>&nbsp;" + items[j].title + "</p><br>"
					},{
						xtype: 'label',
						html: "<span class='wizard-step-desc'>" + items[i].desc + "</span>"
					}]
				});
			} else {
				stepItems.push({
					xtype: "label",
					html: "<p class='wizard-step-off'><span class='wizard-step-off-image'>" + (j+1) + "</span>&nbsp;" + items[j].title + "</p>"
				});
			}
		}
		stepPanel = new Ext.FormPanel({
			id: "step_" + i + this.suffix_id,
			name: "step_" + i + this.suffix_id,
			baseCls: "wizard-step-off-bg",
			frame: false,
			items: stepItems
		});
		
		Ext.getCmp("steps" + this.suffix_id).items.insert(i, items[i].key, stepPanel);
	}
	Ext.getCmp("steps" + this.suffix_id).items.insert(i, ("done" + this.suffix_id), stepPanel);
	
	Ext.getCmp("wizard_win" + this.suffix_id).show();
	this.onStepActive(this.wizardItems[0].key);

	this.mask = new Ext.LoadMask(document.getElementById("wizard_win" + this.suffix_id), {msg:this.mask_msg});
	this.mask.hide();
};

Ext.smart.Wizard.prototype.getWin = function () {
	return Ext.getCmp("wizard_win" + this.suffix_id);
}

Ext.smart.Wizard.prototype.addWizardItem = function (k, t, o, stepNum, type, description) {
	this.wizardItems.splice(stepNum, 0, {key: k, title: t, obj: o, stepType: type, desc: description});
	Ext.getCmp("contents" + this.suffix_id).items.insert(stepNum, k, o);
	Ext.getCmp("contents" + this.suffix_id).items.get(stepNum).bodyStyle = "background-color:#ECEDED;padding:10px;border:0px;background-image:url(../theme/images/index/wizard/bg_03.png);background-repeat:repeat-x;";
};

Ext.smart.Wizard.prototype.getBtnId = function (btn) {
	var btnId = "";
	
	switch (btn) {
	case 'P':	// Previous
		btnId = Ext.getCmp("prev" + this.suffix_id).getId();//this.buttons.prev.getId();
		break;
	case 'N':	// Next
		btnId = Ext.getCmp("next" + this.suffix_id).getId();//this.buttons.next.getId();
		break;
	case 'S':	// Submit
		btnId = Ext.getCmp("submit" + this.suffix_id).getId();//this.buttons.submit.getId();
		break;
	case 'C':	// Cancel
		btnId = Ext.getCmp("cancel" + this.suffix_id).getId();//this.buttons.cancel.getId();
		break;
	case 'F':	// Finish
		btnId = Ext.getCmp("finish" + this.suffix_id).getId();//this.buttons.finish.getId();
		break;
	default:
	}
	
	return btnId;
};

Ext.smart.Wizard.prototype.setDisabledBtn = function (btn, disabled) {
	var btnId = this.getBtnId(btn);
	if (btnId == "") return;
	
	if (Ext.getCmp(btnId).disabled != disabled) {
		Ext.getCmp(btnId).setDisabled(disabled);		
	}
};

Ext.smart.Wizard.prototype.addBtnHandler = function (btn, handler) {
	var btnId = this.getBtnId(btn);
	if (btnId == "") return;
	
	Ext.getCmp(btnId).setHandler(handler);
};

Ext.smart.Wizard.prototype.getValues = function (asString) {
	var output;
	var win = Ext.getCmp("wizard_win" + this.suffix_id);
	
	if (!win.items.get(1)) {
		return null;
	}
	
	if (asString) {
		output = "";
	} else {
		output = {};
	}
	
	var count = 0;
	win.items.get(1).items.each(function(item, index, maxLength) {
		if (item.rendered && item.isXType("form", asString)) {
			if (this.wizardItems[count].stepType == "submit" || this.wizardItems[count].stepType == "final") {
				// do nothing
			} else if (asString) {
				if (output != "") {
					output += "&";
				}
				output += item.getForm().getValues(asString);
			} else {
				Ext.apply(output, item.getForm().getValues(asString));
			}
			count++;
		}
	},this);
	
	return output;
};

Ext.smart.Wizard.prototype.setCenter = function () {
	var win = this.getWin();
	var pos=win.getPosition(false);
	var siz=win.getSize();

	win.setPosition(pos[0], pos[1]-pos[1]*(siz.height-450)/400);
}