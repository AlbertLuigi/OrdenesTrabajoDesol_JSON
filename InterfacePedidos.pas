unit InterfacePedidos;

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
  Data.Bind.ObjectScope ;

type
  TFormTrackeopedidos = class(TForm)
    DataSourceQueryConsultaPedidos: TDataSource;
    DBGrid1: TDBGrid;
    Memo1: TMemo;
    ConexionLocal: TMSConnection;
    Script: TMSSQL;
    QueryConsultaPedidos: TMSQuery;
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
  
function EjecutarQueryYRetornarJSON(QueryConsultaPedidos : TMSQuery): string;
function EnviarDataWebService(json : string): boolean;
function extraerValorFromConfig(key : string; configLines : TStringDynArray) : string;
procedure EnvioDeEmail(Mensaje : string) ; 


const
  //WebServiceUrl : string = 'https://jsonplaceholder.typicode.com/posts';
 // WebServiceUrl : string = 'https://us-central1-sils-stage.cloudfunctions.net/handlerViajesYpfGas';  //Testing
                              
  
      WebServiceUrl : string = 'https://us-central1-sils-ypf.cloudfunctions.net/handlerViajesYpfGass';  // Producción


var

  FormTrackeopedidos: TFormTrackeopedidos;
  TextoMensaje : string ;
  Contador,  CantidadReintentos : SmallInt   ;     
 
  Saludo, SmtpServer, SmtpPort, SmtpUser, SmtpPass , SmtpRemitente, SmtpDestinatario  : string ;
  ConfigLines : TStringDynArray;
  
implementation

{$R *.dfm}





procedure EnvioDeEmail(Mensaje : string)  ; 

var  
   Hora , minuto, segundo, milisegundo : word ;
  
  

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

         
          
                // Usando SMTP GMAIL
                FormTrackeopedidos.ServidorSMTP.Host :=  SmtpServer ;                                                                          
                FormTrackeopedidos.ServidorSMTP.Port :=  strtoint(SmtpPort) ;                                       
                FormTrackeopedidos.ServidorSMTP.Username := SmtpUser ;                         
                FormTrackeopedidos.ServidorSMTP.Password := SmtpPass ;          
                FormTrackeopedidos.MensajeSMTP.Clear;
                FormTrackeopedidos.MensajeSMTP.Priority := TIdMessagePriority(mpHighest);//prioridad del mensaje
                FormTrackeopedidos.MensajeSMTP.Subject := 'Reporte de Trackeo de Pedidos';                           
                FormTrackeopedidos.MensajeSMTP.Body.Text := ('          ' + Saludo +  slinebreak + slinebreak + '          ' + Mensaje +
                                                             slinebreak + slinebreak + '          Atentamente' );
                                    
                                    
                //FormTrackeopedidos.MensajeSMTP.From.Address := 'albertociancio2018@gmail.com' ;  //quien envía el email
                FormTrackeopedidos.MensajeSMTP.From.Address := SmtpRemitente ;  //quien envía el email
                FormTrackeopedidos.MensajeSMTP.From.Name :=   'Reporte Trackeo de Pedidos' ;  // texto que se antepone al remitente
                FormTrackeopedidos.MensajeSMTP.Recipients.EMailAddresses := SmtpDestinatario ; // 'alberto.ciancio@ypf.com'  ;  //AsignacionesActivasEmailJefe.EditValue ;    //Destinatario                                                                      
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
  json  : string;
  DatosEnviados: boolean;
  Hora , minuto, segundo, milisegundo : word ;
 
                                   
begin

  try
  
   // Obtiene parámetros y asigna el valor a variables

    
          ConfigLines := TFile.ReadAllLines('EmailConfig.ini');

          SmtpServer := extraerValorFromConfig('SmtpServer', configLines);
          SmtpPort := extraerValorFromConfig('SmtpPort', configLines);
          SmtpUser := extraerValorFromConfig('SmtpUser', configLines);
          SmtpPass := extraerValorFromConfig('SmtpPass', configLines);
          SmtpRemitente := extraerValorFromConfig('SmtpRemitente', configLines);     
          SmtpDestinatario := extraerValorFromConfig('SmtpDestinatario', configLines);   
          CantidadReintentos := strtoint (extraerValorFromConfig('Reintentos', configLines));
         


   // Ejecuta la query que obtiene los pedidos

          TextoMensaje := ''  ;
          
          json := EjecutarQueryYRetornarJSON(QueryConsultaPedidos);  

          
       
          //memo1.lines.text := json;     // Muestra el resultado del jSON en el campo MEMO1
          
    except on E : Exception do begin           
           TextoMensaje := 'Error en la ejecución de la Query que retorna el JSON.  ' + E.Message  ;
           EnvioDeEmail(TextoMensaje)  ;
           application.terminate;
           application.ProcessMessages ;  
           exit;
    end;
    
  end;

  
  
  
   // Envía el JSON al WEB Service 
          
 
  try
  
       Contador := 0 ;   
      
       while Contador <= CantidadReintentos do begin

            try
         
                  TextoMensaje := ''  ;   
                  
                  DatosEnviados := EnviarDataWebService(json);     
        
                 
                         if not datosEnviados then begin
                       
                              Contador := Contador + 1 ; 

                                   if Contador <= CantidadReintentos then  begin

                                      EnvioDeEmail('Probable error en el response. Reintentando...')  ;
                                      sleep(5000)  ;   
                                      //sleep(120000)  ;                                   
                                      Continue
                 
                                   end;

                              //TextoMensaje := 'Error al enviar el JSON al Web Service: el status code del response no es 200'  ;
                              EnvioDeEmail(TextoMensaje)  ;
                              application.terminate;
                              application.ProcessMessages ;  
                              exit;
                  
                         end;     
                 
            

            except on E : Exception do begin
                        
                        Contador := Contador + 1 ; 

                             if Contador <= CantidadReintentos then  begin
                                EnvioDeEmail('Probable error al enviar el JSON al Web Service. Reintentando...')  ;
                                sleep(120000)  ;                                
                                Continue
                 
                             end;

                        
                        
                        TextoMensaje := 'Error al enviar el JSON al Web Service. Fallo en los reintentos:  ' + E.Message  ;        
                        EnvioDeEmail(TextoMensaje)  ;
                        application.terminate;
                        application.ProcessMessages ;  
                        exit;

            end;    
      
            end;

          Break  
                  
       end;

        

  except on E : Exception do begin           
          TextoMensaje := 'Error al enviar el JSON al Web Service:  ' + E.Message  ;        
          EnvioDeEmail(TextoMensaje)  ;
          application.terminate;
          application.ProcessMessages ;  
          exit;
  end; 
  
  end ;
  
  
  
   // Actualiza la tabla para monitoreo 

   
        
  try


          with Script do begin
               sql.Clear ;
               sql.add ( ' update ParametrosTrackeoPedidos  ' ) ;
               sql.add ( ' set FechaUltimaEjecucion = getdate()  '   ) ;

               Execute ;

		  end ;                


  
      except on E : Exception do begin
           
          
           TextoMensaje := 'Error al actualizar la fecha de última ejecución en la tabla de parámetros:  ' + E.Message  ;        
           EnvioDeEmail(TextoMensaje)  ;
           application.terminate;
           application.ProcessMessages ;  
           exit;
           
      end;   
  
  end;
  
          application.terminate; 
          application.ProcessMessages ;          
          exit; 
  
end;


          


function enviarDataWebService(json : string): boolean;
var
  client : TRESTClient;
  request : TRESTRequest;
begin
 
  try
  
  
    try
       client := TRESTClient.Create(nil);   
       client.BaseURL := WebServiceUrl ;   
       client.RaiseExceptionOn500 := true;
       request := TRESTRequest.Create(client);  
       request.Method := TRESTRequestMethod.rmPost;  
       request.AddBody(json, ctAPPLICATION_JSON);  
    
       request.Execute;

       //raise Exception.Create('el response salio para el orto');
       Result := request.Response.StatusCode = 200;
       
    except on E: Exception do begin
    
       //EnvioDeEmail('Error accediendo al response: ' + E.Message);    
       TextoMensaje := 'Error al enviar el JSON al Web Service: el status code del response no es 200: ' + E.Message  ;
        
    end;

    end;

  finally
  
    request.Free;
    client.Free;
    
  end;                 
          
end;




function EjecutarQueryYRetornarJSON(QueryConsultaPedidos : TMSQuery): string;
var
   objects: string;
   fieldName: string;
   fieldValue: string;
   fieldValueEscaped: string;   
   finalValue: string;
   i : integer;

begin

    QueryConsultaPedidos.Active := True ;
    QueryConsultaPedidos.First ;

    objects := '[';
   
     while not QueryConsultaPedidos.Eof do begin
     
        i := 0;
        objects := objects + '{';
        
        for i := 0 to QueryConsultaPedidos.FieldCount - 1 do begin
        
            fieldName := QueryConsultaPedidos.Fields[i].FieldName;        
            fieldValue := QueryConsultaPedidos.Fields[i].AsString;            
            fieldValueEscaped := Trim(StringReplace(fieldValue, '\', '\\', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, '"', '\"', [rfReplaceAll]));            
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, #13#10, ' ', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, #13, ' ', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, #10, ' ', [rfReplaceAll]));          finalValue := '"' + fieldValueEscaped + '"';
            objects := objects + '"' + fieldName + '":' + finalValue + ',';                                                        
            
        end;

        SetLength(objects, length(objects) - 1);
        objects := objects + '},'; {+  AnsiString(#13#10);}

        QueryConsultaPedidos.Next;

     end;

     SetLength(objects, length(objects) - 1);
     objects := objects + ']';    
     Result := objects;  
     
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
              
                application.terminate;
                application.ProcessMessages ;  
                exit;                  
                
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
