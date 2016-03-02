Package.describe({
  name: "publish-with-relations",
  summary: "Publish associated collections at once.",
  version: "0.2.1"
});

Package.on_use(function(api) {
  api.versionsFrom("METEOR@0.9.0");
  api.use(['coffeescript', 'underscore'], 'server');
  api.add_files('publish_with_relations.coffee', 'server');
});

Package.on_test(function(api) {
  api.use([
    'tinytest',
    'coffeescript',
    'underscore',
    'npvn:publish-with-relations',
    'mongo-livedata'], 'server');

  api.add_files('publish_with_relations_test.coffee', 'server');
});
