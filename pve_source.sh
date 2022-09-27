#!/usr/bin/env bash

Script_Version="V1.0-Alpha"
Script_Build="20220927-001"

# 系统环境变量
export LANG=en_US.UTF-8

echoContent() {
    case $1 in
    # 红色
    "red")
        # shellcheck disable=SC2154
        ${echoType} "\033[31m${printN}$2 \033[0m"
        ;;
        # 天蓝色
    "skyBlue")
        ${echoType} "\033[1;36m${printN}$2 \033[0m"
        ;;
        # 绿色
    "green")
        ${echoType} "\033[32m${printN}$2 \033[0m"
        ;;
        # 白色
    "white")
        ${echoType} "\033[37m${printN}$2 \033[0m"
        ;;
    "magenta")
        ${echoType} "\033[31m${printN}$2 \033[0m"
        ;;
        # 黄色
    "yellow")
        ${echoType} "\033[33m${printN}$2 \033[0m"
        ;;
    esac
}

# 初始化全局变量
initVar() {
	installType='apt -y install'
	reinstallType='apt -y reinstall'
	update="apt update"
	upgrade="apt upgrade -y"
	distupgrade="apt dist-upgrade -y"

	updateReleaseInfoChange='apt-get --allow-releaseinfo-change update'
	removeType='apt -y autoremove'
	echoType='echo -e'

	# 安装总进度
	totalProgress=1

	# 运行模式
	Auto="No"

    # 版本判断
    pveVersionJudge
}

# Proxmox 版本判断
pveVersionJudge() {
    # 读取当前 PVE 版本号
    proxmox_ver="$(pveversion -v | grep proxmox-ve | awk '{print $2}')"
    proxmox_main_ver="${proxmox_ver%%-*}"

    # 版本号比较
    function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
    function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
    function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
    function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }
}

# 更换 Proxmox 软件源
pveSoftSource_menu() {
    pveSoftSource() {
		local domian_url="$1"
        echo "deb "https://${domian_url}" bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
        echoContent green " ---> 更换 Proxmox 软件源完成"

        # 删除 Proxmox 企业源
        if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
            rm -rf /etc/apt/sources.list.d/pve-enterprise.list
    	    echoContent green " ---> 删除 Proxmox 企业源完成"
        fi

        wget -qc -t 5 https://mirrors.ustc.edu.cn/proxmox/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg		
    }
    while :
    do
    	echoContent skyBlue "\n进度  $1/${totalProgress} : 更换 Proxmox 软件源"
        echoContent red "\n=============================================================="
        echoContent yellow "1.中国科技大学源"
        echoContent yellow "2.清华大学源"
        echoContent yellow "3.南京大学源"
        echoContent yellow "0.跳过"
        echoContent red "=============================================================="
        read -r -p "请选择:" pveSoftNewSource
        case ${pveSoftNewSource} in
            1)
                domian_url="mirrors.ustc.edu.cn/proxmox/debian/pve"
                pveSoftSource ${domian_url}
    			break
                ;;
            2)
                domian_url="mirrors.tuna.tsinghua.edu.cn/proxmox/debian"
                pveSoftSource ${domian_url}
    			break
                ;;
            3)
                domian_url="mirrors.nju.edu.cn/proxmox/debian"
                pveSoftSource ${domian_url}
    			break
                ;;
            0)
    			break
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
    done
}

# 更换 Proxmox Debian 源
pveDebianSource_menu() {
    pveDebianSource() {
		local domian_url="$1"
        cat >/etc/apt/sources.list<<EOF
deb https://${domian_url}/debian/ bullseye main contrib non-free
deb https://${domian_url}/debian/ bullseye-updates main contrib non-free
deb https://${domian_url}/debian/ bullseye-backports main contrib non-free
deb https://${domian_url}/debian-security bullseye-security main contrib non-free
deb-src https://${domian_url}/debian/ bullseye main contrib non-free
deb-src https://${domian_url}/debian/ bullseye-updates main contrib non-free
deb-src https://${domian_url}/debian/ bullseye-backports main contrib non-free
deb-src https://${domian_url}/debian-security bullseye-security main contrib non-free
EOF
        echoContent green " ---> 更换 Proxmox Debian 源完成"
	}

    while :
    do
    	echoContent skyBlue "\n进度  $1/${totalProgress} : 更换 Proxmox Debian 源"
        echoContent red "\n=============================================================="
        echoContent yellow "1.中国科技大学源"
        echoContent yellow "2.清华大学源"
        echoContent yellow "3.南京大学源"
        echoContent yellow "4.阿里云源"
        echoContent yellow "5.腾讯云源"
        echoContent yellow "6.华为源"
        echoContent yellow "7.网易源"
        echoContent yellow "0.跳过"
        echoContent red "=============================================================="
        read -r -p "请选择:" pveDebianNewSource
        case ${pveDebianNewSource} in
            1)
                domian_url="mirrors.ustc.edu.cn"
				pveDebianSource ${domian_url}
				break
                ;;
            2)
                domian_url="mirrors.tuna.tsinghua.edu.cn"
				pveDebianSource ${domian_url}
				break
                ;;
            3)
                domian_url="mirrors.nju.edu.cn"
				pveDebianSource ${domian_url}
				break
                ;;
            4)
                domian_url="mirrors.aliyun.com"
				pveDebianSource ${domian_url}
				break
                ;;
            5)
                domian_url="mirrors.cloud.tencent.com"
				pveDebianSource ${domian_url}
				break
                ;;
            6)
                domian_url="repo.huaweicloud.com"
				pveDebianSource ${domian_url}
				break
                ;;
            7)
                domian_url="mirrors.163.com"
				pveDebianSource ${domian_url}
				break
                ;;
            0)
				break
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
	done
}

# 更换 Proxmox Ceph 源
pveCephSource() {
	echoContent skyBlue "\n功能  $1/${totalProgress} : 更换 Proxmox Ceph 源"
    echoContent red "\n=============================================================="
    echoContent yellow "1.中国科技大学源"
    echoContent red "=============================================================="
    read -r -p "请选择:" pveCephNewSource
    case ${pveCephNewSource} in
        1)
            rm -rf /etc/apt/sources.list.d/ceph.list
            domian_url="mirrors.ustc.edu.cn"
            sed -i.bak "s#http://[^\]\+/debian#https://$domian_url/proxmox/debian#g" /usr/share/perl5/PVE/CLI/pveceph.pm
            echoContent green " ---> 更换 Proxmox Ceph 源完成"
            ;;
        *)
            echoContent red " ---> 选择错误"
            exit 0
            ;;
    esac
}

# 更换 Proxmox LXC 仓库源
pveLXCSource() {
	echoContent skyBlue "\n进度  $1/${totalProgress} : 更换 Proxmox LXC 仓库源"
    echoContent red "\n=============================================================="
    echoContent yellow "1.中国科技大学源"
    echoContent yellow "2.清华大学源"
    echoContent yellow "3.南京大学源"
    echoContent red "=============================================================="
    read -r -p "请选择:" pveLXCNewSource
    case ${pveLXCNewSource} in
        1)
            domian_url="mirrors.ustc.edu.cn"
            ;;
        2)
            domian_url="mirrors.tuna.tsinghua.edu.cn"
            ;;
        3)
            domian_url="mirrors.nju.edu.cn"
            ;;
        *)
            echoContent red " ---> 选择错误"
            exit 0
            ;;
    esac

    sed -i.bak "s#http://[^\]\+/images#https://$domian_url/proxmox/images#g" /usr/share/perl5/PVE/APLInfo.pm
    wget -O /var/lib/pve-manager/apl-info/$domian_url https://$domian_url/proxmox/images/aplinfo-pve-7.dat
    systemctl restart pvedaemon
    echoContent green " ---> 更换 Proxmox LXC 仓库源完成"
}


# 设置 DNS
set_DNS() {
	echoContent skyBlue "\n进度  $i/${totalProgress} : 设置 Proxmox 系统 DNS"
	echoContent red "\n=============================================================="
	echoContent yellow "# 注意事项\n"
	echoContent yellow "DNS 错误会导致系统更新失败等网络问题\n"

	echoContent red "=============================================================="

    local DNS=""
    local content="search lan"
    for i in {1..3};do
        while :
        do
            read -r -p "请输入 DNS$i (输入 skip 跳过): " IP
            case $IP in
                skip)
                    eval DNS$i=""
                    echoContent red " ---> DNS$i 跳过输入"
                    break
                    ;;
                *)
                    VALID_CHECK=$(echo ${IP}|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
                    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
                        if [ ${VALID_CHECK:-no} == "yes" ]; then
                            eval DNS$i=${IP}
                            echoContent green " ---> DNS$i：${IP}"
                            break
                        else
                            echoContent red " ---> DNS$i IP 地址错误，请重新输入"
                        fi
                    else
                        echoContent red " ---> DNS$i IP 格式错误，请重新输入"
                    fi
                    ;;
            esac
        done

        if [ -n "$(eval echo \$DNS$i)" ]; then
            tmp="nameserver \$DNS$i"
            DNS="$DNS'\n'$tmp"
        fi
    done

    if [ -n "$DNS" ]; then
        content="$content$DNS"
        eval echo -e "$content" > /etc/resolv.conf
    fi
    echoContent green " ---> DNS 设置完成"
}

# 去除无效订阅源提示
remove_void_soucre_tips() {
	echoContent skyBlue "\n进度  $1/${totalProgress} : 去除无效订阅源提示"
    sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
    systemctl restart pveproxy

    echoContent green " ---> 去除无效订阅源提示完成，请使用 Shift + F5 手动刷新 PVE Web 页面"
}


pveAuto() {
    #设置 DNS
	echoContent skyBlue "\n进度  1/${totalProgress} : 设置 Proxmox VE 的系统 DNS\n"
	echoContent skyBlue "            DNS1 223.5.5.5"
	echoContent skyBlue "            DNS2 8.8.8.8"
	echoContent skyBlue "            DNS3 1.1.1.1\n"
    cat >/etc/resolv.conf<<'EOF'
search lan
nameserver 223.5.5.5
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
    echoContent green " ---> DNS 设置完成"

    # 更换 Proxmox 软件源
	echoContent skyBlue "\n进度  2/${totalProgress} : 更换 Proxmox 软件源为中科大源\n"
    domian_url="mirrors.ustc.edu.cn"
    echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
    echoContent green " ---> 更换 Proxmox 软件源完成"

    # 删除 Proxmox 企业源
    if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
        rm -rf /etc/apt/sources.list.d/pve-enterprise.list
    fi

    wget -qc -t 5 https://mirrors.ustc.edu.cn/proxmox/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg

    # 更换 Proxmox Debian 源
	echoContent skyBlue "\n进度  3/${totalProgress} : 更换 Proxmox Debian 源"
    cat >/etc/apt/sources.list<<EOF
deb https://$domian_url/debian/ bullseye main contrib non-free
deb https://$domian_url/debian/ bullseye-updates main contrib non-free
deb https://$domian_url/debian/ bullseye-backports main contrib non-free
deb https://$domian_url/debian-security bullseye-security main contrib non-free
deb-src https://$domian_url/debian/ bullseye main contrib non-free
deb-src https://$domian_url/debian/ bullseye-updates main contrib non-free
deb-src https://$domian_url/debian/ bullseye-backports main contrib non-free
deb-src https://$domian_url/debian-security bullseye-security main contrib non-free
EOF
    echoContent green " ---> 更换 Proxmox Debian 源完成"

    # 更换 Proxmox Ceph 源
	echoContent skyBlue "\n进度  4/${totalProgress} : 更换 Proxmox Ceph 源"
    rm -rf /etc/apt/sources.list.d/ceph.list
    sed -i.bak "s#http://[^\]\+/debian#https://$domian_url/proxmox/debian#g" /usr/share/perl5/PVE/CLI/pveceph.pm
    echoContent green " ---> 更换 Proxmox Ceph 源完成"

    # 更换 Proxmox LXC 仓库源
	echoContent skyBlue "\n进度  5/${totalProgress} : 更换 Proxmox LXC 仓库源"
    sed -i.bak "s#http://[^\]\+/images#https://$domian_url/proxmox/images#g" /usr/share/perl5/PVE/APLInfo.pm
    wget -O /var/lib/pve-manager/apl-info/$domian_url https://$domian_url/proxmox/images/aplinfo-pve-7.dat > /dev/null 2>&1
    systemctl restart pvedaemon > /dev/null 2>&1
    echoContent green " ---> 更换 Proxmox LXC 仓库源完成"

    # 更新系统
	echoContent skyBlue "\n进度  6/${totalProgress} : 更新系统"
    ${update} > /dev/null 2>&1
    ${distupgrade} > /dev/null 2>&1
    echoContent green " ---> 系统更新完成"
}

# 一键设定 DNS、换源并更新系统确认菜单
pveAuto_menu() {
    echoContent skyBlue "\n功能 1/${totalProgress} : 一键设定 DNS、换源并更新系统"
	echoContent red "\n=============================================================="
	echoContent yellow "# 注意事项\n"
    echoContent yellow "1.当前 Proxmox VE 版本为 $proxmox_ver"
    echoContent yellow "2.使用本功能会将系统(包括内核)升级到最新版\n"

	echoContent red "=============================================================="
    while :
    do
        read -r -p '是否开始一键设定 DNS、换源并更新系统 (Y/n)？ : ' pveAutochoose
        case $pveAutochoose in
            y)
                totalProgress=6
                pveAuto && case_read
				break
                ;;
			n)
				break
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
	done
}

# 更换源
change_source_menu() {
    while :
    do
        echoContent skyBlue "\n功能 1/${totalProgress} : 更换软件源"
        echoContent red "\n=============================================================="
        echoContent yellow "1.更换 PVE 软件源 + Debian 源"
        echoContent yellow "2.更换 PVE Ceph 源"
        echoContent yellow "3.更换 PVE LXC 仓库源"
        echoContent yellow "0.返回"
        echoContent red "=============================================================="
        read -r -p "请选择:" selectNewSource
        case ${selectNewSource} in
            1)
                totalProgress=2
                pveSoftSource_menu 1 && pveDebianSource_menu 2
                ${upgrade}
                echoContent green " ---> 更新数据库完成"
                case_read
                break
                ;;
            2)
                totalProgress=1
                pveCephSource 1 && case_read
                break
                ;;
            3)
                totalProgress=1
                pveLXCSource 1 && case_read
                break
                ;;
            0)
                break
                ;;
            *)
                echoContent red " ---> 选择错误"
                exit 0
                ;;
        esac
	done
}

pveInfo() {
    local cpuProcess_Freq="$1"
    local cpuCore_Temp="$2"
    local storage_Info="$3"
    local textAlign_right="$4"

    # 检查并安装工具包
    if [[ -z $(which sensors) || -z $(which sensors) ]]; then
        ${updateReleaseInfoChange} >/dev/null 2>&1
        if [ -z $(which sensors) ]; then
            echoContent green " ---> 安装 lm-sensors"
            process_line '进度' '安装'
            ${installType} lm-sensors > /dev/null 2>&1
            if [ -z $(which sensors) ]; then
                echoContent red " ---> lm-sensors 安装失败，请检查 PVE 软件源及网络的连通性、DNS有效性后重试"
            else
                echoContent red " ---> lm-sensors 安装完成"
            fi
        fi

        if [ -z $(which iostat) ]; then
            echoContent green " ---> 安装 sysstat"
            process_line '进度' '安装'
            ${installType} sysstat > /dev/null 2>&1
            if [ -z $(which iostat) ]; then
                echoContent red " ---> sysstat 安装失败，请检查 PVE 软件源及网络的连通性、DNS有效性后重试"
            else
                echoContent red " ---> sysstat 安装完成"
            fi
        fi
    fi

    # 设定工具权限
    if [ -n $(which sensors) ]; then
        chmod +s /usr/sbin/smartctl
    fi
    if [ -n $(which iostat) ]; then
        chmod +s /usr/bin/iostat
    fi

    cpu_degree="$(sensors | grep -E 'coretemp-isa|k10temp-pci' | wc -l)"

    # CPU 主频及温度等信息 API
    cpu_info_api='		
	my $cpufreqs = `lscpu | grep MHz`;
	my $corefreqs = `cat /proc/cpuinfo | grep -i  "cpu MHz"`;
	$res->{cpu_frequency} = $cpufreqs . $corefreqs;

    $res->{cpu_temperatures} = `sensors`;
		'

    # CPU 主频信息 Web UI
    if [[ "${cpuProcess_Freq}" == "y" ]]; then
        process_degree="$(cat /proc/cpuinfo | grep -i "cpu MHz" | wc -l)"
        cpu_freq_display=',
	{
	    itemId: '"'"'cpu-frequency'"'"',
	    colspan: 2,
	    printBar: false,
	    title: gettext('"'"'CPU主频'"'"'),
	    textField: '"'"'cpu_frequency'"'"',
	    renderer:function(value){
	        let output = '"'"''"'"';
	        let cpufreqs = value.matchAll(/^CPU MHz.*?(\d+\.\d+)\\n^CPU max MHz.*?(\d+)\.\d+\\n^CPU min MHz.*?(\d+)\.\d+\\n/gm);
	            for (const cpufreq of cpufreqs) {
	                output += `实时: ${cpufreq[1]} MHz | 最低: ${cpufreq[3]} MHz | 最高: ${cpufreq[2]} MHz\\n`;
	            }

	        let corefreqs = value.match(/^cpu MHz.*?(\d+\.\d+)/gm);
	        if (corefreqs.length > 0) {
	            for (i = 1;i < corefreqs.length;) {
	                for (const corefreq of corefreqs) {
	                    output += `线程 ${i++}: ${corefreq.match(/(?<=:\s+)(\d+\.\d+)/g)} MHz`;
	                    output += '"'"' | '"'"';
	                    if ((i-1) % 4 == 0){
	                        output = output.slice(0, -2);
	                        output += '"'"'\\n'"'"';
	                    }
	                }
	            }
	        }
	        return output.replace(/\\n/g, '"'"'<br>'"'"');
	    }
	},'
    elif [[ "${cpuProcess_Freq}" == "n" ]]; then
        process_degree="0"
        cpu_freq_display=',
	{
	    itemId: '"'"'cpu-frequency'"'"',
	    colspan: 2,
	    printBar: false,
	    title: gettext('"'"'CPU主频'"'"'),
	    textField: '"'"'cpu_frequency'"'"',
	    renderer:function(value){
	        let output = '"'"''"'"';
	        let cpufreqs = value.matchAll(/^CPU MHz.*?(\d+\.\d+)\\n^CPU max MHz.*?(\d+)\.\d+\\n^CPU min MHz.*?(\d+)\.\d+\\n/gm);
	            for (const cpufreq of cpufreqs) {
	                output += `实时: ${cpufreq[1]} MHz | 最低: ${cpufreq[3]} MHz | 最高: ${cpufreq[2]} MHz\\n`;
	            }
	        return output.replace(/\\n/g, '"'"'<br>'"'"');
	    }
	},'
    fi
    cpu_freq_degree="$[cpu_degree + (process_degree+4-1)/4]"
    cpu_freq_height="$[cpu_freq_degree*17+7]"

    # CPU 温度信息 Web UI
    if [[ "${cpuCore_Temp}" == "y" ]]; then
        core_degree="$(sensors | grep Core | wc -l)"
        cpu_temp_display='
	{
	    itemId: '"'"'cpu-temperatures'"'"',
	    colspan: 2,
	    printBar: false,
	    title: gettext('"'"'CPU温度'"'"'),
	    textField: '"'"'cpu_temperatures'"'"',
	    renderer: function(value) {
	        value = value.replace(/Â/g, '"'"''"'"');
	        let data = [];
	        let cpus = value.matchAll(/^(?:coretemp-isa|k10temp-pci)-(\w{4})$\\n.*?\\n((?:Package|Core|Tctl)[\s\S]*?^\\n)+/gm);
	        for (const cpu of cpus) {
	            let cpuNumber = 0;
	            data[cpuNumber] = {
	                   packages: [],
	                   cores: []
	            };

	            let packages = cpu[2].matchAll(/^(?:Package id \d+|Tctl):\s*\+([^°]+).*$/gm);
	            for (const package of packages) {
	                data[cpuNumber]['"'"'packages'"'"'].push(package[1]);
	            }

	            let cores = cpu[2].matchAll(/^Core \d+:\s*\+([^°]+).*$/gm);
	            for (const core of cores) {
	                data[cpuNumber]['"'"'cores'"'"'].push(core[1]);
	            }
	        }

	        let output = '"'"''"'"';
	        for (const [i, cpu] of data.entries()) {
	            if (cpu.packages.length > 0) {
	                for (const packageTemp of cpu.packages) {
	                    output += `CPU ${i+1}: ${packageTemp}°C `;
	                }
	            }

	            if (cpu.cores.length > 0 && cpu.cores.length <= 4) {
	                output += '"'"'('"'"';
	                for (j = 1;j < cpu.cores.length;) {
	                    for (const coreTemp of cpu.cores) {
	                        output += `核心 ${j++}: ${coreTemp}°C, `;
	                    }
	                }
	                output = output.slice(0, -2);
	                output += '"'"')'"'"';
	            }

	            let gpus = value.matchAll(/^amdgpu-pci-(\d*)$\\n((?!edge:)[ \S]*?\\n)*((?:edge)[\s\S]*?^\\n)+/gm);
	            for (const gpu of gpus) {
	                let gpuNumber = 0;
	                data[gpuNumber] = {
	                       edges: []
	                };

	                let edges = gpu[3].matchAll(/^edge:\s*\+([^°]+).*$/gm);
	                for (const edge of edges) {
	                    data[gpuNumber]['"'"'edges'"'"'].push(edge[1]);
	                }

	                for (const [k, gpu] of data.entries()) {
	                    if (gpu.edges.length > 0) {
	                        output += '"'"' | 核显: '"'"';
	                        for (const edgeTemp of gpu.edges) {
	                            output += `${edgeTemp}°C, `;
	                        }
	                        output = output.slice(0, -2);
	                    }
	                }
	            }

	            let acpitzs = value.matchAll(/^acpitz-acpi-(\d*)$\\n.*?\\n((?:temp)[\s\S]*?^\\n)+/gm);
	            for (const acpitz of acpitzs) {
	                let acpitzNumber = parseInt(acpitz[1], 10);
	                data[acpitzNumber] = {
	                       acpisensors: []
	                };

	                let acpisensors = acpitz[2].matchAll(/^temp\d+:\s*\+([^°]+).*$/gm);
	                for (const acpisensor of acpisensors) {
	                    data[acpitzNumber]['"'"'acpisensors'"'"'].push(acpisensor[1]);
	                }

	                for (const [k, acpitz] of data.entries()) {
	                    if (acpitz.acpisensors.length > 0) {
	                        output += '"'"' | 主板: '"'"';
	                        for (const acpiTemp of acpitz.acpisensors) {
	                            output += `${acpiTemp}°C, `;
	                        }
	                        output = output.slice(0, -2);
	                    }
	                }
	            }

	            let FunStates = value.matchAll(/^[a-zA-z]{2,3}\d{4}-isa-(\w{4})$\\n((?![ \S]+: *\d+ +RPM)[ \S]*?\\n)*((?:[ \S]+: *\d+ RPM)[\s\S]*?^\\n)+/gm);
	            for (const FunState of FunStates) {
	                let FanNumber = 0;
	                data[FanNumber] = {
	                    rotationals: [],
	                    cpufans: [],
	                    pumpfans: [],
	                    systemfans: []
	                };

	                let rotationals = FunState[3].match(/^([ \S]+: *[0-9]\d* +RPM)[ \S]*?$/gm);
	                for (const rotational of rotationals) {
	                    if (rotational.toLowerCase().indexOf("pump") !== -1 || rotational.toLowerCase().indexOf("opt") !== -1){
	                        let pumpfans = rotational.matchAll(/^[ \S]+: *([1-9]\d*) +RPM[ \S]*?$/gm);
	                        for (const pumpfan of pumpfans) {
	                            data[FanNumber]['"'"'pumpfans'"'"'].push(pumpfan[1]);
	                        }
	                    } else if (rotational.toLowerCase().indexOf("cpu") !== -1){
	                        let cpufans = rotational.matchAll(/^[ \S]+: *([1-9]\d*) +RPM[ \S]*?$/gm);
	                        for (const cpufan of cpufans) {
	                            data[FanNumber]['"'"'cpufans'"'"'].push(cpufan[1]);
	                        }
	                    } else {
	                        let systemfans = rotational.matchAll(/^[ \S]+: *([1-9]\d*) +RPM[ \S]*?$/gm);
	                        for (const systemfan of systemfans) {
	                            data[FanNumber]['"'"'systemfans'"'"'].push(systemfan[1]);
	                        }
	                    }
	                }

	                for (const [j, FunState] of data.entries()) {
	                    if (FunState.cpufans.length > 0 || FunState.pumpfans.length > 0 || FunState.systemfans.length > 0) {
	                        output += '"'"' | 风扇: '"'"';
	                        if (FunState.cpufans.length > 0) {
	                            output += '"'"'CPU-'"'"';
	                            for (const cpufan_value of FunState.cpufans) {
	                                output += `${cpufan_value}转/分钟, `;
	                            }
	                        }

	                        if (FunState.pumpfans.length > 0) {
	                            output += '"'"'水冷-'"'"';
	                            for (const pumpfan_value of FunState.pumpfans) {
	                                output += `${pumpfan_value}转/分钟, `;
	                            }
	                        }

	                        if (FunState.systemfans.length > 0) {
	                            if (FunState.cpufans.length > 0 || FunState.pumpfans.length > 0) {
	                                output += '"'"'系统-'"'"';
	                            }
	                            for (const systemfan_value of FunState.systemfans) {
	                                output += `${systemfan_value}转/分钟, `;
	                            }
	                        }
	                        output = output.slice(0, -2);
	                    } else if (FunState.cpufans.length == 0 && FunState.pumpfans.length == 0 && FunState.systemfans.length == 0) {
	                        output += '"'"' | 风扇: 停转'"'"';
	                    }
	                }
	            }

	            if (cpu.cores.length > 4) {
	                output += '"'"'\\n'"'"';
	                for (j = 1;j < cpu.cores.length;) {
	                    for (const coreTemp of cpu.cores) {
	                        output += `核心 ${j++}: ${coreTemp}°C`;
	                        output += '"'"' | '"'"';
	                        if ((j-1) % 4 == 0){
	                            output = output.slice(0, -2);
	                            output += '"'"'\\n'"'"';
	                        }
	                    }
	                }
	                output = output.slice(0, -2);
	            }
	        }

	        return output.replace(/\\n/g, '"'"'<br>'"'"');
	    }
	}'
    elif [[ "${cpuCore_Temp}" == "n" ]]; then
        core_degree="0"
        cpu_temp_display='
	{
	    itemId: '"'"'cpu-temperatures'"'"',
	    colspan: 2,
	    printBar: false,
	    title: gettext('"'"'CPU温度'"'"'),
	    textField: '"'"'cpu_temperatures'"'"',
	    renderer: function(value) {
	        value = value.replace(/Â/g, '"'"''"'"');
	        let data = [];
	        let cpus = value.matchAll(/^(?:coretemp-isa|k10temp-pci)-(\w{4})$\\n.*?\\n((?:Package|Core|Tctl)[\s\S]*?^\\n)+/gm);
	        for (const cpu of cpus) {
	            let cpuNumber = 0;
	            data[cpuNumber] = {
	                   packages: []
	            };

	            let packages = cpu[2].matchAll(/^(?:Package id \d+|Tctl):\s*\+([^°]+).*$/gm);
	            for (const package of packages) {
	                data[cpuNumber]['"'"'packages'"'"'].push(package[1]);
	            }
	        }

	        let output = '"'"''"'"';
	        for (const [i, cpu] of data.entries()) {
	            if (cpu.packages.length > 0) {
	                for (const packageTemp of cpu.packages) {
	                    output += `CPU ${i+1}: ${packageTemp}°C `;
	                }
	            }

	            let gpus = value.matchAll(/^amdgpu-pci-(\d*)$\\n((?!edge:)[ \S]*?\\n)*((?:edge)[\s\S]*?^\\n)+/gm);
	            for (const gpu of gpus) {
	                let gpuNumber = 0;
	                data[gpuNumber] = {
	                       edges: []
	                };

	                let edges = gpu[3].matchAll(/^edge:\s*\+([^°]+).*$/gm);
	                for (const edge of edges) {
	                    data[gpuNumber]['"'"'edges'"'"'].push(edge[1]);
	                }

	                for (const [k, gpu] of data.entries()) {
	                    if (gpu.edges.length > 0) {
	                        output += '"'"' | 核显: '"'"';
	                        for (const edgeTemp of gpu.edges) {
	                            output += `${edgeTemp}°C, `;
	                        }
	                        output = output.slice(0, -2);
	                    }
	                }
	            }

	            let acpitzs = value.matchAll(/^acpitz-acpi-(\d*)$\\n.*?\\n((?:temp)[\s\S]*?^\\n)+/gm);
	            for (const acpitz of acpitzs) {
	                let acpitzNumber = parseInt(acpitz[1], 10);
	                data[acpitzNumber] = {
	                       acpisensors: []
	                };

	                let acpisensors = acpitz[2].matchAll(/^temp\d+:\s*\+([^°]+).*$/gm);
	                for (const acpisensor of acpisensors) {
	                    data[acpitzNumber]['"'"'acpisensors'"'"'].push(acpisensor[1]);
	                }

	                for (const [k, acpitz] of data.entries()) {
	                    if (acpitz.acpisensors.length > 0) {
	                        output += '"'"' | 主板: '"'"';
	                        for (const acpiTemp of acpitz.acpisensors) {
	                            output += `${acpiTemp}°C, `;
	                        }
	                        output = output.slice(0, -2);
	                    }
	                }
	            }

	            let FunStates = value.matchAll(/^[a-zA-z]{2,3}\d{4}-isa-(\w{4})$\\n((?![ \S]+: *\d+ +RPM)[ \S]*?\\n)*((?:[ \S]+: *\d+ RPM)[\s\S]*?^\\n)+/gm);
	            for (const FunState of FunStates) {
	                let FanNumber = 0;
	                data[FanNumber] = {
	                    rotationals: [],
	                    cpufans: [],
	                    pumpfans: [],
	                    systemfans: []
	                };

	                let rotationals = FunState[3].match(/^([ \S]+: *[0-9]\d* +RPM)[ \S]*?$/gm);
	                for (const rotational of rotationals) {
	                    if (rotational.toLowerCase().indexOf("pump") !== -1 || rotational.toLowerCase().indexOf("opt") !== -1){
	                        let pumpfans = rotational.matchAll(/^[ \S]+: *([1-9]\d*) +RPM[ \S]*?$/gm);
	                        for (const pumpfan of pumpfans) {
	                            data[FanNumber]['"'"'pumpfans'"'"'].push(pumpfan[1]);
	                        }
	                    } else if (rotational.toLowerCase().indexOf("cpu") !== -1){
	                        let cpufans = rotational.matchAll(/^[ \S]+: *([1-9]\d*) +RPM[ \S]*?$/gm);
	                        for (const cpufan of cpufans) {
	                            data[FanNumber]['"'"'cpufans'"'"'].push(cpufan[1]);
	                        }
	                    } else {
	                        let systemfans = rotational.matchAll(/^[ \S]+: *([1-9]\d*) +RPM[ \S]*?$/gm);
	                        for (const systemfan of systemfans) {
	                            data[FanNumber]['"'"'systemfans'"'"'].push(systemfan[1]);
	                        }
	                    }
	                }

	                for (const [j, FunState] of data.entries()) {
	                    if (FunState.cpufans.length > 0 || FunState.pumpfans.length > 0 || FunState.systemfans.length > 0) {
	                        output += '"'"' | 风扇: '"'"';
	                        if (FunState.cpufans.length > 0) {
	                            output += '"'"'CPU-'"'"';
	                            for (const cpufan_value of FunState.cpufans) {
	                                output += `${cpufan_value}转/分钟, `;
	                            }
	                        }

	                        if (FunState.pumpfans.length > 0) {
	                            output += '"'"'水冷-'"'"';
	                            for (const pumpfan_value of FunState.pumpfans) {
	                                output += `${pumpfan_value}转/分钟, `;
	                            }
	                        }

	                        if (FunState.systemfans.length > 0) {
	                            if (FunState.cpufans.length > 0 || FunState.pumpfans.length > 0) {
	                                output += '"'"'系统-'"'"';
	                            }
	                            for (const systemfan_value of FunState.systemfans) {
	                                output += `${systemfan_value}转/分钟, `;
	                            }
	                        }
	                        output = output.slice(0, -2);
	                    } else if (FunState.cpufans.length == 0 && FunState.pumpfans.length == 0 && FunState.systemfans.length == 0) {
	                        output += '"'"' | 风扇: 停转'"'"';
	                    }
	                }
	            }
	        }

	        return output.replace(/\\n/g, '"'"'<br>'"'"');
	    }
	}'
    fi

    # CPU 主频及温度 UI 高度
    if [ $core_degree -gt 4 ]; then
        cpu_temp_degree="$[cpu_degree + (core_degree+4-1)/4]"
    else
        cpu_temp_degree="$cpu_degree"
    fi
    cpu_temp_height="$[cpu_temp_degree*17+7]"

    # 硬盘信息 API 及 Web UI
    if [[ "${storage_Info}" == "y" ]]; then
        # NVME 硬盘信息 API 及 Web UI
        nvme_height="0"
        if [ $(ls /dev/nvme? 2> /dev/null | wc -l) -gt 0 ]; then
            i="1"
            nvme_info_api=''
            nvme_info_display=''
            for nvme_device in $(ls -1 /dev/nvme?); do
                nvme_code=${nvme_device##*/}
                if [[ $(smartctl -a $nvme_device|grep -E "Cycle") && $(iostat -d -x -k 1 1 | grep -E "^$nvme_code") ]] && [[ $(smartctl -a $nvme_device|grep -E "Model") || $(smartctl -a $nvme_device|grep -E "Capacity") ]]; then
                    nvme_degree="2"
                else
                    nvme_degree="1"
                fi
                nvme_tmp_height="$[nvme_degree*17+7]"
                nvme_height="$[nvme_height + nvme_tmp_height]"
                nvme_info_api_tmp='
	my $'$nvme_code'_temperatures = `smartctl -a '$nvme_device'|grep -E "Model Number|Total NVM Capacity|Temperature:|Percentage|Data Unit|Power Cycles|Power On Hours|Unsafe Shutdowns|Integrity Errors"`;
	my $'$nvme_code'_io = `iostat -d -x -k 1 1 | grep -E "^'$nvme_code'"`;
	$res->{'$nvme_code'_status} = $'$nvme_code'_temperatures . $'$nvme_code'_io;
		'
                nvme_info_api="$nvme_info_api$nvme_info_api_tmp"

                nvme_info_display_tmp=',
	{
	    itemId: '"'"''$nvme_code'-status'"'"',
	    colspan: 2,
	    printBar: false,
	    title: gettext('"'"'NVME硬盘 '$i''"'"'),
	    textField: '"'"''$nvme_code'_status'"'"',
	    renderer:function(value){
	        if (value.length > 0) {
	            value = value.replace(/Â/g, '"'"''"'"');
	            let data = [];
	            let nvmes = value.matchAll(/(^(?:Model|Total|Temperature:|Percentage|Data|Power|Unsafe|Integrity Errors|nvme)[\s\S]*)+/gm);
	            for (const nvme of nvmes) {
	                let nvmeNumber = 0;
	                data[nvmeNumber] = {
	                       Models: [],
	                       Integrity_Errors: [],
	                       Capacitys: [],
	                       Temperatures: [],
	                       Useds: [],
	                       Reads: [],
	                       Writtens: [],
	                       Cycles: [],
	                       Hours: [],
	                       Shutdowns: [],
	                       States: [],
	                       r_awaits: [],
	                       w_awaits: [],
	                       utils: []
	                };

	                let Models = nvme[1].matchAll(/^Model Number: *([ \S]*)$/gm);
	                for (const Model of Models) {
	                    data[nvmeNumber]['"'"'Models'"'"'].push(Model[1]);
	                }

	                let Integrity_Errors = nvme[1].matchAll(/^Media and Data Integrity Errors: *([ \S]*)$/gm);
	                for (const Integrity_Error of Integrity_Errors) {
	                    data[nvmeNumber]['"'"'Integrity_Errors'"'"'].push(Integrity_Error[1]);
	                }

	                let Capacitys = nvme[1].matchAll(/^Total NVM Capacity:[^\[]*\[([ \S]*)\]$/gm);
	                for (const Capacity of Capacitys) {
	                    data[nvmeNumber]['"'"'Capacitys'"'"'].push(Capacity[1]);
	                }

	                let Temperatures = nvme[1].matchAll(/^Temperature: *([\d]*)[ \S]*$/gm);
	                for (const Temperature of Temperatures) {
	                    data[nvmeNumber]['"'"'Temperatures'"'"'].push(Temperature[1]);
	                }

	                let Useds = nvme[1].matchAll(/^Percentage Used: *([ \S]*)$/gm);
	                for (const Used of Useds) {
	                    data[nvmeNumber]['"'"'Useds'"'"'].push(Used[1]);
	                }

	                let Reads = nvme[1].matchAll(/^Data Units Read:[^\[]*\[([ \S]*)\]$/gm);
	                for (const Read of Reads) {
	                    data[nvmeNumber]['"'"'Reads'"'"'].push(Read[1]);
	                }

	                let Writtens = nvme[1].matchAll(/^Data Units Written:[^\[]*\[([ \S]*)\]$/gm);
	                for (const Written of Writtens) {
	                    data[nvmeNumber]['"'"'Writtens'"'"'].push(Written[1]);
	                }

	                let Cycles = nvme[1].matchAll(/^Power Cycles: *([ \S]*)$/gm);
	                for (const Cycle of Cycles) {
	                    data[nvmeNumber]['"'"'Cycles'"'"'].push(Cycle[1]);
	                }

	                let Hours = nvme[1].matchAll(/^Power On Hours: *([ \S]*)$/gm);
	                for (const Hour of Hours) {
	                    data[nvmeNumber]['"'"'Hours'"'"'].push(Hour[1]);
	                }

	                let Shutdowns = nvme[1].matchAll(/^Unsafe Shutdowns: *([ \S]*)$/gm);
	                for (const Shutdown of Shutdowns) {
	                    data[nvmeNumber]['"'"'Shutdowns'"'"'].push(Shutdown[1]);
	                }

	                let States = nvme[1].matchAll(/^nvme\S+(( *\d+\.\d{2}){22})/gm);
	                for (const State of States) {
	                    data[nvmeNumber]['"'"'States'"'"'].push(State[1]);
	                    const IO_array = [...State[1].matchAll(/\d+\.\d{2}/g)];
	                    if (IO_array.length > 0) {
	                        data[nvmeNumber]['"'"'r_awaits'"'"'].push(IO_array[4]);
	                        data[nvmeNumber]['"'"'w_awaits'"'"'].push(IO_array[10]);
	                        data[nvmeNumber]['"'"'utils'"'"'].push(IO_array[21]);
	                    }
	                }

	                let output = '"'"''"'"';
	                for (const [i, nvme] of data.entries()) {
	                    if (nvme.Models.length > 0) {
	                        for (const nvmeModel of nvme.Models) {
	                            output += `${nvmeModel}`;
	                        }
	                    }

	                    if (nvme.Integrity_Errors.length > 0) {
	                        for (const nvmeIntegrity_Error of nvme.Integrity_Errors) {
	                            if (nvmeIntegrity_Error != 0) {
	                                output += ` (0E: ${nvmeIntegrity_Error}-故障！)`;
	                            }
	                            break
	                        }
	                    }

	                    if (nvme.Capacitys.length > 0) {
	                        output += '"'"' | '"'"';
	                        for (const nvmeCapacity of nvme.Capacitys) {
	                            output += `容量: ${nvmeCapacity.replace(/ |,/gm, '"'"''"'"')}`;
	                        }
	                    }

	                    if (nvme.Useds.length > 0) {
	                        output += '"'"' | '"'"';
	                        for (const nvmeUsed of nvme.Useds) {
	                            output += `寿命: ${nvmeUsed} `;
	                            if (nvme.Reads.length > 0) {
	                                output += '"'"'('"'"';
	                                for (const nvmeRead of nvme.Reads) {
	                                    output += `已读${nvmeRead.replace(/ |,/gm, '"'"''"'"')}`;
	                                    output += '"'"')'"'"';
	                                }
	                            }

	                            if (nvme.Writtens.length > 0) {
	                                output = output.slice(0, -1);
	                                output += '"'"', '"'"';
	                                for (const nvmeWritten of nvme.Writtens) {
	                                    output += `已写${nvmeWritten.replace(/ |,/gm, '"'"''"'"')}`;
	                                }
	                                output += '"'"')'"'"';
	                            }
	                        }
	                    }

	                    if (nvme.States.length <= 0) {
	                        if (nvme.Cycles.length > 0) {
	                            output += '"'"' | '"'"';
	                            for (const nvmeCycle of nvme.Cycles) {
	                                output += `通电: ${nvmeCycle.replace(/ |,/gm, '"'"''"'"')}次`;
	                            }

	                            if (nvme.Shutdowns.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const nvmeShutdown of nvme.Shutdowns) {
	                                    output += `不安全断电${nvmeShutdown.replace(/ |,/gm, '"'"''"'"')}次`;
	                                }
	                            }

	                            if (nvme.Hours.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const nvmeHour of nvme.Hours) {
	                                    output += `累计${nvmeHour.replace(/ |,/gm, '"'"''"'"')}小时`;
	                                }
	                            }
	                        }
	                    }

	                    if (nvme.Temperatures.length > 0) {
	                        output += '"'"' | '"'"';
	                        for (const nvmeTemperature of nvme.Temperatures) {
	                            output += `温度: ${nvmeTemperature}°C`;
	                        }
	                    }

	                    if (nvme.States.length > 0) {
	                        if (nvme.Cycles.length > 0) {
	                            output += '"'"'\\n'"'"';
	                            for (const nvmeCycle of nvme.Cycles) {
	                                output += `通电: ${nvmeCycle.replace(/ |,/gm, '"'"''"'"')}次`;
	                            }

	                            if (nvme.Shutdowns.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const nvmeShutdown of nvme.Shutdowns) {
	                                    output += `不安全断电${nvmeShutdown.replace(/ |,/gm, '"'"''"'"')}次`;
	                                }
	                            }

	                            if (nvme.Hours.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const nvmeHour of nvme.Hours) {
	                                    output += `累计${nvmeHour.replace(/ |,/gm, '"'"''"'"')}小时`;
	                                }
	                            }
	                        }

	                        output += '"'"' | '"'"';
	                        if (nvme.r_awaits.length > 0) {
	                            for (const nvme_r_await of nvme.r_awaits) {
	                                output += `I/O: 读延迟${nvme_r_await}ms`;
	                            }
	                        }

	                        if (nvme.w_awaits.length > 0) {
	                            output += '"'"', '"'"';
	                            for (const nvme_w_await of nvme.w_awaits) {
	                                output += `写延迟${nvme_w_await}ms`;
	                            }
	                        }

	                        if (nvme.utils.length > 0) {
	                            output += '"'"', '"'"';
	                            for (const nvme_util of nvme.utils) {
	                                output += `负载${nvme_util}%`;
	                            }
	                        }
	                    }
	                    //output = output.slice(0, -3);
	                }
	                return output.replace(/\\n/g, '"'"'<br>'"'"');
	            }
	        } else { 
	            return `提示: 未安装硬盘或已直通硬盘控制器！`;
	        }
	    }
	}'
                nvme_info_display="$nvme_info_display$nvme_info_display_tmp"
                i=$((i + 1))
            done
        fi

        # 其他存储设备信息 API 及 Web UI
        hdd_height="0"
        if [ $(ls /dev/sd? 2> /dev/null | wc -l) -gt 0 ]; then
            i="1"
            hdd_info_api=''
            hdd_info_display=''
            for hdd_device in $(ls -1 /dev/sd?); do
                hdd_code=${hdd_device##*/}
                if [[ $(smartctl -a $hdd_device|grep -E "Cycle") && $(iostat -d -x -k 1 1 | grep -E "^$hdd_code") ]] && [[ $(smartctl -a $hdd_device|grep -E "Model") || $(smartctl -a $hdd_device|grep -E "Capacity") ]]; then
                    hdd_degree="2"
                else
                    hdd_degree="1"
                fi
                hdd_tmp_height="$[hdd_degree*17+7]"
                hdd_height="$[hdd_height + hdd_tmp_height]"
                hdd_info_api_tmp='
	my $'$hdd_code'_temperatures = `smartctl -a '$hdd_device'|grep -E "Model|Capacity|Power_On_Hours|Power_Cycle_Count|Power-Off_Retract_Count|Unexpected_Power_Loss|Unexpect_Power_Loss_Ct|POR_Recovery|Temperature"`;
	my $'$hdd_code'_io = `iostat -d -x -k 1 1 | grep -E "^'$hdd_code'"`;
	$res->{'$hdd_code'_status} = $'$hdd_code'_temperatures . $'$hdd_code'_io;
		'
            hdd_info_api="$hdd_info_api$hdd_info_api_tmp"

            hdd_info_display_tmp=',
	{
	    itemId: '"'"''$hdd_code'-status'"'"',
	    colspan: 2,
	    printBar: false,
	    title: gettext('"'"'其他存储设备 '$i''"'"'),
	    textField: '"'"''$hdd_code'_status'"'"',
	    renderer:function(value){
	        if (value.length > 0) {
	            value = value.replace(/Â/g, '"'"''"'"');
	            let data = [];
	            let devices = value.matchAll(/^((?:Device|Model|User|[ ]{0,2}\d|sd)[\s\S]*)+/gm);
	            for (const device of devices) {
	                let deviceNumber = 0;
	                data[deviceNumber] = {
	                       Models: [],
	                       Capacitys: [],
	                       Temperatures: [],
	                       Cycles: [],
	                       Hours: [],
	                       Shutdowns: [],
	                       States: [],
	                       r_awaits: [],
	                       w_awaits: [],
	                       utils: []
	                };

	                if(device[1].indexOf("Family") !== -1){
	                    let Models = device[1].matchAll(/^Model Family: *([ \S]*?)\\n^Device Model: *([ \S]*?)$/gm);
	                    for (const Model of Models) {
	                        data[deviceNumber]['"'"'Models'"'"'].push(`${Model[1]} - ${Model[2]}`);
	                    }
	                } else {
	                    let Models = device[1].matchAll(/Model: *([ \S]*?)$/gm);
	                    for (const Model of Models) {
	                        data[deviceNumber]['"'"'Models'"'"'].push(Model[1]);
	                    }
	                }

	                let Capacitys = device[1].matchAll(/^User Capacity:[^\[]*\[([ \S]*)\]$/gm);
	                for (const Capacity of Capacitys) {
	                    data[deviceNumber]['"'"'Capacitys'"'"'].push(Capacity[1]);
	                }

	                let Temperatures = device[1].matchAll(/Temperature[ \S]*(?:\-|In_the_past) *?(\d+)[ \S]*$/gm);
	                for (const Temperature of Temperatures) {
	                    data[deviceNumber]['"'"'Temperatures'"'"'].push(Temperature[1]);
	                }

	                let Cycles = device[1].matchAll(/Cycle[ \S]*(?:\-|In_the_past) *?(\d+)[ \S]*$/gm);
	                for (const Cycle of Cycles) {
	                    data[deviceNumber]['"'"'Cycles'"'"'].push(Cycle[1]);
	                }

	                let Hours = device[1].matchAll(/Hours[ \S]*(?:\-|In_the_past) *?(\d+)[ \S]*$/gm);
	                for (const Hour of Hours) {
	                    data[deviceNumber]['"'"'Hours'"'"'].push(Hour[1]);
	                }

	                let Shutdowns = device[1].matchAll(/(?:Retract|Loss|POR_Recovery)[ \S]*(?:\-|In_the_past) *?(\d+)[ \S]*$/gm);
	                for (const Shutdown of Shutdowns) {
	                    data[deviceNumber]['"'"'Shutdowns'"'"'].push(Shutdown[1]);
	                }

	                let States = device[1].matchAll(/^sd\S+(( *\d+\.\d{2}){22})/gm);
	                for (const State of States) {
	                    data[deviceNumber]['"'"'States'"'"'].push(State[1]);
	                    const IO_array = [...State[1].matchAll(/\d+\.\d{2}/g)];
	                    if (IO_array.length > 0) {
	                        data[deviceNumber]['"'"'r_awaits'"'"'].push(IO_array[4]);
	                        data[deviceNumber]['"'"'w_awaits'"'"'].push(IO_array[10]);
	                        data[deviceNumber]['"'"'utils'"'"'].push(IO_array[21]);
	                    }
	                }

	                let output = '"'"''"'"';
	                for (const [i, device] of data.entries()) {
	                    if (device.Models.length > 0) {
	                        for (const deviceModel of device.Models) {
	                            output += `${deviceModel}`;
	                        }
	                    }

	                    if (device.Capacitys.length > 0) {
	                        if (device.Models.length > 0) {
	                            output += '"'"' | '"'"';
                          }
	                        for (const deviceCapacity of device.Capacitys) {
	                            output += `容量: ${deviceCapacity.replace(/ |,/gm, '"'"''"'"')}`;
	                        }
	                    }

	                    if (device.States.length <= 0) {
	                        if (device.Cycles.length > 0) {
	                            output += '"'"' | '"'"';
	                            for (const deviceCycle of device.Cycles) {
	                                output += `通电: ${deviceCycle.replace(/ |,/gm, '"'"''"'"')}次`;
	                            }

	                            if (device.Shutdowns.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const deviceShutdown of device.Shutdowns) {
	                                    output += `不安全断电${deviceShutdown.replace(/ |,/gm, '"'"''"'"')}次`;
	                                }
	                            }

	                            if (device.Hours.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const deviceHour of device.Hours) {
	                                    output += `累计${deviceHour.replace(/ |,/gm, '"'"''"'"')}小时`;
	                                }
	                            }
	                        }
	                    } else if (device.Cycles.length <= 0) {
	                        if (device.States.length > 0) {
	                            if (device.Models.length > 0 || device.Capacitys.length > 0) {
	                                output += '"'"' | '"'"';
	                            }

	                            if (device.r_awaits.length > 0) {
	                                for (const device_r_await of device.r_awaits) {
	                                    output += `I/O: 读延迟${device_r_await}ms`;
	                                }
	                            }

	                            if (device.w_awaits.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const device_w_await of device.w_awaits) {
	                                    output += `写延迟${device_w_await}ms`;
	                                }
	                            }

	                            if (device.utils.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const device_util of device.utils) {
	                                    output += `负载${device_util}%`;
	                                }
	                            }
	                        }
	                    }

	                    if (device.Temperatures.length > 0) {
	                        output += '"'"' | '"'"';
	                        for (const deviceTemperature of device.Temperatures) {
	                            output += `温度: ${deviceTemperature}°C`;
	                            break
	                        }
	                    }

	                    if (device.States.length > 0) {
	                        if (device.Cycles.length > 0) {
	                            output += '"'"'\\n'"'"';
	                            for (const deviceCycle of device.Cycles) {
	                                output += `通电: ${deviceCycle.replace(/ |,/gm, '"'"''"'"')}次`;
	                            }

	                            if (device.Shutdowns.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const deviceShutdown of device.Shutdowns) {
	                                    output += `不安全断电${deviceShutdown.replace(/ |,/gm, '"'"''"'"')}次`;
	                                }
	                            }

	                            if (device.Hours.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const deviceHour of device.Hours) {
	                                    output += `累计${deviceHour.replace(/ |,/gm, '"'"''"'"')}小时`;
	                                }
	                            }

	                            if (device.Models.length > 0 || device.Capacitys.length > 0) {
	                                output += '"'"' | '"'"';
	                            }

	                            if (device.r_awaits.length > 0) {
	                                for (const device_r_await of device.r_awaits) {
	                                    output += `I/O: 读延迟${device_r_await}ms`;
	                                }
	                            }

	                            if (device.w_awaits.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const device_w_await of device.w_awaits) {
	                                    output += `写延迟${device_w_await}ms`;
	                                }
	                            }

	                            if (device.utils.length > 0) {
	                                output += '"'"', '"'"';
	                                for (const device_util of device.utils) {
	                                    output += `负载${device_util}%`;
	                                }
	                            }
	                        }
	                    }
	                    //output = output.slice(0, -3);
	                }
	                return output.replace(/\\n/g, '"'"'<br>'"'"');
	            }
	        } else { 
	            return `提示: 未安装存储设备或已直通存储设备控制器！`;
	        }
	    }
	}'
                hdd_info_display="$hdd_info_display$hdd_info_display_tmp"
                i=$((i + 1))
            done
        fi
    else
        nvme_info_api=''
        nvme_info_display=''
        nvme_height="0"
        hdd_info_api=''
        hdd_info_display=''
        hdd_height="0"
    fi

    # API
    INFO_API="$cpu_info_api$nvme_info_api$hdd_info_api"
    # Web UI
    INFO_DISPLAY="$cpu_freq_display$cpu_temp_display$nvme_info_display$hdd_info_display"

    # 缓存代码
    # echo -e "\n" > /tmp/0.txt
    # echo -e "	    value: '',\n	}," > /tmp/1.txt
    echo -e "$INFO_API" > /tmp/2.txt
    echo -e "	    value: '',\n	}$INFO_DISPLAY" > /tmp/3.txt

    # Web UI 总高度
    #height1="$[400 + (cpu_temp_height + cpu_freq_height + nvme_height + hdd_height)]"
    #height1="400"
    height2="$[300 + cpu_temp_height + cpu_freq_height + nvme_height + hdd_height + 25]"
    if [ $height2 -le 325 ]; then
        height2="300"
    fi

    # 重装 pve-manager
    # echo -e "正在恢复默认 pve-manager ......"
    # apt-get update > /dev/null 2>&1
    # apt-get reinstall pve-manager > /dev/null 2>&1
    # sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;s/my $dinfo = df/\n\t&/' /usr/share/perl5/PVE/API2/Nodes.pm
    # sed -i '/pveversion/,/^\s\+],/!b;//!d;s/^\s\+],/\t    value: '"'"''"'"',\n\t},\n&/' /usr/share/pve-manager/js/pvemanagerlib.js
    # sed -i '/widget.pveNodeStatus/,/},/ { s/height: [0-9]\+/height: 300/; /textAlign/d}' /usr/share/pve-manager/js/pvemanagerlib.js

    # 将 API 及 Web UI 文件修改至原文件
    sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;/my $dinfo = df/e cat /tmp/2.txt' /usr/share/perl5/PVE/API2/Nodes.pm
    sed -i '/pveversion/,/^\s\+],/!b;//!d;/^\s\+],/e cat /tmp/3.txt' /usr/share/pve-manager/js/pvemanagerlib.js

    #sed -i '/let win = Ext.create('"'"'Ext.window.Window'"'"', {/,/height/ s/height: [0-9]\+/height: '$height1'/' /usr/share/pve-manager/js/pvemanagerlib.js

    # 修改信息框 Web UI 高度
	if [[ "${textAlign_right}" == "y" ]]; then
        sed -Ei '/widget.pveNodeStatus/,/},/ s/height: [0-9]+/height: '$height2'/; /width: '"'"'100%'"'"'/{n;s/^[	| ]+},/\t\ttextAlign: '"'"'right'"'"',\n&/}' /usr/share/pve-manager/js/pvemanagerlib.js
	else
        sed -Ei '/widget.pveNodeStatus/,/},/ s/height: [0-9]+/height: '$height2'/; /textAlign/d' /usr/share/pve-manager/js/pvemanagerlib.js
	fi

    # 完善汉化信息
    sed -Ei '/'"'"'netin'"'"', '"'"'netout'"'"'/{n;s/^([	| ]+)store: rrdstore/\1fieldTitles: [gettext('"'"'下行'"'"'), gettext('"'"'上行'"'"')],\n&/g}' /usr/share/pve-manager/js/pvemanagerlib.js
    sed -Ei '/'"'"'diskread'"'"', '"'"'diskwrite'"'"'/{n;s/^([	| ]+)store: rrdstore/\1fieldTitles: [gettext('"'"'读'"'"'), gettext('"'"'写'"'"')],\n&/g}' /usr/share/pve-manager/js/pvemanagerlib.js

	echoContent skyBlue "\n进度  5/${totalProgress} : 添加 CPU 主频、温度、硬盘等概要信息"
    echoContent green " ---> 添加 PVE 硬件概要信息完成，正在重启 pveproxy 服务 ......"
    systemctl restart pveproxy

	echoContent skyBlue "\n进度  6/${totalProgress} : 添加 CPU 主频、温度、硬盘等概要信息"
    echoContent green " ---> pveproxy 服务重启完成，请使用 Shift + F5 手动刷新 PVE Web 页面"
}

# 添加概要信息
add_info() {
    echoContent red "\n=============================================================="
	echoContent yellow "# 注意事项\n"
	echoContent yellow "风扇转速信息需单独安装传感器驱动\n"

    echoContent red "=============================================================="
	local ask_array=('是否显示 CPU 线程频率' '是否显示 CPU 核心温度(不支持AMD)' '是否显示硬盘信息' '是否居右显示')
	local answer_array=()

    for i in {0..3};do
	    j=$[i+1]
        while :
        do
	        echoContent skyBlue "\n进度  $j/${totalProgress} : 添加 CPU 主频、温度、硬盘等概要信息"
            read -r -p "${ask_array[$i]} (Y/n)？ : " answer
            case ${answer} in
                Y|y)
                    answer_array[i]="y"
                    echoContent green " ---> 是"
                    break
                    ;;
                N|n)
                    answer_array[i]="n"
                    echoContent green " ---> 否"
                    break
                    ;;
                *)
                    echoContent red " ---> 选择错误"
                    ;;
            esac
        done
    done

    pveInfo "${answer_array[@]}"
}

# 恢复概要信息
recovery_info_offline() {
    echoContent skyBlue "\n进度 1/${totalProgress} : 恢复原版 PVE 概要信息(离线模式测试版)"
    echoContent red "\n=============================================================="
	echoContent yellow "# 注意事项\n"
	echoContent yellow "1.在线模式会将暗黑主题恢复为官方主题，离线模式不会影响暗黑主题\n"
	echoContent yellow "2.如恢复出现异常，请使用恢复原版 PVE 概要信息(在线模式)\n"

    echoContent red "=============================================================="
    while :
    do
        read -r -p '是否恢复原版 PVE 概要信息 (Y/n)？ : ' choose
        case $choose in
            y)
                sed -i '/PVE::pvecfg::version_text();/,/my $dinfo = df/!b;//!d;s/my $dinfo = df/\n\t&/' /usr/share/perl5/PVE/API2/Nodes.pm
                sed -i '/pveversion/,/^\s\+],/!b;//!d;s/^\s\+],/\t    value: '"'"''"'"',\n\t},\n&/' /usr/share/pve-manager/js/pvemanagerlib.js
                sed -i '/widget.pveNodeStatus/,/},/ { s/height: [0-9]\+/height: 300/; /textAlign/d}' /usr/share/pve-manager/js/pvemanagerlib.js
                systemctl restart pveproxy

                echoContent green " ---> 恢复原版 PVE 概要信息完成，请使用 Shift + F5 手动刷新 PVE Web 页面"
				continue
                ;;
			n)
				continue
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
	done
}

# 恢复概要信息
recovery_info_online() {
    echoContent skyBlue "\n进度 1/${totalProgress} : 恢复原版 PVE 概要信息(在线模式)"
    echoContent red "\n=============================================================="
	echoContent yellow "# 注意事项\n"
	echoContent yellow "1.在线模式会将暗黑主题恢复为官方主题，离线模式不会影响暗黑主题\n"
	echoContent yellow "2.需确保 PVE 软件源连通性正常，否则会恢复失败\n"

    echoContent red "=============================================================="
    while :
    do
        read -r -p '是否恢复原版 PVE 概要信息 (Y/n)？ : ' choose
        case $choose in
            y)
                ${reinstallType} pve-manager > /dev/null 2>&1
                echoContent green " ---> 恢复原版 PVE 概要信息完成，请使用 Shift + F5 手动刷新 PVE Web 页面"
				break
                ;;
			n)
				break
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
	done
}

# 进度条
process_line() {
    i=0
    str='#'
    ch=('|' '\' '-' '/')
    index=0
    while [ $i -le 50 ]
    do
        printf "$1：[%-50s][%d%%][%c]\r" $str $(($i*2)) ${ch[$index]}
        str+='#'
        let i++
        let index=i%4
        sleep 0.05
    done
    printf "\n"
    echoContent green " ---> $2完成"
}

# 添加概要信息
pveInfo_menu() {
    while :
    do
        echoContent skyBlue "\n功能 1/${totalProgress} : 调整 PVE 概要信息(恢复概要/添加 CPU 主频、温度、硬盘等概要信息)"
        echoContent red "\n=============================================================="
        echoContent yellow "# 注意事项\n"
        echoContent yellow "风扇转速信息需单独安装传感器驱动\n"

        echoContent red "=============================================================="
        echoContent yellow "1.添加 CPU 主频、温度、硬盘等概要信息"
        echoContent yellow "2.恢复原版概要信息(离线模式测试版)"
        echoContent yellow "3.恢复原版概要信息(在线模式)"
        echoContent yellow "0.返回"
        echoContent red "=============================================================="
        read -r -p "请选择:" pveInfoChoose
        case ${pveInfoChoose} in
            1)
			    totalProgress=6
                add_info && case_read
                break
                ;;
            2)
			    totalProgress=1
                recovery_info_offline && case_read
                break
                ;;
            3)
			    totalProgress=1
                recovery_info_online && case_read
                break
                ;;
            0)
                break
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
    done
}

PVEDiscordDark() {
    echoContent skyBlue "\n进度  1/${totalProgress} : 检测访问 GitHub (https://raw.githubusercontent.com) 连通性"
    curl -sSf -f https://raw.githubusercontent.com/ &> /dev/null || {
        echoContent red " ---> 无法连通 GitHub ，请检查网络后重试"
        break
    }
    echoContent green " ---> GitHub 连通正常"
    echoContent skyBlue "\n进度  2/${totalProgress} : 开始$2 PVE 暗黑主题"
    bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh ) $1
    echoContent green " ---> PVE 暗黑主题$2完成"
}

# 应用 PVE 暗黑主题
PVEDiscordDark_menu() {
    while :
    do
        echoContent skyBlue "\n功能 1/${totalProgress} : 应用 PVE 暗黑主题\nGithub : https://github.com/Weilbyte/PVEDiscordDark"
        echoContent red "\n=============================================================="
        echoContent yellow "# 注意事项\n"
        echoContent yellow "需确保 GitHub (https://raw.githubusercontent.com) 连通性\n"

        echoContent red "=============================================================="
        echoContent yellow "1.安装"
        echoContent yellow "2.卸载"
        echoContent yellow "3.更新/重装"
        echoContent yellow "0.返回"
        echoContent red "=============================================================="
        echoContent green " ---> GitHub 连通正常"
		totalProgress=2
        read -r -p "请选择:" PVEDiscordDarkChoose
        case ${PVEDiscordDarkChoose} in
            1)
			    totalProgress=2
				PVEDiscordDark install '安装' && case_read
                break
                ;;
            2)
			    totalProgress=2
                PVEDiscordDark uninstall '卸载' && case_read
                break
                ;;
            3)
			    totalProgress=2
                PVEDiscordDark update '更新/重装' && case_read
                break
                ;;
            0)
                break
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
    done
}

pve_IOMMU() {
    # 交互 (Y/n) 询问
    ask_user(){
        Que="$1"
        cmd_0="$2"
        cme_1="$3"
        while true
            do
                read -r -p "$Que (Y/n) : " answer
                case $answer in [Yy]) eval $cmd_0 && break;;
                                [Nn]) eval $cmd_1 && break;;
                                   *) echoContent red " ---> 选择错误";;
                esac
            done
    }

	# PVE 版本适配核显直通参数
    if version_ge $proxmox_main_ver 7.2; then
        gpu_iommu_arg="initcall_blacklist=sysfb_init"
    else
        gpu_iommu_arg="video=efifb:off,vesafb:off"
    fi

    # 默认 grub 参数
    grub_default='quiet'
	# 开启 IOMMU 的 grub 参数
    grub_default_iommu="quiet ${cpu}_iommu=on iommu=pt pcie_acs_override=downstream"
	# 开启 IOMMU 及核显直通的 grub 参数
    grub_default_iommu_gpu="quiet ${cpu}_iommu=on iommu=pt $gpu_iommu_arg pcie_acs_override=downstream"

    # 修改 grub 引导文件
    mod_grub(){
        echoContent skyBlue "\n进度 1/${totalProgress} : 修改 grub 引导文件"
        # 修改 grub 引导文件
        sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT/ s/\".*\"/\"$grub_arg\"/" /etc/default/grub
        echoContent green " ---> grub 引导文件修改完成"

        # 更新 grub 引导配置
        echoContent skyBlue "\n进度 2/${totalProgress} : 更新 grub 引导配置"
        update-grub
        echoContent green " ---> grub 引导配置更新完成"
    }

    # 添加 IOMMU 模块
    Enable_IOMMU_modules(){
        echoContent skyBlue "\n进度 3/${totalProgress} : 配置 vfio 模块"
        for i in vfio vfio_iommu_type1 vfio_pci vfio_virqfd; do
            if [ `grep -c ".*$i$" "/etc/modules"` -ne '0' ];then
                sed -i "s/.*$i$/$i/" /etc/modules
            elif [ `grep -c "^$i$" "/etc/modules"` -eq '0' ];then
                echo "$i" >> /etc/modules
            fi
        done
        echoContent green " ---> vfio 模块配置完成"

        echoContent skyBlue "\n进度 4/${totalProgress} : 修改设备黑名单及 vfio 配置文件"
        if [ "$grub_arg" = "$grub_default_iommu_gpu" ]; then
            for i in "${black_array[@]}"; do
                if [ `grep -c ".*$i$" "/etc/modprobe.d/pve-blacklist.conf"` -ne '0' ];then
                    sed -i "s/.*$i$/blacklist $i/" /etc/modprobe.d/pve-blacklist.conf
                elif [ `grep -c "^$i$" "/etc/modprobe.d/pve-blacklist.conf"` -eq '0' ];then
                    echo "blacklist $i" >> /etc/modprobe.d/pve-blacklist.conf
                fi
            done
            echo $vifo_arg > /etc/modprobe.d/vfio.conf
        else
            for i in "${black_array[@]}"; do
                if [ `grep -c ".*$i$" "/etc/modprobe.d/pve-blacklist.conf"` -ne '0' ];then
                    sed -i "/$i/d" /etc/modprobe.d/pve-blacklist.conf
                fi
            done
            rm -rf /etc/modprobe.d/vfio.conf
        fi
        echoContent green " ---> 设备黑名单及 vfio 配置文件修改完成"

        # 更新 initramfs (初始化 RAM 系统)
        echoContent skyBlue "\n进度 5/${totalProgress} : 更新 initramfs (初始化 RAM 系统)"
        update-initramfs -u -k all
        echoContent green " ---> initramfs (初始化 RAM 系统)更新完成"
    }

    # 禁用 IOMMU 模块
    Disable_IOMMU_modules(){
        echoContent skyBlue "\n进度 3/${totalProgress} : 配置 vfio 模块"
        for i in vfio vfio_iommu_type1 vfio_pci vfio_virqfd; do
            if [ `grep -c "^$i$" "/etc/modules"` -ne '0' ];then
                sed -i "/^$i$/ s/^/# /" /etc/modules
            fi
        done
        echoContent green " ---> vfio 模块配置完成"

        echoContent skyBlue "\n进度 4/${totalProgress} : 修改设备黑名单及 vfio 配置文件"
        for i in "${black_array[@]}"; do
            if [ `grep -c ".*$i$" "/etc/modprobe.d/pve-blacklist.conf"` -ne '0' ];then
                sed -i "/$i/d" /etc/modprobe.d/pve-blacklist.conf
            fi
        done
        rm -rf /etc/modprobe.d/vfio.conf
        echoContent green " ---> 设备黑名单及 vfio 配置文件修改完成"

        # 更新 initramfs (初始化 RAM 系统)
        echoContent skyBlue "\n进度 5/${totalProgress} : 更新 initramfs (初始化 RAM 系统)"
        update-initramfs -u -k all
        echoContent green " ---> initramfs (初始化 RAM 系统)更新完成"
    }
}

pve_Passthough() {
    # 虚拟机节点
	vm_list=`qm list | grep -v VMID | awk '{print $1,$2}' | awk '{printf("%d.%s\n",NR,$0)}'`

    gpu_audio_device=`lspci -nn | grep -E 'VGA compatible controller|Audio device' | awk '{printf("%d.0000:%s\n",NR,$0)}'`
	gpu_audio_device_num=`echo "${gpu_audio_device}" | wc -l`
    gpu_audio_list=`echo "${gpu_audio_device}" | sed -e '/VGA compatible controller/i # 核心显卡' -e '/Audio device/i # 核心音频'`
    gpu_device=`lspci -nn | grep -E 'VGA compatible controller' | awk '{printf("%d.0000:%s\n",NR,$0)}'`
    gpu_list=`echo "${gpu_device}" | sed '/VGA compatible controller/i # 核心显卡'`
    audio_device=`lspci -nn | grep -E 'Audio device' | head -n 1 | awk '{printf("%d.0000:%s\n",NR,$0)}'`
    audio_list=`echo "${audio_device}" | sed '/Audio device/i # 核心音频'`

    while :
    do
        echoContent skyBlue "\n进度 1/${totalProgress} : 选择 PVE 虚拟机节点"
        echoContent red "=============================================================="
        echoContent yellow "${vm_list}"
        echoContent red "=============================================================="

        read -r -p "请选择虚拟机节点: " pve_NodeChoose
        vmid=$(echo "$vm_list" | grep "^${pve_NodeChoose}" | sed -E "s/^${pve_NodeChoose}.([^ ]*).*/\1/")
        if [ -n "$vmid" ]; then
            echoContent green " ---> 虚拟机节点：${vmid}"
            break
        else
            echoContent red " ---> 虚拟机节点选择错误，请重新输入"
        fi
    done

    while :
    do
        echoContent skyBlue "\n进度 2/${totalProgress} : 选择核心显卡"
    echoContent red "\n=============================================================="
    echoContent yellow "# 注意事项\n"
    echoContent yellow "1.Intel J4125 核显直通需要针对核心显卡配置扩展参数，本步骤应跳过"
    echoContent yellow "2.AMD Ryzen 7 等设备本步骤必须选中\n"

    echoContent red "=============================================================="
        echoContent yellow "${gpu_list}"
        echoContent red "=============================================================="

        read -r -p "请选择设备序号 (输入 skip 跳过) : " pve_iGPUChoose
        case ${pve_iGPUChoose} in
            skip)
				iGPU_adr=""
                echoContent green " ---> 跳过"
                break
                ;;
            *)
                iGPU_adr="$(echo "${gpu_list}" | grep "^${pve_iGPUChoose}" | sed -E "s/^${pve_iGPUChoose}.([^ ]*).*/\1/")"
                if [ -n "${iGPU_adr}" ]; then
                    echoContent green " ---> 设备总线：${iGPU_adr}"
                    break
                else
                    echoContent red " ---> 设备序号选择错误，请重新输入"
                fi
				;;
        esac
	done

    while :
    do
        echoContent skyBlue "\n进度 3/${totalProgress} : 选择核心高清音频"
        echoContent red "=============================================================="
        echoContent yellow "${audio_list}"
        echoContent red "=============================================================="

        read -r -p "请选择设备序号 (输入 skip 跳过) : " pve_iAudioChoose
        case ${pve_iAudioChoose} in
            skip)
				iAudio_adr=""
                echoContent green " ---> 跳过"
                break
                ;;
            *)
                iAudio_adr="$(echo "${audio_list}" | grep "^${pve_iAudioChoose}" | sed -E "s/^${pve_iAudioChoose}.([^ ]*).*/\1/")"
                if [ -n "${iAudio_adr}" ]; then
                    echoContent green " ---> 设备总线：${iAudio_adr}"
                    break
                else
                    echoContent red " ---> 设备序号选择错误，请重新输入"
                fi
					;;
        esac
	done

    echoContent skyBlue "\n进度 4/${totalProgress} : vbios 文件路径"
    echoContent red "\n=============================================================="
    echoContent yellow "# 注意事项\n"
    echoContent yellow "1.手动输入 vbios 文件的绝对路径，例如：/root/vbios.bin"
    echoContent yellow "2.如果 vbios 文件已经存在于 /usr/share/，只需输入 vbios 文件名称\n"

    echoContent red "=============================================================="
    while :
    do
        read -r -p "请输入 (输入 skip 跳过) : " pve_vBiosEnter
        case ${pve_vBiosEnter} in
            skip)
                romfile=""
                echoContent green " ---> 跳过"
                break
                ;;
            *)
                romfile="${pve_vBiosEnter}"
					if [[ "${vbios}" =~ "/" && -f "${vbios}" ]]; then
                    echoContent green " ---> vbios 文件路径：${romfile}"
                    break
                elif [[ -f "/usr/share/kvm/${romfile}" ]]; then
                    echoContent green " ---> vbios 文件名称：${romfile}"
                    break
                else
                    echoContent red " ---> vbios 文件路径输入有误，请重新输入"
                fi
                ;;
        esac
    done

    echoContent skyBlue "\n进度 5/${totalProgress} : BIOS 类型"
    echoContent red "\n=============================================================="
    echoContent yellow "# 注意事项\n"
    echoContent yellow "1.使用 vbios 直通核显输出到显示器，通常选择 SeaBIOS\n"
    echoContent red "\n=============================================================="
    echoContent yellow "1.SeaBIOS"
    echoContent yellow "2.OVMF (UEFI)"
    echoContent yellow "3.跳过"
    echoContent red "=============================================================="
    while :
    do
        read -r -p "请选择 : " pve_BiosChoose
        case ${pve_BiosChoose} in
            1)
                bios="seabios"
                echoContent green " ---> BIOS 类型：${bios}"
                break
                ;;
            2)
                bios="ovmf"
                echoContent green " ---> BIOS 类型：${bios}"
                break
                ;;
            3)
                bios=""
                echoContent green " ---> 跳过"
                break
                ;;
            *)
                bios=""
                echoContent red " ---> 设备序号选择错误，请重新输入"
                ;;
        esac
    done

    echoContent skyBlue "\n进度 5/${totalProgress} : QEMU 计算机类型"
    echoContent red "\n=============================================================="
    echoContent yellow "# 注意事项\n"
    echoContent yellow "1.使用 vbios 直通核显输出到显示器，通常选择 q35\n"
    echoContent red "\n=============================================================="
    echoContent yellow "1.q35"
    echoContent yellow "2.i440fx"
    echoContent yellow "3.跳过"
    echoContent red "=============================================================="
    while :
    do
        read -r -p "请选择 : " pve_MachineChoose
        case ${pve_MachineChoose} in
            1)
                machine="q35"
                echoContent green " ---> QEMU 计算机类型：${machine}"
                break
                ;;
            2)
                machine="i440fx"
                echoContent green " ---> QEMU 计算机类型：${machine}"
                break
                ;;
            3)
                machine=""
                echoContent green " ---> 跳过"
                break
                ;;
            *)
                machine=""
                echoContent red " ---> QEMU 计算机类型选择错误，请重新输入"
                ;;
        esac
    done

    echoContent skyBlue "\n进度 5/${totalProgress} : 虚拟机显示设备"
    echoContent red "\n=============================================================="
    echoContent yellow "# 注意事项\n"
    echoContent yellow "1.使用 vbios 直通核显输出到显示器，通常需要禁用虚拟机显示设备\n"
    echoContent red "\n=============================================================="
    echoContent yellow "1.禁用"
    echoContent yellow "2.跳过"
    echoContent red "=============================================================="
    while :
    do
        read -r -p "请选择 : " pve_VGAChoose
        case ${pve_VGAChoose} in
            1)
                vga="none"
                echoContent green " ---> 虚拟机显示设备：禁用"
                break
                ;;
            2)
                vga=""
                echoContent green " ---> 跳过"
                break
                ;;
            *)
                machine=""
                echoContent red " ---> 虚拟机显示设备选择错误，请重新输入"
                ;;
        esac
    done

    for i in bios vga machine; do   
        if [[ -n "${i}" ]]; then
            eval ${i}_config='$(eval echo -$i \$$i)'
        else
            eval ${i}_config=''
        fi
	done

    if [[ -n "${iGPU_adr}" && -n "${romfile}" ]]; then
		hostpci0_config="-hostpci0 $iGPU_adr,pcie=1,romfile=$romfile,x-vga=1"
	elif [[ -n "${iGPU_adr}" && -z "${romfile}" ]]; then
		hostpci0_config="-hostpci0 $iGPU_adr,pcie=1,x-vga=1"
	else
		hostpci0_config=""
	fi

	if [[ -n "${iAudio_adr}" ]]; then
		hostpci1_config="-hostpci1 $iAudio_adr"
	else
		hostpci1_config=""
	fi

    if [[ ${bios_config} || ${vga_config} || ${machine_config} || ${hostpci0_config} || ${hostpci1_config} ]]; then
	    qm set $vmid ${bios_config} ${vga_config} ${machine_config} ${hostpci0_config} ${hostpci1_config}
        echoContent green " ---> 虚拟机直通配置完成"
	fi
}

# 配置虚拟机扩展参数
pve_args() {
    echoContent skyBlue "\n进度 1/${totalProgress} : 配置虚拟机扩展参数"
    echoContent red "\n=============================================================="
    echoContent yellow "# 注意事项\n"
    echoContent yellow "例如：Intel J4125 直通核显需配置虚拟机扩展参数 -device vfio-pci,host=00:02.0,addr=0x02,x-igd-gms=1,romfile=vbios_1005v4.bin\n"

    # 虚拟机节点
	vm_list=`qm list | grep -v VMID | awk '{print $1,$2}' | awk '{printf("%d.%s\n",NR,$0)}'`
    while :
    do
        echoContent skyBlue "\n进度 1/${totalProgress} : 选择 PVE 虚拟机节点"
        echoContent red "=============================================================="
        echoContent yellow "${vm_list}"
        echoContent red "=============================================================="

        read -r -p "请选择虚拟机节点: " pve_NodeChoose
        vmid=$(echo "$vm_list" | grep "^${pve_NodeChoose}" | sed -E "s/^${pve_NodeChoose}.([^ ]*).*/\1/")
        if [ -n "$vmid" ]; then
            echoContent green " ---> 虚拟机节点：${vmid}"
            break
        else
            echoContent red " ---> 虚拟机节点选择错误，请重新输入"
        fi
    done

    while :
    do
        echoContent skyBlue "\n进度 2/${totalProgress} : 输入虚拟机配置扩展参数"
        read -r -p "请输入虚拟机配置扩展参数 (输入 skip 跳过) : " pve_argsEnter
        case ${pve_argsEnter} in
            skip)
                args=""
                echoContent green " ---> 跳过"
                break
                ;;
            *)
                args="${pve_argsEnter}"
	            qm set $vmid -args "$args"
                echoContent green " ---> 虚拟机 ${vmid} 配置扩展参数设置完成"
                break
                ;;
        esac
    done
}

# PVE IOMMU 选项菜单
pve_IOMMU_menu() {
    pve_IOMMU
    while :
    do
        echoContent skyBlue "\n进度 1/${totalProgress} : PVE 直通设置"
        echoContent red "=============================================================="
        echoContent skyBlue "----------------------PVE  系统直通配置-----------------------"
        echoContent yellow "1.开启 IOMMU"
        echoContent yellow "2.开启 IOMMU 及核显直通"
        echoContent yellow "  注：不支持 N5095/N5105/N6005 及其他 Intel 11代及以后架构的 CPU"
        echoContent yellow "3.恢复默认"
        echoContent skyBlue "----------------------PVE 虚拟机直通配置----------------------"
        echoContent yellow "4.虚拟机直通设备配置"
        echoContent yellow "5.虚拟机扩展参数配置"
        echoContent yellow "0.返回"
        echoContent red "=============================================================="

        # 核显及核显音频的设备 ID
        gpu_id="$(lspci -nn|grep -E 'VGA compatible controller' | sed -r 's/.*\[([0-9]+):([0-9]+)\].*/\1:\2/')"
        audio_id="$(lspci -nn|grep -E 'Audio device' | head -n 1 | sed -r 's/.*\[([0-9]+):([0-9]+)\].*/\1:\2/')"
    
        # 识别 CPU 平台
        cpu_platform="$(lscpu | grep 'Model name' | grep -E 'Intel|AMD')"
        case $cpu_platform in
            *Intel*)
                  cpu="intel"
                  vifo_arg="options vfio-pci ids=$gpu_id,$audio_id disable_vga=1"
                  black_array=(i915 snd_hda_intel)
                  ;;
            *AMD*)
                  cpu="amd"
                  vifo_arg="options vfio-pci ids=$gpu_id,$audio_id disable_idle_d3=1"
                  black_array=(amdgpu snd_hda_intel)
                  ;;
            *)
                  echo -e "不支持的CPU平台，正在终止运行......"
                  sleep 5
                  break
                  ;;
        esac
    
        # 核显及核显音频的总线地址
        iGPU_adr="0000:$(lspci|grep 'VGA compatible controller'|head -n 1|cut -c 1-7)"
        iAudio_adr="0000:$(lspci|grep 'Audio device'|head -n 1|cut -c 1-7)"

        read -r -p "请选择:" pve_IOMMUChoose
        case ${pve_IOMMUChoose} in
            1)
                # 开启 IOMMU
                grub_arg="$grub_default_iommu"
                mod_grub
                Enable_IOMMU_modules
                echoContent green " ---> 开启 IOMMU 设置完毕，重启系统后生效" && ask_user "是否重启？" "echoContent green \"正在重启......\" && reboot" "echoContent green \"不重启......\""
                break
                ;;
            2)
                # 开启 IOMMU+核显直通
                grub_arg="$grub_default_iommu_gpu"
                mod_grub
                Enable_IOMMU_modules
                echoContent green " ---> 开启 IOMMU + 核显直通设置完毕，重启系统后生效" && ask_user "是否重启？" "echoContent green \"正在重启......\" && reboot" "echoContent green \"不重启......\""
                break
                ;;
            3)
                # 恢复非直通状态，关闭 IOMMU
                grub_arg="$grub_default"
                mod_grub
                Disable_IOMMU_modules
                echoContent green " ---> 关闭 IOMMU 设置完毕，重启系统后生效" && ask_user "是否重启？" "echoContent green \"正在重启......\" && reboot" "echoContent green \"不重启......\""
                break
                ;;
            4)
                pve_Passthough
				case_read
                break
                ;;
            5)
                pve_args
				case_read
                break
                ;;
            0)
                break
                ;;
            *)
                echoContent red " ---> 选择错误"
                ;;
        esac
    done
}

pve_cpumode_menu() {
    check_mode(){
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    }

    local conf="/etc/default/cpufrequtils"
    local code='GOVERNOR='
    local cpu_avaliable_modes_array=($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors))
    local cpu_avaliable_modes_list="$(echo "${cpu_avaliable_modes_array[@]}" | sed 's/ /\n/g; s/conservative/&\t保守模式/g; s/ondemand/&\t按需模式/g; s/userspace/&\t用户隔离模式/g; s/powersave/&\t节能模式/g; s/performance/&\t性能模式/g; s/schedutil/&\t调度模式/g;' | awk '{printf("%d.%s\n",NR,$0)}')"
    local ori_mode=`check_mode`

    while :
    do
        echoContent skyBlue "\n功能 1/${totalProgress} : 配置 PVE CPU 工作模式"
        echoContent red "=============================================================="
        echoContent skyBlue "-------------------本系统支持的 CPU 工作模式-------------------"
        echoContent yellow "${cpu_avaliable_modes_list}"
        echoContent yellow "0.返回"
        echoContent red "=============================================================="
        read -r -p "请选择:" pve_CPUModeChoose
        case ${pve_CPUModeChoose} in
            0)
                break
                ;;
            *)
                mode="$(echo "${cpu_avaliable_modes_list}" | grep "^${pve_CPUModeChoose}" | sed -E "s/^${pve_CPUModeChoose}.([^\t]*).*/\1/")"
                if [ -n "${mode}" ]; then
                    echoContent green " ---> 选中的 CPU 运行状态：${ori_mode}"
                    if [ "${mode}" = "${ori_mode}" ]; then
                        echoContent green " ---> 设定模式与原模式一致，不作调整"
                    else
                        if [ -z $(which cpufreq-set) ]; then
                            echoContent green " ---> 安装 cpufrequtils"
                            process_line '进度' '安装'
                            ${installType} cpufrequtils > /dev/null 2>&1
                            if [ -z $(which cpufreq-set) ]; then
                                echoContent red " ---> cpufrequtils 安装失败，请检查 PVE 软件源及网络的连通性、DNS有效性后重试"
                            else
                                echoContent red " ---> cpufrequtils 安装完成"
                            fi
                        fi
    
                        if [ -n $(which cpufreq-set) ]; then
                            echoContent green " ---> 原始 CPU 运行状态：${ori_mode}"
                            echo "GOVERNOR=$mode" > $conf
                            cpufreq-set -g $mode
                            systemctl restart cpufrequtils
                            echoContent green " ---> 当前 CPU 运行状态：`check_mode`"
                        fi
                    fi
                    case_read
                    break
                else
                    echoContent red " ---> 选择错误"
                fi
                ;;
        esac
    done
}

# 键入提示
case_read() {
	read -r -p $'\x0a(按键 Ctrl + C 终止运行脚本，键入任意值返回主菜单): ' choose
	case $choose in
	    *)
		    echoContent white ""
			;;
	esac
}

# 主菜单
menu() {
    cd "$HOME" || exit
    while :
    do
        echoContent red "\n"
        echoContent red "\n=============================================================="
        echoContent green '                                                               
               "    m    m               ""#      mmm                      
             mmm    #  m"   mmm    mmm     #    m"   "  mmm    m mm   mmm  
               #    #m#    #" "#  #" "#    #    #      #" "#   #"  " #"  # 
               #    #  #m  #   #  #   #    #    #      #   #   #     #"""" 
             mm#mm  #   "m "#m#"  "#m#"    "mm   "mmm" "#m#"   #     "#mm"                                                             
               '
        echoContent red "\n=============================================================="
        echoContent green "作者 : Jazz、Weilbyte(PVE 暗黑主题)"
        echoContent green "版本 : $Script_Version"
        echoContent green "Build : $Script_Build"
        echoContent green "描述 : PVE 小工具\c"
        echoContent red "\n==============================================================\n\n"
        echoContent skyBlue "-------------------------PVE 换源工具-------------------------"
        echoContent yellow "1.一键设定 DNS、换源并更新系统"
        echoContent yellow "2.更换 Proxmox VE 源"
        echoContent yellow "3.更新软件包"
        echoContent yellow "4.更新系统"
        echoContent yellow "5.设置系统 DNS"
        echoContent yellow "6.去除无效订阅源提示"
        echoContent skyBlue "-------------------------PVE  UI 修改-------------------------"
        echoContent yellow "7.修改 PVE 概要信息"
        echoContent yellow "8.应用 PVE 暗黑主题"
        echoContent skyBlue "-------------------------PVE 直通配置-------------------------"
        echoContent yellow "9.配置 PVE IOMMU 与设备直通"
        echoContent skyBlue "-----------------------PVE CPU 工作模式-----------------------"
        echoContent yellow "10.配置 CPU 工作模式"
        echoContent yellow "0.退出"
        echoContent red "=============================================================="
        read -r -p "请选择:" selectInstallType
        case ${selectInstallType} in
            1)
                totalProgress=1
                pveAuto_menu
                ;;
            2)
                totalProgress=1
                change_source_menu
                echoContent green " ---> 请执行 apt update 同步更新数据库"
                ;;
            3)
	            echoContent skyBlue "\n功能  1/${totalProgress} : 更新软件包"
                ${update} && ${update}
                echoContent green " ---> 软件包更新完成"
				case_read
                ;;
            4)
	            echoContent skyBlue "\n功能  1/${totalProgress} : 更新系统"
                ${update} && apt ${distupgrade}
                echoContent green " ---> 系统更新完成"
				case_read
                ;;
            5)
                totalProgress=3
                set_DNS
				case_read
                ;;
            6)
                totalProgress=1
                remove_void_soucre_tips 1
				case_read
                ;;
            7)
                totalProgress=1
                pveInfo_menu
                ;;
            8)
                totalProgress=1
                PVEDiscordDark_menu
                ;;
            9)
                totalProgress=6
                pve_IOMMU_menu
                ;;
            10)
                totalProgress=1
                pve_cpumode_menu
                ;;
            0)
                exit 0
                ;;
            *)
                echoContent red " ---> 选择错误"
				case_read
                ;;
        esac
    done
}

initVar "$1"

menu
