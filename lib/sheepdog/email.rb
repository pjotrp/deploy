#

require 'net/smtp'

message = <<MESSAGE_END
From: Private Person <me@fromdomain.com>
To: A Test User <test@todomain.com>
Subject: SMTP e-mail test

This is a test e-mail message.
MESSAGE_END

def send_mail(email_to, msg)
  print("Sending...")
  Net::SMTP.start('localhost',25,tls_verify: false, helo: 'mail.from.domain') do |smtp|
    smtp.send_message msg, 'noreply@localhost', email_to
  end
end
