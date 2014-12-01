cheerio = require('cheerio')
express = require('express')
request = require('request')
app     = express()

app.set('port', (process.env.PORT || 5000))

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

app.get '*', (req, res) ->
  res.json(error: 'not enough params')

app.listen app.get('port'), ->
  console.log "Node app is running at localhost: #{app.get('port')}"