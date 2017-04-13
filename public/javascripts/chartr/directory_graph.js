function make_graph(sizes,dates) {
	var dg = new RGraph.Line('directory-chart', sizes);
	dg.Set('chart.colors', ['red']);
	dg.Set('chart.labels', dates);
	dg.Set('chart.ymax', 10);
	dg.Set('chart.linewidth', 2);
	dg.Set('chart.hmargin', 10);
	dg.Set('chart.tickmarks', 'circle');
	dg.Draw();
}