
;;;;;;;;;;; this is the server node. i am hoping to be able to merge networks.



alias _server return antithetical.fleshth.com

;;;;;;;;;;; this is the port the IRCd will listen on
alias _server_port return 8888


/*
Channel user modes



this is the support usermodes you have to be able to have on the network. this is totally up to you
you can have it as such



============== example ===================
alias _supported_channel_user_modes return qaohv ~&@%v

============= end example =======================

The only auto modes, however, will be AOP and voice.
if you specifiy q, then the owner will get ~


*/


alias _supported_prefix return qov ~@+

alias _network return FLESH-NET


/*
SVNICK is what services use to change nicks.
if you want to allow opers to use this feature, retrun 1
if not, return 0

*/

alias _oper_svnick return 1


/*

return 1 if opers can change user modes

warning, this will allow an oper to change any mode. they could even effectivly give +o (oper) or +S (services)
*/

alias _oper_change_user_modes return 0

/*

allow vhost

*/

alias _allow_vhost return 1



/*

allow opers to set other people's vhost

*/

alias _allow_oper_set_vhost return 0


alias juped_nicks return nickserv chanserv operserv god
