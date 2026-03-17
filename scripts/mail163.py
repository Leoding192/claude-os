#!/usr/bin/env python3
"""
mail163.py — 163邮箱 IMAP/SMTP helper for claude-os

Usage:
  python3 mail163.py list [--days N]       # list recent emails (default: since yesterday)
  python3 mail163.py read <uid>            # read full email body
  python3 mail163.py send --to <addr> --subject <subj> --body <text>

Credentials read from macOS Keychain:
  service: claude-os.mail163
  accounts: MAIL_163_ADDRESS, MAIL_163_APP_PASSWORD

163 IMAP: imap.163.com:993 (SSL)
163 SMTP: smtp.163.com:465  (SSL)

Setup if "Unsafe Login" error appears:
  1. Log into mail.163.com in a browser
  2. Approve the security alert / new device confirmation
  3. Re-generate authorization code under Settings → POP3/SMTP/IMAP
  4. Run: bash ~/claude-os/install.sh --rotate-secrets
"""

import imaplib
import smtplib
import email
import subprocess
import argparse
import datetime
import sys
from email.header import decode_header
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart


def get_keychain(service, account):
    r = subprocess.run(
        ["security", "find-generic-password", "-s", service, "-a", account, "-w"],
        capture_output=True, text=True
    )
    v = r.stdout.strip()
    if not v:
        print(f"ERROR: Keychain entry not found: service={service} account={account}")
        print("Run: bash ~/claude-os/install.sh")
        sys.exit(1)
    return v


def decode_str(s):
    if not s:
        return ""
    parts = decode_header(s)
    result = []
    for part, enc in parts:
        if isinstance(part, bytes):
            result.append(part.decode(enc or "utf-8", errors="replace"))
        else:
            result.append(str(part))
    return "".join(result)


def connect_imap():
    user = get_keychain("claude-os.mail163", "MAIL_163_ADDRESS")
    pwd  = get_keychain("claude-os.mail163", "MAIL_163_APP_PASSWORD")
    try:
        mail = imaplib.IMAP4_SSL("imap.163.com", 993)
        mail.login(user, pwd)
        return mail, user
    except imaplib.IMAP4.error as e:
        msg = str(e)
        if "Unsafe Login" in msg:
            print("ERROR: 163 blocked this login as 'Unsafe'.")
            print("Fix:")
            print("  1. Open mail.163.com in a browser and approve the new-device alert")
            print("  2. Re-generate your authorization code under Settings → IMAP")
            print("  3. Run: bash ~/claude-os/install.sh --rotate-secrets")
        else:
            print(f"IMAP error: {msg}")
        sys.exit(1)


def cmd_list(days):
    mail, user = connect_imap()
    status, _ = mail.select('"INBOX"')
    if status != "OK":
        print("ERROR: Could not select INBOX")
        mail.logout()
        sys.exit(1)

    since = (datetime.date.today() - datetime.timedelta(days=days)).strftime("%d-%b-%Y")
    _, data = mail.search(None, f"SINCE {since}")
    ids = data[0].split() if data[0] else []
    print(f"163 Inbox — {len(ids)} email(s) since {since}\n")

    for uid in ids[-30:]:  # cap at 30
        _, msg_data = mail.fetch(uid, "(BODY[HEADER.FIELDS (FROM SUBJECT DATE)])")
        raw = msg_data[0][1]
        msg = email.message_from_bytes(raw)
        subject = decode_str(msg.get("Subject", "(no subject)"))
        sender  = decode_str(msg.get("From", ""))
        date    = msg.get("Date", "")[:22]
        print(f"  [{uid.decode()}] {date}")
        print(f"    From:    {sender[:70]}")
        print(f"    Subject: {subject[:80]}")
        print()

    mail.logout()


def cmd_read(uid):
    mail, _ = connect_imap()
    status, _ = mail.select('"INBOX"')
    if status != "OK":
        print("ERROR: Could not select INBOX")
        mail.logout()
        sys.exit(1)

    _, msg_data = mail.fetch(uid.encode(), "(RFC822)")
    raw = msg_data[0][1]
    msg = email.message_from_bytes(raw)

    print(f"From:    {decode_str(msg.get('From', ''))}")
    print(f"To:      {decode_str(msg.get('To', ''))}")
    print(f"Subject: {decode_str(msg.get('Subject', ''))}")
    print(f"Date:    {msg.get('Date', '')}")
    print("─" * 60)

    if msg.is_multipart():
        for part in msg.walk():
            ct = part.get_content_type()
            if ct == "text/plain":
                charset = part.get_content_charset() or "utf-8"
                print(part.get_payload(decode=True).decode(charset, errors="replace"))
                break
    else:
        charset = msg.get_content_charset() or "utf-8"
        print(msg.get_payload(decode=True).decode(charset, errors="replace"))

    mail.logout()


def cmd_send(to, subject, body, cc=None):
    user = get_keychain("claude-os.mail163", "MAIL_163_ADDRESS")
    pwd  = get_keychain("claude-os.mail163", "MAIL_163_APP_PASSWORD")

    msg = MIMEMultipart()
    msg["From"]    = user
    msg["To"]      = to
    msg["Subject"] = subject
    if cc:
        msg["Cc"] = cc
    msg.attach(MIMEText(body, "plain", "utf-8"))

    recipients = [to] + ([cc] if cc else [])

    try:
        with smtplib.SMTP_SSL("smtp.163.com", 465) as smtp:
            smtp.login(user, pwd)
            smtp.sendmail(user, recipients, msg.as_string())
        print(f"Sent to {to}")
    except smtplib.SMTPException as e:
        print(f"SMTP error: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="163邮箱 IMAP/SMTP helper")
    sub = parser.add_subparsers(dest="cmd")

    p_list = sub.add_parser("list", help="List recent emails")
    p_list.add_argument("--days", type=int, default=1, help="How many days back (default: 1)")

    p_read = sub.add_parser("read", help="Read full email body")
    p_read.add_argument("uid", help="Email UID from list output")

    p_send = sub.add_parser("send", help="Send an email")
    p_send.add_argument("--to",      required=True)
    p_send.add_argument("--subject", required=True)
    p_send.add_argument("--body",    required=True)
    p_send.add_argument("--cc",      default=None)

    args = parser.parse_args()

    if args.cmd == "list":
        cmd_list(args.days)
    elif args.cmd == "read":
        cmd_read(args.uid)
    elif args.cmd == "send":
        cmd_send(args.to, args.subject, args.body, args.cc)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
