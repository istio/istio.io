---
---

// Given an array of documents, constructs a tree of items
//
// The tree is built based on the doc.path array that's in every
// document.
function makeNavTree(parent, docs, depth) {
    var items = [];
    for (var i = 0; i < docs.length; i++) {
        var doc = docs[i];
        var name = doc.path[depth];

        if (name == 'index.md') {
            if (parent != null) {
                parent.doc = doc;
            }
            continue;
        }

        // find or create a node for the current doc
        var item = null;
        for (var j = 0; j < items.length; j++) {
            if (items[j].name === name) {
                item = items[j];
                break;
            }
        }

        if (item === null) {
            // not found, create a fresh node
            item = {name: name, doc: null, children: []};
            items.push(item);
        }

        if (doc.path.length > depth + 1) {
            // if there are additional path elements, this means the doc
            // belongs lower in the hierarchy, so treat it as a child.
            item.children.push(doc);
        } else {
            // this node is home to this doc
            item.doc = doc;
        }
    }

    for (i = 0; i < items.length; i++) {
        item = items[i];
        item.children = makeNavTree(item, item.children, depth + 1);
    }

    items.sort(function(a, b) {
        if (a.doc.order < b.doc.order) {
            return -1;
        } else if (a.doc.order > b.doc.order) {
            return 1;
        }
        return 0;
    });

    return items;
}

function outputSideBarTree(items) {
    document.writeln("<ul class='list-unstyled tree'>");

    for (var i = 0; i < items.length; i++) {
        var item = items[i];

        if (item.children.length == 0) {
            if (item.doc.url == location.pathname) {
                document.write("<li class='sidebar-list-item'><a class='current' href='");
            } else {
                document.write("<li class='sidebar-list-item'><a href='");
            }
            document.write("{{home}}");
            document.write(item.doc.url);
            document.write("' title='");
            document.write(item.doc.overview);
            document.write("'>");
            document.write(item.doc.title);
            document.writeln("</a>");

            if (item.doc.order == 9999) {
                document.writeln('(please set order: front matter for this document)')
            }
            document.writeln("</li>");
        }
    }

    for (var i = 0; i < items.length; i++) {
        var item = items[i];

        if (item.children.length > 0) {
            document.writeln("<li class='sidebar-list-item'>");
            document.writeln("<label class='tree-toggle'>");
            document.writeln("<i class='fa fa-lg fa-caret-down'></i>");
            document.writeln("<a class='tree-toggle-link' href='javascript:void 0;'>");
            if (item.doc == null) {
                document.writeln(item.name);
            } else {
                document.writeln(item.doc.title);
            }
            document.writeln("</a>");
            document.writeln("</label>");

            if (item.doc.order == 9999) {
                document.writeln('(please set order: front matter for this document)')
            }

            outputSideBarTree(item.children);
            document.writeln("</li>");
        }
    }

    document.writeln("</ul>");
}

// Given an array of documents, generate the sidebar nav tree
function genSideBarTree(docs) {
    var items = makeNavTree(null, docs, 0);
    outputSideBarTree(items);
}


function outputSectionNavTree(items) {
    document.writeln("<ul>");
    for (var i = 0; i < items.length; i++) {
        var item = items[i];

        if (item.children.length == 0) {
            document.write("<li class='file'>");
            document.write("<a href='{{home}}");
            document.write(item.doc.url);
            document.write("'>");
            document.write(item.doc.title);
            document.write("</a>. " + item.doc.overview);
            document.writeln("</li>");
        }
    }

    for (var i = 0; i < items.length; i++) {
        var item = items[i];

        if (item.children.length > 0) {
            document.write("<li class='directory'>");

            if (item.doc == null) {
                document.writeln(item.name);
            } else {
                document.write("<a href='");
                document.write("{{home}}");
                document.write(item.doc.url);
                document.write("'>");
                document.write(item.doc.title);
                document.write("</a>");
                document.writeln("");
            }

            outputSectionNavTree(item.children);
            document.writeln("</li>");
        }
    }

    document.writeln("</ul>");
}

// Given an array of documents, generate a section index tree
function genSectionNavTree(docs) {
    var items = makeNavTree(null, docs, 0);
    document.writeln("<div class='section-index'>");
    outputSectionNavTree(items);
    document.writeln("</div>");
}
