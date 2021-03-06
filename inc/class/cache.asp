﻿<%
'@title: Class_Cache
'@author: ekede.com
'@date: 2017-12-7
'@description: 缓存操作类

Class Class_Cache
    '
    Private fso_
    Private cacheTime_
    Private cacheDataPath_
    Private cacheDict_

	'@fso: fso对象依赖

    Public Property Let fso(Values)
        Set fso_ = Values
    End Property
	
	'@cacheTime: 缓存时间

    Public Property Let cacheTime(Values)
        cacheTime_ = Values
    End Property
	
	'@dataPath: 数据缓存路径, 根据需要叠加全局缓存因子 PATH_DATA/cache/default/site_id/language_id/currency_id/usergroup_id ...

    Public Property Let dataPath(Values)
        cacheDataPath_ = PATH_ROOT&Values
        set cacheDict_ = CreateDict("dict_"&cacheDataPath_) '创建容器
    End Property

    Private Sub Class_Initialize()
        cacheTime_ = 3600
    End Sub

    Private Sub Class_Terminate()
    End Sub

    '@GetCache(ByRef names): File 读

    Public Function GetCache(ByRef names)
        Dim paths, str
        paths = cacheDataPath_&names
        '
        ExpireCache names
        Str = fso_.Reads(fso_.getmappath(paths),"UTF-8")
        If Str = "" Then
            GetCache = -1
        Else
            GetCache = str
        End If
    End Function
	
	'@SetCache(ByRef names,ByRef content): File 写

    Public Function SetCache(ByRef names,ByRef content)
        Dim paths
        Dim fpath, fname
        Dim i, arr
        paths = cacheDataPath_&names
        '
        If InStr(paths, "/")>0 Then
            arr = Split(paths, "/")
            For i = 0 To UBound(arr) -1
                fpath = fpath&arr(i)&"/"
            Next
        End If
        fname = Replace(paths, fpath, "")
		'
        fso_.createFolders fso_.getmappath(fpath)
        SetCache = fso_.Writes(fso_.getmappath(paths), content, "UTF-8")
    End Function
	
	'@DelCache(ByRef names): File 删 

    Public Function DelCache(ByRef names)
        DelCache = fso_.DeleteAFile(fso_.GetMapPath(cacheDataPath_&names))
    End Function
	
	'@ExpireCache(ByRef names): File 过期

    Public Function ExpireCache(ByRef names)
        Dim paths, transtime
        paths = cacheDataPath_&names
        Transtime = fso_.ShowFileAccessInfo(fso_.getmappath(paths), 3)
        If transtime<> -1 Then
            If cacheTime_ = 0 Then Exit Function
            If DateDiff("s", CDate(transtime), Now())>cacheTime_ Then delCache names
        End If
    End Function
	
	'@ClearCache(): File 清

    Public Function ClearCache()
        ClearCache = fso_.DeleteAFolder(fso_.GetMapPath(cacheDataPath_))
    End Function

    '****** Value -> cache
	
	'@GetValue(ByRef names): APPLICATION 读

    Public Function GetValue(ByRef names)
        Dim str
        str = Application("cache_"&cacheDataPath_&names)
        If IsArray(str) Then
        ElseIf IsObject(str) Then
        ElseIf str = "" Then
            str = -1
        End If
        GetValue = str
    End Function
	
	'@SetValue(ByRef names,ByRef Content): APPLICATION 写 支持数组

    Public Function SetValue(ByRef names,ByRef Content)
        Application.Contents("cache_"&cacheDataPath_&names) = Content
    End Function
	
	'@DelValue(ByRef names): APPLICATION 删

    Public Function DelValue(ByRef names)
        Application.Contents.Remove("cache_"&cacheDataPath_&names) '释放容器
    End Function
	
	'@ExpireValue(ByRef names): APPLICATION 过期

    Public Function ExpireValue(ByRef names)
        DelValue(names)
    End Function
	
	'@ClearValue(): APPLICATION 清

    Public Function ClearValue()
        For Each objItem in Application.Contents
            If instr(objItem, "cache_"&cacheDataPath_)>0 Then application.Contents.Remove(objItem)
        Next
    End Function

    '****** Dictionary -> cache

	'@GetDict(ByRef names): Dictionary 读

    Public Function GetDict(ByRef names)
        Dim str
        str = cacheDict_.Item(names)
        If IsArray(str) Then
        ElseIf IsObject(str) Then
        ElseIf str = "" Then
            str = -1
        End If
        GetDict = str
    End Function
	
	'@SetDict(ByRef names,ByRef Content): Dictionary 写

    Public Function SetDict(ByRef names,ByRef Content)
        cacheDict_.Item(names) = Content
    End Function
	
	'@DelDict(ByRef names): Dictionary 删

    Public Function DelDict(ByRef names)
        If cacheDict_.Exists(names) Then cacheDict_.Remove(names)
    End Function
	
	'@ExpireDict(ByRef names): Dictionary 过期

    Public Function ExpireDict(ByRef names)
        DelDict(names)
    End Function
	
	'@ClearDict(): Dictionary 清

    Public Function ClearDict()
        cacheDict_.RemoveAll()
    End Function

	'@CleanDict(): Dictionary 释放容器

    Public Function CleanDict()
        Set cacheDict_ = Nothing
        CloseDict "dict_"&cacheDataPath_
    End Function

    '******

    '@CreateDict(ByRef kname): 创建字典容器方法

    Public Function CreateDict(ByRef kname)
        Dim isDic:isDic = True
        If IsArray(Application(kname)) Then
            If ubound(Application(kname))<>-1 Then
                If typename(Application(kname)(0))<>"Dictionary" Then isDic = False
            Else
                isDic = False
            End If
        Else
            isDic = False
        End If
        if Not isDic Then 
            Application.Lock
            Application(kname) = Array(Server.CreateObject("Scripting.Dictionary"))
            Application.Unlock
        End If
        set CreateDict = Application(kname)(0)
    End function

	'@CloseDict(ByRef kname): 释放字典容器方法

    Public Function CloseDict(ByRef kname)
        Application.Lock
        Application.Contents.Remove(kname)
        Application.Unlock
    End Function

End Class
%>