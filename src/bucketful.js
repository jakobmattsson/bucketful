var opra = require('opra');
var powerfs = require('powerfs');
var knox = require('knox');
var async = require('async');
var wrench = require('wrench');
var _ = require('underscore');
var nconf = require('nconf');
var _s = require('underscore.string');
var path = require('path');

exports.deploy = function(options) {
  nconf.overrides(options).argv();
  nconf.file('config', 'config.json');
  nconf.file('package', 'package.json');
  nconf.file('user', path.join(process.env.HOME, '.bucketful'));
  nconf.env().defaults({
    bucketful: {
      targetDir: path.join(process.cwd(), 'public'),
      include: [],
      exclude: [],
      opra: { inline: true }
    }
  });

  var s3bucket = nconf.get('bucketful:bucket');
  var aws_key = nconf.get('bucketful:key');
  var aws_secret = nconf.get('bucketful:secret');
  var excludes = nconf.get('bucketful:exclude');
  var includes = nconf.get('bucketful:include');
  var opraOptions = nconf.get('bucketful:opra');
  var targetDir = path.resolve(nconf.get('bucketful:targetDir'));

  console.log('Resolved targetDir', targetDir);
  console.log('Loaded the following options', nconf.get('bucketful'));

  var client = knox.createClient({
    key: aws_key,
    secret: aws_secret,
    bucket: s3bucket,
    endpoint: s3bucket + '.s3-external-3.amazonaws.com'
  });

  var errHandler = function(f) {
    return function(err) {
      if (err) {
        console.log("FAIL:", err);
        return;
      }
      return f.apply(null, Array.prototype.slice.call(arguments, 1));
    };
  }

  console.log("Compiling opra")
  opra.build('public/index.html', opraOptions, errHandler(function(data) {
    powerfs.writeFile('tmp/index.html', data, 'utf8', errHandler(function() {
      console.log("Uploading index.html")
      client.putFile('tmp/index.html', '/index.html', errHandler(function(res) {

        var files = [];

        if (includes.length > 0) {
          includes.forEach(function(file) {
            var fullpath = path.join(targetDir, file);
            if (powerfs.isDirectorySync(fullpath)) {
              files = files.concat(wrench.readdirSyncRecursive(fullpath).map(function(f) {
                return path.join(file, f);
              }));
            } else {
              files.push(file);
            }
          });
        } else {
          files = wrench.readdirSyncRecursive(targetDir);
        }

        files = files.filter(function(file) {
          return excludes.every(function(x) {
            return file != x && !_s.startsWith(file, x + '/');
          });
        });

        var counter = 0;
        console.log("Uploading the rest (" + files.length + " files)");

        async.forEach(files, function(file, callback) {
          powerfs.isFile(path.join(targetDir, file), function(err, isFile) {
            if (err) {
              callback(err)
            } else if (!isFile) {
              callback();
            } else {
              client.putFile(path.join(targetDir, file), '/' + file, function() {
                counter++;
                console.log("[" + counter + "/" + files.length + "] " + file);
                callback.apply(this, arguments);
              });
            }
          });
        }, errHandler(function() {
          console.log("Done");
        }));
      }));
    }));
  }));
};
