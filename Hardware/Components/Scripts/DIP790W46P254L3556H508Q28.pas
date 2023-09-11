Var
    CurrentSCHLib : ISch_Lib;
    CurrentLib : IPCB_Library;

Function CreateAComponent(Name: String) : IPCB_LibComponent;
Var
    PrimitiveList: TInterfaceList;
    PrimitiveIterator: IPCB_GroupIterator;
    PrimitiveHandle: IPCB_Primitive;
    I:  Integer;

Begin
    // Check if footprint already in library
    Result := CurrentLib.GetComponentByName(Name);
    If Result = Nil Then
    Begin
        // Create New Component
        Result := PCBServer.CreatePCBLibComp;
        Result.Name := Name;
    End
    Else
    Begin
        // Clear existin component
        Try
            // Create List with all primitives on board
            PrimitiveList := TInterfaceList.Create;
            PrimitiveIterator := Result.GroupIterator_Create;
            PrimitiveIterator.AddFilter_ObjectSet(AllObjects);
            PrimitiveHandle := PrimitiveIterator.FirstPCBObject;
            While PrimitiveHandle <> Nil Do
            Begin
                PrimitiveList.Add(PrimitiveHandle);
                PrimitiveHandle := PrimitiveIterator.NextPCBObject;
            End;

            // Delete all primitives
            For I := 0 To PrimitiveList.Count - 1 Do
            Begin
                PrimitiveHandle := PrimitiveList.items[i];
                Result.RemovePCBObject(PrimitiveHandle);
                Result.GraphicallyInvalidate;
            End;

        Finally
            Result.GroupIterator_Destroy(PrimitiveIterator);
            PrimitiveList.Free;
        End;
    End;
End; 

Procedure CreateTHComponentPad(NewPCBLibComp : IPCB_LibComponent, Name : String, HoleType : TExtendedHoleType,
                               HoleSize : Real, HoleLength : Real, Layer : TLayer, X : Real, Y : Real,
                               OffsetX : Real, OffsetY : Real, TopShape : TShape, TopXSize : Real, TopYSize : Real,
                               InnerShape : TShape, InnerXSize : Real, InnerYSize : Real,
                               BottomShape : TShape, BottomXSize : Real, BottomYSize : Real,
                               Rotation: Real, CRRatio : Real, PMExpansion : Real, SMExpansion: Real, Plated : Boolean);
Var
    NewPad                      : IPCB_Pad2;
    PadCache                    : TPadCache;

Begin
    NewPad := PcbServer.PCBObjectFactory(ePadObject, eNoDimension, eCreate_Default);
    NewPad.Mode := ePadMode_LocalStack;
    NewPad.HoleType := HoleType;
    NewPad.HoleSize := MMsToCoord(HoleSize);
    if HoleLength <> 0 then
        NewPad.HoleWidth := MMsToCoord(HoleLength);
    NewPad.TopShape := TopShape;
    if TopShape = eRoundedRectangular then
        NewPad.SetState_StackCRPctOnLayer(eTopLayer, CRRatio);
    if BottomShape = eRoundedRectangular then
        NewPad.SetState_StackCRPctOnLayer(eBottomLayer, CRRatio);
    NewPad.TopXSize := MMsToCoord(TopXSize);
    NewPad.TopYSize := MMsToCoord(TopYSize);
    NewPad.MidShape := InnerShape;
    NewPad.MidXSize := MMsToCoord(InnerXSize);
    NewPad.MidYSize := MMsToCoord(InnerYSize);
    NewPad.BotShape := BottomShape;
    NewPad.BotXSize := MMsToCoord(BottomXSize);
    NewPad.BotYSize := MMsToCoord(BottomYSize);
    NewPad.SetState_XPadOffsetOnLayer(Layer, MMsToCoord(OffsetX));
    NewPad.SetState_YPadOffsetOnLayer(Layer, MMsToCoord(OffsetY));
    NewPad.RotateBy(Rotation);
    NewPad.MoveToXY(MMsToCoord(X), MMsToCoord(Y));
    NewPad.Plated   := Plated;
    NewPad.Name := Name;

    Padcache := NewPad.GetState_Cache;
    if PMExpansion <> 0 then
    Begin
        Padcache.PasteMaskExpansionValid   := eCacheManual;
        Padcache.PasteMaskExpansion        := MMsToCoord(PMExpansion);
    End;
    if SMExpansion <> 0 then
    Begin
        Padcache.SolderMaskExpansionValid  := eCacheManual;
        Padcache.SolderMaskExpansion       := MMsToCoord(SMExpansion);
    End;
    NewPad.SetState_Cache              := Padcache;

    NewPCBLibComp.AddPCBObject(NewPad);
    PCBServer.SendMessageToRobots(NewPCBLibComp.I_ObjectAddress,c_Broadcast,PCBM_BoardRegisteration,NewPad.I_ObjectAddress);
End;

Procedure CreateComponentTrack(NewPCBLibComp : IPCB_LibComponent, X1 : Real, Y1 : Real, X2 : Real, Y2 : Real, Layer : TLayer, LineWidth : Real, IsKeepout : Boolean);
Var
    NewTrack                    : IPCB_Track;

Begin
    NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
    NewTrack.X1 := MMsToCoord(X1);
    NewTrack.Y1 := MMsToCoord(Y1);
    NewTrack.X2 := MMsToCoord(X2);
    NewTrack.Y2 := MMsToCoord(Y2);
    NewTrack.Layer := Layer;
    NewTrack.Width := MMsToCoord(LineWidth);
    NewTrack.IsKeepout := IsKeepout;
    NewPCBLibComp.AddPCBObject(NewTrack);
    PCBServer.SendMessageToRobots(NewPCBLibComp.I_ObjectAddress,c_Broadcast,PCBM_BoardRegisteration,NewTrack.I_ObjectAddress);
End;

Procedure CreateComponentArc(NewPCBLibComp : IPCB_LibComponent, CenterX : Real, CenterY : Real, Radius : Real, StartAngle : Real, EndAngle : Real, Layer : TLayer, LineWidth : Real, IsKeepout : Boolean);
Var
    NewArc                      : IPCB_Arc;

Begin
    NewArc := PCBServer.PCBObjectFactory(eArcObject,eNoDimension,eCreate_Default);
    NewArc.XCenter := MMsToCoord(CenterX);
    NewArc.YCenter := MMsToCoord(CenterY);
    NewArc.Radius := MMsToCoord(Radius);
    NewArc.StartAngle := StartAngle;
    NewArc.EndAngle := EndAngle;
    NewArc.Layer := Layer;
    NewArc.LineWidth := MMsToCoord(LineWidth);
    NewArc.IsKeepout := IsKeepout;
    NewPCBLibComp.AddPCBObject(NewArc);
    PCBServer.SendMessageToRobots(NewPCBLibComp.I_ObjectAddress,c_Broadcast,PCBM_BoardRegisteration,NewArc.I_ObjectAddress);
End;

Function ReadStringFromIniFile(Section: String, Name: String, FilePath: String, IfEmpty: String) : String;
Var
    IniFile                     : TIniFile;

Begin
    result := IfEmpty;
    If FileExists(FilePath) Then
    Begin
        Try
            IniFile := TIniFile.Create(FilePath);

            Result := IniFile.ReadString(Section, Name, IfEmpty);
        Finally
            Inifile.Free;
        End;
    End;
End;

Procedure EnableMechanicalLayers(Zero : Integer);
Var
    Board                       : IPCB_Board;
    MajorADVersion              : Integer;

Begin
End;

Procedure DeleteFootprint(Name : String);
var
    CurrentLib      : IPCB_Library;
    del_list        : TInterfaceList;
    I               :  Integer;
    S_temp          : TString;
    Footprint       : IPCB_LibComponent;
    FootprintIterator : Integer;

Begin
    // ShowMessage('Script running');
    CurrentLib       := PCBServer.GetCurrentPCBLibrary;
    If CurrentLib = Nil Then
    Begin
        ShowMessage('This is not a PCB library document');
        Exit;
    End;

    // store selected footprints in a TInterfacelist that are to be deleted later...
    del_list := TInterfaceList.Create;

    // For each page of library Is a footprint
    FootprintIterator := CurrentLib.LibraryIterator_Create;
    FootprintIterator.SetState_FilterAll;

    // Within each page, fetch primitives of the footprint
    // A footprint Is a IPCB_LibComponent inherited from
    // IPCB_Group which Is a container object storing primitives.
    Footprint := FootprintIterator.FirstPCBObject; // IPCB_LibComponent

    while (Footprint <> Nil) Do
    begin
        S_temp :=Footprint.Name;

        // check for specific footprint, to delete them before (0=equal string)
        If Not (CompareText(S_temp, Name)) Then
        begin
            del_list.Add(Footprint);
            //ShowMessage('selected footprint ' + Footprint.Name);
        end;
        Footprint := FootprintIterator.NextPCBObject;
    end;

    CurrentLib.LibraryIterator_Destroy(FootprintIterator);

    Try
        PCBServer.PreProcess;
        For I := 0 To del_list.Count - 1 Do
        Begin
            Footprint := del_list.items[i];
            // ShowMessage('deleted footprint ' + Footprint.Name);
            CurrentLib.RemoveComponent(Footprint);
        End;
    Finally
        PCBServer.PostProcess;
        del_list.Free;
    End;
End;

Procedure CreateComponentDIP790W46P254L3556H508Q28(Zero : integer);
Var
    NewPCBLibComp               : IPCB_LibComponent;
    NewPad                      : IPCB_Pad2;
    NewRegion                   : IPCB_Region;
    NewContour                  : IPCB_Contour;
    STEPmodel                   : IPCB_ComponentBody;
    Model                       : IPCB_Model;
    TextObj                     : IPCB_Text;

Begin
    Try
        PCBServer.PreProcess;

        EnableMechanicalLayers(0);

        NewPcbLibComp := CreateAComponent('DIP790W46P254L3556H508Q28');
        NewPcbLibComp.Name := 'DIP790W46P254L3556H508Q28';
        NewPCBLibComp.Description := 'DIP, 7.90 mm lead span, 2.54 mm pitch; 28 pin, 35.56 mm L X 7.50 mm W X 5.08 mm H body';
        NewPCBLibComp.Height := MMsToCoord(5.08);

        CreateTHComponentPad(NewPCBLibComp, '1', eRoundHole, 0.85, 0, eBottomLayer, -16.51, -3.95, 0, 0, eRectangular, 1.28, 1.28, eRounded, 1.28, 1.28, eRectangular, 1.28, 1.28, 270, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '2', eRoundHole, 0.85, 0, eBottomLayer, -13.97, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '3', eRoundHole, 0.85, 0, eBottomLayer, -11.43, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '4', eRoundHole, 0.85, 0, eBottomLayer, -8.89, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '5', eRoundHole, 0.85, 0, eBottomLayer, -6.35, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '6', eRoundHole, 0.85, 0, eBottomLayer, -3.81, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '7', eRoundHole, 0.85, 0, eBottomLayer, -1.27, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '8', eRoundHole, 0.85, 0, eBottomLayer, 1.27, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '9', eRoundHole, 0.85, 0, eBottomLayer, 3.81, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '10', eRoundHole, 0.85, 0, eBottomLayer, 6.35, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '11', eRoundHole, 0.85, 0, eBottomLayer, 8.89, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '12', eRoundHole, 0.85, 0, eBottomLayer, 11.43, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '13', eRoundHole, 0.85, 0, eBottomLayer, 13.97, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '14', eRoundHole, 0.85, 0, eBottomLayer, 16.51, -3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '15', eRoundHole, 0.85, 0, eBottomLayer, 16.51, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '16', eRoundHole, 0.85, 0, eBottomLayer, 13.97, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '17', eRoundHole, 0.85, 0, eBottomLayer, 11.43, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '18', eRoundHole, 0.85, 0, eBottomLayer, 8.89, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '19', eRoundHole, 0.85, 0, eBottomLayer, 6.35, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '20', eRoundHole, 0.85, 0, eBottomLayer, 3.81, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '21', eRoundHole, 0.85, 0, eBottomLayer, 1.27, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '22', eRoundHole, 0.85, 0, eBottomLayer, -1.27, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '23', eRoundHole, 0.85, 0, eBottomLayer, -3.81, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '24', eRoundHole, 0.85, 0, eBottomLayer, -6.35, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '25', eRoundHole, 0.85, 0, eBottomLayer, -8.89, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '26', eRoundHole, 0.85, 0, eBottomLayer, -11.43, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '27', eRoundHole, 0.85, 0, eBottomLayer, -13.97, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);
        CreateTHComponentPad(NewPCBLibComp, '28', eRoundHole, 0.85, 0, eBottomLayer, -16.51, 3.95, 0, 0, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, eRounded, 1.28, 1.28, 0, 0, -1.28, 0, True);

        CreateComponentTrack(NewPCBLibComp, -16.79, -3.76, -16.23, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -16.23, -3.76, -16.23, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -16.23, -4.14, -16.79, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -16.79, -4.14, -16.79, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -14.25, -3.76, -13.69, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -13.69, -3.76, -13.69, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -13.69, -4.14, -14.25, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -14.25, -4.14, -14.25, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.71, -3.76, -11.15, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.15, -3.76, -11.15, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.15, -4.14, -11.71, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.71, -4.14, -11.71, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -9.17, -3.76, -8.61, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -8.61, -3.76, -8.61, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -8.61, -4.14, -9.17, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -9.17, -4.14, -9.17, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.63, -3.76, -6.07, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.07, -3.76, -6.07, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.07, -4.14, -6.63, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.63, -4.14, -6.63, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -4.09, -3.76, -3.53, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -3.53, -3.76, -3.53, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -3.53, -4.14, -4.09, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -4.09, -4.14, -4.09, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -1.55, -3.76, -0.99, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -0.99, -3.76, -0.99, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -0.99, -4.14, -1.55, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -1.55, -4.14, -1.55, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 0.99, -3.76, 1.55, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 1.55, -3.76, 1.55, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 1.55, -4.14, 0.99, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 0.99, -4.14, 0.99, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 3.53, -3.76, 4.09, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 4.09, -3.76, 4.09, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 4.09, -4.14, 3.53, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 3.53, -4.14, 3.53, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.07, -3.76, 6.63, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.63, -3.76, 6.63, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.63, -4.14, 6.07, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.07, -4.14, 6.07, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 8.61, -3.76, 9.17, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 9.17, -3.76, 9.17, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 9.17, -4.14, 8.61, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 8.61, -4.14, 8.61, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.15, -3.76, 11.71, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.71, -3.76, 11.71, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.71, -4.14, 11.15, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.15, -4.14, 11.15, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 13.69, -3.76, 14.25, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 14.25, -3.76, 14.25, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 14.25, -4.14, 13.69, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 13.69, -4.14, 13.69, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.23, -3.76, 16.79, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.79, -3.76, 16.79, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.79, -4.14, 16.23, -4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.23, -4.14, 16.23, -3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.79, 3.76, 16.23, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.23, 3.76, 16.23, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.23, 4.14, 16.79, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 16.79, 4.14, 16.79, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 14.25, 3.76, 13.69, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 13.69, 3.76, 13.69, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 13.69, 4.14, 14.25, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 14.25, 4.14, 14.25, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.71, 3.76, 11.15, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.15, 3.76, 11.15, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.15, 4.14, 11.71, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 11.71, 4.14, 11.71, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 9.17, 3.76, 8.61, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 8.61, 3.76, 8.61, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 8.61, 4.14, 9.17, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 9.17, 4.14, 9.17, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.63, 3.76, 6.07, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.07, 3.76, 6.07, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.07, 4.14, 6.63, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 6.63, 4.14, 6.63, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 4.09, 3.76, 3.53, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 3.53, 3.76, 3.53, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 3.53, 4.14, 4.09, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 4.09, 4.14, 4.09, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 1.55, 3.76, 0.99, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 0.99, 3.76, 0.99, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 0.99, 4.14, 1.55, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 1.55, 4.14, 1.55, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -0.99, 3.76, -1.55, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -1.55, 3.76, -1.55, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -1.55, 4.14, -0.99, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -0.99, 4.14, -0.99, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -3.53, 3.76, -4.09, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -4.09, 3.76, -4.09, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -4.09, 4.14, -3.53, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -3.53, 4.14, -3.53, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.07, 3.76, -6.63, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.63, 3.76, -6.63, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.63, 4.14, -6.07, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -6.07, 4.14, -6.07, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -8.61, 3.76, -9.17, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -9.17, 3.76, -9.17, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -9.17, 4.14, -8.61, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -8.61, 4.14, -8.61, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.15, 3.76, -11.71, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.71, 3.76, -11.71, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.71, 4.14, -11.15, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -11.15, 4.14, -11.15, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -13.69, 3.76, -14.25, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -14.25, 3.76, -14.25, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -14.25, 4.14, -13.69, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -13.69, 4.14, -13.69, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -16.23, 3.76, -16.79, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -16.79, 3.76, -16.79, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -16.79, 4.14, -16.23, 4.14, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -16.23, 4.14, -16.23, 3.76, eMechanical5, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -17.78, -3.75, -17.78, 3.75, eMechanical7, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -17.78, 3.75, 17.78, 3.75, eMechanical7, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 17.78, 3.75, 17.78, -3.75, eMechanical7, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, 17.78, -3.75, -17.78, -3.75, eMechanical7, 0.025, False);
        CreateComponentTrack(NewPCBLibComp, -17.78, -3.75, -17.78, 3.75, eMechanical3, 0.12, False);
        CreateComponentTrack(NewPCBLibComp, -17.78, 3.75, 17.78, 3.75, eMechanical3, 0.12, False);
        CreateComponentTrack(NewPCBLibComp, 17.78, 3.75, 17.78, -3.75, eMechanical3, 0.12, False);
        CreateComponentTrack(NewPCBLibComp, 17.78, -3.75, -17.78, -3.75, eMechanical3, 0.12, False);
        CreateComponentArc(NewPCBLibComp, 0, 0, 0.25, 0, 360, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, 0, 0.35, 0, -0.35, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, -0.35, 0, 0.35, 0, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, 17.375, -3.75, 17.78, -3.75, eTopOverlay, 0.15, False);
        CreateComponentTrack(NewPCBLibComp, 17.78, -3.75, 17.78, 3.75, eTopOverlay, 0.15, False);
        CreateComponentTrack(NewPCBLibComp, 17.78, 3.75, 17.375, 3.75, eTopOverlay, 0.15, False);
        CreateComponentTrack(NewPCBLibComp, -17.375, -3.75, -17.78, -3.75, eTopOverlay, 0.15, False);
        CreateComponentTrack(NewPCBLibComp, -17.78, -3.75, -17.78, 3.75, eTopOverlay, 0.15, False);
        CreateComponentTrack(NewPCBLibComp, -17.78, 3.75, -17.375, 3.75, eTopOverlay, 0.15, False);
        CreateComponentTrack(NewPCBLibComp, 18.03, -4, 18.03, 4, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, 18.03, 4, 17.4, 4, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, 17.4, 4, 17.4, 4.84, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, 17.4, 4.84, -17.4, 4.84, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, -17.4, 4.84, -17.4, 4, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, -17.4, 4, -18.03, 4, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, -18.03, 4, -18.03, -4, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, -18.03, -4, -17.4, -4, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, -17.4, -4, -17.4, -4.84, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, -17.4, -4.84, 17.4, -4.84, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, 17.4, -4.84, 17.4, -4, eMechanical7, 0.05, False);
        CreateComponentTrack(NewPCBLibComp, 17.4, -4, 18.03, -4, eMechanical7, 0.05, False);

        STEPmodel := PcbServer.PCBObjectFactory(eComponentBodyObject, eNoDimension, eCreate_Default);
        Model := STEPmodel.ModelFactory_FromFilename('C:\Users\Korisnik\Desktop\DynoControl\Hardware\Components\Scripts\DIP790W46P254L3556H508Q28.STEP', false);
        STEPModel.Layer := eMechanical1;
        STEPmodel.Model := Model;
        STEPmodel.SetState_Identifier('DIP790W46P254L3556H508Q28');
        NewPCBLibComp.AddPCBObject(STEPmodel);

        CurrentLib.RegisterComponent(NewPCBLibComp);
        CurrentLib.CurrentComponent := NewPcbLibComp;
    Finally
        PCBServer.PostProcess;
    End;

    CurrentLib.Board.ViewManager_UpdateLayerTabs;
    CurrentLib.Board.ViewManager_FullUpdate;
    Client.SendMessage('PCB:Zoom', 'Action=All' , 255, Client.CurrentView)
End;

Procedure CreateAPCBLibrary(Zero : integer);
Var
    View     : IServerDocumentView;
    Document : IServerDocument;
    TempPCBLibComp : IPCB_LibComponent;

Begin
    If PCBServer = Nil Then
    Begin
        ShowMessage('No PCBServer present. This script inserts a footprint into an existing PCB Library that has the current focus.');
        Exit;
    End;

    CurrentLib := PcbServer.GetCurrentPCBLibrary;
    If CurrentLib = Nil Then
    Begin
        ShowMessage('You must have focus on a PCB Library in order for this script to run.');
        Exit;
    End;

    View := Client.GetCurrentView;
    Document := View.OwnerDocument;
    Document.Modified := True;

    // Create And focus a temporary component While we delete items (BugCrunch #10165)
    TempPCBLibComp := PCBServer.CreatePCBLibComp;
    TempPcbLibComp.Name := '___TemporaryComponent___';
    CurrentLib.RegisterComponent(TempPCBLibComp);
    CurrentLib.CurrentComponent := TempPcbLibComp;
    CurrentLib.Board.ViewManager_FullUpdate;

    CreateComponentDIP790W46P254L3556H508Q28(0);

    // Delete Temporary Footprint And re-focus
    CurrentLib.RemoveComponent(TempPCBLibComp);
    CurrentLib.Board.ViewManager_UpdateLayerTabs;
    CurrentLib.Board.ViewManager_FullUpdate;
    Client.SendMessage('PCB:Zoom', 'Action=All', 255, Client.CurrentView);

    DeleteFootprint('PCBCOMPONENT_1');  // Randy Added - Delete PCBCOMPONENT_1

End;

Procedure CreateALibrary;
Begin
    Screen.Cursor := crHourGlass;

    CreateAPCBLibrary(0);

    Screen.Cursor := crArrow;
End;

End.
