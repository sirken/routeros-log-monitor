# RouterOS Log Monitor

MikroTik RouterOS script to monitor the logs for specific terms and send email alerts. The original idea was to detect logins to the router and receive notifications.

* Tested on v5.26, v6.20, v6.46.4
* Older versions found [here](http://forum.mikrotik.com/viewtopic.php?f=2&t=60616) and [here](https://wiki.mikrotik.com/wiki/Monitor_logs,_send_email_alert_/_run_script)

## Features

* Check logs at the interval you specify in the schedule
* Search for multiple terms or phrases
* Filter out terms you don't want
* Return all matching log entries since the last trigger

## Prerequisites

* Email settings must be enabled and configured on the router.

## Setup

1. Create a new schedule, and paste the script into the schedule. Set the duration to how often you want to check for new logs.
2. Change the `scheduleName` variable to match your schedule name. This is important because the schedule stores the last date/time stamp trigger.
3. Change the `emailAddress` to your target email.
4. Change the `startBuf` array to use the terms & phrases you want to search for. Remove `|| message~"login failure"` if you only want to search for one item, or add more of these to search for additional terms.
5. Change the `removeThese` array to include any terms you want filtered out of the found results. Add additional items separated by semi-colons: `{"telnet";"whatever string you want"}`, or if you don't want any logs filtered, simply declare the variable `:local removeThese` without any curly braces.

    ```routeros
    :local scheduleName "checkLogs"
    :local emailAddress "user@domain.com"
    :local startBuf [:toarray [/log find message~"logged in" || message~"login failure"]]
    :local removeThese {"telnet"}
    ```

## Other Notes

* If you would rather run a script or whatever (instead of sending email), simply remove the email config line at the top, and change the "/tool email" line near the bottom to do whatever you want.
