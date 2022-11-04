unit MonitoreaEjecucionTrackeo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Data.DB, DBAccess,
  MSAccess, MemDS, Vcl.Grids, Vcl.DBGrids, REST.Client, REST.Types, MemData,IPPeerClient,
  IdComponent, IdMessage, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP,
  IdBaseComponent, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus,
  cxButtons,System.Types, System.IOUtils, StrUtils, Data.Bind.Components,
  Data.Bind.ObjectScope;

type
  TFormTrackeopedidos = class(TForm)
    DataSourceQueryConsultaPedidos: TDataSource;
    DBGrid1: TDBGrid;
    Memo1: TMemo;
    ConexionLocal: TMSConnection;
    Script: TMSSQL;
    QueryMonitoreaTrackeo: TMSQuery;
    ConexionSSL: TIdSSLIOHandlerSocketOpenSSL;
    ServidorSMTP: TIdSMTP;
    MensajeSMTP: TIdMessage;
    BEjecutar: TcxButton;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    procedure ConexionLocalConnectionLost(Sender: TObject;
      Component: TComponent; ConnLostCause: TConnLostCause;
      var RetryMode: TRetryMode);
    procedure ServidorSMTPFailedRecipient(Sender: TObject; const AAddress,
      ACode, AText: string; var VContinue: Boolean);
    procedure BEjecutarClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);


     
    
  private
  public
    { Public declarations }
  end;
  


function extraerValorFromConfig(key : string; configLines : TStringDynArray) : string;
procedure EnvioDeEmail(Mensaje : string) ; 



var
  FormTrackeopedidos: TFormTrackeopedidos;
  TextoMensaje : string ;
  
implementation

{$R *.dfm}





procedure EnvioDeEmail(Mensaje : string)  ; 

var  
   Hora , minuto, segundo, milisegundo : word ;
   Saludo, SmtpServer, SmtpPort, SmtpUser, SmtpPass , SmtpRemitente  : string ;
   ConfigLines : TStringDynArray;

Begin        


          DecodeTime(time,Hora, Minuto, Segundo, Milisegundo)  ;         
                                         

                                          case Hora of
                                          
                                                   0 .. 13 :
                                                         Begin

                                                            Saludo := 'Buenos días' ;
                                                            
                                                         End ;
                                                         
                                                   14 .. 19 :
                                                         Begin

                                                            Saludo := 'Buenas tardes' ;
                                                            
                                                         End ;  

                                                    20 .. 23 :
                                                         Begin

                                                            Saludo := 'Buenas noches' ;
                                                            
                                                         End ;         

                                          end;  

          
           
          
             //ConfigLines := TFile.ReadAllLines('D:\Datos - Aplicaciones\Proyectos Delphi 10\Trackeo Pedidos\Win32\Release\EmailConfig.ini');
          ConfigLines := TFile.ReadAllLines('EmailConfig.ini');

          SmtpServer := extraerValorFromConfig('SmtpServer', configLines);
          SmtpPort := extraerValorFromConfig('SmtpPort', configLines);
          SmtpUser := extraerValorFromConfig('SmtpUser', configLines);
          SmtpPass := extraerValorFromConfig('SmtpPass', configLines);
          SmtpRemitente := extraerValorFromConfig('SmtpRemitente', configLines);     
          
          // Usando SMTP GMAIL
          FormTrackeopedidos.ServidorSMTP.Host :=  SmtpServer ;                                                                          
          FormTrackeopedidos.ServidorSMTP.Port :=  strtoint(SmtpPort) ;                                       
          FormTrackeopedidos.ServidorSMTP.Username := SmtpUser ;                         
          FormTrackeopedidos.ServidorSMTP.Password := SmtpPass ;       
          FormTrackeopedidos.MensajeSMTP.Clear;
          FormTrackeopedidos.MensajeSMTP.Priority := TIdMessagePriority(mpHighest);//prioridad del mensaje
          FormTrackeopedidos.MensajeSMTP.Subject := 'Monitoreo del Trackeo de Pedidos';
                                 

          FormTrackeopedidos.MensajeSMTP.Body.Text := ('          ' + Saludo +  slinebreak + slinebreak + '          ' + Mensaje +
                                                       slinebreak + slinebreak + '          Atentamente' );
                                    
                                    
          //FormTrackeopedidos.MensajeSMTP.From.Address := 'albertociancio2018@gmail.com' ;  //quien envía el email
          FormTrackeopedidos.MensajeSMTP.From.Address := SmtpRemitente ;  //quien envía el email
          FormTrackeopedidos.MensajeSMTP.From.Name :=   'Monitoreo del Trackeo de Pedidos' ;  // texto que se antepone al remitente
          FormTrackeopedidos.MensajeSMTP.Recipients.EMailAddresses :=  'alberto.ciancio@ypf.com'  ;  //AsignacionesActivasEmailJefe.EditValue ;    //Destinatario                                                                      
          FormTrackeopedidos.ServidorSMTP.Connect;
          FormTrackeopedidos.ServidorSMTP.Send(FormTrackeopedidos.MensajeSMTP); 
          FormTrackeopedidos.ServidorSMTP.IOHandler.InputBuffer.Clear;
          FormTrackeopedidos.ServidorSMTP.IOHandler.CloseGracefully;
          FormTrackeopedidos.ServidorSMTP.Disconnect;  

                                   if  FormTrackeopedidos.ServidorSMTP.Connected then begin
                                       FormTrackeopedidos.ServidorSMTP.Disconnect;
                                   end ;    

 
end ;





procedure TFormTrackeopedidos.BEjecutarClick(Sender: TObject);
var
 
  Hora , minuto, segundo, milisegundo : word ;

 
  
                                   
begin

  
  try


        TextoMensaje := ''  ;                                             
        
        
            with QueryMonitoreaTrackeo do begin
            
                 Active := false ;
			     sql.Clear ;
                 sql.add ( ' Select DATEDIFF(minute , FechaUltimaEjecucion , getdate()) MinutosCalculados, TiempoMinutosEjecucion ToleranciaMinutosMonitoreo ' ) ;
                 sql.add ( '       ,CONVERT(VARCHAR(10),FechaUltimaEjecucion ,103) FechaUltimaEjecucionConvertida, CONVERT(VARCHAR(10),FechaUltimaEjecucion ,108) HoraUltimaEjecucionConvertida' ) ;
                 sql.add ( ' FROM [YPFGas_HH].[dbo].[ParametrosTrackeoPedidos] ' ) ;
                 // Params.ParamByName('VUsuario').Value :=   UsuarioSesion ;
                 //active := true  ;

                 Active := true ;
                 First ;   

                   
            end ;

            
                   if QueryMonitoreaTrackeo.IsEmpty then begin

                      try
                          TextoMensaje := 'Error en Monitoreo del Trackeo de Pedidos. No se lodró calcular los minutos.'  ; 
                          EnvioDeEmail(TextoMensaje) ;           
     
                      except on E : Exception do begin
                               showmessage('Error en el envío del email:  ' + E.Message)  ;
                               application.terminate; 
                               Application.ProcessMessages ;
                               exit;
                      end;

                      end;

                         
                   end ;
           


                  if QueryMonitoreaTrackeo['MinutosCalculados']  > QueryMonitoreaTrackeo['ToleranciaMinutosMonitoreo'] then begin

                      try
                          TextoMensaje := 'Error en Monitoreo del Trackeo de Pedidos. Fue superada la tolerancia de' + ' ' + inttostr(QueryMonitoreaTrackeo['ToleranciaMinutosMonitoreo']) + ' minutos' + ' entre ejecuciones del trackeo. Última ejecución: ' + QueryMonitoreaTrackeo['FechaUltimaEjecucionConvertida'] + 
                                          ' ' +  QueryMonitoreaTrackeo['HoraUltimaEjecucionConvertida']  + '.'  + 
                                          ' Minutos sin ejecución:  ' + inttostr(QueryMonitoreaTrackeo['MinutosCalculados']) + '.'  ; 


                          EnvioDeEmail(TextoMensaje) ;           
     
                      except on E : Exception do begin
                               showmessage('Error en el envío del email:  ' + E.Message)  ;
                               application.terminate; 
                               Application.ProcessMessages ;
                               exit;
                      end;

                      end;

                         
                   end ;
                               
                
           // esta parte del código marcada es para comentarear luego de haber verificado el funcionamiento
        {    try
                             
                TextoMensaje := 'Monitoreo del Trackeo de Pedidos sin novedades. Minutos calculados: ' + inttostr(QueryMonitoreaTrackeo['MinutosCalculados']) + ' .' ;         
                EnvioDeEmail(TextoMensaje) ;           
     
              except on E : Exception do begin
                 showmessage('Error en el envío del email:  ' + E.Message)  ;
                 application.terminate; 
                 exit;
              end;

            end;   }
        
           // esta parte del código marcada es para comentarear luego de haber verificado el funcionamiento

        
         application.terminate; 
         Application.ProcessMessages ;
         exit;    
            

      except on E : Exception do begin
           
          //showmessage('Error al enviar el JSON al Web Service: ' + E.Message);
           TextoMensaje := 'Error en Monitoreo del Trackeo de Pedidos:  ' + E.Message  ;        
           EnvioDeEmail(TextoMensaje)  ;
           application.terminate;
           Application.ProcessMessages ;
           exit;
      end;    
      
  end;
  

end;







function extraerValorFromConfig(key : string; configLines : TStringDynArray) : string;
var
  i: integer;
  line: string;
  splitted : TStringDynArray;
begin
  i := 0;
  repeat
    line := configLines[i];
    splitted := SplitString(line, '=');
    i := i + 1;
  until (i = length(configLines)) or (splitted[0] = key);

  if splitted[0] = key then
    Result := splitted[1]
  else
    raise Exception.Create('No se encuentra en el config la key: ' + key);

end;




procedure TFormTrackeopedidos.ConexionLocalConnectionLost(Sender: TObject;
  Component: TComponent; ConnLostCause: TConnLostCause;
  var RetryMode: TRetryMode);
begin


     try


          RetryMode := rmReconnectExecute;



     except
            on e:Exception do begin
               // SilenciaError := 2 ;
               // ErrorEnModulo := 'TModulo1.ConexionLocalConnectionLost' ;
                //TratamientoErrores(e.Message,ErrorEnModulo) ;
                application.terminate;
                Application.ProcessMessages ;
                exit;
                //Halt ;
            end;
     end;


end;

procedure TFormTrackeopedidos.FormActivate(Sender: TObject);
begin

 try


          BEjecutar.Enabled := true ;
          BEjecutar.Click ;

 
   except
 end;

end;

procedure TFormTrackeopedidos.ServidorSMTPFailedRecipient(Sender: TObject; const AAddress,
  ACode, AText: string; var VContinue: Boolean);
begin

          VContinue := true ;

end;

end.
