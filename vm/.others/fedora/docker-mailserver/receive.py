import imaplib
mail = imaplib.IMAP4("localhost", 1433)
# mail.starttls()

mail.login(
    "localinbox@example.com",
    "supersecretpassword",
)

mail.select("INBOX")

status, messages = mail.search(None, "ALL")

for num in messages[0].split():
    status, data = mail.fetch(num, "(RFC822)")
    print(data[0][1].decode(errors="replace"))

mail.logout()