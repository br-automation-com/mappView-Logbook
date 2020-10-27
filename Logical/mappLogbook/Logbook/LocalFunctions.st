// --------------------------------------------------------------------------------------------------------------------
// Gets severity from EventId (bits 31-30)
FUNCTION GetSeverity
	IF ArEventLogIsError(EventID := EventID) THEN
		GetSeverity := arEVENTLOG_SEVERITY_ERROR;
	ELSIF ArEventLogIsWarning(EventID := EventID) THEN
		GetSeverity := arEVENTLOG_SEVERITY_WARNING;
	ELSIF ArEventLogIsInformation(EventID := EventID) THEN
		GetSeverity := arEVENTLOG_SEVERITY_INFO;
	ELSIF ArEventLogIsSuccess(EventID := EventID) THEN
		GetSeverity := arEVENTLOG_SEVERITY_SUCCESS;
	END_IF
END_FUNCTION

// --------------------------------------------------------------------------------------------------------------------
// Gets code from EventId (bits 15-0)
FUNCTION GetCode
	GetCode := DINT_TO_UINT(EventID);
END_FUNCTION

// --------------------------------------------------------------------------------------------------------------------
// Gets facility from EventId (bits 27-16)
FUNCTION GetFacility
	GetFacility := DINT_TO_UINT(SHR(EventID, 16) AND 16#0FFF);
END_FUNCTION

// --------------------------------------------------------------------------------------------------------------------
// Insert new entry
FUNCTION InsertEntry
	// Compare second
	FOR idx:=1 TO DAT.EntriesTotal DO
		IF Sorting = sortingASC THEN
			IF DTsec < DAT.Entries.DTsec[idx] THEN
				EXIT;
			ELSIF DTsec = DAT.Entries.DTsec[idx] THEN
				IF DTmsec < DAT.Entries.DTmsec[idx] THEN
					EXIT;
				END_IF
			END_IF
		ELSE
			IF DTsec > DAT.Entries.DTsec[idx] THEN
				EXIT;
			ELSIF DTsec = DAT.Entries.DTsec[idx] THEN
				IF DTmsec > DAT.Entries.DTmsec[idx] THEN
					EXIT;
				END_IF
			END_IF
		END_IF
	END_FOR;

			
	// Move all data entrys backwards and fill in new entry
	DAT.EntriesTotal := DAT.EntriesTotal + 1;	
	IF idx <= DAT.EntriesTotal AND idx < LOGBOOK_ENTRIES_TOTAL THEN
		brsmemmove(ADR(DAT.Entries.Code[idx+1]),ADR(DAT.Entries.Code[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.Code[1]));
		brsmemmove(ADR(DAT.Entries.Timestamp[idx+1]),ADR(DAT.Entries.Timestamp[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.Timestamp[1]));
		brsmemmove(ADR(DAT.Entries.DTsec[idx+1]),ADR(DAT.Entries.DTsec[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.DTsec[1]));
		brsmemmove(ADR(DAT.Entries.DTmsec[idx+1]),ADR(DAT.Entries.DTmsec[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.DTmsec[1]));
		brsmemmove(ADR(DAT.Entries.ErrorNo[idx+1]),ADR(DAT.Entries.ErrorNo[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.ErrorNo[1]));
		brsmemmove(ADR(DAT.Entries.ErrorText[idx+1]),ADR(DAT.Entries.ErrorText[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.ErrorText[1]));
		brsmemmove(ADR(DAT.Entries.EventID[idx+1]),ADR(DAT.Entries.EventID[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.EventID[1]));
		brsmemmove(ADR(DAT.Entries.FacilityCode[idx+1]),ADR(DAT.Entries.FacilityCode[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.FacilityCode[1]));
		brsmemmove(ADR(DAT.Entries.FacilityText[idx+1]),ADR(DAT.Entries.FacilityText[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.FacilityText[1]));
		brsmemmove(ADR(DAT.Entries.Severity[idx+1]),ADR(DAT.Entries.Severity[idx]), (DAT.EntriesTotal - idx) * SIZEOF(DAT.Entries.Severity[1]));
	END_IF

	InsertEntry := idx;
END_FUNCTION

// --------------------------------------------------------------------------------------------------------------------
// Normalize 2 digit date and time values
FUNCTION NormalizeDateTime
	tmpSTR2 := addSTR;
	IF(value < 10) THEN
		brsstrcat(ADR(tmpSTR2), ADR('0'));
	END_IF
	brsitoa(value, ADR(tmpSTR1));
	brsstrcat(ADR(tmpSTR2), ADR(tmpSTR1));
	brsstrcat(target, ADR(tmpSTR2));
	NormalizeDateTime := TRUE;
END_FUNCTION

// --------------------------------------------------------------------------------------------------------------------
// Working status																						
FUNCTION WorkingStatus
	animation := animation+1;
	
	IF (animation = 80) THEN
		animation := 0;
	END_IF
	
	brsstrcpy(target, text);
	CASE(animation) OF
		0..19	: brsstrcat(target, ADR('/'));
		20..39	: brsstrcat(target, ADR('-'));
		40..59	: brsstrcat(target, ADR('\'));
		60..79	: brsstrcat(target, ADR('|'));
	END_CASE;
	WorkingStatus := animation;
END_FUNCTION

// --------------------------------------------------------------------------------------------------------------------
// Is second string in first string																		
FUNCTION IsInstr
	IF (brsstrlen(string1) > brsstrlen(string2)) THEN
		FOR idx:=0 TO brsstrlen(string1) - brsstrlen(string2) DO
			IF (brsmemcmp(string1 + idx, string2, brsstrlen(string2)) = 0) THEN
				IsInstr := TRUE;
				EXIT;
			END_IF
		END_FOR;
	END_IF
END_FUNCTION