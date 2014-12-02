cheerio = require('cheerio')
express = require('express')
request = require('request')
app     = express()
google  = require('google')
each    = require('async-each')
array   = require('array-extended')

app.set('port', (process.env.PORT || 5000))

sites = {
  'oldielyrics': '#song .lyrics'
  'metrolyrics': '#lyrics-body-text'
}


app.use (req, res, next) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "X-Requested-With"
  next()


app.get '/:sitename/:artist/:title', (req, res) ->
  prms = req.params

  if prms.sitename is 'musixmatch'
    url = sites[prms.sitename] + [prms.artist, prms.title].join('/')

  request url, (error, response, body) ->
    $ = cheerio.load(body)
    text = $('#lyrics-html').text()
    res.json(response: text)


app.get '/search/:q', (req, res) ->
  prms = req.params

  google.resultsPerPage = 10

  google prms.q, (err, next, links) ->
    resp = {}
    match_count = 0
    # todo get uniq by domain
    urls = array(links.map (l) -> l.link).unique().value()
    urls = urls.map (url) ->
      url_obj = { url: url, site: null }
      for site, _ of sites
        url_obj.site = site if new RegExp(site).test(url)
      url_obj
    urls = urls.filter (url) -> url.site?

    processed_urls = 0

    each urls, (obj) ->
      request obj.url, (error, response, body) ->
        $ = cheerio.load(body)
        resp[obj.site] = $(sites[obj.site]).text()
        console.log("get content for #{obj.url}", resp[obj.site])
        processed_urls += 1
        res.json(response: resp) if processed_urls is urls.length

    , (error, contents) ->
      console.log(error, contents)


app.get '*', (req, res) ->
  res.json(error: 'not enough params')


app.listen app.get('port'), ->
  console.log "Node app is running at localhost: #{app.get('port')}"