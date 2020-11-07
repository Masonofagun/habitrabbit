from datetime import datetime

from apiclient import errors
from apiclient.discovery import build
from base64 import urlsafe_b64encode
from email.mime.text import MIMEText
from httplib2 import Http
from google.auth.transport.requests import Request

# from oauth2client import file, client, tools
import json
import fire
import pickle
import pandas as pd
import pytz
import numpy as np
import pendulum

# from bs4 import BeautifulSoup
from prefect.schedules import Schedule
from prefect.schedules.clocks import CronClock
from prefect import task, Flow, Parameter

# https://developers.google.com/gmail/api/guides/sending
def create_message(sender, to, subject, message_text, is_html=False):
    """Create a message for an email.
    Args:
      sender: Email address of the sender.
      to: Email address of the receiver.
      subject: The subject of the email message.
      message_text: The text of the email message.
    Returns:
      An object containing a base64url encoded email object.
    """
    if is_html:
        message = MIMEText(message_text, "html")
    else:
        message = MIMEText(message_text)

    message["to"] = to
    message["from"] = sender
    message["subject"] = subject
    encoded_message = urlsafe_b64encode(message.as_bytes())
    return {"raw": encoded_message.decode()}


# https://developers.google.com/gmail/api/guides/sending
def send_message(service, user_id, message):
    """Send an email message.
    Args:
      service: Authorized Gmail API service instance.
      user_id: User's email address. The special value "me"
      can be used to indicate the authenticated user.
      message: Message to be sent.
    Returns:
      Sent Message.
    """
    message = service.users().messages().send(userId=user_id, body=message).execute()
    print("Message Id: %s" % message["id"])
    return message


def make_service():
    SCOPE = "https://www.googleapis.com/auth/gmail.compose"  # Allows sending only, not reading

    # Initialize the object for the Gmail API
    # https://developers.google.com/gmail/api/quickstart/python
    with open("token.pickle", "rb") as token:
        creds = pickle.load(token)
    # If there are no (valid) credentials available, let the user log in.
    if not creds.valid:
        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            # Save the credentials for the next run
            with open("token.pickle", "wb") as token:
                pickle.dump(creds, token)
        else:
            raise ValueError("Credential not valid!")
    service = build("gmail", "v1", credentials=creds)
    return service


def chronstr_from_row(row):
    time = row["time_to_send_local"]
    time = datetime.strptime(time, "%I:%M %p")
    # tz = pytz.timezone(f'America/{row["time_zone_city"]}')
    # today = tz.localize(datetime.today())
    # time = time.replace(day=today.day, year=today.year, month=today.month)
    # time = tz.localize(time)
    # time = time.astimezone(pytz.utc)
    # map_to_days = {
    # 'sunday': 'SUN', }
    days = [
        "sunday",
        "monday",
        "tuesday",
        "wednesday",
        "thursday",
        "friday",
        "saturday",
    ]
    days = ",".join(
        d[:3].upper()
        for d in days
        if not np.isnan(float(row[d])) and float(row[d]) != 0
    )
    # days = ",".join(
    #     # str(i + 1)

    #     for i, v in enumerate(
    #         row[d]
    #         for d in [
    #             "sunday",
    #             "monday",
    #             "tuesday",
    #             "wednesday",
    #             "thursday",
    #             "friday",
    #             "saturday",
    #         ]
    #     )
    #     if not np.isnan(float(v)) and float(v) != 0
    # )
    # cronstr = f'{time.second} {time.minute} {time.hour} ? * {days} *'
    cronstr = f"{time.minute} {time.hour} * * {days}"
    print(cronstr)
    return cronstr


def end_of_day_form(to, form_link):
    subject = f"What Did You Do Today?"
    # form_link = df.iloc[0]['form_link']

    # soup = BeautifulSoup(iframe.replace("\\\\\"", '"'), 'html.parser')
    # iframe ='\n'.join(soup.prettify().split('\n')[1:-2])

    # msg = f'<div>{iframe}</div>'
    #     msg = f'''
    # <!DOCTYPE html>
    # <html>
    # <head>
    #    <meta http-equiv="Content-Type" content="text/html charset=UTF-8" />
    # </head>
    # <body>

    # </body>
    # </html>
    # '''

    msg = f"Go to {form_link} to log your habits."

    raw_msg = create_message("donotreply", to, subject, msg)
    send_message(make_service(), "me", raw_msg)


@task
def prefect_send_email(schedule_df, row_index):
    assert row_index is not None
    row = schedule_df.iloc[row_index]
    end_of_day_form(
        row.email, row.form_link,
    )


row_index = Parameter("row_index", default=None, required=True)


def on_schedule(path_to_schedule):
    schedule_df = pd.read_csv(path_to_schedule)

    clocks = [
        CronClock(
            cron_str,
            parameter_defaults={"row_index": i},
            start_date=pendulum.now(f"America/{city}"),
        )
        for i, (cron_str, city) in enumerate(
            zip(
                map(lambda x: chronstr_from_row(x[1]), schedule_df.iterrows()),
                schedule_df.time_zone_city,
            )
        )
    ]
    schedule = Schedule(clocks=clocks)
    with Flow("Send Habit Reminders", schedule) as flow:
        prefect_send_email(schedule_df, row_index)

    flow.run(parameters={'row_index': None})


if __name__ == "__main__":
    fire.Fire()
