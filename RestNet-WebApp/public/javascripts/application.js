var FlashBoxController = {
    errorClass: 'error-flash-box',
    noticeClass: 'notice-flash-box',
    run: function(){
        //check the content
        this.showBox(this.errorClass);
        this.showBox(this.noticeClass);
        
        //window.alert($$('div.error-flash-box')[0].innerHTML)
    },
    showBox: function(elementId){
        var el = $$('div.' + elementId)[0];
        
        if (el.innerHTML.strip() != '') {
            el.blindDown({
                duration: 0.8
            });
            
            Element.blindUp.delay(5, $$('div.' + elementId)[0], {
                duration: 0.8
            });
        }
        
        
    }
    
};
document.observe("dom:loaded", function(){
    FlashBoxController.run()
});
