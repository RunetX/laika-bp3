///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, ООО Изи Клауд, https://izi.cloud
// All rights reserved. This program and accompanying materials 
// are subject to license terms Attribution 4.0 International (CC BY 4.0)
// The license text is available here:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetReadingInvoicesXML(connection, dateFrom, dateTo, docType)
	
	argsType = XDTOFactory.Type("https://izi.cloud/iiko/reading/invoices", "args");
	args = XDTOFactory.Create(argsType); 
	
	eVersion = like_EntitiesAtServer.GetEntitiesVersion(connection);
	args.entities_version = eVersion;
	args.client_type 	  = "BACK";
	args.enable_warnings  = False;	
	args.request_watchdog_check_results = True;
	args.use_raw_entities = True;
	args.dateFrom 		  = like_CommonAtServer.getIIKODate(dateFrom, "000");
	args.dateTo 		  = like_CommonAtServer.getIIKODate(dateTo, "999");
	args.docType 		  = docType;	
	
	return like_CommonAtServer.XDTO2XML(args);
	
EndFunction

Function GetInvoices(dateFrom, dateTo, docType) Export
	
	ActiveConnection = like_ConnectionAtServer.GetActiveConnecton();
	If ActiveConnection = Undefined Then
		Return New Structure("success, errorString", False, NStr("en = 'No active connection'; ru = 'Подключение неактивно'"));
	EndIf;
	
	XMLPackage = getReadingInvoicesXML(ActiveConnection, dateFrom, dateTo, docType);	
	ConnectionFields = like_ConnectionAtServer.GetConnectionFields(ActiveConnection);
	
	ObjectFields = like_CommonAtServer.GetObjectFieldsStructure();
	ObjectFields.ConProps  	 = ConnectionFields;
	ObjectFields.Resource 	 = "/resto/services/document";
	ObjectFields.Namespace 	 = "https://izi.cloud/iiko/reading/invoicesResponse";
	ObjectFields.TypeName 	 = "result";
	ObjectFields.RequestType = "POST";
	Params = New Map;
	Params.Insert("methodName", "getIncomingDocumentsRecordsByDepartments");
	ObjectFields.Parameters  = Params;
	ObjectFields.Headers     = like_Common.GetIIKOHeaders(ConnectionFields);
	ObjectFields.Body		 = XMLPackage;
	ObjectFields.isGZIP		 = True;
	
	IIKOObject = like_CommonAtServer.GetIIKOObject(ObjectFields);	
	If IIKOObject = Undefined Then
		Return New Structure("success, errorString", False, NStr("en = 'Receiving data from IIKO server error'; ru = 'Ошибка получения данных с сервера IIKO'"));	
	EndIf;
	
	If IIKOObject.success Then
		updateItems = IIKOObject.entitiesUpdate.items;
		If updateItems.Properties().Get("i") <> Undefined Then
			like_EntitiesAtServer.ExeItems(updateItems.i, ActiveConnection, IIKOObject.entitiesUpdate.revision);
		EndIf;
		If IIKOObject.returnValue.Properties().Get("i") <> Undefined Then
			Return New Structure("success, returnValue", True, IIKOObject.returnValue.i);
		Else
			Return New Structure("success, errorString", False, NStr("en = 'No invoices '; ru = 'Нет накладных типа '") + docType);
		EndIf;
	Else
		Return New Structure("success, errorString", False, IIKOObject.errorString); 
	EndIf;	
EndFunction

Function FindByCodeAndConnection(CatalogName, code) Export
	
	FindQuery = New Query("SELECT
	                      |	like_catalog.UUID AS UUID
	                      |FROM
	                      |	Catalog.[catalogName] AS like_catalog
	                      |WHERE
	                      |	like_catalog.Code = &Code
	                      |	AND like_catalog.connection = &connection");
	FindQuery.Text = StrReplace(FindQuery.Text, "[catalogName]", CatalogName);
	FindQuery.SetParameter("Code", code);
	FindQuery.SetParameter("connection", like_ConnectionAtServer.GetActiveConnecton());
	FindSelection = FindQuery.Execute().Select();
	FindSelection.Next();
	Return FindSelection.UUID;
	
EndFunction