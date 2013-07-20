//require('nodetime').profile();

// this is a worker
var https = require('https');
var fs = require('fs');
var http = require('http');
var util = require('util');
var url = require('url');
var crypto = require('crypto');
var path = require('path');

// create a new states manager
var StatesManager = require(__dirname+'/states.js');
var sm = new StatesManager();

// get configuration
var execSync = require('exec-sync');
var config = execSync(__dirname+'/../configsdiparser.py '+__dirname+'/../sdi.conf js all');
eval(config);

// fix some basic config
var statedir = wwwdir+'/states';
//if(usefastdatadir=='yes') datadir=fastdatadir;

//function isNumeric(a){ return !isNaN(parseFloat(a)) && isFinite(a); }

// load the enabled commands
var commands = {};
{
  var errors = [];
  process.stdout.write('Loading commands... ');

  // traverse on each hooks dir (onconnect.d, on.minutely.d, ...)
  // the hooks dir come from the configuration
  var relativePaths = [];
  var dirs = fs.readdirSync(hooks);
  for(var dir in dirs){
    var files = fs.readdirSync(hooks+'/'+dirs[dir]);
    for(var file in files)
      relativePaths.push(hooks+'/'+dirs[dir]+'/'+files[file]);
  }

  // sort the paths acording to the files basenames
  relativePaths.sort(function(a,b){
    return path.basename(a)>path.basename(b);
  });

  // loat the commands
  for(var index in relativePaths){
    // try loading the user script, and alerts in case of errors
    try {
      var relativePath = relativePaths[index];
      var path = fs.realpathSync(relativePath);
      var cmd = path.split('/').pop();
      commands[cmd] = require(path+'.js');
    } catch(e){
      errors.push('Unable to load command '+cmd+' ('+relativePath+')');
    }
  }
  if(errors.length) console.error('\n'+errors.join('\n'));
  console.log('done.');
}

// load the enabled states
var states = {};
{
  var errors = [];
  process.stdout.write('Loading states... ');

  // the shooks dir come from the configuration
  var files = fs.readdirSync(shooks);
  for(var file in files){
    // try loading the user script, and alerts in case of errors
    try {
      var relativePath = shooks+'/'+files[file];
      var path = fs.realpathSync(relativePath);
      var statename = path.split('/').pop();
      states[statename] = require(path+'.js');
      sm.registerState(statename);
    } catch(e){
      errors.push('Unable to load state '+statename+' ('+relativePath+')');
    }
  }
  if(errors.length) console.error('\n'+errors.join('\n'));
  console.log('done.');
}

// load the enabled summaries
var summaries = {};
{
  var errors = [];
  process.stdout.write('Loading summaries... ');

  // the shooks dir come from the configuration
  var files = fs.readdirSync(sumhooks);
  for(var file in files){
    // try loading the user script, and alerts in case of errors
    try {
      var relativePath = sumhooks+'/'+files[file];
      var path = fs.realpathSync(relativePath);
      var summaryname = path.split('/').pop();
      summaries[summaryname] = require(path+'.js');
    } catch(e){
      errors.push('Unable to load summary '+summaryname+' ('+relativePath+')');
    }
  }
  if(errors.length) console.error('\n'+errors.join('\n'));
  console.log('done.');
}


// load the node list in memory and calculate its md5
var nodeListTxt = fs.readFileSync(nodedbdir+'/list','utf-8');
var nodeListHash = crypto.createHash('md5').update(nodeListTxt).digest('hex');

// process the list and create a map from id to host name
var nodeList = {};
{
  var nodesSplitted = nodeListTxt.split('\n');
  for(var id in nodesSplitted){
    if(id==nodesSplitted.length-1) break;
    nodeList[id] = nodesSplitted[id].split(':')[1];
  }
}

// load the classes
var classes = {};
{
  var errors = [];
  process.stdout.write('Loading classes... ');

  // the shooks dir come from the configuration
  var files = fs.readdirSync(classesdir);
  for(var file in files){
    // try loading the user script, and alerts in case of errors
    try {
      var path = classesdir+'/'+files[file];
      var classname = files[file].toLowerCase();
      classes[classname] = [];

      var list = fs.readFileSync(path,'utf-8');
      var nodesSplitted = list.split('\n');
      for(var id in nodesSplitted){
        if(id==nodesSplitted.length-1) break;
        classes[classname].push(nodesSplitted[id]);
      }
    } catch(e){
      errors.push('Unable to load class '+classname+' ('+path+')');
    }
  }
  if(errors.length) console.error('\n'+errors.join('\n'));
  console.log('done.');
}



// holder of every node informations
var nodeData = {};
{
  for(var node in nodeList){
    node = nodeList[node];
    nodeData[node] = {};
    for(var command in commands)
      nodeData[node][command] = {data: '', sort: '', color: ''};
  }
}



//console.log(util.inspect(nodeList));
//console.log(util.inspect(commands));
//console.log(util.inspect(states));
//console.log(util.inspect(summaries));
//console.log(util.inspect(classes));
//return;


// find if a host with that id exists
function findHost(hostId,callback){
  if(!nodeList[hostId]) return callback(new Error('host '+hostId+' not found'));
  console.log("ID: "+hostId+" -> "+nodeList[hostId]);
  return callback(null,nodeList[hostId]);
}


// parse a bunch of states related to a host
function parsestate(host,state){
  // simply set states to their values
  for(statename in state){
    if(!states[statename])
      return new Error('state '+statename+' not found');
    if(typeof state[statename] != 'boolean')
      return new Error('invalid state type for '+statename);
    sm.setState(host,statename,state[statename]);
  }
  return;
}

// TODO calls to updatedata and www should within try/catch
// parse messages from data related to host
function parse(host,data){
  if(!data) return;
  var ts = Math.round((new Date()).getTime()/1000);

  // import command
  var firstplus = data.indexOf('+');
  var cmd = data.substring(0,firstplus).toLowerCase();

  // if cant find the command, just log it
  if(!commands[cmd]){
    fs.appendFile(datadir+'/'+host+'/'+host+'.log',ts+' '+data+'\n');
    return;
  }

  // get only what matters
  var data = data.substring(firstplus+1);

  // update data file
  var datafile = datadir+'/'+host+'/'+cmd;
  commands[cmd].updatedata(host,data,function(err,datatowrite){
    fs.appendFile(datafile,ts+' '+datatowrite+'\n');
  });

  // update www information
  var wwwfile = wwwdir+'/hosts/'+host+'/'+cmd+'.xml';
  commands[cmd].www(host,data,function(err,wwwinfo){
    // states
    if(wwwinfo.states)
      for(var state in wwwinfo.states)
        parsestate(host,wwwinfo.states[state]);

    // color / customsort / text
    var color = (wwwinfo.color)?'class="'+wwwinfo.color+'"':"";
    var sort  = (wwwinfo.sort)?'sorttable_customkey="'+wwwinfo.sort+'"':"";
    var text  = (wwwinfo.data)?wwwinfo.data:wwwinfo;

    var datatowrite = '<'+cmd+' value="'+text+'" '+color+' '+sort+' />';
    fs.writeFile(wwwfile,datatowrite+'\n');

    // store in memory too
    nodeData[host][cmd]['data'] = text;
    nodeData[host][cmd]['color'] = color;
    nodeData[host][cmd]['sort'] = sort;
  });
}


function columnsXML(){
  var xml = '<host name="columns">';
  xml += '<hostname value="'+hostcolumnname+'" />';
  for(var command in commands){
    var info = commands[command].info;
    if(info['webinterface'])
      xml += '<'+command+' value="'+info['colname']+'" />';
  }
  xml += '</host>';
  return xml;
}

function nodeXML(node){
  var xml = '<host name="'+node+'">';
  xml += '<hostname value="'+node+'" />';
  for(var command in nodeData[node]){
    var info = commands[command].info;
    if(!info['webinterface']) continue;
    xml += '<'+command+' value="'+nodeData[node][command]['data']+'"';
    if(nodeData[node][command]['sort']!='')
      xml += ' '+nodeData[node][command]['sort'];
    if(nodeData[node][command]['color']!='')
      xml += ' '+nodeData[node][command]['color'];
    xml += ' />';
  }
  xml += '</host>';
  return xml;
}

function getauthentication(req){
  header=req.headers['authorization']||'';
  token=header.split(/\s+/).pop()||'';
  auth=new Buffer(token,'base64').toString();
  parts=auth.split(/:/);
  return parts;
}

// TODO: read credentials from file and store then in memory
function validcredentials(auth){
  return (auth[0]=='user' && auth[1]=='senha');
}

// start the server
var httpport = parseInt(serverport)+1;
console.log('Running at https://0.0.0.0:'+serverport+'/');
console.log('Running at http://0.0.0.0:'+httpport+'/');

// server HTTPS key/cert
var options = {
  key:  fs.readFileSync(__dirname+'/certificates/server.key'),
  cert: fs.readFileSync(__dirname+'/certificates/server.crt')
};

https.createServer(options,function(req,res){
  host = req.connection.remoteAddress;
  auth = getauthentication(req);
  if(auth.length!=2 || !validcredentials(auth)){
    res.statusCode = 401; // Unauthorized
    res.setHeader('WWW-Authenticate', 'Basic realm="SDI Secure Area"');
    res.end('Please provide credentials.');
    res.end();
    return;
  }
  req.setEncoding('utf8');

  if(req.method=='GET'){
    req.on('end',function(){
      if(req.url=='/list.md5'){
        res.writeHead(200,{'Content-Type':'text/plain'});
        res.write(nodeListHash);
        console.log('Sent HASH of list of nodes to '+req.connection.remoteAddress);
      } else if(req.url=='/list.txt'){
        res.writeHead(200,{'Content-Type':'text/plain'});
        res.write(nodeListTxt);
        console.log('Sent list of nodes to '+req.connection.remoteAddress);
      } else {
        res.statusCode = 404;
      }
      res.end();
    });
  } else if(req.method=='POST'){
    var postdata = "";
    req.on('data',function(d){ postdata += d; });
    req.on('end',function(){
      console.log(postdata);
      // TODO: move connection end here

      // separate host and data
      var body = postdata.split('\n');
      var host = body[0]; body.shift();

      // find the hostname based on the host number
      // process the data and return to the client
      findHost(host,function(err,host){
        if(err){
          console.error(req.connection.remoteAddress+': '+err.toString());
          res.statusCode = 500;
          res.end();
          return;
        }
        for(element in body) parse(host,body[element]);
        res.end();
      });
    });
  }
}).listen(serverport,'0.0.0.0');


var path = require('path');
// this is the server that will responde to XML calls
var xmlserver = http.createServer(function(req,res){
  // we only serve get requests
  if(req.method!='GET'){
    res.writeHead(500);
    res.end();
    return;
  }

  // and XML files
  var file = url.parse(req.url).pathname;
  if(path.extname(file)!='.xml'){
    res.writeHead(404);
    res.end();
    return;
  }

  // inspect the directory to check if its summary or class xml
  var dir = path.dirname(file);

  // we are talking about a summary
  if(dir=='/'){
    summary = path.basename(file,'.xml').toLowerCase();
    if(!summaries[summary]){
      res.writeHead(404);
      res.end();
      return;
    }

    // all ok. lets responde with the summary xml
    res.writeHead(200,{
      'Content-Type':'application/xml',
      'Access-Control-Allow-Origin':'http://planetmon.inf.ufpr.br'
    });
    res.write('<?xml version="1.0" encoding="utf-8"?>');
    res.write('<summary name="index"><data>');
    for(var state in summaries[summary].info['states']){
      state = summaries[summary].info['states'][state];
      infotext = states[state].info['sumarytext'].replace('%d',sm.count(state));
      res.write('<'+state+'>'+infotext+'</'+state+'>')
    }
    res.write('</data>');
    for(var state in summaries[summary].info['states']){
      state = summaries[summary].info['states'][state];
      info = states[state].info;
      res.write('<table title="'+info.title+'" columns="'+info.defaultcols+'" showtable="'+info.showtable+'">');
      if(info.showtable){
        res.write(columnsXML());
        var nodesInState = sm.getState(state);
        for(var node in nodesInState)
          res.write(nodeXML(node));
      }
      res.write('</table>')
    }
    res.write('</summary>');
    res.end();

  // we are talking about a class
  } else {

    nodeclass = dir.split('/')[1].toLowerCase();
    //console.log(nodeclass);
    if(!classes[nodeclass]){
      res.writeHead(404);
      res.end();
      return;
    }

    // all ok. lets respond with the summary xml
    res.writeHead(200,{
      'Content-Type':'application/xml',
      'Access-Control-Allow-Origin':'http://planetmon.inf.ufpr.br'
    });
    res.write('<?xml version="1.0" encoding="utf-8"?>');
    res.write('<class name="'+nodeclass+'">');
    res.write(columnsXML());
    for(var node in classes[nodeclass])
      res.write(nodeXML(classes[nodeclass][node]));
    res.write('</class>');
    res.end();
  }
}).listen(httpport,'0.0.0.0');
