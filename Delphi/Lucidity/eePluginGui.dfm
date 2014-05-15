object PluginGui: TPluginGui
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'PluginGui'
  ClientHeight = 802
  ClientWidth = 989
  Color = 15506170
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object RedFoxContainer: TRedFoxContainer
    Left = 0
    Top = 0
    Width = 989
    Height = 802
    Color = '$FF000000'
    Align = alClient
    Padding.Left = 2
    Padding.Top = 2
    Padding.Right = 2
    Padding.Bottom = 2
    object MainPanel: TVamDiv
      AlignWithMargins = True
      Left = 2
      Top = 2
      Width = 983
      Height = 796
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 2
      Margins.Bottom = 2
      Opacity = 255
      HitTest = True
      Align = alClient
      Visible = True
      object MainWorkArea: TVamDiv
        Left = 303
        Top = 0
        Width = 680
        Height = 796
        Opacity = 255
        HitTest = True
        Align = alRight
        Visible = True
        object MainTop: TVamDiv
          Left = 48
          Top = 60
          Width = 521
          Height = 80
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          HitTest = True
          Visible = True
        end
        object MainMenuBar: TVamDiv
          Left = 48
          Top = 7
          Width = 521
          Height = 33
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          HitTest = True
          Visible = True
        end
        object SampleMapDiv: TVamDiv
          Left = 48
          Top = 244
          Width = 521
          Height = 80
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          HitTest = True
          Visible = True
        end
        object VoiceControlDiv: TVamDiv
          Left = 48
          Top = 348
          Width = 521
          Height = 80
          Opacity = 255
          HitTest = True
          Visible = True
        end
        object TabPanel: TVamTabPanel
          Left = 56
          Top = 448
          Width = 513
          Height = 89
          Opacity = 255
          Text = 'TabPanel'
          HitTest = True
          Color_Background = '$ff777776'
          Color_TabOff = '$ffC0C0C0'
          Color_TabOn = '$ffD3D3D3'
          TabHeight = 24
          TabOffset = 8
          TabPadding = 16
          TabSpace = 8
          TabPosition = tpBelowCenter
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          TabIndex = -1
          Tabs.Strings = (
            'SEQUENCER ONE'
            'SEQUENCER TWO'
            'MAIN')
          OnChanged = LowerTabsChanged
          Visible = True
        end
        object ModSystem2Div: TVamDiv
          Left = 48
          Top = 568
          Width = 521
          Height = 49
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          HitTest = True
          Visible = True
        end
        object ZoomSampleDiv: TVamDiv
          Left = 48
          Top = 156
          Width = 521
          Height = 37
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Margins.Bottom = 0
          Opacity = 255
          HitTest = True
          Visible = True
        end
      end
      object SideWorkArea: TVamDiv
        Left = 0
        Top = 0
        Width = 303
        Height = 796
        Opacity = 255
        HitTest = True
        Align = alClient
        Visible = True
        object TitlePanel: TVamPanel
          AlignWithMargins = True
          Left = 0
          Top = 0
          Width = 303
          Height = 49
          Margins.Left = 0
          Margins.Top = 0
          Margins.Right = 0
          Opacity = 255
          HitTest = True
          Color = '$FFCCCCCC'
          CornerRadius1 = 4.000000000000000000
          CornerRadius2 = 4.000000000000000000
          CornerRadius3 = 4.000000000000000000
          CornerRadius4 = 4.000000000000000000
          Transparent = False
          Align = alTop
          Visible = True
          object VamLabel1: TVamLabel
            Left = 0
            Top = 0
            Width = 303
            Height = 49
            Opacity = 255
            Text = 'LUCIDITY'
            HitTest = True
            AutoSize = False
            TextAlign = AlignCenter
            TextVAlign = AlignCenter
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Tahoma'
            Font.Style = [fsBold]
            Align = alClient
            Visible = True
          end
        end
        object SidePanel: TVamDiv
          AlignWithMargins = True
          Left = 24
          Top = 72
          Width = 155
          Height = 480
          Margins.Left = 2
          Margins.Top = 0
          Margins.Right = 2
          Margins.Bottom = 2
          Opacity = 255
          HitTest = True
          Visible = True
          Padding.Left = 4
          Padding.Top = 4
          Padding.Right = 4
          Padding.Bottom = 4
        end
      end
    end
  end
end
