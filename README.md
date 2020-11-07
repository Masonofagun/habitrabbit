# G-mail API (because I'm a corporate shill)
Get your [credentials.json](https://developers.google.com/gmail/api/quickstart/python)
```bash
pip3 install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

run `quickstart.py` to authenticate with google. If you want to change your permissions, e.g. read mail, delete token.pickle on the server, change your SCOPE and re-run.

run `send.py arbitrary to subject msg` to send a message from `masonunvagun@gmail.com`.
# Make sure system is setup
```bash
sudo apt-get install python3-dev
```

# Install other dependencies
```bash
pip3 install prefect pandas pytx pendulum numpy fire
```
