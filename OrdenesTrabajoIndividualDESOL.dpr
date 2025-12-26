program OrdenesTrabajoIndividualDESOL;

uses
  Vcl.Forms,
  InterfazIndividualOrdenesTrabajoDESOL in 'InterfazIndividualOrdenesTrabajoDESOL.pas' {FormOrdenesIndividualTrabajoDesol};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormOrdenesIndividualTrabajoDesol, FormOrdenesIndividualTrabajoDesol);
  Application.Run;
end.
