import { LightningElement } from 'lwc';

export default class RefreshButton extends LightningElement {

    handleRefresh() {
        window.location.reload();

    }
}
