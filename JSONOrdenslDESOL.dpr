program JSONOrdenslDESOL;

uses
  Vcl.Forms,
  OrdenesTrabajoDesol in 'OrdenesTrabajoDesol.pas' {FormOrdenesDesol};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormOrdenesDesol, FormOrdenesDesol);
  Application.Run;
end.
