$(function() {
  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
    let ok = confirm("Are you sure?");

    if (ok) {

      let form = $(this);
      let request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent("li").remove();
        } else if (jqXHR.status == 200) {
          document.location = data;
        }
      });

      request.fail(function() {});
    }
  });
});
