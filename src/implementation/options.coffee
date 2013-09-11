module.exports = [
  { name: 'source',  desc: "Directory to use as starting point for the upload" }
  { name: 'bucket',  desc: "S3 bucket used as target for the upload" }
  { name: 'key',     desc: "AWS access key" }
  { name: 'secret',  desc: "AWS access secret" }
  { name: 'region',  desc: "AWS region to create the bucket in (defaults to 'us-east-1')" }
  { name: 'index',   desc: "File to use as index page (defaults to 'index.html')" }
  { name: 'error',   desc: "File to use as error page" }
  { name: 'dns',     desc: "The name of a bucketful plugin for configuring a CNAME" }
  { name: 'configs', desc: "Configuration files (defaults to 'package.json;config.json')" }
]
