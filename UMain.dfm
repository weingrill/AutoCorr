object Form1: TForm1
  Left = 345
  Top = 229
  Width = 648
  Height = 555
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 164
    Top = 8
    Width = 32
    Height = 13
    Caption = 'Label1'
  end
  object ResImage: TImage
    Left = 0
    Top = 48
    Width = 640
    Height = 480
    Align = alBottom
  end
  object Button1: TButton
    Left = 4
    Top = 4
    Width = 75
    Height = 25
    Caption = 'Load Bitmaps'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 84
    Top = 4
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 1
    OnClick = Button2Click
  end
  object OPDLoad: TOpenPictureDialog
    DefaultExt = 'bmp'
    FilterIndex = 6
    Left = 200
    Top = 4
  end
end
