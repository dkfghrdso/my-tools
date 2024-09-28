#注意事项

# 在 fnOS 系统上安装 KVM 虚拟化，并使用 Cockpit 进行网页管理

## 1. 安装 KVM 虚拟化组件



首先，更新软件列表和系统包：

```
sudo apt update && sudo apt upgrade -y
```

安装 KVM 及相关工具软件：

```
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

运行以下命令检查 KVM 是否成功安装：

```
sudo systemctl status libvirtd
```

如果服务正在运行，KVM 安装成功。

## 2.安装 Cockpit 管理工具

安装 Cockpit 及其虚拟机管理插件：

```
sudo apt install cockpit cockpit-machines
```

启动 Cockpit 服务：

```启动 Cockpit 服务：
sudo systemctl start cockpit
```

安装完成后即可打开浏览器，输入以下地址访问 Cockpit：

使用您的 fnOS 用户名和密码登录，就可以管理服务器和虚拟机了。

```
http://<您的服务器IP>:9090
```

## 3.关闭 Apparmor 对 Libvirt 安全限制

Libvirt 在执行和访问系统文件的时候会被 Apparmor 阻挡，因此为了确保 Libvirt 始终有必须的权限，必须禁用 Apparmor：

```
ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
```

执行完成后 `reboot` 重启机器。

## 4.创建 Bridge 网络，使虚拟机通过 bridge0 桥接到物理网络

在 Cockpit Web 管理界面进行操作。

## 5.解决虚拟机网桥不通的问题

解决虚拟机无法 ping 通网桥（如 bridge0）内其他主机的问题，需要在 nftables 的规则中添加放行 bridge0 网桥的规则。具体步骤如下：

```
nft add rule ip filter FORWARD iifname "bridge0" accept
nft add rule ip filter FORWARD oifname "bridge0" accept
```

保存规则，使用 nftables 提供的保存功能将当前规则保存到配置文件中：

```
sudo nft list ruleset > /etc/nftables.conf
```

确保 nftables 服务在启动时加载配置：

```
sudo systemctl enable nftables
```

## 6.解决虚拟机开机无法自动启动的问题

虚拟机无法自动启动原因是 libvirtd 服务过早启动，fnOS 的存储和挂载点未准备好，导致虚拟机存储池 vmdisk 未能挂载，虚拟机无法访问到磁盘文件。我们可以修改 libvirtd.service 启动服务，增加判断，当 fnOS 存储目录可以访问时，再启动 libvirtd，这样就可以让虚拟机正常自动启动。

编辑 libvirtd.service 文件：

```
sudo nano /lib/systemd/system/libvirtd.service
```

在 [Service] 中找到这一行：

```
ExecStart=/usr/sbin/libvirtd $LIBVIRTD_ARGS
```

修改为：

```
ExecStart=/bin/bash -c 'while [ ! -d /vol1/1000/vmdisk ]; do sleep 5; done; /usr/sbin/libvirtd $LIBVIRTD_ARGS'
```

效果：

```
[Service]
Type=notify
Environment=LIBVIRTD_ARGS="--timeout 120"
EnvironmentFile=-/etc/default/libvirtd
ExecStart=/bin/bash -c 'while [ ! -d /vol1/1000/vmdisk ]; do sleep 5; done; /usr/sbin/libvirtd $LIBVIRTD_ARGS'
```

至此，教程结束，虚拟机一切功能正常，fnOS 更新不会影响虚拟机的使用，虚拟机的磁盘文件在飞牛的存储池内，也能保证虚拟机数据的安全性。

# 注意事项

### 建议把飞牛 OS 安装在独立的硬盘上，不要在系统盘上再创建存储空间存储数据。 按上面做法，在系统盘损坏或者系统损坏重装后，至少不会丢失存储空间的数据。 存储空间建议使用 RAID1、RAID5 等具有效验恢复能力的阵列存储，提升安全性。 此操作需要具备一定的 Linux 和网络基础知识，不建议新手对 fnOS 底层进行修改操作。 fnOS 仍在测试阶段，可能发生数据丢失损毁的情况，不建议存放重要数据。 虚拟机内不建议存放重要数据，以免虚拟文件损坏导致数据丢失。 无论如何，重要的数据使用冷备份、网盘备份等多重备份才能确保其安全性。
