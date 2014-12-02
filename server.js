// Generated by CoffeeScript 1.8.0
(function() {
  var app, array, cheerio, each, express, google, request, sites;

  cheerio = require('cheerio');

  express = require('express');

  request = require('request');

  app = express();

  google = require('google');

  each = require('async-each');

  array = require('array-extended');

  app.set('port', process.env.PORT || 5000);

  sites = {
    'oldielyrics': '#song .lyrics',
    'metrolyrics': '#lyrics-body-text',
    'musixmatch': '#lyrics-html',
    'azlyrics': '#main>div:nth-of-type(3)',
    'genius': '.lyrics>p'
  };

  app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "X-Requested-With");
    return next();
  });

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

  app.get('/search/:q', function(req, res) {
    var prms;
    prms = req.params;
    google.resultsPerPage = 10;
    return google("lyrics " + prms.q, function(err, next, links) {
      var match_count, processed_urls, resp, urls;
      resp = {};
      match_count = 0;
      urls = array(links.map(function(l) {
        return l.link;
      })).unique().value();
      urls = urls.map(function(url) {
        var site, url_obj, _;
        url_obj = {
          url: url,
          site: null
        };
        for (site in sites) {
          _ = sites[site];
          if (new RegExp(site).test(url)) {
            url_obj.site = site;
          }
        }
        return url_obj;
      });
      urls = urls.filter(function(url) {
        return url.site != null;
      });
      processed_urls = 0;
      return each(urls, function(obj) {
        return request(obj.url, function(error, response, body) {
          var $;
          $ = cheerio.load(body);
          resp[obj.site] = $(sites[obj.site]).text();
          console.log("get content for " + obj.url, resp[obj.site]);
          processed_urls += 1;
          if (processed_urls === urls.length) {
            return res.json({
              response: resp
            });
          }
        });
      }, function(error, contents) {
        return console.log(error, contents);
      });
    });
  });

  app.get('*', function(req, res) {
    return res.json({
      error: 'not enough params'
    });
  });

  app.listen(app.get('port'), function() {
    return console.log("Node app is running at localhost: " + (app.get('port')));
  });

}).call(this);
