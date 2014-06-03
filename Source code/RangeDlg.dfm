object fmRangeDlg: TfmRangeDlg
  Left = 674
  Top = 407
  AlphaBlend = True
  AlphaBlendValue = 192
  BorderStyle = bsDialog
  Caption = 'Range'
  ClientHeight = 89
  ClientWidth = 166
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 100
  TextHeight = 13
  object Min: TLabel
    Left = 26
    Top = 10
    Width = 20
    Height = 13
    Alignment = taRightJustify
    Caption = 'Min:'
  end
  object Max: TLabel
    Left = 23
    Top = 35
    Width = 23
    Height = 13
    Alignment = taRightJustify
    Caption = 'Max:'
  end
  object editMin: TEdit
    Left = 51
    Top = 7
    Width = 69
    Height = 21
    MaxLength = 15
    TabOrder = 0
  end
  object editMax: TEdit
    Left = 51
    Top = 32
    Width = 69
    Height = 21
    MaxLength = 15
    TabOrder = 1
  end
  object BitBtn1: TBitBtn
    Left = 86
    Top = 59
    Width = 75
    Height = 25
    TabOrder = 2
    Kind = bkCancel
  end
  object BitBtn2: TBitBtn
    Left = 6
    Top = 59
    Width = 75
    Height = 25
    TabOrder = 3
    OnClick = BitBtn2Click
    Kind = bkOK
  end
end
