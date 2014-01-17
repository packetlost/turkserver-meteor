# Server admin code

Meteor.publish "tsAdmin", ->
  return unless @userId and Meteor.users.findOne(@userId).admin

  # Publish all admin data
  return [
    Batches.find(),
    Treatments.find(),
    Experiments.find(),
    # Grouping.find(),
    Assignments.find(),
    Workers.find(),
    LobbyStatus.find()
  ]

# Admin users - needs to update if group updates
Meteor.publish "tsAdminUsers", (groupId) ->
  return unless @userId and Meteor.users.findOne(@userId).admin

  return Meteor.users.find {},
    # {"status.online": true},
    fields:
      status: 1
      turkserver: 1
      workerId: 1

# Publish admin role for users that have it
Meteor.publish null, ->
  return unless @userId
  return Meteor.users.find @userId,
    fields: {admin: 1}

Meteor.methods
  "ts-admin-join-group": (groupId) ->
    throw new Meteor.Error(403, "Not logged in as admin") unless Meteor.user()?.admin
    TurkServer.Groups.setUserGroup Meteor.userId(), groupId

  "ts-admin-leave-group": ->
    throw new Meteor.Error(403, "Not logged in as admin") unless Meteor.user()?.admin
    TurkServer.Groups.clearUserGroup Meteor.userId()

# Create and set up admin user (and password) if not existent
Meteor.startup ->
  adminPw = TurkServer.config?.adminPassword
  unless adminPw?
    Meteor._debug "No admin password found for Turkserver. Please configure it in your settings."
    return

  adminUser = Meteor.users.findOne(username: "admin")
  unless adminUser
    Accounts.createUser
      username: "admin"
      password: adminPw
    Meteor._debug "Created Turkserver admin user from Meteor.settings."

    Meteor.users.update {username: "admin"},
      $set: {admin: true}
  else
    # Make sure password matches that of settings file
    Accounts.setPassword(adminUser._id, adminPw)