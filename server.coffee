cheerio = require('cheerio')
express = require('express')
request = require('request')
app     = express()
google  = require('google')
each    = require('async-each')
array   = require('array-extended')
fs      = require('fs')
https   = require('https')

app.set('port', (process.env.PORT || 2053))
is_dev = process.env.PWD is '/Users/roma/work/aimpr-server'
console.info('is dev?', is_dev)

https_app = https.createServer(
  key:  fs.readFileSync(if is_dev then 'key.pem' else 'ssl.key')
  cert: fs.readFileSync(if is_dev then 'cert.pem' else 'ssl.crt')
  passphrase: if is_dev then 'aimpr' else 'aimpraimpr'
, app)

sites = {
  'pesenok':     '.status_select'
  'megalyrics':  '.text_inner'
  'songspro':    '.status_select'
  'webkind':     '#text'
  're-minor':   '.accords2 pre'
  'oldielyrics': '#song .lyrics'
  'metrolyrics': '#lyrics-body-text'
  'musixmatch':  '#lyrics-html'
  'azlyrics':    '#main>div:nth-of-type(3)'
  'genius':      '.lyrics>p'
}

app.get '/search/:q', (req, res) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "X-Requested-With"

  prms = req.params
  start_time = +new Date

  google.resultsPerPage = 10

  google prms.q, (err, next, links) ->

    return res.json(error: err.message) if err
    return res.json(error: "sorry, there is no lyrics for: '#{prms.q}'") unless links

    result = response: { items: {}, vk: false }
    match_count = 0

    # todo get uniq by domain
    urls = array(links.map (l) -> l.link).unique().value()
    urls = urls.map (url) ->
      url_obj = { url: url, site: null }
      for site, _ of sites
        url_obj.site = site if new RegExp(site).test(url)
      url_obj
    urls = urls.filter (url) -> url.site?
    result.response.count = urls.length

    return res.json(error: "sorry, there is no lyrics for: '#{prms.q}'") unless urls.length

    processed_urls = 0

    each urls, (obj) ->
      request obj.url, (error, response, body) ->
        $ = cheerio.load(body)
        result.response.items[obj.site] = $(sites[obj.site]).text().trim()
        processed_urls += 1
        result.response.time = +new Date - start_time
        res.json(result) if processed_urls is urls.length


app.get '*', (req, res) ->
  res.json(error: 'not enough params')

https_app.listen app.get('port'), ->
  console.log "Node app is running at localhost: #{app.get('port')}"
