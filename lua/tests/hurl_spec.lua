
local testdata = {
  'HTTP/2 200',
  'date: Wed, 18 Jan 2023 09:08:10 GMT',
  'content-type: application/json; charset=utf-8',
  'content-length: 1030',
  'x-powered-by: Express',
  'access-control-allow-origin: *',
  'etag: W/"406-ut0vzoCuidvyMf8arZpMpJ6ZRDw"',
  'via: 1.1 vegur',
  'cache-control: max-age=14400',
  'cf-cache-status: HIT',
  'age: 62',
  'accept-ranges: bytes',
  'report-to: {"endpoints":[{"url":"https:\\/\\/a.nel.cloudflare.com\\/report\\/v3?s=ilmnPfm0ZOpfBw3rIclYQK3HUYqUcawAcTveG%2FAz77Q7x1Pj8LTczOZ3f7kXgClrfS8GN9MObAPONqXkDKce%2Fi%2FBX%2BDjUIANbvOy0hQQV%2Ff%2F42T2ikJtjvxqaw%3D%3D"}],"group":"cf-nel","max_age":604800}',
  'nel: {"success_fraction":0,"report_to":"cf-nel","max_age":604800}',
  'cf-ray: 78b62f3f1d116a48-SYD',
  '',
  '{"page":2,"per_page":6,"total":12,"total_pages":2,"data":[{"id":7,"email":"michael.lawson@reqres.in","first_name":"Michael","last_name":"Lawson","avatar":"https://reqres.in/img/faces/7-image.jpg"},{"id":8,"email":"lindsay.ferguson@reqres.in","first_name":"Lindsay","last_name":"Ferguson","avatar":"https://reqres.in/img/faces/8-image.jpg"},{"id":9,"email":"tobias.funke@reqres.in","first_name":"Tobias","last_name":"Funke","avatar":"https://reqres.in/img/faces/9-image.jpg"},{"id":10,"email":"byron.fields@reqres.in","first_name":"Byron","last_name":"Fields","avatar":"https://reqres.in/img/faces/10-image.jpg"},{"id":11,"email":"george.edwards@reqres.in","first_name":"George","last_name":"Edwards","avatar":"https://reqres.in/img/faces/11-image.jpg"},{"id":12,"email":"rachel.howell@reqres.in","first_name":"Rachel","last_name":"Howell","avatar":"https://reqres.in/img/faces/12-image.jpg"}],"support":{"url":"https://reqres.in/#support-heading","text":"To keep ReqRes free, contributions towards server costs are appreciated!"}}',
}
local eq = assert.are.same

describe("hurl Wrapper:", function()

  vim.cmd([[packadd web-tools.nvim]])
  require('web-tools').setup{}

  local hurl = require "web-tools.hurl".request
  on_output = require('web-tools.hurl').on_output
  describe("on_output", function() -----------------------------------------------
    it("can handle respponse", function()
      local response = on_output(200, testdata, "stdout")
      eq(200, response.status)
    end)
  end)
  describe("request", function() -----------------------------------------------
    it("sends request", function()
      eq(nil, hurl({'get.http'}))
    end)
  end)
end
)
