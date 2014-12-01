// Generated by CoffeeScript 1.8.0
(function() {
  var app, cheerio, express, request, sites;

  cheerio = require('cheerio');

  express = require('express');

  request = require('request');

  app = express();

  sites = {
    musixmatch: 'https://www.musixmatch.com/lyrics/'
  };

  app.get('/:sitename/:artist/:title', function(req, res) {
    var prms, url;
    prms = req.params;
    if (prms.sitename === 'musixmatch') {
      url = sites[prms.sitename] + [prms.artist, prms.title].join('/');
    }
    return request(url, function(error, response, body) {
      var $, text;
      $ = cheerio.load(body);
      text = $('#lyrics-html').text();
      return res.json({
        response: text
      });
    });
  });

  app.get('*', function(req, res) {
    return res.json({
      error: 'not enough params'
    });
  });

  app.listen(3000);

}).call(this);
