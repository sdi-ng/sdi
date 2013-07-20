exports.updatedata = function(host,data,callback){
  callback(null,data);
};

exports.www = function(host,data,callback){
  var res = {'states':[],'data':data};
  if(data=="ONLINE")  res['color']="green";
  if(data=="OFFLINE") res['color']="red";
  res.states.push({'online': data=="ONLINE"});
  res.states.push({'offline':data=="OFFLINE"});
  callback(null,res);
};
