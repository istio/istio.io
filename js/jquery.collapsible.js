/*!
* Collapsible.js v1.2.0
* https://github.com/jordnkr/collapsible
*
* Copyright 2017, Jordan Ruedy
* This content is released under the MIT license
* http://opensource.org/licenses/MIT
*/

(function($, undefined) {
    $.fn.collapsible = function(options) {

        var defaults = {
            accordion: false,
            accordionUpSpeed: 400,
            accordionDownSpeed: 400,
            collapseSpeed: 400,
			contentOpen: null,
            arrowRclass: 'arrow-r',
            arrowDclass: 'arrow-d',
            animate: true
        };

        var settings = $.extend(defaults, options);

        return this.each(function() {
            if (settings.animate === false) {
                settings.accordionUpSpeed = 0;
                settings.accordionDownSpeed = 0;
                settings.collapseSpeed = 0;
            }

            var $thisEven = $(this).children(':even');
            var $thisOdd = $(this).children(':odd');
			var accord = 'accordion-active';

            $(this).children(':nth-child(even)').css('display','none');

            if (settings.accordion === true) {
                if (settings.contentOpen !== null) {
                    $($thisEven[settings.contentOpen]).children(':first-child').toggleClass(settings.arrowRclass + ' ' + settings.arrowDclass);
                    $($thisOdd[settings.contentOpen]).show().addClass(accord);
                }
                $($thisEven).click(function() {
                    if ($(this).next().attr('class') === accord) {
                        $(this).next().slideUp(settings.accordionUpSpeed).removeClass(accord);
                        $(this).children(':first-child').toggleClass(settings.arrowRclass + ' ' + settings.arrowDclass);
                    } else {
                        $($thisEven).children().removeClass(settings.arrowDclass).addClass(settings.arrowRclass);
                        $($thisOdd).slideUp(settings.accordionUpSpeed).removeClass(accord);
                        $(this).next().slideDown(settings.accordionDownSpeed).addClass(accord);
                        $(this).children(':first-child').toggleClass(settings.arrowRclass + ' ' + settings.arrowDclass);
                    }
                });
            } else {
                if (settings.contentOpen !== null) {
                    if (Array.isArray( settings.contentOpen )) {
                        for (var i = 0; i < settings.contentOpen.length; i++) {
                            var index = settings.contentOpen[i];
                            $($thisEven[index]).children(':first-child').toggleClass(settings.arrowRclass + ' ' + settings.arrowDclass);
                            $($thisOdd[index]).show();
                        }
                    } else {
                        $($thisEven[settings.contentOpen]).children(':first-child').toggleClass(settings.arrowRclass + ' ' + settings.arrowDclass);
                        $($thisOdd[settings.contentOpen]).show();
                    }
                }
                $($thisEven).click(function() {
                    $(this).children(':first-child').toggleClass(settings.arrowRclass + ' ' + settings.arrowDclass);
                    $(this).next().slideToggle(settings.collapseSpeed);
                });
            }
        });
    };
})(jQuery);
