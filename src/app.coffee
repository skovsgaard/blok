# Module imports here
express = require 'express'
http = require 'http'
path = require 'path'
level = require 'level'

# Connect to the leveldb data store
postPath = path.join __dirname, '..', '/data/posts'
postDB = level postPath, {
  valueEncoding: 'json'
  keyEncoding: 'json'
}, (err, db) ->
  if err
    console.error "Something terrible happened when connecting to the database: #{throw err}"

app = express()
server = app.listen(process.env.PORT or 3000)

app.set 'views', path.join(__dirname, '..', '/views')
app.set 'view engine', 'ejs'
app.use express.favicon()
app.use express.logger('dev')
app.use express.json()
app.use express.urlencoded()
app.use express.cookieParser()
app.use express.session {secret: 'totallyasecret'}
app.use app.router
app.use express.static(path.join(__dirname, '..', '/public'))

# Development setting
if app.get 'env' is 'development'
  app.use express.errorHandler()

# Route and render the base path
app.get '/', (req, res) ->
  res.render 'index', {title: 'Welcome to blok!'}

# GET the login page
app.get '/login', (req, res) ->
  res.render 'login', {
    title: 'Please log in'
    msg: ''
  }

# POST for the mock login
app.post '/login', (req, res) ->
  if req.body.email is 'abcd@efg.hi' and req.body.pass is '#thistotallyworks'
    req.session.auth = true
    res.redirect '/admin'
  else
    req.session.auth = false
    res.render 'login', {
      title: 'Please log in.'
      msg: 'Incorrect email or password.'
    }

# Route and render the admin interface
app.get '/admin', (req, res) ->
  if req.session.auth
    res.render 'admin', {title: 'the admin', msg: ''}
  else
    res.redirect '/login'

# Make a new post from within the admin
app.post '/admin', (req, res) ->
  if req.body.postTitle
    key = {
      title: req.body.postTitle
      time: Date.now()
    }
  else
    key = {
      title: 'no title'
      time: Date.now()
    }

  if req.body.postBody
    val = {text: req.body.postBody}
  else
    val = {text:''}

  postDB.put key, val, (err) ->
    if err
      console.log err
      res.render 'admin', {
        title: 'the admin'
        msg: "Post failed!: #{err}"
      }

    io.sockets.emit 'feedUpdate', {key: key, val: val}

    res.render 'admin', {
      title: 'the admin'
      msg: 'Post successful!'
    }

io = require('socket.io').listen(server)

console.log "Express is listening on port #{process.env.PORT or 3000}"

# Define the event listeners for websocket stuff
io.on 'connection', (socket) ->
  postDB.createReadStream()
    .on 'data', (data) ->
      socket.emit 'baseFeed', data
    .on 'error', (err) ->
      socket.emit 'feedError', err
      console.log err

  socket.on 'deletePost', (data) ->
    delObj = {
      title: data.postTitle
      time: data.postId
    }
    console.log "Deleting where key is #{JSON.stringify(delObj, null, '  ')}"

    postDB.del delObj, (err) ->
      if err
        console.log "Something went wrong when deleting: #{err}"
      console.log 'Post successfully deleted!'

    io.sockets.emit 'postDelete', {
      key: delObj
    }

  socket.on 'updatePost', (data) ->
    updateObj = {
      title: data.postTitle
      time: data.postId
    }

    updateContent = {
      text: data.postContent
    }
    console.log "Updating post where key is #{JSON.stringify(updateObj, null, '  ')}
                 with #{JSON.stringify(updateContent, null, '  ')}"

    postDB.put updateObj, updateContent, (err) ->
      if err
        console.log "Something went wrong when update: #{err}"
      console.log 'POst successfully update.'

    io.sockets.emit 'postUpdate', {
      key: updateObj
      val: updateContent
    }

# Make sure the database is closed when the application is shut down to avoid
# weird LevelDB locks, and if there's an error, write that out.
process.on 'exit', (code) ->
  console.log "Node process exiting with code: #{code}"

  postDB.close (err) ->
    if err
      return console.error "Something went wrong: #{err}"
    console.log 'Closing LevelDB, posts'
