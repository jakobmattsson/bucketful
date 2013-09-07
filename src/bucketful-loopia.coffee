Q = require 'q'
_ = require 'underscore'
loopia = require 'loopia-api'



exports.namespace = 'loopia'

exports.domainToParts = domainToParts = (domain) ->
  return null if !domain? || domain.match(/\s/) || domain[0] == '.'
  splitted = domain.split('.')
  return null unless splitted.length > 1

  part1 = if splitted.slice(-1)[0] == 'uk' then splitted.slice(-3) else splitted.slice(-2)
  part2 = if splitted.slice(-1)[0] == 'uk' then splitted.slice(0, -3) else splitted.slice(0, -2)

  return null if part1.join('.') == 'co.uk'

  domain: part1.join('.')
  subdomain: if part2.length == 0 then null else part2.join('.')

exports.create = (username, password) ->
  loopiaClient = loopia.createClient(username, password)

  setCNAME: (bucket, cname, callback) ->

    fulldomain = bucket
    client = loopiaClient

    {domain, subdomain} = domainToParts(fulldomain)

    Q.nfcall(client.getSubdomains, domain)
    .then (subdomains) ->
      hasSubdomain = subdomains.some (s) -> s == subdomain
      Q.nfcall(client.addSubdomain, domain, subdomain) if !hasSubdomain
    .then ->
      Q.nfcall(client.getZoneRecords, domain, subdomain)
    .then (zoneRecords) ->
      cnames = zoneRecords.filter (z) -> z.type == 'CNAME'
      if cnames.length == 0
        Q.nfcall(client.addZoneRecord, domain, subdomain, {
          type: 'CNAME'
          ttl: 3600
          priority: 0
          rdata: cname + "."
        })
      else if cnames.length == 1
        Q.nfcall(client.updateZoneRecord, domain, subdomain, _.extend({}, cnames[0], { rdata: cname }))
      else
        throw "several cnames found; don't know which one to update: " + cnames.map (x) -> x.rdata
    .then ->
      callback()
    , (err) ->
      callback(err)
