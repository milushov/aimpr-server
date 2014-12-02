cheerio     = require('cheerio')
express     = require('express')
request     = require('request')
app         = express()
crossdomain = require('crossdomain')
#xml         = crossdomain(domain: '*')

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

app.get '*', (req, res) ->
  res.json(error: 'not enough params')

#app.all '/crossdomain.xml', (req, res, next) ->
  #res.set 'Content-Type', "application/xml; charset=utf-8"
  #res.send xml, 200

app.listen app.get('port'), ->
  console.log "Node app is running at localhost: #{app.get('port')}"