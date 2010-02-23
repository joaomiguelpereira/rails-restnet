var FlashBoxController = {
	errorClass: 'error-flash-box',
	noticeClass: 'notice-flash-box',
    run: function(){
		//check the content
		this.showBox(this.errorClass);
		
		//window.alert($$('div.error-flash-box')[0].innerHTML)
    },
	showBox: function(elementId) {
		window.alert(elementId);
		var el = $$('div.'+elementId)[0];
		window.alert(el);
		window.alert(el.innerHTML)
	}
	
};
document.observe("dom:loaded", function() {FlashBoxController.run()});
