
# a 'publication' that just records stuff
class PubMock
  constructor: () ->
    @activities = []
  
  added: (name, id) ->
    @activities.push {type: 'added', collection: name, id: id}
  
  changed: (name, id) ->
    @activities.push {type: 'changed', collection: name, id: id}
  
  removed: (name, id) ->
    @activities.push {type: 'removed', collection: name, id: id}
  
  ready: ->
    @activities.push {type: 'ready'}
  
  onStop: (cb) ->
    @_onStop = cb
  
  stop: () ->
    @_onStop() if @_onStop

prepare = (run) ->
  data = {}
  
  data.Boards = new Meteor.Collection "boards_#{run}"
  data.Lists = new Meteor.Collection "lists_#{run}"
  data.Tasks = new Meteor.Collection "tasks_#{run}"
  
  # insert some data
  boardId = data.Boards.insert name: 'board'
  listId = data.Lists.insert name: 'list', boardId: boardId
  taskId = data.Tasks.insert name: 'task', listId: listId
  
  data.settings = 
    collection: data.Boards
    filter: {}
    
    mappings: [{
      collection: data.Lists
      key: 'boardId'
      reverse: true
      
      mappings: [{
        collection: data.Tasks
        key: 'listId'
        reverse: true
      }]
    }]
  
  data

Meteor.publish 'data', (runId) ->
  console.log 'subscribing to data'
  data = prepare(runId)
  Meteor.publishWithRelations _.extend(data.settings, {handle: this})

Meteor.methods
  openLiveResultSets: (runId) ->
    # find the lrs that corresponds to this connection
    lrses = MongoInternals.defaultRemoteCollectionDriver().mongo._observeMultiplexers
    console.log MongoInternals.defaultRemoteCollectionDriver().mongo
    console.log lrses
    
    ours = (lrs for lrs in lrses when lrs._cursorDescription.collectionName.match(runId))
    console.log(ours)
    
    return ours.length
  

Tinytest.add "Publish with Relations - ready is only called once", (test) ->
  data = prepare(test.runId())
  
  pub = new PubMock
  Meteor.publishWithRelations _.extend(data.settings, {handle: pub})
  
  readys = (activity for activity in pub.activities when activity.type == 'ready')
  test.equal readys.length, 1

Tinytest.add "Publish with Relations - Nested subscriptions stop", (test) ->
  data = prepare(test.runId())
  
  pub = new PubMock
  Meteor.publishWithRelations _.extend(data.settings, {handle: pub})
  
  count = pub.activities.length
  
  # stop the sub, but then insert some more stuff
  pub.stop()
  boardId = data.Boards.insert name: 'new board'
  listId = data.Lists.insert name: 'new list', boardId: boardId
  taskId = data.Tasks.insert name: 'new task', listId: listId
  
  # nothing new has happened
  test.equal pub.activities.length, count