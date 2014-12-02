cheerio = require('cheerio')
express = require('express')
request = require('request')
app     = express()
google  = require('google')
each    = require('async-each')
array   = require('array-extended')

app.set('port', (process.env.PORT || 5000))

app.use (req, res, next) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "X-Requested-With"
  next()

sites = {
  #https://www.musixmatch.com/lyrics/Eminem/Rap-God
  musixmatch: 'https://www.musixmatch.com/lyrics/'
}

app.get '/:sitename/:artist/:title', (req, res) ->
  prms = req.params

  if prms.sitename is 'musixmatch'
    url = sites[prms.sitename] + [prms.artist, prms.title].join('/')

  request url, (error, response, body) ->
    $ = cheerio.load(body)
    text = $('#lyrics-html').text()
    res.json(response: text)

sites = {
  'oldielyrics': '#song .lyrics'
  'metrolyrics': '#lyrics-body-text'
}

app.get '/search/:q', (req, res) ->
  prms = req.params

  google.resultsPerPage = 10

  google prms.q, (err, next, links) ->
    resp = {}
    match_count = 0
    # todo get uniq by domain
    urls = array(links.map (l) -> l.link).unique().value()

    each urls, (url) ->
      for site_name, query of sites
        if new RegExp(site_name).test(url)
          match_count += 1
          console.log("finded #{url}")

          request url, (error, response, body) ->
            match_count -= 1
            $ = cheerio.load(body)
            resp[site_name] = $(sites[site_name]).text()
            console.log("get content for #{url}", resp[site_name])
            res.json(response: resp) if match_count is 0 # time > 3 seconds

    , (error, contents) ->
      console.log(error, contents)


app.get '*', (req, res) ->
  res.json(error: 'not enough params')

app.listen app.get('port'), ->
  console.log "Node app is running at localhost: #{app.get('port')}"