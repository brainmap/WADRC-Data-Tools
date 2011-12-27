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
