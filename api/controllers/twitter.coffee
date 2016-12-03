

followers = (req,res)->
	console.log req.swagger.params.user.value
	res.json []
friends = (req,res)->
	console.log req.swagger.params.user.value
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