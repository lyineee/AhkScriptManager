;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 蓝蓝小雪 作品
; lyine 支持到ahk2.0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; #Include lib/InsertionSort.ahk
#Warn All, Off
Persistent true
#SingleInstance force

TMP_DIR := "\tmp\"
global SCRIPT_TMP_DIR := A_ScriptDir TMP_DIR
global SCRIPT_DIR := A_ScriptDir "\scripts\"
global INI_FILE := A_ScriptDir "\setting.ini"
SetWorkingDir(A_ScriptDir)

DetectHiddenWindows True ; 允许探测脚本中隐藏的主窗口. 很多子程序均是以隐藏方式运行的
SetTitleMatchMode 2 ; 避免需要指定如下所示的文件的完整路径

Paths:=EnvGet("PATH")
EnvSet("PATH", A_ScriptDir "\3rd") ;%Paths%	; 设置环境变量. 通过AhkScriptManager启动的程序均持有该环境变量

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 初始化 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

global scriptCount := "0"

OnExit(ExitSub)

; Declare tray item
global scriptListTray:=Menu() ; "启动脚本"子菜单
global restartScriptListTray := Menu() ;

global ScriptList := Array() ;读取到的脚本
global ScriptStatus := Array() ;脚本运行的状态 0-未运行 1-运行

; 初始化临时文件夹
if(!DirExist(SCRIPT_TMP_DIR))
    DirCreate(SCRIPT_TMP_DIR)
FileCopy(SCRIPT_DIR "*.ahk", SCRIPT_TMP_DIR "*.*", 1)

; 遍历SCRIPT_TMP_DIR下的ahk文件
Loop Files (SCRIPT_TMP_DIR "*.ahk"){
    menuName := SubStr(A_LoopFileName, 1, -1*(StrLen(".ahk")))
    scriptCount += 1
    FileAppend("#NoTrayIcon",SCRIPT_TMP_DIR A_LoopFileName) ; 设置不出现在托盘
    ; 已经打开则关闭，否则无法被AHK Manager接管
    if(WinExist(A_LoopFileName . " - AutoHotkey"))
        WinKill

    ScriptList.InsertAt(scriptCount,A_LoopFileName)
    ; InsertionSort(&ScriptList)
    ScriptStatus.InsertAt(scriptCount,0)
}

; 主菜单
TraySetIcon(A_ScriptDir "\resources\ahk.ico")
A_TrayMenu.Delete()
A_TrayMenu.Add("AHK Script Manager",Menu_Tray_Handler)
A_TrayMenu.Disable("AHK Script Manager")
A_TrayMenu.Add()
A_TrayMenu.Add("脚本列表(&S)", scriptListTray ) ; S: Start
A_TrayMenu.Add()
A_TrayMenu.Add("重载脚本(&R)", restartScriptListTray ) ; R: Restart
A_TrayMenu.Add("启动所有脚本(&C)", TskOpenAllHandler ) ; C: Close
A_TrayMenu.Add("关闭所有脚本(&A)", TskCloseAllHandler ) ; A: All
A_TrayMenu.Add()
A_TrayMenu.Add("打开源码目录(&D)", Menu_Tray_OpenDir ) ; D: Directory
A_TrayMenu.Add()
A_TrayMenu.Add("重启Manager(&B)", Menu_Tray_Reload ) ; B: reBoot
A_TrayMenu.Add()
A_TrayMenu.Add( "退出(&X)", Menu_Tray_Exit)

; 程序启动时，加载所有可启动脚本
TskOpenAll()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 菜单事件响应 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 开/关选中脚本
TskToggleHandler(ItemName, ItemPos, Menu){
    for item in ScriptList{
        ItemName_ext := ItemName ".ahk"
        if(item=ItemName_ext){
            index := A_Index
            if(!WinExist(ItemName_ext . " - AutoHotkey")){ ; 没有打开
                Run(SCRIPT_TMP_DIR ItemName_ext)
                ScriptStatus[index] := 1
                setAutoLauch(ItemName, True)
            }else{
                WinClose(ItemName_ext " - AutoHotkey")
                ScriptStatus[index] := 0
                setAutoLauch(ItemName, False)
            }
        }
    }
    RecreateMenus()
    Return
}

; 重新启动选中脚本
TskRestartHandler(ItemName, ItemPos, Menu){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(thisScript = ItemName . ".ahk"){
            WinClose(thisScript " - AutoHotkey")
            Run(SCRIPT_TMP_DIR thisScript)
            Break
        }
    }
    Return
}

; 启动所有驻守脚本，从读文件开始就已经被排序了，所以无需排序
TskOpenAll(){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(ScriptStatus[A_Index] = 0 && isAutoLaunch(StrReplace(thisScript,".ahk"))){ ; 程序没打开且在默认打开列表中
            if(!WinExist(thisScript . " - AutoHotkey")){ ; 没有打开
                Run(SCRIPT_TMP_DIR thisScript)
                ScriptStatus[A_Index] := 1
            }
        }
    }
    RecreateMenus() ; refresh menu
    Return
}

TskOpenAllHandler(ItemName, ItemPos, Menu){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(ScriptStatus[A_Index] = 0){ ; 没打开
            if(!WinExist(thisScript . " - AutoHotkey")){ ; 没有打开
                Run(SCRIPT_TMP_DIR thisScript)
                ScriptStatus[A_Index] := 1
            }
        }
    }
    RecreateMenus() ; refresh menu
    Return
}

; 关闭所有脚本
TskCloseAllHandler(ItemName, ItemPos, Menu){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(ScriptStatus[A_Index] = 1 && WinExist(thisScript . " - AutoHotkey")){ ; 已打开
            WinClose(thisScript " - AutoHotkey")
            ScriptStatus[A_Index] := 0
            menuName:=StrReplace(thisScript, ".ahk",,, 1)
        }
    }
    RecreateMenus() ; refresh menu
    Return
}


; 打开源码目录
Menu_Tray_OpenDir(ItemName, ItemPos, Menu){
    Run(SCRIPT_DIR,, "Max")
    Return
}

; 重启Manager
Menu_Tray_Reload(ItemName, ItemPos, Menu){
    Reload
    Return
}

; 退出
Menu_Tray_Exit(ItemName, ItemPos, Menu){
    ExitApp
    Return
}

; 空操作
Menu_Tray_Handler(ItemName, ItemPos, Menu){
    Return
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 创建菜单 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 创建子菜单
CreateMenus(input_menu, title:="脚本列表"){
    input_menu.Add(title, Menu_Tray_Handler)
    input_menu.Disable(title)
    ; input_menu.Check("启动脚本")
    input_menu.Add()
    Return
}

; refresh menu
RecreateMenus(){
    scriptListTray.Delete() ; 剩下空菜单
    CreateMenus(scriptListTray, "脚本列表")

    for menuName_ext in ScriptList{
        ; refresh script status
        ; MsgBox menuName_ext
        ; if(WinExist(menuName_ext . " - AutoHotkey"))
        ;     ScriptStatus[A_Index] := 1
        ; Else
        ;     ScriptStatus[A_Index] := 0
        menuName:=StrReplace(menuName_ext,".ahk")
        scriptListTray.Add(menuName, TskToggleHandler)
        if(ScriptStatus[A_Index]){
            restartScriptListTray.Add(menuName,TskRestartHandler) ; "重载脚本" 菜单
            scriptListTray.Check(menuName)
        }
        else
            scriptListTray.unCheck(menuName)
    }
}

; get setting
isAutoLaunch(scriptName){
    Return IniRead(INI_FILE, "AutoLauch", scriptName, False)
}

; set setting
setAutoLauch(scriptName, isAutoLaunch){
    IniWrite(isAutoLaunch, INI_FILE, "AutoLauch", scriptName)
    Return
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 程序清理 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExitSub(ExitReason, ExitCode){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(WinExist(thisScript " - AutoHotkey")){ ; 已打开
            try{
                WinClose(thisScript " - AutoHotkey")
            }
        }
    }
    FileDelete(SCRIPT_TMP_DIR "*")
    ExitApp
    Return
}
