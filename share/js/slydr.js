var curSlide = 1;

function hideAll () {
  $('.slide').hide();
}

function showAll () {
  $('.slide').show();
}

function show_slide (id) {
  var curSlideId = get_slide_id(id);
  $(curSlideId).show();
}

function get_slide_id (id) {
  var curSlideId = '#slide' + id;
  return curSlideId;
}
      
function slide_down_slide (id) {
  var curSlideId = get_slide_id(id);
  $(curSlideId).slideDown('fast');
}

function slide_up_slide (id) {
  var curSlideId = get_slide_id(id);
  $(curSlideId).slideUp('fast');
}
      
function slide_forward() {
  if( curSlide == maxSlide ) {
    return;
  }
  slide_up_slide(curSlide);
  curSlide = curSlide + 1;
  slide_down_slide(curSlide);
  $(window).scrollTop(0);
}

function slide_backward() {
  if( curSlide == minSlide ) {
    return;
  }
  slide_up_slide(curSlide);
  curSlide = curSlide - 1;
  slide_down_slide(curSlide);
  $(window).scrollTop(0);
}

$(window).jkey( 'right,j,down,return' , function() {
  slide_forward();
});

$(window).jkey( 'left,k,up,backspace' , function() {
  slide_backward();
});

$(window).jkey( '1,<' , function() {
  slide_up_slide(curSlide);
  curSlide = minSlide;
  slide_down_slide(curSlide);
});

$(window).jkey( '9,>' , function() {
  slide_up_slide(curSlide);
  curSlide = maxSlide;
  slide_down_slide(curSlide);
});

var showAllToggle = false;
$(window).jkey( 's' , function() {
  if( showAllToggle ) {
    hideAll();
    show_slide(curSlide);
    showAllToggle = false;
  }
  else {
    showAll();
    showAllToggle = true;
  }
});

$(document).ready( function () {
  hideAll();
  show_slide(curSlide);
});
