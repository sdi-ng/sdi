exports.info = {
  'webinterface': true,
  'colname': 'Last Contact'
};

exports.updatedata = function(host,data,callback){
  callback(null,data);
};

exports.www = function(host,data,callback){
  var res = {'states':[],'data':new Date().toUTCString()};
  callback(null,res);
};
