unit InWindowDialog;

interface

uses
  Vcl.Forms,
  InWindowDialog.CustomDialog,
  InWindowDialog.MessageDialog,
  InWindowDialog.InputDialog;

type
  TInputDialogResultCallback  = InWindowDialog.InputDialog.TDialogResultCallback;
  TCustomDialogResultCallback = InWindowDialog.CustomDialog.TDialogResultCallback;

procedure InWindow_ShowMessage(const TopLevelForm : TForm; const Msg : string);
procedure InWindow_InputDialog(const TopLevelForm : TForm; const Text, InputLabel, DefaultValue : string; ResultHandler : TInputDialogResultCallback);

procedure InWindow_CustomDialog(const TopLevelForm : TForm; const Msg : string; const Buttons : array of string; ResultHandler : TCustomDialogResultCallback);

// TODO:MED need an InWindow about dialog to replace uAboutDialog.pas.

implementation


procedure InWindow_ShowMessage(const TopLevelForm : TForm; const Msg : string);
var
  MsgDialog : TMessageDialog;
begin
  MsgDialog := TMessageDialog.Create;
  MsgDialog.Text := Msg;
  MsgDialog.ShowInWindow_WithAutoFree(TopLevelForm, true, true);
end;

procedure InWindow_InputDialog(const TopLevelForm : TForm; const Text, InputLabel, DefaultValue : string; ResultHandler : TInputDialogResultCallback);
var
  InputDialog : TInputDialog;
begin
  InputDialog := TInputDialog.Create;
  InputDialog.InputText := Text;
  InputDialog.InputLabel := InputLabel;
  InputDialog.DefaultValue := DefaultValue;
  InputDialog.DialogResultHandler := ResultHandler;
  InputDialog.ShowInWindow_WithAutoFree(TopLevelForm, true, true);
end;

procedure InWindow_CustomDialog(const TopLevelForm : TForm; const Msg : string; const Buttons : array of string; ResultHandler : TCustomDialogResultCallback);
var
  CustomDialog : TCustomDialog;
begin
  CustomDialog := TCustomDialog.Create;
  CustomDialog.Text := Msg;
  CustomDialog.AddButtons(Buttons);
  CustomDialog.DialogResultHandler := ResultHandler;
  CustomDialog.ShowInWindow_WithAutoFree(TopLevelForm, true, true);
end;

end.
