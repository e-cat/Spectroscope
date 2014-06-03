program Spectrum;

uses
  Forms,
  SpectrumMainForm in 'SpectrumMainForm.pas' {fmMain},
  RangeDlg in 'RangeDlg.pas' {fmRangeDlg},
  SpectrumProps in 'SpectrumProps.pas' {fmProps};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmProps, fmProps);
  Application.Run;
end.
