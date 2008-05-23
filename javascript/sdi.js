function populate(){
   var tbls = document.getElementsByTagName('table');  
	var row;   
   var cols;
     
   for (var tb=0; tb<tbls.length; tb++) {
   	row = tbls[tb].getElementsByTagName('tr');
   	cols = row[0].getElementsByTagName('td');
		
		var temp = new Array(cols.length)
		for (var col=0; col<cols.length; col++){
	      temp[col] = cols[col].innerHTML;
		} 
		
		var tbid = tbls[tb].id; 
		divID = tbid + '_cols';
		create_list(tbid, temp, divID);
		paint(tbid);
   }
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
	elementID = elementID + '_div';
   element = document.getElementById(elementID);
   if (element.style.display=='none')
      element.style.display='';
   else
      element.style.display='none';
}

function column(table, col, show){
   var stl;
   if (show) stl = ''
   else      stl = 'none';

   var tbl  = document.getElementById(table);
   var rows = tbl.getElementsByTagName('tr');
	
	for (var row=0; row<rows.length; row++) {
      var cels = rows[row].getElementsByTagName('td')
      cels[col].style.display=stl;
   }
}

function create_list(table, cols, elementID){
	var i;
   element = document.getElementById(elementID);
	element.innerHTML = ''
	for (i in cols){
	   element.innerHTML = element.innerHTML + '<input type="checkbox" id="'+table+i+'" onClick="javascript:column(\''+table+'\','+i+',this.checked);" checked="checked" /> <label for="'+table+i+'">'+cols[i]+'</label> ';
	}
}


