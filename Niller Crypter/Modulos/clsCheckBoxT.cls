VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsBoxT"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'---------------------------------------------------------------------------------------
' Modulo         : clsBoxT (M�dulo de clase)
' Proyecto       : TransTest
' Autor          : el_coco
' Fecha          : 18/01/2009 00:46
' Distribucion   : Remember the authors always...
' Creditos       : Benjamin Wilger (RegionFromBitmap)
' Propostio      : Makes a simple checkbox into transparent!
' Funciones/Subs : DoIT *
'---------------------------------------------------------------------------------------
'


Private Type BITMAPINFOHEADER
    biSize As Long
    biWidth As Long
    biHeight As Long
    biPlanes As Integer
    biBitCount As Integer
    biCompression As Long
    biSizeImage As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed As Long
    biClrImportant As Long
End Type

Private Type RGBQUAD
    rgbBlue As Byte
    rgbGreen As Byte
    rgbRed As Byte
    rgbReserved As Byte
End Type

Private Type BITMAPINFO
    bmiHeader As BITMAPINFOHEADER
    bmiColors As RGBQUAD
End Type

Private Declare Function CreateCompatibleDC Lib "gdi32" (ByVal hDC As Long) As Long
Private Declare Function CreateDIBSection Lib "gdi32" (ByVal hDC As Long, pBitmapInfo As BITMAPINFO, ByVal un As Long, ByVal lplpVoid As Long, ByVal handle As Long, ByVal dw As Long) As Long
Private Declare Function SelectObject Lib "gdi32" (ByVal hDC As Long, ByVal hObject As Long) As Long
Private Declare Function BitBlt Lib "gdi32" (ByVal hDestDC As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
Private Declare Function GetDIBits Lib "gdi32" (ByVal aHDC As Long, ByVal hBitmap As Long, ByVal nStartScan As Long, ByVal nNumScans As Long, lpBits As Any, lpBI As BITMAPINFO, ByVal wUsage As Long) As Long
Private Declare Function DeleteDC Lib "gdi32" (ByVal hDC As Long) As Long
Private Declare Function OleTranslateColor Lib "olepro32.dll" (ByVal OLE_COLOR As Long, ByVal hPalette As Long, pccolorref As Long) As Long
Private Declare Function CreateRectRgn Lib "gdi32" (ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long) As Long
Private Declare Function CombineRgn Lib "gdi32" (ByVal hDestRgn As Long, ByVal hSrcRgn1 As Long, ByVal hSrcRgn2 As Long, ByVal nCombineMode As Long) As Long
Private Declare Function DeleteObject Lib "gdi32" (ByVal hObject As Long) As Long
Private Declare Function GetDC Lib "user32" (ByVal hWnd As Long) As Long
Private Declare Function SetWindowRgn Lib "user32" (ByVal hWnd As Long, ByVal hRgn As Long, ByVal bRedraw As Boolean) As Long

Private Const BI_RGB As Long = 0&
Private Const RGN_OR As Long = 2&
Private Const DIB_RGB_COLORS As Long = 0&

Public Function DoIT(objSource As Object) As Boolean
    Dim lngRegion As Long

    lngRegion = RegionFromBitmap(objSource, objSource.BackColor)
    If lngRegion = 0 Then
        DoIT = False
    Else
        If SetWindowRgn(objSource.hWnd, lngRegion, True) = 1 Then
            DoIT = True
        Else
            DoIT = False
        End If
    End If
    DeleteObject lngRegion
End Function

Private Function RegionFromBitmap(objSource As Object, ByVal lngTransColor As Long) As Long
    Dim lngRetr As Long, lngHeight As Long, lngWidth As Long
    Dim lngRgnFinal As Long, lngRgnTmp As Long
    Dim lngStart As Long
    Dim x As Long, y As Long
    Dim hDC As Long
    
    Dim bi24BitInfo As BITMAPINFO
    Dim iBitmap As Long
    Dim bWidth As Long
    Dim bHeight As Long
    Dim iDC As Long
    Dim PicBits() As Byte
    Dim Col As Long
    
    hDC = GetDC(objSource.hWnd)
    
    lngWidth = objSource.Width / 15 '- 1
    lngHeight = (objSource.Height / 15) - 1

    bWidth = ((objSource.Width / 15) \ 4) * 4 + 4
    bHeight = objSource.Height / 15

    'Bitmap-Header
    With bi24BitInfo.bmiHeader
        .biBitCount = 24
        .biCompression = BI_RGB
        .biPlanes = 1
        .biSize = Len(bi24BitInfo.bmiHeader)
        .biWidth = bWidth
        .biHeight = bHeight + 1
    End With
    
    ReDim PicBits(0 To bi24BitInfo.bmiHeader.biWidth * 3 - 1, 0 To bi24BitInfo.bmiHeader.biHeight - 1)
    
    iDC = CreateCompatibleDC(hDC)
    iBitmap = CreateDIBSection(iDC, bi24BitInfo, DIB_RGB_COLORS, ByVal 0&, ByVal 0&, ByVal 0&)
    Call SelectObject(iDC, iBitmap)
    Call BitBlt(iDC, 0, 0, bi24BitInfo.bmiHeader.biWidth, bi24BitInfo.bmiHeader.biHeight, hDC, 0, 0, vbSrcCopy)
    Call GetDIBits(hDC, iBitmap, 0, bi24BitInfo.bmiHeader.biHeight, PicBits(0, 0), bi24BitInfo, DIB_RGB_COLORS)
    
    'DIB-DC
    Call DeleteDC(iDC)
    'Bitmap
    Call DeleteObject(iBitmap)

    lngRgnFinal = CreateRectRgn(0, 0, 0, 0)
    For y = 0 To lngHeight
        x = 0
        Do While x < lngWidth
            Do While x < lngWidth And _
                RGB(PicBits(x * 3 + 2, lngHeight - y + 1), _
                    PicBits(x * 3 + 1, lngHeight - y + 1), _
                    PicBits(x * 3, lngHeight - y + 1) _
                    ) = lngTransColor
                
                x = x + 1
            Loop
            If x <= lngWidth Then
                lngStart = x
                Do While x < lngWidth And _
                    RGB(PicBits(x * 3 + 2, lngHeight - y + 1), _
                        PicBits(x * 3 + 1, lngHeight - y + 1), _
                        PicBits(x * 3, lngHeight - y + 1) _
                        ) <> lngTransColor
                    x = x + 1
                Loop
                If x + 1 > lngWidth Then x = lngWidth
                lngRgnTmp = CreateRectRgn(lngStart, y, x, y + 1)
                lngRetr = CombineRgn(lngRgnFinal, lngRgnFinal, lngRgnTmp, RGN_OR)
                DeleteObject lngRgnTmp
            End If
        Loop
    Next
    
    RegionFromBitmap = lngRgnFinal
End Function



