import { LightningElement, track } from 'lwc';

export default class SpeakerSearch extends LightningElement {
    @track nameFilter = '';
    @track specialityFilter = '';
    @track selectedSpeaker = null;

    handleNameChange(event) {
        this.nameFilter = event.target.value;
    }
    handleSpecialityChange(event) {
        this.specialityFilter = event.target.value;
    }
    handleSearch() {
        // The child listens to reactive @api properties; no extra action needed
    }
    handleClear() {
        this.nameFilter = '';
        this.specialityFilter = '';
    }

    handleSpeakerSelected(event) {
        const detail = event.detail; // expected to be speaker record
        this.selectedSpeaker = detail;
    }
}


