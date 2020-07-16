;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 蓝蓝小雪 作品
; lyine 支持到ahk2.0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 注意: 当更新系统环境变量时，需要退出本程序后再重启，才能使得环境变量的更改有效
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#Include lib/InsertionSort.ahk

#Persistent
#SingleInstance force

SetWorkingDir(A_ScriptDir "\scripts\")

DetectHiddenWindows True ; 允许探测脚本中隐藏的主窗口. 很多子程序均是以隐藏方式运行的
SetTitleMatchMode 2 ; 避免需要指定如下所示的文件的完整路径

Paths:=EnvGet("PATH")
EnvSet("PATH", A_ScriptDir "\3rd") ;%Paths%	; 设置环境变量. 通过AhkScriptManager启动的程序均持有该环境变量

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 初始化 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

global scriptCount := "0"

OnExit("ExitSub")

; Declare tray item
global scripts_restart:=Menu.New() ; "重载脚本"子菜单
global scripts_unclose:=Menu.New() ; "关闭脚本"子菜单
global scripts_unopen:=Menu.New() ; "启动脚本"子菜单

CreateMenus(scripts_restart, "重载脚本")
CreateMenus(scripts_unclose, "关闭脚本")
CreateMenus(scripts_unopen, "启动脚本")

global ScriptList := Array() ;读取到的脚本
global ScriptStatus := Array() ;脚本运行的状态 0-未运行 1-运行

; 遍历scripts目录下的ahk文件
Loop Files (A_ScriptDir "\scripts\*.ahk"){
    menuName := SubStr(A_LoopFileName, 1, -1*(StrLen(".ahk")))
    scriptCount += 1
    
    ; 已经打开则关闭，否则无法被AHK Manager接管
    if(WinExist(A_LoopFileName . " - AutoHotkey"))
        WinKill
    
    ScriptList.InsertAt(scriptCount,A_LoopFileName)
    ScriptStatus.InsertAt(scriptCount,0)
}

; 主菜单
TraySetIcon(A_ScriptDir "\resources\ahk.ico")
A_TrayMenu.Delete()
A_TrayMenu.Add("AHK Script Manager","Menu_Tray_Handler")
A_TrayMenu.Disable("AHK Script Manager")
A_TrayMenu.Add()
A_TrayMenu.Add("启动脚本(&S)", scripts_unopen ) ; S: Start
A_TrayMenu.Add()
A_TrayMenu.Add("重载脚本(&R)", scripts_restart ) ; R: Restart
A_TrayMenu.Add("关闭脚本(&C)", scripts_unclose ) ; C: Close
A_TrayMenu.Add("关闭所有脚本(&A)", "TskCloseAll" ) ; A: All
A_TrayMenu.Add()
A_TrayMenu.Add()
A_TrayMenu.Add("打开源码目录(&D)", "Menu_Tray_OpenDir" ) ; D: Directory
A_TrayMenu.Add()
A_TrayMenu.Add("重启Manager(&B)", "Menu_Tray_Reload" ) ; B: reBoot
A_TrayMenu.Add()
A_TrayMenu.Add( "退出(&X)", "Menu_Tray_Exit")

; 依次添加脚本到启动脚本菜单，类型间加入分隔线
ScriptName:=Array()
for menuName in ScriptList{
    menuName:=StrReplace(menuName,".ahk")
    ScriptName.Push(menuName)
}
AddToUnOpenMenu(ScriptName, false)
; 程序启动时，加载所有可启动脚本
TskOpenAll()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 菜单事件响应 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 启动选中脚本
TskOpenHandler(ItemName, ItemPos, Menu){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(thisScript = ItemName . ".ahk"){
            if(!WinExist(thisScript . " - AutoHotkey")) ; 没有打开
                Run(A_ScriptDir "\scripts\" thisScript)
            ScriptStatus[A_Index] := 1
            Break
        }
    }
    RecreateMenus()
    Return
}

; 关闭选中脚本
TskClose(ItemName, ItemPos, Menu){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(thisScript = ItemName . ".ahk"){
            WinClose(thisScript " - AutoHotkey")
            ScriptStatus[A_Index] := 0
            Break
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
            Run(A_ScriptDir "\scripts\" thisScript)
            Break
        }
    }
    Return
}

; 启动所有驻守脚本，从读文件开始就已经被排序了，所以无需排序
TskOpenAll(){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(ScriptStatus[A_Index] = 0){ ; 没打开
            if(!WinExist(thisScript . " - AutoHotkey")){ ; 没有打开
                Run(A_ScriptDir "\scripts\" thisScript)
                ScriptStatus[A_Index] := 1
                menuName := StrReplace(thisScript, ".ahk",,, 1)
                scripts_unclose.Add(menuName, "TskClose")
                scripts_restart.Add(menuName, "TskRestartHandler")
                scripts_unopen.Delete(menuName)
            }
        }
    }
    Return
}

; 关闭所有脚本
TskCloseAll(ItemName, ItemPos, Menu){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(ScriptStatus[A_Index] = 1){ ; 已打开
            WinClose(thisScript " - AutoHotkey")
            ScriptStatus[A_Index] := 0
            menuName:=StrReplace(thisScript, ".ahk",,, 1)
            scripts_unopen.Add(menuName, "TskOpenHandler")
            scripts_unclose.Delete(menuName)
            scripts_restart.Delete(menuName)
        }
    }
    Return
}

; 打开源码目录
Menu_Tray_OpenDir(ItemName, ItemPos, Menu){
    Run(A_ScriptDir "\scripts",, "Max")
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
CreateMenus(input_menu, title:="启动脚本"){
    input_menu.Add(title, "Menu_Tray_Handler")
    input_menu.Disable(title)
    ; input_menu.Check("启动脚本")
    input_menu.Add()
    Return
}
; 重建子菜单
RecreateMenus(){
    scripts_unopen.Delete() ; 剩下空菜单
    scripts_unclose.Delete() ; 剩下空菜单
    scripts_restart.Delete() ; 剩下空菜单
    
    CreateMenus(scripts_restart, "重载脚本")
    CreateMenus(scripts_unclose, "关闭脚本")
    CreateMenus(scripts_unopen, "启动脚本")
    
    OpenList := Array()
    UnOpenList := Array()
    loop(scriptCount){
        menuName:=StrReplace(ScriptList[A_Index],".ahk")
        if(ScriptStatus[A_Index]=0)
            UnOpenList.Push(menuName)
        else
            OpenList.Push(menuName)
    }
    ; 依次添加脚本到重载脚本/关闭脚本菜单，类型间加入分隔线
    AddToOpenMenu(OpenList, false)
    ; 依次添加脚本到启动脚本菜单，类型间加入分隔线
    AddToUnOpenMenu(UnOpenList)
    Return
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 程序清理 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExitSub(ExitReason, ExitCode){
    Loop(scriptCount){
        thisScript := ScriptList[A_Index]
        if(ScriptStatus[A_Index] = 1){ ; 已打开
            WinClose(thisScript " - AutoHotkey")
            ScriptStatus[A_Index] := 0
        }
    }
    ExitApp
    Return
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 函数 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 为启动脚本菜单添加一种类型的脚本
AddToUnOpenMenu(UnOpenList, AllowSplit:=true){
    InsertionSort(UnOpenList)
    for menuName in UnOpenList{
        scripts_unopen.Add(menuName, "TskOpenHandler")
    }
    ; 必要时加分隔线
    if(AllowSplit = true){
        for Files in UnOpenList{
            scripts_unopen.Add()
            Break
        }
    }
}

; 为重载脚本/关闭脚本菜单添加一种类型的脚本
AddToOpenMenu(OpenList, AllowSplit:=true){
    InsertionSort(OpenList)
    for menuName in OpenList{
        scripts_unclose.Add(menuName, "TskClose")
        scripts_restart.Add(menuName, "TskRestartHandler")
    }
    
    ; 必要时加分隔线
    if(AllowSplit = true){
        for Files in OpenList{
            scripts_unclose.Add()
            scripts_restart.Add()
            Break
        }
    }
}

