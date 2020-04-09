# BEGIN SETUP
:local scheduleName "checkLogs"
:local emailAddress "user@domain.com"
:local startBuf [:toarray [/log find message~"logged in" || message~"login failure"]]
:local removeThese {"telnet"}
# END SETUP

# warn if schedule does not exist
:if ([:len [/system scheduler find name="$scheduleName"]] = 0) do={
  /log warning "[LOGMON] ERROR: Schedule does not exist. Create schedule and edit script to match name"
}

# Router name
:local location [/system identity get name]
# get last time
:local lastTime [/system scheduler get [find name="$scheduleName"] comment]
# for checking time of each log entry
:local currentTime
# log message
:local message
# final output
:local output
:local keepOutput false

# if lastTime is empty, set keepOutput to true
:if ([:len $lastTime] = 0) do={
  :set keepOutput true
}

:local counter 0
# loop through all log entries that have been found
:foreach i in=$startBuf do={

# loop through all removeThese array items
  :local keepLog true
  :foreach j in=$removeThese do={
#   if this log entry contains any of them, it will be ignored
    :if ([/log get $i message] ~ "$j") do={
      :set keepLog false
    }
  }
  :if ($keepLog = true) do={
   :set message [/log get $i message]
#   LOG DATE
#   depending on log date/time, the format may be different. 3 known formats
#   format of jan/01/2002 00:00:00 which shows up at unknown date/time. Using as default
    :set currentTime [ /log get $i time ]
#   format of 00:00:00 which shows up on current day's logs
   :if ([:len $currentTime] = 8 ) do={
     :set currentTime ([:pick [/system clock get date] 0 11]." ".$currentTime)
    } else={
#     format of jan/01 00:00:00 which shows up on previous day's logs
     :if ([:len $currentTime] = 15 ) do={
        :set currentTime ([:pick $currentTime 0 6]."/".[:pick [/system clock get date] 7 11]." ".[:pick $currentTime 7 15])
      }
   }

#   if keepOutput is true, add this log entry to output
   :if ($keepOutput = true) do={
     :set output ($output.$currentTime." ".$message."\r\n")
   }
#   if currentTime = lastTime, set keepOutput so any further logs found will be added to output
#   reset output in the case we have multiple identical date/time entries in a row as the last matching logs
#   otherwise, it would stop at the first found matching log, thus all following logs would be output
    :if ($currentTime = $lastTime) do={
     :set keepOutput true
     :set output ""
   }
  }

#   if this is last log entry
  :if ($counter = ([:len $startBuf]-1)) do={
#   If keepOutput is still false after loop, this means lastTime has a value, but a matching currentTime was never found.
#   This can happen if 1) The router was rebooted and matching logs stored in memory were wiped, or 2) An item is added
#   to the removeThese array that then ignores the last log that determined the lastTime variable.
#   This resets the comment to nothing. The next run will be like the first time, and you will get all matching logs
   :if ($keepOutput = false) do={
#     if previous log was found, this will be our new lastTime entry
     :if ([:len $message] > 0) do={
        :set output ($output.$currentTime." ".$message."\r\n")
      }
    }
  }
  :set counter ($counter + 1)
}

# If we have output, save new date/time, and send email
if ([:len $output] > 0) do={
  /system scheduler set [find name="$scheduleName"] comment=$currentTime
  /tool e-mail send to="$emailAddress" subject="$location alert $currentTime" body="$output"
  /log info "[LOGMON] New logs found, send email"
}
