//
// PasExpat 2.0.0 RM0.83 compiler options configuration file
//

{$IFDEF DEBUG}
  {$DEFINE EXPAT_DEBUG}
{$ENDIF}

//----------------------------------------------------------------------------

{DEFINE XML_UNICODE_WCHAR_T}
{DEFINE XML_LARGE_SIZE}
{DEFINE XML_MIN_SIZE}

//----- PLATFORM DEPENDENT CONFIG --------------------------------------------

{IFDEF WIN32}
  {$I winconfig.inc}
{ENDIF}

//----------------------------------------------------------------------------
{$IFDEF XML_UNICODE_WCHAR_T}
  {$DEFINE XML_UNICODE}
{$ENDIF}

{$IFDEF CPUPOWERPC}
  {$DEFINE EXPAT_CPU_PPC}
{$ENDIF}

{$IFDEF CPUI386}
  {$DEFINE EXPAT_CPU_386}
{$ENDIF}

{$IFDEF CPU386}
  {$DEFINE EXPAT_CPU_386}
{$ENDIF}

{$IFDEF CPUX64}
  {$DEFINE CPU64}
{$ENDIF}

{$IFDEF FPC}
  {$MODE DELPHI}
  {$ASMMODE Intel}
  {$DEFINE SUPPORTS_INLINE}
{$ELSE}
  {$IFDEF CONDITIONALEXPRESSIONS}
    {$IF CompilerVersion >= 17.0}
      {$DEFINE SUPPORTS_INLINE}
    {$IFEND}
    {$IF CompilerVersion < 22.0}
      {$DEFINE SUPPORTS_INLINE}
    {$IFEND}

  {-$DEFINE USE_FASTMM4}

  {$ELSE}
    Delphi Version not supported!!!
  {$ENDIF}
{$ENDIF}

//----------------------------------------------------------------------------
{$IFDEF EXPAT_DEBUG}
  {$DEFINE EXPAT_FULL_DEBUG}
{$ENDIF}

//----------------------------------------------------------------------------
{ SWITCHES CONFIGURATION }
{$IFNDEF FPC}
 {$A-} // Fields alignment OFF
 {$F+} // Far code generation
{$ENDIF}

{$B-} // Complete boolean evaluation
{$V-} // String type checking
{$X+} // Extended syntax

{$IFDEF EXPAT_FULL_DEBUG}
  {$R+} // Range checking
  {$I+} // IO checking
  {$Q+} // Overflow checking

  {$IFNDEF FPC}
    {$O-} // Code Optimization
  {$ENDIF}

  {$D+} // Debug Info ON
  {$Y+} // References Info ON
{$ELSE}
  {$R-} // Range checking
  {$I-} // IO checking
  {$Q-} // OverfLow checking

 { Code Optimization }
 {$IFNDEF FPC}
   {$IFDEF EXPAT_OPTIMIZE}
     {$O+}
   {$ELSE}
     {$O-}
   {$ENDIF}
{$ENDIF}

  {$D-} // Debug Info OFF
  {$Y-} // References Info OFF

{$ENDIF}
