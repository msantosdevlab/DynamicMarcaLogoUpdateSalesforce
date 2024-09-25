import { LightningElement, api } from 'lwc';
import checkLogoMatch from '@salesforce/apex/ModeloLogoChecker.checkLogoMatch';

export default class CheckModelLogo extends LightningElement {
    @api recordId;

    // Called when the component is connected to the DOM
    async connectedCallback() {
        // Check if the logo has been updated
        await this.checkLogo(this.recordId);
    }

    // Asynchronous function to check the logo
    async checkLogo(modelId) {
        try {
            const result = await checkLogoMatch({ modeloId: modelId });
        } catch (error) {
            console.error('Error checking logo match: ', error);
        }
    }
}
