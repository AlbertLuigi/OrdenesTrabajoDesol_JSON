object FormOrdenesDesol: TFormOrdenesDesol
  Left = 0
  Top = 0
  Caption = 'InterfazIndividualOrdenesTrabajoDesol'
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
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 711
    Top = 8
    Width = 194
    Height = 217
    DataSource = DataSourceQueryConsultaOrdenesTrabajo
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object mmo1: TMemo
    Left = 56
    Top = 112
    Width = 633
    Height = 73
    Lines.Strings = (
      'mmo1')
    TabOrder = 1
  end
  object mmoLog400NoCliente: TMemo
    Left = 56
    Top = 191
    Width = 633
    Height = 73
    Lines.Strings = (
      'mmo1')
    TabOrder = 2
  end
  object mmoLog400Otro: TMemo
    Left = 56
    Top = 270
    Width = 633
    Height = 73
    Lines.Strings = (
      'mmo1')
    TabOrder = 3
  end
  object mmoLogErroresCriticos: TMemo
    Left = 56
    Top = 349
    Width = 633
    Height = 73
    Lines.Strings = (
      'mmo1')
    TabOrder = 4
  end
  object mmoLogExitos: TMemo
    Left = 56
    Top = 28
    Width = 633
    Height = 73
    Lines.Strings = (
      'mmo1')
    TabOrder = 5
    Visible = False
  end
  object Script: TMSSQL
    Connection = ConexionServidor
    SQL.Strings = (
      '')
    Left = 824
    Top = 288
  end
  object QueryConsultaOrdenesTrabajo: TMSQuery
    Connection = ConexionServidor
    SQL.Strings = (
      ''
      ''
      ''
      ''
      ''
      'select '
      'i.IDIncidencia,'
      '--d.IDEstado,'
      'e.Estado,'
      'i.IdClaseIncidencia,'
      'c.ClaseIncidencia,'
      'v.Orden_de_Trabajo,'
      '--i.IdSitio,'
      's.IDSAP Centro,'
      's.sitio,'
      '--i.IdCliente,'
      'cl.IdSap Cliente,'
      'cl.Cliente Rzs,'
      'cl.Direccion,'
      'cl.Localidad,'
      'cl.Latitud,'
      'cl.Longitud,'
      'i.IdOtSap,'
      'i.FechaAlta,'
      #39'Importacion_OT_Glp_Sap_Dev_2024'#39' '#39'secret_key'#39' '
      ' '
      'from Incidencia i '
      
        'INNER JOIN IncidenciaDetalle d On d.IdIncidencia = i.IdIncidenci' +
        'a'
      'INNER JOIN Estado e On d.IDEstado = e.IDEstado'
      
        'INNER JOIN ClaseIncidencia c On i.IdClaseIncidencia = c.IdClaseI' +
        'ncidencia'
      'INNER JOIN Sitio s On i.IdSitio = s.IdSitio'
      'INNER JOIN Cliente cl On i.IdCliente = cl.IdCliente'
      
        'LEFT OUTER JOIN VISTA_OTS  v On c.ClaseIncidencia = v.ClaseIncid' +
        'encia'
      ' '
      'Where i.FechaAlta >= '#39'2024-01-01 00:00:00.000'#39
      'and i.IDOTSAP Like '#39'5%'#39
      'and d.IDEstado in ('
      ''
      #9#9' 1'
      #9'        ,566'
      #9#9',9'
      #9#9',532'
      #9#9',533'
      #9#9',83'
      #9#9',534'
      #9#9',18'
      #9#9#9#9')'
      ''
      ''
      #9'and v.Orden_de_Trabajo in ('#9
      #9#9#39'PM21-Orden Mantenimiento Traslado'#39
      #9#9','#39'PM22-Orden Mantenimiento Obra'#39
      #9#9','#39'PM23-Orden Mantenimiento Cambio Capacidad'#39
      #9#9','#39'PM25-Orden Retiro de Tanque'#39
      #9#9','#39'PM26-Orden Solicitud Imagen'#39
      #9#9','#39'PM28-Orden Mantenimiento Correctivo'#39
      #9#9','#39'PM29-Orden de Reprueba'#39
      #9#9','#39'PM30-Orden Mantenimiento Traslado Tk Aum.Cap.'#39
      #9#9','#39'PM31-Orden Mantenimiento Obra Aum. Capacidad'#39
      #9#9','#39'PM33-Orden Mantenimiento Kit Acccesorios'#39#9
      #9')'#9#9#9
      ''
      'and d.Item In (Select max(d1.Item) It'
      '               from IncidenciaDetalle d1 '
      '               where d1.IdIncidencia = d.IdIncidencia)'
      ''
      #9#9#9
      'order by i.IDIncidencia'#9#9#9#9#9#9' ')
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
    SSLOptions.Method = sslvTLSv1_2
    SSLOptions.SSLVersions = [sslvTLSv1_2]
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
  object ConexionServidor: TMSConnection
    OnConnectionLost = ConexionServidorConnectionLost
    Left = 40
    Top = 48
  end
  object DataSourceQueryConsultaOrdenesTrabajo: TMSDataSource
    DataSet = QueryConsultaOrdenesTrabajo
    Left = 792
    Top = 264
  end
end
