$(function() {
  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();
  });
});
