$(document).ready(function () {

  $(document).on('click', '#hit-button', function () {
    $.ajax({
      type: 'POST',
      url: '/player/hit'
    }).done(function (msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', '#stay-button', function () {
    $.ajax({
      type: 'POST',
      url: '/player/stay'
    }).done(function (msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', '#dealer-hit-button', function () {
    $.ajax({
      type: 'POST',
      url: '/dealer/hit'
    }).done(function (msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

});

