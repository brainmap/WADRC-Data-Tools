function testFlotrGetSeries() {
    assertNotNull('Flotr.getSeries() is null', Flotr.getSeries);
	assertEquals('Flotr.getSeries() returns inconsistent data',Flotr.getSeries([[1,2]])[0].data[0], 1);
	assertEquals('Flotr.getSeries() returns inconsistent data',Flotr.getSeries([[1,2]])[0].data[1], 2);
	assertEquals('Empty data array doesn\'t return empty series',Flotr.getSeries([]).length, 0);
}

function testFlotrGetTickSize() {
	assertNotNull('Flotr.getTickSize() is null', Flotr.getTickSize);
	assertEquals('Flotr.getTickSize(10, 0, 100, 1) != 10', Flotr.getTickSize(10, 0, 100, 1), 10);
	assertEquals('Flotr.getTickSize(20, 0, 100, 1) != 5', Flotr.getTickSize(20, 0, 100, 1), 5);
	assertEquals('Flotr.getTickSize(5, 10, 110, 1) != 20', Flotr.getTickSize(5, 10, 110, 1), 20);
	assertEquals('Flotr.getTickSize(0, 0, 10, 1) != Number.POSITIVE_INFINITY', Flotr.getTickSize(0, 0, 10, 1), Number.POSITIVE_INFINITY);
	assertTrue('Flotr.getTickSize(0, 0, -10, 1) is a number', isNaN(Flotr.getTickSize(0, 0, -10, 1)));
}

function testFlotrRegister(){
	assertNotNull('Flotr.register() is null', Flotr.register);
	assertEquals('Flotr._registeredTypes[\'lines\'] != drawSeriesLines', Flotr._registeredTypes['lines'], 'drawSeriesLines');
	assertEquals('Flotr._registeredTypes[\'bars\'] != drawSeriesBars', Flotr._registeredTypes['bars'], 'drawSeriesBars');
	assertEquals('Flotr._registeredTypes[\'points\'] != drawSeriesPoints', Flotr._registeredTypes['points'], 'drawSeriesPoints');
	assertEquals('Flotr._registeredTypes[\'pie\'] != drawSeriesPie', Flotr._registeredTypes['pie'], 'drawSeriesPie');
	assertEquals('Flotr._registeredTypes[\'candles\'] != drawSeriesCandles', Flotr._registeredTypes['candles'], 'drawSeriesCandles');
	Flotr.register('test_type', 'drawSeriesTest');
	assertEquals('Flotr._registeredTypes[\'test_type\'] != drawSeriesTest', Flotr._registeredTypes['test_type'], 'drawSeriesTest');
}

function testFlotrColor(){	
	assertNotNull('Flotr.Color() is null', Flotr.Color);
	var c = new Flotr.Color(0,0,0,0);
	assertEquals('Color red argument\'s not 0',c.r, 0);
	assertEquals('Color green argument\'s not 0',c.g, 0);
	assertEquals('Color blue argument\'s not 0',c.b, 0);	
	assertEquals('Color alpha argument\'s not 1.0',c.a, 1.0);	
}

function testFlotrColorAdjust(){
	var c = new Flotr.Color(200,200,200,0); 	
	assertEquals('Color red argument\'s not 200',c.r, 200);
	assertEquals('Color green argument\'s not 200',c.g, 200);
	assertEquals('Color blue argument\'s not 200',c.b, 200);
	c.adjust(5, 5, 5);
	assertEquals('Color red argument\'s not 205',c.r, 205);
	assertEquals('Color green argument\'s not 205',c.g, 205);
	assertEquals('Color blue argument\'s not 205',c.b, 205);	
	c.adjust(300,300,300);
	assertEquals('Color red argument\'s not 255',c.r, 255);
	assertEquals('Color green argument\'s not 255',c.g, 255);
	assertEquals('Color blue argument\'s not 255',c.b, 255);
}

function testFlotrColorClone(){
	var c = new Flotr.Color(0,0,0,0.1);
	assertEquals('Color alpha argument\'s not right',c.a, 0.1);
	assertEquals('Color clones are not equal',c.toString(), c.clone().toString())
}

function exposeTestFunctionNames(){
	return [
		'testFlotrGetSeries',
		'testFlotrGetTickSize',
		'testFlotrRegister',
		'testFlotrColor',
		'testFlotrColorAdjust',
		'testFlotrColorClone'	
	];
}
