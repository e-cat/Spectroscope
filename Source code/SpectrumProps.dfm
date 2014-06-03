object fmProps: TfmProps
  Left = 589
  Top = 106
  Width = 264
  Height = 191
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  BorderWidth = 3
  Caption = 'fmProps'
  Color = clBtnFace
  Constraints.MaxWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnCreate = FormCreate
  OnHide = FormHide
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 100
  TextHeight = 13
  object Bevel1: TBevel
    Left = 57
    Top = 40
    Width = 5
    Height = 117
    Align = alLeft
    Shape = bsSpacer
  end
  object Bevel2: TBevel
    Left = 115
    Top = 40
    Width = 5
    Height = 117
    Align = alLeft
    Shape = bsSpacer
  end
  object GroupBox1: TGroupBox
    Left = 62
    Top = 40
    Width = 53
    Height = 117
    Align = alLeft
    Caption = 'Lvl. resp.'
    TabOrder = 2
    object slLevelResponse: TTrackBar
      Left = 11
      Top = 15
      Width = 24
      Height = 100
      Align = alLeft
      LineSize = 30
      Max = 0
      Min = -4605
      Orientation = trVertical
      PageSize = 300
      TabOrder = 0
      TickMarks = tmBoth
      TickStyle = tsNone
      OnChange = slLevelResponseChange
    end
    object Panel1: TPanel
      Left = 2
      Top = 15
      Width = 9
      Height = 100
      Align = alLeft
      BevelOuter = bvLowered
      BorderWidth = 1
      TabOrder = 1
      object paintLevel: TPaintBox
        Left = 2
        Top = 2
        Width = 5
        Height = 83
        Cursor = crCross
        Align = alClient
        OnPaint = paintLevelPaint
      end
      object Label1: TLabel
        Left = 2
        Top = 85
        Width = 5
        Height = 13
        Align = alBottom
        Alignment = taCenter
        Caption = 'L'
      end
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 40
    Width = 57
    Height = 117
    Align = alLeft
    Caption = 'Smp. rate'
    TabOrder = 1
    object slSampleRate: TTrackBar
      Left = 2
      Top = 15
      Width = 24
      Height = 100
      Align = alLeft
      LineSize = 10
      Max = 0
      Min = -6215
      Orientation = trVertical
      PageSize = 300
      TabOrder = 0
      TickMarks = tmBoth
      TickStyle = tsNone
      OnChange = slSampleRateChange
    end
  end
  object gbBufferTime: TGroupBox
    Left = 120
    Top = 40
    Width = 43
    Height = 117
    Align = alLeft
    Caption = 'Buf.'
    TabOrder = 3
    object slBufferTime: TTrackBar
      Left = 2
      Top = 15
      Width = 39
      Height = 100
      Align = alLeft
      Max = 0
      Orientation = trVertical
      PageSize = 50
      Frequency = 100
      TabOrder = 0
      TickMarks = tmBoth
      OnChange = slBufferTimeChange
    end
  end
  object gbDevice: TGroupBox
    Left = 0
    Top = 0
    Width = 250
    Height = 40
    Align = alTop
    Caption = 'Device'
    TabOrder = 0
    object comboDevice: TComboBox
      Left = 4
      Top = 14
      Width = 229
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      OnChange = comboDeviceChange
    end
  end
  object timerPaintLevel: TTimer
    Enabled = False
    Interval = 10
    OnTimer = timerPaintLevelTimer
    Left = 75
    Top = 65520
  end
end
