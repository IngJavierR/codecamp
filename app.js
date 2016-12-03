'use strict';

var SwaggerHapi = require('swagger-hapi');
var Hapi = require('hapi');
require('coffee-script/register');
var Path = require('path');
const Inert = require('inert')

var app = new Hapi.Server({
    connections: {
        routes: {
            files: {
                relativeTo: Path.join(__dirname, 'public')
            }
        }
    }
});


module.exports = app; // for testing

var config = {
  appRoot: __dirname // required config
};

SwaggerHapi.create(config, function(err, swaggerHapi) {
  if (err) { throw err; }

  var port = process.env.PORT || 10010;
  app.connection({ port: port , host: "0.0.0.0", routes: {cors : true} });
  app.register(Inert, () => {});
  app.route({
      method: 'GET',
      path: '/{param*}',
      handler: {
          directory: {
              path: '.',
              redirectToSlash: true,
              index: true
          }
      }
  });
  app.address = function() {
    return { port: port };
  };

  app.register(swaggerHapi.plugin, function(err) {
    if (err) { return console.error('Failed to load plugin:', err); }
    app.start(function() {
      if (swaggerHapi.runner.swagger.paths['/hello']) {
        console.log('try this:\ncurl http://127.0.0.1:' + port + '/hello?name=Scott');
      }
    });
  });
});
