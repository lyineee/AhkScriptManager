;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; �鿴���Ͽ���ϵͳ���
; 
; Chao.Gao@cisdi.com.cn
; 2015/5/26
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#SingleInstance Force
#NoEnv

#Include ../lib/IEAttach.ahk

DOMAIN := "http://cbms.cisdi.com.cn/AQS"

; �ȼ��ؿհ�ҳ�� about:blank , ����IE����Ӧ����Ӧ�ÿ�һ���
BrowseWebPage("about:blank")

; ����ϵͳ��ҳ
ie := BrowseWebPage(DOMAIN . "/Login.aspx")
ie.document.getElementById("tbUserID").value := "sa"    ; ���õ�¼��
ie.document.getElementById("tbUserPsw").value := "sa"   ; ��������
ie.document.getElementById("ImageButton1").Click()      ; �������¼ϵͳ

Sleep, 1000

; ��ҳ��. ��¼��ֱ������ҳ���ϴ�����ҳ�����⴦��Cookie
ie := BrowseWebPage(DOMAIN . "/AQSMorning.aspx")
ie.document.getElementById("tbFname").value := "003762" ; ���õ�¼��
ie.document.getElementById("Button1").Click()           ; �����ѯ

; �ȴ���ҳ�������
Loop { 
	Sleep, 200
	if (ie.readyState="complete" or ie.readyState=4 or A_LastError!=0)
		break
}

HWND := ie.HWND
WinSet, AlwaysOnTop, On, %HWND%

Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;                        ����                           ; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

; ��һ��ָ��URL����ҳ������IE����
BrowseWebPage(URL)
{
	ComObjError(false) ; �رն��������ʾ

    ie := 
    ie := IEAttach(DOMAIN, "URL") ; ��ͼ�Ӵ򿪵�IE�������ҳ��������
	if IsObject(ie)=0 {
		ie := ComObjCreate("InternetExplorer.Application") ; �������IE����ʧ�ܾʹ���һ��IE����
	}

	; Ĭ�ϲ��ɼ�����Ϊ�ɼ�
	ie.Visible := true
	ie.Navigate(URL) ; ����ȼ��ؿհ�ҳ�� about:blank , ����IE����Ӧ����Ӧ�ÿ�һ���

    ; �ȴ���ҳ�������
	Loop { 
		Sleep, 200
		if (ie.readyState="complete" or ie.readyState=4 or A_LastError!=0)
			break
	}

	Return ie
}

