unit SpectrumProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TfmProps = class(TForm)
    timerPaintLevel: TTimer;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    gbBufferTime: TGroupBox;
    slLevelResponse: TTrackBar;
    Panel1: TPanel;
    paintLevel: TPaintBox;
    Label1: TLabel;
    slBufferTime: TTrackBar;
    slSampleRate: TTrackBar;
    Bevel1: TBevel;
    Bevel2: TBevel;
    gbDevice: TGroupBox;
    comboDevice: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure timerPaintLevelTimer(Sender: TObject);
    procedure paintLevelPaint(Sender: TObject);
    procedure slBufferTimeChange(Sender: TObject);
    procedure slSampleRateChange(Sender: TObject);
    procedure slLevelResponseChange(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure comboDeviceChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    ControlsInit: Boolean;
    procedure FormatTitle;
  end;

var
  fmProps: TfmProps;

implementation

uses
  MMSystem, CommCtrl, Lite, Lite1, WaveInOut, CtlUtils, DetSpectrum,
  SpectrumMainForm;

{$R *.dfm}

const
  LevelResponseSliderMultiplier = -1e3;
  SampleRateSliderMultiplier = -1e3;
  BufferTimeSliderMultiplier = -1e4;

procedure TfmProps.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Constraints.MinWidth := gbBufferTime.BoundsRect.Right + (Width - ClientWidth);
  paintLevel.ControlStyle := paintLevel.ControlStyle + [csOpaque];
  RestoreFormPlacement(Self);
  ControlsInit := True;
  try
    slBufferTime.Min := -500;
    slBufferTime.Max := -10;
    ChangeWindowStyle(slSampleRate.Handle, 0, TBS_ENABLESELRANGE);
    ChangeWindowStyle(slLevelResponse.Handle, 0, TBS_ENABLESELRANGE);
    ChangeWindowStyle(slBufferTime.Handle, 0, TBS_ENABLESELRANGE);
    with TWaveIn.Create do
      try
        for I := -1 to waveInGetNumDevs - 1 do
        begin
          DeviceID := I;
          comboDevice.Items.Add(DeviceName);
        end;
      finally
        Free;
      end;
    with fmMain.Spectrum do
    begin
      comboDevice.ItemIndex := DeviceID + 1;
      slLevelResponse.Position := Round(Ln(LevelResponse) *
        LevelResponseSliderMultiplier);
      slSampleRate.Position := Round(Ln(SampleRate) *
        SampleRateSliderMultiplier);
      slBufferTime.Position := Round(BufferTime * BufferTimeSliderMultiplier);
    end;
  finally
    ControlsInit := False;
  end;
  FormatTitle;
end;

procedure TfmProps.FormHide(Sender: TObject);
begin
  timerPaintLevel.Enabled := False;
end;

procedure TfmProps.FormShow(Sender: TObject);
begin
  timerPaintLevel.Enabled := True;
end;

procedure TfmProps.timerPaintLevelTimer(Sender: TObject);
begin
  paintLevel.Invalidate;
end;

procedure TfmProps.paintLevelPaint(Sender: TObject);
var
  Y: Integer;
begin
  with paintLevel, Canvas do
  begin
    Y := Round((fmMain.Spectrum.AvgLevel / -AmpdB(MaxIntVal(
      fmMain.Spectrum.PCMFormat.BitDepth))) * Height);
    Brush.Color := clBtnFace;
    FillRect(Rect(0, 0, Width, Y));
    Brush.Color := clHighlight;
    FillRect(Rect(0, Y, Width, Height));
  end;
end;

procedure TfmProps.slBufferTimeChange(Sender: TObject);
begin
  if ControlsInit then
    Exit;
  with fmMain.Spectrum do
  begin
    Active := False;
    BufferTime := slBufferTime.Position / BufferTimeSliderMultiplier;
    Active := True;
  end;
  FormatTitle;
end;

procedure TfmProps.slSampleRateChange(Sender: TObject);
begin
  if ControlsInit then
    Exit;
  fmMain.Spectrum.SampleRate := Round(Exp(slSampleRate.Position /
    SampleRateSliderMultiplier));
  FormatTitle;
end;

procedure TfmProps.slLevelResponseChange(Sender: TObject);
begin
  if ControlsInit then
    Exit;
  fmMain.Spectrum.LevelResponse := Exp(slLevelResponse.Position /
    LevelResponseSliderMultiplier);
  FormatTitle;
end;

procedure TfmProps.FormatTitle;
begin
  with fmMain.Spectrum do
    Caption := Format('%.0f Hz/%.1f/%.1fms - spectrum',
      [SampleRate, LevelResponse, BufferTime * 1e3]);
end;

procedure TfmProps.comboDeviceChange(Sender: TObject);
begin
  if ControlsInit then
    Exit;
  with fmMain.Spectrum do
  begin
    Active := False;
    DeviceID := comboDevice.ItemIndex - 1;
    Active := True;
  end;
end;

procedure TfmProps.FormResize(Sender: TObject);
begin
  comboDevice.Width := gbDevice.ClientWidth - comboDevice.Left * 2;
end;

end.
