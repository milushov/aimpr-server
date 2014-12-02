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
  'musixmatch':  '#lyrics-html'
  'azlyrics':    '#main>div:nth-of-type(3)'
  'genius':      '.lyrics>p'
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
  start_time = +new Date

  google.resultsPerPage = 10

  google "lyrics #{prms.q}", (err, next, links) ->
    resp = response: {}
    match_count = 0
    # todo get uniq by domain
    urls = array(links.map (l) -> l.link).unique().value()
    urls = urls.map (url) ->
      url_obj = { url: url, site: null }
      for site, _ of sites
        url_obj.site = site if new RegExp(site).test(url)
      url_obj
    urls = urls.filter (url) -> url.site?
    resp.count = urls.length

    unless urls.length
      res.json(error: "sorry, there is no lyrics for: '#{prms.q}'")

    processed_urls = 0

    each urls, (obj) ->
      request obj.url, (error, response, body) ->
        $ = cheerio.load(body)
        resp.response[obj.site] = $(sites[obj.site]).text()
        processed_urls += 1
        resp.time = +new Date - start_time
        res.json(resp) if processed_urls is urls.length || resp.time >= 3000

    , (error, contents) ->
      console.log(error, contents)


app.get '*', (req, res) ->
  res.json(error: 'not enough params')


app.listen app.get('port'), ->
  console.log "Node app is running at localhost: #{app.get('port')}"