import { LightningElement} from 'lwc';
import docParser from '@salesforce/apex/PdfParser.docParser';
import getDcParserText from '@salesforce/apex/PdfParser.getDcParserText';

export default class PDFParserComponent extends LightningElement {
    fileContent = "";
    parserDocumentId;

    handleUploadFinished(event) {
      const file = event.detail.files[0];
      console.log(file.documentId)
      if (file && file.documentId) {
        var conVersionId = file.documentId;
        docParser({ documentId : conVersionId })
        .then(response =>{
          //this.fileContent = response;
          
          console.log('>>>',response);
          this.parserDocumentId = response;
        })
        .catch(error => {
          this.showcheckSpinner = false;
          console.error('customFilter exception >> ');
          console.error(error);
          throw error;
        })

      }
      // setTimeout(() => {
      //   console.log('Timeout completed',this.parserDocumentId);
      //   if(this.parserDocumentId){
      //     getDcParserText({ docId : this.parserDocumentId })
      //     .then(response =>{
      //       this.fileContent = response;
            
      //       console.log('>>>',response);
      //     })
      //     .catch(error => {
      //       this.showcheckSpinner = false;
      //       console.error('customFilter exception >> ');
      //       console.error(error);
      //       throw error;
      //     })
      //   }
      // }, 6000); // Delay of 3000 milliseconds (3 seconds)
      
    }

    uploadPDF(uploadedFileName, uploadedFileContent) {
      // globalThis = window;
          // console.log(window)
          // console.log('pdfjslib ', pdfjslib + '/pdfjs-dist/build/pdf.worker.mjs');
          // pdfjslib.GlobalWorkerOptions.workerSrc = pdfjslib + '/pdfjs-dist/build/pdf.worker.js';
          //PDFJS.getDocument(response);
      console.log('uploadedFileName',uploadedFileName)
      console.log('uploadedFileContent',uploadedFileContent)
      
    }

  showToast(title, message) {
    this.dispatchEvent(new ShowToastEvent({ title, message }));
  }
}