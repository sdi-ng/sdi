How to create your self-signed SSL certificate
==============================================

Run the following commands:

  $ openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
  $ openssl rsa -passin pass:x -in server.pass.key -out server.key
  $ rm server.pass.key
  $ openssl req -new -key server.key -out server.csr
  $ openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

Refer to this URL https://devcenter.heroku.com/articles/ssl-certificate-self to
read more.
