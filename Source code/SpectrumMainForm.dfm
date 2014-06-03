object fmMain: TfmMain
  Left = 284
  Top = 108
  Width = 294
  Height = 161
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Spectrum'
  Color = clNone
  ParentFont = True
  OldCreateOrder = False
  PopupMenu = PopupMenu1
  ScreenSnap = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 100
  TextHeight = 13
  object paintSpectrum: TPaintBox
    Left = 0
    Top = 0
    Width = 282
    Height = 133
    Cursor = crCross
    Align = alClient
    OnMouseMove = paintSpectrumMouseMove
    OnPaint = paintSpectrumPaint
  end
  object paintScale: TPaintBox
    Left = 282
    Top = 0
    Width = 4
    Height = 133
    Align = alRight
    OnPaint = paintScalePaint
  end
  object PopupMenu1: TPopupMenu
    Left = 21
    Top = 20
    object miColors: TMenuItem
      Caption = 'Colors'
      OnClick = miColorsClick
      object Soft1: TMenuItem
        Tag = 100
        Caption = 'Soft'
        ShortCut = 49
        OnClick = miColorsClick
      end
      object Space1: TMenuItem
        Tag = 101
        Caption = 'Space'
        ShortCut = 50
        OnClick = miColorsClick
      end
      object Raw1: TMenuItem
        Tag = 102
        Caption = 'Raw'
        ShortCut = 51
        OnClick = miColorsClick
      end
    end
    object miView: TMenuItem
      Caption = 'View'
      object Live2: TMenuItem
        Tag = 201
        Caption = 'Live'
        ShortCut = 76
        OnClick = miViewClick
      end
      object Scroll1: TMenuItem
        Tag = 202
        Caption = 'Scroll'
        ShortCut = 83
        OnClick = miViewClick
      end
      object Overwrite1: TMenuItem
        Tag = 203
        Caption = 'Overwrite'
        ShortCut = 79
        OnClick = miViewClick
      end
    end
    object Range1: TMenuItem
      Caption = 'Range...'
      ShortCut = 82
      OnClick = Range1Click
    end
    object miProperties: TMenuItem
      Caption = 'Properties'
      ShortCut = 80
      OnClick = miPropertiesClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object miAlwaysOnTop: TMenuItem
      AutoCheck = True
      Caption = 'Always on Top'
      ShortCut = 65
      OnClick = miAlwaysOnTopClick
    end
  end
end
