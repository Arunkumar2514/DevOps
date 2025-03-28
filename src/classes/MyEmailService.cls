global class MyEmailService implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        //Test 02
        //System.debug('Subject : '+email.subject);
        List<Messaging.InboundEmail.BinaryAttachment> binaryAttachments = email.binaryAttachments;
        if (binaryAttachments != null && binaryAttachments.size() > 0) {
            for (Messaging.InboundEmail.BinaryAttachment attachment : binaryAttachments) {
                // Extract attachment details
                String pdfFileName = attachment.fileName;
                Blob attachmentBody = attachment.body;

                System.debug('attachment Type : '+attachment.mimeTypeSubType);
                System.debug('attachmentBody Size : '+attachmentBody.size());
                docParser(pdfFileName,attachmentBody);

                // if(fileBody.size() > 5000000) {
                //     System.debug('custom logic to handle chunks');
                //     Integer chunkSize = 3000000; // Specify your desired chunk size
                //     blobList = breakBlobIntoChunks(fileBody, chunkSize);
                //     System.debug('Last Blob :'+(blobList.size()-1));
                //     Blob tempBlob = blobList[blobList.size()-1];
                //     bodyEncoded = EncodingUtil.base64Encode(tempBlob);
                // } else {
                //     bodyEncoded = EncodingUtil.base64Encode(fileBody);
                //     System.debug('logic failed');
                // }
                
                // Perform further processing (e.g., save attachment as a ContentVersion)
                // ContentVersion cv = new ContentVersion();
                // cv.Title = pdfFileName;
                // cv.PathOnClient = pdfFileName;
                // cv.VersionData = attachmentBody;
                // insert cv;
                // System.debug('CV Inserted');
               
            }
        }
        
        return result;
    }

     public static void docParser(String fileName, Blob fileBody){
        String parserDocId;
        String boundary = 'docparser-boundary-string';
        String parserApiKey = 'a2a3d50343ddf49bc2e880c204168c848d96cf42';
        Blob bodyBlob;
        String bodyEncoded = EncodingUtil.base64Encode(fileBody);

        String header = '--' + boundary + '\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"\nContent-Type: multipart/form-data;'+'\nnon-svg='+True;
        String footer = '--' + boundary + '--';
        String headerEncoded;
        String footerEncoded;

        do
        {
            header += ' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header + '\r\n\r\n'));
        }
        while(headerEncoded.endsWith('='));

        String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
        if (last4Bytes.endsWith('=='))
        {
            last4Bytes = last4Bytes.substring(0, 2) + '0K';
            bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length() - 4) + last4Bytes;  
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        } else if (last4Bytes.endsWith('='))
        {
            last4Bytes = last4Bytes.substring(0, 3) + 'N';
            System.debug(bodyEncoded.length());
            bodyEncoded = bodyEncoded.substring(0, bodyEncoded.length()-4) + last4Bytes;
            footer = '\n' + footer;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));           
        } else
        {
            footer = '\r\n' + footer;
            footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
        }

        bodyBlob = EncodingUtil.base64Decode(headerEncoded + bodyEncoded + footerEncoded);
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'Basic ' + parserApiKey);
        req.setMethod('POST');  
        req.setEndpoint('https://api.docparser.com/v1/document/upload/xzatlmyfsrpk');
        req.setBodyAsBlob(bodyBlob);

        Http http = new Http();
        HTTPResponse response;
        try{
            response = http.send(req);
            if(response.getStatusCode() == 200) {
                Map<String, Object> parsedMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                parserDocId = (String) parsedMap.get('id');
                System.debug('Docparser Document Id : '+parserDocId);
                System.enqueueJob(new MyQueueableClass(parserApiKey,parserDocId), 1);
            } else {
                System.debug('Error Response : ' + response.getBody());
                System.debug(' Status : ' + response.getStatus());
                System.debug(' Status Code : ' + response.getStatusCode());
            }
        } catch(Exception e){
            System.debug('+-+ error making request: '+e.getMessage());
        }
    }

}