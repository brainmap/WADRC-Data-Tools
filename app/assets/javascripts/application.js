// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//= require jquery
//= require jquery_ujs  
//= require rails.js
 
	



function isValidDate_yyyy_mm_dd(date){
        var valid = true;

        date = date.replace('/-/g', '');

        var year  = parseInt(date.substring(0, 4),10);
        var month = parseInt(date.substring(4, 6),10);
        var day   = parseInt(date.substring(6, 8),10);


        if((month < 1) || (month > 12)) valid = false;
        else if((day < 1) || (day > 31)) valid = false;
        else if(((month == 4) || (month == 6) || (month == 9) || (month == 11)) && (day > 30)) valid = false;
        else if((month == 2) && (((year % 400) == 0) || ((year % 4) == 0)) && ((year % 100) != 0) && (day > 29)) valid = false;
        else if((month == 2) && ((year % 100) == 0) && (day > 29)) valid = false;

    return valid;
}


// not using the inner html text -- using an image
// so can ignore the link div id
function toggle2(showHideDiv, switchTextDiv) {
	var ele = document.getElementById(showHideDiv);
//	var text = document.getElementById(switchTextDiv);
	if(ele.style.display == "block") {
    		ele.style.display = "none";
		//text.innerHTML = "restore" ;
  	}
	else {
		ele.style.display = "block";
		//text.innerHTML = "collapse";
	}
}


function toggle2_closed(showHideDiv, switchTextDiv) {
	var ele = document.getElementById(showHideDiv);
//	var text = document.getElementById(switchTextDiv);
	if(ele.style.display == "none") {
    		ele.style.display = "block";
		//text.innerHTML = "restore" ;
  	}
	else {
		ele.style.display = "none";
		//text.innerHTML = "collapse";
	}
}

function toggle2_closed_all( switchTextDiv) {
// get all div elements which start with 
// pet, mri, lp, lh, np, questionnaire
var inputs = document.getElementsByTagName("div");
for (var x=0;x<=inputs.length;x++){
  myname = inputs[x].id // getAttribute("id");
  ele = inputs[x]
  if(myname.indexOf("mri")==0 || myname.indexOf("pet")==0 || myname.indexOf("lp")==0 || myname.indexOf("lh")==0 || myname.indexOf("np")==0 || myname.indexOf("questionnaire")==0){
    if(ele.style.display == "none") {
    		ele.style.display = "block";
		//text.innerHTML = "restore" ;
  	}
	else {
		ele.style.display = "none";
		//text.innerHTML = "collapse";
	}
   }
  }

}

function togglecomment(showHideDiv, switchTextDiv,first_text,second_text) {
	var ele = document.getElementById(showHideDiv);
	var text = document.getElementById(switchTextDiv);
	if(ele.style.display == "block") {
    		ele.style.display = "none";
		text.innerHTML = first_text ;
  	}
	else {
		ele.style.display = "block";
		text.innerHTML = second_text;
	}
}
// checks all the children checkboxes
function checkbox_cascade(f, parent_id){
	var v_name = 'cg_search[include_cn]['+parent_id+']'
	var ele = document.getElement
	// document.forms[0].v_name.checked=true; 
	var inputs = document.getElementsByTagName("input"); //or document.forms[0].elements;   
	for (var i = 0; i < inputs.length; i++) {  
	  if (inputs[i].type == "checkbox") { 
		var i_name =inputs[i].name
		if(inputs[i].name.indexOf(v_name) !=-1)
		  {
		   inputs[i].checked=true	
		  }
	   }  
	 }  	
}