unit RangeDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Lite;

type
  TfmRangeDlg = class(TForm)
    editMin: TEdit;
    editMax: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Min: TLabel;
    Max: TLabel;
    procedure BitBtn2Click(Sender: TObject);
  private
    FRange: TRange;
    function GetRange: TRange;
  public
    class function Execute(var Range: TRange): Boolean;
  end;

implementation

{$R *.dfm}

function TfmRangeDlg.GetRange: TRange;
begin
  FRange.Min := StrToFloat(editMin.Text);
  FRange.Max := StrToFloat(editMax.Text);
  Result := FRange;
end;

procedure TfmRangeDlg.BitBtn2Click(Sender: TObject);
begin
  try
    if ValidRange(GetRange) then
      Exit;
  except
    on EConvertError do;
  end;
  Beep;
  ModalResult := mrNone;
end;

class function TfmRangeDlg.Execute(var Range: TRange): Boolean;
begin
  with TfmRangeDlg.Create(Application) do
    try
      editMin.Text := FloatToStr(Range.Min);
      editMax.Text := FloatToStr(Range.Max);
      Result := ShowModal = mrOk;
      if Result then
        Range := FRange;
    finally
      Free;
    end;
end;

end.
