program TrackeoPedidos;

uses
  Vcl.Forms,
  InterfacePedidos in 'InterfacePedidos.pas' {FormTrackeopedidos};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormTrackeopedidos, FormTrackeopedidos);
  Application.Run;
end.
