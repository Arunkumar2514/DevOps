public class MyQueueableClass implements Queueable {
    //Test -02
    private String apiKey;
    private String docId;

    public MyQueueableClass(String apiKey, String docId) {
        this.apiKey = apiKey;
        this.docId = docId;
    }
    
    public void execute(QueueableContext context) {
        PdfParser.getDcParserText(apiKey, docId);
    }

}
