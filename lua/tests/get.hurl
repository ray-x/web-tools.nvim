# Get home:
GET https://example.org

HTTP/2 200
[Captures]
csrf_token: xpath "string(//meta[@name='_csrf_token']/@content)"
