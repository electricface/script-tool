#!/usr/bin/python3
import os
import stat
import enum
import json
import argparse
import sys

# 关键服务延迟启动的脚本
# Task: https://pms.uniontech.com/zentao/task-view-84636.html

def empty_colored(text, color):
    return text


colored = empty_colored

try:
    import termcolor
    colored = termcolor.colored
except ModuleNotFoundError:
    pass

g_services = [
    # dde-daemon
    {
        "pkgname": "dde-daemon"
    },
    {
        "name": "backlight_helper",
        "path": "/usr/lib/deepin-daemon/backlight_helper",
        "desc": "DDE后端 - 背光设置程序"
    },
    {
        "name": "dde-greeter-setter",
        "path": "/usr/lib/deepin-daemon/dde-greeter-setter",
        "desc": "DDE后端 - 登录界面设置程序"
    },
    {
        "name": "dde-lockservice",
        "path": "/usr/lib/deepin-daemon/dde-lockservice",
        "desc": "DDE后端 - 锁屏鉴权服务"
    },
    {
        "name": "dde-session-daemon",
        "path": "/usr/lib/deepin-daemon/dde-session-daemon",
        "desc": "DDE后端 - 用户级守护程序"
    },
    {
        "name": "dde-system-daemon",
        "path": "/usr/lib/deepin-daemon/dde-system-daemon",
        "desc": "DDE后端 - 系统级守护程序"
    },
    {
        "name": "default-file-manager",
        "path": "/usr/lib/deepin-daemon/default-file-manager",
        "desc": "DDE后端 - 默认文件管理器"
    },
    {
        "name": "default-terminal",
        "path": "/usr/lib/deepin-daemon/default-terminal",
        "desc": "DDE后端 - 默认终端"
    },
    {
        "name": "desktop-toggle",
        "path": "/usr/lib/deepin-daemon/desktop-toggle",
        "desc": "DDE后端 - 显示隐藏桌面"
    },
    {
        "name": "grub2",
        "path": "/usr/lib/deepin-daemon/grub2",
        "desc": "DDE后端 - GRUB配置守护程序"
    },
    {
        "name": "langselector",
        "path": "/usr/lib/deepin-daemon/langselector",
        "desc": "DDE后端 - 语言设置守护程序"
    },
    {
        "name": "soundeffect",
        "path": "/usr/lib/deepin-daemon/soundeffect",
        "desc": "DDE后端 - 音效守护程序"
    },
    # startdde
    {
        "pkgname": "startdde"
    },
    {
        "name": "startdde",
        "path": "/usr/bin/startdde",
        "desc": "DDE后端 - DDE启动守护程序"
    },
    {
        "name": "greeter-display-daemon",
        "path": "/usr/lib/deepin-daemon/greeter-display-daemon",
        "desc": "DDE后端 - 登录界面显示守护程序"
    },
    # dde-api
    {
        "pkgname": "dde-api"
    },
    {
        "name": "adjust-grub-theme",
        "path": "/usr/lib/deepin-api/adjust-grub-theme",
        "desc": "DDE后端 - 调整GRUB主题程序"
    },
    {
        "name": "cursor-helper",
        "path": "/usr/lib/deepin-api/cursor-helper",
        "desc": "DDE后端 - 光标设置辅助程序"
    },
    {
        "name": "deepin-shutdown-sound",
        "path": "/usr/lib/deepin-api/deepin-shutdown-sound",
        "desc": "DDE后端 - 关机音效播放程序"
    },
    {
        "name": "image-blur-helper",
        "path": "/usr/lib/deepin-api/image-blur-helper",
        "desc": "DDE后端 - 模块背景辅助程序"
    },
    {
        "name": "locale-helper",
        "path": "/usr/lib/deepin-api/locale-helper",
        "desc": "DDE后端 - 语言设置辅助程序"
    },
    {
        "name": "sound-theme-player",
        "path": "/usr/lib/deepin-api/sound-theme-player",
        "desc": "DDE后端 - 系统级音效播放程序"
    },
    # lastore-daemon
    {
        "pkgname": "lastore-daemon"
    },
    {
        "name": "lastore-daemon",
        "path": "/usr/libexec/lastore-daemon/lastore-daemon",
        "desc": "DDE后端 - 应用商店守护程序"
    },
    {
        "name": "lastore-smartmirror-daemon",
        "path": "/usr/libexec/lastore-daemon/lastore-smartmirror-daemon",
        "desc": "DDE后端 - 应用商店智能镜像源守护程序"
    },
    # deepin-authentication
    {
        "pkgname": "deepin-authentication"
    },
    {
        "name": "deepin-authentication",
        "path": "/usr/lib/deepin-authenticate/deepin-authentication",
        "desc": "DDE后端 - 验证守护程序"
    },
    # deepin-proxy
    {
        "pkgname": "deepin-proxy"
    },
    {
        "name": "dde-proxy",
        "path": "/usr/lib/deepin-daemon/dde-proxy",
        "desc": "DDE后端 - 网络代理守护程序"
    },
    # deepin-user-experience-daemon
    {
        "pkgname": "deepin-user-experience-daemon"
    },
    {
        "name": "deepin-user-experience-daemon",
        "path": "/usr/bin/deepin-user-experience-daemon",
        "desc": "DDE后端 - 用户体验计划守护程序"
    },
    # deepin-sync-daemon
    {
        "pkgname": "deepin-sync-daemon"
    },
    {
        "name": "deepin-sync-helper",
        "path": "/usr/lib/deepin-deepinid-daemon/deepin-sync-helper",
        "desc": "Web后端 - 系统级云同步辅助程序"
    },
    {
        "name": "deepin-deepinid-daemon",
        "path": "/usr/lib/deepin-deepinid-daemon/deepin-deepinid-daemon",
        "desc": "Web后端 - 用户级云同步守护程序"
    },
]


class ReplaceStatus(enum.Enum):
    NONE = '未替换'
    DONE = '替换完成'
    ABNORMAL = '替换异常'
    NOT_INSTALLED = '未安装'

    def color(self):
        if self == ReplaceStatus.NONE:
            return None
        elif self == ReplaceStatus.DONE:
            return 'yellow'
        elif self == ReplaceStatus.ABNORMAL or self == ReplaceStatus.NOT_INSTALLED:
            return 'red'


def show_all_status():
    print('显示所有的状态')
    for service in g_services:
        if service.get("pkgname"):
            print("\n== 包{} ==".format(service["pkgname"]))
        else:
            show_status(service["name"])


def find_service(name):
    if name.startswith('@'):
        # 虚拟的服务
        path = name[1:]
        if len(path) == 0:
            return None
        return {
            "name": os.path.basename(path),
            "path": path,
            "id": 0,
            "desc": "自定义程序"
        }
    elif name.isdecimal():
        id = int(name)
        for s in g_services:
            if s.get("id") == id:
                return s
    else:
        for s in g_services:
            if s.get("name") == name:
                return s
    return None


def show_status(name, only_one=False):
    service = find_service(name)
    if service is None:
        print_unknown_service(name)
        return

    delay = 0
    status = ReplaceStatus.NONE
    bin = service["path"]
    if not os.path.exists(bin):
        status = ReplaceStatus.NOT_INSTALLED
    else:
        try:
            with open(bin, 'rb') as f:
                content = f.read(30)
                if b'# replace script\n' in content:
                    status = ReplaceStatus.DONE
                    f.seek(0, os.SEEK_SET)
                    lines = f.readlines()
                    found_data = False
                    for line in lines:
                        if line.startswith(b'# data:'):
                            found_data = True
                            try:
                                data = json.loads(line[7:])
                                delay = data["delay"]
                            except json.decoder.JSONDecodeError:
                                status = ReplaceStatus.ABNORMAL
                    if not found_data:
                        status == ReplaceStatus.ABNORMAL
        except:
            status = ReplaceStatus.ABNORMAL

    if status == ReplaceStatus.DONE and (not os.path.exists(bin + ".real")):
        status = ReplaceStatus.ABNORMAL
    status_line = ""
    if service["id"] != 0:
        status_line += "[{:02}] ".format(service["id"])
    status_line += "{}, {}, {}".format(service["name"], service["desc"],
                                       colored(status.value, status.color()))
    if status == ReplaceStatus.DONE:
        status_line += ", 延迟 {} 秒".format(delay)
    print(status_line)
    if only_one:
        print('路径:', service["path"])


def restore(name, only_one=False):
    service = find_service(name)
    if service is None:
        print_unknown_service(name)
        return
    bin = service["path"]
    is_script = False
    try:
        with open(bin, 'rb') as f:
            content = f.read(30)
            if b'# replace script\n' in content:
                #print("it is a replace script\n")
                is_script = True
    except:
        pass
    path_real = bin + ".real"
    if is_script and os.path.exists(path_real):
        os.remove(bin)
        os.rename(path_real, bin)
        if only_one:
            print('恢复完成')
    else:
        if only_one:
            print('未做操作')


def restore_all():
    for service in g_services:
        if service.get("name"):
            restore(service["name"])
    print('已恢复所有的')


def print_unknown_service(name):
    print('未找到程序或服务', name)


def set_delay(name, delay):
    service = find_service(name)
    if service is None:
        print_unknown_service(name)
        return

    need_rename = True
    bin = service["path"]

    if not os.path.exists(bin):
        print('未安装程序', bin)
        return

    with open(bin, 'rb') as f:
        content = f.read(30)
        if b'# replace script\n' in content:
            #print("it is a replace script\n")
            need_rename = False

    dst = bin + ".real"
    if need_rename:
        os.rename(bin, dst)

    # 写替换脚本，用来延迟并执行真的可执行文件。
    with open(bin, 'w') as f:
        lines = [
            "#!/bin/sh\n",
            "# replace script\n",
            "# data:{}\n".format(json.dumps({"delay": delay})),
            "sleep {}\n".format(delay),
            "exec {} \"$@\"\n".format(dst)
        ]
        f.writelines(lines)
    # 加权限 0755
    os.chmod(bin, stat.S_IRWXU | stat.S_IRGRP |
             stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)


# 检查权限，一些操作只有 root 能做。
def check_privilege():
    uid = os.geteuid()
    if uid != 0:
        print("请使用root用户权限操作，或加 sudo。")
        exit(1)


g_id = 0


def add_id(service):
    if service.get("name"):
        global g_id
        g_id += 1
        service["id"] = g_id
    return service


if __name__ == '__main__':
    epilog = '''
一般用法：
显示所有状态
$arg0
或 $arg0 -S

查看具体程序或服务状态，可以用数字 id 指代。
$arg0 -s dde-system-daemon
或 $arg0 -s 1
或 $arg0 -S -s dde-system-daemon

设置某个程序或服务延迟
sudo $arg0 -s dde-system-daemon -d 10
或 sudo $arg0 -s 1 -d 10

恢复所有
sudo $arg0 -r

恢复某个程序或服务
sudo $arg0 -s dde-system-daemon -r
或 sudo $arg0 -s 1 -r

自定义程序
有些程序本脚本没有支持，也可以使用 -p 参数替代 -s 参数。-p 参数为程序路径。
设置延迟 sudo $arg0 -p /usr/bin/xcalc -d 10
显示状态 $arg0 -p /usr/bin/xcalc
或 $arg0 -p /usr/bin/xcalc -S
恢复 sudo $arg0 -p /usr/bin/xcalc -r

附加功能 - 彩色显示状态
如果安装了 termcolor 包，则以彩色显示特殊状态。
sudo apt install python3-termcolor
或 sudo pip3 install termcolor
'''

    epilog = epilog.replace('$arg0', sys.argv[0])
    parser = argparse.ArgumentParser(
        epilog=epilog, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-s', '--service', dest='service',
                        type=str, help='服务名')
    parser.add_argument('-S', '--status', dest='show_status',
                        action='store_true', help='显示状态')
    parser.add_argument('-d', '--delay', dest='delay', type=int, help='设置延迟秒数')
    parser.add_argument('-r', '--restore', dest='restore',
                        action='store_true', help='恢复')
    parser.add_argument('-p', '--path', dest='path', help='只指定程序路径')
    args = parser.parse_args()

    if args.path:
        args.service = '@' + args.path

    g_services = [add_id(s) for s in g_services]

    # print('g_services:',g_services)
    # print('args:',args)

    if args.show_status and args.service is None:
        show_all_status()
    elif args.show_status and args.service:
        show_status(args.service, True)
    elif args.delay is not None and args.service:
        check_privilege()
        set_delay(args.service, args.delay)
    elif args.restore and args.service is None:
        check_privilege()
        restore_all()
    elif args.restore and args.service:
        check_privilege()
        restore(args.service, True)
    elif len(sys.argv) == 1:
        show_all_status()
    elif (args.delay is None) and (not args.restore) and args.service:
        show_status(args.service, True)
