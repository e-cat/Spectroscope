unit DetSpectrum;

{$DEFINE HQ}
{$DEFINE SSE}

interface

uses
  Types, Windows, Messages, Classes, SyncObjs, Graphics, Lite, WaveInOut;

const
  DefaultSharpness = -0.7;

  svmLive      = 1;
  svmScroll    = 2;
  svmOverwrite = 3;

  NM_SPECTRUM_CHANGE = $9FFF;

type
  TDetSpectrumBand ={$IFDEF SSE} packed{$ENDIF} record
{$IFDEF SSE}
  case Integer of
    1: (Y, X, SinT, CosT, Persist{$IFDEF HQ}, Acc{$ENDIF}: Single);
    2: (Y_X_SinT_CosT: packed array[0..3] of Single);
    3: (Y_X: packed array[0..1] of Single);
{$ELSE}
    Y, X, SinT, CosT, Persist{$IFDEF HQ}, Acc{$ENDIF}: Real;
{$ENDIF}
  end;

  TSpectrumViewMode = 0..MaxInt;

  TColorFunc = function(const Value: Single): TRGBTriple;

  TDetSpectrum = class(TWaveIn)
  private
    FSharpness: Real;
    FRange: TRange;
    FMaxItersPerSec: Integer;
    FGrid: array of TDetSpectrumBand;
    FGridAccess: TCriticalSection;
    FAvgAmp: Real;
    FAvgAmpPersist: Real;
    FLevelResponse: Real;
    FSampleCounter: Integer;
    FSampleRate: Real;
    FBitmap: TBitmap;
    FBitmapAccess: TCriticalSection;
    FChanged: Boolean;
    FOnChange: TNotifyEvent;
    FColorFunc: TColorFunc;
    FViewMode: TSpectrumViewMode;
    FRightToLeft: Boolean;
    FWritePos: Integer;
    FNeedReset: Boolean;
    FCallbackWindow: HWND;
    procedure CalcAvgAmpPersist;
    function GetAvgLevel: Real;
    function GetMaxAvailableOutputSize: Integer;
    procedure SetColorFunc(const Value: TColorFunc);
    procedure SetLevelResponse(const Value: Real);
    procedure SetRange(const Value: TRange);
    procedure SetSampleRate(const Value: Real);
    procedure SetSharpness(const Value: Real);
    procedure SetViewMode(const Value: TSpectrumViewMode);
  protected
    procedure BitmapWrite(const Values: array of Single); dynamic;
    procedure Change; virtual;
    function OutputCapacity: Integer; dynamic;
    procedure InitGrid;
    procedure Output(const Values: array of Single); virtual;
    procedure ProcessData(var Data; SampleCount: Integer); override;
    procedure ResetBitmap; dynamic;
    procedure ResetOutput; dynamic;
    procedure SetActive(const Value: Boolean); override;
    property Bitmap: TBitmap read FBitmap;
    property Sharpness: Real read FSharpness write SetSharpness;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Draw(Canvas: TCanvas; X, Y: Integer);
    procedure SetViewSize(Width, Height: Integer);
    property Range: TRange read FRange write SetRange;
    property MaxAvailableOutputSize: Integer read GetMaxAvailableOutputSize;
    property LevelResponse: Real read FLevelResponse write SetLevelResponse;
    property AvgLevel: Real read GetAvgLevel;
    property SampleRate: Real read FSampleRate write SetSampleRate;
    property Changed: Boolean read FChanged;
    property ColorFunc: TColorFunc read FColorFunc write SetColorFunc;
    property MaxItersPerSec: Integer read FMaxItersPerSec write FMaxItersPerSec;
    property ViewMode: TSpectrumViewMode read FViewMode write SetViewMode;
    property CallbackWindow: HWND read FCallbackWindow write FCallbackWindow;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

function DefaultColorFunc(const Value: Single): TRGBTriple;

implementation

uses
  SysUtils, Math;

resourcestring
  SInvalidColorFunc = 'Color function can''t be nil';

function DefaultColorFunc(const Value: Single): TRGBTriple;
var
  I: Integer;
begin
  I := EnsureRange(Round($FF * Value), 0, $FF);
  Result.rgbtBlue := I;
  Result.rgbtGreen := I;
  Result.rgbtRed := I;
end;

{ TDetSpectrum }

procedure TDetSpectrum.BitmapWrite(const Values: array of Single);

  procedure WriteLive;
  var
    P: PRGBTripleArray;
    I, J: Integer;
    Levels: array of Integer;
    PixelValues: array[Boolean] of TRGBTriple;
  begin
    if FBitmap.Width >= Length(Values) then
    begin
      PixelValues[False] := FColorFunc(0);
      SetLength(Levels, Length(Values));
      for I := 0 to High(Values) do
        Levels[I] := Round(Values[I] * FBitmap.Height);
      for I := 0 to FBitmap.Height - 1 do
      begin
        P := FBitmap.ScanLine[FBitmap.Height - 1 - I];
        PixelValues[True] := FColorFunc((I + 0.5) / FBitmap.Height);
        for J := 0 to High(Values) do
          P^[J] := PixelValues[Levels[J] > I];
      end;
    end;
  end;

  procedure WriteScroll;
  var
    P: PRGBTripleArray;
    I, J: Integer;
  begin
    if FBitmap.Height >= Length(Values) then
    begin
      if FRightToLeft then
        J := 0
      else
        J := FBitmap.Width - 1;
      for I := 0 to High(Values) do
      begin
        P := FBitmap.ScanLine[High(Values) - I];
        Move(P^[Ord(not FRightToLeft)], P^[Ord(FRightToLeft)],
          (FBitmap.Width - 1) * SizeOf(TRGBTriple));
        P^[J] := FColorFunc(Values[I]);
      end;
    end;
  end;

  procedure WriteOver;
  var
    P: PRGBTripleArray;
    I, J: Integer;
    PixelValue: TRGBTriple;
    WritePos0, WritePos1: Integer;
  begin
    if FBitmap.Height >= Length(Values) then
    begin
      FWritePos := Wrap(FWritePos, 0, FBitmap.Width - 1);
      I := Max(Round(FSampleRate * BufferTime) - 1, 0);
      if FRightToLeft then
      begin
        WritePos0 := Max(FWritePos - I, 0);
        WritePos1 := FWritePos;
      end
      else
      begin
        WritePos0 := FWritePos;
        WritePos1 := Min(FWritePos + I, FBitmap.Width - 1);
      end;
      for I := 0 to High(Values) do
      begin
        P := FBitmap.ScanLine[High(Values) - I];
        PixelValue := FColorFunc(Values[I]);
        for J := WritePos0 to WritePos1 do
          P^[J] := PixelValue;
      end;
      if FRightToLeft then
        Dec(FWritePos)
      else
        Inc(FWritePos);
    end;
  end;

begin
  case FViewMode of
    svmLive:      WriteLive;
    svmScroll:    WriteScroll;
    svmOverwrite: WriteOver;
  end;
end;

procedure TDetSpectrum.CalcAvgAmpPersist;
begin
  FAvgAmpPersist := Exp(-FLevelResponse / PCMFormat.SamplingRate);
end;

procedure TDetSpectrum.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
  if FCallbackWindow <> 0 then
    PostMessage(FCallbackWindow, NM_SPECTRUM_CHANGE, 0, 0);
end;

constructor TDetSpectrum.Create;
begin
  inherited Create;
  BufferTime := 1e-2;
  FSharpness := DefaultSharpness;
  FRange.Min := 20;
  FRange.Max := 20e3;
  FMaxItersPerSec := 20 * 1000 * 1000;  // requires 1.5 GHz with SSE
  SetLevelResponse(4);
  FSampleRate := 120;
  FGridAccess := TCriticalSection.Create;
  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf24bit;
  FBitmapAccess := TCriticalSection.Create;
  FViewMode := svmScroll;
  FColorFunc := DefaultColorFunc;
  if SysLocale.MiddleEast then
    FRightToLeft := True;
end;

destructor TDetSpectrum.Destroy;
begin
  inherited Destroy;
  FBitmap.Free;
  FBitmapAccess.Free;
  FGridAccess.Free;
end;

procedure TDetSpectrum.Draw(Canvas: TCanvas; X, Y: Integer);
begin
  FBitmapAccess.Acquire;
  try
    Canvas.Draw(X, Y, FBitmap);
    FChanged := False;
  finally
    FBitmapAccess.Release;
  end;
end;

function TDetSpectrum.GetAvgLevel: Real;
begin
  Result := -1000;
  if FAvgAmp > 0 then
    Result := AmpdB(FAvgAmp / MaxIntVal(PCMFormat.BitDepth));
end;

function TDetSpectrum.GetMaxAvailableOutputSize: Integer;
begin
  Result := FMaxItersPerSec div PCMFormat.SamplingRate;
end;

procedure TDetSpectrum.InitGrid;
var
  I, Count: Integer;
  Res, ThetaMin, Selectivity, Theta: Real;
  ESinT, ECosT: Extended;
begin
  FGridAccess.Acquire;
  try
    FGrid := nil;
    Count := Min(OutputCapacity, GetMaxAvailableOutputSize);
    SetLength(FGrid, Count);
    if Count > 0 then
    begin
      Res := Ln(FRange.Max / FRange.Min) / Count;
      ThetaMin := 2 * Pi * FRange.Min / PCMFormat.SamplingRate;
      Selectivity := FSharpness * Res;
      for I := 0 to Count - 1 do
        with FGrid[I] do
        begin
          Theta := ThetaMin * Exp(Res * (I + 0.5));
          SinCos(Theta, ESinT, ECosT);
          SinT := ESinT;
          CosT := ECosT;
          Persist := Exp(Selectivity * Theta);
        end;
    end;
  finally
    FGridAccess.Release;
  end;
end;

procedure TDetSpectrum.Output(const Values: array of Single);
begin
  FBitmapAccess.Acquire;
  try
    BitmapWrite(Values);
    FChanged := True;
  finally
    FBitmapAccess.Release;
  end;
  Change;
end;

function TDetSpectrum.OutputCapacity: Integer;
begin
  case FViewMode of
    svmLive: Result := FBitmap.Width;
    svmScroll, svmOverwrite: Result := FBitmap.Height;
  else
    Result := 0;
  end;
end;

procedure TDetSpectrum.ProcessData(var Data; SampleCount: Integer);
var
  Samples: array[0..0, 0..1] of SmallInt absolute Data;
  I, J: Integer;
{$IFDEF SSE}
  Amp: Single;
  PBand: ^TDetSpectrumBand;
{$ELSE}
  Amp, X1: Real;
{$ENDIF}
  Values: array of Single;
begin
  for I := 0 to SampleCount - 1 do
  begin
    Amp := (Samples[I][0] + Samples[I][1]) / 2;
    if Abs(FAvgAmp) > 1 then
    begin
      FGridAccess.Acquire;
      try
        for J := 0 to High(FGrid) do
{$IFDEF SSE}
        begin
          PBand := @FGrid[J];
          asm
            MOV EAX,[PBand]
            MOV EDX,[EAX].TDetSpectrumBand.X
            OR EDX,[EAX].TDetSpectrumBand.Y
            TEST EDX,$60000000  // if X or Y > threshold
            MOVUPS XMM0,[EAX].TDetSpectrumBand.Y_X_SinT_CosT
            JZ @@skip
            MOVUPS XMM1,XMM0
            MOVUPS XMM4,XMM0
            MOVLHPS XMM0,XMM0
            UNPCKHPS XMM1,XMM1
            MULPS XMM0,XMM1    // Y * SinT; X * SinT; Y * CosT; X * CosT
            MOVUPS XMM1,XMM0
            UNPCKHPS XMM0,XMM0
            UNPCKLPS XMM1,XMM1
            MOVHLPS XMM2,XMM0
            MOVHLPS XMM3,XMM1
            SUBSS XMM2,XMM1     // X1 := XCosT - YSinT
            ADDSS XMM0,XMM3     // Y1 := XSinT + YCosT
            UNPCKLPS XMM0,XMM2
            MOVSS XMM1,[EAX].TDetSpectrumBand.Persist
            UNPCKLPS XMM1,XMM1
            MOVLHPS XMM0,XMM4
            MOVLHPS XMM1,XMM4
            MULPS XMM0,XMM1  // Y1 * Persist; X1 * Persist; Y * Y; X * X
@@skip:
            ADDSS XMM0,Amp  // Y1 + Amp
            MOVLPS [EAX].TDetSpectrumBand.Y_X,XMM0  
{$IFDEF HQ}
            JZ @@skip2
            UNPCKHPS XMM0,XMM0
            MOVHLPS XMM1,XMM0
            ADDSS XMM0,XMM1    // SqrX + SqrY
            SQRTSS XMM0,XMM0   // Sqrt()
            ADDSS XMM0,[EAX].TDetSpectrumBand.Acc  // Acc + value
            MOVSS [EAX].TDetSpectrumBand.Acc,XMM0
@@skip2:
{$ENDIF}
          end;
        end;
{$ELSE}
          with FGrid[J] do
          begin
            X1 := Persist * (X * CosT - Y * SinT);
            Y := Persist * (X * SinT + Y * CosT) + Amp;
            X := X1;
{$IFDEF HQ}
            Acc := Acc + Sqrt(Sqr(X) + Sqr(Y));
{$ENDIF}
          end;
{$ENDIF}
      finally
        FGridAccess.Release;
      end;
      Inc(FSampleCounter);
      if FSampleCounter >= PCMFormat.SamplingRate / FSampleRate then
      begin
        FGridAccess.Acquire;
        try
          SetLength(Values, Length(FGrid));
          for J := 0 to High(FGrid) do
            with FGrid[J] do
            begin
              Values[J] := {$IFDEF HQ}Acc / FSampleCounter{$ELSE}Sqrt(Sqr(X) +
                Sqr(Y)){$ENDIF} / (Pi / 4) * (1 - Persist) / FAvgAmp;
{$IFDEF HQ}
              Acc := 0;
{$ENDIF}
            end;
        finally
          FGridAccess.Release;
        end;
        if FNeedReset then
          ResetOutput;
        Output(Values);
        FSampleCounter := 0;
      end;
    end
    else
      FNeedReset := True;
    FAvgAmp := FAvgAmpPersist * FAvgAmp + (1 - FAvgAmpPersist) * Abs(Amp);
  end;
end;

procedure TDetSpectrum.ResetBitmap;
var
  I, J: Integer;
  P: PRGBTripleArray;
  ZeroValue: TRGBTriple;
begin
  ZeroValue := FColorFunc(0);
  for I := 0 to FBitmap.Height - 1 do
  begin
    P := FBitmap.ScanLine[I];
    for J := 0 to FBitmap.Width - 1 do
      P^[J] := ZeroValue;
  end;
  if FRightToLeft then
    FWritePos := FBitmap.Width - 1
  else
    FWritePos := 0;
  FNeedReset := False;
end;

procedure TDetSpectrum.ResetOutput;
begin
  FBitmapAccess.Acquire;
  try
    ResetBitmap;
  finally
    FBitmapAccess.Release;
  end;
end;

procedure TDetSpectrum.SetActive(const Value: Boolean);
var
  I: Integer;
begin
  if Value and not Active then
  begin
    CalcAvgAmpPersist;
    for I := 0 to High(FGrid) do
      with FGrid[I] do
      begin
        X := 0;
        Y := 0;
  {$IFDEF HQ}
        Acc := 0;
  {$ENDIF}
      end;
    FSampleCounter := 0;
    ResetOutput;
  end;
  inherited;
  if not Value then
  begin
    FAvgAmp := 0;
    ResetOutput;
  end;
end;

procedure TDetSpectrum.SetColorFunc(const Value: TColorFunc);
begin
  if not Assigned(Value) then
    raise EInvalidOperation.CreateRes(@SInvalidColorFunc);
  FColorFunc := Value;
end;

procedure TDetSpectrum.SetLevelResponse(const Value: Real);
begin
  FLevelResponse := Value;
  CalcAvgAmpPersist;
end;

procedure TDetSpectrum.SetRange(const Value: TRange);
begin
  if ValidRange(Value) and not EqualRange(Value, FRange) then
  begin
    FRange := Value;
    InitGrid;
  end;
end;

procedure TDetSpectrum.SetSampleRate(const Value: Real);
begin
  FSampleRate := EnsureRange(Value, 1, 1e3);
end;

procedure TDetSpectrum.SetSharpness(const Value: Real);
begin
  if (Value < 0) and (Value <> FSharpness) then
  begin
    FSharpness := Value;
    InitGrid;
  end;
end;

procedure TDetSpectrum.SetViewMode(const Value: TSpectrumViewMode);
begin
  if Value <> FViewMode then
  begin
    FViewMode := Value;
    InitGrid;
    ResetOutput;
  end;
end;

procedure TDetSpectrum.SetViewSize(Width, Height: Integer);
begin
  if (Width <> FBitmap.Width) or (Height <> FBitmap.Height) then
  begin
    FBitmapAccess.Acquire;
    try
      FBitmap.Width := Width;
      FBitmap.Height := Height;
      InitGrid;
      ResetOutput;
    finally
      FBitmapAccess.Release;
    end;
  end;
end;

end.
