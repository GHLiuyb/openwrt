local SYS = require "luci.sys"

m = Map("dnsfilter")
m.title = translate("DNS Filter")
m.description = translate("Support AdGuardHome/Host/DNSMASQ/Domain Rules")
m:section(SimpleSection).template = "dnsfilter/dnsfilter_status"

s = m:section(TypedSection, "dnsfilter")
s.anonymous = true

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty = false

o = s:option(Flag, "block_ios", translate("Block Apple iOS OTA update"))
o.rmempty = false
o.default = 0

o = s:option(Flag, "block_cnshort", translate("Block CNshort APP and Website"))
o.rmempty = false
o.default = 0

o = s:option(Flag, "safe_search", translate("Safe Search"))
o.description = translate("Enforcing SafeSearch for Google Bing Duckduckgo Yandex and Youtube.")
o.rmempty = false
o.default = 0

o = s:option(Flag, "cron_mode", translate("Enable automatic update rules"))
o.rmempty = false
o.default = 1

o = s:option(ListValue, "time_update", translate("Update time (every day)"))
for s = 0,23 do
o:value(s, s .. ':00')
end
o.default = 6
o:depends("cron_mode",1)

tmp_rule = 0
if nixio.fs.access("/tmp/dnsfilter/rules.conf") then
tmp_rule = 1
UD = SYS.exec("cat /tmp/dnsfilter/dnsfilter.updated 2>/dev/null")
rule_count = tonumber(SYS.exec("find /tmp/dnsfilter -exec cat {} \\; 2>/dev/null | wc -l"))
o = s:option(DummyValue, "1", translate("Subscribe Rules Data"))
o.rawhtml = true
o.template = "dnsfilter/dnsfilter_refresh"
o.value = rule_count.." "..translate("Records")
o.description = string.format(translate("AdGuardHome / Host / DNSMASQ / Domain rules auto-convert").."<br/><strong>"..translate("Last Update Checked")..":</strong> %s<br/>",UD)
end

o = s:option(Flag, "flash", translate("Save rules to flash"))
o.description = translate("Should be enabled when rules addresses are slow to download")
o.rmempty = false
o.default = 0

if tmp_rule==1 then
o = s:option(Button, "delete", translate("Delete All Subscribe Rules"))
o.inputstyle = "reset"
o.description = translate("Delete rules files and delete the subscription link<br/>There is no need to click for modify the subscription link,The script will automatically replace the old rule file")
o.write = function()
	SYS.exec("[ -d /etc/dnsfilter/rules ] && rm -rf /etc/dnsfilter/rules")
	SYS.exec("grep -wq 'list url' /etc/config/dnsfilter && sed -i '/list url/d' /etc/config/dnsfilter && /etc/init.d/dnsfilter restart 2>&1 &")
	luci.http.redirect(luci.dispatcher.build_url("admin","services","dnsfilter","base"))
end
end

if luci.sys.call("[ -h /tmp/dnsfilter/url ] || exit 9")==9 then
	if nixio.fs.access("/etc/dnsfilter/rules") then
		o = s:option(Button, "delete_1", translate("Delete Subscribe Rules On The Flash"))
		o.inputstyle = "reset"
		o.write = function()
			SYS.exec("rm -rf /etc/dnsfilter/rules")
			luci.http.redirect(luci.dispatcher.build_url("admin","services","dnsfilter","base"))
		end
	end
end

o = s:option(DynamicList, "url", translate("Anti-AD Rules Subscribe"))
o:value("https://cdn.jsdelivr.net/gh/privacy-protection-tools/anti-AD@master/adblock-for-dnsmasq.conf", translate("anti-AD"))
o:value("https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt", translate("AdGuard"))
o:value("https://easylist-downloads.adblockplus.org/easylistchina+easylist.txt", translate("Easylistchina+Easylist"))
o:value("https://block.energized.pro/extensions/porn-lite/formats/domains.txt", translate("Anti-Porn"))
o.default = "https://cdn.jsdelivr.net/gh/privacy-protection-tools/anti-AD@master/adblock-for-dnsmasq.conf"

return m
