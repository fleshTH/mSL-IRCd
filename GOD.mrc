;services
alias loadGOD { 
  sockopen GOD localhost $_server_port
}
on *:sockopen:GOD: { 
  sockwrite -n $sockname PASS @%$333$&&887654&&6543~!@@@@~!@!~^%$#&8&^%^&
  sockwrite -n $sockname user Services "" $_server :God
  sockwrite -n $sockname nick GOD
}

alias checkIfIdNick { 
  ; echo godLog %sock nick check -> nick is $client($1).nick
  if (r !isincs $client($1).mode) { 
    while ($getnick(Guest $+ $ticks)) { noop }
    godsend svnick $client($1).nick Guest $+ $ticks
  }
}

on *:sockread:GOD: { 
  var %temp
  sockread %temp
  tokenize 32 %temp
  if ($regex(%temp,/^:(([^!]+)![^\s]+)\s([^\s]+)\s(?::)?([^\s]+)(?:\s:?([^\s]+))?(?:\s:?(.*))?/i)) { 
    var %addr = $regml(1)
    var %nick = $regml(2)
    var %event = $regml(3)
    var %chan = $regml(4)
    var %newnick = %chan
    var %text = $regml(5) $regml(6)
    if (%event == nick) { 
      ; echo @godLog NICK -> %nick to %newnick
      if (%nick == %newnick && %nick !== %newnick) return
      if ($readini(users.ini,%newnick,pass)) { 
        if (r isincs $client($getnick(%newnick)).mode) { 
          sumode $getnick(%newnick) -r
        }
        godsend notice %newnick : $+ %newnick is a registed nick. Please type /ns identify <password> or /ns id <password> or change your nickname using /nick <newnick>
        godsend notice %newnick :If you fail to comply within 60 seconds, your nick will forcibly be changed.
        timer_ch_nick_ $+ $getnick(%newnick) 1 60 checkIfIdNick $getnick(%nick)
      }
      else { 
        if ($timer(_ch_nick_ $+ $getnick(%newnick))) { 
          if (r isincs $client($getnick(%newnick)).mode) { 
            sumode $getnick(%newnick) -r
          }
          .timer_ch_nick_ $+ $getnick(%newnick) off
        }
      }
    }
    if (%event == privmsg) { 
      if (%text == $+($chr(1),VERSION,$chr(1))) {
        godsend notice %nick : $+ $+($chr(1),VERSION Atavist services version 0.0000000000.0.0.0.0.0.-1,$chr(1)) 
      }
      if ($regex(%text,/\x01PING (.*?)\x01/i)) {  
        godsend notice %nick : $+ $+($chr(1),PING $regml(1),$chr(1))
      }
    }
    if (%event == join) {
      ;hinc -mu5 god_db $+(joinProtection_i_,%chan)
      ;hadd -u5 god_db $+(joinProtection_nick_,%chan) $addtok($hget(god_db,$+(joinProtection_nick_,%chan)),%nick,32)

      if ($hget(god_db,$+(joinProtection_i_,%chan)) > 5) { 
        godsend mode %chan +i
        var %i = 1
        var %nicks = $hget(god_db,$+(joinProtection_nick_,%chan))
        tokenize 32 %nicks
        godsend kick %chan $* :Join/Part flood protection
        hdel god_db $+(joinProtection_nick_,%chan)
        return
      }
      if ($_nick(%chan,0) == 1 && $_nick(%chan,1) == %nick) { 
        if ($_chanPass(%chan)) { 
          var %i = 1
          while ($ini(chans.ini,%chan,%i)) { 
            var %item = $v1
            chans %chan %item $readini(chans.ini,%chan,%item)
            inc %i
          }
          godsend mode %chan + $+ $chans(%chan).mode
          godsend topic %chan : $+ $chans(%chan).topic
          if ($isbanned($client($getnick(%nick)).gethost,%chan)) {
            godsend fjoin god %chan
            godsend kick %chan %nick You are banned from this channel

          }
        }
        else {
          godsend mode %chan +o %nick
        }
      }

      if ($isAOP(%chan,%nick) && r isincs $client($getnick(%nick)).mode) {
        godsend mode %chan +o $+ $iif($chans(%chan,owner) == %nick,q $chr(32) %nick) %nick
      }
      elseif ($isVoice(%chan,%nick) && r isincs $client($getnick(%nick)).mode) { 
        godsend mode %chan +v %nick
      }
    }
  }
}
alias godsend { 
  :error
  .reseterror
  if ($sock(god)) {
    sockwrite -n GOD $1-
  }
}


alias toGod { 
  if ($getnick(god)) {
    sockwrite -n $v1 $1-
  }
}

alias hasAccess { 
  return $iif($isAOP($1,$2),$v1,$isvoice($1,$2))
}

alias ircd.cs { 
  if ($isalias($+(cs.,$1))) { 
    if (r !isin $chans($2).mode && !$istok(help register,$1,32)) { 
      godsend notice $client($sockname).nick : $+ $2 is not registered. please use /cs register <password>
      return
    }
    ; echo @godlog r isincs $client($sockname).mode &&  $2 , $client($sockname).nick
    if ((r isincs $client($sockname).mode && $hasAccess($2,$client($sockname).nick)) || ($istok(info help register,$1,32))) { 


      $+(cs.,$1) $2-
    }
    else {
      godsend notice $client($sockname).nick :Access Denied

    }
  }
  else { 
    godsend notice $client($sockname).nick : $+ $1 $+ : Unkown command
  }
}

alias cs.kick { 
  if ($ischan($1)) { 
    if ($isop($1,$client($sockname).nick)) {
      if ($_nick($1,$2)) {
        godsend kick $1 $2 : $+ $3- (Requested)
      }
      else {
        sendraw $sockname 401 $2 :No such nick
      }
    }
    else {
      ;sendraw $sockname -n client.1093093 : $+ $_server 4
    }
  }
}

alias _chanPass { 
  return $readini(chans.ini,$1,pass)
}

alias cs.info { 
  if ($ischan($1)) { 

    ; echo @raw $1
    if ($_chanpass($1)) {
      ; echo -s @raw uh... ok
      var %nick = $client($sockname).nick 
      godsend notice %nick :Channel info $1 : Owner $chanOwner($1)
      godsend notice %nick :Channel info $1 : Date registered: $asctime($readini(chans.ini,$1,time))
    }
  }
}

alias cs.help { 
  if (!$1) { 
    var %cat = _
    var %item = *
  }
  else { 
    var %cat = $1
    var %item = $iif($2,$2,*)
  }
  if (%item != *) { 
    if ($readini(cs.help.ini,%cat,%item)) {
      godsend notice $client($sockname).nick :HELP: $upper(%cat)   $readini(cs.help.ini,%cat,%item)
    }
    else {
      godsend notice $client($sockname).nick :HELP  $upper(%cat %item) - No help is availble for your request
    }
  }
  else { 
    if (!$ini(cs.help.ini,%cat,0)) { 
      godsend notice $client($sockname).nick :HELP  $upper(%cat)  - No help is availble for your request
      return
    }
    var %i = 1
    while ($ini(cs.help.ini,%cat,%i)) { 
      var %item = $v1
      godsend notice $client($sockname).nick :HELP $iif(%cat != _,$upper(%cat))  $readini(cs.help.ini,%cat,%item)     
      inc %i
    }
  }
}

alias cs.register { 
  ; ; echo -a  $sockname $1-
  if ($ischan($1)) { 
    if ($isop($1,$client($sockname).nick)) { 
      ; used to check if it's regged or not
      if ($_chanPass($1) == $null) { 
        writeini chans.ini $1 pass $md5($2)
        writeini chans.ini $1 time $ctime
        writeini chans.ini $1 topic $$chans($1).topic
      }
    }
  }
}

alias ns.id { 
  ns.identify $1-
}

alias ns.identify { 
  var %pass = $readini(users.ini,$client($sockname).nick,pass)
  if (!%pass) { 
    godsend NOTICE $client($sockname).nick : $+ $client($sockname).nick is not registered, please use /ns register <password>

    ;user not registered
    return
  }
  if (%pass == $md5($1)) { 
    sumode $sockname +r
    if ($readini(users.ini,$client($sockname).nick,mode)) { 
      sumode $sockname + $+ $v1
    }
    var %chans = $client($sockname).chans
    var %i = 1
    var %n = $client($sockname).nick
    clientadd $sockname vhost $readini(users.ini,%n,vhost)
    while ($gettok(%chans,%i,32)) { 
      var %c = $v1
      if ($isaop(%c,%n) && !$isop(%c,%n)) { 
        godsend mode %c +o $+ $iif($chans(%c,owner) == %n,q $chr(32) %n) %n
      }
      elseif ($isvoice(%c,%n) && + !isin) { 
        godsend mode %c +v %n
      }
      inc %i
    }
    godsend NOTICE $client($sockname).nick :You have been identified.
    if ($readini(users.ini,%n,vhost)) { 
      clientadd $sockname vhost $v1
    }
  }
  else { 
    godsend NOTICE $client($sockname).nick :Password incorrect
  }
}


alias ns.ghost { 
  var %n = $client($sockname).nick
  if ($getnick($1)) {
    var %pass = $readini(users.ini,$1,pass) 

    if ($md5($2) == %pass) { 
      godsend kill $1 :(Ghost command used by %n $+ )
      notice %n :Ghost command successful, $1 has been killed.
    }
  }
  else { 
    godsend notice %n : $+ $1 is not in use.
  }
}



alias ircd.ns { 
  if ($isalias($+(ns.,$1))) { 
    $+(ns.,$1) $2-
  }
}


alias isNickRegged { 
  if ($readini(users.ini,$1,pass)) { 
    return 1
  }
}
alias ns.register { 
  var %nick = $client($sockname).nick
  if (!$1) { 
    godsend notice %nick :You must have a password: /ns register <password>
    return
  }
  if ($left(%nick,5) == guest) { 
    godsend %nick :Sorry, Nicks starting with Guest may not be registered
    return
  }
  if (!$isNickRegged(%nick)) {
    writeini users.ini %nick pass $md5($1)
    sumode $sockname +r
    godsend notice %nick :Your nick is now registered
  }
}


alias fileToSock { 
  sockwrite -n %socket $1-
}


alias file_sock { 
  set %socket $2-
  filter -fk $1 fileToSock *
  unset %socket
}


/*
****************************************

Chanserv aliases

****************************************
*/


alias isSOP { 
  return $readini(chans.ini,$+($1,.SOP),$2)
}

alias isAOP { 
  ; echo -a $1 = 1 $2 = 2
  return $iif($readini(chans.ini,$+($1,.AOP),$2),$v1,$isSOP($1,$2))
}
alias isVOICE { 
  return $readini(chans.ini,$+($1,.VOICE),$2)
}

alias addChanAccess { 
  if ($istok(AOP SOP VOICE,$1,32)) { 
    $+(is,$1) $2-3
    if (!$result) { 
      removeChanAccess aop $3
      removeChanAccess sop $3
      removeChanAccess voice $3
      writeini -n chans.ini $+($2,.,$1) $3-
    }
  }
}

alias removeChanAccess {
  if ($istok(AOP SOP VOICE,$1,32)) { 
    remini chans.ini $+($2,.,$1) $3
  }
}
alias cs.invite { 
  if (!$_nick($1,$client($sockname).nick)) {
    chans $1 inviteList $addtok($chans($1).inviteList,$client($sockname).nick,32)
    sockwrite -n $sockname : $+ $client(god).gethost INVITE $client($sockname).nick : $+ $1
    godsend notice $1 : $+ $client($sockname).nick has been invited to $1
  }
  else { 
    sendraw $sockname 443 $client($sockname).nick $1 :You are already on that channel
  }
}


alias cs.aop { 
  if ($2 == add) { 
    if ($isSOP($1,$client($sockname).nick)) { 
      addChanAccess aop $1 $3 $client($sockname).nick $ctime
      godsend notice $client($sockname).nick : $+ $3 Has been added to auto OP list in $1
    }
  }
  elseif ($2 == list) {
    var %i = 1
    godsend notice $client($sockname).nick :AOP list for $1 $+ 
    while ($ini(chans.ini,$+($1,.aop),%i)) { 
      var %nick = $v1
      var %txt = $readini(chans.ini,$+($1,.aop),%nick)
      godsend notice $client($sockname).nick : %i  %nick added by $gettok(%txt,1,32) on $asctime($gettok(%txt,2,32))
      inc %i
    }
    if (%i == 1) { 
      godsend notice $client($sockname).nick :There are no AOPs in the access list
    }
  }
}

alias chanOwner { 
  return $readini(chans.ini,$1,owner)
}



alias cs.sop { 
  if ($2 == add) { 
    if ($chanOwner($1) == $client($sockname).nick) { 
      addChanAccess sop $1 $3 $client($sockname).nick $ctime
      godsend notice $client($sockname).nick : $+ $3 Has been added to Super OP list in $1
    }
  }
  elseif ($2 == list) {
    var %i = 1
    godsend notice $client($sockname).nick :SOP list for $1 $+ 
    while ($ini(chans.ini,$+($1,.SOP),%i)) { 
      var %nick = $v1
      var %txt = $readini(chans.ini,$+($1,.sop),%nick)
      godsend notice $client($sockname).nick : %i  %nick added by $gettok(%txt,1,32) on $asctime($gettok(%txt,2,32))
      inc %i
    }
    if (%i == 1) { 
      godsend notice $client($sockname).nick :There are no SOPs in the access list
    }
  }

}

alias cs.voice { 
  if ($2 == add) { 
    if ($aop($1,$client($sockname).nick)) { 
      addChanAccess voice $1 $3 $client($sockname).nick $ctime
      godsend notice $client($sockname).nick : $+ $3 Has been added to auto voice list in $1
    }
  }
}
