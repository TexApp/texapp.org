(function() {

  $().ready(function() {
    var docketNumber;
    $('a.document').tooltip({
      html: true,
      title: '<i class="icon-file icon-white"></i> Click to download'
    });
    docketNumber = /^\d\d-\d\d-\d\d\d\d\d-(CV|CR)?$/;
    return $('#search').submit(function() {
      var input, query;
      input = $('input:first');
      query = input.val().trim();
      if (docketNumber.test(query)) {
        input.val("");
        window.location = "/" + query;
        return false;
      } else {
        return true;
      }
    });
  });

}).call(this);
