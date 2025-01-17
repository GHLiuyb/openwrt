#!/bin/sh
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh

LOG_FILE="/tmp/openclash.log"
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))
dns_advanced_setting=$(uci -q get openclash.config.dns_advanced_setting)
core_type=$(uci -q get openclash.config.core_type)

if [ -n "$(ruby_read "$5" "['tun']")" ]; then
   uci -q set openclash.config.config_reload=0
else
   if [ -n "${11}" ]; then
      uci -q set openclash.config.config_reload=0
   fi
fi

if [ -z "${11}" ]; then
   en_mode_tun=0
else
   en_mode_tun=${11}
fi

if [ -z "${12}" ]; then
   stack_type=system
else
   stack_type=${12}
fi

if [ "${22}" != "1" ]; then
   enable_geoip_dat="false"
else
   enable_geoip_dat="true"
fi

if [ "$(ruby_read "$5" "['external-controller']")" != "$controller_address:$3" ]; then
   uci -q set openclash.config.config_reload=0
fi
    
if [ "$(ruby_read "$5" "['secret']")" != "$2" ]; then
   uci -q set openclash.config.config_reload=0
fi

if [ "$core_type" != "TUN" ] && [ "${10}" == "script" ]; then
   rule_mode="rule"
   uci -q set openclash.config.proxy_mode="$rule_mode"
   uci -q set openclash.config.router_self_proxy="1"
   LOG_OUT "Warning: Only TUN Core Support Script Mode, Switch To The Rule Mode!"
else
   rule_mode="${10}"
fi

uci commit openclash

ruby -ryaml -E UTF-8 -e "
begin
   Value = YAML.load_file('$5');
rescue Exception => e
   puts '${LOGTIME} Error: Load File Failed,【' + e.message + '】'
end
begin
   Value['redir-port']=$4;
   Value['tproxy-port']=${15};
   Value['port']=$7;
   Value['socks-port']=$8;
   Value['mixed-port']=${14};
   Value['mode']='$rule_mode';
   Value['log-level']='$9';
   Value['allow-lan']=true;
   Value['external-controller']='0.0.0.0:$3';
   Value['secret']='$2';
   Value['bind-address']='*';
   Value['external-ui']='/usr/share/openclash/dashboard';
if ${21} == 1 then
   Value['geodata-mode']=$enable_geoip_dat;
   Value['geodata-loader']='${23}';
else
   if Value.key?('geodata-mode') then
      Value.delete('geodata-mode')
   end
   if Value.key?('geodata-loader') then
      Value.delete('geodata-loader')
   end
end
if not Value.key?('dns') then
   Value_1={'dns'=>{'enable'=>true}}
   Value['dns']=Value_1['dns']
else
   Value['dns']['enable']=true
end;
if $6 == 1 then
   Value['ipv6']=true
else
   Value['ipv6']=false
end;
if ${16} == 1 then
   Value['dns']['ipv6']=true
else
   Value['dns']['ipv6']=false
end;
if ${19} != 1 then
   Value['dns']['enhanced-mode']='$1';
else
   Value['dns']['enhanced-mode']='fake-ip';
end;
if '$1' == 'fake-ip' or ${19} == 1 then
   Value['dns']['fake-ip-range']='198.18.0.1/16'
else
   Value['dns'].delete('fake-ip-range')
end;
Value['dns']['listen']='0.0.0.0:${13}'
if ${21} == 1 then
   Value_sniffer={'sniffer'=>{'enable'=>true}};
   Value['sniffer']=Value_sniffer['sniffer'];
   Value_sniffer={'sniffing'=>['tls']}
   Value['sniffer'].merge!(Value_sniffer)
   if File::exist?('/etc/openclash/custom/openclash_force_sniffing_domain.yaml') and ${24} == 1 then
     Value_7 = YAML.load_file('/etc/openclash/custom/openclash_force_sniffing_domain.yaml')
     if Value_7 != false and not Value_7['force-domain'].to_a.empty? then
        Value['sniffer']['force-domain']=Value_7['force-domain']
        Value['sniffer']['force-domain']=Value['sniffer']['force-domain'].uniq
     end
   end
   if File::exist?('/etc/openclash/custom/openclash_sniffing_domain_filter.yaml') and ${24} == 1 then
     Value_7 = YAML.load_file('/etc/openclash/custom/openclash_sniffing_domain_filter.yaml')
     if Value_7 != false and not Value_7['skip-sni'].to_a.empty? then
        Value['sniffer']['skip-sni']=Value_7['skip-sni']
        Value['sniffer']['skip-sni']=Value['sniffer']['skip-sni'].uniq
     end
   end
else
   if Value.key?('sniffer') then
      Value.delete('sniffer')
   end
end;
Value_2={'tun'=>{'enable'=>true}};
if $en_mode_tun != 0 then
   Value['tun']=Value_2['tun']
   Value['tun']['stack']='$stack_type'
   if ${20} == 1 then
      Value['tun']['device']='utun'
   end
   Value['tun']['auto-route']=false
   Value['tun']['auto-detect-interface']=false
   Value_2={'dns-hijack'=>['tcp://8.8.8.8:53','tcp://8.8.4.4:53']}
   Value['tun'].merge!(Value_2)
else
   if Value.key?('tun') then
      Value.delete('tun')
   end
end;
if Value.key?('iptables') then
   Value.delete('iptables')
end;
if not Value.key?('profile') then
   Value_3={'profile'=>{'store-selected'=>true}}
   Value['profile']=Value_3['profile']
else
   Value['profile']['store-selected']=true
end;
if ${17} != 1 then
   Value['profile']['store-fake-ip']=false
else
   Value['profile']['store-fake-ip']=true
end;
rescue Exception => e
puts '${LOGTIME} Error: Set General Failed,【' + e.message + '】'
end
begin
#添加自定义Hosts设置
if File::exist?('/etc/openclash/custom/openclash_custom_hosts.list') then
   Value_3 = YAML.load_file('/etc/openclash/custom/openclash_custom_hosts.list')
   if Value_3 != false then
      Value['dns']['use-hosts']=true
      if Value.has_key?('hosts') and not Value['hosts'].to_a.empty? then
         Value['hosts'].merge!(Value_3)
         Value['hosts'].uniq
      else
         Value['hosts']=Value_3
      end
   end
end
rescue Exception => e
puts '${LOGTIME} Error: Set Hosts Rules Failed,【' + e.message + '】'
end
begin
#fake-ip-filter
if '$1' == 'fake-ip' then
   if File::exist?('/tmp/openclash_fake_filter.list') then
     Value_4 = YAML.load_file('/tmp/openclash_fake_filter.list')
     if Value_4 != false and not Value_4['fake-ip-filter'].to_a.empty? then
        if Value['dns'].has_key?('fake-ip-filter') and not Value['dns']['fake-ip-filter'].to_a.empty? then
           Value_5 = Value_4['fake-ip-filter'].reverse!
           Value_5.each{|x| Value['dns']['fake-ip-filter'].insert(-1,x)}
        else
           Value['dns']['fake-ip-filter']=Value_4['fake-ip-filter']
        end
        Value['dns']['fake-ip-filter']=Value['dns']['fake-ip-filter'].uniq
     end
   end
   if ${18} == 1 then
      if Value['dns'].has_key?('fake-ip-filter') and not Value['dns']['fake-ip-filter'].to_a.empty? then
         Value['dns']['fake-ip-filter'].insert(-1,'+.nflxvideo.net')
         Value['dns']['fake-ip-filter'].insert(-1,'+.media.dssott.com')
         Value['dns']['fake-ip-filter']=Value['dns']['fake-ip-filter'].uniq
      else
         Value['dns'].merge!({'fake-ip-filter'=>['+.nflxvideo.net', '+.media.dssott.com']})
      end
   end
elsif ${19} == 1 then
   if Value['dns'].has_key?('fake-ip-filter') and not Value['dns']['fake-ip-filter'].to_a.empty? then
      Value['dns']['fake-ip-filter'].insert(-1,'+.*')
      Value['dns']['fake-ip-filter']=Value['dns']['fake-ip-filter'].uniq
   else
      Value['dns'].merge!({'fake-ip-filter'=>['+.*']})
   end
end;
rescue Exception => e
puts '${LOGTIME} Error: Set Fake-IP-Filter Failed,【' + e.message + '】'
end
begin
#nameserver-policy
if '$dns_advanced_setting' == '1' then
   if File::exist?('/etc/openclash/custom/openclash_custom_domain_dns_policy.list') then
     Value_6 = YAML.load_file('/etc/openclash/custom/openclash_custom_domain_dns_policy.list')
     if Value_6 != false then
        if Value['dns'].has_key?('nameserver-policy') and not Value['dns']['nameserver-policy'].to_a.empty? then
           Value['dns']['nameserver-policy'].merge!(Value_6)
           Value['dns']['nameserver-policy'].uniq
        else
           Value['dns']['nameserver-policy']=Value_6
        end
     end
  end
end;
rescue Exception => e
puts '${LOGTIME} Error: Set Nameserver-Policy Failed,【' + e.message + '】'
ensure
File.open('$5','w') {|f| YAML.dump(Value, f)}
end" 2>/dev/null >> $LOG_FILE
