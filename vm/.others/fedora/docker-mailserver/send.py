import smtplib
from email.message import EmailMessage

msg = EmailMessage()
msg["From"] = "localinbox@example.com"
msg["To"] = "localinbox@example.com"
msg["Subject"] = "Test from Python"
msg.set_content("Hello! This email was sent to my self-hosted mail server.")

with smtplib.SMTP("localhost", 2525) as smtp:
    smtp.send_message(msg)

print("Email sent")