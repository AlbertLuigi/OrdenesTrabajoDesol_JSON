unit InterfacePedidos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Data.DB, DBAccess,
  MSAccess, MemDS, Vcl.Grids, Vcl.DBGrids, REST.Client, REST.Types, IPPeerClient;

type
  TForm1 = class(TForm)
    Button1: TButton;
    DataSourceQueryConsultaPedidos: TDataSource;
    DBGrid1: TDBGrid;
    Memo1: TMemo;
    ConexionLocal: TMSConnection;
    script: TMSSQL;
    QueryConsultaPedidos: TMSQuery;
    procedure Button1Click(Sender: TObject);
  private
  public
    { Public declarations }
  end;
  
function EjecutarQueryYRetornarJSON(QueryConsultaPedidos : TMSQuery): string;
function EnviarDataWebService(json : string): boolean;

const
  //WebServiceUrl : string = 'https://jsonplaceholder.typicode.com/posts';
  //WebServiceUrl : string = 'https://us-central1-sils-stage.cloudfunctions.net/handlerViajesYpfGas';  Testing
                              
  
  WebServiceUrl : string = 'https://us-central1-sils-ypf.cloudfunctions.net/handlerViajesYpfGas';  // Producción


var
  Form1: TForm1;
  
implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  json : string;
  datosEnviados: boolean;
begin

  try
    //json := '{"title": "mi titulo", "body": "el cuerpo": "userId": "99"}';
    //json := '{"test-key" : "test-value"}';
    json := EjecutarQueryYRetornarJSON(QueryConsultaPedidos);  
  except on E : Exception do begin
    showmessage('error ejecutando query. ' + E.Message);
    exit;
  end;
  end;

  //memo1.lines.text := json;

  //exit;



  try
    datosEnviados := EnviarDataWebService(json);
    if not datosEnviados then begin
      showmessage('el webservice no retornó OK');                                
    end;
  except on E : Exception do begin
    showmessage('error al enviar los datos al webservice: ' + E.Message);
  end;    
  end;
  

  showmessage('Envío 0k');
  
end;




function enviarDataWebService(json : string): boolean;
var
  client : TRESTClient;
  request : TRESTRequest;
begin
  try
    {client := TRESTClient.Create(nil);
    client.BaseURL := 'https://jsonplaceholder.typicode.com/posts/1';
    request := TRESTRequest.Create(client);
    request.Method := TRESTRequestMethod.rmGet;
    request.Execute;
    memo1.lines.text := request.Response.Content;}

    client := TRESTClient.Create(nil);
    client.BaseURL := WebServiceUrl;
    request := TRESTRequest.Create(client);
    request.Method := TRESTRequestMethod.rmPost;
    request.AddBody(json, ctAPPLICATION_JSON);

    request.Execute;

    //showmessage(IntToStr(request.Response.StatusCode));
    //showmessage(request.Response.Content);

    Result := request.Response.StatusCode = 200;
  finally
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
   
            finalValue := '"' + fieldValueEscaped + '"';
    
            objects := objects + '"' + fieldName + '":' + finalValue + ',';                                                        
        end;

        SetLength(objects, length(objects) - 1);
        objects := objects + '},'; {+  AnsiString(#13#10);}

            QueryConsultaPedidos.Next;
     end;

     SetLength(objects, length(objects) - 1);
     objects := objects + ']';    
     //QueryConsultaPedidos.Active := false ;

     Result := objects;  
end;





end.
