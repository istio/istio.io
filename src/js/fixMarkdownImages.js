
// Jekyll's markdown processor attaches ALT attributes to <img> elements.
// That's a bug, it really should be attaching TITLE attributes instead.
// This script grovels the DOM and assigns a TITLE attribute if one is not
// present by cloning the ALT attribute.
(function(){
    var images = document.getElementsByTagName('img');
    for (var i = 0; i < images.length; i++) {
        var img = images[i];
        var title = img.getAttribute("title");
        if (title == undefined) {
            title = img.getAttribute("alt");
            if (title != undefined) {
                img.setAttribute("title", title);
            }
        }
    }
})();
