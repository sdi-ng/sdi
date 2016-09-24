exports.info = {
  'webinterface': true,
  'colname': 'Uptime'
};

exports.updatedata = function(host,data,callback){
  callback(null,data);
};

exports.www = function(host,data,callback){
  days=hrs=mins='';
  for(i=0;data[i]!=' ';i++)    days+=data[i]; for(i=i+1;data[i]!=' ';i++);
  for(i=i+1;data[i]!=':';i++)  hrs+=data[i];
  for(i=i+1;i<data.length;i++) mins+=data[i];
  if(hrs.length==1)  hrs='0'+hrs;
  if(mins.length==1) mins='0'+mins;
  var res = {'states':[],'data':data,'sort':days+hrs+mins};
  res.states.push({'highuptime':days>=10});
  res.states.push({'lowuptime':days<=2});
  callback(null,res);
};
