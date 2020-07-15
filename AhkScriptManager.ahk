﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 蓝蓝小雪 作品
; http://wwww.snow518.cn/
; 修改自：http://ahk.5d6d.com/thread-701-1-3.html
; 增加了快捷键、编辑、重载某个单独的脚本
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 注意: 当更新系统环境变量时，需要退出本程序后再重启，才能使得环境变量的更改有效
;
; 删除一些不必要的功能，增加非驻守脚本(文件名以"+"开头)的处理
; gaochao.morgen@gmail.com
; 2014/2/1
;
; 增加菜单排序功能
; gaochao.morgen@gmail.com
; 2014/2/10
;
; 增加进程PID显示
; gaochao.morgen@gmail.com
; 2014/2/13
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

;  declare tray item
global scripts_restart:=Menu.New() ; "重载脚本"子菜单
global scripts_unclose:=Menu.New() ; "关闭脚本"子菜单
global scripts_unopen:=Menu.New() ; "启动脚本"子菜单

CreateMenus(scripts_restart)
CreateMenus(scripts_unclose)
CreateMenus(scripts_unopen)

global ScriptList := Array() ;读取到的脚本
global ScriptStatus := Array() ;脚本运行的状态 0-未运行 1-运行

OpenListTemp := Array()		; 已运行程序列表中的临时驻守脚本
OpenListDeamon := Array()	; 已运行程序列表中的驻守脚本

UnOpenListTemp := Array()	; 未运行程序列表中的临时驻守脚本
UnOpenListOnce := Array()	; 未运行程序列表中的非驻守脚本
UnOpenListDeamon := Array()	; 未运行程序列表中的驻守脚本

; 遍历scripts目录下的ahk文件
Loop Files (A_ScriptDir "\scripts\*.ahk")
{
    menuName := SubStr(A_LoopFileName, 1, -1*(StrLen(".ahk")))
    scriptCount += 1
    
    ; 已经打开则关闭，否则无法被AHK Manager接管
    if WinExist(A_LoopFileName . " - AutoHotkey")
    {
        ; scriptsExisted%scriptCount% = 1
        WinKill
    }
    
    ; global scriptsName%scriptCount% := A_LoopFileName
    ScriptList.InsertAt(scriptCount,A_LoopFileName)
    ; global scriptsOpened%scriptCount% := 0
    ScriptStatus.InsertAt(scriptCount,0)
    
    if InStr(menuName, "!", (A_StringCaseSense="On") ? true : false) ; 文件名中含"!"表示临时驻守脚本
    {
        UnOpenListTemp.Push(menuName)
        Continue
    }
    
    if InStr(menuName, "+", (A_StringCaseSense="On") ? true : false) ; 文件名中含"+"表示非驻守脚本
    {
        UnOpenListOnce.Push(menuName)
        Continue
    }
    
    UnOpenListDeamon.Push(menuName)
}
; 依次添加脚本到启动脚本菜单，类型间加入分隔线
AddToUnOpenMenu(UnOpenListTemp)
AddToUnOpenMenu(UnOpenListOnce)
AddToUnOpenMenu(UnOpenListDeamon, false)

; 主菜单
A_TrayMenu.Delete()
A_TrayMenu.Add("AHK Script Manager","Menu_Tray_Handler")
A_TrayMenu.Disable("AHK Script Manager")
; A_TrayMenu.Add, AHK Script Manager, Menu_Show
; A_TrayMenu.ToggleEnable, AHK Script Manager
; A_TrayMenu.Default, AHK Script Manager
A_TrayMenu.Add()
A_TrayMenu.Add("启动脚本(&S)`tCtrl + Alt + 左键", scripts_unopen ) ; S: Start
A_TrayMenu.Add()
A_TrayMenu.Add("重载脚本(&R)`tCtrl + Alt + 中键", scripts_restart ) ; R: Restart
A_TrayMenu.Add("关闭脚本(&C)`tCtrl + Alt + 右键", scripts_unclose ) ; C: Close
A_TrayMenu.Add("关闭所有脚本(&A)`tCtrl + Alt + A", "TskCloseAll" ) ; A: All
A_TrayMenu.Add()
; A_TrayMenu.Add("进程管理(&P)", tsk_showproc ) ; P: Process
A_TrayMenu.Add()
A_TrayMenu.Add("打开源码目录(&D)", "Menu_Tray_OpenDir" ) ; D: Directory
A_TrayMenu.Add()
A_TrayMenu.Add("重启Manager(&B)", "Menu_Tray_Reload" ) ; B: reBoot
A_TrayMenu.Add()
A_TrayMenu.Add( "退出(&X)`tCtrl + Alt + X", "Menu_Tray_Exit")
; A_TrayMenu.NoStandard

; 程序启动时，加载所有可启动脚本
TskOpenAll()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 菜单事件响应 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 启动选中脚本
TskOpenHandler(ItemName, ItemPos, Menu){
    Loop(scriptCount)
    {
        thisScript := ScriptList[A_Index]
        if (thisScript = ItemName . ".ahk")
        {
            if !WinExist(thisScript . " - AutoHotkey", "", "", "") ; 没有打开
                Run(A_ScriptDir "\scripts\" thisScript)
            
            if InStr(thisScript, "+", (A_StringCaseSense="On") ? true : false) ; 文件名中含"+"表示非驻守脚本
                Break
            
            ScriptStatus[A_Index] := 1
            Break
        }
    }
    GoSub RecreateMenus
    Return
}

; 关闭选中脚本
TskClose(ItemName, ItemPos, Menu){
    Loop(scriptCount)
    {
        thisScript := ScriptList[A_Index]
        if (thisScript = ItemName . ".ahk")
        {
            WinClose(thisScript " - AutoHotkey")
            ScriptStatus[A_Index] := 0
            Break
        }
    }
    GoSub RecreateMenus
    Return
}
; 重新启动选中脚本
TskRestartHandler(ItemName, ItemPos, Menu){
    Loop(scriptCount)
    {
        thisScript := ScriptList[A_Index]
        if (thisScript = ItemName . ".ahk")
        {
            WinClose(thisScript " - AutoHotkey")
            Run(A_ScriptDir "\scripts\" thisScript)
            Break
        }
    }
    Return
}

; 启动所有驻守脚本，从读文件开始就已经被排序了，所以无需排序
TskOpenAll(){
    Loop(scriptCount)
    {
        thisScript := ScriptList[A_Index]
        if ScriptStatus[A_Index] = 0 ; 没打开
        {
            if InStr(thisScript, "!", (A_StringCaseSense="On") ? true : false) ; 文件名中含"!"表示临时驻守脚本，则不启动
            {
                if scriptsExisted%A_Index% != 1 ; AHK Manager启动前该脚本未启动
                    Continue
            }
            
            if InStr(thisScript, "+", (A_StringCaseSense="On") ? true : false) ; 文件名中含"+"表示非驻守脚本，不启动
            {
                if scriptsExisted%A_Index% != 1
                    Continue
            }
            
            if !WinExist(thisScript . " - AutoHotkey", "", "", "") ; 没有打开
            {
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
    Loop(scriptCount)
    {
        thisScript := ScriptList[A_Index]
        if(ScriptStatus[A_Index] = 1) ; 已打开
        {
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
Menu_Tray_Handler(ItemName, ItemPos, Menu){
    Return
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 创建菜单 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 创建子菜单
CreateMenus(input_menu){
    input_menu.Add("启动脚本", "Menu_Tray_Exit")
    input_menu.ToggleEnable("启动脚本")
    input_menu.Add()
    Return
}
; 重建子菜单
RecreateMenus:
    scripts_unopen.Delete() ; 剩下空菜单
    scripts_unclose.Delete() ; 剩下空菜单
    scripts_restart.Delete() ; 剩下空菜单
    
    CreateMenus(scripts_restart)
    CreateMenus(scripts_unclose)
    CreateMenus(scripts_unopen)
    
    OpenListTemp := Array()
    OpenListDeamon := Array()
    
    UnOpenListTemp := Array()
    UnOpenListOnce := Array()
    UnOpenListDeamon := Array()
    
    Loop(scriptCount)
    {
        menuName := SubStr(ScriptList[A_Index], 1, -1*(StrLen(".ahk")))
        if ScriptStatus[A_Index] = 1
        {
            if InStr(menuName, "!", (A_StringCaseSense="On") ? true : false) ; 文件名中含"!"表示临时驻守脚本
            {
                OpenListTemp.Push(menuName)
                Continue
            }
            
            OpenListDeamon.Push(menuName)
        }
        else if ScriptStatus[A_Index] = 0
        {
            if InStr(menuName, "!", (A_StringCaseSense="On") ? true : false) ; 文件名中含"!"表示临时驻守脚本
            {
                UnOpenListTemp.Push(menuName)
                Continue
            }
            
            if InStr(menuName, "+", (A_StringCaseSense="On") ? true : false) ; 文件名中含"+"表示非驻守脚本
            {
                UnOpenListOnce.Push(menuName)
                Continue
            }
            
            UnOpenListDeamon.Push(menuName)
        }
    }
    
    ; 依次添加脚本到重载脚本/关闭脚本菜单，类型间加入分隔线
    AddToOpenMenu(OpenListTemp)
    AddToOpenMenu(OpenListDeamon, false)
    
    ; 依次添加脚本到启动脚本菜单，类型间加入分隔线
    AddToUnOpenMenu(UnOpenListTemp)
    AddToUnOpenMenu(UnOpenListOnce)
    AddToUnOpenMenu(UnOpenListDeamon, false)
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 程序清理 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExitSub(ExitReason, ExitCode){
    Loop(scriptCount)
    {
        thisScript := ScriptList[A_Index]
        if ScriptStatus[A_Index] = 1 ; 已打开
        {
            WinClose(thisScript " - AutoHotkey")
            ScriptStatus[A_Index] := 0
            
            ; StrReplace(menuName, thisScript, ".ahk",, 1)
        }
    }
    ; Menu, Tray, NoIcon
    ExitApp
    Return
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 函数 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 为启动脚本菜单添加一种类型的脚本
AddToUnOpenMenu(UnOpenList, AllowSplit:=true)
{
    InsertionSort(UnOpenList)
    for Index, menuName in UnOpenList
        scripts_unopen.Add(menuName, "TskOpenHandler")
    
    ; 必要时加分隔线
    if (AllowSplit = true)
    {
        for Files in UnOpenList
        {
            scripts_unopen.Add()
            Break
        }
    }
}

; 为重载脚本/关闭脚本菜单添加一种类型的脚本
AddToOpenMenu(OpenList, AllowSplit:=true)
{
    InsertionSort(OpenList)
    for Index, menuName in OpenList
    {
        scripts_unclose.Add(menuName, "TskClose")
        scripts_restart.Add(menuName, "TskRestartHandler")
    }
    
    ; 必要时加分隔线
    if (AllowSplit = true)
    {
        for Files in OpenList
        {
            scripts_unclose.Add()
            scripts_restart.Add()
            Break
        }
    }
}

