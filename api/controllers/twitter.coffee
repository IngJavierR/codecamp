
yaml = require 'js-yaml'
fs = require 'fs'
crypto = require 'crypto'
os = require 'os'
config = yaml.safeLoad fs.readFileSync "#{__dirname}/../../config/runtime.yaml", 'utf8'

Twitter = require 'twitter'
client = new Twitter (config.twitter)

traeme = (urltwitter, params, cb)->
	hash = crypto.createHash('md5').update(JSON.stringify({urltwitter:urltwitter, params:params})).digest('hex')
	tmppath = "#{os.tmpdir()}/#{hash}.json"
	console.log "Buscando cache en #{tmppath}"
	fs.stat tmppath, (err, stats)->
		console.log "No lo encontre en cache, llendo a twitter"
		if err?
			client.get urltwitter, params, (err3, tweets, response)->
				console.log "Creando cache en #{tmppath}"
				fs.writeFile tmppath, JSON.stringify({err:err3,tweets:tweets,response:response}), (err4)->
					if err4?
						console.log "Error al intentar escribir el cache !!!"
						cb {}
					else
						cb err3, tweets, response

		else
			console.log "Encontre el archivo !!!", stats
			fs.readFile tmppath, (err2, data)->
				if err2?
					cb {}
				else
					data = JSON.parse(data)
					cb data.error, data.tweets, data.response

followers = (req,res)->
	traeme 'followers/ids.json', {stringify_ids: req.swagger.params.user.value}, (error, jsres, response)->
		if error?
			console.log "Error de Twitter", error
		else
			if jsres?.ids?
				res.json jsres.ids
			else
				# no tiene followers ??
				res.json []
			
		
friends = (req,res)->
	traeme 'friends/ids.json', {stringify_ids: req.swagger.params.user.value}, (error, jsres, response)->
		if error?
			console.log "Error de Twitter", error
		else
			if jsres?.ids?
				res.json jsres.ids
			else
				# no tiene followers ??
				res.json []
commonfriends = (req,res)->
	res.json {
		user1followers: 0
		user2followers: 0
		commonfollowers:0
	}
module.exports = {
	followers: followers
	friends: friends
	commonfriends: commonfriends
}