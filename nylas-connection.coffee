_ = require 'underscore'
clone = require 'clone'
request = require 'request'
Promise = require 'bluebird'
RestfulModel = require './models/restful-model'
RestfulModelCollection = require './models/restful-model-collection'
RestfulModelInstance = require './models/restful-model-instance'
Account = require './models/account'
ManagementAccount = require './models/management-account'
ManagementModelCollection = require './models/management-model-collection'
Thread = require './models/thread'
Contact = require './models/contact'
Message = require './models/message'
Draft = require './models/draft'
File = require './models/file'
Calendar = require './models/calendar'
Event = require './models/event'
Tag = require './models/tag'
Delta = require './models/delta'
Label = require('./models/folder').Label
Folder = require('./models/folder').Folder

Attributes = require './models/attributes'


module.exports =
class NylasConnection

  constructor: (@accessToken) ->
    @threads = new RestfulModelCollection(Thread, @)
    @contacts = new RestfulModelCollection(Contact, @)
    @messages = new RestfulModelCollection(Message, @)
    @drafts = new RestfulModelCollection(Draft, @)
    @files = new RestfulModelCollection(File, @)
    @calendars = new RestfulModelCollection(Calendar, @)
    @events = new RestfulModelCollection(Event, @)
    @tags = new RestfulModelCollection(Tag, @)
    @deltas = new Delta(@)
    @labels = new RestfulModelCollection(Label, @)
    @folders = new RestfulModelCollection(Folder, @)
    @account = new RestfulModelInstance(Account, @)

  requestOptions: (options={}) ->
    options = clone(options)
    Nylas = require './nylas'
    options.method ?= 'GET'
    options.url ?= "#{Nylas.apiServer}#{options.path}" if options.path
    options.body ?= {} unless options.formData
    options.json ?= true
    options.downloadRequest ?= false

    user = if options.path.substr(0,3) == '/a/' then Nylas.appSecret else @accessToken

    if user
      options.auth =
        'user': user
        'pass': '',
        'sendImmediately': true
    return options

  request: (options={}) ->
    options = @requestOptions(options)

    new Promise (resolve, reject) ->
      request options, (error, response, body) ->
        try
          body = JSON.parse(body) if _.isString body
        catch e
          error = e unless error

        if error or response.statusCode > 299
          unless error
            if _.isString(body.message)
              error = new Error(body.message)
            else
              error = new Error(JSON.stringify(body.message))
          error.code = body.type if body.type
          error.server_error = body.server_error if body.server_error
          logOnError(error, response, body)
          reject(error)
        else
          if options.downloadRequest
            return resolve(response)
          else
            resolve(body)

logOnError = (error, response, body) ->
  console.log('nylas-connection#request error: ', error.toString())

  if error.code?
    console.log('nylas-connection#request error.code: ', error.code)

  if error.stack
    console.log('nylas-connection#request stack: ', error.stack)

  if response
    console.log('nylas-connection#request response.statusCode: ', response.statusCode)
    console.log('nylas-connection#request response.statusMessage: ', response.statusMessage)

  if body
    console.log('nylas-connection#request body', body)
