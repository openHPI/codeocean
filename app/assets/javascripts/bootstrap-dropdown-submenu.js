$(document).ready(function () {

  var subMenusSelector = 'ul.dropdown-menu [data-toggle=dropdown]';

  function openSubMenu(event) {
    if (this.pathname === '/') {
      event.preventDefault();
    }
    event.stopPropagation();

    $(subMenusSelector).parent().removeClass('open');
    $(this).parent().addClass('open');

    var menu = $(this).parent().find("ul");
    var menupos = menu.offset();

    var newPos;
    if ((menupos.left + menu.width()) + 30 > $(window).width()) {
      newPos = -menu.width();
    } else {
      newPos = $(this).parent().width();
    }
    menu.css({left: newPos});
  }

  $(subMenusSelector).on('click', openSubMenu).on('mouseenter', openSubMenu);
});
