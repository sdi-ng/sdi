module.exports = exports = StatesManager;

function StatesManager(){
  this.states = {};
  this.counter = {};
}

StatesManager.prototype.registerState = function(statename){
  if(!this.states[statename]){
    this.states[statename] = {};
    this.counter[statename] = 0;
  }
  return true;
};

StatesManager.prototype.setState = function(host,statename,state){
  var currentState = this.states[statename][host];
  if(currentState===undefined && state==true){
    this.states[statename][host] = true;
    this.counter[statename]++;
    return;
  }
  if(currentState!==undefined && state==false){
    delete this.states[statename][host];
    this.counter[statename]--;
  }
};

StatesManager.prototype.getStates = function(){
  return this.states;
};

StatesManager.prototype.getState = function(statename){
  if(!this.states[statename]) return false;
  return this.states[statename];
};

StatesManager.prototype.find = function(statename){
  return (this.states[statename]!==undefined);
};

StatesManager.prototype.count = function(statename){
  return this.counter[statename];
};
