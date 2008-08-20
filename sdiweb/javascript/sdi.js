var selected;
var menu_scroll = new Array();
var pagetype;
var update = false;

function populate(){
    var tbls = document.getElementsByTagName('table');  
    var row;   
    var cols;

    // fill sdi bar date field
    set_date('date');
    
    // get pagetype
    pagetype = document.getElementById('pagetype').innerHTML;
    
    for (var tb=0; tb<tbls.length; tb++) {
        row = tbls[tb].getElementsByTagName('tr');
        cols = row[0].getElementsByTagName('td');

        var all = new Array(cols.length)
        for (var col=0; col<cols.length; col++){
                all[col] = cols[col].innerHTML;
        }

        var tbid = tbls[tb].id;
        colsID = tbid + '_cols';

        var loadID = tbid + '_load';
        document.getElementById(loadID).innerHTML = '<img ' +
        'src="img/loader.gif" /> Carregando...';
	
        var cookieName = location.href+'#'+tbid;
        if (get_cookie(cookieName)){
            selected = get_cookie(cookieName).split(',');
        } else {
            var colsSel = document.getElementById(colsID);
            selected = colsSel.innerHTML.split(',');
            set_cookie(cookieName, selected.join(','), null);
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

function load_page(href){
    if (pagetype=="sumary")
        window.location.href = href;
    else
        window.location.href = '../' + href;
}

function set_date(elementID){
    var Months = new Array('janeiro', 'fevereiro', 'março', 'abril',
                           'maio', 'junho', 'julho', 'agosto', 'setembro',
                           'outubro', 'novembro', 'dezembro')
    var now = new Date();
    element = document.getElementById(elementID);

    element.innerHTML = now.getDate() + " de " + Months[now.getMonth()] + 
                                        " de " + now.getFullYear();
}

function paint(table){
    var tbl  = document.getElementById(table);
    var rows = tbl.getElementsByTagName('tr');
 
    for (var row=1; row<rows.length; row++)
        if (row%2==1)
            rows[row].className="painted";
        else
            rows[row].className="";
}

function expand(elementID){
    element = document.getElementById(elementID);

    if (element.style.display=='none')
        element.style.display='';
    else
        element.style.display='none';
}

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
        image.innerHTML='<img src="img/expandUP.jpg" />';
        menu_scroll[i][1] = true;
    } else {
        element.style.display='none';
        image.innerHTML='<img src="img/expandDOWN.jpg" />';
        menu_scroll[i][1] = false;
    }

}

function column(table, col, show){
    var stl;
    if (show){
        stl = ''
        selected.push(col);
    } else {
        stl = 'none';
        var new_selected = selected.join(',');
        selected = new_selected.replace(','+col,'').replace(col+',','').split();
    }
    
    var cookieName = location.href+'#'+table;
    set_cookie(cookieName, selected.join(','), null);

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
        cels[colnum].style.display=stl;
    }
}

function create_list(table, cols, selected, elementID){
    var i;
    var html = '';
    
    element = document.getElementById(elementID);
    element.innerHTML = '<ul>';

    for (i in cols){
        html = html + '<li><input type="checkbox" id="'+table+i+'" ' + 
        'onClick="javascript:column(\''+table+'\',\''+cols[i]+'\', ' +
        'this.checked);" ';
        
        var j;
        var haveIt = false;
        
        for (j=0; j<cols.length; j++){
            if (cols[i]==selected[j]){
                haveIt = true;
                break;
            }
        }

        if (haveIt)
            html = html + 'checked="checked"';
        else
            column(table, cols[i], false);

        html = html + ' /> ' +
        '<label for="'+table+i+'">'+cols[i]+'</label></li>';
    }

    element.innerHTML = html;
}

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

function set_cookie(name, value, expireDays){
    var exdate = new Date();
    exdate.setDate(exdate.getDate()+expireDays);
    document.cookie = name + '=' + escape(value) +
    ((expireDays==null) ? '' : '; expires='+exdate.toGMTString());
}

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
