// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

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