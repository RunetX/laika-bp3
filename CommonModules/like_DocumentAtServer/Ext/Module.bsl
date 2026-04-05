///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, ООО Изи Клауд, https://izi.cloud
// All rights reserved. This program and accompanying materials 
// are subject to license terms Attribution 4.0 International (CC BY 4.0)
// The license text is available here:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetReadingDocumentXML(connection, documentId)
	
	argsType = XDTOFactory.Type("https://izi.cloud/iiko/reading/document", "args");
	args = XDTOFactory.Create(argsType); 
	
	eVersion = like_EntitiesAtServer.GetEntitiesVersion(connection);
	args.entities_version = eVersion;
	args.client_type 	  = "BACK";
	args.enable_warnings  = False;	
	args.request_watchdog_check_results = True;
	args.use_raw_entities = True;
	args.id 		  	  = documentId;	
	
	return like_CommonAtServer.XDTO2XML(args);
	
EndFunction

Function GetDocument(documentId, namespace) Export
	
	ActiveConnection = like_ConnectionAtServer.GetActiveConnecton();
	If ActiveConnection = Undefined Then
		Return New Structure("success, errorString", False, "No active connection");
	EndIf;
	
	XMLPackage = getReadingDocumentXML(ActiveConnection, documentId);	
	ConnectionFields = like_ConnectionAtServer.GetConnectionFields(ActiveConnection);
	
	ObjectFields = like_CommonAtServer.GetObjectFieldsStructure();
	ObjectFields.ConProps  	 = ConnectionFields;
	ObjectFields.Resource 	 = "/resto/services/document";
	ObjectFields.Namespace 	 = namespace;
	ObjectFields.TypeName 	 = "result";
	ObjectFields.RequestType = "POST";
	Params = New Map;
	Params.Insert("methodName", "getAbstractDocument");
	ObjectFields.Parameters  = Params;
	ObjectFields.Headers     = like_Common.getIIKOHeaders(ConnectionFields);
	ObjectFields.Body		 = XMLPackage;
	ObjectFields.isGZIP		 = True;
	
	IIKOObject = like_CommonAtServer.GetIIKOObject(ObjectFields);	
	If IIKOObject.success Then
		updateItems = IIKOObject.entitiesUpdate.items;
		If updateItems.Properties().Get("i") <> Undefined Then
			like_EntitiesAtServer.ExeItems(updateItems.i, ActiveConnection, IIKOObject.entitiesUpdate.revision);
		EndIf;
		
		Return New Structure("success, returnValue", True, IIKOObject.returnValue);
	Else
		Return New Structure("success, errorString", False, IIKOObject.errorString); 
	EndIf;	
EndFunction