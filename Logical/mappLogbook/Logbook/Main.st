// --------------------------------------------------------------------------------------------------------------------
// Logbook Task
// This task reads the PLC logbook and creates the data structure to display it in mappView
// --------------------------------------------------------------------------------------------------------------------
PROGRAM _INIT
	// Set time range to all on startup
	DTGetTime_0.enable := TRUE;
	DTGetTime_0();
	gLogbook.PAR.FilterDateStart := STRING_TO_DATE('D#1999-12-31');
	gLogbook.PAR.FilterDateEnd := DT_TO_DATE(DTGetTime_0.DT1);
	
	// Read data after reboot
	gLogbook.CMD.Refresh := TRUE;
END_PROGRAM

PROGRAM _CYCLIC
	// Abort current update run
	IF EDGENEG(gLogbook.CMD.Refresh) THEN
		state := enumWait;
	END_IF
	// Run task multiple times to speed up process
	FOR executions:=1 TO LOGBOOK_EXECUTIONS DO
		// --------------------------------------------------------------------------------------------------------------------
		// Logbook state machine
		// --------------------------------------------------------------------------------------------------------------------
		CASE state OF
			// --------------------------------------------------------------------------------------------------------------------
			// Wait for new command
			// --------------------------------------------------------------------------------------------------------------------
			enumWait:
				// --------------------------------------------------------------------------------------------------------------------
				// Open logbook
				IF gLogbook.CMD.Refresh THEN
					// Erase old data
					brsmemset(ADR(Facility), 0, SIZEOF(Facility));
					brsmemset(ADR(gLogbook.DAT), 0, SIZEOF(gLogbook.DAT));
					gLogbook.Status := ERR_FUB_BUSY;
					state := enumOpen;
				END_IF
			
				// Reset function blocks
				ArEventLogGetIdent_0(Execute := FALSE);
				ArEventLogGetLatestRecordID_0(Execute := FALSE);
				ArEventLogGetPreviousRecordID_0(Execute := FALSE);
				ArEventLogRead_0(Execute := FALSE);
				ArEventLogReadErrorNumber_0(Execute := FALSE);
				ArEventLogReadDescription_0(Execute := FALSE);
				ArEventLogReadAddData_0(Execute := FALSE);
				
				// Hide unused table rows
				brsitoa(gLogbook.DAT.EntriesTotal, ADR(tmpSTR));
				gLogbook.PAR.TableConfig := '{"specRows":[{"from":';
				brsstrcat(ADR(gLogbook.PAR.TableConfig), ADR(tmpSTR));
				brsstrcat(ADR(gLogbook.PAR.TableConfig), ADR(', "to":'));
				brsitoa(LOGBOOK_ENTRIES_TOTAL, ADR(tmpSTR));
				brsstrcat(ADR(gLogbook.PAR.TableConfig), ADR(tmpSTR));
				brsstrcat(ADR(gLogbook.PAR.TableConfig), ADR(', "visible":false}]}'));	
				
				// Get current date and show status
				DTGetTime_0.enable := TRUE;
				DTGetTime_0();
				gLogbook.PAR.DateNow := DTGetTime_0.DT1;
				gLogbook.CMD.ResetError := FALSE;
				gLogbook.StatusText := 'Waiting...';
				EXIT;
				// --------------------------------------------------------------------------------------------------------------------
				// Open logbook facility
				// --------------------------------------------------------------------------------------------------------------------
			enumOpen:
				// Last facility reached 
				IF Facility.CntFacility > LOGBOOK_FACILITIES_TOTAL THEN				
					Facility.CntFacility := 0;
					state := enumLatest;
					EXIT;
				END_IF
				ArEventLogGetIdent_0.Execute := gLogbook.CMD.Refresh;
				ArEventLogGetIdent_0.Name := FACILITY_NAMES[Facility.CntFacility];
				ArEventLogGetIdent_0();
	
				// Success
				IF (ArEventLogGetIdent_0.Done AND ArEventLogGetIdent_0.StatusID = ERR_OK) OR ArEventLogGetIdent_0.StatusID = arEVENTLOG_ERR_LOGBOOK_NOT_FOUND THEN
					Facility.Ident[Facility.CntFacility] := ArEventLogGetIdent_0.Ident;
					Facility.CntFacility := Facility.CntFacility + 1;					
					ArEventLogGetIdent_0(Execute := FALSE);
					// Error
				ELSIF ArEventLogGetIdent_0.Error THEN
					gLogbook.ERR.State := state;
					gLogbook.Status := ArEventLogGetIdent_0.StatusID;
					state := enumError;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Read latest entry
				// --------------------------------------------------------------------------------------------------------------------
			enumLatest:
				ArEventLogGetLatestRecordID_0.Execute := gLogbook.CMD.Refresh;
				ArEventLogGetLatestRecordID_0.Ident := Facility.Ident[Facility.CntFacility];
				ArEventLogGetLatestRecordID_0();

				// Success
				IF ArEventLogGetLatestRecordID_0.Done AND ArEventLogGetLatestRecordID_0.StatusID = ERR_OK THEN
					Facility.RecordID[Facility.CntFacility] := ArEventLogGetLatestRecordID_0.RecordID;
					state := enumDetails1;
					// Error
				ELSIF ArEventLogGetLatestRecordID_0.Error THEN
					gLogbook.ERR.State := state;
					gLogbook.Status := ArEventLogGetLatestRecordID_0.StatusID;
					state := enumError;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Read next entry
				// --------------------------------------------------------------------------------------------------------------------
			enumNext:
				animation := WorkingStatus(ADR(gLogbook.StatusText), ADR('reading entries...'), animation);
				ArEventLogGetPreviousRecordID_0.Execute := gLogbook.CMD.Refresh;
				ArEventLogGetPreviousRecordID_0.Ident := Facility.Ident[Facility.CntFacility];
				ArEventLogGetPreviousRecordID_0.RecordID := Facility.RecordID[Facility.CntFacility];
				ArEventLogGetPreviousRecordID_0();

				// Success
				IF ArEventLogGetPreviousRecordID_0.Done AND ArEventLogGetPreviousRecordID_0.StatusID = ERR_OK THEN
					Facility.RecordID[Facility.CntFacility] := ArEventLogGetPreviousRecordID_0.PrevRecordID;
					state := enumDetails1;
					// Error
				ELSIF ArEventLogGetPreviousRecordID_0.Error THEN
					gLogbook.ERR.State := state;
					gLogbook.Status := ArEventLogGetPreviousRecordID_0.StatusID;
					state := enumError;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Read event id and time stamp
				// --------------------------------------------------------------------------------------------------------------------
			enumDetails1:
				ArEventLogRead_0.Execute := gLogbook.CMD.Refresh;
				ArEventLogRead_0.Ident := Facility.Ident[Facility.CntFacility];
				ArEventLogRead_0.RecordID := Facility.RecordID[Facility.CntFacility];
				ArEventLogRead_0();

				// Success
				IF ArEventLogRead_0.Done AND (ArEventLogRead_0.StatusID = ERR_OK OR ArEventLogRead_0.StatusID = arEVENTLOG_WRN_NO_EVENTID) THEN
					state := enumDetails2;
					// Error
				ELSIF ArEventLogRead_0.Error THEN
					gLogbook.ERR.State := state;
					gLogbook.Status := ArEventLogRead_0.StatusID;
					state := enumError;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Read error no
				// --------------------------------------------------------------------------------------------------------------------
			enumDetails2:
				ArEventLogReadErrorNumber_0.Execute := gLogbook.CMD.Refresh;
				ArEventLogReadErrorNumber_0.Ident := Facility.Ident[Facility.CntFacility];
				ArEventLogReadErrorNumber_0.RecordID := Facility.RecordID[Facility.CntFacility];
				ArEventLogReadErrorNumber_0();

				// Success
				IF (ArEventLogReadErrorNumber_0.Done AND ArEventLogReadErrorNumber_0.StatusID = ERR_OK) OR ArEventLogReadErrorNumber_0.StatusID = arEVENTLOG_ERR_NO_ERRORNUMBER THEN
					state := enumDetails3;
					// Error
				ELSIF ArEventLogReadErrorNumber_0.Error THEN
					gLogbook.ERR.State := state;
					gLogbook.Status := ArEventLogReadErrorNumber_0.StatusID;
					state := enumError;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Read error description
				// --------------------------------------------------------------------------------------------------------------------
			enumDetails3:
				ArEventLogReadDescription_0.Execute := gLogbook.CMD.Refresh;
				ArEventLogReadDescription_0.Ident := Facility.Ident[Facility.CntFacility];
				ArEventLogReadDescription_0.RecordID := Facility.RecordID[Facility.CntFacility];
				ArEventLogReadDescription_0.TextBuffer := ADR(ErrorText);
				ArEventLogReadDescription_0.TextBufferSize := SIZEOF(ErrorText);
				ArEventLogReadDescription_0();

				// Success
				IF (ArEventLogReadDescription_0.Done AND (ArEventLogReadDescription_0.StatusID = ERR_OK OR ArEventLogReadDescription_0.StatusID = arEVENTLOG_WRN_NO_EVENTID)) OR ArEventLogReadDescription_0.StatusID = arEVENTLOG_ERR_NO_DESCRIPTION THEN
					state := enumDetails4;
					// Error
				ELSIF ArEventLogReadDescription_0.Error THEN
					gLogbook.ERR.State := state;
					gLogbook.Status := ArEventLogReadDescription_0.StatusID;
					state := enumError;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Read additional information
				// --------------------------------------------------------------------------------------------------------------------
			enumDetails4:
				// Skip if no additional data is available
				IF ArEventLogRead_0.AddDataSize > 0 THEN
					// Read additional data
					ArEventLogReadAddData_0.Execute := gLogbook.CMD.Refresh;
					ArEventLogReadAddData_0.Ident := Facility.Ident[Facility.CntFacility];
					ArEventLogReadAddData_0.RecordID := Facility.RecordID[Facility.CntFacility];
					ArEventLogReadAddData_0.AddData := ADR(AddData);
					// Limit buffer to max size
					IF ArEventLogRead_0.AddDataSize < SIZEOF(AddData) THEN
						ArEventLogReadAddData_0.BytesToRead := ArEventLogRead_0.AddDataSize;
					ELSE
						ArEventLogReadAddData_0.BytesToRead := SIZEOF(AddData);
					END_IF
					ArEventLogReadAddData_0();
	
					// Success
					IF (ArEventLogReadAddData_0.Done AND ArEventLogReadAddData_0.StatusID = ERR_OK) OR ArEventLogReadAddData_0.StatusID = arEVENTLOG_INF_SIZE THEN
						// Enter standard text if additional does not fit
						IF ArEventLogReadAddData_0.StatusID = arEVENTLOG_INF_SIZE THEN
							brsstrcat(ADR(ErrorText), ADR('\n >>> '));
							brsstrcat(ADR(ErrorText), ADR('Additional buffer is too small'));
						ELSE
							// Make sure string is readable
							IF brsstrcmp(ADR(AddData), ADR('')) <> 0 AND ArEventLogRead_0.AddDataFormat = arEVENTLOG_ADDFORMAT_TEXT THEN
								brsstrcat(ADR(ErrorText), ADR('\n >>> '));
								// Limit additional text to max size
								IF ArEventLogReadAddData_0.AddDataSize < SIZEOF(ErrorText) - brsstrlen(ADR(ErrorText)) THEN		
									brsstrcat(ADR(ErrorText), ADR(AddData));
								ELSE
									brsmemcpy(ADR(ErrorText) + brsstrlen(ADR(ErrorText)), ADR(AddData), SIZEOF(ErrorText) - brsstrlen(ADR(ErrorText)));
								END_IF
							END_IF
						END_IF
						state := enumFilter;
					// Error
					ELSIF ArEventLogReadDescription_0.Error THEN
						gLogbook.ERR.State := state;
						gLogbook.Status := ArEventLogReadAddData_0.StatusID;
						state := enumError;
					END_IF
				ELSE
					state := enumFilter;
				END_IF				
				// --------------------------------------------------------------------------------------------------------------------
				// Apply filter settings
				// --------------------------------------------------------------------------------------------------------------------
			enumFilter:
				// --------------------------------------------------------------------------------------------------------------------
				// Filters
				cntFilterNo := 0;
				cntFilterText := 0;
				cntFilterFacility := 0;
				cntFilterSeverity := 0;
				cntFilterDate := 0;
				// --------------------------------------------------------------------------------------------------------------------
				// Check if facility should be read
				IF  gLogbook.PAR.FilterFacility[Facility.CntFacility] THEN
					cntFilterFacility := cntFilterFacility + 1;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Check if error text matches search string
				IF gLogbook.PAR.FilterErrorText = '' OR IsInstr(ADR(ErrorText), ADR(gLogbook.PAR.FilterErrorText)) THEN
					cntFilterText := cntFilterText + 1;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Make sure error number matches filter
				IF gLogbook.PAR.FilterErrorNo = 0 OR gLogbook.PAR.FilterErrorNo = ArEventLogReadErrorNumber_0.ErrorNumber THEN
					cntFilterNo := cntFilterNo + 1;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Check severity filter settings
				IF ArEventLogRead_0.EventID <> 0 THEN
					gLogbook.DAT.CntSeverity[GetSeverity(EventID := ArEventLogRead_0.EventID)] := gLogbook.DAT.CntSeverity[GetSeverity(EventID := ArEventLogRead_0.EventID)] + 1;
					IF gLogbook.PAR.FilterSeverity[GetSeverity(EventID := ArEventLogRead_0.EventID)] THEN
						cntFilterSeverity := cntFilterSeverity + 1;
					END_IF
				ELSE
					gLogbook.DAT.CntSeverity[ArEventLogReadErrorNumber_0.Severity] := gLogbook.DAT.CntSeverity[ArEventLogReadErrorNumber_0.Severity] + 1;
					IF gLogbook.PAR.FilterSeverity[ArEventLogReadErrorNumber_0.Severity] THEN
						cntFilterSeverity := cntFilterSeverity + 1;
					END_IF
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Check date range
				tmpSTR:= DT_TO_STRING(DATE_TO_DT(gLogbook.PAR.FilterDateStart));
				brsmemcpy(ADR(tmpSTR)+13, ADR('-00:00:00'), 9);
				TimeStart := STRING_TO_DT(tmpSTR);
				tmpSTR:= DT_TO_STRING(DATE_TO_DT(gLogbook.PAR.FilterDateEnd));
				brsmemcpy(ADR(tmpSTR)+13, ADR('-23:59:59'), 9);
				TimeEnd := STRING_TO_DT(tmpSTR);
				IF ArEventLogRead_0.TimeStamp.sec >= DT_TO_UDINT(TimeStart) AND ArEventLogRead_0.TimeStamp.sec <= DT_TO_UDINT(TimeEnd) THEN
					cntFilterDate := cntFilterDate + 1;
				END_IF
				// --------------------------------------------------------------------------------------------------------------------
				// Count facility entries
				gLogbook.DAT.CntFacility[Facility.CntFacility] := gLogbook.DAT.CntFacility[Facility.CntFacility] +  1;
			
				// --------------------------------------------------------------------------------------------------------------------
				// Transfer data
				IF cntFilterNo > 0 AND cntFilterText > 0 AND cntFilterFacility > 0 AND cntFilterSeverity > 0 AND cntFilterDate > 0 AND gLogbook.DAT.EntriesTotal < LOGBOOK_ENTRIES_TOTAL THEN
					// --------------------------------------------------------------------------------------------------------------------
					// Find new place for entry
					idx := InsertEntry(ADR(gLogbook.DAT), ArEventLogRead_0.TimeStamp.sec, UDINT_TO_UINT(ArEventLogRead_0.TimeStamp.nsec/1000000), gLogbook.PAR.Sorting);
					// Store date and time
					gLogbook.DAT.Entries.DTsec[idx] := ArEventLogRead_0.TimeStamp.sec;
					gLogbook.DAT.Entries.DTmsec[idx] := UDINT_TO_UINT(ArEventLogRead_0.TimeStamp.nsec/1000000);
					// Add timestamp
					tmpDT := UDINT_TO_DT(ArEventLogRead_0.TimeStamp.sec);
					DT_TO_DTStructure(tmpDT, ADR(tmpDTstruct));
					brsmemset(ADR(gLogbook.DAT.Entries.Timestamp[idx]), 0, SIZEOF(gLogbook.DAT.Entries.Timestamp[idx]));
					NormalizeDateTime(ADR(gLogbook.DAT.Entries.Timestamp[idx]), tmpDTstruct.day, '');
					NormalizeDateTime(ADR(gLogbook.DAT.Entries.Timestamp[idx]), tmpDTstruct.month, '.');
					NormalizeDateTime(ADR(gLogbook.DAT.Entries.Timestamp[idx]), tmpDTstruct.year, '.');
					NormalizeDateTime(ADR(gLogbook.DAT.Entries.Timestamp[idx]), tmpDTstruct.hour, ' ');
					NormalizeDateTime(ADR(gLogbook.DAT.Entries.Timestamp[idx]), tmpDTstruct.minute, ':');
					NormalizeDateTime(ADR(gLogbook.DAT.Entries.Timestamp[idx]), tmpDTstruct.second, ':');
					NormalizeDateTime(ADR(gLogbook.DAT.Entries.Timestamp[idx]), gLogbook.DAT.Entries.DTmsec[idx], '.');
					// Add event ID, code, facility, severity
					gLogbook.DAT.Entries.EventID[gLogbook.DAT.EntriesTotal] := ArEventLogRead_0.EventID;
					IF ArEventLogRead_0.EventID <> 0 THEN
						gLogbook.DAT.Entries.Severity[idx] := GetSeverity(EventID := ArEventLogRead_0.EventID);
					ELSE
						gLogbook.DAT.Entries.Severity[idx] := ArEventLogReadErrorNumber_0.Severity;
					END_IF
					gLogbook.DAT.Entries.Code[idx] := GetCode(EventID := ArEventLogRead_0.EventID);
					gLogbook.DAT.Entries.FacilityCode[idx] := GetFacility(EventID := ArEventLogRead_0.EventID);
					gLogbook.DAT.Entries.FacilityText[idx] := FACILITY_TEXT[Facility.CntFacility];
					// Add error number and text, use event ID if error no is 0
					IF ArEventLogReadErrorNumber_0.ErrorNumber <> 0 THEN
						gLogbook.DAT.Entries.ErrorNo[idx] := ArEventLogReadErrorNumber_0.ErrorNumber;
					ELSE
						gLogbook.DAT.Entries.ErrorNo[idx] := ArEventLogRead_0.EventID;
					END_IF
					httpUtf8ToString_0(enable := TRUE, pSrc := ADR(ErrorText), pDest := ADR(gLogbook.DAT.Entries.ErrorText[idx]), destSize := SIZEOF(gLogbook.DAT.Entries.ErrorText[idx]));
				END_IF
			
				// --------------------------------------------------------------------------------------------------------------------
				// Reset buffer and function blocks
				brsmemset(ADR(AddData), 0, SIZEOF(AddData));
				ArEventLogGetLatestRecordID_0(Execute := FALSE);
				ArEventLogGetPreviousRecordID_0(Execute := FALSE);
				ArEventLogRead_0(Execute := FALSE);
				ArEventLogReadErrorNumber_0(Execute := FALSE);
				ArEventLogReadDescription_0(Execute := FALSE);
				ArEventLogReadAddData_0(Execute := FALSE);
			
				// Find next facility from here to the end
				REPEAT 
					Facility.CntFacility := Facility.CntFacility + 1;
					IF Facility.CntFacility <= LOGBOOK_FACILITIES_TOTAL THEN
						IF (Facility.Ident[Facility.CntFacility] <> 0 AND Facility.RecordID[Facility.CntFacility] > 1) OR (Facility.Ident[Facility.CntFacility] <> 0 AND Facility.RecordID[Facility.CntFacility] = 0) THEN
							EXIT;
						END_IF
					END_IF
					UNTIL Facility.CntFacility > LOGBOOK_FACILITIES_TOTAL
				END_REPEAT;
				// No facility found, start at the beginning
				IF Facility.CntFacility > LOGBOOK_FACILITIES_TOTAL THEN
					Facility.CntFacility := 0;
					// Find next facility from start to the end
					REPEAT 
						IF (Facility.Ident[Facility.CntFacility] <> 0 AND Facility.RecordID[Facility.CntFacility] > 1) OR (Facility.Ident[Facility.CntFacility] <> 0 AND Facility.RecordID[Facility.CntFacility] = 0) THEN
							EXIT;
						END_IF
						Facility.CntFacility := Facility.CntFacility + 1;
						UNTIL Facility.CntFacility > LOGBOOK_FACILITIES_TOTAL
					END_REPEAT;
				END_IF
				// Finish when no facility found or max entries is reached
				IF Facility.CntFacility > LOGBOOK_FACILITIES_TOTAL OR (gLogbook.PAR.AbortOnEntriesLimit AND gLogbook.DAT.EntriesTotal = LOGBOOK_ENTRIES_TOTAL) THEN
					gLogbook.Status := ERR_OK;
					gLogbook.CMD.Refresh := FALSE;
					state := enumWait;
				ELSE
					// Read latest entry
					IF Facility.RecordID[Facility.CntFacility] = 0 THEN
						state := enumLatest;
					// Read next entry
					ELSE
						state := enumNext;
					END_IF
				END_IF
				
				// --------------------------------------------------------------------------------------------------------------------
				// Error state
				// --------------------------------------------------------------------------------------------------------------------
			enumError:
				gLogbook.StatusText := 'Error...';
				brsmemset(ADR(gLogbook.CMD), 0, SIZEOF(gLogbook.CMD)-1);
				// Reset error
				IF gLogbook.CMD.ResetError THEN
					brsmemset(ADR(gLogbook.ERR), 0, SIZEOF(gLogbook.ERR));
					gLogbook.CMD.ResetError := FALSE;
					state := enumWait;	
				END_IF
				EXIT;
		END_CASE;
	END_FOR;


END_PROGRAM

