object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 536
  ClientWidth = 1005
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object VamArrows1: TVamArrows
    Left = 104
    Top = 64
    Width = 100
    Height = 41
    Opacity = 255
    HitTest = True
    Color = '$FF000000'
    Visible = True
  end
  object Button1: TButton
    Left = 25
    Top = 461
    Width = 139
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object RedFoxContainer1: TRedFoxContainer
    Left = 25
    Top = 8
    Width = 849
    Height = 425
    Color = '$FFCCCCCC'
    object VamPanel1: TVamPanel
      Left = 56
      Top = 80
      Width = 345
      Height = 225
      Opacity = 255
      Text = 'VamPanel1'
      HitTest = True
      Color = '$FFCCCCCC'
      Transparent = False
      Visible = True
      object VamScrollBar1: TVamScrollBar
        Left = 32
        Top = 16
        Width = 33
        Height = 185
        Opacity = 255
        Text = 'VamScrollBar1'
        HitTest = True
        IndexSize = 0.250000000000000000
        Color_Border = '$FF000000'
        Color_Background = '$FF888888'
        Color_Foreground = '$FFCCCCCC'
        SliderStyle = SquareCorners
        SliderType = stVertical
        Visible = True
      end
    end
  end
  object Button2: TButton
    Left = 23
    Top = 503
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 3
  end
  object Button3: TButton
    Left = 104
    Top = 503
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 4
  end
  object Button4: TButton
    Left = 185
    Top = 503
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 5
  end
  object Button5: TButton
    Left = 185
    Top = 463
    Width = 139
    Height = 25
    Caption = 'Button1'
    TabOrder = 6
    OnClick = Button5Click
  end
  object Memo1: TMemo
    Left = 592
    Top = 463
    Width = 353
    Height = 265
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
end
