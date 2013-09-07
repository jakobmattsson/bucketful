should = require 'should'
jscov = require 'jscov'
loopia = require jscov.cover('..', 'src', 'bucketful-loopia')

describe 'Loopia', ->

  describe 'domainToParts', ->

    it 'parses domain-only .se domains', ->
      loopia.domainToParts('google.se').should.eql { domain: 'google.se', subdomain: null }

    it 'parses domain-only .com domains', ->
      loopia.domainToParts('google.com').should.eql { domain: 'google.com', subdomain: null }

    it 'parses domain-only .co.uk domains', ->
      loopia.domainToParts('google.co.uk').should.eql { domain: 'google.co.uk', subdomain: null }

    it 'parses .se domains with a single level subdomain', ->
      loopia.domainToParts('analytics.google.se').should.eql { domain: 'google.se', subdomain: 'analytics' }

    it 'parses .com domains with a single level subdomain', ->
      loopia.domainToParts('analytics.google.com').should.eql { domain: 'google.com', subdomain: 'analytics' }

    it 'parses .co.uk domains with a single level subdomain', ->
      loopia.domainToParts('analytics.google.co.uk').should.eql { domain: 'google.co.uk', subdomain: 'analytics' }

    it 'parses .se domains with a several levels deep subdomain', ->
      loopia.domainToParts('foo.bar.analytics.google.se').should.eql { domain: 'google.se', subdomain: 'foo.bar.analytics' }

    it 'parses .com domains with a several levels deep subdomain', ->
      loopia.domainToParts('foo.bar.analytics.google.com').should.eql { domain: 'google.com', subdomain: 'foo.bar.analytics' }

    it 'parses .co.uk domains with a several levels deep subdomain', ->
      loopia.domainToParts('foo.bar.analytics.google.co.uk').should.eql { domain: 'google.co.uk', subdomain: 'foo.bar.analytics' }

    it 'fails for .se top-domain only', ->
      should.not.exist loopia.domainToParts('se')

    it 'fails for .com top-domain only', ->
      should.not.exist loopia.domainToParts('com')

    it 'fails for .co.uk top-domain only', ->
      should.not.exist loopia.domainToParts('co.uk')

    it 'fails for null and empty string', ->
      should.not.exist loopia.domainToParts('')
      should.not.exist loopia.domainToParts(null)
      should.not.exist loopia.domainToParts()

    it 'fails if it starts with a dot', ->
      should.not.exist loopia.domainToParts('.se')
      should.not.exist loopia.domainToParts('.co.uk')
      should.not.exist loopia.domainToParts('.google.se')
      should.not.exist loopia.domainToParts('.google.co.uk')
      should.not.exist loopia.domainToParts('.analytics.google.se')
      should.not.exist loopia.domainToParts('.analytics.google.co.uk')

    it 'fails if it contains with a whitespace character', ->
      should.not.exist loopia.domainToParts(' se')
      should.not.exist loopia.domainToParts('co.uk ')
      should.not.exist loopia.domainToParts('goo gle.se')
      should.not.exist loopia.domainToParts('''google.
      co.uk''')
      should.not.exist loopia.domainToParts('analytics  .google.se')
      should.not.exist loopia.domainToParts('analytics.google.co. uk')
