unit WaveFmt;

interface

uses
  Lite, SysUtils, Classes, MMSystem;

type
  PPCMFormat = ^TPCMFormat;
  TPCMFormat = record
    BitDepth: Integer;
    SamplingRate: Integer;
    ChannelCount: Integer;
  end;

  TPCMSamples8_1 = array[0..0] of Byte;
  TPCMSamples8_2 = array[0..0, 0..1] of Byte;
  TPCMSamples16_1 = array[0..0] of SmallInt;
  TPCMSamples16_2 = array[0..0, 0..1] of SmallInt;
  TPCMSamples24_1 = array[0..0] of Int24;
  TPCMSamples24_2 = array[0..0, 0..1] of Int24;
  TPCMSamples32_1 = array[0..0] of LongInt;
  TPCMSamples32_2 = array[0..0, 0..1] of LongInt;

const
  ValidPCMSamplingRate: TIntRange = (Min: 8000; Max: 192000);

var
  MaxPCMChannels: Integer = 8;

function MakePCMFormat(BitDepth, SamplingRate, ChannelCount: Integer): TPCMFormat;
function ValidPCMFormat(const PCMFormat: TPCMFormat): TPCMFormat;

const
  KSDATAFORMAT_SUBTYPE_PCM: TGUID = '{00000001-0000-0010-8000-00aa00389b71}';
  
  WAVE_FORMAT_EXTENSIBLE   = $FFFE;

  WAVE_FORMAT_DIRECT        = $0008;
  WAVE_FORMAT_DIRECT_QUERY  = WAVE_FORMAT_QUERY or WAVE_FORMAT_DIRECT;

type
  TSpeakerID = (spkFrontLeft, spkFrontRight, spkFrontCenter, spkSubwoofer,
    spkBackLeft, spkBackRight, spkFrontLeftOfCenter, spkFrontRightOfCenter,
    spkBackCenter, spkSideLeft, spkSideRight, spkTopCenter, spkTopFrontLeft,
    spkTopFrontCenter, spkTopFrontRight, spkTopBackLeft, spkTopBackCenter,
    spkTopBackRight);

  TChannelMask = set of TSpeakerID;

  TWaveFormatExtensible = packed record
    Format: TWaveFormatEx;
    case Integer of
      0: (wValidBitsPerSample: Word;
          dwChannelMask: TChannelMask;
          SubFormat: TGUID);
      1: (wSamplesPerBlock: Word);
      2: (wReserved: Word);
  end;
  
procedure SetPCMFormatInfo(var wfe: TWaveFormatExtensible;
  const PCMFormat: TPCMFormat; ChannelMask: TChannelMask = []);

{ defines for dwFormat field of WAVEINCAPS and WAVEOUTCAPS }
const
  WAVE_FORMAT_44M08      = $00000100;       { 44.1   kHz, Mono,   8-bit  }
  WAVE_FORMAT_44S08      = $00000200;       { 44.1   kHz, Stereo, 8-bit  }
  WAVE_FORMAT_44M16      = $00000400;       { 44.1   kHz, Mono,   16-bit }
  WAVE_FORMAT_44S16      = $00000800;       { 44.1   kHz, Stereo, 16-bit }
  WAVE_FORMAT_48M08      = $00001000;       { 48     kHz, Mono,   8-bit  }
  WAVE_FORMAT_48S08      = $00002000;       { 48     kHz, Stereo, 8-bit  }
  WAVE_FORMAT_48M16      = $00004000;       { 48     kHz, Mono,   16-bit }
  WAVE_FORMAT_48S16      = $00008000;       { 48     kHz, Stereo, 16-bit }
  WAVE_FORMAT_96M08      = $00010000;       { 96     kHz, Mono,   8-bit  }
  WAVE_FORMAT_96S08      = $00020000;       { 96     kHz, Stereo, 8-bit  }
  WAVE_FORMAT_96M16      = $00040000;       { 96     kHz, Mono,   16-bit }
  WAVE_FORMAT_96S16      = $00080000;       { 96     kHz, Stereo, 16-bit }

type
  TPCMFormatID = (pcm11m8, pcm11s8, pcm11m16, pcm11s16, pcm22m8, pcm22s8,
    pcm22m16, pcm22s16, pcm44m8, pcm44s8, pcm44m16, pcm44s16, pcm48m8, pcm48s8,
    pcm48m16, pcm48s16, pcm96m8, pcm96s8, pcm96m16, pcm96s16);
  // as binary: 000rrrds; r - smp. rate id, d - 16bit, s - stereo

  TPCMFormatMask = set of TPCMFormatID;

const
  StdPCMSamplingRates: array[0..4] of Integer = (11025, 22050, 44100, 48000, 96000);

function PCMFormatByID(FormatID: TPCMFormatID): TPCMFormat;
function GetPCMFormatID(const PCMFormat: TPCMFormat;
  var FormatID: TPCMFormatID): Boolean;

type
  EInvalidPCMFormatMask = class(Exception);

function HighPCMFormat(Formats: TPCMFormatMask): TPCMFormatID;

  
function IsSupportOutPCMFormat(DeviceID: Integer; const PCMFormat: TPCMFormat): Boolean;
function FindFirstSupportedOutPCMFormat(DeviceID: Integer;
  const SearchFormats: array of TPCMFormat; var ResultFormat: TPCMFormat): Boolean;


function PCMFormatToStr(const PCMFormat: TPCMFormat): string;


type
  TPCMFormats = array of TPCMFormat;

function StrToPCMFormats(const S: string): TPCMFormats;
function PCMFormatsToStr(const Formats: array of TPCMFormat): string;

type
  TCustomWaveFileWriter = class(TFileStream)
  public
    constructor Create(const FileName: string; PCMFormat: TPCMFormat); virtual;
  end;

  TBasicWaveFileWriter = class(TCustomWaveFileWriter)
  private
    FDataOffset: Integer;
  public
    constructor Create(const FileName: string; PCMFormat: TPCMFormat); override;
    destructor Destroy; override;
  end;

type
  EInvalidWaveHeader = class(Exception);

procedure ReadRIFFWaveHeader(Stream: TStream; var PCMFormat: TPCMFormat;
  var BlockCount: Cardinal);
procedure WriteRIFFWaveHeader(Stream: TStream; PCMFormat: TPCMFormat);
procedure WriteRIFFWaveSize(Stream: TStream; DataOffset: Integer);

implementation

uses
  Math, Lite1;

resourcestring
  SInvalidWaveHeader = 'Invalid wave header';
  SInvalidPCMFormatMask = 'Invalid PCM format mask';

function MakePCMFormat(BitDepth, SamplingRate, ChannelCount: Integer): TPCMFormat;
begin
  Result.BitDepth := BitDepth;
  Result.SamplingRate := SamplingRate;
  Result.ChannelCount := ChannelCount;
end;

function ValidPCMFormat(const PCMFormat: TPCMFormat): TPCMFormat;
begin
  with PCMFormat do
  begin
    Result.BitDepth := Min((BitDepth + 7) and $38, 32);
    Result.SamplingRate := EnsureRange(SamplingRate, ValidPCMSamplingRate);
    Result.ChannelCount := EnsureRange(ChannelCount, 1, MaxPCMChannels);
  end;
end;

procedure SetPCMFormatInfo(var wfe: TWaveFormatExtensible;
  const PCMFormat: TPCMFormat; ChannelMask: TChannelMask);
const
  Tags: array[Boolean] of Integer = (WAVE_FORMAT_PCM, WAVE_FORMAT_EXTENSIBLE);
  InfoSizes: array[Boolean] of Integer = (0, SizeOf(TWaveFormatExtensible));
var
  UseExtensible: Boolean;
begin
  with wfe, Format, PCMFormat do
  begin
    UseExtensible := (ChannelCount > 2) or (BitDepth > 16);
    wFormatTag := Tags[UseExtensible];
    nChannels := ChannelCount;
    nSamplesPerSec := SamplingRate;              
    wBitsPerSample := BitDepth;
    nBlockAlign := (wBitsPerSample + 7) div 8 * nChannels;
    nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
    cbSize := InfoSizes[UseExtensible];
    wValidBitsPerSample := wBitsPerSample;
    dwChannelMask := ChannelMask;
    SubFormat := KSDATAFORMAT_SUBTYPE_PCM;
  end;
end;


function PCMFormatByID(FormatID: TPCMFormatID): TPCMFormat;
begin
  with Result do
  begin 
    SamplingRate := StdPCMSamplingRates[Ord(FormatID) shr 2];
    BitDepth := 8 + (Ord(FormatID) and 2) * 4;
    ChannelCount := 1 + Ord(FormatID) and 1;
  end;                                               
end;

function GetPCMFormatID(const PCMFormat: TPCMFormat;
  var FormatID: TPCMFormatID): Boolean;
var
  i: Integer;
begin
  with PCMFormat do
  begin
    i := ValueIndex(SamplingRate, StdPCMSamplingRates);
    Result := (i <> -1) and (BitDepth in [8, 16]) and (ChannelCount in [1, 2]);
    if Result then
      FormatID := TPCMFormatID(i shl 2 + BitDepth div 4 + ChannelCount - 3);
  end;
end;

function HighPCMFormat(Formats: TPCMFormatMask): TPCMFormatID;
var
  I: Integer;
begin
  if not FindLastNZBit(Integer(Formats), I) or (I > Ord(High(TPCMFormatID))) then
    raise EInvalidPCMFormatMask.CreateRes(@SInvalidPCMFormatMask);
  Result := TPCMFormatID(I);
end;


function IsSupportOutPCMFormat(DeviceID: Integer; const PCMFormat: TPCMFormat): Boolean;
var
  wfe: TWaveFormatExtensible;
begin
  SetPCMFormatInfo(wfe, PCMFormat);
  Result := waveOutOpen(nil, DeviceID, @wfe.Format, 0, 0,
    WAVE_FORMAT_DIRECT_QUERY) = MMSYSERR_NOERROR;
end;
  
function FindFirstSupportedOutPCMFormat(DeviceID: Integer;
  const SearchFormats: array of TPCMFormat; var ResultFormat: TPCMFormat): Boolean;
var
  woc: TWaveOutCaps;
  i: Integer;
  pcmfi: TPCMFormatID;
begin
  if waveOutGetDevCaps(DeviceID, @woc, SizeOf(TWaveOutCaps)) <> MMSYSERR_NOERROR
    then woc.dwFormats := 0;
  for i := 0 to High(SearchFormats) do
    if GetPCMFormatID(SearchFormats[i], pcmfi) and (pcmfi in TPCMFormatMask(
      woc.dwFormats)) or IsSupportOutPCMFormat(DeviceID, SearchFormats[i]) then
    begin
      ResultFormat := SearchFormats[i];
      Result := True;
      Exit;
    end;
  Result := False;
end;


resourcestring
  SPCMFormat = '%u-bit, %g kHz, %s';
  SPCMFormatMultiChannel = '%u-bit, %g kHz, %d-channel';
  SMono = 'mono';
  SStereo = 'stereo';

function PCMFormatToStr(const PCMFormat: TPCMFormat): string;
const
  SMonoStereo: array[1..2] of string = (SMono, SStereo);
begin
  with PCMFormat do
    if ChannelCount in [1, 2] then
      Result := Format(SPCMFormat, [BitDepth, SamplingRate * 1.e-3,
        SMonoStereo[ChannelCount]])
    else
      Result := Format(SPCMFormatMultiChannel, [BitDepth, SamplingRate *
        1.e-3, ChannelCount])
end;


function StrToPCMFormats(const S: string): TPCMFormats;
var
  i, v1, e, l: Integer;
  P, Start: PChar;
  buf: array[0..15] of char;
  v2: Extended;

  procedure SetBuf;
  var
    len: Integer;
  begin
    len := P - Start;
    if len >= SizeOf(buf) then
      len := 0;
    Move(Start^, buf, len);
    buf[len] := #0;
  end;

begin
  i := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    Start := P;
    while not (P^ in ['/', ';', #0]) do
      Inc(P);
    case P^ of
      '/':
        begin
          SetBuf;
          Inc(P);
          Val(PChar(@buf), v1, e);
          if (e = 0) and (v1 in [8, 16, 24, 32]) then
          begin
            Start := P;
            while not (P^ in [' ', ';', #0]) do
              Inc(P);
            SetBuf;
            if TextToFloat(buf, v2, fvExtended) and (v2 >=
              ValidPCMSamplingRate.Min div 1000) and (v2 <=
              ValidPCMSamplingRate.Max div 1000) then
            begin
              while P^ = ' ' do
                Inc(P);
              l := Length(Result);
              if l <= i then
                if l = 0 then
                  l := 16
                else
                  l := l * 2;
              SetLength(Result, l);
              with Result[i] do
              begin
                BitDepth := v1;
                SamplingRate := Round(v2 * 1e3);
                ChannelCount := 2 - Ord(P^ = 'm');
              end;
              Inc(i);
            end;
          end;
        end;
      ';': Inc(P);
    end;
  end;
  SetLength(Result, i);
end;

function PCMFormatsToStr(const Formats: array of TPCMFormat): string;
const
  fmt = '%u/%g';
var
  i, len: Integer;
  buf: array[0..1024] of Char;
begin
  len := 0;
  for i := 0 to High(Formats) do
    with Formats[i] do
    begin
      if (i > 0) then
        Inc(len, FormatBuf(buf[len], SizeOf(buf) - len, '; ', 2, []));
      Inc(len, FormatBuf(buf[len], SizeOf(buf) - len, fmt, Length(fmt),
        [BitDepth, SamplingRate * 1.e-3]));
      if ChannelCount = 1 then
        Inc(len, FormatBuf(buf[len], SizeOf(buf) - len, ' m', 2, []));
    end;
  SetString(Result, buf, len);
end;


type
  TRIFFChunkHeader = record
    ID: TDWORDID;
    DataSize: LongWord;
  end;

const
  WaveTag: TDWORDID = 'WAVE';

procedure ReadRIFFWaveHeader(Stream: TStream; var PCMFormat: TPCMFormat;
  var BlockCount: Cardinal);

  procedure Error;
  begin
    raise EInvalidWaveHeader.CreateRes(@SInvalidWaveHeader);
  end;

  procedure CheckSize(Size: Integer);
  begin
    if Stream.Size - Stream.Position < Size then
      Error;
  end;

  procedure ReadChunk(ID: TDWORDID; var DataSize: Cardinal; PData: Pointer = nil);
  var
    Header: TRIFFChunkHeader;
  begin
    CheckSize(SizeOf(Header) + DataSize);
    Stream.ReadBuffer(Header, SizeOf(Header));
    if (LongWord(Header.ID) <> LongWord(ID)) or (Header.DataSize < DataSize) then
      Error;
    Stream.ReadBuffer(PData^, DataSize);
    DataSize := Header.DataSize;
  end;

var
  FormatIDSize, FormatSize, DataSize: Cardinal;
  FormatID: TDWORDID;
  wfe: TWaveFormatExtensible;
begin
  FormatIDSize := SizeOf(FormatID);
  ReadChunk('RIFF', FormatIDSize, @FormatID);
  if LongWord(FormatID) <> LongWord(WaveTag) then
    Error;
  FormatSize := $10;
  ReadChunk('fmt ', FormatSize, @wfe);
  with PCMFormat, wfe, Format do
  begin
    case wFormatTag of
      WAVE_FORMAT_PCM: ;
      WAVE_FORMAT_EXTENSIBLE:
        begin
          CheckSize(SizeOf(cbSize));
          Stream.ReadBuffer(cbSize, SizeOf(cbSize));
          if cbSize <> SizeOf(TWaveFormatExtensible) then
            Error;
          DataSize := SizeOf(TWaveFormatExtensible) - SizeOf(TWaveFormatEx);
          CheckSize(DataSize);
          Stream.ReadBuffer(Pointer(Integer(@wfe) + SizeOf(TWaveFormatEx))^,
            DataSize);
        end;
    else
      Error;
    end;
    BitDepth := wBitsPerSample;
    SamplingRate := nSamplesPerSec;
    ChannelCount := nChannels;
    DataSize := 0;
    ReadChunk('data', DataSize);
    BlockCount := DataSize div nBlockAlign;
  end;
end;

procedure WriteRIFFWaveHeader(Stream: TStream; PCMFormat: TPCMFormat);

  procedure WriteChunk(ID: TDWORDID; DataSize: Cardinal = 0;
    PData: Pointer = nil);
  var
    Header: TRIFFChunkHeader;
  begin
    Header.ID := ID;
    Header.DataSize := DataSize;
    Stream.WriteBuffer(Header, SizeOf(Header));
    Stream.WriteBuffer(PData^, DataSize);
  end;

var
  wfe: TWaveFormatExtensible;
begin
  WriteChunk('RIFF', SizeOf(WaveTag), @WaveTag);
  SetPCMFormatInfo(wfe, PCMFormat);
  WriteChunk('fmt ', $10 + Ord(wfe.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE) *
    (wfe.Format.cbSize - $10), @wfe);
  WriteChunk('data');
end;

procedure WriteRIFFWaveSize(Stream: TStream; DataOffset: Integer);

  procedure WriteDataSize(Offset: Integer; DataSize: LongWord);
  begin
    Stream.Seek(Offset, soFromBeginning);
    Stream.WriteBuffer(DataSize, SizeOf(DataSize));
  end;

const
  PadByte: Byte = 0;
begin
  WriteDataSize(DataOffset - 4, Stream.Size - DataOffset);
  if Stream.Size and 1 <> 0 then
  begin
    Stream.Seek(0, soFromEnd);
    Stream.WriteBuffer(PadByte, 1);
  end;
  WriteDataSize(4, Stream.Size - 8);
end;

{ TCustomWaveFileWriter }

constructor TCustomWaveFileWriter.Create(const FileName: string;
  PCMFormat: TPCMFormat);
begin
  inherited Create(FileName, fmCreate);
end;

{ TBasicWaveFileWriter }

constructor TBasicWaveFileWriter.Create(const FileName: string;
  PCMFormat: TPCMFormat);
begin
  inherited Create(EnsureFileExt(FileName, '.wav'), PCMFormat);
  WriteRIFFWaveHeader(Self, PCMFormat);
  FDataOffset := Position;
end;

destructor TBasicWaveFileWriter.Destroy;
begin
  if FDataOffset <> 0 then
    WriteRIFFWaveSize(Self, FDataOffset);
  inherited Destroy;
end;

end.
