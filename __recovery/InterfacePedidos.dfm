object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 474
  ClientWidth = 921
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 480
    Top = 40
    Width = 145
    Height = 57
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object DBGrid1: TDBGrid
    Left = 711
    Top = 8
    Width = 194
    Height = 217
    TabOrder = 1
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
    TabOrder = 2
  end
  object DataSourceQueryConsultaPedidos: TDataSource
    DataSet = QueryConsultaPedidos
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
    Left = 72
    Top = 40
    EncryptedPassword = '89FFCCFF85FFB6FF96FFA9FFCCFFB3FFBAFFC8FFDEFF8EFF'
  end
  object script: TMSSQL
    Connection = ConexionLocal
    SQL.Strings = (
      '')
    Left = 824
    Top = 288
  end
  object QueryConsultaPedidos: TMSQuery
    Connection = ConexionLocal
    SQL.Strings = (
      ''
      ''
      ''
      'SELECT'
      '                t.IDTransporteBackOffice Transporte,'
      '--t.IDVehiculoTanque,'
      '                t.FechaAlta,'
      '                v.patente Patente,'
      '                s.IDSitioBackOffice Centro,'
      '                s.sitio Planta,'
      '                s.Direccion,'
      '                c.IDChoferBackOffice DNI_Chofer,'
      '                c.Chofer,'
      '--d.IDPedido,'
      '                p.IDPedidoBackOffice Pedido,'
      '                '#39'1100 - Propano'#39' Material,'
      'CASE'
      '                               '
      '                               WHEN p.Estado = 1 THEN'
      '                               '#39'Pendiente'#39' '
      '                               WHEN p.Estado = 2 THEN'
      '                               '#39'Entregado'#39' '
      '                END AS EstadoPedido,'
      '--p.idboca,'
      '                p.FechaEstimadaEntrega,'
      '                b.IDBocaBackOffice Boca,'
      '                b.boca Rzs,'
      '                b.latitud,'
      '                b.Longitud,'
      '                e.FechaEntrega,'
      '                e.serie AS Serie_Remito,'
      '                e.numero AS NroRemito,'
      '--r.IDRazonNoAbastecido,'
      '--r.IDRna Rna,'
      '                tr.RazonNoAbastecido ,'
      '                r.FechaRna,'
      '                r.Observaciones '
      'FROM'
      '                transporte t'
      
        '                INNER JOIN TransporteDetalle d ON t.IDTransporte' +
        ' = d.IDTransporte'
      '                INNER JOIN Pedido p ON d.IDPedido = p.IDPedido'
      '                INNER JOIN Boca b ON p.idboca = b.idboca'
      
        '                INNER JOIN Vehiculo v ON t.IDVehiculoTanque = v.' +
        'IDVehiculo'
      '                INNER JOIN Chofer c ON t.IDChofer = c.IDChofer'
      '                INNER JOIN Sitio s ON t.IDSitio = s.IDSitio'
      
        '                LEFT OUTER JOIN Entrega e ON d.IDPedido = e.IDPe' +
        'dido'
      
        '                LEFT OUTER JOIN RazonNoAbastecido r ON t.idtrans' +
        'porte = r.idtransporte '
      '                AND p.IDPedido = r.IDPedido'
      
        '                LEFT OUTER JOIN TipoRazonNoAbastecido tr ON r.ID' +
        'Rna = tr.IDTipoRazonNoAbastecidoBackOffice '
      'WHERE'
      '                t.IDEstadoTransporte = 1 '
      'ORDER BY'
      '                t.IDTransporteBackOffice,'
      '                p.FechaEstimadaEntrega')
    CachedUpdates = True
    RefreshOptions = [roAfterUpdate]
    Options.QueryIdentity = False
    Options.FullRefresh = True
    Options.LocalMasterDetail = True
    Left = 168
    Top = 46
  end
end
