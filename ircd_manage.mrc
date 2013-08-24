dialog ircd_manage {
  title "New Project"
  size -1 -1 333 329
  option dbu
  list 1, 9 19 105 107, sort size vsbar
  box "Nick Info", 2, 3 3 319 144
  list 3, 117 18 124 49, sort size vsbar
  edit "", 4, 119 126 83 15, autohs
  button "Delete Nick", 5, 10 130 37 12
  text "Chans", 6, 117 9 29 8
  text "Nicks", 7, 12 11 25 8
  button "Remove Fom Chan", 8, 244 19 56 12
  button "Force Join", 9, 245 35 56 12
  list 10, 117 77 124 48, sort size vsbar
  text "Properties", 11, 119 68 32 8
  button "Edit", 12, 244 78 37 12
  button "Save Edit", 13, 206 127 37 12
  box "Chan Info", 14, 2 148 105 174
  list 15, 11 168 84 149, sort size vsbar
  text "chans", 17, 12 159 25 8
  tab "Chan Options", 16, 107 149 217 168
  list 19, 109 177 129 37, tab 16 size vsbar
  text "Properties", 20, 111 168 25 8, tab 16
  list 21, 109 244 126 32, tab 16 sort size vsbar
  button "Delete", 22, 243 177 37 12, tab 16
  button "Delete", 24, 241 245 37 12, tab 16
  edit "", 26, 109 279 126 14, tab 16 autohs
  button "Save Edit", 27, 241 282 37 12, tab 16
  text "Bans", 28, 110 235 25 8, tab 16
  edit "", 23, 109 216 129 12, tab 16
  button "Save Edit", 25, 243 215 37 12, tab 16
  tab "Nick Options", 18
  list 29, 111 168 74 73, tab 18 size
  menu "Stop Server", 30
  item "Restart Server", 31, 30
  item "-", 32, 30
  item "Exit - snotice", 33, 30
  item "Exit", 34, 30
}


alias ircd_manage { 

  dialog -dm ircd_manage ircd_manage

}

on *:dialog:ircd_manage:init:0: { 
  var %i = 1

  while ($hfind(clients,nicks.*,%i,w)) { 
    did -a $dname 1 $gettok($v1,2,46)
    inc %i
  }
  var %i = 1
  while ($hfind(chans,#*.created,%i,w)) { 
    var %chan $gettok($v1,1,46)
    did -a $dname 15 %chan
    inc %i
  }

}
/*********************

the NICKS sclick (1st list box)

**********************
*/

on *:dialog:ircd_manage:sclick:1: { 

  var %sock = $getnick($did($did).seltext)
  var %chans = $client(%sock).chans
  var %i = 1
  did -r $dname 3
  while ($gettok(%chans,%i,32)) { 
    did -a $dname 3 $v1
    inc %i

  }
  var %i = 1
  did -r $dname 10
  while ($hfind(clients,$+(%sock,\.,(?!chans).*),%i,r)) { 
    did -a $dname 10 $gettok($v1,3,46)
    inc %i
  }
}

/*******************
1st group box, nick properties click
*/


on *:dialog:ircd_manage:sclick:10: { 
  var %sock = $getnick($did(1).seltext)
  did -ra $dname 4 $client(%sock,$did($did).seltext)
}

/****************************
Group box 2 chans list box
*/

on *:dialog:ircd_manage:sclick:15: { 

  var %i = 1
  var %chan = $did($did).seltext
  did -r $dname 19
  while ($hfind(chans,$+(%chan,.*),%i,w)) { 
    did -a $dname 19 $gettok($v1,2,46)
    inc %i
  }
  var %i = 1
  did -r $dname 21
  while ($hfind(chans,$+(%chan,.,bans.,*),%i,w)) { 
    did -a $dname 21 $gettok($v1,3-,46) 
    inc %i
  }
  var %i = 1
  did -r $dname 29
  while ($_nick(%chan,%i)) { 
    did -a $dname 29 $v1
    inc %i
  }
}

/************************
Chan properties click
***********************
*/
on *:dialog:ircd_manage:sclick:19: { 
  did -ra $dname 23 $chans($did(15).seltext,$did($did).seltext)

}
