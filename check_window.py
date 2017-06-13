#!/usr/bin/python3
import subprocess
import psutil
from pydbus import SessionBus

win_id = subprocess.check_output(['xdotool', 'selectwindow'])
win_id = win_id.decode('ascii').strip()
print("window id:", win_id)
subprocess.run(['xprop', '-id', win_id, 'WM_CLASS', 'WM_NAME', '_GTK_APPLICATION_ID'])

xprop_wm_pid = subprocess.check_output(['xprop', '-id', win_id, '_NET_WM_PID' ])
wm_pid = int((xprop_wm_pid.split())[2].decode('ascii'))
print("pid:", wm_pid)

process = psutil.Process(wm_pid)
print("ppid:", process.ppid())
print("wm cmdline:", process.cmdline())
env = process.environ()
desktop_file = env.get('GIO_LAUNCHED_DESKTOP_FILE')
desktop_file_pid_str = env.get('GIO_LAUNCHED_DESKTOP_FILE_PID')
print('GL DESKTOP_FILE:', desktop_file)
print('GL DESKTOP_FILE_PID:', desktop_file_pid_str)
if desktop_file_pid_str is not None:
    desktop_file_pid = int(desktop_file_pid_str)
    if psutil.pid_exists(desktop_file_pid):
        process1 = psutil.Process(int(desktop_file_pid))
        print('GL cmdline:', process1.cmdline())
    else:
        print('process exited')

# const
dock_daemon_dest = 'com.deepin.dde.daemon.Dock'
session_bus = SessionBus()
dock_manager = session_bus.get(dock_daemon_dest, "/com/deepin/dde/daemon/Dock")

print("Identify method:", dock_manager.QueryWindowIdentifyMethod(int(win_id)))


for entry_obj_path in dock_manager.Entries:
    entry = session_bus.get(dock_daemon_dest, entry_obj_path)
    win_titles = entry.WindowTitles
    # print(win_titles)
    if int(win_id) in win_titles:
        print("dock entry:", entry_obj_path)
        desktop_file = entry.DesktopFile
        print('prop DesktopFile:', desktop_file)


    


