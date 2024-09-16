在fnOS系统上安装 KVM 虚拟化，并使用 Cockpit 进行网页管理，可以按照以下步骤进行：
1. 安装 KVM虚拟化组件
首先，更新软件列表和系统包：
sudo apt update && sudo apt upgrade -y安装 KVM 及相关工具软件：
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils运行以下命令检查 KVM 是否成功安装：
sudo systemctl status libvirtd如果服务正在运行，KVM 安装成功。

2. 安装 Cockpit管理工具
安装 Cockpit 及其虚拟机管理插件：
sudo apt install cockpit cockpit-machines启动 Cockpit 服务：
sudo systemctl start cockpit安装完成后即可打开浏览器，输入以下地址访问Cockpit：
http://<您的服务器IP>:9090使用您的fnOS用户名和密码登录，就可以管理服务器和虚拟机了。

3.关闭Apparmor对Libvirt安全限制
Libvirt在执行和访问系统文件的时候会被Apparmor阻挡，因此为了确保Libvirt始终有必须的权限，必须禁用apparmor：
ln -s /etc/apparmor.d/usr.sbin.libvirtd  /etc/apparmor.d/disable/
apparmor_parser -R  /etc/apparmor.d/usr.sbin.libvirtd执行完成后reboot重启机器。

4.创建Bridge网络，使虚拟机通过bridge0桥接到物理网络
在Cockpit Web管理界面进行操作

5.安装虚拟机（以OpenWrt为例）
在Cockpit Web管理界面进行操作（这一步需先创建虚拟机存储池）

6.解决虚拟机网桥不通的问题
解决虚拟机无法 ping 通网桥（如 bridge0）内其他主机的问题，需要在 nftables 的规则中添加放行 bridge0 网桥的规则。具体步骤如下：
1. 允许 bridge0 网桥的流量，在 filter 表的 FORWARD 链中添加规则，以允许通过 bridge0 网桥的流量，这样可以确保来自虚拟机的流量可以通过网桥转发到其他主机：
nft add rule ip filter FORWARD iifname "bridge0" accept
nft add rule ip filter FORWARD oifname "bridge0" accept2. 保存规则，使用 nftables 提供的保存功能将当前规则保存到配置文件中：
sudo nft list ruleset > /etc/nftables.conf3.确保 nftables 服务在启动时加载配置：
sudo systemctl enable nftables
7.解决虚拟机开机无法自动启动的问题
虚拟机无法自动启动原因是libvirtd服务过早启动，fnOS的存储和挂载点未准备好，导致虚拟机存储池vmdisk未能挂载，虚拟机无法访问到磁盘文件，我们可以修改libvirtd.service启动服务，增加判断，当fnOS存储目录可以访问时，再启动libvirtd，这样就可以让虚拟机正常自动启动。
编辑libvirtd.service文件：
sudo nano /lib/systemd/system/libvirtd.service在[Service]中找到这一行：
ExecStart=/usr/sbin/libvirtd $LIBVIRTD_ARGS
修改为改为：
ExecStart=/bin/bash -c 'while [ ! -d /vol1/1000/vmdisk ]; do sleep 5; done; /usr/sbin/libvirtd $LIBVIRTD_ARGS'
增加了对/vol1/1000/vmdisk路径访问到判断，可以按自己路径进行修改，改完以后效果：
[Service]
Type=notify
Environment=LIBVIRTD_ARGS="--timeout 120"
EnvironmentFile=-/etc/default/libvirtd
ExecStart=/bin/bash -c 'while [ ! -d /vol1/1000/vmdisk ]; do sleep 5; done; /usr/sbin/libvirtd $LIBVIRTD_ARGS'
至此，教程结束，虚拟机一切功能正常，fnOS更新不会影响虚拟机的使用，虚拟机的磁盘文件在飞牛的存储池内，也能保证虚拟机数据的安全性。




其他1：调整虚拟机关机超时时间（可选）
有些虚拟机不支持acpid 或者无法安装ga代理工具，可能出现无法响应关机命令，造成fnOS关机或者重启过慢。
可以修改 /etc/default/libvirt-guests文件中的相关设置，调整关机超时时间减少等待，配置文件也可以控制虚拟机关机的相关动作，默认的关机时间为300s，即5分钟：
SHUTDOWN_TIMEOUT=300
根据自己情况修改，修改完成后，重新启动 libvirt 服务生效：
sudo systemctl restart libvirtd
其他2：虚拟机的快照功能（可选）
如果需要使用快照功能，需要使用下面命令将img格式的磁盘文件转换为qcow2格式：
qemu-img convert -f raw -O qcow2 /path/to/source.img /path/to/destination.qcow2
其他3：使用iptables，解决虚拟机网桥不通（供参考，无需操作，已用nf实现）
1.放行bridge0流量：
sudo iptables -A FORWARD -i bridge0 -j ACCEPT
sudo iptables -A FORWARD -o bridge0 -j ACCEPT2.安装iptables-persisten使tiptables规则持久化保存：
sudo apt install iptables-persistent
虚拟机配置数据的备份
虚拟机创建好以后，配置文件存放在/etc/libvirt/qemu/ 路径下
定时对此路径下的文件进行备份，当系统意外崩溃损坏后重装后，
可以导入虚拟机的配置文件，快速恢复虚拟机。
前提是虚拟磁盘文件是正常的，所以不建议在系统盘创建存储空间存放数据，
重要数据应该存放在带有效验恢复能力的RAID1 RAID5等阵列中，加以保护。

注意事项
• 建议把飞牛OS安装在独立的硬盘上，不要在系统盘上再创建存储空间存储数据。
• 按上面做法，在系统盘损坏或者系统损坏重装后，至少不会丢失存储空间的数据。
• 存储空间建议使用RAID1 RAID5等具有效验恢复能力的阵列存储，提升安全性。
• 此操作需要具备一定的Linux和网络基础知识，不建议新手对fnOS底层进行修改操作。
• fnOS仍在测试阶段，可能发生数据丢失损毁的情况，不建议存放重要数据。
• 虚拟机内不建议存放重要数据，以免虚拟文件损坏导致数据丢失。
• 无论如何，重要的数据使用冷备份、网盘备份等多重备份才能确保其安全性。