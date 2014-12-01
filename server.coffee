cheerio = require('cheerio')
express = require('express')
request = require('request')
app     = express()
is_prod = process.env.NODE_ENV == 'production'
port    = if is_prod then 80 else 3000

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

app.listen port