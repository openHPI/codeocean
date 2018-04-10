$(document).ready(function () {

  function openSubMenu(event) {
    if (this.pathname === '/') {
      event.preventDefault();
    }
    event.stopPropagation();
    $(this).parent().addClass('open');

    var menu = $(this).parent().find("ul");
    var menupos = menu.offset();

    if ((menupos.left + menu.width()) + 30 > $(window).width()) {
      var newpos = -menu.width();
    } else {
      var newpos = $(this).parent().width();
    }
    menu.css({left: newpos});
  }

  $('ul.dropdown-menu [data-toggle=dropdown]').on('click', openSubMenu).on('mouseenter', openSubMenu);
});
