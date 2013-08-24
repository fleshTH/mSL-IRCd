alias isop { 
  ; ; echo -a $1-
  if (o isin $_nick($1,$2).mode || $2 == god) {
    return 1
  }
}


alias ircd.mode {
  if ($ischan($1)) { 
    var %chan $1
    tokenize 32 $2-
  }
  elseif ($1 == $client($sockname).nick) {
    var %i = 1
    var %x
    var %+modes
    var %-modes

    while ($mid($2,%i,1)) {  

      var %c = $v1
      if (%c == + || %c = -) { 
        %x = %c
        inc %i
        continue
      }
      if (%c isincs $no_user_set_user) { 
        inc %i
        continue
      }
      if (%x == +) {
        if (%c isincs $user_modes_supported && %c !isincs $client($sockname).mode) {
          echo -s passed4
          clientadd $sockname mode $client($sockname).mode $+ %c
          var  %+modes = %+modes $+ %c
        }
      } 
      else {
        if (%c isincs $user_modes_supported && %c isincs $client($sockname).mode) {
          clientadd $sockname mode $remove($client($sockname).mode,%c)
          var %-modes = %-modes $+ %c
        }

      }
      inc %i
    }
    var %str = $iif(%+modes,+ $+ $v1) $+ $iif(%-modes,- $+ $v1)
    if (%str) { 
      sockwrite -n $sockname : $+ $client($sockname).gethost MODE $client($sockname).nick : $+ %str
    }
    return

  } 
  else { 
    return
  }


  ; ; echo -s MODE  $1-
  if (!$1-) {
    sendraw $sockname 324 %chan : $+ $chans(%chan).mode
    sendraw $sockname 329 %chan : $+ $chans(%chan).created
    return
  }
  if ($2 && (!$isop(%chan,$client($sockname).nick) && !$isoper($sockname))) {
    sendraw $sockname 482 %chan :You are not a channel operator
    return
  }
  var %pos = 0
  var %i = 0
  var %tok = 1
  var %str
  var %-modes
  var %-aff
  var %+aff
  var %+modes

  while (%i < $len($1)) { 
    inc %i   
    var %c = $charAt($1,%i)
    if (%c == + || %c == -)  { 
      var %pos = %c 
      continue
    }
    ;482 \ #uno.test :You're not channel operator
    var %m = $getmode(%c)
    ; echo -s %m %c
    if (!%m) { 
      sendraw $sockname 472  : $+ %c is unknown mode char to me
      return
    }
    if (%c isincs $no_user_set_chan && god != $client($sockname).nick) return
    if (%m == 1) { 
      ; 401 \ x :No such nick
      if ($pos($gettok($_supported_prefix,1,32),%c)) {
        var %mode = $mid($gettok($_supported_prefix,2,32),$v1,1)
        var %nick = $gettok($2-,%tok,32)
        ;        echo -a %nick
        if (!%nick) { 
          inc %tok
          continue
        }
        if (!$_nick(%chan,%nick)) { 
          inc %tok
          sendraw $sockname 401 %nick :No such nick
          continue
        }
        if (%pos == +) {  
          channick %chan %nick mode $channick(%chan,%nick).mode $+ %c
          %+modes = %+modes $+ %c
          %+aff = %+aff %nick
        }
        else { 
          channick %chan %nick mode $remove($_nick(%chan,%nick).mode,%c)
          %-modes = %-modes $+ %c
          %-aff = %-aff %nick
        }
      }
      elseif (%c == b) { 
        var %mask = $gettok($2-,%tok,32)
        if (!%mask) {
          var %i = 1
          while ($hfind(chans,$+(%chan,.bans.*),%i,w)) {
            var %key = $v1
            ; ; echo -a %key $hget(chans,%key)
            sendraw $sockname 367 %chan $gettok(%key,3-,46) $hget(chans,%key)
            inc %i
          }
          sendraw $sockname 368 %chan :End of channel ban list
          return
          goto end

        }
        if (*!*@* !iswm %mask && $left(%mask,1) != ~) {
          if ($left(%mask,1) == @) %mask = *!* $+ %mask
          if (! !isin %mask) { %mask = %mask $+ !*@* }
        }
        if (%pos == +) { 
          if ($chanban(%chan,%mask)) { inc %tok | continue }
          chanban %chan %mask $client($sockname).nick $ctime
          if ($_chanpass(%chan)) writeini chans.ini %chan bans. $+ %mask $chanban(%chan,%mask)
          %+modes = %+modes $+ %c
          %+aff = %+aff %mask
        }
        else { 
          if (!$chanban(%chan,%mask)) { inc %tok | continue }
          hdel chans $+(%chan,.bans.,%mask)
          if ($_chanpass(%chan)) remini chans.ini %chan bans. $+ %mask
          %-modes = %-modes $+ %c
          %-aff = %-aff %mask
        }
      }
      var %str = %str $+(%pos,%c) set for nick/address $gettok($2-,%tok,32)
      :end
      inc %tok
    }
    elseif (%m == 2) { 
      var %str = %str $+(%pos,%c) set for channel as $gettok($2-,%tok,32)
      inc %tok
    }
    elseif (%m == 3) { 
      if (%pos == -)  {
        var %str = %str $+(%pos,%c) set for channel. no params needed
      }
      else {
        var %str = %str $+(%pos,%c) set for channel as $gettok($2-,%tok,32)
        inc %tok
      }
    }
    elseif (%m == 4) { 
      if (%pos == +) {
        if (%c !isincs $chans(%chan).mode) {
          %+modes = $regsubex(%+modes $+ %c,(.)\1+,\1)
          chans %chan mode $chans(%chan).mode $+ %c
        }
      }
      else { 
        if (%c isincs $chans(%chan).mode) {
          %-modes = $regsubex(%-modes $+ %c,(.)\1+,\1)
          chans %chan mode $removecs($chans(%chan).mode,%c)
        }
      }
    }
  }
  ;msg $chan %str
  var %str = $iif(%-modes,- $+ %-modes) $+  $iif(%+modes,+ $+ %+modes) %-aff %+aff
  ; ; echo -a %str
  if (%str) {
    tochan %chan : $+ $client($sockname).gethost MODE %chan : $+ %str
    if ($_chanpass(%chan)) writeini chans.ini %chan mode $chans(%chan).mode
  }
}

alias getmode { 
  var %modes = $gettok($_supported_prefix,1,32) $+ b,k,l,rimntcSB
  ;imnpst
  var %i = 1
  while ($gettok(%modes,%i,44)) { 
    var %s = $ifmatch
    if ($1 isincs %s) { return %i }
    inc %i
  }
  return 0
}




;

alias user_modes_supported return SmoBr
;xwWsTRp

alias no_user_set_chan return rB

alias no_user_set_user return roSB


alias charAt { 
  return $mid($1-,$2,1)
}
