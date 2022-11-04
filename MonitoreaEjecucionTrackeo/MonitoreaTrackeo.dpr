program MonitoreaTrackeo;

uses
  Vcl.Forms,
  MonitoreaEjecucionTrackeo in 'MonitoreaEjecucionTrackeo.pas' {FormTrackeopedidos};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormTrackeopedidos, FormTrackeopedidos);
  Application.Run;
end.
