alias ircd.invite { 
  if ($isop($2,$client($sockname).nick)) { 
    if (!$_nick($2,$1)) {
      if ($getnick($1)) {
        chans $2 inviteList $addtok($chans($2).inviteList,$1,32)
        sockwrite -n $getnick($1) : $+ $client($sockname).gethost INVITE $1 : $+ $2
      }
    }
    else { 
      sendraw $sockname 443 $1 $2 :is already on channel
    }
  }
  else { 
    sendraw $sockname 482 $2 :You are not a channel operator
  }
}
alias ircd.helpop { 









}

alias getwho { 
  var %sock = $getnick($1)
  noop $regex($client(%sock).getHost,/^([^!]+)!([^@]+)@(\S+)/)
  var %chan = $iif($2,$2,$gettok($client(%sock).chans,1,32))
  sockwrite -n $sockname : $+ $_server 352 $1 $iif(%chan,%chan,*) $regml(2) $regml(3) $_server $1 * : $+ $client(%sock).realName
}

alias ircd.who { 

  if ($getnick($1)) { 
    getwho $1

    sendraw $sockname 315 $1 :End of /Who
  }
  else { 
    if ($ischan($1)) { 
      var %nick = $client($sockname).nick
      if ($_nick($1,%nick)) {
        var %i = 1
        while ($_nick($1,%i)) { 
          getwho $v1 $1
          inc %i
        }
        sendraw $sockname 315 $1 :End of /Who
      }
    }
  }
}

alias ircd.whois { 

  if ($getnick($1)) { 
    var %sock = $v1
    ;away?
    ;screw helpful crap.
    sendraw $sockname 311 $1 $client(%sock).username $iif($client(%sock).vhost,$v1,$client(%sock).host) * : $+ $client(%sock).realname
    sendraw $sockname 319 $1 : $+ $client(%sock).chans
    sendraw $sockname 312 $1 $_server :--mSL IRCd
    if ($isoper(%sock)) { 
      sendraw $sockname 313 $1 :is an IRC Operator
    }
    sendraw $sockname 317 $1 0 $client(%sock).ctime :seconds idle, signon time


  }
  else { 
    sendraw $sockname 401 $1 :No such nick/channel
  }
  sendraw $sockname 318 :End Of /Whois
}

alias do./names {
  if ($ischan($2)) { 
    var %i = 1
    var %names
    while ($_nick($2,%i)) { 
      var %n = $v1
      var %mode = $gettok($sorttok($regsubex($_nick($2,%n).mode,/(.)/g,$mid($gettok($_supported_prefix,2,32),$pos($gettok($_supported_prefix,1,32),\1),1) $chr(32)),32,c),1,32)
      var %n = %mode $+ %n
      if ($calc($len(%names) + $len(%n)) > 510) {
        sockwrite -n $1 : $+ $_server 353 $client($1).nick = $2 : $+ %names
        var %names
      }

      %names = %names %n
      inc %i
    }
    if (%names) { 
      sockwrite -n $1 : $+ $_server 353 $client($1).nick = $2 : $+ %names
    }
    sendraw $1 366 * :End of /NAMES 
  }
}

alias ircd.names { 
  do./names $sockname $1-
}

alias ircd.nick { 
  var %nick = $remove($1,:)
  if (%nick != $client($sockname).nick) {
    if ($getnick(%nick) || $istok($juped_nicks,%nick,32)) { 
      sockwrite -n $sockname 433 * %nick Nickname is already in use
      return
    }
  }
  else {
    if (%nick === $client($sockname).nick) {
      ; echo -s no go
      return
    }
  }
  if (!$regex(%nick,/^(?(?=\d)[^\d])[\w\\\d\[\]\{\}`\-\|]+$/) || $len(%nick) > 30 || $client($sockname).nickChange > 3) {
    ; ; echo -s $client($sockname).nickChange
    hinc -u10 clients $+($sockname,.,nickChange)
    if ($client($sockname).nickChange == 5) { 
      godsend NOTICE $client($sockname).nick :You are changing your nick too much, please stop
    }
    if ($client($sockname).nickChange == 7) { 
      godsend kill $client($sockname).nick :I said fucking stop
      return
    }

    sendraw $sockname 432 %nick :Erroneus nickname
    return
  }
  renameNick $client($sockname).nick %nick
}
alias ircd.userhost { 

  sendraw $sockname 302 : $+ $iif($getnick($1),$1 $+ =+ $+ $gettok($client($v1).gethost,2,$asc(!)))
}
alias ircd.kick { 
  if ($ischan($1)) { 
    if ($isop($1,$client($sockname).nick)) { 

      if (S isincs $client($getnick($2)).mode) { 
        sendraw $sockname 484 $1 :Cannot kill, kick or deop services or system admin
        return 
      }

      var %nick = $client($getnick($2)).nick
      if ($_nick($1,%nick)) {
        tochan $1 : $+ $client($sockname).gethost KICK $1 %nick : $+ $gettext($3-)
        removeFromChan $1 %nick
      }
      else { 
        sendraw $sockname 401 $2 :No such nick
      }
    }
    else { 
      sendraw $sockname 482 $1 :You are not a channel operator
    }
  }
}

alias ircd.privmsg { 
  var %j = 1
  var %___txt = $gettext($2-)
  var %chans = $1
  while ($gettok(%chans,%j,44)) { 
    tokenize 32 $v1 %___txt
    var %nick = $client($sockname).nick
    if ($ischan($1)) { 
      ;    404 qb2 #no Cannot send to channel
      if (!$_nick($1,%nick) && n isincs $chans($1).mode) { 
        ;no external messages
        return
      }
      if (($isbanned($client($sockname).gethost,$1) || m isincs $chans($1).mode || $isbanned(~t: $+ $strip($2-),$1) || $regtextban($2-,$1)) && !$_nick($1,%nick).mode) { 
        sendraw $sockname 404 $1 :Cannot Send to Channel
        return
      }

      if ($chr(3) isin $2- && c isincs $chans($1).mode) { 
        sendraw $sockname 408 $1 :You cannot use colors on this channel.
        return
      }
      if ($2 == !test) {
        var %n = $ticks
        echo -s %n
      }
      tochan $client($sockname).nick $1 : $+ $client($sockname).gethost PRIVMSG $1 : $+ $iif(S isincs $chans($1).mode,$strip($2-,c),$2-)
      if (%n) { godsend notice $client($sockname).nick : $+ $calc(($ticks - %n) / 1000) }
    }
    elseif ($getnick($1)) {
      ;493 - user does not want pm (+m)
      ;494 you have +m, cannot send pm
      ;adapted from webchat.org (i found this really useful.
      ;
      if (m isincs $client($sockname).mode) { 
        sendraw $sockname 494 $client($sockname).nick :You own modes prohibit you from sending that type of message
        return
      }
      if (m isincs $client($getnick($1)).mode) { 
        sendraw $sockname 493 $1 :User does not wish to recieve that type of message
        return
      }
      sockwrite -n $getnick($1) : $+ $client($sockname).gethost PRIVMSG $1 : $+ $2-
    }
    inc %j
  }
}
alias ircd.umode { 
  ircd.mode $client($sockname).nick $1-
}


alias ircd.part { 
  if (B isincs $chans($1).mode) { 
    sockwrite -n $sockname : $+ $client($sockname).gethost JOIN $1
    do./names $sockname $1
    return
  }

  removeFromChan $1 $client($sockname).nick
  tochan $1 : $+ $client($sockname).gethost PART $1
  sockwrite -n $sockname : $+ $client($sockname).gethost PART $1

}
alias ircd.join { 
  var %i = 1
  var %chans = $1
  if (B isincs $client($sockname).mode) { 
    godsend notice $client($sockname).nick :You may not join any channels, you have been banished
    return
  }

  while ($gettok(%chans,%i,44) != $null) {

    tokenize 32 $gettok(%chans,%i,44) $1
    if (!$nickison($1,$client($sockname).nick)) {
      if ($ischan($1)) { 
        if (!$istok($chans($1).inviteList,$client($sockname).nick,32)) {
          if (i isincs $chans($1).mode) { 
            ;473 fleshTH #uno.test :Cannot join channel (+i)
            sendraw $sockname 473 $1 :Cannot join chanel (+i)
            return
          }
          if ($isbanned($client($sockname).gethost,$1)) { 
            ;474 fleshTH #uno.test :Cannot join channel (+b)
            sendraw $sockname 474 $1 :Cannot join channel (+b)
            return
          }
        }
        else {
          chans $1 inviteList $remtok($chans($1).inviteList,$client($sockname).nick,1,32)
        }
        if (!$_nick($1,0)) {
          var %op = 1
        }
        ; ; echo -a $hfind(chans,$+(*,$client($sockname).nick,*),1,w) - 
        channick $1 $client($sockname).nick $sockname
        if (!$_nick($1,god)) {
          togod : $+ $client($sockname).gethost JOIN : $+ $1
        }
        tochan $1 : $+ $client($sockname).gethost JOIN : $+ $1
        if (!$_nick($1,$client($sockname).nick)) { 
          sockwrite -n $sockname : $+ $client($sockname).gethost JOIN : $+ $1
        }
        sendraw $sockname 332 $1 : $+ $chans($1,topic)
        ;324 fleshTH #uno.test +i
        sendraw $sockname 324 $1 : $+ $chans($1,mode)
        do./names $sockname $1
        if (%op) { 
          ; godsend MODE $1 +o $client($sockname).nick
        }
      }
      else { 
        sockwrite -n $sockname 403 $client($sockname).nick $1 No such channel
      }
    }
    inc %i
  }
}


alias ircd.quit { 
  removeUser $sockname quit : $+ $1-
}

alias ircd.notice { 

  if ($ischan($1)) { 
    tochan $1 : $+ $client($sockname).gethost NOTICE $1 $2-
  }
  else {
    sockwrite -n $getnick($1) : $+ $client($sockname).gethost NOTICE $1 $2-
  }
}

alias ircd.topic { 
  if ($ischan($1)) {
    if (!$2) { 
    }
    else {
      if (t isin $chan($1).topic && !$isop($1,$client($sockname).nick)) { return }
      tochan $1 : $+ $client($sockname).gethost TOPIC $1 : $+ $gettok($2-,1,58)
      chans $1 topic $gettok($2-,1,58)
      writeini chans.ini $1 topic $2-
    }
  }
}

alias ircd.pong { 
  if ($remove($1,:) == $_server) { 
    clientadd $sockname pinged 0
  }
}
alias ircd.list { 
  ; ; ; echo -s BLAH
  var %s = $gettext($1)
  if (!%s) %s = *
  var %i = 1

  sendraw $sockname 321 Channel :Users Name
  while ($hfind(chans,%s $+ .created,%i,w)) { 
    var %chan = $gettok($v1,1,46)
    ; ; ; echo -s %chan
    sendraw $sockname 322 %chan $_nick(%chan,0) : $+ $chan(%chan).topic
    inc %i
  }
  sendraw $sockname 323 :End of /LIST
}

alias ircd.vHost { 
  if (r !isincs $client($sockname).mode) { 
    godsend notice $client($sockname).nick :You must have a registered nick to use vHost
    return
  }
  if (!$client($sockname).vhost) { 
    if ($regex($1-,/^[\w-\.]+$/)) { 
      clientadd $sockname vhost $1-
      writeini users.ini $client($sockname).nick vhost $1-
      godsend notice $client($sockname).nick :Your vHost has been set to  $+ $1- $+ 

    }
    else { 
      godsend notice $client($sockname).nick :You have invalid characters in your vHost. Only a-z 0-9 - _ and . are allowed.
      return
    }
  }
  else { 
    godsend notice $client($sockname).nick :You already have a vHost. You may only set a vHost 1 time each time you connect. If you made a typo, Please ask a IRC operator to remove the vhost so that you can reset it.
  }
}



alias ircd.lusers { 
  var %sock = $iif($sockname,$v1,$1)
  sendraw %sock 251 :There are $getusercount users and 0 invisible on 1 server
  sendraw %sock 252 :1 operator(s) online
  sendraw %sock 254 : $+ $getchancount channels formed
}
alias ircd.motd { 
  var %sock = $iif($sockname,$v1,$1)
  sendraw %sock 375  :- $+ $_network Message of the day
  file_sock motd.txt %sock : $+ $_server 372 $client(%sock).nick :-
}
