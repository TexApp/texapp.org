(function() {

  $().ready(function() {
    return $.getJSON('/stats.json', {}, function(data) {
      var graph, legend, offsetForm, palette, x_axis, y_axis;
      palette = new Rickshaw.Color.Palette();
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
      offsetForm = document.getElementById('offset_form');
      offsetForm.addEventListener('change', (function(e) {
        var offsetMode;
        offsetMode = e.target.value;
        if (offsetMode === 'lines') {
          graph.setRenderer('line');
          graph.offset = 'zero';
        } else {
          graph.setRenderer('stack');
          graph.offset = offsetMode;
        }
        return graph.render();
      }), false);
      return graph.render();
    });
  });

}).call(this);
