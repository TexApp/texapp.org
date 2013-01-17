(function() {

  $().ready(function() {
    var data;
    data = location.search.replace(/^\?/, '');
    return $.getJSON('/statistics.json', data, function(data) {
      var graph, legend, palette, x_axis, y_axis;
      palette = new Rickshaw.Color.Palette();
      $('#loading').remove();
      $('#statsForm').show();
      $('#chartContainer').show();
      graph = new Rickshaw.Graph({
        element: document.querySelector("#chart"),
        width: 800,
        height: 400,
        renderer: 'line',
        series: data.map(function(e) {
          e.color = palette.color();
          return e;
        })
      });
      x_axis = new Rickshaw.Graph.Axis.Time({
        graph: graph
      });
      y_axis = new Rickshaw.Graph.Axis.Y({
        graph: graph,
        orientation: 'left',
        tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
        element: document.getElementById('y_axis')
      });
      legend = new Rickshaw.Graph.Legend({
        element: document.querySelector('#legend'),
        graph: graph
      });
      return graph.render();
    });
  });

}).call(this);
