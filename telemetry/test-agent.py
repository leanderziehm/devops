import subprocess
import time
import json
import requests
import os

API_URL = os.getenv("EVENT_API_URL", "https://homelab.apis.leanderziehm.com")
NOTIFY_URL = "https://notify.leanderziehm.com/notify/me"
POLL_INTERVAL = 0.6

pc_name = subprocess.check_output(["hostname"]).decode().strip()

def parse_who():
    result = subprocess.run(["who"], capture_output=True, text=True)

    sessions = []

    for line in result.stdout.splitlines():
        parts = line.split()

        if len(parts) >= 4:
            sessions.append(
                {
                    "user": parts[0],
                    "terminal": parts[1],
                    "date": parts[2],
                    "time": parts[3],
                    "host": parts[4] if len(parts) >= 5 else None,
                }
            )

    return sessions

def send_event(event):
    requests.post(API_URL, json=event, timeout=5)


def send_notification(text):
    try:
        requests.post(
            NOTIFY_URL,
            headers={
                "accept": "application/json",
                "Content-Type": "application/json",
            },
            json={"text": text},
            timeout=5,
        )
    except requests.RequestException as e:
        print("Notification failed:", e)

def compare(old, new):
    old_set = {json.dumps(x, sort_keys=True) for x in old}
    new_set = {json.dumps(x, sort_keys=True) for x in new}
    return {
        "login": [json.loads(x) for x in new_set - old_set],
        "logout": [json.loads(x) for x in old_set - new_set],
    }

def format_notification(event):
    changes = event["payload"]

    lines = []

    if changes["login"]:
        lines.append("👤 Login:")
        for session in changes["login"]:
            host = f" from {session['host']}" if session.get("host") else ""
            lines.append(
                f"• {session['user']} on {session['terminal']} "
                f"{session['date']} {session['time']}{host}"
            )
        lines.append("")

    if changes["logout"]:
        lines.append("🚪 Logout:")
        for session in changes["logout"]:
            host = f" from {session['host']}" if session.get("host") else ""
            lines.append(
                f"• {session['user']} on {session['terminal']} "
                f"{session['date']} {session['time']}{host}"
            )

    end = [ "",
        f"💻 PC: {pc_name}"]
    lines.extend(end)

    return "\n".join(lines)


def main():
    previous = parse_who()
    while True:
        time.sleep(POLL_INTERVAL)
        current = parse_who()
        # print("current:",current)
        changes = compare(previous, current)
        # print("changes:",changes)

        
        if changes["login"] or changes["logout"]:
            
          
            event = {
                "text": f"source:{pc_name}",
                "category": "security",
                "name": "user_session_change",
                "payload": changes,
            }
            # Save in backend DB
            send_event(event)
            # Push notification
            send_notification(format_notification(event))
        previous = current


if __name__ == "__main__":
    main()
