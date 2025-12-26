UNIT OrdenesTrabajoDesol;

INTERFACE

USES
      Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
      Data.DB, Vcl.Grids, Vcl.DBGrids, REST.Client, REST.Types, IPPeerClient, IdComponent, IdMessage, IdTCPConnection, IdTCPClient,
      IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP, IdBaseComponent, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
      cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, cxButtons, System.Types, System.IOUtils, StrUtils, Data.Bind.Components,
      Data.Bind.ObjectScope, DBAccess, MSAccess, MemDS, MidasLib, MemData, IdAttachmentFile;

TYPE
      TFormOrdenesDesol = CLASS(TForm)
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
            mmoLog400NoCliente: TMemo;
            mmoLog400Otro: TMemo;
            mmoLogErroresCriticos: TMemo;

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

PROCEDURE AgregarMensajeConSeparador(LogMemo: TMemo; CONST Mensaje: STRING);

FUNCTION GuardarMemoComoArchivo(CONST Memo: TMemo; CONST Identificador: STRING): STRING;

PROCEDURE EliminarArchivosTemporalesViejos(DiasAntiguedad: Integer);

PROCEDURE EjecutaProceso();

CONST
  //WebServiceUrl : string = 'https://jsonplaceholder.typicode.com/posts';
 // WebServiceUrl : string = 'https://us-central1-sils-stage.cloudfunctions.net/handlerViajesYpfGas';  //Testing

      //WebServiceUrl: STRING = 'https://ypfglpapi.desol.com.ar/ot/importar';  // Producción anterior
      WebServiceUrl: STRING = 'https://legajotecnicoapi.ypfgas.com.ar/ot/importar';  // Producción

     

VAR
      FormOrdenesDesol: TFormOrdenesDesol;
      TextoMensaje, ErrorUpdate: STRING;
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
      FechaActual: TDateTime;
BEGIN

      TRY
            EliminarArchivosTemporalesViejos(2);

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
                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;

                  END;

            END;

            TRY
  
                // Conecta con el servidor

                  WITH FormOrdenesDesol.ConexionServidor DO BEGIN

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
                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;

                  END;

            END;

            TRY
    

                 // Ejecuta la query que obtiene los pedidos

                  TextoMensaje := '';
                  ErrorUpdate := '';
                  FormOrdenesDesol.mmoLog400NoCliente.Clear;
                  FormOrdenesDesol.mmoLog400Otro.Clear;
                  FormOrdenesDesol.mmoLogErroresCriticos.Clear;

                  FormOrdenesDesol.QueryConsultaOrdenesTrabajo.Active := true;
                  FormOrdenesDesol.QueryConsultaOrdenesTrabajo.First;

                  WHILE NOT FormOrdenesDesol.QueryConsultaOrdenesTrabajo.Eof DO BEGIN
                        //EnvioDeEmail(FormOrdenesDesol.QueryConsultaOrdenesTrabajo['IDIncidencia']);
                        json := CrearJSON(FormOrdenesDesol.QueryConsultaOrdenesTrabajo);
                       // FormOrdenesDesol.mmo1.lines.text := json;     // Muestra el resultado del jSON en el campo MEMO1
                       // Application.ProcessMessages;
	                    { Poner el sleep acá... }
                        Sleep(500);
                        //EnvioDeEmail(FormOrdenesDesol.QueryConsultaOrdenesTrabajo['IDIncidencia']) ;
                        EnviarDataWebService(json);
           	            //Break ;
                        FormOrdenesDesol.QueryConsultaOrdenesTrabajo.Next;
                  END;

                  IF (Trim(FormOrdenesDesol.mmoLog400NoCliente.Text) <> '') OR (Trim(FormOrdenesDesol.mmoLog400Otro.Text) <> '') OR (Trim(FormOrdenesDesol.mmoLogErroresCriticos.Text)
                        <> '') THEN BEGIN

                        EnvioDeEmail(TextoMensaje);
                  END;

            EXCEPT
                  ON E: Exception DO BEGIN

                        TextoMensaje := 'Error en la ejecución de la Query que retorna el JSON.  ' + E.Message;
                        EnvioDeEmail(TextoMensaje);

                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;
                  END;
            END;


            //ShowMessage(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));


            FormOrdenesDesol.ConexionServidor.Connected := False;
            FormOrdenesDesol.ConexionServidor.Connected := True;

            TRY

              // Actualiza la tabla para monitoreo

                  WITH FormOrdenesDesol.Script DO BEGIN

                        ErrorUpdate := '';
                        FechaActual := Now;
                        sql.Clear;

                        SQL.Add('UPDATE ParametrosApoyoTecnico');
                        SQL.Add('SET FechaUltimaEjecucion = :FechaHora');
                        SQL.Add('WHERE Proceso = ''JSONDigitalizacionCarpetasDESOL''');

                        ParamByName('FechaHora').AsDateTime := FechaActual;

                        Execute;

                  END;

            EXCEPT
                  ON E: Exception DO BEGIN
                        ErrorUpdate := 'Error';
                        TextoMensaje := 'Error al actualizar la fecha de última ejecución en la tabla de parámetros:  ' + E.Message;
                        EnvioDeEmail(TextoMensaje);
                        TerminateProcess(GetCurrentProcess(), 0);
                        exit;

                  END;

            END;

            FormOrdenesDesol.ConexionServidor.Close;
            FormOrdenesDesol.QueryConsultaOrdenesTrabajo.Close;

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
      Adj: TIdAttachmentFile;
      RutaArchivo: STRING;
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
      FormOrdenesDesol.ServidorSMTP.Host := SmtpServer;
      FormOrdenesDesol.ServidorSMTP.Port := strtoint(SmtpPort);
      FormOrdenesDesol.ServidorSMTP.Username := SmtpUser;
      FormOrdenesDesol.ServidorSMTP.Password := SmtpPass;
      FormOrdenesDesol.MensajeSMTP.Clear;
      FormOrdenesDesol.MensajeSMTP.Body.Clear;
      FormOrdenesDesol.MensajeSMTP.Priority := TIdMessagePriority(mpHighest); //prioridad del mensaje
      FormOrdenesDesol.MensajeSMTP.Subject := 'Reporte de envío de Ordenes de Trabajo a Desol - Proyecto Digitalización de Legajos Técnicos';
      FormOrdenesDesol.MensajeSMTP.Body.Text := ('          ' + Saludo + slinebreak + slinebreak);
      //FormOrdenesDesol.MensajeSMTP.Body.Add(Saludo);
      FormOrdenesDesol.MensajeSMTP.Body.Add('          ' + 'Este es un informe automático generado por el sistema.' + slinebreak);
      FormOrdenesDesol.MensajeSMTP.Body.Add('          ' + 'A continuación se listan los distintos tipos de errores detectados.' + slinebreak);
      FormOrdenesDesol.MensajeSMTP.Body.Add('          ' + 'Atentamente.');
      FormOrdenesDesol.MensajeSMTP.Body.Add(slinebreak + slinebreak);
      
      //FormOrdenesDesol.MensajeSMTP.Body.Add('---------------------------------------');


      IF ErrorUpdate <> 'Error' THEN BEGIN
    
      
         
          
        // Log de errores 400 sin cliente
            IF Trim(FormOrdenesDesol.mmoLog400NoCliente.Text) <> '' THEN BEGIN
                 // FormOrdenesDesol.MensajeSMTP.Body.Add('Errores 400 - Cliente no encontrado:');
                 // FormOrdenesDesol.MensajeSMTP.Body.AddStrings(FormOrdenesDesol.mmoLog400NoCliente.Lines);
                  RutaArchivo := GuardarMemoComoArchivo(FormOrdenesDesol.mmoLog400NoCliente, 'Clientes no encontrados');
                  Adj := TIdAttachmentFile.Create(FormOrdenesDesol.MensajeSMTP.MessageParts, RutaArchivo);

            END;
	
       
        // Log de errores 400 con otros motivos

            IF Trim(FormOrdenesDesol.mmoLog400Otro.Text) <> '' THEN BEGIN

                  FormOrdenesDesol.MensajeSMTP.Body.Add('Errores 400 - Otros motivos:');
                  FormOrdenesDesol.MensajeSMTP.Body.AddStrings(FormOrdenesDesol.mmoLog400Otro.Lines);
                  RutaArchivo := GuardarMemoComoArchivo(FormOrdenesDesol.mmoLog400Otro, 'Datos no encontrados');
                  Adj := TIdAttachmentFile.Create(FormOrdenesDesol.MensajeSMTP.MessageParts, RutaArchivo);

            END;
            
            
       // Log de errores críticos (403, 404, 500)

            IF Trim(FormOrdenesDesol.mmoLogErroresCriticos.Text) <> '' THEN BEGIN

                  FormOrdenesDesol.MensajeSMTP.Body.Add('Errores Críticos (403, 404, 500):');
                  FormOrdenesDesol.MensajeSMTP.Body.AddStrings(FormOrdenesDesol.mmoLogErroresCriticos.Lines);
                  RutaArchivo := GuardarMemoComoArchivo(FormOrdenesDesol.mmoLogErroresCriticos, 'Errores Críticos');
                  Adj := TIdAttachmentFile.Create(FormOrdenesDesol.MensajeSMTP.MessageParts, RutaArchivo);

            END;

      END
      ELSE BEGIN

            FormOrdenesDesol.MensajeSMTP.Body.Add('Errores Críticos del Sistema' + slinebreak);
            FormOrdenesDesol.MensajeSMTP.Body.Add('          ' + TextoMensaje);
      END;

                                    
                //FormOrdenesDesol.MensajeSMTP.From.Address := 'albertociancio2018@gmail.com' ;  //quien envía el email
      FormOrdenesDesol.MensajeSMTP.From.Address := SmtpRemitente;  //quien envía el email
      FormOrdenesDesol.MensajeSMTP.From.Name := 'Reporte de envío de Ordenes de Trabajo a Desol - Proyecto Digitalización de Legajos Técnicos';  // texto que se antepone al remitente
      FormOrdenesDesol.MensajeSMTP.Recipients.EMailAddresses := SmtpDestinatario; // 'alberto.ciancio@ypf.com'  ;  //AsignacionesActivasEmailJefe.EditValue ;    //Destinatario
      FormOrdenesDesol.ServidorSMTP.Connect;
      FormOrdenesDesol.ServidorSMTP.Send(FormOrdenesDesol.MensajeSMTP);
      FormOrdenesDesol.ServidorSMTP.IOHandler.InputBuffer.Clear;
      FormOrdenesDesol.ServidorSMTP.IOHandler.CloseGracefully;
      FormOrdenesDesol.ServidorSMTP.Disconnect;

      IF FormOrdenesDesol.ServidorSMTP.Connected THEN BEGIN

            FormOrdenesDesol.ServidorSMTP.Disconnect;

      END;

END;

FUNCTION enviarDataWebService(json: STRING): boolean;
VAR
      client: TRESTClient;
      request: TRESTRequest;
      Content, TextoMensaje: STRING;
      NroIncidencia, Cliente, Planta, NroOrden: STRING;
      Intentos: SmallInt;
CONST
      RETRYABLE_ERRORS: ARRAY[0..2] OF Integer = (403, 404, 500);
BEGIN
      Result := False;
      Intentos := 0;

      REPEAT
            Inc(Intentos);
            client := TRESTClient.Create(nil);
            request := TRESTRequest.Create(client);

            TRY
                  client.BaseURL := WebServiceUrl;
                  client.RaiseExceptionOn500 := False;

                  request.Method := TRESTRequestMethod.rmPost;
                  request.AddBody(json, ctAPPLICATION_JSON);
                  request.Client := client;

                  request.Execute;
                  Content := request.Response.Content;

             // Armar datos complementarios
                  NroIncidencia := IntToStr(FormOrdenesDesol.QueryConsultaOrdenesTrabajo['IDIncidencia']);
                  Cliente := IntToStr(FormOrdenesDesol.QueryConsultaOrdenesTrabajo['Cliente']);
                  Planta := FormOrdenesDesol.QueryConsultaOrdenesTrabajo['Centro'];
                  NroOrden := IntToStr(FormOrdenesDesol.QueryConsultaOrdenesTrabajo['IdOtSap']);

                  IF request.Response.StatusCode = 200 THEN BEGIN
                        Result := True;
                        Break; // Éxito, salir del ciclo
                  END
                  ELSE IF request.Response.StatusCode = 400 THEN BEGIN
                        IF Content.Contains('No se encontró el cliente') THEN BEGIN

                              TextoMensaje := Format('Status %d - Mensaje: %s - Datos: Incidencia: %s - Cliente: %s - Planta: %s - Orden: %s', [Integer(request.Response.StatusCode),
                                    Content, NroIncidencia, Cliente, Planta, NroOrden]);
 
                              //FormOrdenesDesol.mmoLog400NoCliente.Lines.Add(TextoMensaje);
                              AgregarMensajeConSeparador(FormOrdenesDesol.mmoLog400NoCliente, TextoMensaje);
                              // EnvioDeEmail(TextoMensaje);
             //EnvioDeEmail(TextoMensaje);
                              Break; // No reintentar
                        END
                        ELSE BEGIN

                              TextoMensaje := Format('Status %d - Mensaje: %s - Datos: Incidencia: %s - Cliente: %s - Planta: %s - Orden: %s', [Integer(request.Response.StatusCode),
                                    Content, NroIncidencia, Cliente, Planta, NroOrden]);

                              AgregarMensajeConSeparador(FormOrdenesDesol.mmoLog400Otro, TextoMensaje);
                              //FormOrdenesDesol.mmoLog400Otro.Lines.Add(TextoMensaje);
                              //EnvioDeEmail(TextoMensaje);
                              Break; // No reintentar
                        END;
                  END
                  ELSE IF (request.Response.StatusCode = 403) OR (request.Response.StatusCode = 404) OR (request.Response.StatusCode = 500) THEN BEGIN

                        TextoMensaje := Format('Status %d - Mensaje: %s - Datos: Incidencia: %s - Cliente: %s - Planta: %s - Orden: %s', [Integer(request.Response.StatusCode),
                              Content, NroIncidencia, Cliente, Planta, NroOrden]);

                        AgregarMensajeConSeparador(FormOrdenesDesol.mmoLogErroresCriticos, TextoMensaje);
                        //FormOrdenesDesol.mmoLogErroresCriticos.Lines.Add(TextoMensaje);
                        IF (Intentos < 3) THEN
                              Sleep(1000); // Esperar 1 segundo antes de reintentar
                  END
                  ELSE BEGIN
             // Otro error no contemplado explícitamente

                        TextoMensaje := Format('Status %d - Mensaje: %s - Datos: Incidencia: %s - Cliente: %s - Planta: %s - Orden: %s', [Integer(request.Response.StatusCode),
                              Content, NroIncidencia, Cliente, Planta, NroOrden]);

                        AgregarMensajeConSeparador(FormOrdenesDesol.mmoLogErroresCriticos, TextoMensaje);
                        //FormOrdenesDesol.mmoLogErroresCriticos.Lines.Add('Error inesperado: ' + TextoMensaje);
                       // EnvioDeEmail(TextoMensaje);
                        Break;
                  END;

            EXCEPT
                  ON E: Exception DO BEGIN
                        TextoMensaje := 'Excepción al enviar JSON: ' + E.Message;

                        TextoMensaje := Format('Status %d - Mensaje: %s - Datos: Incidencia: %s - Cliente: %s - Planta: %s - Orden: %s', [Integer(request.Response.StatusCode),
                              Content, NroIncidencia, Cliente, Planta, NroOrden]);
                        TextoMensaje := Format('Status %d - Mensaje: %s - Datos: Incidencia: %s - Cliente: %s - Planta: %s - Orden: %s', [Integer(request.Response.StatusCode),
                              Content, NroIncidencia, Cliente, Planta, NroOrden]);

                        AgregarMensajeConSeparador(FormOrdenesDesol.mmoLogErroresCriticos, TextoMensaje);
                        //FormOrdenesDesol.mmoLogErroresCriticos.Lines.Add(TextoMensaje);
                        //EnvioDeEmail(TextoMensaje);
                        Break;
                  END;
            END;

            request.Free;
            client.Free;

      UNTIL Intentos >= 3;

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

PROCEDURE TFormOrdenesDesol.ConexionServidorConnectionLost(Sender: TObject; Component: TComponent; ConnLostCause: TConnLostCause; VAR RetryMode: TRetryMode);
BEGIN

      TRY

            RetryMode := rmReconnectExecute;

      EXCEPT

            ON e: Exception DO BEGIN

                  TerminateProcess(GetCurrentProcess(), 0);
                  exit;

            END;

      END;

END;

PROCEDURE TFormOrdenesDesol.FormActivate(Sender: TObject);
BEGIN

      TRY

            EjecutaProceso();

      EXCEPT
            ON E: Exception DO BEGIN

                  TextoMensaje := 'Error al llamar al procedure:  ' + E.Message;
                  EnvioDeEmail(TextoMensaje);

                  TerminateProcess(GetCurrentProcess(), 0);
                  exit;

            END;
      END;

END;

PROCEDURE TFormOrdenesDesol.ServidorSMTPFailedRecipient(Sender: TObject; CONST AAddress, ACode, AText: STRING; VAR VContinue: Boolean);
BEGIN

      VContinue := true;

END;

PROCEDURE AgregarMensajeConSeparador(LogMemo: TMemo; CONST Mensaje: STRING);
BEGIN
      LogMemo.Lines.Add('');
      LogMemo.Lines.Add('========================================');
      LogMemo.Lines.Add('Registro: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
      LogMemo.Lines.Add(Mensaje);
      LogMemo.Lines.Add('========================================');
      LogMemo.Lines.Add('');
END;

FUNCTION GuardarMemoComoArchivo(CONST Memo: TMemo; CONST Identificador: STRING): STRING;
VAR
      CarpetaTemp, Archivo, NombreArchivo: STRING;
BEGIN
      Result := '';
      IF Assigned(Memo) AND (Trim(Memo.Text) <> '') THEN BEGIN
            CarpetaTemp := GetEnvironmentVariable('TEMP');
            NombreArchivo := 'log_' + Identificador + '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt';
            Archivo := IncludeTrailingPathDelimiter(CarpetaTemp) + NombreArchivo;
            ;
            Memo.Lines.SaveToFile(Archivo);
            Result := Archivo;
      END;
END;

PROCEDURE EliminarArchivosTemporalesViejos(DiasAntiguedad: Integer);
VAR
      CarpetaTemp, Filtro, Archivo: STRING;
      SR: TSearchRec;
      FechaActual, FechaArchivo: TDateTime;
BEGIN
      CarpetaTemp := GetEnvironmentVariable('TEMP'); // Mismo path que GuardarMemoComoArchivo
      Filtro := IncludeTrailingPathDelimiter(CarpetaTemp) + 'log_*.txt';

      FechaActual := Now;

      IF FindFirst(Filtro, faAnyFile, SR) = 0 THEN BEGIN
            REPEAT
                  Archivo := IncludeTrailingPathDelimiter(CarpetaTemp) + SR.Name;

       // Convertir timestamp del archivo a TDateTime
                  FechaArchivo := FileDateToDateTime(SR.Time);

       // Si es más viejo que los días indicados, se elimina
                  IF FechaActual - FechaArchivo > DiasAntiguedad THEN BEGIN
                        DeleteFile(Archivo);
                  END;

            UNTIL FindNext(SR) <> 0;
            FindClose(SR);
      END;
END;

END.

