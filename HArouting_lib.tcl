proc HAroute_Connect_all {args} {
    LogMsg "TRACE([set myName [myname]]): Calledby [calledby]"	
	LogMsg "Info($myName): Start connecting to all the devices"
	LogMsg "##########################################################"             
	
	global DUT_IP cmtsSmm6IP cmtsSmm7IP cmtsIP DUT_ETH0_IP DUT2_IP R1_ip R2_ip R3_ip R4_ip switch_ip101 switch_ip202 server_ip timeout debug PE1 PE2
	
    set buffer1 0
	catch {Telnet $cmtsIP -callback ::spawn_cmts} buffer1
	
	if {$buffer1 == 1} {
	     if {$cmtsIP != $DUT2_IP} {
	       set cmtsIP {172.0.2.239}
		   set DUT_ETH0_IP {172.0.2.239}
	       LogMsg "now active SMM is SMM7"
	       LogMsg " cmtsIP is $cmtsIP"
		   LogMsg " DUT_ETH0_IP is $DUT_ETH0_IP"
	       } else {
	           set cmtsIP {172.0.2.238}
	           LogMsg "cmtsIP is $cmtsIP"
		       LogMsg "DUT_ETH0_IP is $DUT_ETH0_IP"
	           LogMsg "now active SMM is SMM6"
	     }
	}
    set var1 [Telnet $cmtsIP -callback ::spawn_cmts -timeout $timeout -config -debug  -print]
	
	set var2 [Telnet $R1_ip -callback ::spawn_R1 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]

    set var3 [Telnet $R2_ip -callback ::spawn_R2 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
	set var4 [Telnet $R3_ip -callback ::spawn_R3 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
    set var5 [Telnet $R4_ip -callback ::spawn_R4 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
    set var6 [Telnet $switch_ip101 -callback ::spawn_switch101 -uname -passwd casa -deviceType Huawei -debug  -print]
    set var7 [Telnet $switch_ip202 -callback ::spawn_switch202 -uname -passwd casa -deviceType Huawei -debug  -print]
	set var8 [Telnet $PE1 -callback ::spawn_huawei -uname -passwd casa -deviceType Huawei -debug  -print]
	SendAndExpect sys -prompt casa -fd $::spawn_switch202 -timeout $timeout
	SendAndExpect sys -prompt casa -fd $::spawn_switch101 -timeout $timeout
	SendAndExpect sys -prompt casa -fd $::spawn_huawei -timeout $timeout
    set var9 [Telnet $server_ip -callback ::spawn_server -uname zhouxueliang -passwd casa -dev linux]

	set var10 [Telnet $PE2 -callback ::spawn_asr -uname casa -password casa -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
	if {$var1 || $var2 ||$var3 ||$var4 ||$var5 ||$var6 ||$var7 ||$var8 ||$var9 ||$var10 == 0} {
	    LogMsg "connected to all device successfully,continue smoking test"
	    LogMsg "##########################################################"
	    return 0
	    } else {
	        LogMsg "connected to all device failed,stop the test"
	        LogMsg "##########################################################"
	        return 1
	    } 
}

proc HAroute_show_route_summary {args} {
    LogMsg "TRACE([set myName [myname]]): Calledby [calledby]"  
    LogMsg "Info($myName): Check MPLS_vpls_vpws ospf neighbor status" 
    global ::spawn_cmts DUT_ETH0_IP DUT2_IP timeout
 	set rv "0"
    set debug   0
    set verbose 1
	set cmd [list]
	if [regexp -- -help $args] {    #### here defined help info
        set help "[ApiDescriptionTable]\nUsage:  $myName \n"
        append help "\nWhere:\n"
        append help "  -debug    : Toggle debug printing (default is disabled)\n"
        append help "  -verbose  : Toggle verbosity (default is enabled)\n"
        append help "  -cmd      : Toggle cmd to check background table \n"
		append help "  -proto    : proto ospf/bgp/rip \n"
		append help "  -fd       : Toggle cmd to check background table \n"
		append help "  -callback : return summary number \n"
		append help "\n show_route_summary -cmd show ip route rip | count-only R -fd $::spawn_cmts\n"
		append help "\n show_route_summary -cmd show ip route rip vrf xxx | count-only R -fd $::spawn_cmts\n"
		append help "\n show_route_summary -cmd show ipv6 route vrf xxx | count-only B -fd $::spawn_cmts \n"
        append help "\nReturn Values:\n"
        append help "  Pass   : 0\n"
        append help "  Fail   : 1\n\n"
        return $help
    }
    set args [join $args]
    if ![regexp -- ^$ $args] {
        regsub -all -- ¨C $args - args   ;
        set arg_list [xsplit $args " -"];
        foreach a $arg_list {
            switch -re -- [string tolower [string trimleft $a -]] {
                ^$ {}
                ^cmd {
				       set cmd [lrange $a 1 end]
					   LogMsg "input cmd is $cmd"
				}
				^fd {
				       set fd [lrange $a 1 end]
				}
				^callback { 
				       set callback [lrange $a 1 end]
					   uplevel [list catch "unset $callback"]
				}
                ^ver {
                    set verbose [regexp -nocase -- {^(|1|on|enable|true|verbose)$} [lindex $a 1]]
					LogMsg "verbose is $verbose"
                }
                ^debug {
                    set debug [regexp -nocase -- {^(|1|on|enable|true|debug)$} [lindex $a 1]]
                }                
                default {
                    LogMsg "!! Error($myName): Unknown argument \"-$a\""
                    return 1
                }
            } ;# EOswitch
        } ;# EOeach
    } 
	
    array set routesummary "" 
    set routesummary(ospfglobal) " "
    set routesummary(ripglobal) " "
    set routesummary(ripvrfsmk1) " "
    set routesummary(ripvrfsmk2) " "
    set routesummary(bgpglobalipv4) " "
    set routesummary(bgpglobalipv6) " "
    set routesummary(bgpvpnv4) " "
    set routesummary(bgpvpnv6) " "
    
    SendAndExpect "$cmd" -- -fd $fd -timeout $timeout -prompt casa -callback total 
    regexp -all -line -- {Line:\s+([^ \r]+)} $total - summary
    LogMsg "$cmd summary is $summary"
	if [info exists callback] {
		uplevel [list set $callback $summary]
	}
    if {$summary == $cmd } {
        LogMsg "Info($myName:) $cmd summary is the same and this test is passed" 
        return 0
        } else { 
             LogMsg "!! Error($myName:) $cmd summary is not the same and this test is failed" 
             return 1
         }
}    
	
proc HAroute_mplsl2vpn_config {args} {
	LogMsg "TRACE([set myName [myname]]): Calledby [calledby]"  
    LogMsg "Info($myName): creat and delete vpls vpws on CMTS 238 and 202 device " 
    global ::spawn_cmts DUT_ETH0_IP DUT2_IP timeout ::spawn_switch202
 	set rv "0"
    set debug   0
    set verbose 1
	if [regexp -- -help $args] {    #### here defined help info
        set help "[ApiDescriptionTable]\nUsage:  $myName \n"
        append help "\nWhere:\n"
        append help "  -debug    : Toggle debug printing (default is disabled)\n"
        append help "  -verbose  : Toggle verbosity (default is enabled)\n"
        append help "  -mplsl2vpn      : Toggle cmd to check background table \n"
		append help "  -operation      : proto \n"
		append help "  -fd      : Toggle cmd to check background table \n"
		append help "\n HAmplsl2vpn_config -mplsl2vpn vpls -operation add -fd cmts\n"
		append help "\n HAmplsl2vpn_config -mplsl2vpn vpls -operation remove -fd PE\n"
		append help "\n HAmplsl2vpn_config -mplsl2vpn vpws -operation add -fd cmts \n"
		append help "\n HAmplsl2vpn_config -mplsl2vpn vpws -operation remove -fd cmts \n"
        append help "\nReturn Values:\n"
        append help "  Pass   : 0\n"
        append help "  Fail   : 1\n\n"
        return $help
    }
    set args [join $args]
    if ![regexp -- ^$ $args] {
        regsub -all -- ¨C $args - args   ;
        set arg_list [xsplit $args " -"];
        foreach a $arg_list {
            switch -re -- [string tolower [string trimleft $a -]] {
                ^$ {}
                ^mplsl2vpn {
				       set mplsl2vpn [lrange $a 1 end]
					   LogMsg "input mplsl2vpn is $mplsl2vpn"
				}
				^operation {
				       set operation [lrange $a 1 end]
					   LogMsg "input operation is $operation"
				}
				^fd {
				       set fd [lrange $a 1 end]
				}
                ^ver {
                    set verbose [regexp -nocase -- {^(|1|on|enable|true|verbose)$} [lindex $a 1]]
					LogMsg "verbose is $verbose"
                }
                ^debug {
                    set debug [regexp -nocase -- {^(|1|on|enable|true|debug)$} [lindex $a 1]]
                }                
                default {
                    LogMsg "!! Error($myName): Unknown argument \"-$a\""
                    return 1
                }
            } ;# EOswitch
        } ;# EOeach
    } 
	if {$mplsl2vpn == "vpls"} {
		if {$operation == "add"} {
			if {$fd == "cmts"} {
				for {set a 3994} {$a < 4095} {incr a} {
					# set b [expr $a-1];
					SendAndExpect "mpls vpls $a $a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					SendAndExpect "signaling bgp route-distinguisher 238:$a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					SendAndExpect "signaling bgp route-target 238:$a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					SendAndExpect "signaling bgp ve-id 1\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					SendAndExpect "signaling bgp ve-range 8\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					after 500
				}
				for {set a 3894} {$a < 3994} {incr a} {
					SendAndExpect "mpls vpls $a $a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					SendAndExpect "signaling ldp vpls-peer 202.77.1.1\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					after 500
				}
				return 0
			} elseif { $fd == "pe"} {
				SendAndExpect "interface xg0/0/23 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "undo port trunk allow vlan 3001 to 4094 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "interface xg0/0/24 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "port trunk allow vlan 3001 to 4094 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				for {set a 3994} {$a < 4095} {incr a} {
				    set b [expr $a -1]
					# SendAndExpect "vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "vsi $a auto\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "pwsignal bgp\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "route-distinguisher 202:$a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "vpn-target 238:$a import-extcommunity\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "vpn-target 238:$a export-extcommunity\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "encapsulation rfc4761-compatible\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "site $b range 20 default-offset 0\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "quit\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect " encapsulation ethernet\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "quit\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "interface vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "l2 binding vsi $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				}
				for {set a 3894} {$a < 3994} {incr a} {
					# SendAndExpect "vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "vsi $a static\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "pwsignal ldp\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "vsi-id $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "peer 10.238.1.2\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "quit\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "encapsulation ethernet\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "int vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "l2 binding vsi $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				}
	        return 0
			}
			
		} elseif {$operation == "remove"} {
			if {$fd == "cmts"} {
				for {set a 3894} {$a < 4095} {incr a} {
				# 
				SendAndExpect "no mpls vpls $a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
				after 500
				}
			return 0
			} elseif {$fd == "pe"} {
			for {set a 3894} {$a < 4095} {incr a} {
				SendAndExpect "interface vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "undo l2 binding vsi $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "quit\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "undo vsi $a \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				# SendAndExpect "undo vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				}
			return 0
			}
		}
	}
	if {$mplsl2vpn == "vpws"} {
		if {$operation == "add"} {
			if {$fd == "cmts"} {
				for {set a 3001} {$a < 3801} {incr a} {
					SendAndExpect "mpls vpws $a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					SendAndExpect "peer 202.77.1.1 $a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					after 500
					}
			return 0
			} elseif {$fd == "pe"} {
				SendAndExpect "interface xg0/0/23 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "undo port trunk allow vlan 3001 to 4094 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "interface xg0/0/24 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				SendAndExpect "port trunk allow vlan 3001 to 4094 \r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
				for {set a 3001} {$a < 3801} {incr a} {
					SendAndExpect "vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "interface Vlanif$a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "mpls l2vc 10.238.1.2 $a raw\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout 
					}
				return 0
			}
		} elseif {$operation == "remove"} {
			if {$fd == "cmts"} {
				for {set a 3001} {$a < 3801} {incr a} {
					SendAndExpect "no mpls vpws $a\r" -- -fd $::spawn_cmts -prompt casa -timeout $timeout
					}
			} elseif {$fd == "pe"} {
				for {set a 3001} {$a < 3801} {incr a} {
					SendAndExpect "interface vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					SendAndExpect "undo  mpls l2vc 10.238.1.2 $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					# SendAndExpect "undo vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
					}
			 return 0
			}
		return 0
		}
		return 0
	}
	return 0
}
proc HAroute_creat_mplsl2vpn {args} {
HAmplsl2vpn_config -mplsl2vpn vpls -operation add -fd cmts
HAmplsl2vpn_config -mplsl2vpn vpls -operation add -fd pe
HAmplsl2vpn_config -mplsl2vpn vpws -operation add -fd cmts
HAmplsl2vpn_config -mplsl2vpn vpws -operation add -fd pe
}
proc HAroute_remove_mplsl2vpn {args} {
HAmplsl2vpn_config -mplsl2vpn vpls -operation remove -fd cmts
HAmplsl2vpn_config -mplsl2vpn vpls -operation remove -fd pe
HAmplsl2vpn_config -mplsl2vpn vpws -operation remove -fd cmts
HAmplsl2vpn_config -mplsl2vpn vpws -operation remove -fd pe
}
proc HAroute_creatvlan {args} {
    global ::spawn_cmts DUT_ETH0_IP DUT2_IP timeout ::spawn_switch202
	for {set a 4088} {$a < 4094} {incr a} {
	SendAndExpect "vlan $a\r" -- -fd $::spawn_switch202 -prompt casa -timeout $timeout
	}
return 0	
}
proc HAroute_summary {args} {
SendAndExpect "show ip route rip | count-only \\\*>" -fd $::spawn_cmts -callback global_rip
regexp -all -line -- {Line:\s+([^ \r]+)} $global_rip - global_rip
SendAndExpect "show ip route ospf | count-only \\\*>" -fd $::spawn_cmts -callback global_ospf
regexp -all -line -- {Line:\s+([^ \r]+)} $global_ospf - global_ospf
SendAndExpect "show ip route connected | count-only \\\*>" -fd $::spawn_cmts -callback global_connected
regexp -all -line -- {Line:\s+([^ \r]+)} $global_connected - global_connected
SendAndExpect "show ip route static | count-only \\\*>" -fd $::spawn_cmts -callback global_static
regexp -all -line -- {Line:\s+([^ \r]+)} $global_static - global_static
SendAndExpect "show ip route bgp | count-only \\\*>" -fd $::spawn_cmts -callback global_bgp
regexp -all -line -- {Line:\s+([^ \r]+)} $global_bgp - global_bgp
SendAndExpect "show ipv6 route bgp | count-only \\\*>"  -fd $::spawn_cmts -callback global_bgp_ipv6
regexp -all -line -- {Line:\s+([^ \r]+)} $global_bgp_ipv6 - global_bgp_ipv6
SendAndExpect "show ipv6 route | count-only I"  -fd $::spawn_cmts -callback global_isis_ipv6
regexp -all -line -- {Line:\s+([^ \r]+)} $global_isis_ipv6 - global_isis_ipv6
SendAndExpect "show ip route vrf smk1 | count-only R"  -fd $::spawn_cmts -callback vrf_smk1_rip
regexp -all -line -- {Line:\s+([^ \r]+)} $vrf_smk1_rip - vrf_smk1_rip
SendAndExpect "show ip route vrf smk2 | count-only R"  -fd $::spawn_cmts -callback vrf_smk2_rip
regexp -all -line -- {Line:\s+([^ \r]+)} $vrf_smk2_rip - vrf_smk2_rip
SendAndExpect "show ip route vrf smk2 | count-only B"  -fd $::spawn_cmts -callback vrf_smk1_bgp
regexp -all -line -- {Line:\s+([^ \r]+)} $vrf_smk1_bgp - vrf_smk1_bgp
set summarylist [list "$global_rip" "$global_ospf" "$global_connected" "$global_static" "$global_bgp" "$global_bgp_ipv6" "$global_isis_ipv6" "$vrf_smk1_rip" "$vrf_smk2_rip" "$vrf_smk1_bgp"]

set route_summary {"vrf instance" "protocol" "vrf ipv4 route" "vrf ipv6 route"}
lappend result [list "global" "rip" "$global_rip" "null"]
lappend result [list "global" "ospf" "$global_ospf" "null"]
lappend result [list "global" "connect" "$global_connected" "null"]
lappend result [list "global" "static" "$global_static" "null"]
lappend result [list "global" "bgp" "$global_bgp" "$global_bgp_ipv6"]
MakeTable "route summary " $route_summary $result
for {set i 17} {$i < 132} {incr i} {
set a vrf$i-ipv4_bgp
set b vrf$i
set c vrf$i-ipv6_bgp
SendAndExpect "show ip route vrf $b | count-only B"  -fd $::spawn_cmts -callback a
regexp -all -line -- {Line:\s+([^ \r]+)} $a - a
SendAndExpect "show ipv6 route vrf $b | count-only B"  -fd $::spawn_cmts -callback c
regexp -all -line -- {Line:\s+([^ \r]+)} $c - c
lappend result [list "vrf$i" "bgp" "$a" "$c"]
}
MakeTable "route summary " $route_summary $result

return 0
}
proc HAroute_connect_all {args} {
    LogMsg "TRACE([set myName [myname]]): Calledby [calledby]"	
	LogMsg "Info($myName): Start connecting to all the devices"
	LogMsg "##########################################################"
	
	global DUT_IP cmtsSmm6IP cmtsSmm7IP cmtsIP DUT_ETH0_IP DUT2_IP R1_ip R2_ip R3_ip R4_ip switch_ip101 switch_ip202 server_ip timeout debug PE1 PE2
	
    set buffer1 0
	catch {Telnet $cmtsIP -callback ::spawn_cmts} buffer1
	
	if {$buffer1 == 1} {
		if {$cmtsIP != $DUT2_IP} {
			set cmtsIP {172.0.2.239}
			set DUT_ETH0_IP {172.0.2.239}
			LogMsg "now active SMM is SMM7"
			LogMsg " cmtsIP is $cmtsIP"
			LogMsg " DUT_ETH0_IP is $DUT_ETH0_IP"
			} else {
				set cmtsIP {172.0.2.238}
				LogMsg "cmtsIP is $cmtsIP"
				LogMsg "DUT_ETH0_IP is $DUT_ETH0_IP"
				LogMsg "now active SMM is SMM6"
	        }
	}
    set var1 [Telnet $cmtsIP -callback ::spawn_cmts -timeout $timeout -config -debug  -print]
	
	set var2 [Telnet $R1_ip -callback ::spawn_R1 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]

    set var3 [Telnet $R2_ip -callback ::spawn_R2 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
	set var4 [Telnet $R3_ip -callback ::spawn_R3 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
    set var5 [Telnet $R4_ip -callback ::spawn_R4 -uname -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
    set var6 [Telnet $switch_ip101 -callback ::spawn_switch101 -uname -passwd casa -deviceType Huawei -debug  -print]
    set var7 [Telnet $switch_ip202 -callback ::spawn_switch202 -uname -passwd casa -deviceType Huawei -debug  -print]
	set var8 [Telnet $PE1 -callback ::spawn_huawei -uname -passwd casa -deviceType Huawei -debug  -print]
	SendAndExpect sys -prompt casa -fd $::spawn_switch202 -timeout $timeout
	SendAndExpect sys -prompt casa -fd $::spawn_switch101 -timeout $timeout
	SendAndExpect sys -prompt casa -fd $::spawn_huawei -timeout $timeout
    set var9 [Telnet $server_ip -callback ::spawn_server -uname zhouxueliang -passwd casa -dev linux]

	set var10 [Telnet $PE2 -callback ::spawn_asr -uname casa -password casa -deviceType Cisco -timeout $timeout -prompt  -debug  -print]
	if {$var1 || $var2 ||$var3 ||$var4 ||$var5 ||$var6 ||$var7 ||$var8 ||$var9 ||$var10 == 0} {
		LogMsg "connected to all device successfully,continue mplsl2vpn script test"
		LogMsg "##########################################################"
		return 0
		} else {
			LogMsg "connected to all device failed,stop the script test"
			LogMsg "##########################################################"
			return 1
		} 
}
proc HAroute_ini {args} {
	LogMsg "TRACE([set myName [myname]]): Calledby [calledby]" 
    LogMsg "Info($myName):ini all topo as the default"
	global timeout
	set cli_cfg_CMTS_vpws_config [ subst {
	no mpls vpws-share-id
	no mpls vpws 3801 
	no mpls vpws 3802
	no mpls vpws 3803 
	no mpls vpws 3804
	no mpls vpws 3805 
	no mpls vpws 3806
	no mpls vpws 3807
	no mpls vpws 3808
	no mpls vpws 3809 
	no mpls vpws 3810
	no mpls vpws 3811 
	no mpls vpws 3812  
	mpls vpws 3801
	peer 202.77.1.1 3801 encapsulation mpls 4
	mpls vpws 3802
	peer 202.77.1.1 3802 
	mpls vpws 3803
	peer 202.77.1.1 3803 
	mpls vpws 3804
	peer 202.77.1.1 3804
	mpls vpws 3805
	peer 202.77.1.1 3805 
	mpls vpws 3806
	peer 202.77.1.1 3806
	mpls vpws 3807
	peer 202.77.1.1 3807 encapsulation mpls 4
	mpls vpws 3808
	peer 202.77.1.1 3808 encapsulation mpls 4
	mpls vpws 3809
	peer 202.77.1.1 3809 encapsulation mpls 4
	mpls vpws 3810
	peer 202.77.1.1 3810 encapsulation mpls 4
	mpls vpws 3811
	peer 202.77.1.1 3811 encapsulation mpls 4
	mpls vpws 3812
	peer 202.77.1.1 3812 encapsulation mpls 4
	
	mpls vpls 1001 1001
	signaling bgp route-distinguisher 238:238
	signaling bgp route-target 222:463
	signaling bgp ve-id 463
	signaling bgp ve-range 104
	mpls vpls 1101 1101
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1102 1102
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1103 1103
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1104 1104
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1105 1105
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1106 1106
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1107 1107
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1108 1108
	signaling ldp vpls-peer 114.1.1.1
	mpls vpls 1109 1109
	signaling ldp vpls-peer 114.1.1.1
	mpls vpws 141
	peer 114.1.1.1 141 
	mpls vpws 142
	peer 114.1.1.1 142 
	mpls vpws 143
	peer 114.1.1.1 143 
	mpls vpws 144
	peer 114.1.1.1 144 
	mpls vpws 145
	peer 114.1.1.1 145 
	mpls vpws 146
	peer 114.1.1.1 146 
	mpls vpws 147
	peer 114.1.1.1 147 
	mpls vpws 148
	peer 114.1.1.1 148 
	mpls vpws 149
	peer 114.1.1.1 149 
	mpls vpws 150
	peer 114.1.1.1 150 
	mpls vpws 151
	peer 114.1.1.1 151 
	mpls vpws 152
	peer 114.1.1.1 152 
	exit
	no cable modem e448.c7bf.aeba mpls 
	no cable modem 0025.2ed4.1cf2 mpls
	no cable modem 0025.2e06.767a mpls
	cable modem e448.c7bf.b140 mpls vpws 3801 3801
	cable modem 7cb2.1bbe.a688 mpls vpws 3802 3802
	
	} ]
	set cli_cfg_ASR_vpws_config [ subst {
	config t
	l2vpn
	pw-class casa-vpws-77
	encapsulation mpls
	protocol ldp
	control-word
	transport-mode ethernet
	ipv4 source 114.1.1.1
	no bridge group AFFAIRES
	no bridge group vpls_ldp
	bridge group AFFAIRES
	bridge-domain TEST-BSOD
	interface GigabitEthernet0/0/0/39.100
		
	neighbor 10.238.1.2 pw-id 141
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 142
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 143
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 144
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 145
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 146
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 147
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 148
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 149
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 150
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 151
		pw-class casa-vpws-77
	exit
	neighbor 10.238.1.2 pw-id 152
		pw-class casa-vpws-77
		exit
	neighbor 10.238.1.2 pw-id 3833
		pw-class casa-vpws-77 
		exit
	neighbor 10.238.1.2 pw-id 3834
		pw-class casa-vpws-77
		exit
	neighbor 10.238.1.2 pw-id 3837
		pw-class casa-vpws-77
		exit
	neighbor 10.238.1.2 pw-id 3841
		pw-class casa-vpws-77
	vfi vpls_bgp
		vpn-id 463
		autodiscovery bgp
		rd 114.1.1.1:463
		route-target 222:463
		signaling-protocol bgp
		ve-id 464
		ve-range 100
	bridge group vpls_ldp
	bridge-domain vpls_238_1
	interface GigabitEthernet0/0/0/39.10
	!
	neighbor 10.238.1.2 pw-id 1101
	!
	neighbor 10.238.1.2 pw-id 1102
	!
	neighbor 10.238.1.2 pw-id 1103
	!
	neighbor 10.238.1.2 pw-id 1104
	!
	neighbor 10.238.1.2 pw-id 1105
	!
	neighbor 10.238.1.2 pw-id 1106
	!
	neighbor 10.238.1.2 pw-id 1107
	!
	neighbor 10.238.1.2 pw-id 1108
	!
	neighbor 10.238.1.2 pw-id 1109
	} ]
	
	set cli_cfg_202_vpws_config [ subst {
	mpls lsr-id 202.77.1.1
	mpls
	mpls l2vpn
	mpls ldp
	mpls ldp remote-peer 238
	remote-ip 10.238.1.2
	
	vlan 159 
	interface Vlanif159
	ipv6 enable
	ip address 172.16.82.202 255.255.255.0
	ipv6 address 2001:16:82::202/64
	mpls
	mpls ldp
	
	interface Vlanif160
	ipv6 enable
	ip address 172.160.82.1 255.255.255.252
	ipv6 address 2001:160:82::202/64
	isis enable 238
	isis ipv6 enable 238
	mpls
	mpls ldp
	
	interface vlan 161
	ip binding vpn-instance smk3
	ipv6 enable
	ip address 172.161.202.1 255.255.255.252
	ipv6 address 2202:161:1::202/64
	isis ipv6 enable 239 
ip vpn-instance smk3
 ipv4-family
  route-distinguisher 238:300
  vpn-target 238:500 export-extcommunity
  vpn-target 238:100 import-extcommunity
  vpn-target 238:200 import-extcommunity
 ipv6-family
  route-distinguisher 238:300
  vpn-target 238:500 export-extcommunity
  vpn-target 238:100 import-extcommunity
  vpn-target 238:200 import-extcommunity
  
interface LoopBack77
 ipv6 enable
 ip address 202.77.1.1 255.255.255.255
 ipv6 address 2001:202::1/128
 isis ipv6 enable 1

 interface LoopBack238
 ipv6 enable
 ip address 202.238.1.1 255.255.255.255
 ipv6 address 2001:202:238::1/128
 isis enable 238
 isis ipv6 enable 238
	interface LoopBack3
	ip binding vpn-instance smk3
	ipv6 enable
	ip address 202.1.3.1 255.255.255.255
	ip address 202.1.3.2 255.255.255.255 sub
	ip address 202.1.3.3 255.255.255.255 sub
	ip address 202.1.3.4 255.255.255.255 sub
	ip address 202.1.3.5 255.255.255.255 sub
	ip address 202.1.3.6 255.255.255.255 sub
	ip address 202.1.3.7 255.255.255.255 sub
	ip address 202.1.3.8 255.255.255.255 sub
	ip address 202.1.3.9 255.255.255.255 sub
	ipv6 address 2202:1:3::1/128
	ipv6 address 2202:1:3::2/128
	ipv6 address 2202:1:3::3/128
	ipv6 address 2202:1:3::4/128
	ipv6 address 2202:1:3::5/128
	ipv6 address 2202:1:3::6/128
	ipv6 address 2202:1:3::7/128
	ipv6 address 2202:1:3::8/128
	ipv6 address 2202:1:3::9/128
	ipv6 address 2202:1:3::10/128
	
		
	ospf 238 
	import-route direct
	default-route-advertise
	area 0.0.0.0
	network 172.16.82.0 0.0.0.255
	network 172.160.82.0 0.0.0.3
	
	ospf 239 vpn-instance smk3 
	area 0.0.0.0
	network 172.161.202.0 0.0.0.3
	
	isis 238
	graceful-restart
	is-level level-1
	cost-style wide
	bfd all-interfaces enable
	network-entity 49.0001.0202.0000.0000.00
	ipv6 enable topology ipv6
	
	isis 239 vpn-instance smk3 
	graceful-restart
	is-level level-1
	cost-style wide
	bfd all-interfaces enable
	network-entity 49.0001.0202.0000.0000.00
	ipv6 enable topology ipv6
		
		
	interface xg 0/0/23
	undo port trunk allow-pass vlan 3801 to 3812
	
	interface xg 0/0/24
	port link-type trunk
	port trunk allow-pass vlan 3801 to 3812
	
	
	interface Vlanif3801
	mpls l2vc 10.238.1.2 3801 
	
	interface Vlanif3802
	mpls l2vc 10.238.1.2 3802 control-word raw
		
	interface Vlanif3803
	mpls l2vc 10.238.1.2 3803 control-word raw
	
	interface Vlanif3804
	mpls l2vc 10.238.1.2 3804 control-word raw
	
	interface Vlanif3805
	mpls l2vc 10.238.1.2 3805 control-word raw
	
	interface Vlanif3806
	mpls l2vc 10.238.1.2 3806 control-word raw
	
	interface Vlanif3807
	mpls l2vc 10.238.1.2 3807 
	
	interface Vlanif3808
	mpls l2vc 10.238.1.2 3808 
	
	interface Vlanif3809                      
	mpls l2vc 10.238.1.2 3809 control-word   
	
	interface Vlanif3810
	mpls l2vc 10.238.1.2 3810 control-word  
	
	interface Vlanif3811
	mpls l2vc 10.238.1.2 3811 control-word  
	
	interface Vlanif3812
	mpls l2vc 10.238.1.2 3812 control-word  
	
	ip route-static vpn-instance smk3 0.0.0.0 0.0.0.0 NULL0
	ipv6 route-static vpn-instance smk3 :: 0 NULL0

	bgp 60000
	router-id 202.1.1.1
	undo default ipv4-unicast
	graceful-restart
	graceful-restart peer-reset
	group rrclinet238 internal
	peer rrclinet238 connect-interface LoopBack238
	peer rrclinet238 password simple casa
	peer 10.88.88.1 as-number 60000
	peer 10.88.88.1 group rrclinet238
	peer 10.238.1.2 as-number 60000
	peer 10.238.1.2 group rrclinet238
	peer 58.77.1.1 as-number 60000
	peer 58.77.1.1 group rrclinet238
	peer 82.82.82.82 as-number 60000
	peer 82.82.82.82 group rrclinet238
	peer 83.83.83.83 as-number 60000
	peer 83.83.83.83 group rrclinet238
	peer 114.1.1.1 as-number 60000
	peer 114.1.1.1 group rrclinet238
	group rrclinetv6238 internal
	peer rrclinetv6238 connect-interface LoopBack238
	peer rrclinetv6238 password simple casa
	peer 2001:58::1 as-number 60000
	peer 2001:58::1 group rrclinetv6238
	peer 2001:82::1 as-number 60000
	peer 2001:82::1 group rrclinetv6238
	peer 2001:83::1 as-number 60000
	peer 2001:83::1 group rrclinetv6238
	peer 2001:238::1 as-number 60000
	peer 2001:238::1 group rrclinetv6238
	#
	ipv4-family unicast
	undo synchronization
	reflector cluster-id 202.58.202.58
	undo peer rrclinetv6238 enable
	peer 10.88.88.1 enable
	peer 10.88.88.1 reflect-client
	peer 10.238.1.2 enable
	peer 10.238.1.2 reflect-client
	peer 58.77.1.1 enable
	peer 58.77.1.1 reflect-client
	peer 82.82.82.82 enable
	peer 82.82.82.82 reflect-client
	peer 83.83.83.83 enable
	peer 83.83.83.83 reflect-client
	peer 114.1.1.1 enable
	peer 114.1.1.1 reflect-client
	peer rrclinet238 enable
	peer rrclinet238 reflect-client
	peer rrclinet238 advertise-community
	
	ipv6-family unicast
	undo synchronization
	peer 2001:58::1 enable
	peer 2001:58::1 reflect-client
	peer 2001:82::1 enable
	peer 2001:82::1 reflect-client
	peer 2001:83::1 enable
	peer 2001:83::1 reflect-client
	peer 2001:88::1 enable
	peer 2001:88::1 reflect-client
	peer 2001:238::1 enable
	peer 2001:238::1 reflect-client
	peer rrclinetv6238 enable
	peer rrclinetv6238 reflect-client
	peer rrclinetv6238 advertise-community
	
	vpls-family
	policy vpn-target
	peer 10.238.1.2 enable
	
	ipv4-family vpnv4
	undo policy vpn-target
	peer 10.88.88.1 enable
	peer 10.88.88.1 reflect-client
	peer 10.238.1.2 enable
	peer 10.238.1.2 reflect-client
	peer 58.77.1.1 enable
	peer 58.77.1.1 reflect-client
	peer 82.82.82.82 enable
	peer 82.82.82.82 reflect-client
	peer 83.83.83.83 enable
	peer 83.83.83.83 reflect-client
	peer 114.1.1.1 enable
	peer 114.1.1.1 reflect-client
	peer rrclinet238 enable
	peer rrclinet238 reflect-client
	peer rrclinet238 advertise-community
	
	ipv4-family vpn-instance smk3
	default-route imported
	import direct
	import static
	import ospf 239
 #
 ipv6-family vpnv6
  undo policy vpn-target
  peer 10.88.88.1 enable
  peer 10.88.88.1 reflect-client
  peer 10.238.1.2 enable
  peer 10.238.1.2 reflect-client
  peer 58.77.1.1 enable
  peer 58.77.1.1 reflect-client
  peer 82.82.82.82 enable
  peer 82.82.82.82 reflect-client
  peer 83.83.83.83 enable
  peer 83.83.83.83 reflect-client
  peer 114.1.1.1 enable
  peer 114.1.1.1 reflect-client
  peer rrclinet238 enable
  peer rrclinet238 reflect-client
  peer rrclinet238 advertise-community
 #

 ipv6-family vpn-instance smk3
  default-route imported
   import static
   import isis 239
   import direct
	} ]
	set cli_cfg_huawei111_config [ subst {
	vlan 3801
	vlan 3802 
	vlan 3803
	vlan 3804
	vlan 3805
	vlan 3806
	vlan 3807
	vlan 3808
	vlan 3809
	vlan 3810
	vlan 3811
	vlan 3812
	int xg 4/0/5 
	port link-type trunk
	port trunk allow-pass vlan 3801 3802 
	int g 1/0/32
	port link-type trunk
	port trunk allow-pass vlan 3801 to 3811 
	interface Vlanif3803
	mpls l2vc 10.238.1.2 3803 control-word raw
	
	interface Vlanif3804
	mpls l2vc 10.238.1.2 3804 control-word raw
	
	interface Vlanif3805
	mpls l2vc 10.238.1.2 3805 control-word raw
	
	interface Vlanif3806
	mpls l2vc 10.238.1.2 3806 control-word raw
	
	interface Vlanif3807
	mpls l2vc 10.238.1.2 3807 raw
	
	interface Vlanif3808
	mpls l2vc 10.238.1.2 3808 
	
	interface Vlanif3809                      
	mpls l2vc 10.238.1.2 3809 control-word   
	
	interface Vlanif3810
	mpls l2vc 10.238.1.2 3810 control-word  
	
	interface Vlanif3811
	mpls l2vc 10.238.1.2 3811 control-word  
	
	interface Vlanif3812
	mpls l2vc 10.238.1.2 3812 control-word  
	} ]
	
	set cli_cfg_R3_config [ subst {
	config t
	router bgp 60000
	neighbor 202.77.1.1 peer-group rrc
	address-family vpnv4 
	neighbor 202.77.1.1 activate 
	address-family vpnv6 
	neighbor 202.77.1.1 activate 
	address-family ipv6  
	neighbor 202.77.1.1 activate 
	exit
	exit
	} ]
	set cli_cfg_R4_config [ subst {
	config t
	router bgp 60000
	neighbor 202.77.1.1 peer-group rrc
	address-family vpnv4 
	neighbor 202.77.1.1 activate 
	address-family vpnv6 
	neighbor 202.77.1.1 activate 
	address-family ipv6  
	neighbor 202.77.1.1 activate 
	exit
	exit
	} ]
	set cli_cfg_101_config [ subst {
	interface g 0/0/47
	undo port trunk allow vlan 3 to 5
	quit
	} ]
   	CasaLoadCliConfig -verifyShow disabled -prompt Casa -upvar cli_cfg_CMTS_vpws_config -fd $::spawn_cmts
	SendAndExpect "clear cable modem reset \ryes\r" --  -prompt casa -fd $::spawn_cmts -timeout $timeout
	CasaLoadCliConfig -verifyShow disabled -prompt Casa -upvar cli_cfg_ASR_vpws_config -fd $::spawn_asr
	SendAndExpect "commit\r" --  -prompt casa -fd $::spawn_asr -timeout $timeout
	for {set i 1} { $i < 12} {incr i} {
	set j [expr (3800+$i)]
	SendAndExpect "clear configuration interface vlan $j\ryes\r" --  -prompt casa -fd $::spawn_switch202 -timeout $timeout
	SendAndExpect "interface vlan $j\r" -- -prompt casa  -fd $::spawn_switch202	-timeout $timeout
	SendAndExpect "undo shutdown \r" -- -fd $::spawn_switch202  -prompt casa -timeout $timeout
	}
	CasaLoadCliConfig -verifyShow disabled -prompt Casa -upvar cli_cfg_202_vpws_config -fd $::spawn_switch202
	CasaLoadCliConfig -verifyShow disabled -prompt Casa -upvar cli_cfg_101_config -fd $::spawn_switch101
	CasaLoadCliConfig -verifyShow disabled -prompt Casa -upvar cli_cfg_R3_config -fd $::spawn_R3
	CasaLoadCliConfig -verifyShow disabled -prompt Casa -upvar cli_cfg_R4_config -fd $::spawn_R4
	# HAroute_creat_mplsl2vpn
	return 0
}
