
yaml = require 'js-yaml'
fs = require 'fs'
crypto = require 'crypto'
os = require 'os'
async = require 'async'
dot = require 'graphlib-dot'
Viz = require 'viz.js'

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
	traeme 'followers/ids.json', {screen_name: req.swagger.params.user.value}, (error, jsres, response)->
		if error?
			console.log "Error de Twitter", error
		else
			if jsres?.ids?
				res.json jsres.ids
			else
				# no tiene followers ??
				res.json []
			
		
friends = (req,res)->
	traeme 'friends/ids.json', {screen_name: req.swagger.params.user.value}, (error, jsres, response)->
		if error?
			console.log "Error de Twitter", error
		else
			if jsres?.ids?
				res.json jsres.ids
			else
				# no tiene followers ??
				res.json []
friendsbyuserid = (userid,callback)->
	traeme 'friends/ids.json', {user_id: userid}, (error, jsres, response)->
		if error?
			console.log "Error de Twitter", error
		else
			if jsres?.ids?
				callback jsres.ids
			else
				# no tiene followers ??
				callback []
commonfriends = (req,res)->
	userids = [req.swagger.params.user1.value,req.swagger.params.user2.value]
	console.log "commonfriends of", userids
	async.mapSeries userids,(item,callback)->
		if item?
			friends {swagger :{params : {user : {value:item}}}}, {
				json: (data)->
					console.log "#{item}->",data.length
					callback null,data
			}
		else
			console.log "item invalido, #{item}"
			callback null,[]
	,(err,results)->
		comunes = results[0].filter (e)->
			return results[1].indexOf(e) isnt -1
		retval = {
			user1followers: results[0]
			user2followers: results[1]
			commonfollowers: comunes
		}
		res.json retval

CommonFriendsGraph = (req,res)->
	commonfriends req, {
			json: (data)->
				console.log "Buscando los friends de las coincidencias ... "
				data.commonfollowers = data.commonfollowers[0..5]
				async.mapSeries data.commonfollowers, (item,callback)->
					friendsbyuserid item, (data)->
						console.log "#{item}->",data.length
						callback null,data
				,(err,results)->
					retval = ""
					retval += "#{userid};" for userid, ix in data.commonfollowers
					for userid1, ix1 in data.commonfollowers
						for userid2, ix2 in data.commonfollowers
							if userid1 isnt userid2 and results[ix2].indexOf (userid) isnt -1
								retval += "#{userid1} -> #{userid2}\n"
					digraph = dot.read("digraph { #{retval} }")
					ascii = dot.write digraph
					svg = Viz ascii,{format:"svg", engine:"dot", scale:2}
					res.json {message:svg}
		}
module.exports = {
	followers: followers
	friends: friends
	commonfriends: commonfriends
	CommonFriendsGraph : CommonFriendsGraph
}