public class PdfParser {
    //Test - 3

    @AuraEnabled
    public static String docParser(Id documentId){
        String parserDocId;
        String boundary = 'docparser-boundary-string';
        String parserApiKey = 'a2a3d50343ddf49bc2e880c204168c848d96cf42';
        ContentVersion contentVersion = [SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :documentId LIMIT 1];
        String fileName = contentVersion.Title;
        Blob fileBody = contentVersion.VersionData;
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
        //req.setEndpoint('https://api.docparser.com/v1/document/reparse/xzatlmyfsrpk');
        //req.setEndpoint('https://api.docparser.com/v1/results/xzatlmyfsrpk/382e37d8bd18f9af142daca74e66a2f2');
        req.setBodyAsBlob(bodyBlob);

        Http http = new Http();
        HTTPResponse response;
        try{
            response = http.send(req);
            if(response.getStatusCode() == 200) {
                Map<String, Object> parsedMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                parserDocId = (String) parsedMap.get('id');
                System.debug('Docparser Document Id : '+parserDocId);
                //return getDcParserText(parserApiKey,parserDocId);
                return parserDocId;
            } else {
                System.debug('Error Response : ' + response.getBody());
                System.debug(' Status : ' + response.getStatus());
                System.debug(' Status Code : ' + response.getStatusCode());
                return response.getBody();
            }
        } catch(Exception e){
            System.debug('+-+ error making request: '+e.getMessage());
            return e.getMessage();
        }
    }

    @Future(callout=true)
    public static void getDcParserText(String apiKey, String docId){
        String extractedTextContent;
        String generateEndpoint = 'https://api.docparser.com/v1/results/xzatlmyfsrpk/' + docId;
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Basic ' + apiKey);
        req.setEndpoint(generateEndpoint);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse docResponse;
        try{
            docResponse = http.send(req);
            if(docResponse.getStatusCode() == 200) {
                List<DocParserResponse> parsedResponse = (List<DocParserResponse>) JSON.deserialize(docResponse.getBody(), List<DocParserResponse>.class);
                extractedTextContent = parsedResponse[0].answer;  
                System.debug(extractedTextContent);
                //extractedTextContent;
            } else {
                System.debug('Error Response ' + docResponse.getBody());
                System.Debug(' Status ' + docResponse.getStatus());
                System.Debug(' Status Code' + docResponse.getStatusCode());
            }
        } catch(Exception e){
            System.debug('+-+ error making request: '+e.getMessage());
        }
    }

    public class DocParserResponse {
        public String id;
        public String document_id;
        public String file_name;
        public String answer;
    }
    // public static List<Blob> breakBlobIntoChunks(Blob dataBlob, Integer chunkSize) {
    //     List<Blob> chunks = new List<Blob>();
        
    //     // Calculate the number of chunks needed
    //     System.debug('dataBlob.size() : ' + dataBlob.size());
    //     System.debug('chunkSize - 1 : ' + (chunkSize - 1));
    //     Integer numChunks = (dataBlob.size() + chunkSize - 1) / chunkSize;
    //     System.debug('numChunks : '+numChunks);
    //     // Break the Blob into chunks
    //     for (Integer i = 0; i < numChunks; i++) {
    //         Integer startByte = i * chunkSize;
    //         Integer endByte = Math.min((i + 1) * chunkSize, dataBlob.size());
    //         System.debug('startByte : '+startByte);
    //         System.debug('endByte : '+endByte);
    //         // Extract a chunk of data
    //         Blob chunk = extractChunk(dataBlob, startByte, endByte);
    //         chunks.add(chunk);
    //     }
        
    //     return chunks;
    // }

    // public static Blob extractChunk(Blob dataBlob, Integer startByte, Integer endByte) {
        
    //     Blob chunk = Blob.valueOf(EncodingUtil.base64Encode(dataBlob).substring(startByte, endByte));
    //     System.debug('chunk : '+chunk.size());
    //     return chunk;
    // }

}
