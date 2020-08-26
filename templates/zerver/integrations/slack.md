Mirror a Slack channel in Zulip!

### Install the bridge software

1. Clone the Zulip API repository, and install its dependencies.

    ```
    git clone https://github.com/zulip/python-zulip-api.git
    cd python-zulip-api
    python3 ./tools/provision
    ```

    This will create a new Python virtualenv. You'll run the bridge service
    inside this virtualenv.

1. Activate the virtualenv by running the `source` command printed
   at the end of the output of the previous step.

1. Go to the directory containing the bridge script if you haven't already done so
   ```
   cd zulip/integrations/bridge_with_slack
   ```

1. Install the bridge dependencies in your virtualenv, by running:
    ```
    pip install -r requirements.txt
    ```

### Configure the bridge

1. In Zulip, [create a bot](/help/add-a-bot-or-integration), using **Generic bot**
   for the bot type. Download the bot's `zuliprc` configuration file to your
   computer.

1. [Subscribe the bot](/help/add-or-remove-users-from-a-stream) to the Zulip
   stream that will contain the mirror.

1. Make sure Websocket isn't blocked in the computer where you run this bridge.
   Test it at https://www.websocket.org/echo.html.

1. Go to https://api.slack.com/apps?new_classic_app=1 and create a new classic
   app (note: must be a classic app). Choose a bot name that will be put into
   bridge_with_slack_config.py, e.g. "zulip_mirror". Make sure to install the
   app to the workspace. When successful, you should see a token that starts
   with "xoxb-..." (there is also a token that starts with "xoxp-..."; we need
   the "xoxb-..." one).

1. Subscribe the Slack bot to the relevant channel. You can do this by typing
   e.g. `/invite @zulip_mirror` in the relevant channel.

1. Fill up `bridge_with_slack_config.py` with the relevant information

1. Run the following command to start the Slack bridge:

    ```
    ./run-slack-bridge
    ```
