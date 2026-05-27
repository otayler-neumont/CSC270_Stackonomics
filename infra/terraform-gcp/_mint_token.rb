require 'json'
require 'openssl'
require 'base64'
require 'net/http'
require 'uri'

key_path, scope = ARGV
key = JSON.parse(File.read(key_path))
now = Time.now.to_i

header  = { alg: 'RS256', typ: 'JWT' }.to_json
payload = {
  iss:   key['client_email'],
  scope: scope,
  aud:   'https://oauth2.googleapis.com/token',
  iat:   now,
  exp:   now + 3600
}.to_json

b64 = ->(s) { Base64.urlsafe_encode64(s, padding: false) }
signing_input = "#{b64.call(header)}.#{b64.call(payload)}"

rsa = OpenSSL::PKey::RSA.new(key['private_key'])
sig = rsa.sign('SHA256', signing_input)
jwt = "#{signing_input}.#{b64.call(sig)}"

uri = URI('https://oauth2.googleapis.com/token')
res = Net::HTTP.post_form(uri,
  'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
  'assertion'  => jwt)

unless res.is_a?(Net::HTTPSuccess)
  warn "token exchange failed: #{res.code} #{res.body}"
  exit 1
end

puts JSON.parse(res.body)['access_token']
