object FormTrackeopedidos: TFormTrackeopedidos
  Left = 0
  Top = 0
  Caption = 'MonitoreaEjecucionTrackeo'
  ClientHeight = 474
  ClientWidth = 921
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  DesignSize = (
    921
    474)
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 711
    Top = 8
    Width = 194
    Height = 217
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object Memo1: TMemo
    Left = 32
    Top = 111
    Width = 673
    Height = 355
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object BEjecutar: TcxButton
    Left = 285
    Top = 40
    Width = 95
    Height = 35
    Anchors = []
    Caption = 'Eje&cutar'
    Colors.Default = 8516504
    Colors.DefaultText = clBlack
    Colors.Normal = 8906744
    Colors.NormalText = clBlack
    Colors.Hot = 8516504
    Colors.HotText = clBlack
    Colors.Pressed = 8516504
    Colors.PressedText = clBlack
    Colors.Disabled = clRed
    Colors.DisabledText = clWhite
    Enabled = False
    LookAndFeel.NativeStyle = False
    TabOrder = 2
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = BEjecutarClick
  end
  object DataSourceQueryConsultaPedidos: TDataSource
    DataSet = QueryMonitoreaTrackeo
    Left = 824
    Top = 232
  end
  object ConexionLocal: TMSConnection
    Database = 'YPFGas_HH'
    ConnectionTimeout = 20
    Options.DisconnectedMode = True
    Options.LocalFailover = True
    Username = 'Test'
    Server = 'SSBUETYSQL13'
    LoginPrompt = False
    OnConnectionLost = ConexionLocalConnectionLost
    Left = 72
    Top = 40
    EncryptedPassword = '89FFCCFF85FFB6FF96FFA9FFCCFFB3FFBAFFC8FFDEFF8EFF'
  end
  object Script: TMSSQL
    Connection = ConexionLocal
    SQL.Strings = (
      '')
    Left = 824
    Top = 288
  end
  object QueryMonitoreaTrackeo: TMSQuery
    Connection = ConexionLocal
    CachedUpdates = True
    RefreshOptions = [roAfterUpdate]
    Options.QueryIdentity = False
    Options.FullRefresh = True
    Options.LocalMasterDetail = True
    Left = 168
    Top = 46
  end
  object ConexionSSL: TIdSSLIOHandlerSocketOpenSSL
    Destination = ':587'
    MaxLineAction = maException
    Port = 587
    DefaultPort = 0
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 872
    Top = 390
  end
  object ServidorSMTP: TIdSMTP
    IOHandler = ConexionSSL
    OnFailedRecipient = ServidorSMTPFailedRecipient
    Port = 587
    SASLMechanisms = <>
    UseTLS = utUseExplicitTLS
    Left = 800
    Top = 390
  end
  object MensajeSMTP: TIdMessage
    AttachmentEncoding = 'UUE'
    BccList = <>
    CCList = <>
    Encoding = meDefault
    FromList = <
      item
      end>
    Recipients = <>
    ReplyTo = <>
    ConvertPreamble = True
    Left = 728
    Top = 390
  end
  object RESTClient1: TRESTClient
    Params = <>
    HandleRedirects = True
    Left = 464
    Top = 56
  end
  object RESTRequest1: TRESTRequest
    Client = RESTClient1
    Params = <>
    SynchronizedEvents = False
    Left = 560
    Top = 56
  end
end
