var selected;
var menu_scroll = new Array();
var pagetype;

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
