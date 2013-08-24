;;
;
; mIRCd - fleshTH style
;
;


on *:start: echo -ag ** type /start to start the server


alias newSock { 
  var %s = $ticks
  while ($sock($+(client.,%s))) %s = $ticks
  return client. $+ %s
}

alias getUserCount { 
  return $hfind(clients,/client\.\d+\.registered$/,0,r)
}

alias getChanCount { 
  return $hfind(chans,/^#.*?\.created$/,0,r)
}

menu @users { 
  kill: {
    var %i = 1
    while ($($+($,%i),2) != $null) {
      removeUser $getnick($v1) Killed by server admin
      inc %i
    }
  }
}

/*
Thanks to Wiz126 for pointing out that nick and quit events
must be sent to each socket once, regaurdless of how many common chans they are on
that poses a bit of a problem, however, i'll fix it =P
*/
alias dst { 
  return $+(%,$1,.,$2)
}
alias sendDistinctToChans { 

  var %key = $ticks
  var %chans = $client($getnick($1)).chans
  var %i = 1
  while ($gettok(%chans,%i,32)) { 
    var %chan = $v1
    var %j = 1
    while ($_nick(%chan,%j)) { 
      var %sock = $getnick($v1)
      echo -s %sock - - $v1 $hget(global,$+(%key,.,%sock))
      if (!$hget(global,$+(%key,.,%sock))) {
        hadd global $+(%key,.,%sock) 1
        sockwrite -n %sock $2-
        :error
        .reseterror
      }
      inc %j
    }
    inc %i
  }
  hdel -w global $+(%key,*)
}


alias clientadd {
  hadd -m clients $+($1,.,$2) $3-
}

alias client { 
  if ($prop == gethost) { 
    return $+($hget(clients,$+($1,.nick)),!,$hget(clients,$+($1,.,username)),@,$iif($hget(clients,$+($1,.,vhost)),$v1,$hget(clients,$+($1,.,host))))
  }
  return $hget(clients,$+($1,.,$iif($2,$2,$prop)))
}

alias makeNick { 
  clientadd nicks $1-
  clientadd $2 nick $1
  clientadd $2 ctime $ctime

}


alias getNick { 
  return $client(nicks,$1)
}



alias renameNick { 

  var %chans = $client($getnick($1)).chans
  ; ; ; echo -a %chans

  var %i = 1
  togod : $+ $client($getnick($1)).gethost NICK : $+ $2
  sendDistinctToChans $1 : $+ $client($getnick($1)).gethost NICK : $+ $2
  while ($gettok(%chans,%i,32)) { 
    var %j = 1
    var %c = $v1
    ; ; ; echo -a chans, $+(%c,.nicks.,$1,.*) ,%j,w


    ;tochan %c : $+ $client($getnick($1)).gethost NICK : $+ $2


    while ($hfind(chans,$+(%c,.nicks.,$1,.*),%j,w)) {
      var %key = $v1
      ; ; ; echo -a %key

      var %old = $hget(chans,%key)
      var %new = $puttok(%key,$2,3,46)
      hdel chans %key
      hadd chans %new %old
      inc %j
    }
    var %c1 = $_nick(%c,$1)
    hdel chans $+(%c,.nicks.,@,$1)
    hadd chans $+(%c,.nicks.,@,$2)  %c1
    inc %i
  }

  var %old = $client(nicks,$1)
  if ($1 != $2) {
    .timer 1 2 hdel clients $+(nicks,.,$1)
  }
  clientadd %old nick $2
  clientadd nicks $2 %old
  hinc -u10 clients $+($getnick($1),.nickChange)
  rline @users $fline(@users,$1) $2
}


alias clientunset { 
  hdel -w clients $+($1,.*)
  :error
  .reseterror
}
/*
alias chanCreated { 
  return $hfind(chans,$+($1,.*),0,w)
}
*/



alias sumode {
  var %i = 1
  var %x
  while ($mid($2,%i,1)) {  

    var %c = $v1
    if (%c == + || %c = -) { 
      %x = %c
      inc %i
      continue
    }
    if (%x == +) {
      clientadd $1 mode $client($1).mode $+ %c
    } 
    else {
      clientadd $1 mode $remove($client($1).mode,%c)
    }
    inc %i
  }
  sockwrite -n $1 : $+ $_server MODE $client($1).nick : $+ $2

}

alias isoper { 
  if (o isincs $client($1).mode) { 
    return 1
  }
}


alias chans { 
  if (!$isid) { 


    hadd -m chans $+($1,.,$2) $3-
    ; echo @raw created $chanCreated($1)
    if (!$chanCreated($1)) { 
      hadd -m chans $+($1,.,created) $ctime
      hadd -m chans $+($1,.,modes) nt
    }
  }
  else {
    return $hget(chans,$+($1,.,$iif($2,$2,$prop)))
  }
}

alias chanCreated { 
  return $hget(chans,$1 $+ .created)
}


alias channick { 
  if (!$isid) { 
    if (!$_nick($1,$2)) { 

      clientadd $getnick($2) chans $addtok($client($3,chans),$1,32)
      chans $1 $+(nicks.,@ $+ $2) $3-
    }
    else { 
      chans $1 $+(nicks.,$2,.,$3) $4-
    }

  }
  else { 
    return $chans($1,$+(nicks,.,$2,$iif($prop,. $+ $v1))))
  }
}

alias chanban { 
  if ($isid) { 
    return $chans($1,$+(bans.,$2))
  }
  chans $1 $+(bans.,$2) $3-
}

alias isBanned { 

  /*

  $1 host
  $2 chan

  */

  if ($isRegExBanned($1,$2)) return 1
  var %i = 1
  while ($hfind(chans,$+($2,.bans.,*),%i,w)) { 
    var %mask = $gettok($v1,3-,46)
    if (%mask iswm $1) return 1
    inc %i
  }
}
alias regtextban { 
  var %i = 1
  while ($hfind(chans,$+($2,.bans.,~tr:*),%i,w)) { 
    var %mask = $regsubex($gettok($v1,3-,46),/^~tr:/i,)
    if ($regex($1,%mask)) return 1
    inc %i
  }

}

alias isRegExBanned { 
  var %i = 1
  while ($hfind(chans,$+($2,.bans.,~r:*),%i,w)) { 
    var %mask = $regsubex($gettok($v1,3-,46),/^~r:/i,)
    if ($regex($1,%mask)) return 1
    inc %i
  }
}


alias _nick {
  ;$1 = chan
  ;$2 = nick
  ; ; ; echo -s $1-
  if ($2 isnum) { 
    var %nick = $regsubex($hfind(chans,$+($1,.nicks.@*),$2,w),/^.*?@(.*)$/,\1)
    if (!$prop) { 
      return %nick
    }
    return $channick($1,$+(%nick,.,$prop))
  }
  else { 
    return $channick( $1 , $iif($prop,$+($2,.,$prop),$+(@,$2)) )
  }
}


alias getText { 
  return $gettok($1-,1-,58)
}
alias start { 
  socklisten mircd $_server_port
  hmake clients
  hmake chans
  hmake kline
  hload kline kline.dat
  if ($window(@users) == $null) window -l @users $calc($window(-3).w -150) 0 150 $window(-3).h
  loadgod
}

alias restart { 
  sockwrite -n * : $+ $_server NOTICE *:*** Server is restarting
  hfree clients
  hfree chans
  hfree kline
  clear @users
  sockclose *
  start
}


alias removeFromChan { 
  hdel -w chans $+($1,.nicks.,$2,.*)
  hdel chans $+($1,.nicks.@,$2)
  clientadd $getnick($2) chans $remtok($client($getnick($2)).chans,$1,1,32)
  if ($_nick($1,0) == 0) { 
    hdel -w chans $+($1,.*)
  }

}




alias ischan { 
  return $regex($1,/^#(?!\.)[\/\w\$\^#&%$@!\-\xa0]+$/)
}
alias ircd.ping { 
  sockwrite -n $sockname PONG $1-
}

alias nickison { 
  return $_nick($1,$2)
}





alias sendraw { 
  if ($sock($1)) {
    sockwrite -n $1 : $+ $_server $2 $client($1).nick $3-
  }
}



alias removeUser { 
  if (!$1) return
  var %i = 1
  var %chans = $client($1).chans
  ; echo @raw USER EXIT = %CHANS
  sendDistinctToChans $client($1).nick : $+ $client($1).gethost QUIT : $+ $2-

  dline @users $fline(@users,$client($1).nick)
  :error
  reseterror
  hdel -w clients $+(nicks.,$client($1).nick)
  hdel -w clients $+(nicks.,$client($1).nick,.*)
  hdel -w chans $+(#*.nicks.,$client($1).nick,.*)
  hdel -w chans $+(#*.nicks.,@,$client($1).nick)

  hdel -w clients $+($1,.*)
  if ($sock($1)) {
    sockclose $1
  }


}




alias tochan { 
  var %i = 1
  if (!$ischan($1)) {
    var  %nick = $1
    tokenize 32 $2-
  }
  while ($_nick($1,%i)) { 
    if ($v1 != %nick) {
      sockwrite -n $getnick($v1) $2-
      :error
      .reseterror
    }
    inc %i
  }
}


on *:socklisten:mircd: { 
  if ($hget(global,lockdown)) return
  var %sock = $newSock
  sockaccept %sock
}

alias floodControl { 
  if (o isincs $client($1).mode) return
  if (!$isid) {
    hinc -u2 clients $+($1,.,floodBytes) $2
    hinc -u2 clients $+($1,.,floodLines)
  }
  else {
    return $iif(($client($1).floodBytes > 2056) || $client($1).floodLines > 20,1,0)
  }
}


on *:sockread:client.*: { 
  if ($sockerr) { 

    removeUser $sockname $sock($sockname).wsmsg
    return
  }


  sockread %temp

  sockpause client.*
  if ($getnick(god)) sockpause -r $v1
  .timer -h 1 50 sockpause -r client.*
  floodcontrol $sockname $sockbr
  if ($floodcontrol($sockname)) {
    ;removeUser $sockname Excess Flood
  }
  if ($sock($sockname).rq > 30000) { 
    removeUser $sockname Send Queue Exceed
    return
  }

  while ($sockbr) { 
    tokenize 32 %temp
    ; ; ; echo @raw %temp
    if (!$client($sockname).registered) {
      if ($hget(kline,$sock($sockname).ip)) { 
        sockwrite -n $sockname Error: You have been k:lined reason $gettok($v1,2-,32)
        sockclose $sockname
        return
      }
      if ($1 == user || $1 == nick || $1 == pass) { 
        if ($1 == pass) {  
          if ($2 == @%$333$&&887654&&6543~!@@@@~!@!~^%$#&8&^%^&) {
            clientadd $sockname passed 1
          }
          else { 
            sockclose $sockname
          }
        }
        if ($1 == nick) { 
          if (!$regex($remove($2,:),/^(?(?=\d)[^\d])[\w\\\d\[\]\{\}`\-\|]+$/)) {
            sendraw $sockname 432 %nick :Erroneus nickname
            return
          }
          if (!$getnick($remove($2,:))) {
            if ($2 == GOD) {
              if ($sock($sockname).ip != 127.0.0.1) { 
                sockwrite -n $sockname 433 * $remove($2,:) Nickname is already in use

              }
            }
            aline @users $remove($2,:)
            makeNick $remove($2,:) $sockname
            if ($client($sockname).username) { 
              clientadd $sockname registered 1
              if ($client($sockname).nick != god) {
                ; sendStandardStartMessage $sockname
                sockwrite -n $sockname NOTICE AUTH :Resolving Your host
                timer $+ $sockname 0 $calc(60 * 3) checkping $sockname
                dns $sock($sockname).ip
              }
              else { 
                sumode $sockname +So

              }
            }
          }
          else { 
            sockwrite -n $sockname 433 * $remove($2,:) Nickname is already in use
          }
        }
        else {
          if ($numtok($2-,32) < 4) return
          clientadd $sockname username $2
          clientadd $sockname realName $gettext($5-)
          ;clientadd $sockname host $regsubex($md5($sock($sockname).ip),/(.{8})(?!$)/g,\1.)
          clientadd $sockname ip $sock($sockname).ip
          hadd -m global $sock($sockname).ip  $sockname
          if ($client($sockname).nick) { 
            clientadd $sockname registered 1
            if ($client($sockname).nick != god) {
              ;sendStandardStartMessage $sockname
              sockwrite -n $sockname NOTICE AUTH :Resolving Your host
              timer $+ $sockname 0 $calc(60 * 3) checkping $sockname
              dns $sock($sockname).ip
            }
            else { 
              sumode $sockname +So
            }
          }
        }
      }
      else { 
        if ($1 == CONNECT && HTTP isin $1-) { 
          sockclose $sockname
          return
        }
        sockwrite -n $sockname  451 $upper($1) You have not registered
      }

    }
    else { 
      ; ; echo -s $1 --- $2-
      if ($isalias($+(ircd.,$1))) { 
        $+(ircd.,$1) $2-
      }
      else { 
        sockwrite -n $sockname  421 $client($sockname).nick $upper($1) Unknown command
      }
    }
    if ($sock($sockname)) sockread %temp
  }
}
alias getSockErr {
  var %a = $1
  echo -s $1 -
  goto %a
  :10053
  return Connection reset by peer
  :%a
  return 0
}

on *:sockclose:client.*: { 
  removeUser $sockname $iif($sockerr,$iif($getSockErr($sock($sockname).wserr),$v1,$sock($sockname).wsmsg),Quit: Client Exited)
}




alias checkping { 
  ; ; ; echo @raw checking ping for $1 => $client($1).nick
  if ($sock($1)) { 
    if ($client($1).pinged) {
      ; ; ; echo @raw  ping timed out for $1 => $client($1).nick
      removeUser $1 Ping Timeout
      return
    }
    ; ; ; echo @raw  ping OK for $1 => $client($1).nick
    clientadd $1 pinged 1
    sockwrite -n $1 PING : $+ $_server
  }
  else { 
    ; ; ; echo @raw  ping Socket not open for $1 => $client($1).nick
    timer $+ $1 off
    removeUser $1 Unknown Error
  }


}




alias sendStandardStartMessage { 

  sendraw $1 001 :Welcome to the Internet Relay Network %nick
  sendraw $1 002 :Your host is $_server $+ , running version AtavistIRCd 0.0.01 on mIRC $version
  sendraw $1 003 :This server is being creating right now. so $!date = $date
  sendraw $1 004 : $+ $_server 0.0.01 rSomB Bbmirtnov
  sendraw $1 005 PREFIX= $+ $regsubex($_supported_prefix,/([^\s]+)\s,( $+ \1 $+ )   )  MAXCHANNELS=10  are supported by this server
  sendraw $1 005 NICKLEN=30 TOPICLEN=160 AWAYLEN=160 KICKLEN=160  CHANTYPES=# MAXBANS=45 CHANMODES=b,k,l,rimnpst CASEMAPPING=rfc1459 NETWORK= $+ $_network are supported by this server
  ircd.lusers $1
  ircd.motd $1
  togod : $+ $client($1).gethost NICK : $+ $client($1).nick
  if ($client($1).nick != GOD) {
    var %nick = $v1
    if (i !isincs $chans(#ircdtest).mode) {
      godsend fjoin %nick #ircdtest
    }
  }
}



on *:dns: {

  var %sock = $hget(global,$dns(0).ip)
  hdel global $dns(0).ip
  if ($sock(%sock)) { 
    clientadd %sock host $puttok($iif($dns(0).addr,$v1,$regsubex($md5($sock(%sock).ip),/(.{8})(?!$)/g,\1.)),$_network,1,46)
    clientadd %sock realhost $iif($dns(0).addr,$v1,$sock(%sock).ip)
    if (!$client(%sock).host) {
      return
    }
    sockwrite -n %sock NOTICE AUTH : $+ $iif($dns(0).addr,Resolved host $v1,Could not resolve host - using IP: $sock(%sock).ip))
    sendstandardStartMessage %sock
  }
  else { 
    removeUser %sock -
  }
}


raw *:*: { 
  ; ; ; echo @raw $numeric $1-

}



dialog hash_table {
  title "hash manager"
  size -1 -1 164 106
  option dbu
  list 1, 1 16 61 53, hsbar vsbar
  list 2, 65 16 94 54, hsbar vsbar sort
  box "hash tables", 4, 0 9 63 62
  box "item value", 5, 1 71 163 23
  box "table items", 6, 65 8 97 63
  edit "", 3, 2 79 162 10, autohs
  button "ok", 7, 124 96 37 9
}


on *:dialog:hash_table:init:0: { 
  var %i = 1
  while ($hget(%i)) { 
    did -a $dname 1 $ifmatch
    inc %i
  }
  ;.timer 0 0 update_hash
}
on *:dialog:hash_table:sclick:*: { 
  update_hash
}

alias update_hash {
  if ($did == 1) { 
    var %s = $did(hash_table,1).seltext
    if (!%s) return
    var %i = 1
    did -r hash_table 2
    while ($hget(%s,%i).item) { 
      did -a hash_table 2 $ifmatch
      inc %i
    }
  }
  if ( $did == 2) { 
    did -ra hash_table 3 $hget($did(1).seltext,$did(2).seltext)
  }
}


alias hash_table { 
  dialog -m hash_table hash_table
}
/*
alias sockwrite { 
  ; echo @raw $1-
  sockwrite $1-
}
*/
