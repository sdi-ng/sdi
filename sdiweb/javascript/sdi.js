var selected;
var menu_scroll = new Array();
var pagetype;
var update = false;
var months;

// main function, must be called when page is fully loaded
// its responsable to set all table and page features
function populate(){
    var tbls = document.getElementsByTagName('table');  
    var row;   
    var cols;

    // discover and set language
    load_language(false);
    
    // get pagetype
    pagetype = document.getElementById('pagetype').innerHTML;
    
    // for each table
    for (var tb=0; tb<tbls.length; tb++) {
        row = tbls[tb].getElementsByTagName('tr');
        cols = row[0].getElementsByTagName('td');

        // get all cols name
        var all = new Array(cols.length)
        for (var col=0; col<cols.length; col++){
                all[col] = cols[col].innerHTML;
        }

        var tbid = tbls[tb].id;
        var loadID = tbid + '_load';
        colsID = tbid + '_cols';

        // check if get default cols from cookie, or from colsID div
        var cookie_name = location.href+'#'+tbid;
        if (get_cookie(cookie_name)){
            selected = get_cookie(cookie_name).split(',');
        } else {
            var colsSel = document.getElementById(colsID);
            selected = colsSel.innerHTML.split(',');
            set_cookie(cookie_name, selected.join(','), null);
        }

        // check the cookie for auto update
        var cookie_name = location.href+'#jsupdater';
        if (get_cookie(cookie_name)){
            update = get_cookie(cookie_name);
            if (update=="true"){
                document.getElementById('update').checked = "checked";
                update = true;
            }
        }

        // insert table info on menu_scroll
        // this is done cause all tables must have
        // a separated scroll variable.
        var info = new Array(2);
        info[0] = tbid;
        info[1] = true;
        menu_scroll.push(info);

        create_list(tbid, all, selected, colsID);
        paint(tbid);

        expand(loadID);
        expand(tbid);
    }
}

// used on sdibar to redirect pages
function load_page(href){
    if (pagetype=="summary")
        window.location.href = href;
    else
        window.location.href = '../' + href;
}

// returns str with the first character capitalized
function init_cap(str){
    return str.substr(0,1).toUpperCase() + str.substr(1);
}

// fills element with the current date according to format
function set_date(elementID, format){
    var now = new Date();
    element = document.getElementById(elementID);

    format = format.replace('%d', now.getDate()).replace('%y', now.getFullYear());
    format = format.replace('%m', months[now.getMonth()]);
    format = format.replace('%M', init_cap(months[now.getMonth()]));

    element.innerHTML = format;
}

// paint a table to a better data view
function paint(table){
    var tbl  = document.getElementById(table);
    var rows = tbl.getElementsByTagName('tr');
 
    for (var row=1; row<rows.length; row++)
        if (row%2==1)
            rows[row].className="painted";
        else
            rows[row].className="";
}

// expand a element
function expand(elementID){
    element = document.getElementById(elementID);

    if (element.style.display=='none')
        element.style.display='';
    else
        element.style.display='none';
}

// expand a table and change the table bar information
function table_expand(tbID){
    element = document.getElementById(tbID);
    image = tbID + '_expand';
    image = document.getElementById(image);

    // find table numeric id at menu_scroll
    var i;
    for (i=0; i<menu_scroll.length; i++)
        if (menu_scroll[i][0]==tbID)
            break;
    
    if (element.style.display=='none'){
        element.style.display='';
        image.innerHTML='<img src="img/expand_up.jpg"' +
                        'alt="" title="" />';
        menu_scroll[i][1] = true;
    } else {
        element.style.display='none';
        image.innerHTML='<img src="img/expand_down.jpg"' +
                        'alt="" title="" />';
        menu_scroll[i][1] = false;
    }

}

// expand a table column and update the table cookie
function column_expand(table, col, show){
    var stl;
    if (show){
        stl = ''
        selected.push(col);
    } else {
        stl = 'none';
        var new_selected = selected.join(',');
        new_selected = new_selected.replace(','+col,'').replace(col+',','');
        selected = new_selected.split();
    }
    
    var cookie_name = location.href+'#'+table;
    set_cookie(cookie_name, selected.join(','), null);

    var tbl  = document.getElementById(table);
    var rows = tbl.getElementsByTagName('tr');

    // get col number
    var cols = rows[0].getElementsByTagName('td');
    var colnum = -1;

    for (i=0; i<cols.length; i++)
        if (cols[i].innerHTML==col)
            colnum = i;

    for (var row=0; row<rows.length; row++) {
        var cels = rows[row].getElementsByTagName('td')
        cels[colnum].style.display = stl;
    }
}

// create the menu list of columns
function create_list(table, cols, selected, elementID){
    var i;
    var html = '';
    
    element = document.getElementById(elementID);
    element.innerHTML = '<ul>';

    // for each col, add a menu item
    for (i in cols){
        html = html + '<li><input type="checkbox" id="'+table+i+'" ' + 
        'onClick="column_expand(\''+table+'\',\''+cols[i]+'\', ' +
        'this.checked);" ';
        
        var j;
        var haveIt = false;
        
        // search if the col is selected
        for (j=0; j<cols.length; j++){
            if (cols[i]==selected[j]){
                haveIt = true;
                break;
            }
        }

        if (haveIt)
            html = html + 'checked="checked"';
        else
            column_expand(table, cols[i], false);

        html = html + ' /> ' +
        '<label for="'+table+i+'">'+cols[i]+'</label></li>';
    }

    element.innerHTML = html;
}

// hide the menu, trigered with onmouseout
function hide_menu(e, element){
    if (!e) var e = window.event;
    var tg = (window.event) ? e.srcElement : e.target;
    if (tg.nodeName != 'DIV') return;
    var reltg = (e.relatedTarget) ? e.relatedTarget : e.toElement;
    while (reltg != tg && reltg.nodeName != 'BODY')
        reltg = reltg.parentNode
    if (reltg== tg) return;
    // Mouseout took place when mouse actually left layer
    // Handle event
    element.className='hide';
}

// show the menu, trigered with onmouseover
function show_menu(elementID){
    var i;
    var tbid = elementID.split('_cols')[0];
    for (i=0; i<menu_scroll.length; i++){
        if (menu_scroll[i][0]==tbid && menu_scroll[i][1]){
            document.getElementById(elementID).className='select_cols';
            break;
        }
    }
}

// set the update variable to control auto table update
function set_update(set){
   var cookie_name = location.href+'#jsupdater';
   set_cookie(cookie_name, set, null);

   update = set;
}

// -------------------- Cookies relates functions

// a simple set cookie interface
function set_cookie(name, value, expireDays){
    var exdate = new Date();
    exdate.setDate(exdate.getDate()+expireDays);
    document.cookie = name + '=' + escape(value) +
    ((expireDays==null) ? '' : '; expires='+exdate.toGMTString());
}

// a simple get cookie interface
function get_cookie(name){
    if (document.cookie.length>0){
        start = document.cookie.indexOf(name + "=");
        if (start!=-1){ 
            start = start + name.length+1; 
            end = document.cookie.indexOf(";",start);
            if (end==-1) end = document.cookie.length;
            return unescape(document.cookie.substring(start, end));
        } 
    }
    return "";
}

// -------------------- DOM relates functions

// retrieves all elements from node with a class
function getElementsByClass(searchClass,node,tag) {
    var classElements = new Array();
    if (node == null)
        node = document;
    if (tag == null)
        tag = '*';
    var els = node.getElementsByTagName(tag);
    var elsLen = els.length;
    var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
    var j = 0;
    for (i = 0; i < elsLen; i++) {
        if (pattern.test(els[i].className) ) {
            classElements[j] = els[i];
            j++;
        }
    }
    return classElements;
}

// -------------------- XML and tables related functions

// loads a xmlURI and return the DOM object
function load_xml(xmlURI){
    try {
        // IE
        xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
    } catch(e) {
        try {
            // Firefox
            xmlDoc = document.implementation.createDocument("","",null);
        } catch(e) {
            alert(e.message);
            return;
        }
    }

    // get the file
    xmlDoc.async = false;
    xmlDoc.load(xmlURI);

    return xmlDoc;
}

// get the first element with tagname
function get_tag(xmlDoc, tagname){
    var node = xmlDoc.getElementsByTagName(tagname);
    if (node==null)
        return null;
    else {
        node = node[0];
        // IE
        if (node.text)
            return node.text;
        // Firefox
        else
            return node.textContent;
    }
}

function create_tablebody(xmlNode){
    // create the table body
    var tablebody = document.createElement('tbody');
    var hosts = xmlNode;

    // this will hold your tr's and td's elements
    var row = new Array();
    var col = new Array();

    // counters
    var i, j, h;

    for (h=0; h<hosts.length; h++){
        // create the row
        row[h] = document.createElement('tr');

        var fields = hosts[h].childNodes;
        for (i=0; i<fields.length; i++){
            if (fields[i].nodeType==1){
                // create the col
                col[i] = document.createElement('td');

                // populate the collumn
	            for (j=0; j<fields[i].attributes.length; j++)
                    if (fields[i].attributes[j].name=='value'){
                        // IE hack should go here
                        innerTEXT = fields[i].attributes[j].textContent;
                        innerTEXT = document.createTextNode(innerTEXT);
                        col[i].appendChild(innerTEXT);
                    } else {
                        // IE hack should go here
                        col[i].setAttribute(fields[i].attributes[j].name,
                                      fields[i].attributes[j].textContent);
                    }

                // append the col
                row[h].appendChild(col[i]);
	        }

        }
        // append the row
        tablebody.appendChild(row[h]);
    }

    return tablebody;
}

// with a xmlURI, this function load it and create a table element,
// appending it to the tableContainer.
// check the documentation to the XML format
function create_table_from_xml(xmlURI, tableID, tableContainerID){
    // load XML
    xmlDoc = load_xml(xmlURI);

    // create table element
    var table = document.createElement('table');
    table.setAttribute('id',tableID);
    table.setAttribute('class','sortable');
    table.setAttribute('style','display: none;');

    var hosts = xmlDoc.getElementsByTagName("host");
    var tablebody = create_tablebody(hosts);

    // to finish
    table.appendChild(tablebody);

    // update the container
    tableContainer = document.getElementById(tableContainerID);
    tableContainer.appendChild(table);

    // set interval to reload the table
    window.setInterval(reload_table, 60000, xmlURI, tableID);
}

function create_table_topbar(tableID, tableTitle, defaultColumns){
    var table_div = document.createElement('div');

    table_div.setAttribute('class', 'table_bar');
    table_div.setAttribute('id', tableID+'_bar');

    var h3 = document.createElement('h3');
    var a = document.createElement('a');
    var img = document.createElement('img');

    a.setAttribute('href', 'javascript:table_expand(\''+tableID+'\');');
    a.setAttribute('id', tableID+'_expand');

    img.setAttribute('src', 'img/expand_up.jpg');
    img.setAttribute('alt', '');
    img.setAttribute('title', '');

    a.appendChild(img);
    h3.appendChild(a);
    h3.appendChild(document.createTextNode(' '+tableTitle));
    table_div.appendChild(h3);

    var right_div = document.createElement('div');
    right_div.setAttribute('class', 'bar_right');

    var a = document.createElement('a');
    var img = document.createElement('img');
    var label = document.createElement('label');

    a.setAttribute('href', '#');
    a.setAttribute('onmouseover', 'show_menu(\''+tableID+'_cols\');');

    label.setAttribute('class', 'select_columns');

    img.setAttribute('src', 'img/columns.jpg');
    img.setAttribute('class', 'columns');
    img.setAttribute('alt', '');
    img.setAttribute('title', '');

    a.appendChild(label);
    a.appendChild(document.createTextNode(' '));
    a.appendChild(img);

    var div_cols = document.createElement('div');
    div_cols.setAttribute('class', 'hide');
    div_cols.setAttribute('id', tableID+'_cols');
    div_cols.setAttribute('onmouseout', 'hide_menu(event, this);');

    var columns = document.createTextNode(defaultColumns);
    div_cols.appendChild(columns);

    right_div.appendChild(a);
    right_div.appendChild(div_cols);

    table_div.appendChild(right_div);

    return table_div;
}

function create_table_structure(tableID){
    var table_div = document.createElement('div');
    var load_div = document.createElement('div');

    table_div.setAttribute('id', tableID+'_div');
    load_div.setAttribute('id', tableID+'_load');
    load_div.setAttribute('class', 'loading');

    var img = document.createElement('img');
    img.setAttribute('src', 'img/loader.gif');
    img.setAttribute('class', 'loading_image');
    img.setAttribute('alt', '');
    img.setAttribute('title', '');

    var span = document.createElement('span');
    span.setAttribute('class', 'loading_message');

    load_div.appendChild(img);
    load_div.appendChild(span);
    table_div.appendChild(load_div);

    return table_div;
}

function create_summary_from_xml(xmlURI, containerID){
    // load XML
    xmlDoc = load_xml(xmlURI);

    var i;
    var container = document.getElementById(containerID);
    var data = xmlDoc.getElementsByTagName("data")[0].childNodes;
    var text = '<br />';

    // first print the data on xml
    for (i=0; i<data.length; i++){
        if (data[i].nodeType==1){
            text = text + data[i].textContent + '<br />';
        }
    }

    // create table elemen
    var span = document.createElement('span');
    span.innerHTML = text;
    container.appendChild(span);

    var tables = xmlDoc.getElementsByTagName("table");

    for (i=0; i<tables.length; i++){
        for (j=0; j<tables[i].attributes.length; j++){
            switch (tables[i].attributes[j].name){
                case 'title':
                    // IE hack should go here
                    var title = tables[i].attributes[j].textContent;
                    break;
                case 'columns':
                    // IE hack should go here
                    var columns = tables[i].attributes[j].textContent;
                    break;
            }
        }
        var id = title.replace(/ /g,'');

        var table_bar = create_table_topbar(id, title, columns);
        var table_struct = create_table_structure(id);
        container.appendChild(table_bar);
        container.appendChild(table_struct);

        // create table element
        var table = document.createElement('table');
        table.setAttribute('id',id);
        table.setAttribute('class','sortable');
        table.setAttribute('style','display: none;');

        var tablebody = create_tablebody(tables[i].getElementsByTagName("host"));
        table.appendChild(tablebody);

        container.appendChild(table);
    }

}

// with a xmlURI, reload table information
// this means don't create the table itself
function reload_table(xmlURI, tableID){
    if (!update) return false;

    // reload XML
    xmlDoc = load_xml(xmlURI);

    // counters
    var i, j, h;

    // the target table
    var table = document.getElementById(tableID);
    var hosts = xmlDoc.getElementsByTagName("host");

    // h=1 jumps the table header
    for (h=1; h<hosts.length; h++){
        var fields = hosts[h].childNodes;

        // get the hostname on XML
        for (i=0; i<fields.length; i++)
            if (fields[i].nodeType==1 && fields[i].nodeName=='hostname'){
                // get the value of hostname
                for (j=0; j<fields[i].attributes.length; j++){
                    if (fields[i].attributes[j].name=='value'){
                        // IE hack should go here
                        hostname = fields[i].attributes[j].textContent;
                        break;
                    }
                }
            }

        // get the table line to be updated based on hostname
        rows = table.getElementsByTagName('tr');
        for (i=0; i<rows.length; i++){
            cols = rows[i].getElementsByTagName('td');
            if (cols[0].innerHTML==hostname){
                row = rows[i];
                break;
            }
        }
        cols = rows[i].getElementsByTagName('td');

        // start populating the table
        col = 0;
        for (i=0; i<fields.length; i++){
            if (fields[i].nodeType==1){
                // populate the line
	            for (j=0; j<fields[i].attributes.length; j++){
                    if (fields[i].attributes[j].name=='value'){
                        // IE hack should go here
                        innerTEXT = fields[i].attributes[j].textContent;
                        cols[col].innerHTML = innerTEXT;
                    } else {
                        // IE hack should go here
                        cols[col].setAttribute(fields[i].attributes[j].name,
                                         fields[i].attributes[j].textContent);
                    }
                }
                col++;
	        }

        }
    }

}

// -------------------- Language related functions

function load_language(language){
    // check the language cookie
    var cookie_name = 'lang';

    // decide from where get language
    if (language){
        lang = language;
        set_cookie(cookie_name, language, null);
    } else if (get_cookie(cookie_name)){
        lang = get_cookie(cookie_name);
    } else {
        lang = navigator.language;
        set_cookie(cookie_name, lang, null);
    }

    // load XML
    xmlDoc = load_xml('langs/'+lang+'.xml');

    // check if the language selected has been loaded
    if (xmlDoc.getElementsByTagName('language').length==0){
        load_language('en-US');
        return false;
    }

    var text, i;

    // page elements colection
    var select_page = document.getElementById('pages_select');
    var auto_update = document.getElementById('auto_update');
    var language_selection = document.getElementById('language_selection');
    var select_columns = getElementsByClass('select_columns', null, 'label');
    var select_columns_img = getElementsByClass('columns', null, 'img');
    var loading = getElementsByClass('loading_message', null, 'span');
    var loading_img = getElementsByClass('loading_image', null, 'img');

    // get data and update elements
    select_page.innerHTML = get_tag(xmlDoc, 'sdibar_pages_select') + ':';
    auto_update.alt = get_tag(xmlDoc, 'sdibar_auto_update');
    auto_update.title = auto_update.alt;
    months = get_tag(xmlDoc, 'sdibar_months').split(',');
    language_selection.innerHTML = get_tag(xmlDoc, 'langs_language_selection') + ':';

    // multiples tables elements update
    text = get_tag(xmlDoc, 'tables_select_columns');
    for (i=0; i<select_columns.length; i++)
        select_columns[i].innerHTML = text; 

    for (i=0; i<select_columns_img.length; i++){
        select_columns[i].alt = text;
        select_columns[i].title = text;
    }

    text = get_tag(xmlDoc, 'tables_loading');
    for (i=0; i<loading.length; i++)
        loading[i].innerHTML = text + '...';

    for (i=0; i<loading_img.length; i++){
        loading[i].alt = text;
        loading[i].title = text;
    }

    // update date field
    set_date('date', get_tag(xmlDoc, 'sdibar_date_format'));

    // select the current language on selectbox
    var box = document.getElementById('lang_sel');

    for (i=0; i<box.options.length; i++)
        if (box.options[i].value==lang)
            box.options[i].selected = true;
        else
            box.options[i].selected = false;
}

// vim:tabstop=4:shiftwidth=4:encoding=utf-8:expandtab
