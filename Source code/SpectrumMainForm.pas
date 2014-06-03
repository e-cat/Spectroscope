unit SpectrumMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, Menus, DetSpectrum, SyncObjs, StdCtrls;

type
  TfmMain = class(TForm)
    paintSpectrum: TPaintBox;
    PopupMenu1: TPopupMenu;
    miColors: TMenuItem;
    miAlwaysOnTop: TMenuItem;
    paintScale: TPaintBox;
    Range1: TMenuItem;
    miProperties: TMenuItem;
    Soft1: TMenuItem;
    Space1: TMenuItem;
    Raw1: TMenuItem;
    miView: TMenuItem;
    Live2: TMenuItem;
    Scroll1: TMenuItem;
    Overwrite1: TMenuItem;
    N1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure paintSpectrumPaint(Sender: TObject);
    procedure paintSpectrumMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure miColorsClick(Sender: TObject);
    procedure miAlwaysOnTopClick(Sender: TObject);
    procedure paintScalePaint(Sender: TObject);
    procedure Range1Click(Sender: TObject);
    procedure miPropertiesClick(Sender: TObject);
    procedure miViewClick(Sender: TObject);
  private
    FColorsIndex: Integer;
    FrequncyStr: string;
    MouseTracking: Boolean;
    tme: TTrackMouseEvent;
    procedure SetColorsIndex(const Value: Integer);
    procedure WMMouseLeave(var Message: TMessage); message WM_MOUSELEAVE;
    procedure FormatTitle;
    procedure ViewModeChanged;
    procedure NMSpectrumChange(var Message: TMessage);
      message NM_SPECTRUM_CHANGE;
  public
    Spectrum: TDetSpectrum;
    property ColorsIndex: Integer read FColorsIndex write SetColorsIndex;
  end;

var
  fmMain: TfmMain;

implementation

uses
  MMSystem, Math, Registry, Lite, Lite1, Lite2, WaveInOut, CtlUtils, RangeDlg,
  SpectrumProps;

{$R *.dfm}
{$R WindowsXP.res}

procedure TfmMain.FormCreate(Sender: TObject);
var
  S: string;
  I: Integer;
begin
  paintSpectrum.ControlStyle := paintSpectrum.ControlStyle + [csOpaque];
  tme.cbSize := SizeOf(TTrackMouseEvent);
  tme.dwFlags := TME_LEAVE;
  tme.hwndTrack := Handle;

  Spectrum := TDetSpectrum.Create;
  Spectrum.CallbackWindow := Handle;

  ColorsIndex := 0;
  try
    RestoreFormPlacement(Self);
    with TRegistry.Create do
      try
        if OpenKey(RegKey, False) then
          with Spectrum do
          begin
            if ValueExists('RangeMin') then
              Range := Lite.Range(ReadFloat('RangeMin'), ReadFloat('RangeMax'));
            if ValueExists('Device') then
            begin
              S := ReadString('Device');
              with TWaveIn.Create do
              try
                for I := -1 to waveInGetNumDevs - 1 do
                begin
                  DeviceID := I;
                  if S = DeviceName then
                  begin
                    Spectrum.DeviceID := DeviceID;
                    Break;
                  end;
                end;
              finally
                Free;
              end;
            end;
            if GetDataType('SampleRate') = rdBinary then
              SampleRate := ReadFloat('SampleRate');
            if ValueExists('LevelResponse') then
              LevelResponse := ReadFloat('LevelResponse');
            if ValueExists('ColorsIndex') then
              ColorsIndex := ReadInteger('ColorsIndex');
            if ValueExists('BufferTime') then
              BufferTime := ReadFloat('BufferTime');
            if ValueExists('ViewMode') then
              ViewMode := ReadInteger('ViewMode');
            miAlwaysOnTop.Checked := ReadBool('AlwaysOnTop');
            SetTopmost(Handle, miAlwaysOnTop.Checked);
          end;
      finally
        Free;
      end;
  except
    Application.HandleException(Self);
  end;
  ViewModeChanged;
  FormatTitle;

  Spectrum.Active := True;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  Spectrum.Free;
end;

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  SaveFormPlacement;
  with TRegistry.Create do
    try
      if OpenKey(RegKey, True) then
        with Spectrum do
        begin
          WriteFloat('RangeMin', Range.Min);
          WriteFloat('RangeMax', Range.Max);
          WriteString('Device', DeviceName);
          WriteFloat('SampleRate', SampleRate);
          WriteFloat('LevelResponse', LevelResponse);
          WriteInteger('ColorsIndex', ColorsIndex);
          WriteFloat('BufferTime', BufferTime);
          WriteInteger('ViewMode', ViewMode);
          WriteBool('AlwaysOnTop', miAlwaysOnTop.Checked);
        end;
    finally
      Free;
    end;
  SaveFormPlacement(fmProps);
end;

procedure TfmMain.FormResize(Sender: TObject);
begin
  with paintSpectrum do
    Spectrum.SetViewSize(Width, Height);
end;

procedure TfmMain.NMSpectrumChange(var Message: TMessage);
begin
  if Spectrum.Changed then
    paintSpectrum.Invalidate;
end;

procedure TfmMain.paintSpectrumPaint(Sender: TObject);
begin
  Spectrum.Draw(paintSpectrum.Canvas, 0, 0);
end;

procedure TfmMain.paintScalePaint(Sender: TObject);
var
  Freq, LogMin, LogFreq, Res: Real;
  I, Count, Pos: Integer;
begin
  if Spectrum.ViewMode = svmLive then
    Count := paintScale.Width
  else
    Count := paintScale.Height;
  LogMin := Log10(Spectrum.Range.Min);
  Res := Count / (Log10(Spectrum.Range.Max) - LogMin);
  I := 1;
  Freq := 20;
  while Freq < 3e4 do
    with paintScale, Canvas do
    begin
      LogFreq := Log10(Freq);
      Pos := Round((LogFreq - LogMin) * Res);
      if Color and $808080 = 0 then
        Pen.Color := Hue(I mod 9 * 30)
      else
        Pen.Color := clBlack;
      if Spectrum.ViewMode = svmLive then
      begin
        MoveTo(Pos, 0);
        LineTo(Pos, Height);
      end
      else
      begin
        Pos := Count - Pos;
        MoveTo(0, Pos);
        LineTo(Width, Pos);
      end;
      Freq := Freq + IntPower(10, Trunc(LogFreq));
      Inc(I);
    end;
end;

procedure TfmMain.FormatTitle;     
begin
  Caption := ProductName + FrequncyStr;
end;

procedure TfmMain.paintSpectrumMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Pos, Freq, Dummy: Real;
begin
  with paintSpectrum do
    if Spectrum.ViewMode = svmLive then
      Pos := (X + 0.5) / Width
    else
      Pos := 1 - (Y + 0.5) / Height;
  with Spectrum.Range do
    Freq := Exp(Ln(Min) + Pos * (Ln(Max) - Ln(Min)));
  FrequncyStr := Format('  %.5g Hz  %3s', [Freq, NoteName(NoteByFrequency(Freq,
    Dummy))]);
  FormatTitle;
  if not MouseTracking then
    MouseTracking := TrackMouseEvent(tme);
end;

procedure TfmMain.WMMouseLeave(var Message: TMessage);
begin
  FrequncyStr := '';
  FormatTitle;
  MouseTracking := False;
end;

procedure TfmMain.miColorsClick(Sender: TObject);
begin
  ColorsIndex := (Sender as TComponent).Tag - 100;
end;

function Climb(X, OX, OY: Integer): Integer;
begin
  Result := EnsureRange(OY - Abs(X - OX), 0, $FF);
end;

function ColorFunc1(const Value: Single): TRGBTriple;
var
  NormValue, V1: Integer;
begin
  NormValue := Round(Value * $3BE);
  V1 := Climb(NormValue, $FF, $FF);
  Result.rgbtRed := V1;
  Result.rgbtGreen := V1 + EnsureRange(NormValue - $1FE, 0, $FF);
  Result.rgbtBlue := Climb(NormValue, $1DF, $1DF);
end;

function ColorFunc2(const Value: Single): TRGBTriple;
var
  NormValue, V1: Integer;
begin
  NormValue := Round(Value * $37F);
  V1 := Max($FF - NormValue, 0);
  Result.rgbtRed := V1 + Climb(NormValue, $23F, $140);
  Result.rgbtGreen := V1 + EnsureRange(NormValue - $1BE, 0, $FF);
  Result.rgbtBlue := V1;
end;

procedure SetMenuChecks(Items: TMenuItem; Base, Index: Integer);
var
  I, J: Integer;
begin
  with Items do
    for I := 0 to Count - 1 do
    begin
      J := Items[I].Tag;
      if (J >= Base) and (J <= Base + 99) then
        Items[I].Checked := J = Base + Index;
    end;
end;

const
  ColorFunctions: array[0..2] of TColorFunc = (ColorFunc2,
    ColorFunc1, DefaultColorFunc);

procedure TfmMain.SetColorsIndex(const Value: Integer);
begin
  if (Value >= Low(ColorFunctions)) and (Value <= High(ColorFunctions)) then
  begin
    Spectrum.ColorFunc := ColorFunctions[Value];
    SetMenuChecks(miColors, 100, Value);
    with Spectrum.ColorFunc(0) do
      Color := RGB(rgbtRed, rgbtGreen, rgbtBlue);
    paintScale.Repaint;  
    FColorsIndex := Value;
  end;
end;

procedure TfmMain.miAlwaysOnTopClick(Sender: TObject);
begin
  SetTopmost(Handle, miAlwaysOnTop.Checked);
end;

procedure TfmMain.Range1Click(Sender: TObject);
var
  NewRange: TRange;
begin
  NewRange := Spectrum.Range;
  if TfmRangeDlg.Execute(NewRange) then
    Spectrum.Range := NewRange;
end;

procedure TfmMain.miPropertiesClick(Sender: TObject);
begin
  fmProps.Show;
end;

procedure TfmMain.miViewClick(Sender: TObject);
begin
  Spectrum.ViewMode := TSpectrumViewMode((Sender as TComponent).Tag - 200);
  ViewModeChanged;
end;

procedure TfmMain.ViewModeChanged;
begin
  with Constraints, Spectrum do
  begin
    SetMenuChecks(miView, 200, ViewMode);
    MaxWidth := 0;
    MaxHeight := 0;
    case ViewMode of
      svmLive:
        begin
          MaxWidth := MaxAvailableOutputSize + (Width - ClientWidth);
          paintScale.Align := alBottom;
          paintScale.Height := 3;
        end;
      svmScroll, svmOverwrite:
        begin
          MaxHeight := MaxAvailableOutputSize + (Height - ClientHeight);
          if SysLocale.MiddleEast then
            paintScale.Align := alLeft
          else
            paintScale.Align := alRight;
          paintScale.Width := 3;
        end;
    end;
  end;
  Resize;
end;

initialization
  ProductName := 'Spectrum';

end.
