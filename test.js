var http = require('http');
var hyperquest = require('hyperquest');
var request = require('request');

/* -- Making calls ---------------------------------------------------------- */
var interval_id = setInterval(function(){proxy();}, 5000);

j = 0
var proxy = function() {
  j = (j < 3) ? (j + 1) : 0
  hyperquest('http://localhost:8000');
  hyperquest('http://localhost:8000/domain');
  hyperquest('http://localhost:8000/user/cataflu');
  hyperquest('http://localhost:8000/domain/subdomain');
  // hyperquest('http://localhost:8000/domain/subdomain/');
  hyperquest('http://localhost:8000/domain/subdomain/endpoint?name=javi&twitter=soyjavi');


  request({
    uri: "http://localhost:8000/domain/subdomain/endpoint?op=true",
    method: "POST",
    form: {
      name: "Javi",
      twitter: "@soyjavi"
    }
  } , function(error, response, body) {} );

  // hyperquest.put('http://localhost:8000/domain/subdomain');
  hyperquest.delete('http://localhost:8000/domain/subdomain');

};

proxy();
process.stdout.setMaxListeners(0);
