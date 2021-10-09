#!/usr/bin/python3
import os
import stat
import enum
import json
import argparse
import sys

g_services = [
    {
        "name": "dde-system-daemon",
        "path": "/usr/lib/deepin-daemon/dde-system-daemon",
                "desc": "DDE后端 - 系统级守护进程"
    },
    {
        "name": "dde-session-daemon",
        "path": "/usr/lib/deepin-daemon/dde-session-daemon",
                "desc": "DDE后端 - 用户级守护进程"
    },
    {
        "name": "xcalc",
                "path": "/usr/bin/xcalc",
                "desc": "测试程序"
    }
]


class ReplaceStatus(enum.Enum):
    NONE = '未替换'
    DONE = '替换完成'
    ABNORMAL = '替换异常'


def show_all_status():
    for service in g_services:
        show_status(service["name"])


def show_status(name):
    service = None
    for s in g_services:
        if s["name"] == name:
            service = s
            break
    if service is None:
        # TODO
        return

    delay = 0
    status = ReplaceStatus.NONE
    bin = service["path"]
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

    if status == ReplaceStatus.DONE and (not os.path.exists(bin + ".real")):
        status = ReplaceStatus.ABNORMAL
    status_line = "{}, {}, {}".format(name, service["desc"], status.value)
    if status == ReplaceStatus.DONE:
        # print("延迟{}秒".format(delay))
        status_line += ", 延迟 {} 秒".format(delay)
    print(status_line)


def restore(name):
    service = None
    for s in g_services:
        if s["name"] == name:
            service = s
            break
    if service is None:
        # TODO
        return
    bin = service["path"]
    is_script = False
    with open(bin, 'rb') as f:
        content = f.read(30)
        if b'# replace script\n' in content:
            #print("it is a replace script\n")
            is_script = True
    path_real = bin + ".real"
    if is_script and os.path.exists(path_real):
        os.remove(bin)
        os.rename(path_real, bin)


def restore_all():
    for service in g_services:
        restore(service["name"])

def set_delay(name, delay):
    service = None
    for s in g_services:
        if s["name"] == name:
            service = s
            break
    if service is None:
        # TODO
        return

    need_rename = True
    bin = service["path"]
    with open(bin, 'rb') as f:
        content = f.read(30)
        if b'# replace script\n' in content:
            #print("it is a replace script\n")
            need_rename = False

    dst = bin + ".real"
    if need_rename:
        os.rename(bin, dst)
    with open(bin, 'w') as f:
        lines = [
            "#!/bin/sh\n",
            "# replace script\n",
            "# data:{}\n".format(json.dumps({"delay": delay})),
            "sleep {}\n".format(delay),
            "exec {}\n".format(dst)
        ]
        f.writelines(lines)
    os.chmod(bin, stat.S_IRWXU | stat.S_IRGRP |
             stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)


def check_privilege():
    uid = os.geteuid()
    if uid != 0:
        print("run with root user")
        exit(1)


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--service', dest='service',
                        type=str, help='服务名')
    parser.add_argument('-S', '--status', dest='show_status',
                        action='store_true', help='显示状态')
    parser.add_argument('-d', '--delay', dest='delay', type=int, help='设置延迟秒数')
    parser.add_argument('-r', '--restore', dest='restore',
                        action='store_true', help='恢复')
    args = parser.parse_args()

    # print("args:", args)
    if args.show_status and args.service is None:
        show_all_status()
    elif len(sys.argv) == 1:
        show_all_status()
    elif args.show_status and args.service:
        show_status(args.service)
    elif args.delay is not None and args.service:
        check_privilege()
        set_delay(args.service, args.delay)
    elif args.restore and args.service is None:
        check_privilege()
        restore_all()
    elif args.restore and args.service:
        check_privilege()
        restore(args.service)
