<center><h1> PVE_Status_Tools </center>

<hr>

![](https://github.com/iKoolCore/PVE_Status_Tools/blob/main/images/pve_status.png?raw=true)

<hr>

#### 一、安装方法：

> 注意:需要使用`root`身份执行下面代码

*在终端中按行分别执行以下代码：*
```
export LC_ALL=en_US.UTF-8
apt update && apt -y install git && git clone https://github.com/iKoolCore/PVE_Status_Tools.git
cd PVE_Status_Tools
bash ./PVE_Status_Tools.sh
```

**或**  *直接执行下面一行代码：*
```
wget -qO-  https://raw.githubusercontent.com/iKoolCore/PVE_Status_Tools/main/PVE_Status_Tools.sh | bash
```
#### 二、还原方法：
方法① ：
用压缩包中对应文件`（PVE 7.2-3）`的原版覆盖，再重启 `pveproxy服务`： <br>
```
systemctl restart pveproxy
```
~~方法② ：~~ `因部分网络环境无法联网安装，弃用此联网重装方式，采用下面离线正则修改方式` <br>
~~执行命令重新安装 `proxmox-widget-toolkit` 和 `pve-manager` <br>~~

```
apt reinstall proxmox-widget-toolkit && systemctl restart pveproxy.service   #还原订阅提示并重启服务
apt reinstall pve-manager && systemctl restart pveproxy   #还原概要页面并重启服务
```
方法②：
运行以下四条命令（适用于已经改过概要信息，还原成默认的概要信息）：
```
sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;s/my $dinfo = df/\n\t&/' /usr/share/perl5/PVE/API2/Nodes.pm
sed -i '/pveversion/,/^\s\+],/!b;//!d;s/^\s\+],/\t    value: '"'"''"'"',\n\t},\n&/' /usr/share/pve-manager/js/pvemanagerlib.js
sed -i '/widget.pveNodeStatus/,/},/ { s/height: [0-9]\+/height: 300/; /textAlign/d}' /usr/share/pve-manager/js/pvemanagerlib.js
systemctl restart pveproxy
```


#### 三、相关资源：

 [PVE暗黑主题 ｜ PVEDiscordDark ](https://github.com/Weilbyte/PVEDiscordDark) thanks to [Weilbyte](https://github.com/Weilbyte)
 [![](https://ikoolcore.oss-cn-shenzhen.aliyuncs.com/Banner1.png)](https://item.taobao.com/item.htm?ft=t&id=682025492099)

