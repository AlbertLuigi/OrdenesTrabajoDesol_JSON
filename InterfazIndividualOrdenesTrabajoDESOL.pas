UNIT InterfazIndividualOrdenesTrabajoDESOL;

INTERFACE

USES
      Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
      Data.DB, Vcl.Grids, Vcl.DBGrids, REST.Client, REST.Types, IPPeerClient, IdComponent, IdMessage, IdTCPConnection, IdTCPClient,
      IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP, IdBaseComponent, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
      cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, cxButtons, System.Types, System.IOUtils, StrUtils, Data.Bind.Components,
      Data.Bind.ObjectScope, DBAccess, MSAccess, MemDS, MidasLib, MemData;

TYPE
      TFormOrdenesIndividualTrabajoDesol = CLASS(TForm)
            DBGrid1: TDBGrid;
            Script: TMSSQL;
            QueryConsultaOrdenesTrabajo: TMSQuery;
            ConexionSSL: TIdSSLIOHandlerSocketOpenSSL;
            ServidorSMTP: TIdSMTP;
            MensajeSMTP: TIdMessage;
            RESTClient1: TRESTClient;
            RESTRequest1: TRESTRequest;
            ConexionServidor: TMSConnection;
            mmo1: TMemo;
            DataSourceQueryConsultaOrdenesTrabajo: TMSDataSource;

            PROCEDURE ServidorSMTPFailedRecipient(Sender: TObject; CONST AAddress, ACode, AText: STRING; VAR VContinue: Boolean);

            PROCEDURE FormActivate(Sender: TObject);
            PROCEDURE ConexionServidorConnectionLost(Sender: TObject; Component: TComponent; ConnLostCause: TConnLostCause; VAR RetryMode: TRetryMode);

      PRIVATE
      PUBLIC
    { Public declarations }
      END;

FUNCTION EnviarDataWebService(json: STRING): boolean;

FUNCTION CrearJSON(QueryConsultaOrdenesTrabajo: TMSQuery): STRING;

FUNCTION extraerValorFromConfig(key: STRING; configLines: TStringDynArray): STRING;

PROCEDURE EnvioDeEmail(Mensaje: STRING);

PROCEDURE EjecutaProceso();

CONST
  //WebServiceUrl : string = 'https://jsonplaceholder.typicode.com/posts';
 // WebServiceUrl : string = 'https://us-central1-sils-stage.cloudfunctions.net/handlerViajesYpfGas';  //Testing

      WebServiceUrl: STRING = 'https://legajotecnicoapi.ypfgas.com.ar';  // Producción

VAR
      FormOrdenesIndividualTrabajoDesol: TFormOrdenesIndividualTrabajoDesol;
      TextoMensaje: STRING;
      Contador, CantidadReintentos: SmallInt;
      Saludo, SmtpServer, SmtpPort, SmtpUser, SmtpPass, SmtpRemitente, SmtpDestinatario, SmtpDestinatarioExterno, SmtpConCopia: STRING;
      ConfigLines: TStringDynArray;

IMPLEMENTATION

{$R *.dfm}

PROCEDURE EjecutaProceso();
VAR
      json: STRING;
      DatosEnviados: boolean;
      Hora, minuto, segundo, milisegundo: word;
BEGIN

      TRY

            TRY
     
           // Obtiene parámetros y asigna el valor a variables

                  ConfigLines := TFile.ReadAllLines(ExtractFilePath(ParamStr(0)) + 'EmailConfig.ini');
         // ConfigLines := TFile.ReadAllLines('EmailConfig.ini');

                  SmtpServer := extraerValorFromConfig('SmtpServer', configLines);
                  SmtpPort := extraerValorFromConfig('SmtpPort', configLines);
                  SmtpUser := extraerValorFromConfig('SmtpUser', configLines);
                  SmtpPass := extraerValorFromConfig('SmtpPass', configLines);
                  SmtpRemitente := extraerValorFromConfig('SmtpRemitente', configLines);
                  SmtpDestinatario := extraerValorFromConfig('SmtpDestinatario', configLines);
                  CantidadReintentos := strtoint(extraerValorFromConfig('Reintentos', configLines));
                  SmtpDestinatarioExterno := extraerValorFromConfig('SmtpDestinatarioExterno', configLines);
                  SmtpConCopia := extraerValorFromConfig('SmtpConCopia', configLines);
                  TextoMensaje := '';

            EXCEPT
                  ON E: Exception DO BEGIN

                        TextoMensaje := 'Error en la asignación de parámetros para el envío de emails.  ' + E.Message;
                        ShowMessage(TextoMensaje);
           //application.terminate;
           //application.ProcessMessages ;
                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;

                  END;

            END;

            TRY
  
                // Conecta con el servidor

                  WITH FormOrdenesIndividualTrabajoDesol.ConexionServidor DO BEGIN

                        connected := false;
                        close;
                        Database := 'INCYTP_PRO';
                        ConnectionTimeout := 20;
                        Server := 'azpussql01.database.windows.net';
                        loginprompt := false;
                        Username := 'usr_INCYTP';
                        Password := 'Acceso62619';
                        connected := true;

                  END;

            EXCEPT
                  ON E: Exception DO BEGIN

                        TextoMensaje := 'Error al conectarse con el servidor:  ' + E.Message;
                        EnvioDeEmail(TextoMensaje);
           //application.terminate;
           //application.ProcessMessages ;
                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;

                  END;

            END;

            TRY
    

                 // Ejecuta la query que obtiene los pedidos

                  TextoMensaje := '';
          
          //json := EjecutarQueryYRetornarJSON(FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo);

                  FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo.Active := true;
                  FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo.First;

                  WHILE NOT FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo.Eof DO BEGIN
                        //EnvioDeEmail(FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo['IDIncidencia']);
                        json := CrearJSON(FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo);
                        FormOrdenesIndividualTrabajoDesol.mmo1.lines.text := json;     // Muestra el resultado del jSON en el campo MEMO1
                        Application.ProcessMessages;
	            { Poner el sleep acá... }
                        Sleep(500);
                //EnvioDeEmail(FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo['IDIncidencia']) ;
                        EnviarDataWebService(json);
           	    //Break ;
                        FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo.Next;
                  END
          
       
          //FormOrdenesIndividualTrabajoDesol.mmo1.lines.text := json;     // Muestra el resultado del jSON en el campo MEMO1

            EXCEPT
                  ON E: Exception DO BEGIN

                        TextoMensaje := 'Error en la ejecución de la Query que retorna el JSON.  ' + E.Message;
                        EnvioDeEmail(TextoMensaje);
           //application.terminate;
           //application.ProcessMessages ;
                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;
                  END;
            END;

            ShowMessage(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));

            exit;
    

               
 
   {  try
  
            // Envía el JSON al WEB Service 

       Contador := 0 ;   
      
       while Contador <= CantidadReintentos do begin

            try
         
                  TextoMensaje := ''  ;   
                  
                  DatosEnviados := EnviarDataWebService(json);     
        
                 
                         if not datosEnviados then begin
                       
                              Contador := Contador + 1 ; 

                                   if Contador <= CantidadReintentos then  begin

                                      EnvioDeEmail('Probable error en el response. Reintento ' + inttostr(Contador) + ' ...')  ;
                                      sleep(5000)  ;   
                                      //sleep(120000)  ;                                   
                                      Continue
                 
                                   end;

                              //TextoMensaje := 'Error al enviar el JSON al Web Service: el status code del response no es 200'  ;
                              EnvioDeEmail(TextoMensaje)  ;
                              //application.terminate;
                              //application.ProcessMessages ;  
                              TerminateProcess(GetCurrentProcess(), 0)  ;
                              exit;
                  
                         end;     
                 
            

            except on E : Exception do begin
                        
                        Contador := Contador + 1 ; 

                             if Contador <= CantidadReintentos then  begin
                                EnvioDeEmail('Probable error al enviar el JSON al Web Service. Reintentando...')  ;
                                 sleep(5000)  ;  
                                //sleep(120000)  ;                                
                                Continue
                 
                             end;

                        
                        TextoMensaje := 'Error al enviar el JSON al Web Service. Fallo en los reintentos:  ' + E.Message  ;        
                        EnvioDeEmail(TextoMensaje)  ;
                        //application.terminate;
                        //application.ProcessMessages ;  
                        TerminateProcess(GetCurrentProcess(), 0)  ;
                        exit;

            end;    
      
            end;

          Break  
                  
       end;

        

     except on E : Exception do begin           
          TextoMensaje := 'Error al enviar el JSON al Web Service:  ' + E.Message  ;        
          EnvioDeEmail(TextoMensaje)  ;
          //application.terminate;
          //application.ProcessMessages ;  
          TerminateProcess(GetCurrentProcess(), 0)  ;
          exit;
     end; 
  
     end ;}


            TRY

              // Actualiza la tabla para monitoreo

                  WITH FormOrdenesIndividualTrabajoDesol.Script DO BEGIN
                        sql.Clear;
                        sql.add(' update ParametrosTrackeoPedidos  ');
                        sql.add(' set FechaUltimaEjecucion = getdate()  ');

                        Execute;

                  END;

            EXCEPT
                  ON E: Exception DO BEGIN

                        TextoMensaje := 'Error al actualizar la fecha de última ejecución en la tabla de parámetros:  ' + E.Message;
                        EnvioDeEmail(TextoMensaje);
           //application.terminate;
           //application.ProcessMessages ;
                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;

                  END;

            END;

            FormOrdenesIndividualTrabajoDesol.ConexionServidor.Close;
            FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo.Close;
          
          //application.terminate;
          //application.ProcessMessages ;
            TerminateProcess(GetCurrentProcess(), 0);
            exit;

      EXCEPT
            ON E: Exception DO BEGIN
                  TextoMensaje := 'Error general del proceso:  ' + E.Message;
                  EnvioDeEmail(TextoMensaje);
          //application.terminate;
          //application.ProcessMessages ;
                  TerminateProcess(GetCurrentProcess(), 0);
                  exit;

            END;

      END;

END;

PROCEDURE EnvioDeEmail(Mensaje: STRING);
VAR
      Hora, minuto, segundo, milisegundo: word;
BEGIN

      DecodeTime(time, Hora, minuto, segundo, milisegundo);

      CASE Hora OF

            0..13:

                  BEGIN

                        Saludo := 'Buenos días';

                  END;

            14..19:

                  BEGIN

                        Saludo := 'Buenas tardes';

                  END;

            20..23:

                  BEGIN

                        Saludo := 'Buenas noches';

                  END;

      END;
  

         
          
                // Usando SMTP GMAIL
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Host := SmtpServer;
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Port := strtoint(SmtpPort);
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Username := SmtpUser;
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Password := SmtpPass;
      FormOrdenesIndividualTrabajoDesol.MensajeSMTP.Clear;
      FormOrdenesIndividualTrabajoDesol.MensajeSMTP.Priority := TIdMessagePriority(mpHighest); //prioridad del mensaje
      FormOrdenesIndividualTrabajoDesol.MensajeSMTP.Subject := 'Reporte de Trackeo de Pedidos';
      FormOrdenesIndividualTrabajoDesol.MensajeSMTP.Body.Text := ('          ' + Saludo + slinebreak + slinebreak + '          ' + Mensaje + slinebreak +
            slinebreak + '          Atentamente');
                                    
                                    
                //FormOrdenesIndividualTrabajoDesol.MensajeSMTP.From.Address := 'albertociancio2018@gmail.com' ;  //quien envía el email
      FormOrdenesIndividualTrabajoDesol.MensajeSMTP.From.Address := SmtpRemitente;  //quien envía el email
      FormOrdenesIndividualTrabajoDesol.MensajeSMTP.From.Name := 'Reporte Trackeo de Pedidos';  // texto que se antepone al remitente
      FormOrdenesIndividualTrabajoDesol.MensajeSMTP.Recipients.EMailAddresses := SmtpDestinatario; // 'alberto.ciancio@ypf.com'  ;  //AsignacionesActivasEmailJefe.EditValue ;    //Destinatario
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Connect;
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Send(FormOrdenesIndividualTrabajoDesol.MensajeSMTP);
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.IOHandler.InputBuffer.Clear;
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.IOHandler.CloseGracefully;
      FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Disconnect;

      IF FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Connected THEN BEGIN

            FormOrdenesIndividualTrabajoDesol.ServidorSMTP.Disconnect;

      END;

END;

FUNCTION enviarDataWebService(json: STRING): boolean;
VAR
      client: TRESTClient;
      request: TRESTRequest;
      Content, NroIncidencia, Cliente, Planta, NroOrden: STRING;
BEGIN

      TRY

            TRY
                  client := TRESTClient.Create(nil);
                  client.BaseURL := WebServiceUrl;
                  client.RaiseExceptionOn500 := true;
                  request := TRESTRequest.Create(client);
                  request.Method := TRESTRequestMethod.rmPost;
                  request.AddBody(json, ctAPPLICATION_JSON);

                  request.Execute;

           {  if ((request.Response.StatusCode = 400) and
                  (not request.Response.Content.Contains('No se encontró el cliente'))) then
              begin
                    raise Exception.Create('se retornó un 400 con otro error');
               end;}


                  Content := request.Response.Content;
                  NroIncidencia := inttostr(FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo['IDIncidencia']);
                  Cliente := inttostr(FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo['Cliente']);
                  Planta := FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo['Centro'];
                  NroOrden := inttostr(FormOrdenesIndividualTrabajoDesol.QueryConsultaOrdenesTrabajo['IdOtSap']);
                  TextoMensaje := Format('Se retornó un 400 con el siguiente error: %s', [Content]) + '    -  Datos a varificar:  Nro Incidencia: ' +
                                  NroIncidencia + '   -  Planta: ' + Planta + '   -  Cliente:  ' + Cliente + '   -  Nro Orden ' + NroOrden;
                                  
                  IF (request.Response.StatusCode = 400) THEN BEGIN //AND (NOT Content.Contains('No se encontró el cliente')) THEN BEGIN

                        
                        //ShowMessage(TextoMensaje);

                        EnvioDeEmail(TextoMensaje);

                  END
                        

                        //RAISE Exception.CreateFmt('Se retornó un 400 con otro error: %s', [Content]));
                  ELSE IF request.Response.StatusCode = 500 THEN BEGIN
                        EnvioDeEmail(TextoMensaje);
                  END;
                                    

       //raise Exception.Create('el response salio para el orto');
                  Result := request.Response.StatusCode = 200;

            EXCEPT
                  ON E: Exception DO BEGIN

                        showmessage(E.Message);
       //EnvioDeEmail('Error accediendo al response: ' + E.Message);
                        TextoMensaje := 'Error al enviar el JSON al Web Service: el status code del response no es 200: ' + E.Message;

                  END;

            END;

      FINALLY

            request.Free;
            client.Free;

      END;

END;

FUNCTION CrearJSON(QueryConsultaOrdenesTrabajo: TMSQuery): STRING;
VAR
      objects: STRING;
      fieldName: STRING;
      fieldValue: STRING;
      fieldValueEscaped: STRING;
      finalValue: STRING;
      i: integer;
BEGIN

      objects := objects + '{';

      FOR i := 0 TO QueryConsultaOrdenesTrabajo.FieldCount - 1 DO BEGIN
            fieldName := QueryConsultaOrdenesTrabajo.Fields[i].fieldName;
            fieldValue := QueryConsultaOrdenesTrabajo.Fields[i].AsString;

            fieldValueEscaped := Trim(StringReplace(fieldValue, '\', '\\', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, '"', '\"', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, #13#10, ' ', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, #13, ' ', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, #10, ' ', [rfReplaceAll]));
            fieldValueEscaped := Trim(StringReplace(fieldValueEscaped, #9, ' ', [rfReplaceAll]));

            finalValue := '"' + fieldValueEscaped + '"';
            objects := objects + '"' + fieldName + '":' + finalValue + ',';
      END;

      SetLength(objects, length(objects) - 1); { Borramos la última coma al final }
      objects := objects + '}'; {+  AnsiString(#13#10);}

      Result := objects;

END;

FUNCTION extraerValorFromConfig(key: STRING; configLines: TStringDynArray): STRING;
VAR
      i: integer;
      line: STRING;
      splitted: TStringDynArray;
BEGIN

      i := 0;

      REPEAT

            line := configLines[i];
            splitted := SplitString(line, '=');
            i := i + 1;

      UNTIL (i = length(configLines)) OR (splitted[0] = key);

      IF splitted[0] = key THEN
            Result := splitted[1]
      ELSE

            RAISE Exception.Create('No se encuentra en el config la key: ' + key);

END;

PROCEDURE TFormOrdenesIndividualTrabajoDesol.ConexionServidorConnectionLost(Sender: TObject; Component: TComponent; ConnLostCause: TConnLostCause; VAR RetryMode: TRetryMode);
BEGIN

      TRY

            RetryMode := rmReconnectExecute;

      EXCEPT

            ON e: Exception DO BEGIN
              
                //application.terminate;
                //application.ProcessMessages ;
                  TerminateProcess(GetCurrentProcess(), 0);
                  exit;

            END;

      END;

END;

PROCEDURE TFormOrdenesIndividualTrabajoDesol.FormActivate(Sender: TObject);
BEGIN

      TRY

            EjecutaProceso();

      EXCEPT
            ON E: Exception DO BEGIN

                  TextoMensaje := 'Error al llamar al procedure:  ' + E.Message;
                  EnvioDeEmail(TextoMensaje);
           //application.terminate;
           //application.ProcessMessages ;
                  TerminateProcess(GetCurrentProcess(), 0);
                  exit;

            END;
      END;

END;

PROCEDURE TFormOrdenesIndividualTrabajoDesol.ServidorSMTPFailedRecipient(Sender: TObject; CONST AAddress, ACode, AText: STRING; VAR VContinue: Boolean);
BEGIN

      VContinue := true;

END;

END.

