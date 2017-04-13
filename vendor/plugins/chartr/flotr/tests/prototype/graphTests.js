var f;

function setup(){	
	var d1 = [];
	var d2 = [[0, 3], [4, 8], [8, 5], [9, 13]];
	
    for(var i = 0; i < 14; i += 0.5)
        d1.push([i, Math.sin(i)]);

    f = Flotr.draw($('container'), [ d1, d2 ]);
};

function testFlotrDraw(){
	assertNotNull('Container element doesn\'t exist',$('container'));
	assertNotNull('Flotr.draw doesn\'t return a Graph', f);	
}

function testCanvas(){
	var canvas = $($('container').childNodes[0]);		
	assertNotNull('Drawing canvas doesn\'t exist',canvas);
	assertEquals('Drawing canvas is not a canvas element',canvas.tagName.toLowerCase(),'canvas');
	assertTrue('Drawing canvas doesn\'t have ".flotr-canvas" classname',canvas.className.indexOf('flotr-canvas')!=-1);
	
	var overlay = $($('container').childNodes[1]);
	assertNotNull('Overlay canvas doesn\'t exist',overlay);
	assertEquals('Overlay canvas is not a canvas element',overlay.tagName.toLowerCase(),'canvas');
	assertTrue('Overlay canvas doesn\'t have ".flotr-overlay" classname',overlay.className.indexOf('flotr-overlay')!=-1);
}

function exposeTestFunctionNames(){
	return [
		'setup',
		'testFlotrDraw',
		'testCanvas'
	];
}
