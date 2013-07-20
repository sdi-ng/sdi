var fs = require('fs');

module.exports = exports = MapManager;

// must load the nodes database
function MapManager(dblist,infodir){
  this.infodir = infodir;
  this.nodes = {};
  this.conn = {};

  // base to map IP and Name to node id
  this.nodeByIP = {};
  this.nodeByName = {};
  this.nodeNameByID = {};
  this.nodeNameByIP = {};

  // load file and keep it in memory
  var nodeListTxt = fs.readFileSync(dblist,'utf-8');
  var nodesSplitted = nodeListTxt.split('\n');
  for(var id in nodesSplitted){
    if(id==nodesSplitted.length-1) break;
    nodeID   = nodesSplitted[id].split(':')[0];
    nodeName = nodesSplitted[id].split(':')[1];
    nodeIP   = nodesSplitted[id].split(':')[2];
    this.nodeByIP[nodeIP] = nodeID;
    this.nodeByName[nodeName] = nodeID;
    this.nodeNameByID[nodeID] = nodeName;
    this.nodeNameByIP[nodeIP] = nodeName;
  }
}

MapManager.prototype.registerNode = function(nodename){
  if(!this.nodes[nodename]){
    // read node information
    var nodeID = this.getNodeID(nodename);
    var datastring = fs.readFileSync(this.infodir+'/'+nodeID+'.json','utf-8');
    this.nodes[nodename] = JSON.parse(datastring);
    this.nodes[nodename]['color'] = 'red';
  }
  return true;
};

MapManager.prototype.getNodeID = function(node){
  if(this.nodeByIP[node]) return this.nodeByIP[node];
  if(this.nodeByName[node]) return this.nodeByName[node];
  return false;
};

MapManager.prototype.getNodeName = function(node){
  if(this.nodeNameByIP[node]) return this.nodeNameByIP[node];
  if(this.nodeNameByID[node]) return this.nodeNameByID[node];
  return false;
};

MapManager.prototype.addConnection = function(nodeA,nodeB){
  nodeA = this.getNodeID(nodeA);
  nodeB = this.getNodeID(nodeB);
  if(!nodeA || !nodeB) return false;
  if(nodeA == nodeB) return false;

  if(!this.conn[nodeA]) this.conn[nodeA] = {};
  this.conn[nodeA][nodeB] = {color: 'black', opacity: 1, weight: 1};
  return true;
};

MapManager.prototype.removeConnection = function(nodeA,nodeB){
  nodeA = this.getNodeID(nodeA);
  nodeB = this.getNodeID(nodeB);
  if(!nodeA || !nodeB) return false;
  if(nodeA == nodeB) return false;

  if(!this.conn[nodeA]) return false;
  if(!this.conn[nodeA][nodeB]) return false;
  delete this.conn[nodeA][nodeB];
  return true;
};

MapManager.prototype.updateConnection = function(nodeA,nodeB,attrs){
  var nodeA = this.getNodeID(nodeA);
  var nodeB = this.getNodeID(nodeB);
  if(!nodeA || !nodeB) return false;
  if(nodeA == nodeB) return false;
  if(!this.conn[nodeA]) return false;
  if(!this.conn[nodeA][nodeB]) return false;

  var nameA = this.getNodeName(nodeA);
  // mycolor color opacity weight
  if(attrs['color']) this.conn[nodeA][nodeB]['color'] = attrs['color'];
  if(attrs['opacity']) this.conn[nodeA][nodeB]['opacity'] = attrs['opacity'];
  if(attrs['weight']) this.conn[nodeA][nodeB]['weight'] = attrs['weight'];
  return true;
};

MapManager.prototype.updateNode = function(nodeA,attrs){
  var nodeA = this.getNodeID(nodeA);
  if(!nodeA) return false;

  // node are mapped with their name
  var nameA = this.getNodeName(nodeA);
  if(attrs['mycolor']) this.nodes[nameA]['color'] = attrs['mycolor'];
  return true;
};

MapManager.prototype.getConnections = function(){
  return this.conn;
};

MapManager.prototype.getNodes = function(){
  return this.nodes;
};
